//
//  ClientSocket.m
//  ScubyWars
//
//  Created by twiedow on 06.03.11.
//  Copyright 2011 Tobias Wiedow. All rights reserved.
//

#import "ClientSocket.h"
#import "ByteUtils.h"

#define kHost @"10.1.1.169"
#define kPort 1337
#define kPlayerName @"Hubba"

static short kRelationTypePlayer = 0;
//static short kRelationTypeListener = 1;

//static short kEntityTypePlayer = 0;
//static short kEntityTypeShot = 1;
//static short kEntityTypePowerUp = 2;
//static short kEntityTypeWorld = 3;
static short kEntityTypeHandshake = 4;
static short kEntityTypeAction = 5;
static short kEntityTypeScoreboard = 6;
static short kEntityTypePlayerJoined = 7;
static short kEntityTypePlayerLeft = 8;
static short kEntityTypePlayerName = 9;


@interface Action : NSObject {
}
- (NSData*) payload;
@end

@implementation Action
- (NSData*) payload {
  return [NSData data];
}
@end


@interface HandshakeAction : Action {
}
@end

@implementation HandshakeAction
- (NSData*) payload {
  NSData* playerNameData = [ByteUtils dataFromString:kPlayerName];

  NSMutableData* payload = [NSMutableData data];
  [payload appendData:[ByteUtils dataFromShort:kEntityTypeHandshake]];
  [payload appendData:[ByteUtils dataFromInt:(2 + [playerNameData length])]];
  [payload appendData:[ByteUtils dataFromShort:kRelationTypePlayer]];
  [payload appendData:playerNameData];
  
  return payload;
}
@end


@interface PlayerAction : NSObject {
  PlayerDirection playerDirection;
  PlayerAcceleration playerAcceleration;
  BOOL fire;
}
- (id) initWithDirection:(PlayerDirection) playerDirection withAcceleration:(PlayerAcceleration) playerAcceleration fire:(BOOL) fireFlag;
@end

@implementation PlayerAction
- (id) initWithDirection:(PlayerDirection) aPlayerDirection withAcceleration:(PlayerAcceleration) aPlayerAcceleration fire:(BOOL) fireFlag {
  if ((self=[super init])) {
    playerDirection = aPlayerDirection;
    playerAcceleration = aPlayerAcceleration;
    fire = fireFlag;
  }

  return self;
}


- (NSData*) payload {
  NSMutableData* payload = [NSMutableData data];
  [payload appendData:[ByteUtils dataFromShort:kEntityTypeAction]];
  [payload appendData:[ByteUtils dataFromInt:4]];
  [payload appendData:[ByteUtils dataFromByte:(playerDirection==PlayerDirectionLeft?1:0)]];
  [payload appendData:[ByteUtils dataFromByte:(playerDirection==PlayerDirectionRight?1:0)]];
  [payload appendData:[ByteUtils dataFromByte:(playerAcceleration==PlayerAccelerationStraight?1:0)]];
  [payload appendData:[ByteUtils dataFromByte:(fire?1:0)]];
  
  NSLog(@"player action (playerDirection %d, playerAcceleration %d, fire %@) %@", playerDirection, playerAcceleration, fire?@"YES":@"NO", payload);
  return payload;
}
@end


@implementation ClientSocket


@synthesize inputStream;
@synthesize outputStream;
@synthesize sendActionLock;


- (void) dealloc {
  self.inputStream = nil;
  self.outputStream = nil;
  self.sendActionLock = nil;

  [super dealloc];
}


- (void) sendAction:(Action*) action {
  NSAutoreleasePool* pool = [[NSAutoreleasePool alloc] init];
  
  [action retain];
  [sendActionLock lock];
  
  NSData* payload = [action payload];
  [outputStream write:[payload bytes] maxLength:[payload length]];
  
  [action release];
  [sendActionLock unlock];
  
  [pool drain];
}


- (void) handshakeAndHandleInput {
  NSAutoreleasePool* pool = [[NSAutoreleasePool alloc] init];

  [self sendAction:[[[HandshakeAction alloc] init] autorelease]];

  uint8_t headerBuffer[6];
  NSInteger readBytes = 0;
  short entityType = -1;
  int length = -1;

  do {
    readBytes = [inputStream read:headerBuffer maxLength:6];

    if (readBytes == 6) {
      entityType = OSReadBigInt16(headerBuffer, 0);
      length = OSReadBigInt32(headerBuffer, 2);
    }
    
    uint8_t payloadBuffer[length];

    readBytes = [inputStream read:payloadBuffer maxLength:length];
  
    if (readBytes == length) {
      if (entityType == kEntityTypeHandshake) {
        if (payloadBuffer[0] == 0)
          playerId = OSReadBigInt64(payloadBuffer, 1);
      }
      else if (entityType == kEntityTypeScoreboard) {
        for (int offset = 0; offset < length; offset+=12) {
          long long pId = OSReadBigInt64(payloadBuffer, offset);
          int score = OSReadBigInt32(payloadBuffer, offset+8);
          
          NSLog(@"ID %qi: %d", pId, score);
        }
      }
      else if (entityType == kEntityTypePlayerJoined || entityType == kEntityTypePlayerLeft || entityType == kEntityTypePlayerName) {
        long long pId = OSReadBigInt64(payloadBuffer, 0);
        char chars[length - 8];
        
        for (int i = 8; i < length; i++)
          chars[i-8] = payloadBuffer[i];
        
        NSString* name = [NSString stringWithUTF8String:chars];
        
        NSLog(@"%@ <%qi> %@", name, pId, entityType == kEntityTypePlayerJoined ? @"joined" : (entityType == kEntityTypePlayerLeft ? @"left" : @"named"));
      }
    }
  } while (readBytes == 6);
  
  [pool drain];
}


- (id) init {
  if ((self = [super init])) {
    self.sendActionLock = [[[NSLock alloc] init] autorelease];
    playerId = -1;

    CFReadStreamRef readStream;
    CFWriteStreamRef writeStream;
    CFStreamCreatePairWithSocketToHost(NULL, (CFStringRef) kHost, kPort, &readStream, &writeStream);
    
    self.inputStream = (NSInputStream*) readStream;
    self.outputStream = (NSOutputStream*) writeStream;

    [inputStream setDelegate:self];
    [outputStream setDelegate:nil];
    [inputStream open];
    [outputStream open];

    [NSThread detachNewThreadSelector:@selector(handshakeAndHandleInput) toTarget:self withObject:nil];
  }

  return self;
}


- (long long) playerId {
  return playerId;
}


- (void) sendPlayerActionWithDirection:(PlayerDirection) playerDirection withAcceleration:(PlayerAcceleration) playerAcceleration fire:(BOOL) fireFlag {
  if (playerId != -1)
    [NSThread detachNewThreadSelector:@selector(sendAction:) toTarget:self withObject:[[[PlayerAction alloc] initWithDirection:playerDirection withAcceleration:playerAcceleration fire:fireFlag] autorelease]];
}


- (void) stream:(NSStream*) stream handleEvent:(NSStreamEvent) streamEvent {
  if (streamEvent == NSStreamEventErrorOccurred)
    NSLog(@"Error in input stream");
  else if (streamEvent == NSStreamEventEndEncountered)
    NSLog(@"End of input stream");
}


- (void) close {
  [inputStream close];
  [outputStream close];
}


@end
