//
//  ScubyWarsViewController.h
//  ScubyWars
//
//  Created by twiedow on 06.03.11.
//  Copyright 2011 Tobias Wiedow. All rights reserved.
//

#import <UIKit/UIKit.h>
#import "ClientSocket.h"


@interface ScubyWarsViewController : UIViewController <UIAccelerometerDelegate> {
  IBOutlet UILabel* playerIdLabel;
  ClientSocket* clientSocket;
  PlayerDirection currentPlayerDirection;
  PlayerAcceleration currentPlayerAcceleration;
}

@property (retain) UILabel* playerIdLabel;
@property (retain) ClientSocket* clientSocket;

@end
