//
//  CocoaColaClassic.m
//  Shortwave
//
//  Created by Ethan Sherr on 8/9/14.
//  Copyright (c) 2014 Ethan Sherr. All rights reserved.
//

#import "CocoaColaClassic.h"
#import <UIKit/UIKit.h>


@implementation CocoaColaClassic


+(void)RegisterRemoteNotifications
{
//#ifdef __IPHONE_8_0
    if ([[UIApplication sharedApplication] respondsToSelector:@selector(registerUserNotificationSettings:)])
    {
        UIUserNotificationSettings *settings = [UIUserNotificationSettings settingsForTypes:(UIRemoteNotificationTypeBadge
                                                                                             |UIRemoteNotificationTypeSound
                                                                                             |UIRemoteNotificationTypeAlert) categories:nil];
        [[UIApplication sharedApplication] registerUserNotificationSettings:settings];
    } else
//#else
    {
        //register to receive notifications
        UIRemoteNotificationType myTypes = UIRemoteNotificationTypeBadge | UIRemoteNotificationTypeAlert | UIRemoteNotificationTypeSound;
        [[UIApplication sharedApplication] registerForRemoteNotificationTypes:myTypes];
    }
    
//#endif
}

+(BOOL)debug
{
    return DEBUG;
}

////        #if __IPHONE_8_0
//if (elems[0] == "8")
//{
//    println("iphone80")
//    let settings = UIUserNotificationSettings(forTypes: (.Badge | .Sound | .Alert) , categories: nil)
//    UIApplication.sharedApplication().registerUserNotificationSettings(settings)
//}
////        #else
//else
//{
//    println("whatever iphon7")
//    UIApplication.sharedApplication().registerForRemoteNotificationTypes((.Badge | .Sound | .Alert))
//}
////        #endif

@end
