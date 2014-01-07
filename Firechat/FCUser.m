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

@interface FCUser ()
@property Firebase *ref;
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
//        self.username = @"alonso";
//        self.id = @"alonsosid";
    }
    return self;
}

- (id) initWithId:(NSString *)id
{
    [self populateFromFirebaseId:id];
    
    return self;
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

- (id) initWithTwitter:(FAUser *)twitterUser
{

    NSLog(@"%@",twitterUser.thirdPartyUserData);
    
    // Create the new user
    self = [super init];
    if(!self) return nil;
    
    // Check for an existing user by twitter id
    // If one exists, populate with that one instead of creating a new one
    BOOL existing = [self checkExisting:@"twitter"];
//    
//    if (!existing) {
//        return [self populateFromFirebaseId:(NSString *)]
//    }
    
    // Populate
    self.username =[twitterUser.thirdPartyUserData valueForKey:@"username"];
    self.displayName = [twitterUser.thirdPartyUserData valueForKey:@"displayName"];
    self.imageURL = [twitterUser.thirdPartyUserData valueForKey:@"profile_image_url"];
    self.description =[twitterUser.thirdPartyUserData valueForKey:@"description"];
    self.thirdPartyId = [NSString stringWithFormat:@"twitter:%@", twitterUser.userId];
    
    // Generate an id
    unsigned int idInt = arc4random() % 4294967295;
    self.id = [NSString stringWithFormat:@"%i", idInt];
    NSLog(@"Generated id: %@",self.id);
    
    // Create ref via firebase
    self.ref = [[[[Firebase alloc] initWithUrl:@"https://orbit.firebaseio.com/"] childByAppendingPath:@"users"] childByAppendingPath:self.id];
    
    // This ref should be null -> dump data in here
    [[self.ref childByAppendingPath:@"username" ] setValue:self.username];
    [[self.ref childByAppendingPath:@"displayName" ] setValue:self.displayName];
    [[self.ref childByAppendingPath:@"imageURL"] setValue:self.imageURL];
    [[self.ref childByAppendingPath:@"description"] setValue:self.description];
    
    return self;
}

- (void) populateFromFirebaseId:(NSString *)userID
{
    
    // Set id
    self.id = userID;
    
    // Firebase ref for this user
    self.ref = [[[[Firebase alloc] initWithUrl:@"https://orbit.firebaseio.com/"] childByAppendingPath:@"users"] childByAppendingPath:self.id];
    
    [self.ref observeEventType:FEventTypeValue withBlock:^(FDataSnapshot *snapshot) {
        NSLog(@"Got user back:");
        NSLog([snapshot.value description]);
        if(snapshot.value){
            self.username = [snapshot.value objectForKey:@"username"];
            self.imageURL = [snapshot.value objectForKey:@"imageURL"];
        }
        
    }];

}

- (BOOL) checkExisting:(NSString *)service
{
    return FALSE;
}




    
//    self.imageURL:@"http://t2.gstatic.com/images?q=tbn:ANd9GcSpfi-oy-mmjR35QHzmCgzKD331GmxTteCFuaO3khCTCsHV3OpNDA"
//    
//    self.username = username;
//    self.id = @"hello";
//    self.imageURL = [[NSURL alloc] initWithString:imageURL];
//    
//    return self;
//}

@end
