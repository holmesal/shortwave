//
//  SWChannelModel.h
//  Shortwave
//
//  Created by Ethan Sherr on 9/3/14.
//  Copyright (c) 2014 Ethan Sherr. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <UIKit/UIKit.h>
#import <Firebase/Firebase.h>
#import "WallSource.h"


@interface  QueryChannelRequest : NSObject

@property (strong, nonatomic) Firebase *put;
@property (strong, nonatomic) Firebase *get;
@property (assign, nonatomic) FirebaseHandle listener;
@property (strong, nonatomic) id result;
@property (strong, nonatomic) NSMutableArray *results; //of QueryResult

@end

@interface QueryResult : NSObject

@property (assign, nonatomic) NSInteger memberCount;
@property (strong, nonatomic) NSNumber *score;
@property (strong, nonatomic) NSString *text;
-(id)initWithDictionary:(NSDictionary*)dictionary;



@end

@protocol ChannelMutedResponderDelegate
-(void)channel:(id)channel isMuted:(BOOL)muted;
@end

@protocol ChannelActivityIndicatorDelegate
-(void) channel:(id)channel hasNewActivity:(BOOL)activity;
-(void) channel:(id)channel isReorderingWithMessage:(MessageModel*)lastMessage;
@end


@protocol ChannelCellActionDelegate
-(void)didLongPress:(UILongPressGestureRecognizer*)longPress;
-(void)userTappedFlagOnMessageModel:(MessageModel*)messageModel;
@end


@interface SWChannelModel : NSObject <UICollectionViewDelegate>

@property id<UIScrollViewDelegate> scrollViewDelegate; //v

@property (strong, nonatomic) MessageModel *lastMessage; //v


@property (strong, nonatomic) NSString *name; //x
@property (strong, nonatomic) NSString *channelDescription; //may be nil //x
@property (strong, nonatomic) NSString *url; //x

@property (assign, nonatomic) double lastSeen; //init 0 //x
@property (strong, nonatomic) Firebase *mutedFirebase; //x
@property (assign, nonatomic) BOOL muted; //x (Setter is setMuted:(boolean)

@property (assign, nonatomic) BOOL isSynchronized; //defaults to TRUE //x

@property (strong, nonatomic) Firebase *messagesRoot; //x
@property (strong, nonatomic) Firebase *channelRoot; //x
@property (strong, nonatomic) Firebase *latestMessagePriority; //x

//@property (strong, nonatomic) NSMutableArray* messages; //TODO: init empty array (message models go in)
//@property (strong, nonatomic) NSMutableArray* members; //TODO: init empty array (strings go in)
@property (strong, nonatomic) UICollectionView* messageCollectionView; //didSet willSet

@property (strong, nonatomic) WallSource *wallSource;

@property (strong, nonatomic) id<ChannelActivityIndicatorDelegate> delegate;
@property (strong, nonatomic) id<ChannelMutedResponderDelegate> mutedDelegate; //x
@property (strong, nonatomic) id<ChannelCellActionDelegate> cellActionDelegate;


-(id)initWithDictionary:(NSDictionary*)dictionary andUrl:(NSString*)url andChannelMeta:(NSDictionary*)meta; 
-(void)setMutedToFirebase; //x
+(void)joinChannel:(NSString*)channelName withCompletion:(void (^)(NSError *error))completion;
+(void)query:(NSString*)queryTerm andCompletionHandler:(void(^)(QueryChannelRequest *request, NSString *originalQuery))completion;

@end
