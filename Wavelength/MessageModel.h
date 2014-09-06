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
    MessageModelTypeWebSite,
    MessageModelTypeSpotifyTrack,
    MessageModelTypeYoutubeVideo,
    
    MessageModelTypePersonalVideo,
    MessageModelTypePersonalPhoto,
    
    MessageModelTypeFile

    
    
} MessageModelType;

//returns nil if it failed to grab all data
-(void)setUserData:(SWUser*)user;
-(id)initWithDictionary:(NSDictionary*)dictionary andPriority:(double)priority;

//bool success?  Override this to set more data!
-(BOOL)setDictionary:(NSDictionary*)dictionary;

//must be implemented by all classes
-(NSDictionary*)toDictionary;
-(NSDictionary*)toDictionaryWithContent:(NSDictionary*)content andType:(NSString*)typeString;

+(id)messageModelFromValue:(id)value andPriority:(double)priority;

//inherited properties

@property (strong, nonatomic) NSString *profileUrl;
@property (strong, nonatomic) NSString *firstName;

@property (strong, nonatomic) NSString *ownerID;
@property (strong, nonatomic) NSString *text;

@property (assign, nonatomic) MessageModelType type;

@property (assign, nonatomic) double priority;


-(id)initWithOwnerID:(NSString*)ownerID andText:(NSString*)text;


-(void)postToAll;
-(void)postToUsers:(NSArray*)earshotIds;

-(void)sendMessageToChannel:(NSString*)channel;


#pragma mark override these 2 functions to reflect a model that must fetch more unstackable data requests before being displayed
-(BOOL)hasAllData;
-(void)fetchRelevantDataWithCompletion:(void (^)(void) )completion;
-(BOOL)isReadyForDisplay;

@end
