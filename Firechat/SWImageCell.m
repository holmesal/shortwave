//
//  SWImageCell.m
//  Shortwave
//
//  Created by Ethan Sherr on 5/19/14.
//  Copyright (c) 2014 Buildco. All rights reserved.
//

#import "SWImageCell.h"

@interface SWImageCell()

@property (weak, nonatomic) IBOutlet UIImageView *imageView;
@property (weak, nonatomic) IBOutlet UIImageView *iconImageView;
@property (weak, nonatomic) IBOutlet UIView *iconImageViewContiainer;

@property (strong, nonatomic) CALayer *coloredCircleLayer;

@end

@implementation SWImageCell
@synthesize imageView;
@synthesize iconImageView;
@synthesize iconImageViewContiainer;
@synthesize coloredCircleLayer;
@synthesize ownerID;

-(void)awakeFromNib
{
    [super awakeFromNib];
    [self resetWithImageSize:CGSizeZero];
}
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
        frame.origin.x += (iconImageViewContiainer.frame.size.width-frame.size.width)*0.5f;
        frame.origin.y += (iconImageViewContiainer.frame.size.height-frame.size.height)*0.5f;
        [coloredCircleLayer setFrame:frame];
        
        [iconImageViewContiainer.layer insertSublayer:coloredCircleLayer atIndex:0];
    }
    return coloredCircleLayer;
}

-(void)resetWithImageSize:(CGSize)size
{
    //if size is 0,0 then it is still loading, and activate loading mode
    if (size.width == size.height && size.height == 0)
    {
        NSLog(@"be loading!");
    }
    else
    {
        
    }
}

-(void)setMessage:(ESImageMessage*)message
{
    [iconImageView setImage:[UIImage imageNamed:message.icon]];
    [coloredCircleLayer setBackgroundColor:[UIColor colorWithHexString:message.color].CGColor];
    ownerID = message.ownerID;
}

-(void)setImage:(UIImage*)image
{
    if (!image)
    {
        [self resetWithImageSize:CGSizeZero];
    }
    
    [self.imageView setImage:image];
}
-(BOOL)hasImage
{
    return (imageView.image ? YES : NO);
}




-(void)setProfileColor:(NSString*)profileColor
{
    [self.coloredCircleLayer setBackgroundColor:[UIColor colorWithHexString:profileColor].CGColor];
}

@end
