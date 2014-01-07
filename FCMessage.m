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

- (id) initWithText:(NSString *)text user:(FCUser *)user
{
    self = [super init];
    if(!self) return Nil;
    
    self.text = text;
    self.user = user;
    
    return self;
    
}

- (NSDictionary *) toDictionary
{
//    NSDictionary *message = [[NSDictionary alloc] initWithObjectsAndKeys:<#(id), ...#>, nil];
    NSDictionary *user = @{@"username": self.user.username,
                                 @"id": self.user.id,
                           @"imageURL":self.user.imageURL};
    NSDictionary *message = @{@"text"     : self.text,
                              @"user"     : user};
//    [message setValue:self.text forKey:@"text"];
//    [message setValue:self.user.id forKey:@"user"];
    
    return message;
}

@end
