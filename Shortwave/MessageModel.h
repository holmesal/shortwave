//
//  MessageModel.h
//  Shortwave
//
//  Created by Ethan Sherr on 7/14/14.
//  Copyright (c) 2014 Buildco. All rights reserved.
//

#import <Foundation/Foundation.h>

#import "FCUser.h"

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
-(void)setUserData:(FCUser*)user;
-(id)initWithDictionary:(NSDictionary*)dictionary;

//bool success?  Override this to set more data!
-(BOOL)setDictionary:(NSDictionary*)dictionary;

//must be implemented by all classes
-(NSDictionary*)toDictionary;
-(NSDictionary*)toDictionaryWithContent:(NSDictionary*)content andType:(NSString*)typeString;

+(MessageModel*)messageModelFromValue:(id)value;

//inherited properties
@property (strong, nonatomic) NSString *icon;
@property (strong, nonatomic) UIColor *color;

@property (strong, nonatomic) NSString *ownerID;
@property (strong, nonatomic) NSString *text;



@property (assign, nonatomic) MessageModelType type;

//for posting, use init to be safe that you've initialized all fields
-(id)initWithIcon:(NSString*)icon color:(NSString*)color ownerID:(NSString*)ownerID text:(NSString*)text;

-(id)initWithOwnerID:(NSString*)ownerID andText:(NSString*)text;


-(void)postToAll;
-(void)postToUsers:(NSArray*)earshotIds;


-(BOOL)hasAllData;

@end
