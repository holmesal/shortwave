//
//  MessageCell.h
//  Shortwave
//
//  Created by Ethan Sherr on 7/14/14.
//  Copyright (c) 2014 Buildco. All rights reserved.
//

#import <UIKit/UIKit.h>
#import "MessageModel.h"

@interface MessageCell : UICollectionViewCell

+(void)registerCollectionViewCellsForCollectionView:(UICollectionView*)collectionView;
+(MessageCell*)messageCellFromMessageModel:(MessageModel*)messageModel andCollectionView:(UICollectionView*)collectionView forIndexPath:(NSIndexPath*)indexPath;

-(void)setMessageModel:(MessageModel*)messageModel;

@end
