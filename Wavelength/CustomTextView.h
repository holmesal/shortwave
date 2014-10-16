//
//  CustomTextView.h
//  hashtag
//
//  Created by Ethan Sherr on 10/15/14.
//  Copyright (c) 2014 Ethan Sherr. All rights reserved.
//

#import <UIKit/UIKit.h>

@interface CustomTextView : UIView

-(void)setLabel:(NSAttributedString*)label size:(CGSize)size font:(UIFont*)font width:(CGFloat)width point:(CGPoint)point alignment:(NSTextAlignment)textAlignment color:(UIColor*)color;

@end
