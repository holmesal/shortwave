//
//  SWImageCell.h
//  Shortwave
//
//  Created by Ethan Sherr on 5/19/14.
//  Copyright (c) 2014 Buildco. All rights reserved.
//

#import <UIKit/UIKit.h>
#import "ESImageMessage.h"

@protocol SomeDelegate <NSObject>

-(void)someFunction;
@property (strong, nonatomic) NSObject *someObjectItMustHave;

@end


@interface SWImageCell : UICollectionViewCell

@property (nonatomic, readonly, strong) NSString *ownerID; //for ease of blurring & lookup
-(BOOL)hasImage;
-(void)setMessage:(ESImageMessage*)message;
-(void)setImage:(UIImage *)image;
-(void)setImage:(UIImage *)image animated:(BOOL)animated;
//-(void)setProfileImage:(NSString*)imageName;
//-(void)setProfileColor:(NSString*)profileColor;

@property (assign, nonatomic) id<SomeDelegate> oops;

#define SWImageCellIdentifier @"SWImageCell"

#define SWImageCell_ImageViewOffset CGPointMake(40, 65)
#define SWImageCell_NoImageHeight 40+17*2
#define SWImageCell_FIXEDHEIGHT 174

@end
