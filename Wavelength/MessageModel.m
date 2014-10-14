git s
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
#import "MessageFile.h"
#import "ObjcConstants.h"

#import <CoreLocation/CoreLocation.h>
#import <Firebase/Firebase.h>


#import "NSString+Extension.h"
#import <Mixpanel/Mixpanel.h>

@interface MessageModel ()
@end


@implementation Section

-(id)init
{
    if (self = [super init])
    {
        _messagesDisplay = [[NSMutableArray alloc] init];
        _messagesOrder = [[NSMutableArray alloc] init];
        
        _isLoaded = NO;
        _numberOfLoadedCells = 0;
    }
    return self;
}
-(NSString*)toString
{
    NSString *str = @"[";
    for (MessageModel *model in _messagesOrder){
        str = [NSString stringWithFormat:@"%@,%@", str, model.text];
    }
    str = [NSString stringWithFormat:@"%@]", str];
    return str;
}
-(NSInteger)displayIndexForMessageModel:(MessageModel*)messageModel
{
    NSInteger displayIndex = 0;
    for (int i = 0; i < _messagesOrder.count ; i++)
    {
        MessageModel *otherMessageModel = _messagesOrder[i];
        if (otherMessageModel == messageModel)
        {
            break;
        } else
        if (!messageModel.isPending)
        {
            displayIndex++;
        }
    }
    return displayIndex;
}
@end


@implementation MessageModel

@synthesize ownerID;
@synthesize text;

@synthesize profileUrl;
@synthesize displayName;


-(id)initWithOwnerID:(NSString*)OwnerID andText:(NSString*)Text
{
    if (self = [super init])
    {
        self.ownerID = OwnerID;
        self.text = Text;
    }
    return self;
} //x

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
        if ([type isEqualToString:@"file"])
        {
            return [[MessageFile alloc] initWithDictionary:dictionary andPriority:priority];
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
} //x

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
} //x

-(NSDictionary*)toDictionaryWithContent:(NSDictionary*)content andType:(NSString*)typeString
{
    if (!content)
        content = @{};
    
//    NSNumber *accuracy = [NSNumber numberWithDouble:-1];
//    NSNumber *lat = [NSNumber numberWithDouble:0];// [NSNumber numberWithDouble:self.location.coordinate.latitude];
//    NSNumber *lon = [NSNumber numberWithDouble:0];//[NSNumber numberWithDouble:self.location.coordinate.longitude];

    
    NSMutableDictionary *mutableDictionary = [NSMutableDictionary dictionaryWithDictionary:
    @{
        @"type": typeString,
        @"content": content,
        @"owner":ownerID,
        //                @"raw":self.text,
        //                @"parsed":@NO,
        @".priority":kFirebaseServerValueTimestamp
    }];
    
    if (_usersMentioned && _usersMentioned.count != 0)
    {
        NSMutableArray *mentionsValue = [[NSMutableArray alloc] initWithCapacity:_usersMentioned.count];
        
        for (SWUser *user in _usersMentioned)
        {
            NSString *substring = [NSString stringWithFormat:@"%@%@", @"@", [user getAutoCompleteKey:_isPublic]];
            NSString *uuid = user.userID;
            NSDictionary *dict = @{@"substring": substring,
                                   @"uuid": uuid};
            [mentionsValue addObject:dict];
        }
        
        [mutableDictionary setObject:mentionsValue forKey:@"mentions"];
    }
    

    return mutableDictionary;
} //x

-(NSDictionary*)toDictionary
{
    return [self toDictionaryWithContent:@{@"text":self.text} andType:@"text"];
} //x

-(MessageModelType)type
{
    return MessageModelTypePlainText;
}

