//
//  ESImageLoader.h
//  ESImageLoader
//
//  Created by Ethan Sherr on 5/15/14.
//  Copyright (c) 2014 Ethan Sherr. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <UIKit/UIKit.h>


@interface ESImageLoader : NSObject


+(ESImageLoader*)sharedImageLoader;
-(void)loadImage:(NSURL*)url completionBlock:(void(^)(UIImage* image, NSURL *url, BOOL synchronous))completion isGif:(BOOL)isGif;
// errorBlock:(void(^)(NSError *error))error;

//returns true if the image was removed, false if the image was not there.
-(BOOL)discardImage:(NSURL*)url;

//returns 0,0 if that image is not yet loaded, and WxH if it is
-(CGSize)sizeOfImage:(NSURL*)url;

@end
