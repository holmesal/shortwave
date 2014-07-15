//
//  MessageGif.m
//  Shortwave
//
//  Created by Ethan Sherr on 7/14/14.
//  Copyright (c) 2014 Buildco. All rights reserved.
//

#import "MessageGif.h"

@implementation MessageGif

@synthesize src;

-(id)initWithSrc:(NSString*)source andIcon:(NSString *)icon color:(NSString *)color ownerID:(NSString *)ownerID text:(NSString *)text
{
    if (self = [super initWithIcon:icon color:color ownerID:ownerID text:text])
    {
        self.src = source;
    }
    return self;
}

-(id)initWithDictionary:(NSDictionary *)dictionary
{
    if (self = [super initWithDictionary:dictionary])
    {
        if (![self setDictionary:dictionary])
        {
            return nil;
        }
    }
    return self;
}

-(BOOL)setDictionary:(NSDictionary *)dictionary
{
    BOOL success = YES;
    /*
     {@"color": @"292929" ,
     @"icon":@"shortbot",
     @"type":@"gif",
     @"content":@{
     @"src": @"http://i.imgur.com/dupSbtr.gif"
     },
     @"meta":@{@"ownerID":@"shortbot"}
     }
     */
    NSDictionary *content = dictionary[@"content"];
    if (content && [content isKindOfClass:[NSDictionary class]])
    {
        src = content[@"src"];
    }
    
    return success;
}

-(MessageModelType)type
{
    return MessageModelTypeGif;
}

-(NSDictionary*)toDictionary
{
    NSDictionary *content = @{@"src": src};
    return [self toDictionaryWithContent:(NSDictionary*)content andType:@"gif"];
}

@end
