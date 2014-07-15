//
//  MessageModel.m
//  Shortwave
//
//  Created by Ethan Sherr on 7/14/14.
//  Copyright (c) 2014 Buildco. All rights reserved.
//

#import "MessageModel.h"


#import "MessageGif.h"
#import "MessageImage.h"
#import "MessageSpotifyTrack.h"


@implementation MessageModel

@synthesize icon;
@synthesize color;
@synthesize ownerID;
@synthesize text;


-(id)initWithIcon:(NSString*)icon color:(NSString*)colorString ownerID:(NSString*)ownerID text:(NSString*)text
{
    if (self = [super init])
    {
        self.icon = icon;
        self.color = [UIColor colorWithHexString:colorString];
        self.ownerID = ownerID;
        self.text = text;
    }
    return self;
}

+(MessageModel*)messageModelFromDictionary:(NSDictionary*)dictionary
{
    //parse what kind of message it is here
    NSString *type = dictionary[@"type"];
    
    if ([type isEqualToString:@"text"])
    {
        return [[MessageModel alloc] initWithDictionary:dictionary];
        
    } else
    if ([type isEqualToString:@"gif"])
    {
        return [[MessageGif alloc] initWithDictionary:dictionary];
        
    } else
    if ([type isEqualToString:@"image"])
    {
        return [[MessageImage alloc] initWithDictionary:dictionary];
    } else
    if ([type isEqualToString:@"link_web"])
    {
        NSAssert(NO, @"not yet implemented type: link_web");
        /*
         {
         @"color": @"292929" ,
         @"icon":@"shortbot",
         @"type":@"link-web",
         @"content":@{
         @"url":@"http://google.com",
         @"title":@"Google - We're Not Evil, We Promise!",
         @"description":@"Something awful."
         },
         @"meta":@{@"ownerID":@"shortbot"}
         }
         */
    } else
    if ([type isEqualToString:@"spotify_track"])
    {
        return [[MessageSpotifyTrack alloc] initWithDictionary:dictionary];
    } else
    if ([type isEqualToString:@"personal_video"])
    {
        NSAssert(NO, @"not yet implemented type: personal_video");
    } else
    if ([type isEqualToString:@"personal_photo"])
    {
        NSAssert(NO, @"not yet implemented type: personal_photo");
    }
    
    NSAssert(NO, @"type is %@ and dict is %@", type, dictionary);
    
    return nil;
}

-(id)initWithDictionary:(NSDictionary *)dictionary
{
    if (self = [super init])
    {
        if (![self setDictionary:dictionary])
        {
            return nil;
        }
    }
    return self;
}

//bool success?  Override this to set more data!
-(BOOL)setDictionary:(NSDictionary*)dictionary
{
    NSDictionary *meta = dictionary[@"meta"];
    BOOL success = YES;
    
    icon = dictionary[@"icon"];
    success = success && (icon && [icon isKindOfClass:[NSString class]]);
    
    text = dictionary[@"text"];
    success = success && (text && [text isKindOfClass:[NSString class]]);
    
    NSString *colorString = dictionary[@"color"];
    if (colorString && [colorString isKindOfClass:[NSString class]])
    {
        color = [UIColor colorWithHexString:colorString];
    } else
    {
        success = NO;
    }
    
    if (meta && [meta isKindOfClass:[NSDictionary class]])
    {
        ownerID = meta[@"ownerID"];
        success = success && (ownerID && [ownerID isKindOfClass:[NSString class]]);
    } else
    {
        success = NO;
    }
    
    return success;
}

-(NSDictionary*)toDictionaryWithContent:(NSDictionary*)content andType:(NSString*)typeString
{
    if (!content)
        content = @{};
    
    return @{
                @"color": color,
                @"icon": icon,
                @"type": typeString,
                @"text": text,
                @"content": content,
                @"timestamp": kFirebaseServerValueTimestamp,
                @"meta":@{@"ownerID":ownerID}
            };
}
-(NSDictionary*)toDictionary
{
    return [self toDictionaryWithContent:nil andType:@"text"];
}

-(MessageModelType)type
{
    return MessageModelTypePlainText;
}


@end