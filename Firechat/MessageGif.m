//
//  MessageGif.m
//  Shortwave
//
//  Created by Ethan Sherr on 7/14/14.
//  Copyright (c) 2014 Buildco. All rights reserved.
//

#import "MessageGif.h"

@implementation MessageGif

-(id)initWithDictionary:(NSDictionary *)dictionary
{
    if (self = [super initWithDictionary:dictionary])
    {

    }
    return self;
}

-(MessageModelType)type
{
    return MessageModelTypeGif;
}

-(NSDictionary*)toDictionary
{
    NSDictionary *content = @{@"src": self.src,
                             @"width": self.width,
                             @"height": self.height};
    return [self toDictionaryWithContent:(NSDictionary*)content andType:@"gif"];
}

@end
