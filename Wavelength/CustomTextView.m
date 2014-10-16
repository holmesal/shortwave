//
//  CustomTextView.m
//  hashtag
//
//  Created by Ethan Sherr on 10/15/14.
//  Copyright (c) 2014 Ethan Sherr. All rights reserved.
//

#import "CustomTextView.h"

@interface CustomTextView ()

@property (strong, nonatomic) NSAttributedString *label;
@property (assign, nonatomic) CGSize size;
@property (strong, nonatomic) UIFont *font;
@property (assign, nonatomic) CGFloat width;
@property (assign, nonatomic) CGPoint point;
@property (assign, nonatomic) NSTextAlignment textAlignment;
@property (strong, nonatomic) UIColor *color;

@end

@implementation CustomTextView



-(void)setLabel:(NSAttributedString*)label size:(CGSize)size font:(UIFont*)font width:(CGFloat)width point:(CGPoint)point alignment:(NSTextAlignment)textAlignment color:(UIColor*)color
{
    _label = label;
    _size = size;
    _font = font;
    _width = width;
    _point = point;
    _textAlignment = textAlignment;
    _color = color;
    [self setNeedsDisplay];
}

// Only override drawRect: if you perform custom drawing.
// An empty implementation adversely affects performance during animation.
- (void)drawRect:(CGRect)rect
{
    // Drawing code
    [self _drawLabel:_label withSize:_size withFont:_font forWidth:_width atPoint:_point withAlignment:_textAlignment color:_color];

}


- (void)_drawLabel:(NSAttributedString *)label withSize:(CGSize)size withFont:(UIFont *)font forWidth:(CGFloat)width
           atPoint:(CGPoint)point withAlignment:(NSTextAlignment)alignment color:(UIColor *)color
{
    // obtain current context
    CGContextRef context = UIGraphicsGetCurrentContext();
    
    // save context state first
    CGContextSaveGState(context);
    
    //    // obtain size of drawn label
    //    CGSize size = [label sizeWithFont:font
    //                             forWidth:width
    //                        lineBreakMode:UILineBreakModeClip];
    
    // determine correct rect for this label
//    CGRect rect = CGRectMake(point.x, point.y - (size.height / 2),
//                             width, size.height);
    CGRect rect = {point , size};
    
    // set text color in context
    CGContextSetFillColorWithColor(context, color.CGColor);
    
    // draw text
    [label drawInRect:rect];
    //    [label drawInRect:rect
    //             withFont:font
    //        lineBreakMode:UILineBreakModeClip
    //            alignment:alignment];
    //
    // restore context state
    CGContextRestoreGState(context);
}


@end
