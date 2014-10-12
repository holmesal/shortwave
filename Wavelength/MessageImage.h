//
//  MessageImage.h
//  Shortwave
//
//  Created by Ethan Sherr on 7/14/14.
//  Copyright (c) 2014 Buildco. All rights reserved.
//

#import "MessageModel.h"

@interface MessageImage : MessageModel

@property (strong, nonatomic) NSString *src;
@property (strong, nonatomic) NSNumber *width;
@property (strong, nonatomic) NSNumber *height;

@property (assign, nonatomic) CGSize size;

//to initialize a message with raw values, so as not to forget any
-(id)initWithSrc:(NSString*)src ownerID:(NSString *)ownerID;// width:(NSNumber*)w height:(NSNumber*)h;
-(NSString*)key;

@end
