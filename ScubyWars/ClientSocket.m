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


@interface ClientSocket ()

@property (strong, nonatomic) NSInputStream* inputStream;
@property (strong, nonatomic) NSOutputStream* outputStream;
@property (strong, nonatomic) NSLock* sendActionLock;
@property (strong, nonatomic) NSNumber* playerId;

@end


@implementation ClientSocket


@synthesize inputStream = _inputStream;
@synthesize outputStream = _outputStream;
@synthesize sendActionLock = _sendActionLock;
@synthesize playerId = _playerId;


- (void) sendAction:(Action*) action {
  @autoreleasepool {
  
    [self.sendActionLock lock];
    
    NSData* payload = [action payload];
    [self.outputStream write:[payload bytes] maxLength:[payload length]];
    
    [self.sendActionLock unlock];
  
  }
}


- (void) handshakeAndHandleInput {
  @autoreleasepool {

    [self sendAction:[[HandshakeAction alloc] init]];

    uint8_t headerBuffer[6];
    NSInteger readBytes = 0;
    short entityType = -1;
    int length = -1;

    do {
      readBytes = [self.inputStream read:headerBuffer maxLength:6];

      if (readBytes == 6) {
        entityType = OSReadBigInt16(headerBuffer, 0);
        length = OSReadBigInt32(headerBuffer, 2);
      }
      
      uint8_t payloadBuffer[length];

      readBytes = [self.inputStream read:payloadBuffer maxLength:length];
    
      if (readBytes == length) {
        if (entityType == kEntityTypeHandshake) {
          if (payloadBuffer[0] == 0)
            self.playerId = [NSNumber numberWithInt:OSReadBigInt64(payloadBuffer, 1)];
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
    // TODO: send notifications on data change
  }
}


- (id) init {
  if ((self = [super init])) {
    self.sendActionLock = [[NSLock alloc] init];

    CFReadStreamRef readStream;
    CFWriteStreamRef writeStream;
    CFStreamCreatePairWithSocketToHost(NULL, (CFStringRef) kHost, kPort, &readStream, &writeStream);
    
    self.inputStream = (__bridge NSInputStream*) readStream;
    self.outputStream = (__bridge NSOutputStream*) writeStream;

    [self.inputStream setDelegate:self];
    [self.outputStream setDelegate:nil];
    [self.inputStream open];
    [self.outputStream open];

    [NSThread detachNewThreadSelector:@selector(handshakeAndHandleInput) toTarget:self withObject:nil];
  }

  return self;
}


- (void) sendPlayerActionWithDirection:(PlayerDirection) playerDirection withAcceleration:(PlayerAcceleration) playerAcceleration fire:(BOOL) fireFlag {
  if (self.playerId != nil)
    [NSThread detachNewThreadSelector:@selector(sendAction:) toTarget:self withObject:[[PlayerAction alloc] initWithDirection:playerDirection withAcceleration:playerAcceleration fire:fireFlag]];
}


- (void) stream:(NSStream*) stream handleEvent:(NSStreamEvent) streamEvent {
  if (streamEvent == NSStreamEventErrorOccurred)
    NSLog(@"Error in input stream");
  else if (streamEvent == NSStreamEventEndEncountered)
    NSLog(@"End of input stream");
}


- (void) close {
  [self.inputStream close];
  [self.outputStream close];
}


@end
