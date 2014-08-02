//
//  MessageModel.h
//  Shortwave
//
//  Created by Ethan Sherr on 7/14/14.
//  Copyright (c) 2014 Buildco. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <UIKit/UIKit.h>
#import "SWUser.h"

@interface MessageModel : NSObject

@property (strong, nonatomic) NSString *name;

typedef enum
{
    MessageModelTypePlainText,
    MessageModelTypeGif,
    MessageModelTypeImage,
    MessageModelTypeLinkWeb,
    MessageModelTypeSpotifyTrack,
    MessageModelTypeYoutubeVideo,
    
    MessageModelTypePersonalVideo,
    MessageModelTypePersonalPhoto

} MessageModelType;

//returns nil if it failed to grab all data
-(void)setUserData:(SWUser*)user;
-(id)initWithDictionary:(NSDictionary*)dictionary;

//bool success?  Override this to set more data!
-(BOOL)setDictionary:(NSDictionary*)dictionary;

//must be implemented by all classes
-(NSDictionary*)toDictionary;
-(NSDictionary*)toDictionaryWithContent:(NSDictionary*)content andType:(NSString*)typeString;

+(id)messageModelFromValue:(id)value;

//inherited properties

@property (strong, nonatomic) NSString *profileUrl;
@property (strong, nonatomic) NSString *firstName;

@property (strong, nonatomic) NSString *ownerID;
@property (strong, nonatomic) NSString *text;

@property (assign, nonatomic) MessageModelType type;


-(id)initWithOwnerID:(NSString*)ownerID andText:(NSString*)text;


-(void)postToAll;
-(void)postToUsers:(NSArray*)earshotIds;

-(void)sendMessageToChannel:(NSString*)channel;


-(BOOL)hasAllData;

@end
