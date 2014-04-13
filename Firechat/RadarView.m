//
//  RadarView.m
//  Plug
//
//  Created by Ethan Sherr on 4/12/14.
//  Copyright (c) 2014 Ethan Sherr. All rights reserved.
//

#import "RadarView.h"

@interface RadarView ()
@property (nonatomic) CALayer *contentLayer;

@property (nonatomic) CALayer *fullMask;
@property (nonatomic) CALayer *invertedImage;
@property (nonatomic) CALayer *spinnerRod;
@property (nonatomic) CALayer *trail;


@property (nonatomic) UIPanGestureRecognizer *panGesture;
@property (nonatomic) CGFloat lastRotation;
@property (nonatomic) CGFloat angularVelocity;

@property (nonatomic) UIImageView *centeredIconImageView;
@property (nonatomic) BOOL isAnimating;

@end


@implementation RadarView

@synthesize invertedImage;
@synthesize fullMask;

@synthesize spinnerRod;
@synthesize trail;

@synthesize lastRotation;
@synthesize angularVelocity;

@synthesize panGesture;

@synthesize centeredIconImageView;

@synthesize isAnimating;

-(id)initWithDim:(CGFloat)dim
{
    if (self = [super initWithFrame:CGRectMake(0, 0, dim, dim)])
    {
        [self setBackgroundColor:[UIColor clearColor]];

        self.contentLayer = [CALayer layer];
        [self.contentLayer setFrame:self.bounds];
        [self.layer addSublayer:self.contentLayer];
        [self.contentLayer addSublayer:self.spinnerRod];
        
    }
    return self;
}
-(void)setPosition:(CGPoint)xy
{
    xy.x = xy.x-self.frame.size.width*0.5f;
    xy.y = xy.y-self.frame.size.height*0.5f;
    
    CGRect frame = self.frame;
    frame.origin = xy;
    [self setFrame:frame];
}

//creation getter
-(CALayer*)spinnerRod
{
    if (!spinnerRod)
    {
        //build
        spinnerRod = [CALayer layer];
        [spinnerRod setFrame:self.bounds];
        CAShapeLayer *theRod =  [CAShapeLayer layer];
        [theRod setBackgroundColor:[UIColor clearColor].CGColor];
        [theRod setStrokeColor:[UIColor whiteColor].CGColor];
        [theRod setLineCap:kCALineCapRound];
        [theRod setLineWidth:1.0f];
        UIBezierPath *bezPath = [[UIBezierPath alloc] init];
        [bezPath moveToPoint:CGPointMake(spinnerRod.frame.size.width*0.5f, spinnerRod.frame.size.height*0.5f)];
        [bezPath addLineToPoint:CGPointMake(spinnerRod.frame.size.width*0.5f, 3)];
        [theRod setPath:bezPath.CGPath];
        
        [spinnerRod addSublayer:theRod];
    }
    return spinnerRod;
}

