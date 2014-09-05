//
//  SWImageLoader.h
//  Shortwave
//
//  Created by Ethan Sherr on 9/3/14.
//  Copyright (c) 2014 Ethan Sherr. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <UIKit/UIKit.h>

typedef enum
{
    DataLoadingParcelStateUnstarted,
    DataLoadingParcelStateDownloading,
    DataLoadingParcelStateFailed,
//    DataLoadingParcelStatePaused,
    DataLoadingParcelStateComplete
} DataLoadingParcelState;

@interface SWImageLoader : NSObject

-(id)init;//default concurrent 5
-(id)initWithConcurrent:(NSInteger)conc;
-(void)loadImage:(NSString*)urlString completionBlock:(void (^)(UIImage* image, BOOL synchronous))completionBlock progressBlock:(void (^)(float progress))progressBlock;
-(BOOL)hasImage:(NSString*)urlString;

//(returnType (^)(parameterTypes))blockName

@end

