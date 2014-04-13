//
//  RadarView.h
//  Plug
//
//  Created by Ethan Sherr on 4/12/14.
//  Copyright (c) 2014 Ethan Sherr. All rights reserved.
//

#import <UIKit/UIKit.h>

@interface RadarView : UIView

-(id)initWithDim:(CGFloat)dim;
-(void)setPosition:(CGPoint)xy;

-(void)buildMaskWithImage:(UIImage*)image atScale:(CGFloat)scale;
-(void)buildRoundMaskAtRadius:(CGFloat)radius;
-(void)animate;

@end
