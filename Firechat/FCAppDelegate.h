//
//  FCAppDelegate.h
//  Firechat
//
//  Created by Alonso Holmes on 12/22/13.
//  Copyright (c) 2013 Buildco. All rights reserved.
//

#import <UIKit/UIKit.h>
#import "FCUser.h"
#import "ESApplication.h"
#import "Reachability.h"
@interface FCAppDelegate : UIResponder <ESApplicationDelegate>

@property (strong, nonatomic) UIWindow *window;
-(NetworkStatus)getNetworkStatus;

-(NSString*)getRandomMessageInputHint;

@end
