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
#include "FCAppDelegate.h"
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
        // This should probably happen earlier, depending on where we want to pop up permissions
        self.beacon = [[FCBeacon alloc] init];
    }
    return self;
}

// Only run once from appdelegate - initialize as an owner - if the first run, this will be set later and called
- (id) initAsOwner
{
    self = [self init];
    if (self) {
        NSUserDefaults *prefs = [NSUserDefaults standardUserDefaults];
        self.id = [prefs stringForKey:@"id"];
        if (self.id) {
            // Link up with firebase
            [self initFirebase:self.id];
        }
    }
    
    return self;
}

// Initialize with an ID, pull data from firebase, and run the callback block
//- (id) initWithId:(NSString *)id
//{
////    [self initFirebase];
//    return self;
//}

// Set up the firebase reference
- (void) initFirebase:(NSString *)id
{
    self.ref = [[[[Firebase alloc] initWithUrl:@"https://orbit.firebaseio.com/"] childByAppendingPath:@"users"] childByAppendingPath:self.id];
}

- (void) pullFromFirebase
{
    
}

//- (void) initWithId:(NSString *)id
//{
//    self.id = id;
//    [self populateFromFirebaseId:id];
//    
////    return self;
//}

//- (id) initWithSnapshot:(NSDictionary *)snapshot
//{
//    
//    self = [super init];
//    if(!self) return nil;
//    
//    self.username = [snapshot objectForKey:@"username"];
//    self.imageURL = [snapshot valueForKey:@"imageURL"];
//    
//    return self;
//}
//
//- (id) initWithSnapshot:(NSDictionary *)snapshot andID:(NSString *)id
//{
//    self = [self initWithSnapshot:snapshot];
//    if(!self) return nil;
//    
//    self.id = id;
//    
//    return self;
//}

- (void) startBroadcasting
{
    
}

#pragma mark - creating from a username and a profile photo
- (void) signupWithUsername:(NSString *)username andImage:(UIImage *)image
{
    NSLog(@"Creating user...");
    // Populate
    self.username = username;
    
    // Hardcode image URL for now - in the future, we probably want to host these on s3 or sommat
    self.imageURL = @"https://pbs.twimg.com/profile_images/378800000822867536/3f5a00acf72df93528b6bb7cd0a4fd0c.jpeg";
    
    // Generate the id
    [self generateIds];
    
    // Create ref via firebase
    [self initFirebase:self.id];
    
    // Call update to set these values on firebase, and save to NSUserDefaults
    [self updateUserData];
    
    // Start broadcasting with a beacon
    [self.beacon startBroadcastingWithMajor:self.major andMinor:self.minor];
    
    // Set on the app delegate
    FCAppDelegate *del =[[UIApplication sharedApplication] delegate];
    del.owner = self;
    
    // Finally, emit a "complete" event, so the view can proceed
    [[NSNotificationCenter defaultCenter] postNotificationName:@"Signup Success" object:nil];
}

- (void) updateUserData
{
    // Init user defaults
    NSUserDefaults *prefs = [NSUserDefaults standardUserDefaults];
    // Username
    [[self.ref childByAppendingPath:@"username"] setValue:self.username];
//    [prefs setValue:self.username forKey:@"username"];
    // Profile photo
    [[self.ref childByAppendingPath:@"imageURL"] setValue:self.imageURL];
//    [prefs setValue:self.imageURL forKey:@"imageURL"];
    // Major/minor
    [[self.ref childByAppendingPath:@"major"] setValue:self.major];
    [[self.ref childByAppendingPath:@"minor"] setValue:self.minor];
//    [prefs setValue:self.major forKey:@"major"];
//    [prefs setValue:self.minor forKey:@"minor"];
    
    [prefs setValue:self.id forKey:@"id"];
    
    // Synchronize preferences
    [prefs synchronize];
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


@end
