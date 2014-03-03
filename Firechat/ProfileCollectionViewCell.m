//
//  ProfileCollectionViewCell.m
//  Firechat
//
//  Created by Ethan Sherr on 3/3/14.
//  Copyright (c) 2014 Buildco. All rights reserved.
//

#import "ProfileCollectionViewCell.h"
#import "UIView+Glow.h"

@implementation ProfileCollectionViewCell

- (id)initWithFrame:(CGRect)frame
{
    self = [super initWithFrame:frame];
    if (self)
    {
        // Initialization code
    }
    return self;
}

/*
// Only override drawRect: if you perform custom drawing.
// An empty implementation adversely affects performance during animation.
- (void)drawRect:(CGRect)rect
{
    // Drawing code
}
*/

-(void)boop
{
    [self startGlowingWithColor:[UIColor whiteColor] fromIntensity:0 toIntensity:1 repeat:NO];
}

@end
