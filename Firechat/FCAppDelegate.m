//
//  FCAppDelegate.m
//  Firechat
//
//  Created by Alonso Holmes on 12/22/13.
//  Copyright (c) 2013 Buildco. All rights reserved.
//

#define kAlwaysLocalUpdateWhenEncounteringAnyBeacon 0

//#define UIColorFromRGB(rgbValue) [UIColor colorWithRed:((float)((rgbValue & 0xFF0000) >> 16))/255.0 green:((float)((rgbValue & 0xFF00) >> 8))/255.0 blue:((float)(rgbValue & 0xFF))/255.0 alpha:1.0]

#import "FCAppDelegate.h"
#import <CoreBluetooth/CoreBluetooth.h>
#import "FCLandingViewController.h"
#import "FCSignupViewController.h"
#import <CoreData/CoreData.h>
#import "ESCoreDataController.h"
#import "Beacon.h" //NSManagedObject (core data)
#import <FirebaseSimpleLogin/FirebaseSimpleLogin.h>
#import <Mixpanel/Mixpanel.h>

@interface FCAppDelegate () <UIAlertViewDelegate>

@property (nonatomic) FirebaseSimpleLogin *authClient;

@end

@implementation FCAppDelegate
{
    CBPeripheralManager *_peripheralManager;
    BOOL _isAdvertising;
}

- (BOOL)application:(UIApplication *)application didFinishLaunchingWithOptions:(NSDictionary *)launchOptions
{
    //clear local notifications
    
    [[UIApplication sharedApplication] setApplicationIconBadgeNumber:0];
    
    UILocalNotification *localNotification = [launchOptions objectForKey:UIApplicationLaunchOptionsLocalNotificationKey];
    if (localNotification) {
        
        [application cancelAllLocalNotifications];
    }
    
    [self authorizeWithFirebase]; //creates owner

    
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(beaconsDiscovered:) name:@"Beacons Added" object:nil];
    
    // Set navigation bar style
//    [[UINavigationBar appearance] setBarTintColor:[UIColor clearColor]]; // 0x00CF69   more green -> 0x56BD54
//    [[UIApplication sharedApplication] setStatusBarStyle:UIStatusBarStyleLightContent];
//    [[UINavigationBar appearance] setTintColor:[UIColor whiteColor]];
//    [[UINavigationBar appearance] setTitleTextAttributes:@{
//                                                          NSForegroundColorAttributeName: UIColorFromRGB(0xffffff)
//                                                          }];
    
    // Register for push notifications
    [[UIApplication sharedApplication] registerForRemoteNotificationTypes:(UIRemoteNotificationTypeBadge | UIRemoteNotificationTypeSound | UIRemoteNotificationTypeAlert)];
    
    
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
    
    
    // Add mixpanel
    #define MIXPANEL_TOKEN @"8a3d5ae8ce286cefdff58b462b124250"
    
    // Initialize the library with your
    // Mixpanel project token, MIXPANEL_TOKEN
    [Mixpanel sharedInstanceWithToken:MIXPANEL_TOKEN];

    
    

    return YES;
}

-(void)authorizeWithFirebase
{
    FCUser *owner = [FCUser owner];
    if (!owner)
    {
        owner = [FCUser createOwner];
    }
    
    if (!self.authClient)
    {
        self.authClient = [[FirebaseSimpleLogin alloc] initWithRef:owner.rootRef];
    }
    

//    if (!owner.fuser)
//    {
        [self.authClient loginAnonymouslywithCompletionBlock:^(NSError* error, FAUser* user) {
            if (error != nil)
            {
                NSLog(@"loginAnonymouslywithCompletionBlock%@", error.localizedDescription);
                UIAlertView *alert = [[UIAlertView alloc] initWithTitle:@"Ahh!" message:error.localizedDescription delegate:self cancelButtonTitle:@"cancel" otherButtonTitles:@"try again", nil];
                [alert show];
                // There was an error logging in to this account
            } else
            {
                
                owner.fuser = user; // We are now logged in
            }
        }];
//    } else
//    {
//        
//    }

}

