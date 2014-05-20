//
//  SWSwapUserStateCell.h
//  Shortwave
//
//  Created by Ethan Sherr on 5/20/14.
//  Copyright (c) 2014 Buildco. All rights reserved.
//

#import <UIKit/UIKit.h>
#import "ESSwapUserStateMessage.h"

@interface SWSwapUserStateCell : UICollectionViewCell

-(void)setMessage:(ESSwapUserStateMessage*)swapUserStateMessage;
-(void)doFirstTimeAnimation;

#define SWSwapUserStateCellIdentifier @"SWSwapUserStateCell"

@end