-(void)buildRoundMaskAtRadius:(CGFloat)radius
{
    if (invertedImage || fullMask)
    {
        [invertedImage removeFromSuperlayer];
        [fullMask removeFromSuperlayer];
        self.contentLayer.mask = nil;
    }
    
    invertedImage = [CALayer layer];
    [invertedImage setFrame:self.bounds];
    
    UIBezierPath *bezierPath = [UIBezierPath bezierPathWithRect:self.bounds];
    [bezierPath addArcWithCenter:CGPointMake(invertedImage.frame.size.width*0.5f, invertedImage.frame.size.height*0.5f) radius:radius startAngle:0 endAngle:2*M_PI clockwise:YES];
    CAShapeLayer *circleMask = [CAShapeLayer layer];
    [circleMask setPath:bezierPath.CGPath];
    [circleMask setFillRule:kCAFillRuleEvenOdd];
    [circleMask setStrokeColor:[UIColor clearColor].CGColor];
    [circleMask setFillColor:[UIColor blackColor].CGColor];
    [invertedImage addSublayer:circleMask];
    
    
    self.fullMask = [CALayer layer];
    [fullMask setFrame:self.bounds];
    [self.fullMask addSublayer:invertedImage];
    
    [self.contentLayer setMask:fullMask];
    
    
}
-(void)buildMaskWithImage:(UIImage *)image atScale:(CGFloat)scale
{
    CGSize size = image.size;
    if (invertedImage || fullMask)
    {
        [invertedImage removeFromSuperlayer];
        [fullMask removeFromSuperlayer];
         self.contentLayer.mask = nil;
    }
 
//    centeredIconImageView = [[UIImageView alloc] initWithFrame:CGRectMake((self.frame.size.width-size.width)*0.5f, (self.frame.size.height-size.height)*0.5f, size.width, size.height)];
//    [centeredIconImageView setImage:image];
    
    
    size.height *= scale;
    size.width *= scale;
    
    UIImage *alphaInverted = [self seperateAlphaFromImage:image];
    
    invertedImage = [CALayer layer];
    invertedImage.frame = CGRectMake((self.frame.size.width-size.width)*0.5f, (self.frame.size.height-size.height)*0.5f, size.width, size.height);
    [invertedImage setContentsGravity:kCAGravityResizeAspectFill];
    invertedImage.contents = (id)alphaInverted.CGImage;
    [invertedImage setBackgroundColor:[UIColor clearColor].CGColor];
    
    fullMask = [CALayer layer];
    fullMask.frame = self.bounds;
    
    
    {//nasty area around the inverted image
        CALayer *top = [CALayer layer];
        top.frame = CGRectMake(0, 0, self.frame.size.width, invertedImage.frame.origin.y);
        [top setBackgroundColor:[UIColor blackColor].CGColor];
        [fullMask addSublayer:top];
        
        
        CALayer *left = [CALayer layer];
        left.frame = CGRectMake(0,
                                top.frame.origin.y+top.frame.size.height,
                                invertedImage.frame.origin.x,
                                invertedImage.frame.size.height);
        [left setBackgroundColor:[UIColor redColor].CGColor];
        [fullMask addSublayer:left];
        
        CALayer *right = [CALayer layer];
        right.frame = CGRectMake(invertedImage.frame.origin.x + invertedImage.frame.size.width,
                                top.frame.origin.y+top.frame.size.height,
                                invertedImage.frame.origin.x,
                                invertedImage.frame.size.height);
        [right setBackgroundColor:[UIColor blueColor].CGColor];
        [fullMask addSublayer:right];
        
        
        CALayer *bottom = [CALayer layer];
        bottom.frame = CGRectMake(0, invertedImage.frame.origin.y+invertedImage.frame.size.height, self.frame.size.width, invertedImage.frame.origin.y);
        [bottom setBackgroundColor:[UIColor blackColor].CGColor];
        [fullMask addSublayer:bottom];
        
    }
    

    
    [self.contentLayer setMask:fullMask];
    [fullMask addSublayer:invertedImage];
    [self addSubview:centeredIconImageView];
    
    
}
- (UIImage*)seperateAlphaFromImage:(UIImage*)pngImage
{
    CGRect imageRect = CGRectMake(0, 0, pngImage.size.width*[UIScreen mainScreen].scale, pngImage.size.height*[UIScreen mainScreen].scale);
    //Pixel Buffer
    uint32_t* piPixels = (uint32_t*)malloc(imageRect.size.width * imageRect.size.height * sizeof(uint32_t));
    if (piPixels == NULL)
    {
        return nil;
    }
    memset(piPixels, 0, imageRect.size.width * imageRect.size.height * sizeof(uint32_t));
    
    //Drawing image in the buffer
    CGColorSpaceRef colorSpace = CGColorSpaceCreateDeviceRGB();
    CGContextRef context = CGBitmapContextCreate(piPixels, imageRect.size.width, imageRect.size.height, 8, sizeof(uint32_t) * imageRect.size.width, colorSpace, kCGBitmapByteOrder32Little | kCGImageAlphaPremultipliedLast);
    
    CGContextDrawImage(context, imageRect, pngImage.CGImage);
    
    
    //Copying the alpha values to the red values of the image and setting the alpha to 1
    for (uint32_t y = 0; y < imageRect.size.height; y++)
    {
        for (uint32_t x = 0; x < imageRect.size.width; x++)
        {
            uint8_t* argbValues = (uint8_t*)&piPixels[y * (uint32_t)imageRect.size.width + x];
            
            //alpha = 0, red = 1, green = 2, blue = 3.
            
            argbValues[0] = 255-argbValues[0];//rgbaValues[0];
            argbValues[1] = 0;
            argbValues[2] = 0;
            argbValues[3] = 0;
           
        }
    }
    
    //Creating image whose red values will preserve the alpha values
    CGImageRef newCGImage = CGBitmapContextCreateImage(context);
    UIImage* newImage = [[UIImage alloc] initWithCGImage:newCGImage scale:[UIScreen mainScreen].scale orientation:UIImageOrientationUp];
    
    return newImage;    
}


//motion callback
-(void)rotationGesture:(UIPanGestureRecognizer*)pan
{
    CGPoint location = [pan locationInView:self];
    location.x -= self.frame.size.width*0.5f;
    location.y -= self.frame.size.height*0.5f;
    
    CGFloat rotation = atan(location.y/location.x)*180/M_PI;
    
    NSLog(@"lcoation = %@", NSStringFromCGPoint(location));
    NSLog(@"rot = %f", rotation);
    
    switch ((int)pan.state)
    {
            
        case UIGestureRecognizerStateBegan:
        {
            
        }
        break;
        case UIGestureRecognizerStateChanged:
        {
            
        }
        break;
        case UIGestureRecognizerStateEnded:
        {
            
        }
        break;
    }
}

-(void)animate
{
//    if (isAnimating)
//    {
//        return;
//    }
    isAnimating = YES;
    CABasicAnimation *animation = [CABasicAnimation animationWithKeyPath:@"opacity"];
    
    animation.fromValue       = @0.0f;
    animation.toValue         = @(M_PI*2);
    animation.duration        = 5.0f;
    animation.timingFunction  = [CAMediaTimingFunction functionWithName:kCAMediaTimingFunctionLinear];
    animation.autoreverses    = NO;
    animation.repeatCount     = HUGE_VALF;
    animation.keyPath = @"transform.rotation.z";
    
    [spinnerRod addAnimation:animation forKey:@"transform.rotation.z"];
}

@end
