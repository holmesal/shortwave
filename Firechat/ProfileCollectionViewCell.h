//
//  ProfileCollectionViewCell.h
//  Firechat
//
//  Created by Ethan Sherr on 3/3/14.
//  Copyright (c) 2014 Buildco. All rights reserved.
//

#import <UIKit/UIKit.h>

@interface ProfileCollectionViewCell : UICollectionViewCell
@property (weak, nonatomic) IBOutlet AsyncImageView *asyncImageView;

-(void)boop;

@end
