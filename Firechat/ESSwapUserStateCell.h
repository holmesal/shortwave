//
//  ESSwapUserStateCell.h
//  Earshot
//
//  Created by Ethan Sherr on 4/2/14.
//  Copyright (c) 2014 Buildco. All rights reserved.
//

#import <UIKit/UIKit.h>

@interface ESSwapUserStateCell : UITableViewCell

-(void)setFromColor:(NSString*)fromClr andIcon:(NSString*)frmIcon toColor:(NSString*)toClr andIcon:(NSString*)toIcon;

-(void)doFirstTimeAnimation;

@end
