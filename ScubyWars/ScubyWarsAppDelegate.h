//
//  ScubyWarsAppDelegate.h
//  ScubyWars
//
//  Created by twiedow on 06.03.11.
//  Copyright 2011 Tobias Wiedow. All rights reserved.
//

#import <UIKit/UIKit.h>

@class ScubyWarsViewController;

@interface ScubyWarsAppDelegate : NSObject <UIApplicationDelegate> {

}

@property (nonatomic, retain) IBOutlet UIWindow *window;

@property (nonatomic, retain) IBOutlet ScubyWarsViewController *viewController;

@end
