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

@property (strong, nonatomic) NSString *name; //x

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

    
    
} MessageModelType; //x

//returns nil if it failed to grab all data
-(void)setUserData:(SWUser*)user; //avoid
-(id)initWithDictionary:(NSDictionary*)dictionary andPriority:(double)priority; //x

//bool success?  Override this to set more data!
-(BOOL)setDictionary:(NSDictionary*)dictionary; //x

//must be implemented by all classes
-(NSDictionary*)toDictionary;//x
-(NSDictionary*)toDictionaryWithContent:(NSDictionary*)content andType:(NSString*)typeString;//x

+(id)messageModelFromValue:(id)value andPriority:(double)priority; //imp

//inherited properties

@property (strong, nonatomic) NSString *profileUrl; //x
@property (strong, nonatomic) NSString *firstName; //x

@property (strong, nonatomic) NSString *ownerID; //x
@property (strong, nonatomic) NSString *text; //x

@property (assign, nonatomic) MessageModelType type; //x

@property (assign, nonatomic) double priority; //x


-(id)initWithOwnerID:(NSString*)ownerID andText:(NSString*)text; //x


-(void)postToAll;//unimp!
-(void)postToUsers:(NSArray*)earshotIds;//unimp

-(void)sendMessageToChannel:(NSString*)channel;//imp


#pragma mark override these 2 functions to reflect a model that must fetch more unstackable data requests before being displayed
-(BOOL)hasAllData;
-(void)fetchRelevantDataWithCompletion:(void (^)(void) )completion; //x
-(BOOL)isReadyForDisplay; //x

@end
