//
//  ClientSocket.m
//  ScubyWars
//
//  Created by twiedow on 06.03.11.
//  Copyright 2011 Tobias Wiedow. All rights reserved.
//

#import "ClientSocket.h"
#import "ByteUtils.h"

#define kHost @"192.168.178.3"
#define kPort 1337
#define kPlayerName @"Hubba"

static short kRelationTypePlayer = 0;
static short kRelationTypeListener = 1;

static short kEntityTypePlayer = 0;
static short kEntityTypeShot = 1;
static short kEntityTypePowerUp = 2;
static short kEntityTypeWorld = 3;
static short kEntityTypeHandshake = 4;
static short kEntityTypeAction = 5;
static short kEntityTypeDirectAction = 6;
static short kEntityTypeScoreboard = 7;
static short kEntityTypePlayerJoined = 8;
static short kEntityTypePlayerLeft = 9;


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
  NSMutableData* payload = [NSMutableData data];
  [payload appendData:[ByteUtils dataFromShort:kEntityTypeHandshake]];
  [payload appendData:[ByteUtils dataFromInt:(2 + [kPlayerName length])]];
  [payload appendData:[ByteUtils dataFromShort:kRelationTypePlayer]];
  [payload appendData:[kPlayerName dataUsingEncoding:NSUTF8StringEncoding]];
  
  return payload;
}
@end


@interface PlayerAction : NSObject {
  PlayerDirection playerDirection;
  PlayerAcceleration playerAcceleration;
  BOOL fire;
}
- (id) initWithDirection:(PlayerDirection) playerDirection withAcceleration:(PlayerAcceleration) playerAcceleration fire:(BOOL) fire;
@end

@implementation PlayerAction
- (id) initWithDirection:(PlayerDirection) aPlayerDirection withAcceleration:(PlayerAcceleration) aPlayerAcceleration fire:(BOOL) aFire {
  if ((self=[super init])) {
    playerDirection = aPlayerDirection;
    playerAcceleration = aPlayerAcceleration;
    fire = aFire;
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


- (void) readInputStream {
  NSAutoreleasePool* pool = [[NSAutoreleasePool alloc] init];
  [pool drain];
}


- (void) performHandshake {
  NSAutoreleasePool* pool = [[NSAutoreleasePool alloc] init];
  
  [self sendAction:[[[HandshakeAction alloc] init] autorelease]];
  
  uint8_t headerBuffer[6];
  [inputStream read:headerBuffer maxLength:6];
  
  short entityType = OSReadBigInt16(headerBuffer, 0);
  int length = OSReadBigInt32(headerBuffer, 2);
  
  NSLog(@"entityType %d", entityType);
  NSLog(@"length %d", length);
  
  if (entityType == kEntityTypeHandshake) {
    uint8_t payloadBuffer[length];
    [inputStream read:payloadBuffer maxLength:length];
    
    if (payloadBuffer[0] == 0) {
      playerId = OSReadBigInt64(payloadBuffer, 1);
//      [NSThread detachNewThreadSelector:@selector(readInputStream) toTarget:self withObject:nil];
    }
  }
  
  [pool drain];
}


- (id) init {
  if ((self = [super init])) {
    self.sendActionLock = [[[NSLock alloc] init] autorelease];

    CFReadStreamRef readStream;
    CFWriteStreamRef writeStream;
    CFStreamCreatePairWithSocketToHost(NULL, (CFStringRef) kHost, kPort, &readStream, &writeStream);
    
    self.inputStream = (NSInputStream*) readStream;
    self.outputStream = (NSOutputStream*) writeStream;

    [inputStream setDelegate:nil];
    [outputStream setDelegate:nil];
    [inputStream open];
    [outputStream open];

//    [NSThread detachNewThreadSelector:@selector(performHandshake) toTarget:self withObject:nil];
    [self performHandshake];
  }

  return self;
}


- (long long) playerId {
  return playerId;
}


- (void) sendPlayerActionWithDirection:(PlayerDirection) playerDirection withAcceleration:(PlayerAcceleration) playerAcceleration fire:(BOOL) fire {
  [NSThread detachNewThreadSelector:@selector(sendAction:) toTarget:self withObject:[[[PlayerAction alloc] initWithDirection:playerDirection withAcceleration:playerAcceleration fire:fire] autorelease]];
}


- (void) close {
  [inputStream close];
  [outputStream close];
}


@end
