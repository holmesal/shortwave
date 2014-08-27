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
#import "MessageWebSite.h"

#import <CoreLocation/CoreLocation.h>
#import <Firebase/Firebase.h>
#import "Shortwave-Swift.h"

@interface MessageModel ()


@end


@implementation MessageModel

@synthesize ownerID;
@synthesize text;

@synthesize profileUrl;
@synthesize firstName;


-(id)initWithOwnerID:(NSString*)OwnerID andText:(NSString*)Text
{
    if (self = [super init])
    {
        self.ownerID = OwnerID;
        self.text = Text;
    }
    return self;
}

+(MessageModel*)messageModelFromValue:(id)value andPriority:(double)priority
{
//    NSLog(@"new message with priority %f", priority);
    if ([value isKindOfClass:[NSDictionary class]])
    {//receiving message itself.
        
        NSDictionary *dictionary = value;
        //parse what kind of message it is here
        NSString *type = dictionary[@"type"];
        

        if ([type isEqualToString:@"text"])
        {
            return [[MessageModel alloc] initWithDictionary:dictionary andPriority:priority];
        } else
        if ([type isEqualToString:@"gif"])
        {
            return [[MessageGif alloc] initWithDictionary:dictionary andPriority:priority];
        } else
        if ([type isEqualToString:@"image"])
        {
            return [[MessageImage alloc] initWithDictionary:dictionary andPriority:priority];
        } else
        if ([type isEqualToString:@"spotify_track"])
        {
            return [[MessageSpotifyTrack alloc] initWithDictionary:dictionary andPriority:priority];
        } else
        if ([type isEqualToString:@"website"])
        {
            return [[MessageWebSite alloc] initWithDictionary:dictionary andPriority:priority];
        } else
        if ([type isEqualToString:@"personal_video"])
        {
            NSAssert(NO, @"not yet implemented type: personal_video");
        } else
        if ([type isEqualToString:@"personal_photo"])
        {
            NSAssert(NO, @"not yet implemented type: personal_photo");
        }
        
        NSLog(@"MessageModel NOT DEFINED FOR TYPE '%@' FOR DATA %@", type, dictionary);
//        NSAssert(NO, @"type is %@ and dict is %@", type, dictionary);
        
    }
    
    return nil;
}

-(id)initWithDictionary:(NSDictionary*)dictionary andPriority:(double)priority;
{
    if (self = [super init])
    {
        self.priority = priority;
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
    NSDictionary *content = dictionary[@"content"];
    BOOL success = YES;
    
//    icon = dictionary[@"icon"];
//    success = success && (icon && [icon isKindOfClass:[NSString class]]);
    
        ownerID = dictionary[@"owner"];
        success = success && (ownerID && [ownerID isKindOfClass:[NSString class]]);
    
//    NSString *colorString = dictionary[@"color"];
//    if (colorString && [colorString isKindOfClass:[NSString class]])
//    {
//        color = [UIColor colorWithHexString:colorString];
//    } else
//    {
//        success = NO;
//    }
    
    if (content && [content isKindOfClass:[NSDictionary class]])
    {
        //text is optional
        text = content[@"text"];
//        success = success && (text && [text isKindOfClass:[NSString class]]);
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
    
    NSNumber *accuracy = [NSNumber numberWithDouble:-1];
    NSNumber *lat = [NSNumber numberWithDouble:0];// [NSNumber numberWithDouble:self.location.coordinate.latitude];
    NSNumber *lon = [NSNumber numberWithDouble:0];//[NSNumber numberWithDouble:self.location.coordinate.longitude];
//    if (location)
//    {
//        accuracy = [NSNumber numberWithDouble:location.horizontalAccuracy];
//        lat = [NSNumber numberWithDouble:location.coordinate.latitude];
//        lon = [NSNumber numberWithDouble:location.coordinate.longitude];
//    }
    
    
    /*
     "type": String,
     "content": Dictionary,
     "owner": String,
     "raw": String,
     "parsed": Bool
     ".priority": Unix time in milliseconds
     */

    return @{
                @"type": typeString,
                @"content": content,
                @"owner":ownerID,
                @"raw":self.text,
                @"parsed":@NO,
                @".priority":kFirebaseServerValueTimestamp
            };
}

-(NSDictionary*)toDictionary
{
    return [self toDictionaryWithContent:@{@"text":self.text} andType:@"text"];
}

-(MessageModelType)type
{
    return MessageModelTypePlainText;
}

//adds it to the push queue too
-(void)sendMessageToChannel:(NSString*)channel
{
    
    NSDictionary *value = [self toDictionary];
    Firebase *messagesChannel = [[[Firebase alloc] initWithUrl:[NSString stringWithFormat:@"https://shortwave-dev.firebaseio.com/messages/%@/", channel] ] childByAutoId];
    
    __weak typeof(self) weakSelf = self;
    [messagesChannel setValue:value withCompletionBlock:^(NSError *error, Firebase *firebase)
    {
        if (!error)
        {
            BOOL containsUrl = NO;
            if ([StringFunction validateUrlString:self.text])
            {
                containsUrl = YES;
                Firebase *parseRequest = [[[Firebase alloc] initWithUrl:@"https://shortwave-dev.firebaseio.com/parseQueue"] childByAutoId];
                [parseRequest setValue:@{
                                         @"channel": channel,
                                         @"message": weakSelf.name
                                         } withCompletionBlock:^(NSError *error, Firebase *firebase)
                {
                    NSLog(@"error = %@", error );
                }];
                
            }
            
            //mixpanel vars
            NSInteger numChars = 0;
            if (self.text)
            {
                numChars = self.text.length;
            }
            
            NSNumber *type =  [NSNumber numberWithInt:self.type];
            if (!type)
            {
                type = [NSNumber numberWithInt:-1];
            }
            
            [[Mixpanel sharedInstance] track:@"Send Message" properties:
                @{@"containsUrl": [NSNumber numberWithBool:containsUrl],
                  @"numChars": [NSNumber numberWithInt:numChars],
                  @"type": type
                  
                  }];
            
        }
    }];
    self.name = messagesChannel.name;
    
    [self addToPushQueueForChannel:channel];

    
}

-(void)addToPushQueueForChannel:(NSString*)channel
{
    NSAssert(self.name && channel, @"message name must not be nil '%@', ,channel name must not be nil '%@'", self.name, channel);
    Firebase *pushQueue = [[[Firebase alloc] initWithUrl:@"https://shortwave-dev.firebaseio.com/pushQueue"] childByAutoId];
    
    NSDictionary *value = @{@"channel":channel,
                            @"message":self.name};
    [pushQueue setValue:value withCompletionBlock:^(NSError *error, Firebase *firebase)
    {
        if (error)
        {
            NSLog(@"after pushQueue %@ setValue %@, error: %@", pushQueue, value, error.localizedDescription);
        }
    }];
    
}

#pragma mark override this function for more data fetch before display
-(void)fetchRelevantDataWithCompletion:(void (^)(void) )completion
{
    completion();
}
#pragma mark override this function for more data fetch before display
-(BOOL)isReadyForDisplay
{
    return YES;
}


 #pragma mark nearby functionality
-(void)postToAll
{

}



-(void)setUserData:(SWUser*)user
{
    profileUrl = user.photo;
    firstName = user.firstName;
}

-(BOOL)hasAllData
{
    return ownerID && text && profileUrl && firstName;
}

@end


