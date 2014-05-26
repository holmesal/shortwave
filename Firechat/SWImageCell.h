//
//  SWImageCell.h
//  Shortwave
//
//  Created by Ethan Sherr on 5/19/14.
//  Copyright (c) 2014 Buildco. All rights reserved.
//

#import <UIKit/UIKit.h>
#import "ESImageMessage.h"



@interface SWImageCell : UICollectionViewCell

@property (nonatomic, readonly, strong) NSString *ownerID; //for ease of blurring & lookup
-(BOOL)hasImage;
-(void)setMessage:(ESImageMessage*)message;
-(void)setImage:(UIImage *)image;
-(void)resetWithImageSize:(CGSize)size;
-(void)setImage:(UIImage *)image animated:(BOOL)animated;

#define SWImageCellIdentifier @"SWImageCell"

#define SWImageCell_ImageViewOffset CGPointMake(40, 65)
#define SWImageCell_NoImageHeight 40+17*2
#define SWImageCell_FIXEDHEIGHT 174

@end
