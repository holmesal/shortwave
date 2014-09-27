//
//  MessageGif.m
//  Shortwave
//
//  Created by Ethan Sherr on 7/14/14.
//  Copyright (c) 2014 Buildco. All rights reserved.
//

#import "MessageGif.h"
#import "ASIHTTPRequest.h"

@implementation MessageGif

@synthesize playerLayer;
@synthesize mp4;

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

-(void)setMp4:(NSString *)newValue
{
    mp4 = newValue;
    AVURLAsset *asset = [AVURLAsset URLAssetWithURL:[NSURL URLWithString:mp4] options:nil];
    // Create an AVPlayerItem using the asset
    AVPlayerItem *item = [AVPlayerItem playerItemWithAsset:asset];

    _player = [AVPlayer playerWithPlayerItem:item];
    _player.muted = YES;

    playerLayer = [AVPlayerLayer playerLayerWithPlayer:_player];

    _player.actionAtItemEnd = AVPlayerActionAtItemEndNone;
}

-(BOOL)setDictionary:(NSDictionary*)dictionary
{
    BOOL success = [super setDictionary:dictionary];
    
    NSDictionary *content = dictionary[@"content"];
    if (content && [content isKindOfClass:[NSDictionary class]])
    {
        _gif = [content objectForKey:@"src"];
        self.mp4 = [content objectForKey:@"mp4"]; //optional
        
//        NSDictionary *src = content[@"src"];
//        if (src && [src isKindOfClass:[NSDictionary class]])
//        {
//            _mp4 = src[@"mp4"];
//            success = success && (_mp4 && [_mp4 isKindOfClass:[NSString class]]);
//            if (success)
//            {
//                // Create an AVURLAsset with an NSURL containing the path to the video
//                AVURLAsset *asset = [AVURLAsset URLAssetWithURL:[NSURL URLWithString:_mp4] options:nil];
//                // Create an AVPlayerItem using the asset
//                AVPlayerItem *item = [AVPlayerItem playerItemWithAsset:asset];
//                
//                _player = [AVPlayer playerWithPlayerItem:item];
//                _player.muted = YES;
//                
//                playerLayer = [AVPlayerLayer playerLayerWithPlayer:_player];
//                
//                _player.actionAtItemEnd = AVPlayerActionAtItemEndNone;
//                
//            }
//        }
        
    }
    
    return success && _gif && [_gif isKindOfClass:[NSString class]];
} //x

-(NSDictionary*)toDictionary
{
    NSDictionary *content = @{@"src": @{@"mp4": self.mp4}};
    return [self toDictionaryWithContent:(NSDictionary*)content andType:@"gif"];
}

-(void)fetchRelevantDataWithCompletion:(void (^)(void))completion
{
    if (mp4)
    {
        completion();
    } else
    {
        NSString *fetch = [NSString stringWithFormat:@"http://upload.gfycat.com/transcode?fetchUrl=%@", _gif];
        
//        NSLog(@"MESSAGEGIF about to start async call %@", fetch);
        
        __block ASIHTTPRequest *request = [ASIHTTPRequest requestWithURL:[NSURL URLWithString:fetch ]];
        
        [request setCompletionBlock:^{
//            NSLog(@"what thread am I on? main? %@", [NSThread mainThread] ? @"YES" : @"NO" );
//            NSLog(@"done fetching %@ ", fetch);
            NSData *data = [request responseData];
            NSString *dataString = [[NSString alloc] initWithData:data encoding:NSUTF8StringEncoding];
            
            NSError *error;
            NSDictionary *dictionary = [NSJSONSerialization JSONObjectWithData:data options:NSJSONReadingAllowFragments error:&error];
            NSString *maybeMp4 = [dictionary objectForKey:@"mp4Url"];
            
            if (maybeMp4 && [maybeMp4 isKindOfClass:[NSString class]])
            {
                self.mp4 = maybeMp4;
                completion();
            }
            
//            NSLog(@"data = %@", dataString);
//            NSLog(@"error = %@", error.localizedDescription);
        }];
        
        [request startAsynchronous];
        
        
    }
}

@end
