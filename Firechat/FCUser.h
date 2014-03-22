//
//  FCUser.h
//  Firechat
//
//  Created by Alonso Holmes on 12/26/13.
//  Copyright (c) 2013 Buildco. All rights reserved.
//

#import <Foundation/Foundation.h>


#import "FCBeacon.h"

@interface FCUser : NSObject

@property Firebase *ref;
@property Firebase *onOffRef;//reference to the boolan value of keyboard pressed or not pressed
@property Firebase *rootRef;

@property NSString *icon;
//@property NSString *displayName;
@property NSString *color;
@property UIColor *displayColor;
//@property NSString *description;
@property NSString *id;
//@property NSString *thirdPartyId;
@property NSNumber *major;
@property NSNumber *minor;

@property (nonatomic) FCBeacon *beacon;

//- (id) linkFirebase:(NSString *)id;

- (void)sendProviderDeviceToken:(NSData *)bytes;

- (id) initWithSnapshot:(NSDictionary *)snapshot;
- (id) initWithSnapshot:(NSDictionary *)snapshot andID:(NSString *)id;
//- (id) initWithTwitter:(FAUser *)twitterUser;
//- (void) setupWithTwitter:(FAUser *)twitterUser withCompletionBlock:(void (^)(NSError* error))block;
- (void) signupWithUsername:(NSString *)username andImage:(UIImage *)image;
- (id) initAsOwner;

@end
