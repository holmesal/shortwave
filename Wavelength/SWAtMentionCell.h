//
//  SWAtMentionCell.h
//  hashtag
//
//  Created by Ethan Sherr on 10/8/14.
//  Copyright (c) 2014 Ethan Sherr. All rights reserved.
//

#import <UIKit/UIKit.h>
#import "SWUser.h"

@interface SWAtMentionCell : UICollectionViewCell
-(SWUser*)getUser;
-(void)setUser:(SWUser*)user isPublic:(BOOL)isPublic;

-(void)customSetSelected:(BOOL)selected animated:(BOOL)animated;

@end
