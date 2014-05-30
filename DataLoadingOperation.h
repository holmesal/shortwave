//
//  DataLoadingOperation.h
//  ESImageLoader
//
//  Created by Ethan Sherr on 5/17/14.
//  Copyright (c) 2014 Ethan Sherr. All rights reserved.
//

#import <Foundation/Foundation.h>

@interface DataLoadingOperation : NSOperation


@property (strong, nonatomic, readonly) NSURL *url;
@property (strong, nonatomic, readonly) NSError *error;
@property (assign, nonatomic, readonly) float percent;
@property (strong, nonatomic, readonly) NSData *receivedData;
@property (strong, nonatomic, readonly) NSHTTPURLResponse *response;
@property (assign, nonatomic, readonly) BOOL wasCancelled;


//-(id)initWithUrl:(NSURL *)theUrl
//      completion:(void(^)(DataLoadingOperation *this))completionBlock
//         failure:(void(^)(DataLoadingOperation *this))failureBlock
//        progress:(void(^)(DataLoadingOperation *this))progressBlock
//           began:(void(^)(DataLoadingOperation *this))beganBlock;

-(id)initWithUrl:(NSURL *)theUrl progress:(void(^)(DataLoadingOperation *this))progressBlock;


@end
