//
//  ByteUtils.h
//  ScubyWars
//
//  Created by twiedow on 06.03.11.
//  Copyright 2011 Tobias Wiedow. All rights reserved.
//

#import <Foundation/Foundation.h>


@interface ByteUtils : NSObject {
    
}

+ (NSData*) dataFromInt:(int) value;
+ (NSData*) dataFromShort:(short) value;
+ (NSData*) dataFromByte:(uint8_t) value;

@end
