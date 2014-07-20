//
//  SWMessageCell.m
//  Shortwave
//
//  Created by Ethan Sherr on 5/19/14.
//  Copyright (c) 2014 Buildco. All rights reserved.
//

#import "SWTextCell.h"

@interface SWTextCell ()


@property (weak, nonatomic) IBOutlet UIImageView *iconImageView;
@property (weak, nonatomic) IBOutlet UITextView *messageText;
@property (weak, nonatomic) IBOutlet UIView *iconImageViewContainer;

@property (nonatomic, strong) CALayer *coloredCircleLayer;

//@property (nonatomic) UILongPressGestureRecognizer *longPress;
//@property (nonatomic) UITapGestureRecognizer *doubleTap;
//@property (nonatomic) UITapGestureRecognizer *debugTap;

@end

@implementation SWTextCell
@synthesize coloredCircleLayer;
@synthesize ownerID;
@synthesize messageText;
@synthesize iconImageViewContainer;
@synthesize iconImageView;

-(void)awakeFromNib
{
    [super awakeFromNib];
    [iconImageView setContentMode:UIViewContentModeScaleAspectFit];
    
}

-(CALayer*)coloredCircleLayer
{
    if (!coloredCircleLayer)
    {
        CGFloat radius = iconImageViewContainer.frame.size.width/2;
        coloredCircleLayer = [CALayer layer];
        [coloredCircleLayer setBackgroundColor:[UIColor blackColor].CGColor];
        [coloredCircleLayer setBorderColor:[UIColor clearColor].CGColor];
        [coloredCircleLayer setCornerRadius:radius];
        
        
        CGRect frame = CGRectMake(-0.5f, -0.0f, radius*2+1, radius*2+1);
        frame.origin.x += (iconImageViewContainer.frame.size.width-frame.size.width)*0.5f;
        frame.origin.y += (iconImageViewContainer.frame.size.height-frame.size.height)*0.5f;
        [coloredCircleLayer setFrame:frame];
        
        [iconImageViewContainer.layer insertSublayer:coloredCircleLayer atIndex:0];
    }
    return coloredCircleLayer;
}


- (void)setMessage:(FCMessage *)message
{
    NSAssert(NO, @"Use MessageModel setter");
    ownerID = message.ownerID;
    messageText.text = message.text;

    [self.coloredCircleLayer setBackgroundColor:[UIColor colorWithHexString:message.color].CGColor];
    UIImage *img = [UIImage imageNamed:[NSString stringWithFormat:@"%@.png",message.icon]];
    iconImageView.image = img;
    
}

-(void)setFaded:(BOOL)faded animated:(BOOL)animated
{
    CGFloat targetAlpha = (faded? 0.2f : 1.0f);
    
    if (animated)
    {
        [UIView animateWithDuration:0.6f delay:0.0f usingSpringWithDamping:1.2f initialSpringVelocity:0.0f options:UIViewAnimationOptionCurveEaseInOut animations:^
         {
             self.coloredCircleLayer.opacity = targetAlpha;
             iconImageView.alpha = targetAlpha;
             self.messageText.alpha = targetAlpha;
         } completion:^(BOOL finishd){}];
    } else
    {
        self.coloredCircleLayer.opacity = targetAlpha;
        iconImageView.alpha = targetAlpha;
        self.messageText.alpha  = targetAlpha;
    }
}

-(void)setModel:(MessageModel *)model
{
    ownerID = model.ownerID;
    messageText.text = model.text;
    
    [self.coloredCircleLayer setBackgroundColor:[UIColor redColor].CGColor];
    UIImage *img = [UIImage imageNamed:[NSString stringWithFormat:@"%@.png", @"1"] ];
    iconImageView.image = img;
    
    super.model = model;
}

@end
