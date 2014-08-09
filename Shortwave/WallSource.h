//
//  WallSource.h
//  Shortwave
//
//  Created by Ethan Sherr on 7/19/14.
//  Copyright (c) 2014 Buildco. All rights reserved.
//

#import <Foundation/Foundation.h>
//#import "ESSpringFlowLayout.h"
#import "MessageModel.h"

@interface WallSource : NSObject <UICollectionViewDataSource, UICollectionViewDelegate>

//@property (strong, nonatomic) SWChannelModel *channelModel;

@property (strong, nonatomic, readonly) NSString *url;
@property (strong, nonatomic) UICollectionView *collectionView;
-(id)initWithUrl:(NSString*)url;// collectionView:(UICollectionView*)cv andLayout:(UICollectionViewLayout*)lay;
-(MessageModel*)wallObjectAtIndex:(NSInteger)index;

@property (assign, nonatomic) id target;


@end