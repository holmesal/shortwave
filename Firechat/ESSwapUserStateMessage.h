//
//  ESSwapIconMessage.h
//  Earshot
//
//  Created by Ethan Sherr on 4/2/14.
//  Copyright (c) 2014 Buildco. All rights reserved.
//

#import <Foundation/Foundation.h>

@interface ESSwapUserStateMessage : NSObject

- (id) initWithSnapshot:(FDataSnapshot *)snapshot;
- (id) initWithOldIcon:(NSString*)oldIcon oldColor:(NSString*)oldColor newIcon:(NSString*)newIcon newColor:(NSString*)newColor;

-(void)postMessageAsOwner;

@property (nonatomic, readonly) NSString *fromColor;
@property (nonatomic, readonly) NSString *toColor;

@property (nonatomic, readonly) NSString *fromIcon;
@property (nonatomic, readonly) NSString *toIcon;

@property (nonatomic, assign) BOOL hasDoneFirstTimeAnimation;

@end
