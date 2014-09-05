//
//  SWWebSiteCell.h
//  Shortwave
//
//  Created by Ethan Sherr on 8/11/14.
//  Copyright (c) 2014 Ethan Sherr. All rights reserved.
//

#import "MessageCell.h"

@interface SWWebSiteCell : MessageCell

#define SWWebSiteCellIdentifier @"SWWebSiteCell"

-(void)setFavIconImg:(UIImage*)img animated:(BOOL)animated;
-(void)setImg:(UIImage*)img animated:(BOOL)animated;

@end
