//
//  AppDelegate.m
//  Wavelength
//
//  Created by Ethan Sherr on 9/4/14.
//  Copyright (c) 2014 Ethan Sherr. All rights reserved.
//

#import "AppDelegate.h"
#import <Crashlytics/Crashlytics.h>
#import <Mixpanel/Mixpanel.h>
#import "ObjcConstants.h"
#import <AVFoundation/AVFoundation.h>
#import <Firebase/Firebase.h>

@interface AppDelegate ()


@end

@implementation AppDelegate
@synthesize channelFromRemoteNotification;
@synthesize window;


@synthesize imageLoader;
-(SWImageLoader*)imageLoader
{
    if (!imageLoader)
    {
        imageLoader = [[SWImageLoader alloc] initWithConcurrent:5];
    }
    return imageLoader;
}

-(BOOL)application:(UIApplication *)application didFinishLaunchingWithOptions:(NSDictionary *)launchOptions
{
    [Crashlytics startWithAPIKey:@"4a71d4033d33d194e246ada67acce08c24c06e80"];
    [Mixpanel sharedInstanceWithToken:Objc_kMixpanelToken];
    
    //audio session
    AVAudioSession *audioSession = [AVAudioSession sharedInstance];
    [audioSession setCategory:AVAudioSessionCategoryAmbient error:nil];
    
    [UINavigationBar appearance].titleTextAttributes = @{NSForegroundColorAttributeName : [UIColor whiteColor]};
    
    [UIApplication sharedApplication].statusBarStyle = UIStatusBarStyleLightContent;
    
    if (launchOptions)
    {
        NSDictionary *notificationData = launchOptions[UIApplicationLaunchOptionsRemoteNotificationKey];
        if (notificationData)
        {
            [self openWithRemoteNotification:notificationData];
        }
    }
    return YES;
}

- (NSString *)hexStringFromData:(NSData *)data
{
	NSMutableString *hex = [NSMutableString stringWithCapacity:[data length]*2];
	[data enumerateByteRangesUsingBlock:^(const void *bytes, NSRange byteRange, BOOL *stop)
     {
         const unsigned char *dataBytes = (const unsigned char *)bytes;
         for (NSUInteger i = byteRange.location; i < byteRange.length; ++i)
         {
             [hex appendFormat:@"%02x", dataBytes[i]];
         }
     }];
	return hex;
}

-(void)application:(UIApplication *)application didRegisterForRemoteNotificationsWithDeviceToken:(NSData *)deviceToken
{
    NSUserDefaults *prefs = [NSUserDefaults standardUserDefaults];
    
    NSString *tokenString = [self hexStringFromData:deviceToken];
    
    NSString *userId = [prefs objectForKey:Objc_kNSUSERDEFAULTS_KEY_userId];
    NSString *url = [NSString stringWithFormat:@"%@users/%@/devices/", Objc_kROOT_FIREBASE, userId];
    
    __block Firebase *saveTokenFirebase = nil;
    
    NSString *knownDeviceTokenKey = [prefs objectForKey:Objc_kNSUSERDEFAULTS_KEY_firebaseKeyForDeviceToken];
    if (knownDeviceTokenKey && [knownDeviceTokenKey isKindOfClass:[NSString class] ])
    {
        saveTokenFirebase = [[Firebase alloc] initWithUrl:[NSString stringWithFormat:@"%@%@", url, knownDeviceTokenKey]];
        [saveTokenFirebase setValue:
         @{@"type": @"ios",
           @"token": tokenString,
           @"sandbox": [NSNumber numberWithBool:Objc_kSandbox]
           
           } withCompletionBlock:^(NSError *error, Firebase *firebase)
        {
            if (error)
            {
                NSLog(@"token saving with error %@", error.localizedDescription);
            }
        }];
        
        [prefs setObject:saveTokenFirebase.name forKey:Objc_kNSUSERDEFAULTS_KEY_firebaseKeyForDeviceToken];
        [prefs synchronize];
    } else
    {
        Firebase *loadDevices = [[Firebase alloc] initWithUrl:url];
        [loadDevices observeSingleEventOfType:FEventTypeValue withBlock:^(FDataSnapshot* snapshot)
        {
            NSDictionary *devicesDict = snapshot.value;
            if (devicesDict && [devicesDict isKindOfClass:[NSDictionary class]])
            {
                for (NSString *keyName in [devicesDict allKeys])
                {
                    NSDictionary *device = devicesDict[keyName];
                    if (device && [device isKindOfClass:[NSDictionary class]])
                    {
                        NSString *optionalToken = device[@"token"];
                        
                        if (optionalToken && [optionalToken isKindOfClass:[NSString class]] &&
                            [optionalToken isEqualToString:tokenString])
                        {
                            [prefs setObject:keyName forKey:Objc_kNSUSERDEFAULTS_KEY_firebaseKeyForDeviceToken];
                            [prefs synchronize];
                            return;
                        }
                    }
                }
            }
            
            NSLog(@"no token found!");
            saveTokenFirebase = [[[Firebase alloc] initWithUrl:url] childByAutoId];
            [saveTokenFirebase setValue:@{@"type": @"ios",
                                         @"token": tokenString,
                                          @"sandbox": [NSNumber numberWithBool:Objc_kSandbox]} withCompletionBlock:^(NSError *error, Firebase *firebase)
            {
                if (error)
                {
                    NSLog(@"token saving error is %@", error);
                }
            }];
            
            [prefs setObject:saveTokenFirebase.name forKey:Objc_kNSUSERDEFAULTS_KEY_firebaseKeyForDeviceToken];
            [prefs synchronize];
            
            
        }];
    }
}

-(void)application:(UIApplication *)application didFailToRegisterForRemoteNotificationsWithError:(NSError *)error
{
    NSLog(@"failed to register for remote notifications %@", error);
}

-(void)application:(UIApplication *)application didReceiveRemoteNotification:(NSDictionary *)userInfo
{
    [UIApplication sharedApplication].applicationIconBadgeNumber = 0;
    [[UIApplication sharedApplication] cancelAllLocalNotifications];
    
    if ([UIApplication sharedApplication].applicationState == UIApplicationStateActive)
    {
        NSLog(@"##notification## received by running app");
    } else
    {
        NSLog(@"##notification## opened from notification \n%@", userInfo);
        [self openWithRemoteNotification:userInfo ];
    }
}

-(void)openWithRemoteNotification:(NSDictionary*)userInfo
{
    NSString *channel = userInfo[@"channel"];
    if (channel && [channel isKindOfClass:[NSString class]])
    {
        channelFromRemoteNotification = channel;
        
        NSLog(@"listen for channel %@", channel);
        UINavigationController *navigationController = (UINavigationController *)self.window.rootViewController;
        
        NSArray *viewControllers = navigationController.viewControllers;
        if (viewControllers.count > 2)
        {
            viewControllers = @[viewControllers[0], viewControllers[1]];
            navigationController.viewControllers = viewControllers;
        }
        [[NSNotificationCenter defaultCenter] postNotificationName:Objc_kRemoteNotification_JoinChannel object:self];
    }
}


@end
