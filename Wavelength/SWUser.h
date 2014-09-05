//
//  SWUser.h
//  Shortwave
//
//  Created by Ethan Sherr on 7/31/14.
//  Copyright (c) 2014 Ethan Sherr. All rights reserved.
//

#import <Foundation/Foundation.h>

@interface SWUser : NSObject

@property (strong, nonatomic) NSString *userID;
@property (strong, nonatomic) NSString *photo;
@property (strong, nonatomic) NSString *firstName;

-(id)initWithDictionary:(NSDictionary*)profile andUserId:(NSString*)userId;

@end
