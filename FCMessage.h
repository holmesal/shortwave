//
//  FCMessage.h
//  Firechat
//
//  Created by Alonso Holmes on 12/23/13.
//  Copyright (c) 2013 Buildco. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "FCUser.h"

@interface FCMessage : NSObject

@property NSString *text;
@property FCUser *user;

- (id) initWithText:(NSString *)text user:(FCUser *)user;

- (NSDictionary *) toDictionary;

@end
