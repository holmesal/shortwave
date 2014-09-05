//
//  SWChannelsLayout.m
//  Shortwave
//
//  Created by Ethan Sherr on 9/3/14.
//  Copyright (c) 2014 Ethan Sherr. All rights reserved.
//

#import "SWChannelsLayout.h"

@implementation SWChannelsLayout

-(UICollectionViewLayoutAttributes*)initialLayoutAttributesForAppearingItemAtIndexPath:(NSIndexPath *)itemIndexPath
{
    UICollectionViewLayoutAttributes *c = [super initialLayoutAttributesForAppearingItemAtIndexPath:itemIndexPath];
    
    if (itemIndexPath.row != 0)
    {
        c.alpha = 1.0f;
    }
    return c;
    
}

-(UICollectionViewLayoutAttributes*)finalLayoutAttributesForDisappearingItemAtIndexPath:(NSIndexPath *)itemIndexPath
{
    UICollectionViewLayoutAttributes *c = [super finalLayoutAttributesForDisappearingItemAtIndexPath:itemIndexPath];
    
    if (itemIndexPath.row != 0)
    {
        c.alpha = 1.0f;
    }
    return c;
}


@end
