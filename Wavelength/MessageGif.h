//
//  MessageGif.h
//  Shortwave
//
//  Created by Ethan Sherr on 7/14/14.
//  Copyright (c) 2014 Buildco. All rights reserved.
//

#import "MessageModel.h"
#import "MessageImage.h"
#import <AVFoundation/AVFoundation.h>

@interface MessageGif : MessageModel

@property (strong, nonatomic) NSString *mp4;
@property (strong, nonatomic) NSString *gif;


@property (strong, nonatomic) AVPlayer *player;
//@property (strong, nonatomic) AVPlayerLayer *playerLayer; // must be removed from superlayer upon get

-(void)generatePlayer;
-(AVPlayerLayer*)avplayerlayer;
//to initialize a message with raw values, so as not to forget any
//-(id)initWithSrc:(NSString*)src andIcon:(NSString *)icon color:(NSString *)color ownerID:(NSString *)ownerID text:(NSString *)text;

@end
