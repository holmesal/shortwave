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

@protocol ChannelMutedResponderDelegate
-(void)channel:(id)channel isMuted:(BOOL)muted;
@end

@protocol ChannelActivityIndicatorDelegate
-(void) channel:(id)channel hasNewActivity:(BOOL)activity;
@end


@protocol ChannelCellActionDelegate
-(void)didLongPress:(UILongPressGestureRecognizer*)longPress;
@end


@interface SWChannelModel : NSObject <UICollectionViewDelegate>

@property id<UIScrollViewDelegate> scrollViewDelegate;
@property (strong, nonatomic) NSString *name;
@property (strong, nonatomic) NSString *channelDescription; //may be nil
@property (strong, nonatomic) NSString *url;

@property (assign, nonatomic) double lastSeen; //init 0
@property (strong, nonatomic) Firebase *mutedFirebase;
@property (assign, nonatomic) BOOL muted;

@property (assign, nonatomic) BOOL isSynchronized; //defaults to TRUE

@property (strong, nonatomic) Firebase *messagesRoot;
@property (strong, nonatomic) Firebase *channelRoot;

//@property (strong, nonatomic) NSMutableArray* messages; //TODO: init empty array (message models go in)
//@property (strong, nonatomic) NSMutableArray* members; //TODO: init empty array (strings go in)
@property (strong, nonatomic) UICollectionView* messageCollectionView; //didSet willSet

@property (strong, nonatomic) WallSource *wallSource;

@property (strong, nonatomic) id<ChannelActivityIndicatorDelegate> delegate;
@property (strong, nonatomic) id<ChannelMutedResponderDelegate> mutedDelegate;
@property (strong, nonatomic) id<ChannelCellActionDelegate> cellActionDelegate;


-(id)initWithDictionary:(NSDictionary*)dictionary andUrl:(NSString*)url andChannelMeta:(NSDictionary*)meta;
-(void)setMutedToFirebase;
+(void)joinChannel:(NSString*)channelName withCompletion:(void (^)(NSError *error))completion;

@end
