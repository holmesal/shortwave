//
//  FCOwnerMessageCell.m
//  Earshot
//
//  Created by Ethan Sherr on 4/3/14.
//  Copyright (c) 2014 Buildco. All rights reserved.
//

#import "FCOwnerMessageCell.h"

@interface FCOwnerMessageCell ()

@property (weak, nonatomic) IBOutlet UIView *sneakyView;
@property (nonatomic) CALayer *coloredCircleLayer;

@property (nonatomic) UITapGestureRecognizer *debugTap;

@end

@implementation FCOwnerMessageCell
@synthesize coloredCircleLayer;


-(CALayer*)coloredCircleLayer
{
    if (!coloredCircleLayer)
    {
        CGFloat radius = 15;
        coloredCircleLayer = [CALayer layer];
        [coloredCircleLayer setBackgroundColor:[UIColor blackColor].CGColor];
        [coloredCircleLayer setBorderColor:[UIColor clearColor].CGColor];
        [coloredCircleLayer setCornerRadius:radius];
        
        
        CGRect frame = CGRectMake(-0.5f, -0.0f, radius*2+1, radius*2+1);
        frame.origin.x += (self.sneakyView.frame.size.width-frame.size.width)*0.5f;
        frame.origin.y += (self.sneakyView.frame.size.height-frame.size.height)*0.5f;
        [coloredCircleLayer setFrame:frame];
        
        [self.sneakyView.layer insertSublayer:coloredCircleLayer atIndex:0];
    }
    return coloredCircleLayer;
}

- (void)setSelected:(BOOL)selected animated:(BOOL)animated
{
    [super setSelected:selected animated:animated];
    
    // Configure the view for the selected state
}

- (void)setMessage:(FCMessage *)message
{
    // Set message text
    self.messageText.text = message.text;
    // Set message icon
    [self setIcon:message.icon withColor:message.color];
}

- (void)setIcon:(NSString *)icon withColor:(NSString *)color
{
    // Grab the icon from the included PNGs
    [self.profilePhoto setContentMode:UIViewContentModeScaleAspectFit];
    [self.coloredCircleLayer setBackgroundColor:[UIColor colorWithHexString:color].CGColor];
    UIImage *img = [UIImage imageNamed:[NSString stringWithFormat:@"%@.png",icon]];
    self.profilePhoto.image = img;
    // Set the color
    //[self.profilePhoto setBackgroundColor:[UIColor redColor]];
    
    
    //    self.profilePhoto.backgroundColor = [UIColor colorWithHexString:color];
    //    // Mask, etc
    //    self.profilePhoto.layer.masksToBounds = YES;
    //    self.profilePhoto.layer.cornerRadius = self.profilePhoto.layer.frame.size.width/2;
}

-(void)setFaded:(BOOL)faded animated:(BOOL)animated
{
    CGFloat targetAlpha = (faded? 0.2f : 1.0f);
    
    if (animated)
    {
        [UIView animateWithDuration:0.6f delay:0.0f usingSpringWithDamping:1.2f initialSpringVelocity:0.0f options:UIViewAnimationOptionCurveEaseInOut animations:^
         {
             self.coloredCircleLayer.opacity = targetAlpha;
             self.profilePhoto.alpha = targetAlpha;
             self.messageText.alpha = targetAlpha;
         } completion:^(BOOL finishd){}];
    } else
    {
        self.coloredCircleLayer.opacity = targetAlpha;
        self.profilePhoto.alpha = targetAlpha;
        self.messageText.alpha  = targetAlpha;
    }
}

-(void)addTapDebugGestureIfNecessary
{
    if (!self.debugTap)
    {
        self.debugTap = [[UITapGestureRecognizer alloc] initWithTarget:self action:@selector(debugTapGesture:)];
        [self addGestureRecognizer:self.debugTap];
    }
}

-(void)debugTapGesture:(UITapGestureRecognizer*)tap
{
    UIAlertView *alertView = [[UIAlertView alloc] initWithTitle:@"Debug" message:self.ownerID delegate:nil cancelButtonTitle:@"ok" otherButtonTitles:nil];
    [alertView show];
}

@end
