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

- (id) initWithSnapshot:(FDataSnapshot *)snapshot  withLoadedBlock:(void (^)(NSError* error, FCMessage* message))block
{
    self = [super init];
    if(!self) return Nil;
    
    self.text = [snapshot.value valueForKey:@"text"];
    self.ownerID = [snapshot.value valueForKey:@"ownerID"];
    
    // Set up a firebase reference to this user
    Firebase *ref = [[[[Firebase alloc] initWithUrl:@"https://orbit.firebaseio.com/"] childByAppendingPath:@"users"] childByAppendingPath:self.ownerID];
    // Wait for the data
    [ref observeSingleEventOfType:FEventTypeValue withBlock:^(FDataSnapshot *snapshot) {
        NSLog(@"Got value for user %@",self.ownerID);
        NSLog(@"%@",snapshot.value);
        
        // Set the values
        self.username = [snapshot.value valueForKey:@"username"];
//        self.displayName = [snapshot.value valueForKey:@"displayName"];
        self.imageUrl = [[NSURL alloc] initWithString:[snapshot.value valueForKey:@"imageURL"]];
        
        // You should really do some error checking here
        
        // Run the callback block
        block(nil, self);
        
    }];
    
    
    return self;
    
}

//- (id)

//- (id) initWithData:(

//- (NSDictionary *) toDictionary
//{
////    NSDictionary *message = [[NSDictionary alloc] initWithObjectsAndKeys:<#(id), ...#>, nil];
//    NSDictionary *user = @{@"username": self.user.username,
//                                 @"id": self.user.id,
//                           @"imageURL":self.user.imageURL};
//    NSDictionary *message = @{@"text"     : self.text,
//                              @"user"     : user};
////    [message setValue:self.text forKey:@"text"];
////    [message setValue:self.user.id forKey:@"user"];
//    
//    return message;
//}

@end
