//
//  DataLoadingOperation.h
//  ESImageLoader
//
//  Created by Ethan Sherr on 5/17/14.
//  Copyright (c) 2014 Ethan Sherr. All rights reserved.
//

#import <Foundation/Foundation.h>

@interface DataLoadingParcel : NSObject

typedef NS_ENUM(NSUInteger, DataLoadingParcelState)
{
    
    DataLoadingParcelStateUnstarted = 0,
    DataLoadingParcelStateDownloading,
    DataLoadingParcelStateFailed,
    DataLoadingParcelStatePaused,
    DataLoadingParcelStateComplete
    
};

//readable properties
@property (strong, nonatomic, readonly) NSURL *url;
@property (strong, nonatomic, readonly) NSError *error;
@property (assign, nonatomic, readonly) float percent;
@property (strong, nonatomic, readonly) NSData *receivedData;
@property (assign, nonatomic, readonly) DataLoadingParcelState state;

//setable properties, controls & metric
-(void)pause;
@property (assign, nonatomic) NSInteger metric; //optionally set


-(id)initWithUrl:(NSURL *)theUrl progress:(void (^)(DataLoadingParcel *itself))progress completion:(void (^)(DataLoadingParcel *itself))completion;

-(void)start;

@end
