//
//  ClientSocket.h
//  ScubyWars
//
//  Created by twiedow on 06.03.11.
//  Copyright 2011 Tobias Wiedow. All rights reserved.
//

#import <Foundation/Foundation.h>


enum {
  PlayerDirectionLeft = 0,
  PlayerDirectionRight = 1,
  PlayerDirectionStraight = 2
};
typedef NSUInteger PlayerDirection;


enum {
  PlayerAccelerationStraight = 0,
  PlayerAccelerationNone = 1
};
typedef NSUInteger PlayerAcceleration;


@interface ClientSocket : NSObject <NSStreamDelegate> {
}

- (void) sendPlayerActionWithDirection:(PlayerDirection) playerDirection withAcceleration:(PlayerAcceleration) playerAcceleration fire:(BOOL) fireWithNextActionFlag;
- (void) close;

@end
