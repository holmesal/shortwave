//
//  WalkthroughView.m
//  hashtag
//
//  Created by Ethan Sherr on 10/14/14.
//  Copyright (c) 2014 Ethan Sherr. All rights reserved.
//

#import "WalkthroughView.h"
#import <QuartzCore/QuartzCore.h>
@implementation WalkthroughView

-(id)initWithFrame:(CGRect)frame
{
    if (self = [super initWithFrame:frame])
    {
        self.backgroundColor = [UIColor clearColor];
    }
    return self;
}
// Only override drawRect: if you perform custom drawing.
// An empty implementation adversely affects performance during animation.
- (void)drawRect:(CGRect)rect
{
    // Drawing code
    CGContextRef context = UIGraphicsGetCurrentContext();
    
    CGContextSaveGState(context);
    
    CGContextSetRGBFillColor(context, 1, 1, 1, 1);
    CGContextSetRGBStrokeColor(context, 151/255.0f, 151/255.0f, 151/255.0f, 1.0f);
    CGContextSetLineWidth(context, 0.5f);
    
    UIBezierPath *bezierPath = [UIBezierPath bezierPathWithRoundedRect:self.bounds cornerRadius:3.0f];
    CGContextAddPath(context, bezierPath.CGPath);
    CGContextDrawPath(context, kCGPathFillStroke);
    
    
    CGContextRestoreGState(context);

}


@end
