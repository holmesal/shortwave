//
//  SWUser.m
//  Shortwave
//
//  Created by Ethan Sherr on 7/31/14.
//  Copyright (c) 2014 Ethan Sherr. All rights reserved.
//

#import "SWUser.h"

@implementation SWUser

@synthesize userID, photo, firstName;

-(id)initWithDictionary:(NSDictionary*)profile andUserId:(NSString*)userId
{
    if (self = [super init])
    {
        userID = userId;
        [self updateWithDictionary:profile];
    }
    return self;
} //x

-(void)updateWithDictionary:(NSDictionary*)profile
{
    if (profile)
    {
        firstName = profile[@"firstName"];
        photo = profile[@"photo"];
    }
} //x

@end
