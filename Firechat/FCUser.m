//
//  FCUser.m
//  Firechat
//
//  Created by Alonso Holmes on 12/26/13.
//  Copyright (c) 2013 Buildco. All rights reserved.
//

#import "FCUser.h"
#import <Firebase/Firebase.h>
#include <stdlib.h>
//#import "FirebaseSimpleLogin/FirebaseSimpleLogin.h"

typedef void (^CompletionBlockType)(id);

@interface FCUser ()
@property (nonatomic, copy) CompletionBlockType completionBlock;
@end

@implementation FCUser
//
//
//
//// Make that shit a singleton
//+ (void) initialize
//{
//    static BOOL initialized = NO;
//    if(!initialized){
//        initialized = YES;
//        self = [[self alloc] init];
//    }
//}

- (id)init
{
    self = [super init];
    if (self) {
        self.beacon = [[FCBeacon alloc] init];
    }
    return self;
}

- (void) initWithId:(NSString *)id
{
    self.id = id;
    [self populateFromFirebaseId:id];
    
//    return self;
}

- (id) initWithSnapshot:(NSDictionary *)snapshot
{
    
    self = [super init];
    if(!self) return nil;
    
    self.username = [snapshot objectForKey:@"username"];
    self.imageURL = [snapshot valueForKey:@"imageURL"];
    
    return self;
}

- (id) initWithSnapshot:(NSDictionary *)snapshot andID:(NSString *)id
{
    self = [self initWithSnapshot:snapshot];
    if(!self) return nil;
    
    self.id = id;
    
    return self;
}

//- (id) initWithTwitter:(FAUser *)twitterUser
//{
//
//    NSLog(@"%@",twitterUser.thirdPartyUserData);
//    
//    // Create the new user
//    self = [super init];
//    if(!self) return nil;
//    
//    // Check for an existing user by twitter id
//    // If one exists, populate with that one instead of creating a new one
////    BOOL existing = [self checkExisting:@"twitter"];
////
////    if (!existing) {
////        return [self populateFromFirebaseId:(NSString *)]
////    }
//    
//    // Populate
//    self.username =[twitterUser.thirdPartyUserData valueForKey:@"username"];
//    self.displayName = [twitterUser.thirdPartyUserData valueForKey:@"displayName"];
//    self.imageURL = [twitterUser.thirdPartyUserData valueForKey:@"profile_image_url"];
//    self.description =[twitterUser.thirdPartyUserData valueForKey:@"description"];
//    self.thirdPartyId = [NSString stringWithFormat:@"twitter:%@", twitterUser.userId];
//    
//    // Generate an id
//    self.major = [[NSNumber alloc] initWithInt:arc4random() % 65535];
////    self.major = [self formatValue:self.major forDigits:@4[self.major length]]
//    self.minor = [[NSNumber alloc] initWithInt:arc4random() % 65535];
//    self.id = [NSString stringWithFormat:@"%@:%@", self.major, self.minor];
//    NSLog(@"Generated id: %@",self.id);
//    
//    // Create ref via firebase
//    self.ref = [[[[Firebase alloc] initWithUrl:@"https://orbit.firebaseio.com/"] childByAppendingPath:@"users"] childByAppendingPath:self.id];
//    
//    // This ref should be null -> dump data in here
//    [[self.ref childByAppendingPath:@"username" ] setValue:self.username];
//    [[self.ref childByAppendingPath:@"major" ] setValue:self.major];
//    [[self.ref childByAppendingPath:@"minor" ] setValue:self.minor];
//    [[self.ref childByAppendingPath:@"displayName" ] setValue:self.displayName];
//    [[self.ref childByAppendingPath:@"imageURL"] setValue:self.imageURL];
//    [[self.ref childByAppendingPath:@"description"] setValue:self.description];
//    
//    // Logged in, so start broadcasting!
//    [self.beacon startBroadcastingWithMajor:self.major andMinor:self.minor];
//    
//    return self;
//}

- (void) populateFromFirebaseId:(NSString *)userId
{
    
    // Firebase ref for this user
    self.ref = [[[[Firebase alloc] initWithUrl:@"https://orbit.firebaseio.com/"] childByAppendingPath:@"users"] childByAppendingPath:userId];
    
    // Fill in the data on a value event
    [self.ref observeEventType:FEventTypeValue withBlock:^(FDataSnapshot *snapshot) {
        NSLog(@"Got user back from firebase...");
//        NSLog([snapshot.value description]);
        if(snapshot.value){
            // Store the dater
            self.username = [snapshot.value objectForKey:@"username"];
            self.displayName = [snapshot.value objectForKey:@"displayName"];
            self.major = [snapshot.value objectForKey:@"major"];
            self.minor = [snapshot.value objectForKey:@"minor"];
            self.imageURL = [snapshot.value objectForKey:@"imageURL"];
            self.description = [snapshot.value objectForKey:@"description"];
            
            // Start broadcasting
            [self.beacon startBroadcastingWithMajor:self.major andMinor:self.minor];
            
            // Run the completion block if it exists
            [self runCompletionBlock];
        }
        
    }];

}

