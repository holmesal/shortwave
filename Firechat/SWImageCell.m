
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

@property (weak, nonatomic) IBOutlet UIView *oversizedOverlay;
@property (strong, nonatomic) CALayer *coloredCircleLayer;
@property (strong, nonatomic) UILongPressGestureRecognizer *longPress;

@end

@implementation SWImageCell
@synthesize imageView;
@synthesize iconImageView;
@synthesize iconImageViewContiainer;
@synthesize coloredCircleLayer;
@synthesize ownerID;
@synthesize textLabel;
@synthesize longPress;
@synthesize oversizedOverlay;

-(void)awakeFromNib
{
    
//    longPress = [[UILongPressGestureRecognizer alloc] initWithTarget:self action:@selector(longPressOccured:)];
//    [longPress setMinimumPressDuration:0];
//    
//    id thing = self.superview;
//    
//    NSArray *gestures = self.superview.gestureRecognizers;
//    
//    
//    [longPress requireGestureRecognizerToFail:gestures.lastObject];
//    [imageView setUserInteractionEnabled:YES];
//    [oversizedOverlay addGestureRecognizer:longPress];
    oversizedOverlay.alpha = 0.0f;
    
    [super awakeFromNib];
}

-(void)longPressOccured:(UILongPressGestureRecognizer*)longPress
{
    if (self.oversizedOverlay.alpha)
    {
        switch ((int)longPress.state)
        {
            case UIGestureRecognizerStateBegan:
            {
                UICollectionView *collectionView = (UICollectionView*)self.superview;
                [collectionView.delegate performSelector:@selector(collectionView:didBeginLongPressForItemAtIndexPath:) withObject:collectionView withObject:[NSIndexPath indexPathForItem:self.tag inSection:0]];
            }
            break;
            case UIGestureRecognizerStateEnded:
            {
                UICollectionView *collectionView = (UICollectionView*)self.superview;
                [collectionView.delegate performSelector:@selector(collectionView:didEndLongPressForItemAtIndexPath:) withObject:collectionView withObject:[NSIndexPath indexPathForItem:self.tag inSection:0]];
            }
                break;
            case UIGestureRecognizerStateChanged:
            {
                //for movement
                UICollectionView *collectionView = (UICollectionView*)self.superview;
                [collectionView.delegate performSelector:@selector(collectionView:didLongPressDragItemAtIndexPath:) withObject:collectionView withObject:[NSIndexPath indexPathForItem:self.tag inSection:0]];
            }
                break;
            case UIGestureRecognizerStateCancelled:
            {
                
            }
                break;
                
            default:
                break;
        }
    }
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

-(void)initializeTouchGesturesFromCollectionViewIfNecessary:(UICollectionView*)collectionView
{
    if (!longPress)
    {
        longPress = [[UILongPressGestureRecognizer alloc] initWithTarget:self action:@selector(longPressOccured:)];
        [longPress setMinimumPressDuration:0.075];
        
        NSArray *gestures = collectionView.gestureRecognizers;
        
        
        [longPress requireGestureRecognizerToFail:gestures.firstObject];
        [oversizedOverlay addGestureRecognizer:longPress];
    }
}
-(void)setMessage:(ESImageMessage*)message
{

    textLabel.text = message.text;
    [iconImageView setImage:[UIImage imageNamed:message.icon]];
    
    [self.coloredCircleLayer setBackgroundColor:[UIColor colorWithHexString:message.color].CGColor];
    ownerID = message.ownerID;
    
    // Set the imageview height
//    [self resetWithImageSize:message.size];
}

-(void)setImage:(UIImage *)image animated:(BOOL)animated isOversized:(BOOL)ovrsz
{
    //silly fix for double loading pics. in future don't double load imgs with same context
    if (animated && !self.hasImage)
    {

        self.imageView.alpha = 0.0f;
        
        
        [UIView animateWithDuration:0.52f animations:^
         {
            if (ovrsz)
            {
                oversizedOverlay.alpha = 1.0f;
            }
             imageView.alpha = 1.0f;
         }];
    }
    [self.imageView setImage:image];
    
    if (image)
    {
        [self resetWithImageSize:image.size];
    }
    else
    {
        self.imageView.alpha = 0.0f;
    }
    
    if (!ovrsz)
    {
        oversizedOverlay.alpha = 0.0f;
    }
    
    if (ovrsz && !animated)
    {
        oversizedOverlay.alpha = 1.0f;
    }
    
    if (!animated)
    {
        self.imageView.alpha = 1.0f;
    }
    
}

-(UIImage*)getImage
{
    return imageView.image;
}

-(void)setImage:(UIImage*)image
{
    [self setImage:image animated:NO isOversized:NO];
}
-(BOOL)hasImage
{
    return (imageView.image ? YES : NO);
}

-(void)setProfileColor:(NSString*)profileColor
{
    [self.coloredCircleLayer setBackgroundColor:[UIColor colorWithHexString:profileColor].CGColor];
}

-(CGRect)imageViewRect
{
    return imageView.superview.frame;
}

@end
