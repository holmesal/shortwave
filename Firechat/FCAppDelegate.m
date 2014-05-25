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
#import "FCLandingPageViewController.h"
#import <CoreData/CoreData.h>
#import "ESCoreDataController.h"
//#import "Beacon.h" //NSManagedObject (core data)
#import <FirebaseSimpleLogin/FirebaseSimpleLogin.h>
#import <Mixpanel/Mixpanel.h>
#import "Reachability.h"
#import "FCWallViewController.h"
#import <CoreLocation/CoreLocation.h>
#import <Crashlytics/Crashlytics.h>
//#import <ESImageLoader/ESImagßeLoader.h>


@interface FCAppDelegate () <UIAlertViewDelegate, CLLocationManagerDelegate>

@property (nonatomic) FirebaseSimpleLogin *authClient;
//@property (nonatomic) Reachability *hostReachability;
@property (nonatomic) Reachability *internetReachability;
//@property (nonatomic) Reachability *wifiReachability;
@property (nonatomic) NSArray *messageInputHints;
@property (strong, nonatomic) CLLocationManager *locationManager;

@end

@implementation FCAppDelegate
{
    CBPeripheralManager *_peripheralManager;
    BOOL _isAdvertising;
}

-(NSString*)getRandomMessageInputHint
{
    if (self.messageInputHints)
    {
        int index = esRandomNumberIn(0, self.messageInputHints.count);
        return [self.messageInputHints objectAtIndex:index];
    }
    
    return @"Say something...";
}

- (BOOL)application:(UIApplication *)application didFinishLaunchingWithOptions:(NSDictionary *)launchOptions
{
//    ESImageLoader *loader = [ESImageLoader sharedImageLoader];
//    
//    NSURL *url = [NSURL URLWithString:@"http://cdn3.raywenderlich.com/wp-content/uploads/2013/06/lib-header-search-2.png"];
//    [loader loadImage:url completionBlock:^(UIImage *image, BOOL wasInstantaneous)
//    {
//        NSLog(@"image %@ wasInstantaneous %d", image, wasInstantaneous);
//        
//    } errorBlock:nil];
    
     // Register as a location manager delegate
    self.locationManager = [[CLLocationManager alloc] init];
    self.locationManager.delegate = self;
    
    // Setup the owner
    // Can get owner later with [FCUser owner];
    [self authorizeWithFirebase];
    
    // Try to start the beacon (won't go if owner is null or owner.id is null)
    [self attemptToStartBeacon];
    
    
    // Fetch message prompts from firebase
    Firebase *fetchMessageHints = [[[Firebase alloc] initWithUrl:FIREBASE_ROOT_URL] childByAppendingPath:@"messageInputHints"];
    [fetchMessageHints observeSingleEventOfType:FEventTypeValue withBlock:^(FDataSnapshot *snapshot)
    {
        if (snapshot.value && snapshot.value != [NSNull null] && [snapshot.value isKindOfClass:[NSArray class]])
        {
            self.messageInputHints = snapshot.value;
        }
    } withCancelBlock:^(NSError *error)
    {
        NSLog(@"error = %@", error.localizedDescription);
    }];

    
    //notifications for when internet changes, handld in ESViewController, superclass to all UIViewControllers these days
    self.internetReachability = [Reachability reachabilityForInternetConnection];
    [self.internetReachability startNotifier];
    

        
    // Clear any outstanding local notifications
//    UILocalNotification *localNotification = [launchOptions objectForKey:UIApplicationLaunchOptionsLocalNotificationKey];
//    if (localNotification) {
//        
//        [application cancelAllLocalNotifications];
//    }

    
    // Register for push notifications
    [[UIApplication sharedApplication] registerForRemoteNotificationTypes:(UIRemoteNotificationTypeBadge | UIRemoteNotificationTypeSound | UIRemoteNotificationTypeAlert)];
    
    // Listen for updates to the number of users and set the app icon
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(updateBadge:) name:kTransponderEventCountUpdated object:nil];

    
    // Add mixpanel
    #define MIXPANEL_TOKEN @"8a3d5ae8ce286cefdff58b462b124250"
    
    // Initialize the library with your
    // Mixpanel project token, MIXPANEL_TOKEN
    [Mixpanel sharedInstanceWithToken:MIXPANEL_TOKEN];
    
    // Start crashlytics
    [Crashlytics startWithAPIKey:@"4a71d4033d33d194e246ada67acce08c24c06e80"];


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
    

    [self.authClient loginAnonymouslywithCompletionBlock:^(NSError* error, FAUser* user) {
        if (error != nil)
        {
            //wait for internet and try again!
            NSLog(@"error = %@", error.localizedDescription);
            //loop itself every 1.5 seconds
            [self performSelector:_cmd withObject:nil afterDelay:1.5];
            
        } else
        {
            owner.fuser = user; // We are now logged in
            Firebase* authRef = [owner.rootRef childByAppendingPath:@".info/authenticated"];
            __block FirebaseHandle isAuthenticatedHandle = [authRef observeEventType:FEventTypeValue withBlock:^(FDataSnapshot* snap)
            {
                BOOL isAuthenticated = [snap.value boolValue];
//                NSLog(@"isAuthenticated = %@", isAuthenticated ? @"YES" : @"NO");
                if (!isAuthenticated)
                {
                    [authRef removeObserverWithHandle:isAuthenticatedHandle];
                    owner.fuser = nil;
                    [self authorizeWithFirebase];
                }
            }];
        }
    }];
}

