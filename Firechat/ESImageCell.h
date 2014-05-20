//
//  ESImageCell.h
//  Shortwave
//
//  Created by Ethan Sherr on 5/18/14.
//  Copyright (c) 2014 Buildco. All rights reserved.
//

#import <UIKit/UIKit.h>

@interface ESImageCell : UITableViewCell

-(void)setImage:(UIImage *)image;
-(BOOL)hasImage;
-(void)setProfileImage:(NSString*)imageName;
-(void)setProfileColor:(NSString*)profileColor;
#define ESImageCell_NO_IMAGE_CELL_HEIGHT 70.0f
#define ESImageCell_IMAGE_CELL_HEIGHT 166.0f

@end
