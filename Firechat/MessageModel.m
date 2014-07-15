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

#import "FCUser.h"

@interface MessageModel ()


@end


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
    if (dictionary && [dictionary isKindOfClass:[NSDictionary class]])
    {
        
        //parse what kind of message it is here
        NSString *type = dictionary[@"type"];
        
        NSLog(@"type = %@", type);
        
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
        if ([type isEqualToString:@"spotify_track"])
        {
            return [[MessageSpotifyTrack alloc] initWithDictionary:dictionary];
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
    
    //location stuff filled in from CLLocationManager
    CLLocation *location = [[FCUser owner].beacon getLocation];
    
    NSNumber *accuracy = [NSNumber numberWithDouble:-1];
    NSNumber *lat = [NSNumber numberWithDouble:0];// [NSNumber numberWithDouble:self.location.coordinate.latitude];
    NSNumber *lon = [NSNumber numberWithDouble:0];//[NSNumber numberWithDouble:self.location.coordinate.longitude];
    if (location)
    {
        accuracy = [NSNumber numberWithDouble:location.horizontalAccuracy];
        lat = [NSNumber numberWithDouble:location.coordinate.latitude];
        lon = [NSNumber numberWithDouble:location.coordinate.longitude];
    }
    
    return @{
                @"color": color.toHexString,
                @"icon": icon,
                @"type": typeString,
                @"text": text,
                @"content": content,
                @"timestamp": kFirebaseServerValueTimestamp,
                @"meta":
                    @{
                        @"ownerID":ownerID,
                        @"location":@{@"lat":lat, @"lon":lon, @"accuracy":accuracy}
                    }
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

-(void)postToAll
{
    FCUser *owner = [FCUser owner];
    // Grab the current list of earshot users
    NSArray *earshotIdsWithoutMe = [owner.beacon.earshotUsers allKeys];
    
    
    if (IS_ON_SIMULATOR) {
        earshotIdsWithoutMe = @[];
    }
    
    NSArray *earshotIds = [earshotIdsWithoutMe arrayByAddingObject:owner.id];
    
    // Loop through and post to the firebase of every beacon in range (including self) add to PushQueue (excluding self)
    for (NSString *earshotId in earshotIds)
    {
        // Post to the firebase wall of this beacon
        Firebase *otherPersonMessageRef = [[[[owner.rootRef childByAppendingPath:@"users"] childByAppendingPath:earshotId] childByAppendingPath:@"wall"] childByAutoId];
        [otherPersonMessageRef setValue:[self toDictionary]];
        
        if (![earshotId isEqualToString:owner.id])
        {
            // Send a push notification to this user
            Firebase *otherPersonTokenRef = [[[owner.rootRef childByAppendingPath:@"users"] childByAppendingPath:earshotId] childByAppendingPath:@"deviceToken"];
            [otherPersonTokenRef observeSingleEventOfType:FEventTypeValue withBlock:^(FDataSnapshot *snapshot) {
                // Make the push notification IF the user allows it
                if (snapshot && [snapshot value] && [snapshot value] != [NSNull null])
                {
                    NSDictionary *pushNotification = @{@"deviceToken": [snapshot value],
                                                       @"alert": text};
                    // Set the push notification
                    Firebase *pushQueueRef = [[owner.rootRef childByAppendingPath:@"pushQueue"] childByAutoId];
                    [pushQueueRef setValue:pushNotification];
                }
            }];
        }
    }
    
    // Pass every message to shortbot 4 now
    NSDictionary *shortbotMessage = @{
                                      @"sender": owner.id,
                                      @"message": text,
                                      @"nearby": earshotIdsWithoutMe
                                      };
    // post to the queue
    Firebase *shortbotQueueItemRef = [[owner.rootRef childByAppendingPath:@"shortbotQueue"] childByAutoId];
    [shortbotQueueItemRef setValue:shortbotMessage];
    
    //        text = [text stringByReplacingOccurrencesOfString:@"short bot" withString:@"shortbot" options:NSCaseInsensitiveSearch range:NSMakeRange(0, [text length])];
    
    // Is this a shortbot message?
    NSNumber *isShortbotMessage = @0;
    if ([text rangeOfString:@"shortbot" options:NSCaseInsensitiveSearch].location != NSNotFound || [text rangeOfString:@"short bot" options:NSCaseInsensitiveSearch].location != NSNotFound) {
        isShortbotMessage = @1;
    }
    
//    // Log the message to mixpanel
//    Mixpanel *mixpanel = [Mixpanel sharedInstance];
//    [mixpanel track:@"Message Sent" properties:@{
//                                                 @"location":@{
//                                                         @"lat":lat,
//                                                         @"lon":lon,
//                                                         @"accuracy":accuracy,
//                                                         @"toUsers":earshotIds},
//                                                 @"inRangeCount":[NSString stringWithFormat:@"%ld", (unsigned long)[earshotIds count]],
//                                                 @"shortbotMessage":isShortbotMessage}];
}

@end