//
//  ESShortbotOverlay.h
//  Shortwave
//
//  Created by Alonso Holmes on 5/20/14.
//  Copyright (c) 2014 Buildco. All rights reserved.
//

#import <Foundation/Foundation.h>

@interface ESShortbotOverlay : NSObject <UITableViewDataSource, UITableViewDelegate>

@property (nonatomic) UIView *theView;

- (ESShortbotOverlay *)initWithView:(UIView *)overlayView;

- (void)showOverlay;

@end
