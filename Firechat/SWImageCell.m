
//
//  SWImageCell.m
//  Shortwave
//
//  Created by Ethan Sherr on 5/19/14./Users/ethan/Desktop/iOS Simulator Screen shot May 23, 2014, 5.32.02 PM.png
//  Copyright (c) 2014 Buildco. All rights reserved.
//

#import "SWImageCell.h"
#import "UIImageView+AnimatedGif.h"
#import "MessageImage.h"

#import "ESImageLoader.h"

#define kMAX_IMAGE_HEIGHT 520/2.0f

@interface SWImageCell()

@property (strong, nonatomic) NSTimer *fingAnimDelayTimer;

@property (strong, nonatomic) UIImageView *realImageView;

@property (weak, nonatomic) IBOutlet UILabel *progressLabel;
@property (weak, nonatomic) IBOutlet UITextView *textLabel;
@property (weak, nonatomic) IBOutlet UIImageView *imageView;
@property (weak, nonatomic) IBOutlet UIImageView *iconImageView;
@property (weak, nonatomic) IBOutlet UIView *iconImageViewContiainer;
@property (assign, nonatomic) BOOL didShowFingerAnim;

@property (weak, nonatomic) IBOutlet UIView *oversizedOverlay;
@property (strong, nonatomic) CALayer *coloredCircleLayer;
@property (strong, nonatomic) UILongPressGestureRecognizer *longPress;

@property (assign, nonatomic) CGSize assignedSize;
@property (weak, nonatomic) IBOutlet NSLayoutConstraint *imageViewConstraintHeigt;


//finger business
@property (strong, nonatomic) CALayer *fingerScene;
@property (strong, nonatomic) CALayer *fingerLayer;
@property (strong, nonatomic) CALayer *fingerMask;
@property (strong, nonatomic) CALayer *circleLayer;
@property (strong, nonatomic) CALayer *circleScene;


@end

@implementation SWImageCell
@synthesize fingAnimDelayTimer;
@synthesize imageView;
@synthesize iconImageView;
@synthesize iconImageViewContiainer;
@synthesize coloredCircleLayer;
@synthesize ownerID;
@synthesize textLabel;
@synthesize longPress;
@synthesize oversizedOverlay;

//finger business
@synthesize fingerScene;
@synthesize fingerLayer;
@synthesize fingerMask;
@synthesize circleLayer;
@synthesize progressLabel;
@synthesize circleScene;

@synthesize realImageView;


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
    oversizedOverlay.backgroundColor = [UIColor colorWithRed:0.2 green:0.2 blue:0.2 alpha:0.8f];
    
//    UITapGestureRecognizer *tap = [[UITapGestureRecognizer alloc] initWithTarget:self action:@selector(debugTap:)];
//    [self addGestureRecognizer:tap];
    
//    [progressLabel setTextColor:[UIColor redColor]];
    
    [super awakeFromNib];

    
    [self intializeFingerAndFingerMask];

}
-(void)debugTap:(UITapGestureRecognizer*)tap
{
    NSLog(@"\n");
    NSLog(@"assignedSize = %@", NSStringFromCGSize(self.assignedSize));
    NSLog(@"currentSize = %@", NSStringFromCGSize(imageView.frame.size));
}

