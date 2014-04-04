//
//  ESUserPMCell.m
//  Earshot
//
//  Created by Ethan Sherr on 4/3/14.
//  Copyright (c) 2014 Buildco. All rights reserved.
//

#import "ESUserPMCell.h"

@interface ESUserPMCell ()

@property (weak, nonatomic) IBOutlet UIView *circleView;
@property (weak, nonatomic) IBOutlet UIImageView *profileIcon;

@property (nonatomic) UIButton *button;

@property (nonatomic) CALayer *circleLayer;

@end

@implementation ESUserPMCell
@synthesize circleLayer;
@synthesize button;
-(void)awakeFromNib
{
    [self initialize];
}
-(void)initialize
{
    CGFloat radius = self.circleView.frame.size.width*0.5f;
    circleLayer = [CALayer layer];
    [circleLayer setBackgroundColor:[UIColor blackColor].CGColor];
    [circleLayer setBorderColor:[UIColor clearColor].CGColor];
    [circleLayer setCornerRadius:radius];
    
    
    CGRect frame = CGRectMake(-0.0f, -0.0f, radius*2, radius*2);
    frame.origin.x += (self.circleView.frame.size.width-frame.size.width)*0.5f;
    frame.origin.y += (self.circleView.frame.size.height-frame.size.height)*0.5f;
    [circleLayer setFrame:frame];

    [self.circleView setBackgroundColor:[UIColor clearColor]];
    [self.circleView.layer insertSublayer:circleLayer atIndex:0];
    
    [self.profileIcon setContentMode:UIViewContentModeScaleAspectFit];
    
    //button
    button = [UIButton buttonWithType:UIButtonTypeCustom];
    [button setBackgroundColor:[UIColor clearColor]];
    [button setFrame:self.bounds];
    [button addTarget:self action:@selector(select) forControlEvents:UIControlEventTouchUpInside];
    [self addSubview:button];
    
    
    [self setSelectionStyle:UITableViewCellSelectionStyleNone];
    
}

-(void)select
{
//    id owner = ((UITableView*)self.superview).dataSource;
    id tableView = (self.superview.superview);
    id owner = ((UITableView*)tableView).dataSource;
    if ([owner respondsToSelector:@selector(didSelectPmWithUserAtIndex:)])
    {
        [owner performSelector:@selector(didSelectPmWithUserAtIndex:) withObject:[NSNumber numberWithInt:self.tag]];
    }
}

-(void)setColor:(NSString*)color andImage:(NSString*)image
{
    [self.circleLayer setBackgroundColor:[UIColor colorWithHexString:color].CGColor];
    [self.profileIcon setImage:[UIImage imageNamed:image]];
}

-(void)transitionToColor:(NSString*)color andImage:(NSString*)image
{
    UIImageView *secondImageView = [[UIImageView alloc] initWithFrame:self.profileIcon.frame];
    [secondImageView setContentMode:UIViewContentModeScaleAspectFit];
    [secondImageView setImage:[UIImage imageNamed:image]];
    
    secondImageView.alpha = 0.0f;
    [self.profileIcon.superview addSubview:secondImageView];
    
    [UIView animateWithDuration:1.2f delay:0.0f usingSpringWithDamping:1.2f initialSpringVelocity:0.0f options:UIViewAnimationOptionCurveLinear animations:^
    {
        self.circleLayer.backgroundColor = [UIColor colorWithHexString:color].CGColor;
        secondImageView.alpha = 1.0f;
        self.profileIcon.alpha = 0.0f;
    } completion:^(BOOL finished)
    {
        [self.profileIcon removeFromSuperview];
        self.profileIcon = secondImageView;
    }];
}

@end
