//
//  SWChannelCell.h
//  Shortwave
//
//  Created by Ethan Sherr on 9/3/14.
//  Copyright (c) 2014 Ethan Sherr. All rights reserved.
//

#import <UIKit/UIKit.h>
#import "SWChannelModel.h"


@interface SWChannelCell : UICollectionViewCell <ChannelMutedResponderDelegate>

+(CGFloat)cellHeightGivenChannel:(SWChannelModel*)channel;


@property (strong, nonatomic) SWChannelModel *channelModel; //willSet and didSet responders
@property (strong, nonatomic) UIPanGestureRecognizer *panGesture;

-(void)hideLeaveChannelConfirmUI;
-(void)setIsSynchronized:(BOOL)synchronized;
//-(void)push;

@end
