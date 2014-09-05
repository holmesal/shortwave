//
//  SWGifCell.h
//  Shortwave
//
//  Created by Ethan Sherr on 8/3/14.
//  Copyright (c) 2014 Ethan Sherr. All rights reserved.
//

#import <UIKit/UIKit.h>
#import "MessageCell.h"

@interface SWGifCell : MessageCell

//-(void)setGif:(NSString*)mp4 animated:(BOOL)animated;
//-(void)setProgress:(float)progress;

-(BOOL)hasGif;

#define SWGifCellIdentifier @"SWGifCell"

@end
