//
//  SWOwnerTextCell.h
//  Shortwave
//
//  Created by Ethan Sherr on 5/19/14.
//  Copyright (c) 2014 Buildco. All rights reserved.
//

#import <UIKit/UIKit.h>
#import "FCMessage.h"

@interface SWOwnerTextCell : UICollectionViewCell

@property (nonatomic, readonly, strong) NSString *ownerID; //for ease of blurring & lookup
//set message sets icon, color, text
-(void)setMessage:(FCMessage *)message;
-(void)setFaded:(BOOL)faded animated:(BOOL)animated;

#define SWOwnerTextCellIdentifier @"SWOwnerTextCell"

//debugging tap gestures
//-(void)initializeDoubleTap;
//-(void)initializeLongPress;
//-(void)addTapDebugGestureIfNecessary;
@end