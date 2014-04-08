//
//  FCAppDelegate.m
//  Firechat
//
//  Created by Alonso Holmes on 12/22/13.
//  Copyright (c) 2013 Buildco. All rights reserved.
//

#define kAlwaysLocalUpdateWhenEncounteringAnyBeacon 1

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
#import "Reachability.h"

@interface FCAppDelegate () <UIAlertViewDelegate>

@property (nonatomic) FirebaseSimpleLogin *authClient;
@property (nonatomic) Reachability *hostReachability;
@property (nonatomic) Reachability *internetReachability;
@property (nonatomic) Reachability *wifiReachability;

@end

@implementation FCAppDelegate
{
    CBPeripheralManager *_peripheralManager;
    BOOL _isAdvertising;
}

- (BOOL)application:(UIApplication *)application didFinishLaunchingWithOptions:(NSDictionary *)launchOptions
{
    //clear local notifications
    
    //EThan was testing the Identifiers
    BOOL noConflicts = YES;
    uint32_t max = 4294967295; //== 2^32

    
    
//    for (uint32_t i = 0; i <= max; i+= 1)
//    {
//        unsigned char byte1, byte2, byte3, byte4;
//        esDecomposeIntToMajorMinor(i, &byte1, &byte2, &byte3, &byte4);
//        
//        uint32_t value;
//        esRecomposeMajorMinorToInt(byte1, byte2, byte3, byte4, &value);
//
//        
//        if (value != i)
//        {
//            NSLog(@"WARNING!");
//            noConflicts = NO;
//            NSLog(@"decomposing %d", i);
//            NSLog(@"%d\t%d\t%d\t%d", byte1, byte2, byte3, byte4);
//            NSLog(@"recompose = %d", value);
//            NSLog(@"\n");
//        }
//        
//        if (!(i%10000))
//        {
//            NSLog(@"decomposing %d", i);
//            NSLog(@"%d\t%d\t%d\t%d", byte1, byte2, byte3, byte4);
//            NSLog(@"recompose = %d", value);
//            NSLog(@"\n");
//        }
//    }
//    
//    NSLog(@"noConflicts ? %@", (noConflicts ? @"None!" : @"CONFCLIT!"));
    

    //ok
    for (uint32_t identifier = 2000000000; identifier <= max; identifier+= 1)
    {
        uint16_t major, minor;
        esDecomposeIdToMajorMinor(identifier, &major, &minor);
        
        
        uint32_t value;
        esRecomposeMajorMinorToId(major, minor, &value);
        
        
        if (value != identifier)
        {
            NSLog(@"WARNING!");
            noConflicts = NO;
            NSLog(@"decomposing %d", identifier);
            NSLog(@"%d\t%d", major, minor);
            NSLog(@"recompose = %d", value);
            NSLog(@"\n");
        }

        if (!(identifier%100000000))
        {
            NSLog(@"decomposing %d", identifier);
            NSLog(@"%d\t%d", major, minor);
            NSLog(@"recompose = %d", value);
            NSLog(@"\n");
        }
    }
    
    NSLog(@"noConflicts ? %@", (noConflicts ? @"None!" : @"CONFCLIT!"));

    
    

    
    
    
    
    [[UIApplication sharedApplication] setApplicationIconBadgeNumber:0];
    

    
    //generates notifications kReachabilityChangedNotification
    {
        [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(internetChangeEvent:) name:kReachabilityChangedNotification object:nil];

        //generates notifications kReachabilityChangedNotification
        {
//            //Change the host name here to change the server you want to monitor.
//            NSString *remoteHostName = @"www.apple.com";
//            
//            self.hostReachability = [Reachability reachabilityWithHostName:remoteHostName];
//            [self.hostReachability startNotifier];
            
            self.internetReachability = [Reachability reachabilityForInternetConnection];
            [self.internetReachability startNotifier];
            
            self.wifiReachability = [Reachability reachabilityForLocalWiFi];
            [self.wifiReachability startNotifier];
        }
    }
        
    
    UILocalNotification *localNotification = [launchOptions objectForKey:UIApplicationLaunchOptionsLocalNotificationKey];
    if (localNotification) {
        
        [application cancelAllLocalNotifications];
    }
    
    [self authorizeWithFirebase]; //creates owner

    
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(beaconsDiscovered:) name:@"Beacons Added" object:nil];
    
    
    // Register for push notifications
    [[UIApplication sharedApplication] registerForRemoteNotificationTypes:(UIRemoteNotificationTypeBadge | UIRemoteNotificationTypeSound | UIRemoteNotificationTypeAlert)];
    
    

    
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
//    [[NSNotificationCenter defaultCenter] postNotificationName:@"chirpBeacon" object:self];
    // Called as part of the transition from the background to the inactive state; here you can undo many of the changes made on entering the background.
}

- (void)applicationDidBecomeActive:(UIApplication *)application
{
    // Restart any tasks that were paused (or not yet started) while the application was inactive. If the application was previously in the background, optionally refresh the user interface.
    [[NSNotificationCenter defaultCenter] postNotificationName:@"chirpBeacon" object:self];
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


#pragma mark reachability callback (internte availability)
-(void)internetChangeEvent:(NSNotification*)notification
{
    
    Reachability* curReach = [notification object];
    switch (curReach.currentReachabilityStatus)
    {
        case NotReachable:
        {
            NSLog(@"NotReachable");
        }
        break;
            
        case ReachableViaWiFi:
        {
            NSLog(@"ReachableViaWiFi");
        }
        break;
            
        case ReachableViaWWAN:
        {
            NSLog(@"ReachableViaWWAN");
        }
        break;
    }
}




@end
