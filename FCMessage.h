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



@property (nonatomic) CLLocation *location;
@property NSString *text;
//@property NSURL *imageUrl;
//@property NSString *username;
//@property NSString *displayName;
@property NSString *ownerID;
//@property NSString *timestamp;
@property NSString *icon;
@property NSString *color;

- (id) initWithSnapshot:(FDataSnapshot *)snapshot;
- (void)postText:(NSString *)text asOwner:(FCUser *)owner;

//- (NSDictionary *) toDictionary;

@end
