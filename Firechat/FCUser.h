//
//  FCUser.h
//  Firechat
//
//  Created by Alonso Holmes on 12/26/13.
//  Copyright (c) 2013 Buildco. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "FirebaseSimpleLogin/FirebaseSimpleLogin.h"

@interface FCUser : NSMutableDictionary

@property NSString *username;
@property NSString *displayName;
@property NSString *imageURL;
@property NSString *description;
@property NSString *id;
@property NSString *thirdPartyId;

//- (id) linkFirebase:(NSString *)id;

- (id) initWithSnapshot:(NSDictionary *)snapshot;
- (id) initWithSnapshot:(NSDictionary *)snapshot andID:(NSString *)id;
- (id) initWithTwitter:(FAUser *)twitterUser;

@end
