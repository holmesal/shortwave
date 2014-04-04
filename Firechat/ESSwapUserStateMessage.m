//
//  ESSwapIconMessage.m
//  Earshot
//
//  Created by Ethan Sherr on 4/2/14.
//  Copyright (c) 2014 Buildco. All rights reserved.
//

#import "ESSwapUserStateMessage.h"
#import "FCUser.h"

@interface ESSwapUserStateMessage ()

@end

@implementation ESSwapUserStateMessage

@synthesize fromColor, toColor;
@synthesize fromIcon, toIcon;

-(id)initWithSnapshot:(FDataSnapshot *)snapshot
{
    if (self = [super init])
    {
        NSString *type = [snapshot.value objectForKey:@"type"];
        
        NSAssert ([type isEqualToString:@"ESSwapUserStateMessage"], @"Sorry, type is %@, it must be ESSwapUserStateMessage", type);
        
        fromColor = [snapshot.value objectForKey:@"fromColor"];
        toColor = [snapshot.value objectForKey:@"toColor"];
        fromIcon = [snapshot.value objectForKey:@"fromIcon"];
        toIcon = [snapshot.value objectForKey:@"toIcon"];
        
        
        
    }
    return self;
}

- (id) initWithOldIcon:(NSString*)oldIcon oldColor:(NSString*)oldColor newIcon:(NSString*)newIcon newColor:(NSString*)newColor;
{
    if (self = [super init])
    {
        fromColor = oldColor;
        toColor = newColor;
        fromIcon = oldIcon;
        toIcon = newIcon;
    }
    return self;
}

-(void)postMessageAsOwner
{
    FCUser *owner = [FCUser owner];
  
    
    
//    NSDictionary *message = @{@"ownerID": owner.id,
//                              @"color": owner.color,
//                              @"icon": owner.icon,
//                              @"text": text,
//                              @"location":@{@"lat":lat, @"lon":lon, @"accuracy":accuracy} };
    
    NSNumber *accuracy = @-1.0;
    NSNumber *lat = @0;
    NSNumber *lon = @0;
    CLLocation *location = [owner.beacon getLocation];
    if (location)
    {
        accuracy = [NSNumber numberWithDouble:location.horizontalAccuracy];
        lat = [NSNumber numberWithDouble:location.coordinate.latitude];
        lon = [NSNumber numberWithDouble:location.coordinate.longitude];
    }
    
    NSDictionary *message = @{@"type": @"ESSwapUserStateMessage",
                              @"fromColor":self.fromColor,
                              @"toColor":self.toColor,
                              @"fromIcon":self.fromIcon,
                              @"toIcon":self.toIcon,
                              @"meta":
                                    @{@"ownerID": owner.id, @"location":
                                          @{@"lat":lat, @"lon":lon, @"accuracy":accuracy}
                                      }
                              };
    
    // Grab the current list of iBeacons
    NSArray *beaconIds = [owner.beacon getUsersInRange];
    
    
    // Loop through and post to the firebase of every beacon in range
    for (NSString *beaconId in beaconIds)
    {
        NSLog(@"Posting message to %@",beaconId);
        // Post to the firebase wall of this beacon
        Firebase *otherPersonMessageRef = [[[[owner.rootRef childByAppendingPath:@"users"] childByAppendingPath:beaconId] childByAppendingPath:@"wall"] childByAutoId];
        [otherPersonMessageRef setValue:message];
        [self setTimestampAsNow:otherPersonMessageRef];
        
//        // Send a push notification to this user
//        Firebase *otherPersonTokenRef = [[[owner.rootRef childByAppendingPath:@"users"] childByAppendingPath:beaconId] childByAppendingPath:@"deviceToken"];
////        [otherPersonTokenRef observeSingleEventOfType:FEventTypeValue withBlock:^(FDataSnapshot *snapshot) {
////            // Make the push notification
//////            NSDictionary *pushNotification = @{@"deviceToken": [snapshot value],
//////                                               @"alert": text};
//////            // Set the push notification
//////            Firebase *pushQueueRef = [[owner.rootRef childByAppendingPath:@"pushQueue"] childByAutoId];
//////            [pushQueueRef setValue:pushNotification];
////        }];
    }
    
    //also post to yourself
    //I actually don't want these posting to my wall.
    
    //Firebase *ownerMessageRef = [[owner.ref childByAppendingPath:@"wall"] childByAutoId];
    //[ownerMessageRef setValue:message];
    //[self setTimestampAsNow:ownerMessageRef];
}

- (void)setTimestampAsNow:(Firebase *)ref
{
    // BEWARE - this will cause a value event that will happen AFTER the value event for setting the data.
    // Act appropriately on the wall view controller
    [[ref childByAppendingPath:@"timestamp"] setValue:kFirebaseServerValueTimestamp];
}

@end
