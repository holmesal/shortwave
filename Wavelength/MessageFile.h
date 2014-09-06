//
//  MessageFile.h
//  Wavelength
//
//  Created by Ethan Sherr on 9/5/14.
//  Copyright (c) 2014 Ethan Sherr. All rights reserved.
//

#import "MessageModel.h"

@interface MessageFile : MessageModel

@property (strong, nonatomic) NSString *fileName;
@property (assign, nonatomic) CGSize imageSize; //if image
@property (strong, nonatomic) NSString *contentType;

-(id)initWithFileName:(NSString*)fileName contentType:(NSString*)contentType andImageSize:(CGSize)imageSize andOwnerID:(NSString*)ownerID;
-(id)initWithFileName:(NSString*)fileName contentType:(NSString*)contentType andOwnerID:(NSString*)ownerID;

-(id)initWithDictionary:(NSDictionary *)dictionary andPriority:(double)priority;

-(CGSize)size;

@end
