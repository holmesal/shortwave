//
//  ESTransponder.h
//  Earshot
//
//  Created by Alonso Holmes on 4/1/14.
//  Copyright (c) 2014 Buildco. All rights reserved.
//

#import <Foundation/Foundation.h>

@interface ESTransponder : NSObject

@property (strong, nonatomic) NSString *earshotID;

// Sets the earshot id, and starts advertising it.
- (void)setEarshotID:(NSString *)earshotID;

// Starts broadcasting. Safe to call if already broadcasting
- (void)startBroadcasting;

@end
