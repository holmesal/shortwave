//
//  ESApplication.h
//  Firechat
//
//  Created by Ethan Sherr on 3/3/14.
//  Copyright (c) 2014 Buildco. All rights reserved.
//

#import <UIKit/UIKit.h>

@interface ESApplication : UIApplication
@end
//for capturing touches on a keyboard, to flash profile icons
@protocol ESApplicationDelegate <UIApplicationDelegate>
//- (void)application:(ESApplication *)application willSendTouchEvent:(UIEvent *)event;
@end
