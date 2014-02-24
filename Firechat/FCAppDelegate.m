//
//  FCAppDelegate.m
//  Firechat
//
//  Created by Alonso Holmes on 12/22/13.
//  Copyright (c) 2013 Buildco. All rights reserved.
//

#define UIColorFromRGB(rgbValue) [UIColor colorWithRed:((float)((rgbValue & 0xFF0000) >> 16))/255.0 green:((float)((rgbValue & 0xFF00) >> 8))/255.0 blue:((float)(rgbValue & 0xFF))/255.0 alpha:1.0]

#import "FCAppDelegate.h"
#import <CoreBluetooth/CoreBluetooth.h>
#import "FCLandingViewController.h"
#import "FCSignupViewController.h"

@implementation FCAppDelegate
{
    CBPeripheralManager *_peripheralManager;
    BOOL _isAdvertising;
}

- (BOOL)application:(UIApplication *)application didFinishLaunchingWithOptions:(NSDictionary *)launchOptions
{
    // Override point for customization after application launch.
    // init the user object
    self.owner = [[FCUser alloc] initAsOwner];
    
    // Set navigation bar style
//    [[UINavigationBar appearance] setBarTintColor:UIColorFromRGB(0x00DA6D)]; // 0x00CF69   more green -> 0x56BD54
    [[UINavigationBar appearance] setBarTintColor:[UIColor clearColor]]; // 0x00CF69   more green -> 0x56BD54
    [[UIApplication sharedApplication] setStatusBarStyle:UIStatusBarStyleLightContent];
    [[UINavigationBar appearance] setTintColor:[UIColor whiteColor]];
    [[UINavigationBar appearance] setTitleTextAttributes:@{
                                                          NSForegroundColorAttributeName: UIColorFromRGB(0xffffff)
                                                          }];
    
    
    // Skip the login flow if this isn't the first run
//    NSUserDefaults *prefs = [NSUserDefaults standardUserDefaults];
//    NSString *username = [prefs stringForKey:@"username"];
//    if (self.owner.id) {
//        UIViewController *wallController=[[UIStoryboard storyboardWithName:@"main" bundle:nil] instantiateViewControllerWithIdentifier:@"FCWallViewController"];
//        UINavigationController *navController = [[UINavigationController alloc] initWithRootViewController:wallController];
//        self.window.rootViewController = navController;
//    } else {
//        FCSignupViewController *signupController=[[UIStoryboard storyboardWithName:@"main" bundle:nil] instantiateViewControllerWithIdentifier:@"FCSignupViewController"];
//        UINavigationController *navController = [[UINavigationController alloc] initWithRootViewController:signupController];
//        self.window.rootViewController = navController;
//    }
    
    


//    NSLog(@"User %@",self.owner);
    
    return YES;
}
							
- (void)applicationWillResignActive:(UIApplication *)application
{
    // Sent when the application is about to move from active to inactive state. This can occur for certain types of temporary interruptions (such as an incoming phone call or SMS message) or when the user quits the application and it begins the transition to the background state.
    // Use this method to pause ongoing tasks, disable timers, and throttle down OpenGL ES frame rates. Games should use this method to pause the game.
}

- (void)applicationDidEnterBackground:(UIApplication *)application
{
    // Use this method to release shared resources, save user data, invalidate timers, and store enough application state information to restore your application to its current state in case it is terminated later. 
    // If your application supports background execution, this method is called instead of applicationWillTerminate: when the user quits.
}

- (void)applicationWillEnterForeground:(UIApplication *)application
{
    // Called as part of the transition from the background to the inactive state; here you can undo many of the changes made on entering the background.
}

- (void)applicationDidBecomeActive:(UIApplication *)application
{
    // Restart any tasks that were paused (or not yet started) while the application was inactive. If the application was previously in the background, optionally refresh the user interface.
}

- (void)applicationWillTerminate:(UIApplication *)application
{
    // Called when the application is about to terminate. Save data if appropriate. See also applicationDidEnterBackground:.
}

@end
