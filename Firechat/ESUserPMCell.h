//
//  ESUserPMCell.h
//  Earshot
//
//  Created by Ethan Sherr on 4/3/14.
//  Copyright (c) 2014 Buildco. All rights reserved.
//

#import <UIKit/UIKit.h>

@interface ESUserPMCell : UITableViewCell

-(void)setColor:(NSString*)color andImage:(NSString*)image;
-(void)transitionToColor:(NSString*)color andImage:(NSString*)image;

-(void)mySetSelected:(BOOL)selected;

@end
