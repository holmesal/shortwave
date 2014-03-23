//
//  FCMessage.m
//  Firechat
//
//  Created by Alonso Holmes on 12/23/13.
//  Copyright (c) 2013 Buildco. All rights reserved.
//

#import "FCMessage.h"
#import "FCUser.h"
#

@implementation FCMessage

- (id) initWithSnapshot:(FDataSnapshot *)snapshot
{
    self = [super init];
    if(!self) return Nil;
    
    self.text = [snapshot.value valueForKey:@"text"];
    self.ownerID = [snapshot.value valueForKey:@"ownerID"];
    self.icon = [snapshot.value valueForKey:@"icon"];
    self.color = [snapshot.value valueForKey:@"color"];
    
    
    return self;
    
}

# pragma mark - posting a message
- (void)postText:(NSString *)text asOwner:(FCUser *)owner
{
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
    
    
    NSDictionary *message = @{@"ownerID": owner.id,
                              @"color": owner.color,
                              @"icon": owner.icon,
                              @"text": text,
                              @"location":@{@"lat":lat, @"lon":lon, @"accuracy":accuracy} };
    // Grab the current list of iBeacons
    NSArray *beaconIds = [owner.beacon getBeaconIds];
    
    
    // Loop through and post to the firebase of every beacon in range
    for (NSString *beaconId in beaconIds)
    {
        NSLog(@"Posting message to %@",beaconId);
        // Post to the firebase wall of this beacon
        Firebase *otherPersonMessageRef = [[[[owner.rootRef childByAppendingPath:@"users"] childByAppendingPath:beaconId] childByAppendingPath:@"wall"] childByAutoId];
        [otherPersonMessageRef setValue:message];
        [self setTimestampAsNow:otherPersonMessageRef];
        
        // Send a push notification to this user
        Firebase *otherPersonTokenRef = [[[owner.rootRef childByAppendingPath:@"users"] childByAppendingPath:beaconId] childByAppendingPath:@"deviceToken"];
        [otherPersonTokenRef observeSingleEventOfType:FEventTypeValue withBlock:^(FDataSnapshot *snapshot) {
            // Make the push notification
            NSDictionary *pushNotification = @{@"deviceToken": [snapshot value],
                                               @"alert": text};
            // Set the push notification
            Firebase *pushQueueRef = [[owner.rootRef childByAppendingPath:@"pushQueue"] childByAutoId];
            [pushQueueRef setValue:pushNotification];
        }];
    }
    
//    // Also post to yourself
    Firebase *ownerMessageRef = [[owner.ref childByAppendingPath:@"wall"] childByAutoId];
    [ownerMessageRef setValue:message];
    [self setTimestampAsNow:ownerMessageRef];
    

}

- (void)setTimestampAsNow:(Firebase *)ref
{
    // BEWARE - this will cause a value event that will happen AFTER the value event for setting the data.
    // Act appropriately on the wall view controller
    [[ref childByAppendingPath:@"timestamp"] setValue:kFirebaseServerValueTimestamp];
}

@end
