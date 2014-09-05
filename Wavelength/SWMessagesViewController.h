//
//  SWMessagesViewController.h
//  Shortwave
//
//  Created by Ethan Sherr on 9/4/14.
//  Copyright (c) 2014 Ethan Sherr. All rights reserved.
//

#import <UIKit/UIKit.h>
#import "SWChannelModel.h"

@interface SWMessagesViewController : UIViewController <ChannelCellActionDelegate, UIScrollViewDelegate>

@property (strong, nonatomic) SWChannelModel *channelModel; // didSet

@end
