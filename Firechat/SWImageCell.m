//
//  SWImageCell.m
//  Shortwave
//
//  Created by Ethan Sherr on 5/19/14./Users/ethan/Desktop/iOS Simulator Screen shot May 23, 2014, 5.32.02 PM.png
//  Copyright (c) 2014 Buildco. All rights reserved.
//

#import "SWImageCell.h"

@interface SWImageCell()

@property (weak, nonatomic) IBOutlet UITextView *textLabel;
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
}
-(CALayer*)coloredCircleLayer
{
    if (!coloredCircleLayer)
    {
        CGFloat radius = iconImageViewContiainer.frame.size.width/2;
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
    CGSize sizeOfImageView = {320,size.height*(320/size.width)};//imageView.frame.size;
    //ratio w.h
    
    CGRect imageViewRect = {self.imageView.frame.origin, sizeOfImageView};
    [imageView setFrame:imageViewRect];
    
}

-(void)setMessage:(ESImageMessage*)message
{
    [iconImageView setImage:[UIImage imageNamed:message.icon]];
    
    [self.coloredCircleLayer setBackgroundColor:[UIColor colorWithHexString:message.color].CGColor];
    ownerID = message.ownerID;
    
    // Set the imageview height
//    [self resetWithImageSize:message.size];
}

-(void)setImage:(UIImage *)image animated:(BOOL)animated
{
    
    [self.imageView setImage:image];
    
    if (image)
    {
        [self resetWithImageSize:image.size];
    }

    
    if (animated)
    {
        self.imageView.alpha = 0.0f;
        
        [UIView animateWithDuration:0.52f animations:^
        {
            imageView.alpha = 1.0f;
        }];
    }
}

-(void)setImage:(UIImage*)image
{
    [self setImage:image animated:NO];
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
