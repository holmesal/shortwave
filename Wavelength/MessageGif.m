//
//  MessageGif.m
//  Shortwave
//
//  Created by Ethan Sherr on 7/14/14.
//  Copyright (c) 2014 Buildco. All rights reserved.
//

#import "MessageGif.h"
#import "AppDelegate.h"
#import "ASIHTTPRequest.h"

@interface MessageGif ()

@property (strong, nonatomic) AVPlayerLayer *layer;

@end

@implementation MessageGif

@synthesize mp4;
@synthesize layer;

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
}
-(void)generatePlayer;
{
    AppDelegate *appDelegate = (AppDelegate*)[UIApplication sharedApplication].delegate;
    
    NSString *filePath = [appDelegate.imageLoader filePathForMp4Url:mp4];
    
    AVURLAsset *asset = [AVURLAsset URLAssetWithURL:[NSURL fileURLWithPath:filePath] options:nil];
    //    AVURLAsset *asset = [AVURLAsset URLAssetWithURL:[NSURL URLWithString:mp4] options:nil];
    // Create an AVPlayerItem using the asset
    AVPlayerItem *item = [AVPlayerItem playerItemWithAsset:asset];
    
    _player = [AVPlayer playerWithPlayerItem:item];
    _player.muted = YES;
    
    //    playerLayer = [AVPlayerLayer playerLayerWithPlayer:_player];
    
    _player.actionAtItemEnd = AVPlayerActionAtItemEndNone;
}
-(BOOL)setDictionary:(NSDictionary*)dictionary
{
    BOOL success = [super setDictionary:dictionary];
    
    NSDictionary *content = dictionary[@"content"];
    if (content && [content isKindOfClass:[NSDictionary class]])
    {
        _gif = [content objectForKey:@"src"];
        NSString *thisMustNotBeNull = [content objectForKey:@"mp4"];
//        NSAssert(thisMustNotBeNull, @"content has no mp4? %@", content);
        if (thisMustNotBeNull)
        {
            self.mp4 = [content objectForKey:@"mp4"]; //optional
        }
        
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

-(AVPlayerLayer*)avplayerlayer
{
    if (!_player)
    {
        return nil;
    }
    if (!layer)
    {
        layer = [AVPlayerLayer playerLayerWithPlayer:self.player];
        layer.videoGravity = AVLayerVideoGravityResizeAspectFill;
    }
    return layer;

}

@end
