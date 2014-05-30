//
//  ESImageLoader.m
//  ESImageLoader
//
//  Created by Ethan Sherr on 5/15/14.
//  Copyright (c) 2014 Ethan Sherr. All rights reserved.
//

#import "ESImageLoader.h"
#import "DiscardableImage.h"
#import "DataLoadingOperation.h"
#import "AnimatedGif.h"

@interface ESImageLoader ()
@property (strong, nonatomic) NSCache *cache;

@property (strong, nonatomic) NSOperationQueue *imageLoadingQueue;
@property (strong, nonatomic) NSMutableDictionary *imageLoadingOperations;

@end

@implementation ESImageLoader
@synthesize cache;
@synthesize imageLoadingQueue;
@synthesize imageLoadingOperations;


static ESImageLoader *loader;


+(ESImageLoader*)sharedImageLoader
{
    if (!loader)
    {
        loader = [[ESImageLoader alloc] init];
    }
    return loader;
}

-(id)init
{
    if (self = [super init])
    {
        cache = [[NSCache alloc] init];
        imageLoadingQueue = [[NSOperationQueue alloc] init];
        [imageLoadingQueue setMaxConcurrentOperationCount:5];
        imageLoadingOperations = [[NSMutableDictionary alloc] init];
    }
    return self;
}

-(void)loadImage:(NSURL*)url completionBlock:(void(^)(id imageOrGif, NSURL *url, BOOL synchronous))completion
     updateBlock:(void(^)(NSURL *url, float p) )progressBlock isGif:(BOOL)_isGif
{
    DiscardableImage *discardableImage = [cache objectForKey:url];
    if ( discardableImage)
    {
        if ([discardableImage isGif])
        {
            completion(discardableImage.gif, url, YES);
        } else
        {
            completion(discardableImage.image, url, YES);
        }
    } else
    {
        __block BOOL isGif = _isGif;
        
        id result = [imageLoadingOperations objectForKey:url];
        if (result)
        {
            NSLog(@"already loading this operation %@", url.absoluteString);
            return;
        }

        DataLoadingOperation *operation = [[DataLoadingOperation alloc] initWithUrl:url progress:^(DataLoadingOperation *op)
        {
            progressBlock(op.url, op.percent);
        }];
        [imageLoadingOperations setObject:operation forKey:url];
        
        
        __weak DataLoadingOperation *weakOperation = operation;
        [operation setCompletionBlock:^
        {
            NSData *data = weakOperation.receivedData;
            NSLog(@"%d", data.length);

            
            
            
            UIImage *img  = nil;
            AnimatedGif *gif = nil;
            if (isGif)
            {
                gif = [AnimatedGif getAnimationForGifWithData:data];
                
            } else
            {
                img = [UIImage imageWithData:data];
            }
            dispatch_sync(dispatch_get_main_queue(), ^
            {
                DiscardableImage *discardableImage = nil;
                if (img)
                {
                    discardableImage = [[DiscardableImage alloc] initWithImage:img];
                } else
                if (gif)
                {
                    discardableImage = [[DiscardableImage alloc] initWithGif:gif];
                } else
                {
                    NSString *str = [NSString stringWithFormat:@"failed to get either gif or image data from a request: %@", url.absoluteString ];
                    ESAssert(NO, str);
                }
                
                [cache setObject:discardableImage  forKey:weakOperation.url];
                id val = gif ? gif : img;
                completion(val, weakOperation.url, NO);
            });
            
            [imageLoadingOperations removeObjectForKey:weakOperation.url];
            
        }];
        
        
        
        [imageLoadingQueue addOperation:operation];
        
//        NSLog(@"imageLoadingQueue Count = %d", imageLoadingQueue.operationCount);
    }
}

-(float)progressForImage:(NSURL *)url
{
    DataLoadingOperation *dlo = [imageLoadingOperations objectForKey:url];
    float v = dlo ? dlo.percent : 0.0f;
    return v;
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

-(void)pauseOrUnpauseProcess:(NSURL*)url
{
    DataLoadingOperation *dlo = [imageLoadingOperations objectForKey:url];
    if (!dlo)
    {
        NSLog(@"image is loaded, it can't be paused");
    } else
    {
        
    }
}

@end
