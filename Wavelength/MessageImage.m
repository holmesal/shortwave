//
//  MessageImage.m
//  Shortwave
//
//  Created by Ethan Sherr on 7/14/14.
//  Copyright (c) 2014 Buildco. All rights reserved.
//

#import "MessageImage.h"

@implementation MessageImage

@synthesize src;
@synthesize width;
@synthesize height;

@synthesize size;

-(id)initWithSrc:(NSString*)source andIcon:(NSString *)icon color:(NSString *)color ownerID:(NSString *)ownerID text:(NSString *)text width:(NSNumber*)w height:(NSNumber*)h
{
//    if (self = [super initWithIcon:icon color:color ownerID:ownerID text:text])
//    {
//        self.src = source;
//        self.width = w;
//        self.height = h;
//    }
    return self;
}

-(id)initWithDictionary:(NSDictionary *)dictionary andPriority:(double)priority
{
    if (self = [super initWithDictionary:dictionary andPriority:priority])
    {

    }
    return self;
} //x

-(BOOL)setDictionary:(NSDictionary *)dictionary
{
    BOOL success = [super setDictionary:dictionary];
    
    
    NSDictionary *content = dictionary[@"content"];
    if (content && [content isKindOfClass:[NSDictionary class]] )
    {
        
        src = content[@"src"];
        success = success && (src && [src isKindOfClass:[NSString class]]);

    }

   
    return success;
} //x

-(MessageModelType)type
{
    return MessageModelTypeImage;
} //x

-(NSDictionary*)toDictionary
{
    NSDictionary *content = @{@"src": src,
                              @"width": width,
                              @"height": height};
    return [self toDictionaryWithContent:content andType:@"image"];
} //x

-(CGSize)size
{
    return CGSizeMake(width.integerValue, height.integerValue);
}

-(NSString*)key
{
    return src;
} //x

@end