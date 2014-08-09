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
             @"meta":@{@"ownerID":@"shortbot"
             }
             }
             */
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
    
    NSNumber *priority = [NSNumber numberWithDouble:[NSDate date].timeIntervalSince1970*1000];
    
    
    return @{
                @"type": typeString,
                @"content": content,
                @"owner":ownerID,
                @"raw":self.text,
                @"parsed":@NO,
                @".priority":priority
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
            if ([StringFunction validateUrlString:self.text])
            {
                NSLog(@"self.text = %@ HAS a url in it!", self.text);
                Firebase *parseRequest = [[[Firebase alloc] initWithUrl:@"https://shortwave-dev.firebaseio.com/parseQueue"] childByAutoId];
                [parseRequest setValue:@{
                                         @"channel": channel,
                                         @"message": weakSelf.name
                                         } withCompletionBlock:^(NSError *error, Firebase *firebase)
                {
//                    NSLog(@"error = %@", error );
                }];
                
                
            }
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



 #pragma mark nearby functionality
-(void)postToAll
{
//    FCUser *owner = [FCUser owner];
//    //get all ibeacon users
//    NSArray *earshotIdsWithoutMe = [owner.beacon.earshotUsers allKeys];
//    
//    if (IS_ON_SIMULATOR)
//    {
//        earshotIdsWithoutMe = @[];
//    }
//    NSArray *earshotIds = [earshotIdsWithoutMe arrayByAddingObject:owner.id];
//    
//    [self postToUsers:earshotIds];
}

//-(void)postToUsers:(NSArray*)earshotIds
//{
//    FCUser *owner = [FCUser owner];
//
//    Firebase *messageFB = [[[Firebase alloc] initWithUrl:[NSString stringWithFormat:@"%@messages", FIREBASE_ROOT_URL]] childByAutoId];
//    NSNumber *priority = [NSNumber numberWithDouble:[[NSDate date] timeIntervalSince1970]]; //priority in wall of receiver
//    NSDictionary *message = [self toDictionary];
//    NSDictionary *messageValue = @{@"message": message,
//                                   @"ownerID": owner.id,
//                                   @"usersWithReadAccess":earshotIds};
//    [messageFB setValue:messageValue];
//
//    // Loop through and post to the firebase of every beacon in range (including self) add to PushQueue (excluding self)
//    for (NSString *earshotId in earshotIds)
//    {
//        // Post to the firebase wall of this beacon
//        //[[[[owner.rootRef childByAppendingPath:@"users"] childByAppendingPath:earshotId] childByAppendingPath:@"wall"] childByAutoId];
//        NSString *userPersonMessageUrl = [NSString stringWithFormat:@"%@users/%@/wall", FIREBASE_ROOT_URL, earshotId] ;
//        Firebase *userPersonMessageRef = [[[Firebase alloc] initWithUrl:userPersonMessageUrl] childByAutoId];
//        [userPersonMessageRef setValue:messageFB.name];
//        [userPersonMessageRef setPriority:priority];
//        
//        if (![earshotId isEqualToString:owner.id])
//        {
//            // Send a push notification to this user
//            NSString *otherPersonTokenUrl = [NSString stringWithFormat:@"%@users/%@/deviceToken", FIREBASE_ROOT_URL, earshotId];
//            Firebase *otherPersonTokenRef = [[Firebase alloc] initWithUrl:otherPersonTokenUrl];
//            [otherPersonTokenRef observeSingleEventOfType:FEventTypeValue withBlock:^(FDataSnapshot *snapshot) {
//                // Make the push notification IF the user allows it
//                if (snapshot && [snapshot value] && [snapshot value] != [NSNull null])
//                {
//                    NSDictionary *pushNotification = @{@"deviceToken": [snapshot value],
//                                                       @"alert": text};
//                    // Set the push notification
//                    Firebase *pushQueueRef = [[Firebase alloc] initWithUrl:[NSString stringWithFormat:@"%@pushQueue", FIREBASE_ROOT_URL]];
//                    [pushQueueRef setValue:pushNotification];
//                }
//            }];
//        }
//    }
//}

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


//-(void)OLDpostToAll/Users/ethan/Documents/iPhone workspace/earshot/Firechat/MessageModel.m
//{
//    FCUser *owner = [FCUser owner];
//    // Grab the current list of earshot users
//    NSArray *earshotIdsWithoutMe = [owner.beacon.earshotUsers allKeys];
//    
//    
//    if (IS_ON_SIMULATOR)
//    {
//        earshotIdsWithoutMe = @[];
//    }
//    
//    NSArray *earshotIds = [earshotIdsWithoutMe arrayByAddingObject:owner.id];
//    
//    // Loop through and post to the firebase of every beacon in range (including self) add to PushQueue (excluding self)
//    for (NSString *earshotId in earshotIds)
//    {
//        // Post to the firebase wall of this beacon
//        Firebase *otherPersonMessageRef = [[[[owner.rootRef childByAppendingPath:@"users"] childByAppendingPath:earshotId] childByAppendingPath:@"wall"] childByAutoId];
//        [otherPersonMessageRef setValue:[self toDictionary]];
//        
//        if (![earshotId isEqualToString:owner.id])
//        {
//            // Send a push notification to this user
//            Firebase *otherPersonTokenRef = [[[owner.rootRef childByAppendingPath:@"users"] childByAppendingPath:earshotId] childByAppendingPath:@"deviceToken"];
//            [otherPersonTokenRef observeSingleEventOfType:FEventTypeValue withBlock:^(FDataSnapshot *snapshot) {
//                // Make the push notification IF the user allows it
//                if (snapshot && [snapshot value] && [snapshot value] != [NSNull null])
//                {
//                    NSDictionary *pushNotification = @{@"deviceToken": [snapshot value],
//                                                       @"alert": text};
//                    // Set the push notification
//                    Firebase *pushQueueRef = [[owner.rootRef childByAppendingPath:@"pushQueue"] childByAutoId];
//                    [pushQueueRef setValue:pushNotification];
//                }
//            }];
//        }
//    }
//    
//    // Pass every message to shortbot 4 now
//    NSDictionary *shortbotMessage = @{
//                                      @"sender": owner.id,
//                                      @"message": text,
//                                      @"nearby": earshotIdsWithoutMe
//                                      };
//    // post to the queue
//    Firebase *shortbotQueueItemRef = [[owner.rootRef childByAppendingPath:@"shortbotQueue"] childByAutoId];
//    [shortbotQueueItemRef setValue:shortbotMessage];
//    
//    //        text = [text stringByReplacingOccurrencesOfString:@"short bot" withString:@"shortbot" options:NSCaseInsensitiveSearch range:NSMakeRange(0, [text length])];
//    
//    // Is this a shortbot message?
//    NSNumber *isShortbotMessage = @0;
//    if ([text rangeOfString:@"shortbot" options:NSCaseInsensitiveSearch].location != NSNotFound || [text rangeOfString:@"short bot" options:NSCaseInsensitiveSearch].location != NSNotFound) {
//        isShortbotMessage = @1;
//    }
//    
//    //    // Log the message to mixpanel
//    //    Mixpanel *mixpanel = [Mixpanel sharedInstance];
//    //    [mixpanel track:@"Message Sent" properties:@{
//    //                                                 @"location":@{
//    //                                                         @"lat":lat,
//    //                                                         @"lon":lon,
//    //                                                         @"accuracy":accuracy,
//    //                                                         @"toUsers":earshotIds},
//    //                                                 @"inRangeCount":[NSString stringWithFormat:@"%ld", (unsigned long)[earshotIds count]],
//    //                                                 @"shortbotMessage":isShortbotMessage}];
//}