//1. (async) set current timestamp value to channel/<>/meta/latestMessagePriority (so that the actual latest messagePriority > channel.meta.latestMessagePriority
//2. (async) set message to the messages/<>/
//3. synchronously wait for 2 to finish and post to
//	a. url push queue
//	b. hubot push queue
-(void)sendMessageToChannel:(NSString*)channel
{
    //1.
    Firebase *latestMessagePriority = [[Firebase alloc] initWithUrl:[NSString stringWithFormat:@"%@channels/%@/meta/latestMessagePriority", Objc_kROOT_FIREBASE, channel]];
    [latestMessagePriority setValue:kFirebaseServerValueTimestamp withCompletionBlock:^(NSError *error, Firebase *firebase) {
        if (error)
        {
            NSLog(@"latestMessagePriority error saving: %@", error.localizedDescription);
        }
    }];
    
    //2.
    NSDictionary *value = [self toDictionary];
    Firebase *messagesChannel = [[[Firebase alloc] initWithUrl:[NSString stringWithFormat:@"%@messages/%@/", Objc_kROOT_FIREBASE, channel] ] childByAutoId];
    __weak typeof(self) weakSelf = self;
    [messagesChannel setValue:value withCompletionBlock:^(NSError *error, Firebase *firebase)
    {
        if (!error)
        {
            BOOL containsUrl = [NSString validateUrlString:self.text];
            BOOL containsHubot = ([self.text.lowercaseString rangeOfString:@"hubot"].location != NSNotFound);
            //3.
            [self addToPushQueueForChannel:channel];
            
            if (containsUrl || containsHubot)
            {//a
                [self addToParseQueue:channel];
            }
            
//            if (containsHubot)
//            {//b
//                [self addToHubotQueueForChannel:channel];
//            }
            
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
                  @"containsHubot": [NSNumber numberWithBool:containsHubot],
                  @"numChars": [NSNumber numberWithInt:numChars],
                  @"type": type
                  
                  }];
            
        }
    }];
    
    self.name = messagesChannel.name;

} //x
-(void)addToHubotQueueForChannel:(NSString*)channel
{
    NSAssert(self.name && channel, @"message name must not be nil '%@', ,channel name must not be nil '%@'", self.name, channel);
    NSString *pushQueueUrl = [NSString stringWithFormat:@"%@hubotQueue", Objc_kROOT_FIREBASE];
    Firebase *pushQueue = [[[Firebase alloc] initWithUrl:pushQueueUrl] childByAutoId];
    
    NSDictionary *value = @{@"channel":channel,
                            @"message":self.name};
    [pushQueue setValue:value withCompletionBlock:^(NSError *error, Firebase *firebase)
     {
         if (error)
         {
             //            NSLog(@"after pushQueue %@ setValue %@, error: %@", pushQueue, value, error.localizedDescription);
         }
     }];
}

-(void)addToParseQueue:(NSString*)channel
{
    NSString *pushQueueUrl = [NSString stringWithFormat:@"%@parseQueue", Objc_kROOT_FIREBASE];
    Firebase *pushQueue = [[[Firebase alloc] initWithUrl:pushQueueUrl] childByAutoId];
    
    NSDictionary *value = @{@"channel":channel,
                            @"message":self.name};
    [pushQueue setValue:value withCompletionBlock:^(NSError *error, Firebase *firebase)
     {
         if (error)
         {
             //            NSLog(@"after pushQueue %@ setValue %@, error: %@", pushQueue, value, error.localizedDescription);
         }
     }];
}
-(void)addToPushQueueForChannel:(NSString*)channel
{
    NSAssert(self.name && channel, @"message name must not be nil '%@', ,channel name must not be nil '%@'", self.name, channel);
    NSString *pushQueueUrl = [NSString stringWithFormat:@"%@pushQueue", Objc_kROOT_FIREBASE];
    Firebase *pushQueue = [[[Firebase alloc] initWithUrl:pushQueueUrl] childByAutoId];
    
    NSDictionary *value = @{@"channel":channel,
                            @"message":self.name};
    [pushQueue setValue:value withCompletionBlock:^(NSError *error, Firebase *firebase)
    {
        if (error)
        {
//            NSLog(@"after pushQueue %@ setValue %@, error: %@", pushQueue, value, error.localizedDescription);
        }
    }];
    
} //x

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
    displayName = [NSString stringWithFormat:@"%@ %@", user.firstName, user.lastName];
}

-(BOOL)hasAllData
{
    return ownerID && text && profileUrl && displayName;
}

@end


