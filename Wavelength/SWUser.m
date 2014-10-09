//
//  SWUser.m
//  Shortwave
//
//  Created by Ethan Sherr on 7/31/14.
//  Copyright (c) 2014 Ethan Sherr. All rights reserved.
//

#import "SWUser.h"
#import "ObjcConstants.h"


@implementation SWUser

@synthesize userID, photo, firstName, lastName, userName;

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
        lastName = profile[@"lastName"];
        firstName = profile[@"firstName"];
        photo = profile[@"photo"];
        userName = profile[@"userName"];
        
        if (!lastName)
        {
            lastName = @"Lastname";
        }
        if (!userName)
        {
            userName = @"Username";
        }
            
    }
} //x

-(NSString*)getAutoCompleteKey:(BOOL)isPublic
{
    if (isPublic)
    {
        return [NSString stringWithFormat:@"%@%@", firstName, lastName];
    } else
    {
        return userName;
    }
}

-(BOOL)isMe
{
    return [[[NSUserDefaults standardUserDefaults] objectForKey:Objc_kNSUSERDEFAULTS_KEY_userId] isEqualToString:self.userID];
}


@end
