//
//  SWMessageHeaderView.h
//  hashtag
//
//  Created by Ethan Sherr on 10/9/14.
//  Copyright (c) 2014 Ethan Sherr. All rights reserved.
//

#import <UIKit/UIKit.h>
#import "SWUser.h"

@interface SWMessageHeaderView : UICollectionReusableView

-(void)setPhoto:(NSString*)ownerPhoto andName:(NSString*)ownerName;

@end
