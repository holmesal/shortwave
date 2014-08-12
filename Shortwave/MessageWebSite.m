//
//  MessageWebSite.m
//  Shortwave
//
//  Created by Ethan Sherr on 8/11/14.
//  Copyright (c) 2014 Ethan Sherr. All rights reserved.
//

#import "MessageWebSite.h"
#import "Shortwave-Swift.h"

@implementation MessageWebSite

@synthesize url;
@synthesize siteName;
@synthesize image;
@synthesize description;
@synthesize favicon;
@synthesize title;

-(id)initWithDictionary:(NSDictionary*)dictionary andPriority:(double)priority
{
    if (self = [super initWithDictionary:dictionary andPriority:priority])
    {
        
    }
    return self;
}

-(NSArray*)keys
{
    return @[@"url", @"siteName", @"image", @"description", @"favicon", @"title"];
}

-(BOOL)setDictionary:(NSDictionary *)dictionary
{
    BOOL success = [super setDictionary:dictionary];
    
    NSInteger validValueCount = 0;

    NSDictionary *content = dictionary[@"content"];
    if (content && [content isKindOfClass:[NSDictionary class]])
    {
        NSArray *keys = self.keys;
        
        for (NSString *key in keys)
        {
            NSString *value = content[key];
            
            
            if (value && ![value isKindOfClass:[NSString class]])
            {
                success = NO;
            } else
            {
                validValueCount++;
                [self setValue:value forKey:key];
            }
        }
    }
    
    return success && (validValueCount > 1);
}

-(MessageModelType)type
{
    return MessageModelTypeWebSite;
}

-(NSDictionary*)toDictionary
{
    NSArray *keys = self.keys;
    NSMutableDictionary *content = [[NSMutableDictionary alloc] initWithCapacity:keys.count];
    
    for (NSString *key in keys)
    {
        NSString *value = [self valueForKey:key];
        if (value)
        {
            [content setObject:value forKey:key];
        }
    }
    
    return [self toDictionaryWithContent:content andType:@"website"];
}

-(BOOL)isReadyForDisplay
{
    AppDelegate *appDelegate = ( AppDelegate *)[UIApplication sharedApplication].delegate;
    return (favicon == nil) || ([appDelegate.imageLoader hasImage:favicon]);
}

-(void)fetchRelevantDataWithCompletion:(void (^)(void) )completion
{
    AppDelegate *appDelegate = (AppDelegate *)[UIApplication sharedApplication].delegate;
    
    [appDelegate.imageLoader loadImage:favicon completionBlock:^(UIImage *img, BOOL synchronous)
    {
        completion();
    } progressBlock:^(float progress){
        
    }];
}

@end