- (void)attemptToStartBeacon
{
    FCUser *owner = [FCUser owner];
    if (owner && owner.id) {
//        NSLog(@"The user has an ID - starting the transponder!");
        [owner.beacon startAwesome];
    }
}

//-(void)alertView:(UIAlertView *)alertView clickedButtonAtIndex:(NSInteger)buttonIndex
//{
//    if (buttonIndex)
//    {//try again!
//        [self authorizeWithFirebase];
//    }
//}

- (void)updateBadge:(NSNotification *)note
{
    NSInteger count = [[note.userInfo objectForKey:@"count"] integerValue];
    [[UIApplication sharedApplication] setApplicationIconBadgeNumber:count];
}

// Delegation methods
- (void)application:(UIApplication *)app didRegisterForRemoteNotificationsWithDeviceToken:(NSData *)devToken {
    // Set the token on firebase via the user object

    [[FCUser owner] sendProviderDeviceToken:devToken];
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
    
    [self doAuth];
    
    FCUser *owner = [FCUser owner];
    if (owner)
    {
        BOOL stackIsActive = owner.beacon.stackIsRunning;
        NSLog(@"%d" ,stackIsActive);
        
        if (!stackIsActive)
        {
            UINavigationController *navContr = (UINavigationController *)self.window.rootViewController;
            if (navContr.viewControllers.count > 1)
            {
                FCLandingPageViewController *lvc = nil;// (FCLandingPageViewController*)[navContr.viewControllers objectAtIndex:0];
                
                for (UIViewController *vc in navContr.viewControllers)
                {
                    if ([vc isKindOfClass:[FCLandingPageViewController class]])
                    {
                        lvc = (FCLandingPageViewController*)vc;
                        break;
                    }
                }
                [lvc resetAsNewAnimated];
                [navContr popToRootViewControllerAnimated:NO];
            }
        }
//        if (!owner.beacon.peripheralManagerIsRunning)
//        {
//            [owner.beacon startBroadcasting];
//            [owner.beacon startDetecting];
//            [[FCUser owner].beacon chirpBeacon];
//        } else
//        {
////            [self continueWithBluetooth:nil];
//            return;
//        }
    }
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
        
#pragma GCC diagnostic ignored "-Wundeclared-selector"
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

-(NetworkStatus)getNetworkStatus
{
    return self.internetReachability.currentReachabilityStatus;
}
//called right away, to make sure they are logged in correctly
-(void)internetStateChanged:(NSNotification*)notif
{
    Reachability *reachability = notif.object;
    FCUser *user = [FCUser owner];
    if (reachability.currentReachabilityStatus != NotReachable && !user.fuser)
    {
        [self doAuth];
    }
}
-(void)doAuth
{
    [self.authClient loginAnonymouslywithCompletionBlock:^(NSError* error, FAUser* user)
     {
         if (error != nil)
         {
             NSLog(@"failed to log user in again!");
         } else
         {
             [FCUser owner].fuser = user; // We are now logged in
         }
     }];
}

// Called when a beacon region is entered
- (void)locationManager:(CLLocationManager *)manager didDetermineState:(CLRegionState)state forRegion:(CLRegion *)region
{
    NSLog(@"Woke up via app delegate location manager callback");
}


@end
