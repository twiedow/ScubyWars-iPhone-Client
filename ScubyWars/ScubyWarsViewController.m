//
//  ScubyWarsViewController.m
//  ScubyWars
//
//  Created by twiedow on 06.03.11.
//  Copyright 2011 Tobias Wiedow. All rights reserved.
//

#import "ScubyWarsViewController.h"


@interface ScubyWarsViewController () {
  PlayerDirection currentPlayerDirection;
  PlayerAcceleration currentPlayerAcceleration;
}

@property (strong, nonatomic) ClientSocket* clientSocket;

@end


@implementation ScubyWarsViewController


@synthesize playerIdLabel = _playerIdLabel;
@synthesize clientSocket = _clientSocket;


- (void) viewDidLoad {
  [super viewDidLoad];

  self.clientSocket = [[ClientSocket alloc] init];
  currentPlayerDirection = PlayerDirectionStraight;
  currentPlayerAcceleration = PlayerAccelerationNone;

  UIGestureRecognizer* gestureRecognizer = [[UITapGestureRecognizer alloc] initWithTarget:self action:@selector(touchAction)];
  [self.view addGestureRecognizer:gestureRecognizer];

  [UIAccelerometer sharedAccelerometer].delegate = self;
  [UIAccelerometer sharedAccelerometer].updateInterval = 1.0 / 10;
}


- (void) viewDidDisappear:(BOOL) animated {
  [UIAccelerometer sharedAccelerometer].delegate = nil;
  [self.clientSocket close];

  [super viewDidDisappear:animated];
}


- (void) touchAction {
  [self.clientSocket sendPlayerActionWithDirection:currentPlayerDirection withAcceleration:currentPlayerAcceleration fire:YES];
}


- (void) accelerometer:(UIAccelerometer*) accelerometer didAccelerate:(UIAcceleration*) acceleration {
//  NSLog(@"accel (x=%f,y=%f,z=%f)", acceleration.x, acceleration.y, acceleration.z);

  PlayerDirection newPlayerDirection = PlayerDirectionStraight;
  PlayerAcceleration newPlayerAcceleration = PlayerAccelerationNone;

  if (acceleration.y < -0.2)
    newPlayerDirection = PlayerDirectionLeft;
  else if (acceleration.y > 0.2)
    newPlayerDirection = PlayerDirectionRight;

  if (acceleration.z < -0.8)
    newPlayerAcceleration = PlayerAccelerationStraight;
  else if (acceleration.z > -0.4)
    newPlayerAcceleration = PlayerAccelerationNone;

  if (newPlayerDirection != currentPlayerDirection || newPlayerAcceleration != currentPlayerAcceleration) {
    currentPlayerDirection = newPlayerDirection;
    currentPlayerAcceleration = newPlayerAcceleration;

    [self.clientSocket sendPlayerActionWithDirection:currentPlayerDirection withAcceleration:currentPlayerAcceleration fire:NO];
  }
}


- (BOOL) shouldAutorotateToInterfaceOrientation:(UIInterfaceOrientation) toInterfaceOrientation {
  if (toInterfaceOrientation == UIInterfaceOrientationLandscapeLeft)
    return YES;
  return NO;
}


@end
