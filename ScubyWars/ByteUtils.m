//
//  ByteUtils.m
//  ScubyWars
//
//  Created by twiedow on 06.03.11.
//  Copyright 2011 Tobias Wiedow. All rights reserved.
//

#import "ByteUtils.h"


@implementation ByteUtils


+ (NSData*) dataFromInt:(int) value {
  uint8_t bytes[4];
  bytes[0] = (value >> 24) & 0xFF;
  bytes[1] = (value >> 16) & 0xFF;
  bytes[2] = (value >> 8) & 0xFF;
  bytes[3] = value & 0xFF;
  
  return [NSData dataWithBytes:bytes length:4];
}


+ (NSData*) dataFromShort:(short) value {
  uint8_t bytes[2];
  bytes[0] = (value >> 8) & 0xFF;
  bytes[1] = value & 0xFF;

  return [NSData dataWithBytes:bytes length:2];
}


+ (NSData*) dataFromByte:(uint8_t) value {
  uint8_t bytes[1];
  bytes[0] = value & 0xFF;
  
  return [NSData dataWithBytes:bytes length:1];
}


@end
