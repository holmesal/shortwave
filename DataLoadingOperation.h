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
@property (strong, nonatomic, readonly) NSURLResponse *response;
@property (assign, nonatomic, readonly) BOOL wasCancelled;


-(id)initWithUrl:(NSURL *)theUrl
      completion:(void(^)(DataLoadingOperation *this))completion
         failure:(void(^)(DataLoadingOperation *this))failure
        progress:(void(^)(DataLoadingOperation *this))progress
           began:(void(^)(DataLoadingOperation *this))began;


@end
