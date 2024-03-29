//
//  SWChannelsViewController.h
//  Shortwave
//
//  Created by Ethan Sherr on 9/3/14.
//  Copyright (c) 2014 Ethan Sherr. All rights reserved.
//

#import <UIKit/UIKit.h>
#import "SWChannelModel.h"

@interface SWChannelsViewController : UIViewController <ChannelActivityIndicatorDelegate>

-(void)openChannelForChannelName:(NSString*)channelName;

@end
