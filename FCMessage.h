//
//  FCMessage.h
//  Firechat
//
//  Created by Alonso Holmes on 12/23/13.
//  Copyright (c) 2013 Buildco. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "FCUser.h"
#import <Firebase/Firebase.h>

@interface FCMessage : NSObject

@property NSString *text;
@property NSURL *imageUrl;
@property NSString *username;
//@property NSString *displayName;
@property NSString *ownerID;

- (id) initWithSnapshot:(FDataSnapshot *)snapshot  withLoadedBlock:(void (^)(NSError* error, FCMessage* message))block;

//- (NSDictionary *) toDictionary;

@end
