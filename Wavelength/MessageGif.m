//
//  MessageGif.m
//  Shortwave
//
//  Created by Ethan Sherr on 7/14/14.
//  Copyright (c) 2014 Buildco. All rights reserved.
//

#import "MessageGif.h"

@implementation MessageGif

@synthesize playerLayer;

-(id)initWithDictionary:(NSDictionary *)dictionary andPriority:(double)priority
{
    if (self = [super initWithDictionary:dictionary andPriority:priority])
    {

    }
    return self;
} //x

-(MessageModelType)type
{
    return MessageModelTypeGif;
} //x

-(BOOL)setDictionary:(NSDictionary*)dictionary
{
    BOOL success = [super setDictionary:dictionary];
    
    NSDictionary *content = dictionary[@"content"];
    if (content && [content isKindOfClass:[NSDictionary class]])
    {
        NSDictionary *src = content[@"src"];
        if (src && [src isKindOfClass:[NSDictionary class]])
        {
            _mp4 = src[@"mp4"];
            success = success && (_mp4 && [_mp4 isKindOfClass:[NSString class]]);
            if (success)
            {
                // Create an AVURLAsset with an NSURL containing the path to the video
                AVURLAsset *asset = [AVURLAsset URLAssetWithURL:[NSURL URLWithString:_mp4] options:nil];
                // Create an AVPlayerItem using the asset
                AVPlayerItem *item = [AVPlayerItem playerItemWithAsset:asset];
                
                _player = [AVPlayer playerWithPlayerItem:item];
                _player.muted = YES;
                
                playerLayer = [AVPlayerLayer playerLayerWithPlayer:_player];
                
                _player.actionAtItemEnd = AVPlayerActionAtItemEndNone;
                
            }
        }
    }
    
    return success;
} //x

-(NSDictionary*)toDictionary
{
    NSDictionary *content = @{@"src": @{@"mp4": self.mp4}};
    return [self toDictionaryWithContent:(NSDictionary*)content andType:@"gif"];
}

@end
