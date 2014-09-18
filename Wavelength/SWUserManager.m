//
//  SWUserManager.m
//  Shortwave
//
//  Created by Ethan Sherr on 7/31/14.
//  Copyright (c) 2014 Ethan Sherr. All rights reserved.
//

#import "SWUserManager.h"
#import <Firebase/Firebase.h>
#import "ObjcConstants.h"

@interface SWUserManager ()

@property (strong, nonatomic) NSMutableDictionary *cachedUsers; //x
@property (strong, nonatomic) NSMutableDictionary *completionBlocksForUser; //x

@end



@implementation SWUserManager
@synthesize cachedUsers;
@synthesize completionBlocksForUser;

static SWUserManager *sharedManager; //x

+(id)sharedInstance
{
    if (!sharedManager)
    {
        sharedManager = [[SWUserManager alloc] init];
    }
    return sharedManager;
} //x

-(id)init
{
    if (self = [super init])
    {
        cachedUsers = [[NSMutableDictionary alloc] init];
        completionBlocksForUser = [[NSMutableDictionary alloc] init];
    }
    return self;
} //x


+(void)userForID:(NSString*)userID withCompletion:(void(^)(SWUser *user, BOOL synchronous) )completionBlock
{
    SWUserManager *userManager = [SWUserManager sharedInstance];
    
    SWUser *cachedUser = [userManager.cachedUsers objectForKey:userID];
    if (cachedUser)
    {
        completionBlock(cachedUser, YES);
    } else
    {
        NSMutableArray *completionBlocks = userManager.completionBlocksForUser[userID];
        
        BOOL performUserFetch = NO;
        if (!completionBlocks)
        {
            performUserFetch = YES;
            completionBlocks = [[NSMutableArray alloc] init];
            userManager.completionBlocksForUser[userID] = completionBlocks;
        }
        
        [completionBlocks addObject:completionBlock];
        
        
        if (performUserFetch)
        {
            NSString *fetchUserProfileString = [NSString stringWithFormat:@"%@users/%@/profile", Objc_kROOT_FIREBASE, userID];
            Firebase *fetchUserFirebase = [[Firebase alloc] initWithUrl:fetchUserProfileString];
            [fetchUserFirebase observeSingleEventOfType:FEventTypeValue withBlock:^(FDataSnapshot *snap)
            {
                NSDictionary *profile = snap.value;
                if (profile && [profile isKindOfClass:[NSDictionary class]])
                {
                    SWUser *user = [[SWUser alloc] initWithDictionary:profile andUserId:userID];
                    [userManager.cachedUsers setObject:user forKey:userID];
                    
                    NSArray *completionBlocks = userManager.completionBlocksForUser[userID];
                    for (void (^completion)(SWUser*, BOOL) in completionBlocks)
                    {
                        completion(user, NO);
                    }
                    
                    [userManager.completionBlocksForUser removeObjectForKey:userID]; //cleanup all blocks
                
                }
            } withCancelBlock:^(NSError *error)
            {
                NSLog(@"error while fetching user = %@", error);
            }];
        }
    }
    
}

@end
