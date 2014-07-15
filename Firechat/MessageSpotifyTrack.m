//
//  MessageSpotifyTrack.m
//  Shortwave
//
//  Created by Ethan Sherr on 7/14/14.
//  Copyright (c) 2014 Buildco. All rights reserved.
//

#import "MessageSpotifyTrack.h"

@implementation MessageSpotifyTrack

@synthesize title, artist, uri, albumImage;

-(id)initWithTitle:(NSString*)Title uri:(NSString*)Uri artist:(NSString*)Artist albumImage:(NSString*)AlbumImage andIcon:(NSString *)icon color:(NSString *)color ownerID:(NSString *)ownerID text:(NSString *)text
{
    if (self = [super initWithIcon:icon color:color ownerID:ownerID text:text])
    {
        self.title = Title;
        self.artist = Artist;
        self.uri = Uri;
        self.albumImage = AlbumImage;
    }
    return self;
}

-(id)initWithDictionary:(NSDictionary *)dictionary
{
    if (self = [super initWithDictionary:dictionary])
    {

    }
    return self;
}

-(BOOL)setDictionary:(NSDictionary *)dictionary
{
    BOOL succcess = [super setDictionary:dictionary];
    NSDictionary *content = dictionary[@"content"];
    /*
     @{
     @"color": @"292929" ,
     @"icon":@"shortbot",
     @"type":@"spotify_track",
     @"text": @"shared a song with you:",
     
     @"content":@{
     @"title":@"I Am A Hologram",
     @"artist":@"Mister Heavenly",
     @"uri":@"spotify:track:1OpkIbqR0fKlRSt33oiIGa",
     @"albumImage":@"https://i.scdn.co/image/31d501956beee416abc15c9d7709977afe473634"
     },
     @"meta":@{@"ownerID":@"shortbot"}
     }
     */
    if (content && [content isKindOfClass:[NSDictionary class]])
    {
        NSArray *keys = @[@"title", @"artist", @"uri", @"albumImage"];
       
        for (NSString *key in keys)
        {
            NSString *value = [content objectForKey:key];
            succcess = succcess && (value && [value isKindOfClass:[NSString class]]);
            [self setValue:value forKey:key];
        }
        
    } else
    {
        succcess = NO;
    }
    
    
    return succcess;
}

-(MessageModelType)type
{
    return MessageModelTypeSpotifyTrack;
}

-(NSDictionary*)toDictionary
{
    NSDictionary *content = @{@"title": title,
                             @"artist": artist,
                             @"uri": uri,
                             @"albumImage": albumImage};
    
    return [self toDictionaryWithContent:content andType:@"spotify_track"];
}

@end