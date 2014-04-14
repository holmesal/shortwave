//
//  FCLiveBlurButton.h
//  Firechat
//
//  Created by Ethan Sherr on 3/17/14.
//  Copyright (c) 2014 Buildco. All rights reserved.
//

#import <UIKit/UIKit.h>

@interface FCLiveBlurButton : UIView

-(void)invalidatePressedLayer;

-(void)addTarget:(id)target action:(SEL)selector forControlEvents:(UIControlEvents)controlEvents;

-(void)setRadius:(CGFloat)radius;

@property (readonly, strong) UIButton *theButton;
@end