-(void)longPressOccured:(UILongPressGestureRecognizer*)lP
{
    if (self.oversizedOverlay.alpha)
    {
        switch ((int)longPress.state)
        {
            case UIGestureRecognizerStateBegan:
            {
                NSLog(@"collectionView:didBeginLongPressForItemAtIndexPath:");
                UICollectionView *collectionView = (UICollectionView*)self.superview;
                [collectionView.delegate performSelector:@selector(collectionView:didBeginLongPressForItemAtIndexPath:) withObject:collectionView withObject:[NSIndexPath indexPathForItem:self.tag inSection:0]];
            }
            break;
            case UIGestureRecognizerStateEnded:
            {
                NSLog(@"collectionView:didEndLongPressForItemAtIndexPath:");
                UICollectionView *collectionView = (UICollectionView*)self.superview;
                [collectionView.delegate performSelector:@selector(collectionView:didEndLongPressForItemAtIndexPath:) withObject:collectionView withObject:[NSIndexPath indexPathForItem:self.tag inSection:0]];
            }
                break;
            case UIGestureRecognizerStateChanged:
            {
                //for movement
                NSLog(@"collectionView:didLongPressDragItemAtIndexPath:");
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
    CGSize sizeOfImageView = {320,size.height*(320/size.width)};
    CGRect imageViewRect = {self.imageView.frame.origin, sizeOfImageView};
    self.assignedSize = imageViewRect.size;
    self.imageViewConstraintHeigt.constant = self.assignedSize.height;
    
}

-(void)intializeFingerAndFingerMask
{
    //controls
    CGFloat targetFingerWidth = 150.0f;
    CGFloat fingerRadiusFromFinger = 10;
    CGFloat setupYDifference = 15;
    BOOL centerToFinger = YES;
    
    //imagres
    UIImage *_fingerImg = [UIImage imageNamed:@"finger.png"];
    UIImage *_fingerMaskImg = [UIImage imageNamed:@"finger-mask.png"];
    
    //varius constants localized
    CGSize _fingerSize = _fingerImg.size;
    CGRect fingerRect = CGRectMake(0, 0, oversizedOverlay.frame.size.width, _fingerSize.height*(_fingerSize.width/oversizedOverlay.frame.size.width));
    CGPoint displacementToFinger = {121.0f, 36.0f};
    float r = (targetFingerWidth/_fingerSize.width);
    displacementToFinger.x *= r;
    displacementToFinger.y *= r;
    float fingerRadius = 75*r + fingerRadiusFromFinger;
    
    //finger artwork
    fingerLayer = [CALayer layer];
    CGRect fingerLayerRect = CGRectMake(
                
                centerToFinger ? oversizedOverlay.frame.size.width*0.5f - displacementToFinger.x : (oversizedOverlay.frame.size.width-targetFingerWidth)*0.5f,
                                        (oversizedOverlay.frame.size.height-_fingerSize.height*r)+setupYDifference,
                                        targetFingerWidth,
                                        _fingerSize.height*r );
    [fingerLayer setFrame:fingerRect];
    fingerLayer.contents = (id)_fingerImg.CGImage;
    [fingerLayer setContentsScale:[UIScreen mainScreen].scale];
    [fingerLayer setContentsGravity:kCAGravityResizeAspectFill];
    fingerLayer.frame = fingerLayerRect;
    [fingerLayer setBackgroundColor:[UIColor colorWithRed:0 green:0 blue:1 alpha:0.0].CGColor];
    

    
    
    //circle layer button
    circleScene = [CALayer layer];
    circleScene.frame = fingerLayerRect;
    
    
    
    circleLayer = [CALayer layer];
    [circleLayer setFrame:CGRectMake(displacementToFinger.x-fingerRadius*0.5f,
                                     displacementToFinger.y-fingerRadius*0.5f,
                                     fingerRadius,
                                     fingerRadius)];
    [circleLayer setBorderColor:[UIColor whiteColor].CGColor];
    [circleLayer setBorderWidth:1.0f];
    [circleLayer setBackgroundColor:[UIColor clearColor].CGColor];
    [circleLayer setCornerRadius:circleLayer.frame.size.width/2.0f];
    
    //finger mask in circle layer button
    {
        fingerMask = [CALayer layer];
        CGRect fingerMaskRect = CGRectMake( 0, 0,
//                                          -(displacementToFinger.x-fingerRadius*0.5f),
//                                           -(displacementToFinger.y-fingerRadius*0.5f),
                                           targetFingerWidth,
                                           _fingerSize.height*r );
        [fingerMask setFrame:fingerRect];
        fingerMask.contents = (id)_fingerMaskImg.CGImage;
        [fingerMask setContentsScale:[UIScreen mainScreen].scale];
        [fingerMask setContentsGravity:kCAGravityResizeAspectFill];
        fingerMask.frame = fingerMaskRect;
        
        CALayer *aboveRect = [CALayer layer];
        [aboveRect setFrame:CGRectMake(0, -300, fingerMaskRect.size.width, 300)];
        [aboveRect setBackgroundColor:[UIColor blackColor].CGColor];
        [fingerMask addSublayer:aboveRect];
        
        [fingerMask setBackgroundColor:[UIColor clearColor].CGColor];
//        circleLayer.mask = fingerMask;
//        [circleLayer addSublayer:fingerMask];
    }
    
    
    //root of the scene
    fingerScene = [CALayer layer];
    [fingerScene setFrame:oversizedOverlay.bounds];
    [fingerScene setBackgroundColor:[UIColor clearColor].CGColor];
    
    
    [fingerScene addSublayer:fingerLayer];
//    [fingerScene addSublayer:circleLayer];
    [fingerScene addSublayer:circleScene];
    [circleScene addSublayer:circleLayer];
    [circleScene setMask:fingerMask];
    
    
    [oversizedOverlay.layer addSublayer:fingerScene];
    
}

-(void)initializeTouchGesturesFromCollectionViewIfNecessary:(UICollectionView*)collectionView
{
    if (!longPress)
    {
        longPress = [[UILongPressGestureRecognizer alloc] initWithTarget:self action:@selector(longPressOccured:)];
        [longPress setMinimumPressDuration:0.075];
        
        NSArray *gestures = collectionView.gestureRecognizers;
        
//        [longPress requireGestureRecognizerToFail:gestures.firstObject];
        [oversizedOverlay addGestureRecognizer:longPress];
    }
}

-(void)setMessage:(ESImageMessage*)message
{
    NSAssert(NO, @"set content using setModel:");
    self.didShowFingerAnim = NO;
    textLabel.text = message.text;
    [iconImageView setImage:[UIImage imageNamed:message.icon]];
    
    [self.coloredCircleLayer setBackgroundColor:[UIColor colorWithHexString:message.color].CGColor];
    ownerID = message.ownerID;
    
    [self resetWithImageSize:message.size];
}

-(void)setModel:(MessageImage *)model
{
    [self setImageNil];
    
    self.didShowFingerAnim = NO;
    textLabel.text = model.text;
//    [iconImageView setImage:[UIImage imageNamed:model.icon]];
//    [self.coloredCircleLayer setBackgroundColor:model.color.CGColor];
    ownerID = model.ownerID;
    [self resetWithImageSize:model.size];
    
    NSURL *imgUrl = [NSURL URLWithString:model.src];
    float p = [[ESImageLoader sharedImageLoader] progressForImage:imgUrl];
    [self updateProgress:p];
    
    super.model = model;
}

-(void)setImageOrGif:(id)imageOrGif animated:(BOOL)animated isOversized:(BOOL)ovrsz;
{
    [self.imageView setHidden:NO];
    [CATransaction begin];
    [CATransaction setDisableActions:YES];
        [fingerScene setHidden:YES];

    [CATransaction commit];

    realImageView = [[UIImageView alloc] initWithFrame:imageView.frame];
    [realImageView setBackgroundColor:[UIColor redColor]];
    [realImageView setContentMode:imageView.contentMode];
    [imageView.superview insertSubview:realImageView belowSubview:imageView];
    
    //silly fix for double loading pics. in future don't double load imgs with same context
    if (animated && !self.hasImage)
    {

        realImageView.alpha = 0.0f;
        
        
        [UIView animateWithDuration:0.52f animations:^
         {
            if (ovrsz)
            {
                oversizedOverlay.alpha = 1.0f;
            }
             realImageView.alpha = 1.0f;
         }];
        
    }

    
    if ([imageOrGif isKindOfClass:[AnimatedGif class]])
    {
        AnimatedGif *gif = imageOrGif;
//        [gif start];
        //        [gif start];
        
        [realImageView setAnimatedGif:gif startImmediately:YES];

//        NSLog(@"self.imageView.alpha = %f", self.imageView.alpha);
//        NSLog(@"self.imageView.hidden = %d", self.imageView.isHidden);
//        
//        NSLog(@"self.imageView.superView.alpha = %f", self.imageView.superview.alpha);
//        NSLog(@"self.imageView.superView.hidden = %d", self.imageView.superview.isHidden);
        
        
        
        
    } else
    if ([imageOrGif isKindOfClass:[UIImage class]])
    {
        UIImage *image = imageOrGif;
        [realImageView setImage:image];
    }
    else
    {
        realImageView.alpha = 0.0f;
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
        realImageView.alpha = 1.0f;
    }
    
}

-(void)invalidateShowFingerTimer
{
    if (fingAnimDelayTimer)
    {
        [fingAnimDelayTimer invalidate];
        fingAnimDelayTimer = nil;
    }
}

-(void)showFingerAnimDelayed
{
    if (!fingAnimDelayTimer)
    {
        fingAnimDelayTimer = [NSTimer timerWithTimeInterval:0.5f target:self selector:@selector(doAnimation) userInfo:nil repeats:NO];
        [[NSRunLoop mainRunLoop] addTimer:fingAnimDelayTimer forMode:NSDefaultRunLoopMode];
    }
}

-(void)doAnimation
{
    [fingAnimDelayTimer invalidate];
    fingAnimDelayTimer = nil;
    if (!self.didShowFingerAnim)
    {
        self.didShowFingerAnim = YES;
        
        [CATransaction begin];
        [CATransaction setDisableActions:YES];
        
            CGFloat h = oversizedOverlay.frame.size.height;// - fingerLayer.frame.origin.y;
            fingerLayer.transform = CATransform3DMakeTranslation(0, h, 0);
            fingerMask.transform = CATransform3DMakeTranslation(0, h, 0);
            circleLayer.opacity = 0.0f;
            CGFloat r = 0.384615391f;
            CGFloat s = (75*r)/(75*r+10);
            circleLayer.transform = CATransform3DMakeScale(s, s, 1);
        [CATransaction commit];
        
        
        
        [fingerScene setHidden:NO];
        
        float fingerAnimTime = 0.8f;
        
        CABasicAnimation *transformAnimation = [CABasicAnimation animationWithKeyPath: @"transform"];
        transformAnimation.fillMode = kCAFillModeForwards;
        transformAnimation.removedOnCompletion = NO;
        [transformAnimation setTimingFunction:[CAMediaTimingFunction functionWithName:kCAMediaTimingFunctionEaseOut]];
        transformAnimation.fromValue = [NSValue valueWithCATransform3D:fingerLayer.transform];
        transformAnimation.toValue = [NSValue valueWithCATransform3D:CATransform3DIdentity];
        transformAnimation.duration = fingerAnimTime;
        [fingerLayer addAnimation:transformAnimation forKey:@"fingerPosition"];
        [fingerMask addAnimation:transformAnimation forKey:@"fingerMaskPosition"];
        
        CABasicAnimation *fadeInAnimation = [CABasicAnimation animationWithKeyPath:@"opacity"];
        fadeInAnimation.fillMode = kCAFillModeForwards;
        fadeInAnimation.removedOnCompletion = NO;
        [fadeInAnimation setTimingFunction:[CAMediaTimingFunction functionWithName:kCAMediaTimingFunctionEaseOut]];
        fadeInAnimation.fromValue = @0;
        fadeInAnimation.toValue = @1;
        fadeInAnimation.duration = 0.2;
        fadeInAnimation.beginTime = CACurrentMediaTime() + fingerAnimTime;
        [circleLayer addAnimation:fadeInAnimation forKey:@"fadeInQuick"];
        
        CABasicAnimation *circleRadiusAnim = [CABasicAnimation animationWithKeyPath:@"transform"];
        circleRadiusAnim.fillMode = kCAFillModeForwards;
        circleRadiusAnim.removedOnCompletion = NO;
        [circleRadiusAnim setTimingFunction:[CAMediaTimingFunction functionWithName:kCAMediaTimingFunctionEaseInEaseOut]];
        circleRadiusAnim.fromValue = [NSValue valueWithCATransform3D:circleLayer.transform];
        circleRadiusAnim.toValue = [NSValue valueWithCATransform3D:CATransform3DIdentity];
        circleRadiusAnim.duration = 0.4;
        circleRadiusAnim.beginTime = CACurrentMediaTime() + fingerAnimTime;
        [circleLayer addAnimation:circleRadiusAnim forKey:@"scaleInQuick"];
    }
}

-(AnimatedGif*)getAnimatedGif
{
    return imageView.animatedGif;
}
-(UIImage*)getImage
{
    return realImageView.image;
}
-(void)setImageNil
{
    if (realImageView)
    {
        [realImageView stopAnimating];
        [realImageView removeFromSuperview];
        realImageView = nil;
    }
    return;
//    [self setImage:nil animated:NO isOversized:NO];
//    [self setImageOrGif:nil animated:NO isOversized:NO];
    [self.imageView stopAnimating];
    self.imageView.image = nil;
//    [self.imageView setImage:nil];
//    [self.imageView setAnimatedGif:nil];
    [self.imageView setHidden:YES];

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

-(void)updateProgress:(float)p
{
    
    [self.progressLabel setText:[NSString stringWithFormat:@"%.f", p*100]];
    
}


+(CGFloat)heightWithMessageModel:(MessageImage *)messageModel //collectionView:(UICollectionView *)collectionView
{
    CGSize imgSize = messageModel.size;
    static float topImgOffset = 59;
    CGFloat height = topImgOffset + imgSize.height*320/imgSize.width;
    
    if (height > topImgOffset+kMAX_IMAGE_HEIGHT)
    {
        
        height = 380/2.0f;
    }
    return height;
}

-(void)loadImage:(NSString*)imageUrlString withImageCell:(SWImageCell*)imageCell imageMessage:(MessageImage*)imageMessage collectionView:(UICollectionView*)wallCollectionView wall:(NSArray*)wall andIndexPath:(NSIndexPath*)indexPath;
{
    NSURL *imgUrl = [NSURL URLWithString:imageUrlString];
    
    BOOL isGif = imageMessage.type == MessageModelTypeGif;
    
//    NSLog(@"imgUrl = %@", imgUrl);
//    NSLog(@"isGif = %@", (isGif? @"YES": @"NO"));

    [[ESImageLoader sharedImageLoader] loadImage:imgUrl completionBlock:^(id imageOrGif, NSURL *url, BOOL synchronous)
     {
//         NSLog(@"finished:");
        NSLog(@"isGif = %@", (isGif? @"YES": @"NO"));
        NSLog(@"data = %@", imageOrGif);
         
         if (synchronous)
         {
             CGSize size = imageMessage.size;
             BOOL isOversized = (size.height * 320/size.width > kMAX_IMAGE_HEIGHT);
             [self setImageOrGif:imageOrGif animated:NO isOversized:isOversized];
         } else
         {
             NSArray *visibleIndexPaths = [wallCollectionView indexPathsForVisibleItems];
             for (NSIndexPath *currentIndexPath in visibleIndexPaths)
             {
                 //scan the current visible messages for an ESImageMessage and retrieve corresponding SWImageCell (if it exists) to give it the UIImage
                 MessageModel *aMessage = (MessageModel *)[wall objectAtIndex:currentIndexPath.row];
                 if ([aMessage isKindOfClass:[MessageImage class]])
                 {
                     MessageImage *currentImageMessage = (MessageImage*)aMessage;
                     if ([url.absoluteString isEqualToString:currentImageMessage.src])
                     {
                         
                         SWImageCell *retrievedImageCell = (SWImageCell *)[wallCollectionView cellForItemAtIndexPath:currentIndexPath];
                         MessageImage *againmessage = (MessageImage*)[wall objectAtIndex:currentIndexPath.row];
                         
                         if (retrievedImageCell)
                         {
                             CGSize size = againmessage.size;
                             BOOL isOversized = (size.height * 320/size.width > kMAX_IMAGE_HEIGHT);
                             [retrievedImageCell setImageOrGif:imageOrGif animated:YES isOversized:isOversized];
                             
                             ESAssert([retrievedImageCell isKindOfClass:[SWImageCell class]], @"Supposed ESImageMessage must correspond kind of SWImageCell!");
                             
                             
                         }
                         break;
                     }
                 }
             }//end of NSIndexPath visible loop
         }
     } updateBlock:^(NSURL *theUrl, float p)
     {
         NSArray *visibleIndexPaths = [wallCollectionView indexPathsForVisibleItems];
         for (NSIndexPath *idxPth in visibleIndexPaths)
         {
             //scan the current visible messages for an ESImageMessage and retrieve corresponding SWImageCell (if it exists) to give it the UIImage
             MessageModel *aMessage = (MessageModel *)[wall objectAtIndex:idxPth.row];
             if ([aMessage isKindOfClass:[MessageImage class]])
             {
                 MessageImage *currMsg = (MessageImage*)aMessage;
                 if ([theUrl.absoluteString isEqualToString:currMsg.src])
                 {
                     
                     SWImageCell *retrievedImageCell = (SWImageCell *)[wallCollectionView cellForItemAtIndexPath:idxPth];
                     if (retrievedImageCell)
                     {
                         [retrievedImageCell updateProgress:p];
                     }
                     
                     break;
                 }
             }
         }//end of NSIndexPath visible loop
         
         
     } isGif:isGif withMetric:indexPath.row];
}

@end
