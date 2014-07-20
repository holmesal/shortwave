//
//  WallSource.h
//  Shortwave
//
//  Created by Ethan Sherr on 7/19/14.
//  Copyright (c) 2014 Buildco. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "ESSpringFlowLayout.h"

@interface WallSource : NSObject <UICollectionViewDataSource, UICollectionViewDelegate>

@property (strong, nonatomic, readonly) NSString *url;

-(id)initWithUrl:(NSString*)url collectionView:(UICollectionView*)cv andLayout:(ESSpringFlowLayout*)lay;

@end
