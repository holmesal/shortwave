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
//-(void)setProfileImage:(NSString*)imageName;
//-(void)setProfileColor:(NSString*)profileColor;

#define SWImageCellIdentifier @"SWImageCell"

@end
