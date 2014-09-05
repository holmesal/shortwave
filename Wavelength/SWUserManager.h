//
//  SWUserManager.h
//  Shortwave
//
//  Created by Ethan Sherr on 7/31/14.
//  Copyright (c) 2014 Ethan Sherr. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "SWUser.h"


@interface SWUserManager : NSObject

+(void)userForID:(NSString*)userID withCompletion:(void(^)(SWUser *user, BOOL synchronous) )completionBlock;

@end
