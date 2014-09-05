

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

@property (strong, nonatomic) UILongPressGestureRecognizer *longPressGesture;
@end

@implementation SWImageCell

@synthesize imageView, imageContainer;
@synthesize longPressGesture;

-(void)awakeFromNib
{
    imageContainer.transform = CGAffineTransformMakeRotation(M_PI);

    longPressGesture = [[UILongPressGestureRecognizer alloc] initWithTarget:self action:@selector(didLongPress:)];
    longPressGesture.cancelsTouchesInView = NO;
    longPressGesture.minimumPressDuration = 0.04f;
    [self addGestureRecognizer:longPressGesture];
    
}

-(void)didLongPress:(id)sender
{
    UICollectionView *collectionView = (UICollectionView *)self.superview;
    
    
    if ([collectionView.delegate respondsToSelector:@selector(didLongPress:)])
    {
        [collectionView.delegate performSelector:@selector(didLongPress:) withObject:longPressGesture];
    } else
    {
        NSLog(@"WARNING: SWImageCell fails to LongPress, collectionView.delegate does not respond to selector %@", NSStringFromSelector(_cmd));
    }
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
//    NSString *src = model.src;
    //try to uncache it
    imageView.alpha = 0.0f;
    imageView.image = nil;
    
    super.model = model;
}

-(BOOL)hasImage
{
    return imageView.image != nil;
}

-(UIImage*)getImage
{
    return imageView.image;
}

+(CGFloat)heightWithMessageModel:(MessageModel*)model
{
    return 100.0f;
}

@end