-(void)alertView:(UIAlertView *)alertView clickedButtonAtIndex:(NSInteger)buttonIndex
{
    if (buttonIndex)
    {//try again!
        [self authorizeWithFirebase];
    }
}

// Delegation methods
- (void)application:(UIApplication *)app didRegisterForRemoteNotificationsWithDeviceToken:(NSData *)devToken {
    // Set the token on firebase via the user object
    [[FCUser owner] sendProviderDeviceToken:devToken]; // custom method
}

- (void)application:(UIApplication *)app didFailToRegisterForRemoteNotificationsWithError:(NSError *)err {
    NSLog(@"Error in registration. Error: %@", err);
}

- (void)application:(UIApplication *)application didReceiveRemoteNotification:(NSDictionary *)userInfo
{
    NSLog(@"Got remote notification!");
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
    [[UIApplication sharedApplication] setApplicationIconBadgeNumber:0];
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

#pragma mark custom touches captured
- (void)application:(ESApplication *)application willSendTouchEvent:(UIEvent *)event
{
//    NSLog(@"touch event: %@", event);
    
    if (event.type == UIEventTypeTouches)
    {
        id rootContr = self.window.rootViewController;
        
        NSArray *viewControllers = @[rootContr];
        
        if ([rootContr isKindOfClass:[UINavigationController class] ])
        {
            viewControllers = ((UINavigationController*)rootContr).viewControllers;
        }
        
        for (UIViewController *vc in viewControllers)
        {
            if ([vc respondsToSelector:@selector(receiveTouchEvent:)])
            {
                [vc performSelector:@selector(receiveTouchEvent:) withObject:event];
            }
        }
    }
    // Reset your idle timer here.
}
#pragma mark custom touches captured end


#pragma mark discover beacons
-(void)beaconsDiscovered:(NSNotification*)notification
{
    NSArray *newBeacons = notification.object;
    
    NSManagedObjectContext *managedObjectContext = [[ESCoreDataController sharedInstance] masterManagedObjectContext];
    
    [managedObjectContext performBlock:^{
    
        BOOL hasEncounteredNewBeacon = NO;
        for (CLBeacon *beacon in newBeacons)
        {
            NSString *majorMinor = [NSString stringWithFormat:@"%d:%d", beacon.major.intValue, beacon.minor.intValue];
            NSFetchRequest *fetch = [NSFetchRequest fetchRequestWithEntityName:@"Beacon"];
            fetch.predicate = [NSPredicate predicateWithFormat:@"(SELF.identifier == %@)", majorMinor];
            
            NSError *error = nil;
            NSArray *fetchedResults = [managedObjectContext executeFetchRequest:fetch error:&error];
            if (error)
            {
                NSLog(@"fetch beacon request error: %@", error.localizedDescription);
            }
            
            //if I have encountered this beacon, nevermind...  else add the beacon and flag hasEncounteredNewBeacon
            if (!fetchedResults.count)
            {
                hasEncounteredNewBeacon = YES;
                Beacon *beacon = [NSEntityDescription insertNewObjectForEntityForName:@"Beacon" inManagedObjectContext:managedObjectContext];
                beacon.identifier = majorMinor;
            }
            
        }
        
        //Change this bellow to see new people
        if (hasEncounteredNewBeacon || kAlwaysLocalUpdateWhenEncounteringAnyBeacon) //|| YES)
        {
            //now it is time to do a local notification!
            UILocalNotification *localNotification = [[UILocalNotification alloc] init];
            
            localNotification.fireDate = [NSDate date];
            localNotification.alertBody = @"A new person is nearby!";
            localNotification.timeZone = [NSTimeZone defaultTimeZone];
            
            [[UIApplication sharedApplication] scheduleLocalNotification:localNotification];
            
            [managedObjectContext save:nil];
        }
        
        
    }];
    
}
#pragma mark discover beacons end
@end
