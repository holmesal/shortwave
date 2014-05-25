//
//  ESShortbotOverlay.h
//  Shortwave
//
//  Created by Alonso Holmes on 5/20/14.
//  Copyright (c) 2014 Buildco. All rights reserved.
//

#import <Foundation/Foundation.h>

@protocol ESShortbotOverlayDelegate <NSObject>

// Delegate method for selecting a command
- (void)shortbotOverlay:(id)overlay didPickCommand:(NSString *)command;

@end

@interface ESShortbotOverlay : NSObject <UITableViewDataSource, UITableViewDelegate>

@property (nonatomic) UIView *theView;
@property (nonatomic, assign) id <ESShortbotOverlayDelegate> delegate;

- (ESShortbotOverlay *)initWithView:(UIView *)overlayView andColor:(UIColor *)color;

- (void)showOverlay;
- (void)pulseButton;

@end
