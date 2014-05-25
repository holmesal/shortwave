//
//  FCMessage.m
//  Firechat
//
//  Created by Alonso Holmes on 12/23/13.
//  Copyright (c) 2013 Buildco. All rights reserved.
//

#import "FCMessage.h"
#import "FCUser.h"
#import <Mixpanel/Mixpanel.h>
#import "ESRobot.h"

@implementation FCMessage
- (id) initWithSnapshot:(FDataSnapshot *)snapshot
{
    if (self = [super init])
    {
        self.text = [snapshot.value valueForKey:@"text"];
        self.ownerID = [[snapshot.value valueForKey:@"meta"] objectForKey:@"ownerID"];
        self.icon = [snapshot.value valueForKey:@"icon"];
        self.color = [snapshot.value valueForKey:@"color"];
    }
    return self;
}

# pragma mark - posting a message
- (void)postText:(NSString *)text asOwner:(FCUser *)owner
{
    // Check if it's a special message
    NSMutableDictionary *results = [self filterMessage:text toOwner:owner];
    
    // Make the message
    
    NSNumber *accuracy = [NSNumber numberWithDouble:-1];
    NSNumber *lat = [NSNumber numberWithDouble:0];// [NSNumber numberWithDouble:self.location.coordinate.latitude];
    NSNumber *lon = [NSNumber numberWithDouble:0];//[NSNumber numberWithDouble:self.location.coordinate.longitude];
    if (self.location)
    {
        accuracy = [NSNumber numberWithDouble:self.location.horizontalAccuracy];
        lat = [NSNumber numberWithDouble:self.location.coordinate.latitude];
        lon = [NSNumber numberWithDouble:self.location.coordinate.longitude];
    }
    
    
    
    
    NSDictionary *message = @{@"type":@"FCMessage",
                              @"color": owner.color,
                              @"icon": owner.icon,
                              @"text": text,
                              @"meta":
                                  @{@"ownerID": owner.id, @"location":
                                        @{@"lat":lat, @"lon":lon, @"accuracy":accuracy}
                                    },
                              @"type":@"text"
                              };
    
    // Post the message TO YOUR OWN WALL FIRST (faster?)
    Firebase *ownerMessageRef = [[owner.ref childByAppendingPath:@"wall"] childByAutoId];
    [ownerMessageRef setValue:message];
    [self setTimestampAsNow:ownerMessageRef];
    
    // Should this message go to other people?
    if ([[results objectForKey:@"shouldPostToPeers"]  isEqual: @YES]) {
        
        // Grab the current list of earshot users
        NSArray *earshotIds = [owner.beacon.earshotUsers allKeys];
        
        
        if (IS_ON_SIMULATOR) {
            earshotIds = @[];
        }
        
        // Loop through and post to the firebase of every beacon in range
        for (NSString *earshotId in earshotIds)
        {
            NSLog(@"Posting message to %@",earshotId);
            // Post to the firebase wall of this beacon
            Firebase *otherPersonMessageRef = [[[[owner.rootRef childByAppendingPath:@"users"] childByAppendingPath:earshotId] childByAppendingPath:@"wall"] childByAutoId];
            [otherPersonMessageRef setValue:message];
            [self setTimestampAsNow:otherPersonMessageRef];
            
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
        
        // Catch two-word shortbot messages
        text = [text stringByReplacingOccurrencesOfString:@"short bot" withString:@"shortbot" options:NSCaseInsensitiveSearch range:NSMakeRange(0, [text length])];
        
        // Is this a shortbot message?
        if ([text rangeOfString:@"shortbot" options:NSCaseInsensitiveSearch].location != NSNotFound || [text rangeOfString:@"short bot" options:NSCaseInsensitiveSearch].location != NSNotFound) {
            // Create a hubot message
            NSDictionary *shortbotMessage = @{
                                              @"sender": owner.id,
                                              @"message": text,
                                              @"nearby": earshotIds
                                              };
            // post to the queue
            Firebase *shortbotQueueItemRef = [[owner.rootRef childByAppendingPath:@"shortbotQueue"] childByAutoId];
            [shortbotQueueItemRef setValue:shortbotMessage];
            
            // Check with shortbot
            ESRobot *robot = [[ESRobot alloc] init];
            [robot checkForCommand:text];
        }
        
        // Log the message to mixpanel
        Mixpanel *mixpanel = [Mixpanel sharedInstance];
        [mixpanel track:@"Message Sent" properties:@{
                                                     @"location":@{@"lat":lat, @"lon":lon, @"accuracy":accuracy, @"toUsers":earshotIds},
                                                     @"inRangeCount":[NSString stringWithFormat:@"%ld", (unsigned long)[earshotIds count]]}];
    }
    
    // Finally, post the contents of the filter message, if they exist
    NSDictionary *responseMessage = [results objectForKey:@"message"];
    if ([responseMessage count] != 0)
    {
        // Post the message TO YOUR OWN WALL FIRST (faster?)
        Firebase *ownerMessageRef = [[owner.ref childByAppendingPath:@"wall"] childByAutoId];
        [ownerMessageRef setValue:responseMessage];
        [self setTimestampAsNow:ownerMessageRef];
    }
    

}

- (void)setTimestampAsNow:(Firebase *)ref
{
    // BEWARE - this will cause a value event that will happen AFTER the value event for setting the data.
    // Act appropriately on the wall view controller
    [[ref childByAppendingPath:@"timestamp"] setValue:kFirebaseServerValueTimestamp];
}

- (NSMutableDictionary *)filterMessage:(NSString *)text toOwner:(FCUser *)owner
{
    NSMutableDictionary *results = [[NSMutableDictionary alloc] init];
    [results setObject:@YES forKey:@"shouldPostToPeers"];
    if ([text rangeOfString:@"#version"].location != NSNotFound) {
        // Don't post this to anyone else
        [results setObject:@NO forKey:@"shouldPostToPeers"];
        // Post the current version to yourself
        NSString *version = [[NSBundle mainBundle] objectForInfoDictionaryKey:@"CFBundleShortVersionString"];
        NSDictionary *message = @{@"color": @"292929" ,
          @"icon":@"shortbot",
          @"text":[NSString stringWithFormat:@"%@ iterations of awesomeness so far.",version],
          @"meta":@{@"ownerID":@"shortbot"}
          };
        // Store that shit
        [results setObject:message forKey:@"message"];
    }
    return results;
}

@end