- (void) setupWithTwitter:(FAUser *)twitterUser
{
    
    // Connect to the twitter -> orbiter entity
    Firebase *twitterRef = [[[Firebase alloc] initWithUrl:@"https://orbit.firebaseio.com/providers/twitter"] childByAppendingPath:twitterUser.userId];
    // Will trigger an empty snapshot if this user doesn't exist
    [twitterRef observeSingleEventOfType:FEventTypeValue withBlock:^(FDataSnapshot *snapshot) {
        if(snapshot.value == [NSNull null]) {
            NSLog(@"This user is empty!");
            [self createWithTwitterUser:twitterUser];
        }
        else {
            NSLog(@"This user already exists!");
            [self initWithId:snapshot.value];
        }
    }];
}

- (void) setupWithTwitter:(FAUser *)twitterUser withCompletionBlock:(void (^)(NSError* error))block
{
    self.completionBlock = block;
    [self setupWithTwitter:twitterUser];
    
}

- (void) createWithTwitterUser:(FAUser *)twitterUser
{
    NSLog(@"Creating with twitter user");
    // Populate
    self.username =[twitterUser.thirdPartyUserData valueForKey:@"username"];
    self.displayName = [twitterUser.thirdPartyUserData valueForKey:@"displayName"];
    self.imageURL = [twitterUser.thirdPartyUserData valueForKey:@"profile_image_url"];
    self.description =[twitterUser.thirdPartyUserData valueForKey:@"description"];
    self.thirdPartyId = [NSString stringWithFormat:@"twitter:%@", twitterUser.userId];
    
    // Generate the id
    [self generateIds];
    
    // Create ref via firebase
    self.ref = [[[[Firebase alloc] initWithUrl:@"https://orbit.firebaseio.com/"] childByAppendingPath:@"users"] childByAppendingPath:self.id];
    
    // Create the twitter -> orbiter entity
    Firebase *twitterRef = [[[Firebase alloc] initWithUrl:@"https://orbit.firebaseio.com/providers/twitter"] childByAppendingPath:twitterUser.userId];
    // Set to point to the actual user entity
    [twitterRef setValue:self.id];
    
    // Populate the actual entity
    [self updateFirebase];
    
    // Logged in, so start broadcasting!
    [self.beacon startBroadcastingWithMajor:self.major andMinor:self.minor];
    
    // Run the completion block if it exists
    [self runCompletionBlock];
    
}

- (void) runCompletionBlock
{
    NSLog(@"running completion block");
    if(self.completionBlock)
    {
        self.completionBlock(nil);
    }
}

- (void) generateIds
{
    // Generate an id
    self.major = [[NSNumber alloc] initWithInt:arc4random() % 65535];
    //    self.major = [self formatValue:self.major forDigits:@4[self.major length]]
    self.minor = [[NSNumber alloc] initWithInt:arc4random() % 65535];
    self.id = [NSString stringWithFormat:@"%@:%@", self.major, self.minor];
    NSLog(@"Generated id: %@",self.id);
}

- (void) updateFirebase
{
    // Update the firebase entity with all of the current values
    [[self.ref childByAppendingPath:@"username" ] setValue:self.username];
    [[self.ref childByAppendingPath:@"major" ] setValue:self.major];
    [[self.ref childByAppendingPath:@"minor" ] setValue:self.minor];
    [[self.ref childByAppendingPath:@"displayName" ] setValue:self.displayName];
    [[self.ref childByAppendingPath:@"imageURL"] setValue:self.imageURL];
    [[self.ref childByAppendingPath:@"description"] setValue:self.description];
}

//+ (NSString *)formatValue:(int)value forDigits:(int)zeros {
//    NSString *format = [NSString stringWithFormat:@"%%0%dd", zeros];
//    return [NSString stringWithFormat:format,value];
//}
//
//- (BOOL) checkExisting:(NSString *)service
//{
//    return FALSE;
//}




    
//    self.imageURL:@"http://t2.gstatic.com/images?q=tbn:ANd9GcSpfi-oy-mmjR35QHzmCgzKD331GmxTteCFuaO3khCTCsHV3OpNDA"
//    
//    self.username = username;
//    self.id = @"hello";
//    self.imageURL = [[NSURL alloc] initWithString:imageURL];
//    
//    return self;
//}

@end
