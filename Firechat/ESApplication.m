//
//  ESApplication.m
//  Firechat
//
//  Created by Ethan Sherr on 3/3/14.
//  Copyright (c) 2014 Buildco. All rights reserved.
//

#import "ESApplication.h"

@implementation ESApplication

- (void)sendEvent:(UIEvent *)event
{
    if (event.type == UIEventTypeTouches)
    {
        id<ESApplicationDelegate> delegate = (id<ESApplicationDelegate>)self.delegate;
        [delegate application:self willSendTouchEvent:event];
    }
    [super sendEvent:event];
}

@end
