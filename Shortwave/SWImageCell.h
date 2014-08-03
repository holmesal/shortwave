//
//  SWImageCell.h
//  Shortwave
//
//  Created by Ethan Sherr on 5/19/14.
//  Copyright (c) 2014 Buildco. All rights reserved.
//

#import <UIKit/UIKit.h>

#import "MessageCell.h"
#import "MessageImage.h"


@interface SWImageCell : MessageCell

-(void)setImage:(UIImage*)image animated:(BOOL)animated;
-(void)setProgress:(float)progress;

-(BOOL)hasImage;

#define SWImageCellIdentifier @"SWImageCell"
#define SWImageCell_ImageViewOffset CGPointMake(40, 65)
#define SWImageCell_NoImageHeight 40+17*2
#define SWImageCell_FIXEDHEIGHT 174


@end
