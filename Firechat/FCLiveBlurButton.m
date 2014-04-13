//
//  FCLiveBlurButton.m
//  Firechat
//
//  Created by Ethan Sherr on 3/17/14.
//  Copyright (c) 2014 Buildco. All rights reserved.
//

#import "FCLiveBlurButton.h"
#import "UIImage+ImageEffects.h"
@interface FCLiveBlurButton ()

@property (nonatomic) CALayer *pressedLayer;
@property (nonatomic) CALayer *frameLayer;
@property (nonatomic) UIColor *originalColorText;




@property (nonatomic) UILabel *label;

@property (nonatomic) UIButton *button;


@end

@implementation FCLiveBlurButton
@synthesize pressedLayer;
@synthesize frameLayer;
@synthesize theButton;

- (id)initWithFrame:(CGRect)frame
{
    self = [super initWithFrame:frame];
    if (self) {
        // Initialization code
    }
    return self;
}

-(void)awakeFromNib
{
    for (id view in self.subviews)
    {
        [self setBackgroundColor:[UIColor clearColor]];
        if ([view isKindOfClass:[UILabel class]])
        {
            self.label = view;
            self.originalColorText = self.label.textColor;
            break;
        }
    }
    [self initialize];
}

-(void)initialize
{
    [self drawRim];
    
    self.button = [UIButton buttonWithType:UIButtonTypeCustom];
    [self.button setFrame:self.bounds];
    [self.button addTarget:self action:@selector(touchBegan) forControlEvents:UIControlEventTouchDown];
    [self.button  addTarget:self action:@selector(touchEnd) forControlEvents:UIControlEventTouchUpOutside];
    [self.button  addTarget:self action:@selector(touchEnd) forControlEvents:UIControlEventTouchUpInside];
    [self.button  addTarget:self action:@selector(touchEnd) forControlEvents:UIControlEventTouchCancel];
    
    [self addSubview:self.button];
    
    
}
-(void)touchEnd
{
//    [UIView animateWithDuration:5.8f delay:0.0f usingSpringWithDamping:1.6 initialSpringVelocity:0.0f options:UIViewAnimationOptionCurveLinear animations:^
//     {
//#warning this is fucked
////         self.label.textColor = self.originalColorText;
//         
//         self.pressedLayer.opacity = 0.0f;
//     } completion:^(BOOL finished){}];
    
    CABasicAnimation *flash = [CABasicAnimation animationWithKeyPath:@"opacity"];
    flash.fromValue = @1;
    flash.toValue = @0;
    flash.duration = 1.2;
    flash.autoreverses = NO;    // Back
    flash.repeatCount = 0;       // Or whatever
    flash.fillMode = kCAFillModeForwards;
    flash.removedOnCompletion = NO;
    
    [self.pressedLayer addAnimation:flash forKey:@"sizzle"];
    
}
-(void)touchBegan
{
//    [UIView animateWithDuration:0.8f delay:0.0f usingSpringWithDamping:1.6 initialSpringVelocity:0.0f options:UIViewAnimationOptionCurveLinear animations:^
//    {
//
//        self.pressedLayer.opacity = 1.0f;
//    } completion:^(BOOL finished){}];
    
    CABasicAnimation *flash = [CABasicAnimation animationWithKeyPath:@"opacity"];
    flash.fromValue = @0;
    flash.toValue = @1;
    flash.duration = 0.2;
    flash.autoreverses = NO;    // Back
    flash.repeatCount = 0;       // Or whatever
    flash.fillMode = kCAFillModeForwards;
    flash.removedOnCompletion = NO;
    
    [self.pressedLayer addAnimation:flash forKey:@"flashAnimation"];
    
}

-(void)setRadius:(CGFloat)radius
{
//    self.cornerRadius = radius;
    [frameLayer setCornerRadius:radius];
    [pressedLayer setCornerRadius:radius];
    [self invalidatePressedLayer];
}

-(void)drawRim
{
    frameLayer = [CALayer layer];
    [frameLayer setFrame:self.bounds];
    [frameLayer setBorderColor:[UIColor whiteColor].CGColor];
    [frameLayer setBorderWidth:0.5f];
    [frameLayer setCornerRadius:2.0f];
    [frameLayer setBackgroundColor:[UIColor clearColor].CGColor];
    
    [self.layer insertSublayer:frameLayer atIndex:0];
}

-(void)addTarget:(id)target action:(SEL)selector forControlEvents:(UIControlEvents)controlEvents
{
    [self.button addTarget:target action:selector forControlEvents:controlEvents];
}

-(void)invalidatePressedLayer
{
    if (!self.superview)
    {
        NSLog(@"warning, no superview when invalidatePressedLayer called in FCLiveBlurButton");
        return;
    }
    if (pressedLayer)
    {
        [pressedLayer removeFromSuperlayer];
    }
    [self setHidden:YES];
    UIGraphicsBeginImageContextWithOptions(self.superview.bounds.size, NO, self.window.screen.scale);    // Still slow.
    
    [self.superview drawViewHierarchyInRect:self.superview.bounds afterScreenUpdates:NO];
    
    UIImage *image = UIGraphicsGetImageFromCurrentImageContext();
    
    CGRect doubleFrame = self.frame;
    doubleFrame.origin.x *= 2;
    doubleFrame.origin.y *= 2;
    doubleFrame.size.width *= 2;
    doubleFrame.size.height *= 2;
    
    CGImageRef imageRef = CGImageCreateWithImageInRect([image CGImage], doubleFrame);
    image = [UIImage imageWithCGImage:imageRef];
    CGImageRelease(imageRef);
    
    pressedLayer = [CALayer layer];
    [pressedLayer setFrame:self.bounds];
    [pressedLayer setCornerRadius:frameLayer.cornerRadius];

    image = [image applyBlurWithRadius:10.0f tintColor:[UIColor colorWithWhite:1.0f alpha:0.6f] saturationDeltaFactor:1 maskImage:nil];//[image applyExtraLightEffect ];
    pressedLayer.contents = (id)image.CGImage;
    
    CALayer *mask = [CALayer layer];
    [mask setCornerRadius:frameLayer.cornerRadius];
    [mask setBorderColor:[UIColor whiteColor].CGColor];
    [mask setBackgroundColor:[UIColor whiteColor].CGColor];
    [mask setFrame:self.bounds];
    
    pressedLayer.mask = mask;
    [pressedLayer setOpacity:0.0f];
    [self.layer insertSublayer:pressedLayer below:self.frameLayer];
    
    UIGraphicsEndImageContext();
    [self setHidden:NO];

    
}

-(UIButton*)theButton
{
    return self.button;
}




/*
// Only override drawRect: if you perform custom drawing.
// An empty implementation adversely affects performance during animation.
- (void)drawRect:(CGRect)rect
{
    // Drawing code
}
*/

@end
