//
//  ProfileCollectionViewCell.h
//  Firechat
//
//  Created by Ethan Sherr on 3/3/14.
//  Copyright (c) 2014 Buildco. All rights reserved.
//

#import <UIKit/UIKit.h>

@interface ProfileCollectionViewCell : UICollectionViewCell


-(void)boop;
//calculates the glow color and sets it on main thread
-(void)setImageURL:(NSURL*)url;
-(void)setTurnOn:(BOOL)isOn;

@end
