//
//  OTAppDelegate.m
//  SliderWithNumberPad
//
//  Created by Kevin He on 2013-04-01.
//  Copyright (c) 2013 OANDA Corp. All rights reserved.
//

#import "OTAppDelegate.h"

#import "OTMainViewController.h"

@implementation OTAppDelegate

- (BOOL)application:(UIApplication *)application didFinishLaunchingWithOptions:(NSDictionary *)launchOptions
{
    self.window = [[UIWindow alloc] initWithFrame:[[UIScreen mainScreen] bounds]];
    // Override point for customization after application launch.
    self.mainViewController = [[OTMainViewController alloc] initWithNibName:@"OTMainViewController" bundle:nil];
    self.window.rootViewController = self.mainViewController;
    [self.window makeKeyAndVisible];
    return YES;
}

@end
