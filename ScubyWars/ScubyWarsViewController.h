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
}

@property (weak, nonatomic) IBOutlet UILabel* playerIdLabel;

@end
