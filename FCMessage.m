//
//  FCMessage.m
//  Firechat
//
//  Created by Alonso Holmes on 12/23/13.
//  Copyright (c) 2013 Buildco. All rights reserved.
//

#import "FCMessage.h"
#import "FCUser.h"

@implementation FCMessage

- (id) initWithSnapshot:(FDataSnapshot *)snapshot
{
    self = [super init];
    if(!self) return Nil;
    
    self.text = [snapshot.value valueForKey:@"text"];
    self.ownerID = [snapshot.value valueForKey:@"ownerID"];
    self.icon = [snapshot.value valueForKey:@"icon"];
    self.color = [snapshot.value valueForKey:@"color"];
//    self.timestamp = [[snapshot.value valueForKey:@"timestamp"] stringValue];
    
    // Set up a firebase reference to this user
//    Firebase *ref = [[[[Firebase alloc] initWithUrl:@"https://orbit.firebaseio.com/"] childByAppendingPath:@"users"] childByAppendingPath:self.ownerID];
//    // Wait for the data
//    [ref observeSingleEventOfType:FEventTypeValue withBlock:^(FDataSnapshot *snapshot) {
////        NSLog(@"Got value for user %@",self.ownerID);
////        NSLog(@"%@",snapshot.value);
//        
////        NSLog(@"time: %@",[snapshot.value valueForKey:@"timestamp"]);
//        
//        // Set the values
////        self.username = [snapshot.value valueForKey:@"username"];
//        
////        self.displayName = [snapshot.value valueForKey:@"displayName"];
////        self.imageUrl = [[NSURL alloc] initWithString:[snapshot.value valueForKey:@"imageURL"]];
//        
//        // You should really do some error checking here
//        
//        // Run the callback block
//        block(nil, self);
//        
//    }];
    
    
    return self;
    
}

# pragma mark - posting a message
- (void)postText:(NSString *)text asOwner:(FCUser *)owner
{
    // TODO - Make the author
    // Make the message
    NSDictionary *message = @{@"ownerID": owner.id,
                              @"color": owner.color,
                              @"icon": owner.icon,
                              @"text": text};
    // Grab the current list of iBeacons
    NSArray *beaconIds = [owner.beacon getBeaconIds];
    
    NSLog(@"%@",beaconIds);
    
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
            NSDictionary *pushNotification = @{@"deviceToken": [snapshot value]};
            // Set the push notification
            Firebase *pushQueueRef = [[owner.rootRef childByAppendingPath:@"pushQueue"] childByAutoId];
            [pushQueueRef setValue:pushNotification];
        }];
    }
    
    // Also post to yourself
    Firebase *ownerMessageRef = [[owner.ref childByAppendingPath:@"wall"] childByAutoId];
    [ownerMessageRef setValue:message];
    [self setTimestampAsNow:ownerMessageRef];
    
    // Finally, post to the push notification queue with the device token from this user
    // First, get the device token to send to
//    Firebase *pushQueueRef = [[owner.rootRef childByAppendingPath:@"pushQueue"] childByAutoId];
//    NSDictionary *pushQueueItem = @{@"ownerID": owner.id,
//                                    @"color": owner.color,
//                                    @"icon": owner.icon,
//                                    @"text": text,
//                                    @"receivers": beaconIds};
//    [pushQueueRef setValue:pushQueueItem];
    
}

- (void)setTimestampAsNow:(Firebase *)ref
{
    // BEWARE - this will cause a value event that will happen AFTER the value event for setting the data.
    // Act appropriately on the wall view controller
    [[ref childByAppendingPath:@"timestamp"] setValue:kFirebaseServerValueTimestamp];
}

@end
