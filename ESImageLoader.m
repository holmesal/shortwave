//
//  ESImageLoader.m
//  ESImageLoader
//
//  Created by Ethan Sherr on 5/15/14.
//  Copyright (c) 2014 Ethan Sherr. All rights reserved.
//

#import "ESImageLoader.h"
#import "DiscardableImage.h"
#import "UIImage+animatedGIF.h"
#import "DataLoadingOperation.h"

@interface ESImageLoader ()
@property (strong, nonatomic) NSCache *cache;
@property (strong, nonatomic) NSOperationQueue *imageLoadingQueue;
@end

@implementation ESImageLoader
@synthesize cache;
@synthesize imageLoadingQueue;

static ESImageLoader *loader;


+(ESImageLoader*)sharedImageLoader
{
    if (!loader)
    {
        loader = [[ESImageLoader alloc] init];
        loader.cache = [[NSCache alloc] init];
        loader.imageLoadingQueue = [[NSOperationQueue alloc] init];
        [loader.imageLoadingQueue setMaxConcurrentOperationCount:5];
        
    }
    return loader;
}

-(void)loadImage:(NSURL*)url completionBlock:(void(^)(UIImage* image, NSURL *url, BOOL synchronous))completion isGif:(BOOL)_isGif//error:(void(^)(NSError *error))errorBlock
{
    DiscardableImage *discardableImage = [cache objectForKey:url];
    if ( discardableImage)
    {
//        BOOL isMainThread = [NSThread isMainThread];
//        dispatch_sync(dispatch_get_main_queue(), ^
//        {
            NSLog(@"Load image from cache %@", url);
            completion(discardableImage.image, url, YES);
//        });
    } else
    {
        __block BOOL isGif = _isGif;
        NSLog(@"NEW Add Image to operation queue %@", [url.absoluteString substringToIndex:5]);

        DataLoadingOperation *operation = [[DataLoadingOperation alloc] initWithUrl:url
        completion:^(DataLoadingOperation *dlo)
        {
            NSLog(@"completion! %@", [dlo.url.absoluteString substringToIndex:5]);
            UIImage *img  = nil;
            if (isGif)
            {
                img = [UIImage animatedImageWithAnimatedGIFData:dlo.receivedData];
            } else
            {
                img = [UIImage imageWithData:dlo.receivedData];
            }
            dispatch_sync(dispatch_get_main_queue(), ^
            {
                [cache setObject:[[DiscardableImage alloc] initWithImage:img]  forKey:dlo.url];
                completion(img, dlo.url, NO);
            });
            
        }
        failure:^(DataLoadingOperation* dlo)
        {
            dispatch_sync(dispatch_get_main_queue(), ^
            {
                NSLog(@"failure! %@ : %@", [dlo.url.absoluteString substringToIndex:5], dlo.error);
                completion(nil, dlo.url, NO);
            });
        }
        progress:^(DataLoadingOperation* dlo)
        {
            //not called
            NSLog(@"progress! %@ : %f", [dlo.url.absoluteString substringToIndex:5], dlo.percent);
        }
        began:^(DataLoadingOperation *dlo)
        {
            dispatch_sync(dispatch_get_main_queue(), ^
            {
                NSLog(@"began! %@ ", [dlo.url.absoluteString substringToIndex:5]);
            });
        }];
        	
        [imageLoadingQueue addOperation:operation];
    }
}

/*        NSLog(@"Add Image to operation queue %@", url);
 //        NSLog(@"queue %d", imageLoadingQueue getQ)
 NSInvocationOperation *operation = [[NSInvocationOperation alloc] initWithTarget:self selector:@selector(loadImageAsync:) object:
 @{@"url":url,
 @"completion":completion}];
 //, @"error":error}];
 [imageLoadingQueue addOperation:operation];*/
//-(void)loadImageAsync:(NSDictionary*)dict
//{
//    NSURL *url = [dict objectForKey:@"url"];
//    NSLog(@"loadImageAsync %@", url);
//    void (^completionBlock)(UIImage *image, BOOL wasInstantaneous) = [dict objectForKey:@"completion"];
//    void (^errorBlock)(NSError *error) = [dict objectForKey:@"error"];
//    NSLog(@"blocks %@ %@", completionBlock, errorBlock);
//    
//    NSData *data = [[NSData alloc] initWithContentsOfURL:url];
//    UIImage *image = [[UIImage alloc] initWithData:data];
//    NSLog(@"loaded image %@->%@", url, image);
//    [cache setObject:[[DiscardableImage alloc] initWithImage:image] forKey:url];
//
//    dispatch_async( dispatch_get_main_queue(),
//    ^{
//        NSLog(@"main thread running completion block on %@->%@", url, image);
//        completionBlock(image, NO);
//    });
//}

//returns true if the image was removed, false if the image was not there.
-(BOOL)discardImage:(NSURL*)url
{
    DiscardableImage *discardableImage = [self.cache objectForKey:url];
    if (!discardableImage)
    {
        return NO;
    }
    
    [discardableImage discardContentIfPossible];
    
    return YES;
}

//returns 0,0 if that image is not yet loaded, and WxH if it is
-(CGSize)sizeOfImage:(NSURL*)url
{
    CGSize size = CGSizeZero;
    DiscardableImage *discardableimage = [self.cache objectForKey:url];
    if (discardableimage)
    {
        size = discardableimage.image.size;
    }

    return size;
}


@end
