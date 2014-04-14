//
//  FCUser.h
//  Firechat
//
//  Created by Alonso Holmes on 12/26/13.
//  Copyright (c) 2013 Buildco. All rights reserved.
//

#import <Foundation/Foundation.h>


//#import "FCBeacon.h"
#import "ESTransponder.h"
#import <FirebaseSimpleLogin/FirebaseSimpleLogin.h>

@interface FCUser : NSObject

@property Firebase *ref;
@property Firebase *onOffRef;//reference to the boolan value of keyboard pressed or not pressed
@property Firebase *rootRef;

@property (strong, nonatomic) NSString *icon;
//@property NSString *displayName;
@property (strong, nonatomic) NSString *color;
@property UIColor *displayColor;
//@property NSString *description;
@property NSString *id;
//@property NSString *thirdPartyId;
//@property NSNumber *major;
//@property NSNumber *minor;
@property NSString *deviceToken;

@property (nonatomic) ESTransponder *beacon;
@property (nonatomic) FAUser *fuser;


//- (id) linkFirebase:(NSString *)id;

- (void)sendProviderDeviceToken:(NSData *)bytes;

//- (id) initWithSnapshot:(NSDictionary *)snapshot;
//- (id) initWithSnapshot:(NSDictionary *)snapshot andID:(NSString *)id;
//- (id) initWithTwitter:(FAUser *)twitterUser;
//- (void) setupWithTwitter:(FAUser *)twitterUser withCompletionBlock:(void (^)(NSError* error))block;
//- (void) signupWithUsername:(NSString *)username andImage:(UIImage *)image;
- (id) initAsOwner;

+(FCUser*)owner;
+(FCUser*)createOwner;

@end
