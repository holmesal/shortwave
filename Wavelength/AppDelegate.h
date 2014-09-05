//
//  AppDelegate.h
//  Wavelength
//
//  Created by Ethan Sherr on 9/4/14.
//  Copyright (c) 2014 Ethan Sherr. All rights reserved.
//

#import <UIKit/UIKit.h>
#import "SWImageLoader.h"


@interface AppDelegate : UIResponder <UIApplicationDelegate>

@property (strong, nonatomic) UIWindow *window;
@property (strong, nonatomic) NSString *channelFromRemoteNotification;
@property (strong, nonatomic) SWImageLoader *imageLoader;

@end
