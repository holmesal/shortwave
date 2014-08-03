

//
//  SWImageCell.m
//  Shortwave
//
//  Created by Ethan Sherr on 5/19/14./Users/ethan/Desktop/iOS Simulator Screen shot May 23, 2014, 5.32.02 PM.png
//  Copyright (c) 2014 Buildco. All rights reserved.
//

#import "SWImageCell.h"
#import "MessageImage.h"


#define kMAX_IMAGE_HEIGHT 520/2.0f

@interface SWImageCell()

@property (weak, nonatomic) IBOutlet UIView *imageContainer;
@property (weak, nonatomic) IBOutlet UIImageView *imageView;
@property (weak, nonatomic) IBOutlet UILabel *progressLabel;

@end

@implementation SWImageCell

@synthesize imageView, imageContainer;

-(void)awakeFromNib
{
    imageContainer.transform = CGAffineTransformMakeRotation(M_PI);
}

-(void)setImage:(UIImage*)image animated:(BOOL)animated
{
    [imageView setImage:image];
    imageView.alpha = 1.0f;
}

-(void)setProgress:(float)progress
{
    _progressLabel.text = [NSString stringWithFormat:@"%d", (int)(progress*100)];
}

-(void)setModel:(MessageImage *)model
{
    NSString *src = model.src;
    //try to uncache it
    imageView.alpha = 0.0f;
    imageView.image = nil;
    
    super.model = model;
}

-(BOOL)hasImage
{
    return imageView.image != nil;
}

+(CGFloat)heightWithMessageModel:(MessageModel*)model
{
    return 100.0f;
}

@end
