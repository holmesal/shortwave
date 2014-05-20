//
//  SWSwapUserStateCell.m
//  Shortwave
//
//  Created by Ethan Sherr on 5/20/14.
//  Copyright (c) 2014 Buildco. All rights reserved.
//

#import "SWSwapUserStateCell.h"

@interface SWSwapUserStateCell ()

@property (weak, nonatomic) IBOutlet UIView *fromView;
@property (weak, nonatomic) IBOutlet UIView *toView;

@property (weak, nonatomic) IBOutlet UIImageView *fromImageView;
@property (weak, nonatomic) IBOutlet UIImageView *toImageView;

@property (nonatomic) CALayer *fromCircle;
@property (nonatomic) CALayer *toCircle;


@property (nonatomic) CGRect originalFromRect;
@property (nonatomic) CGRect originalToRect;

@property (weak, nonatomic) IBOutlet UIImageView *arrowImageView;

@end

@implementation SWSwapUserStateCell
@synthesize fromCircle, toCircle;
@synthesize originalFromRect, originalToRect, fromView, toView, fromImageView, toImageView;

-(void)setMessage:(ESSwapUserStateMessage *)swapUserStateMessage
{
    [self setFromColor:swapUserStateMessage.fromColor andIcon:swapUserStateMessage.fromIcon toColor:swapUserStateMessage.toColor andIcon:swapUserStateMessage.toIcon];
}

-(void)awakeFromNib
{
    [self initialize];
}

-(void)initialize
{
    CGFloat radius = 15;
    
    [self.fromImageView setContentMode:UIViewContentModeScaleAspectFit];
    [self.toImageView setContentMode:UIViewContentModeScaleAspectFit];
    
    fromCircle = [CALayer layer];
    [fromCircle setBackgroundColor:[UIColor blackColor].CGColor];
    [fromCircle setBorderColor:[UIColor clearColor].CGColor];
    [fromCircle setCornerRadius:radius];
    
    toCircle = [CALayer layer];
    [toCircle setBackgroundColor:[UIColor blackColor].CGColor];
    [toCircle setBorderColor:[UIColor clearColor].CGColor];
    [toCircle setCornerRadius:radius];
    
    CGRect frame = CGRectMake(-0.0f, -0.0f, radius*2+1, radius*2+1);
    frame.origin.x += (self.fromView.frame.size.width-frame.size.width)*0.5f;
    frame.origin.y += (self.fromView.frame.size.height-frame.size.height)*0.5f;
    [fromCircle setFrame:frame];
    [toCircle setFrame:frame];
    
    //    [self.fromView.layer addSublayer:fromCircle];
    //    [self.toView.layer addSublayer:toCircle];
    
    [self.fromView.layer insertSublayer:fromCircle atIndex:0];
    [self.toView.layer insertSublayer:toCircle atIndex:0];
    
    self.originalFromRect = self.fromView.frame;
    self.originalToRect = self.toView.frame;
    
}

-(void)setFromColor:(NSString*)fromClr andIcon:(NSString*)fromIcn toColor:(NSString*)toClr andIcon:(NSString*)toIcn
{
    self.toView.frame = self.originalToRect;
    self.fromView.frame = self.originalFromRect;
    self.arrowImageView.alpha = 1.0f;
    
    UIColor *fromColor = [UIColor colorWithHexString:fromClr];
    UIColor *toColor = [UIColor colorWithHexString:toClr];
    
    [fromCircle setBackgroundColor:fromColor.CGColor ];
    [toCircle setBackgroundColor:toColor.CGColor ];
    
    UIImage *fromIcon = [UIImage imageNamed:fromIcn];
    UIImage *toIcon = [UIImage imageNamed:toIcn];
    
    [self.fromImageView setImage:fromIcon];
    //[self.fromImageView setBackgroundColor:[UIColor redColor]];
    [self.toImageView setImage:toIcon];
    //[self.toImageView setBackgroundColor:[UIColor redColor]];
    
    
}

-(void)doFirstTimeAnimation
{
    CGRect center = CGRectMake((self.frame.size.width-self.toView.frame.size.width)*0.5f, self.toView.frame.origin.y, self.toView.frame.size.width, self.toView.frame.size.height);
    
    
    self.arrowImageView.alpha = 0.0f;
    [self.toView setFrame:center];
    [self.fromView setFrame:center];
    
    [UIView animateWithDuration:0.8f delay:0.3f usingSpringWithDamping:1.2 initialSpringVelocity:0.0f options:UIViewAnimationOptionCurveLinear animations:^
     {
         self.toView.frame = self.originalToRect;
         self.fromView.frame = self.originalFromRect;
     } completion:^(BOOL finished){}];
    
    
    [UIView animateWithDuration:0.8f delay:0.6f usingSpringWithDamping:1.2 initialSpringVelocity:0.0f options:UIViewAnimationOptionCurveLinear animations:^
     {
         self.arrowImageView.alpha = 1.0f;
     } completion:^(BOOL finished){}];
}

@end
