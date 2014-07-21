//
//  SWImageCell.h
//  Shortwave
//
//  Created by Ethan Sherr on 5/19/14.
//  Copyright (c) 2014 Buildco. All rights reserved.
//

#import <UIKit/UIKit.h>
#import "ESImageMessage.h"
#import "AnimatedGif.h"

#import "MessageCell.h"
#import "MessageImage.h"


@interface SWImageCell : MessageCell

@property (nonatomic, readonly, strong) NSString *ownerID; //for ease of blurring & lookup
-(BOOL)hasImage;
-(void)setMessage:(ESImageMessage*)message; //no more
-(void)setImageNil; //no more

-(void)resetWithImageSize:(CGSize)size;
-(void)setImageOrGif:(id)imageOrGif animated:(BOOL)animated isOversized:(BOOL)ovrsz;
-(void)initializeTouchGesturesFromCollectionViewIfNecessary:(UICollectionView*)collectionView;

-(UIImage*)getImage;
-(AnimatedGif*)getAnimatedGif;

-(void)showFingerAnimDelayed;
-(void)invalidateShowFingerTimer;

-(CGRect)imageViewRect;
-(void)updateProgress:(float)p;

#define SWImageCellIdentifier @"SWImageCell"

#define SWImageCell_ImageViewOffset CGPointMake(40, 65)
#define SWImageCell_NoImageHeight 40+17*2
#define SWImageCell_FIXEDHEIGHT 174

-(void)loadImage:(NSString*)imageUrlString withImageCell:(SWImageCell*)imageCell imageMessage:(MessageImage*)imageMessage collectionView:(UICollectionView*)wallCollectionView wallSource:(WallSource*)wall andIndexPath:(NSIndexPath*)indexPath;

@end
