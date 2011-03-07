//
//  ScubyWarsViewController.m
//  ScubyWars
//
//  Created by twiedow on 06.03.11.
//  Copyright 2011 Tobias Wiedow. All rights reserved.
//

#import "ScubyWarsViewController.h"


@implementation ScubyWarsViewController


@synthesize playerIdLabel;
@synthesize clientSocket;


- (void) dealloc {
  self.playerIdLabel = nil;
  self.clientSocket = nil;

  [playerIdLabel release];
  [super dealloc];
}


- (void) viewDidLoad {
  [super viewDidLoad];

  self.clientSocket = [[[ClientSocket alloc] init] autorelease];
  currentPlayerDirection = PlayerDirectionStraight;
  currentPlayerAcceleration = PlayerAccelerationNone;

  playerIdLabel.text = [NSString stringWithFormat:@"%qi", [clientSocket playerId]];

  UIGestureRecognizer* gestureRecognizer = [[[UITapGestureRecognizer alloc] initWithTarget:self action:@selector(touchAction)] autorelease];
  [self.view addGestureRecognizer:gestureRecognizer];

  [UIAccelerometer sharedAccelerometer].delegate = self;
  [UIAccelerometer sharedAccelerometer].updateInterval = 1.0 / 10;
}


- (void) viewDidDisappear:(BOOL) animated {
  [UIAccelerometer sharedAccelerometer].delegate = nil;
  [clientSocket close];

  [super viewDidDisappear:animated];
}


- (void) touchAction {
  [clientSocket sendPlayerActionWithDirection:currentPlayerDirection withAcceleration:currentPlayerAcceleration fire:YES];
}


- (void) accelerometer:(UIAccelerometer*) accelerometer didAccelerate:(UIAcceleration*) acceleration {
//  NSLog(@"accel (x=%f,y=%f,z=%f)", acceleration.x, acceleration.y, acceleration.z);

  PlayerDirection newPlayerDirection;
  PlayerAcceleration newPlayerAcceleration;

  if (acceleration.y < -0.2)
    newPlayerDirection = PlayerDirectionLeft;
  else if (acceleration.y > 0.2)
    newPlayerDirection = PlayerDirectionRight;
  else
    newPlayerDirection = PlayerDirectionStraight;

  if (acceleration.z < -0.8)
    newPlayerAcceleration = PlayerAccelerationStraight;
  else if (acceleration.z > -0.4)
    newPlayerAcceleration = PlayerAccelerationNone;

  if (newPlayerDirection != currentPlayerDirection || newPlayerAcceleration != currentPlayerAcceleration) {
    currentPlayerDirection = newPlayerDirection;
    currentPlayerAcceleration = newPlayerAcceleration;

    [clientSocket sendPlayerActionWithDirection:currentPlayerDirection withAcceleration:currentPlayerAcceleration fire:NO];
  }
}


- (BOOL) shouldAutorotateToInterfaceOrientation:(UIInterfaceOrientation) toInterfaceOrientation {
  if (toInterfaceOrientation == UIInterfaceOrientationLandscapeLeft)
    return YES;
  return NO;
}


- (void)viewDidUnload {
  [playerIdLabel release];
  playerIdLabel = nil;
  [super viewDidUnload];
}
@end
