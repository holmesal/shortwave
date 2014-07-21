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

@property (strong, nonatomic) NSString *icon;
//@property NSString *displayName;
@property (strong, nonatomic) NSString *color;


@property NSString *id;
@property NSString *deviceToken;

@property (nonatomic) ESTransponder *beacon;
@property (nonatomic) FAUser *fuser;


- (void)sendProviderDeviceToken:(NSData *)bytes;
-(void)registerListenersToMeta;
//- (id) initAsOwner;

+(FCUser*)owner;
+(FCUser*)createOwner;

@end
