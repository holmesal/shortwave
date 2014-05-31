//
//  ESImageLoader.m
//  ESImageLoader
//
//  Created by Ethan Sherr on 5/15/14.
//  Copyright (c) 2014 Ethan Sherr. All rights reserved.
//

#import "ESImageLoader.h"
#import "DiscardableImage.h"


#import "DataLoadingParcel.h"
#import "DataLoadingOperation.h"
#import "AnimatedGif.h"

#define NUM_CONCURRENT 4

@interface ESImageLoader ()
@property (strong, nonatomic) NSCache *cache;

//@property (strong, nonatomic) NSOperationQueue *imageLoadingQueue;
@property (strong, nonatomic) NSMutableArray *imageLoadingArray;
@property (strong, nonatomic) NSMutableDictionary *imageLoadingOperations;

@end

@implementation ESImageLoader
@synthesize cache;

@synthesize imageLoadingArray;
//@synthesize imageLoadingQueue;
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
//        [imageLoadingQueue setMaxConcurrentOperationCount:5];
        imageLoadingArray = [[NSMutableArray alloc] init];
        imageLoadingOperations = [[NSMutableDictionary alloc] init];
    }
    return self;
}

-(void)loadImage:(NSURL *)url
            completionBlock:(void (^)(id imageOrGif, NSURL *url, BOOL synchronous))completion
            updateBlock:(void (^)(NSURL *url, float p))progressBlock
           isGif:(BOOL)_isGif withMetric:(NSInteger)metric
{
    
    //return synchronously if in cache
    DiscardableImage *discardableImage = [cache objectForKey:url];
    if (discardableImage)
    {
        id imageOrGif = discardableImage.imageOrGif;
        completion(imageOrGif, url, YES);
    } else
    //return asynchronously if loading (but end blocks are run on main thread)
    {
        //dlp may be in progress already
        DataLoadingParcel *dlp = [imageLoadingOperations objectForKey:url];
        
        if (dlp)
        {
            //use this dlp to reshuffle (if it is not already running!)
//            NSLog(@"already loading this image, but its state mayh be paused");
        } else
        {
            //create a dlp
            __block BOOL blockIsGif = _isGif;
            dlp = [[DataLoadingParcel alloc] initWithUrl:url
            progress:^(DataLoadingParcel *parcel)
            {//update UI progress
                float p = parcel.percent;
                progressBlock(parcel.url, p);
            } completion:^(DataLoadingParcel *parcel)
            {
                //means removal & parcel is finished
                
                NSData *data = parcel.receivedData;
                id imageOrGif = nil;

                //data enterpretation
                if (blockIsGif)
                {
                    imageOrGif = [AnimatedGif getAnimationForGifWithData:data];
                } else
                {
                    imageOrGif = [UIImage imageWithData:data];
                }
                DiscardableImage *discardableImage2 = [[DiscardableImage alloc] initWithImageOrGif:imageOrGif isGif:blockIsGif];
                
                //cacheing and message passing
                [cache setObject:discardableImage2 forKey:url];
                completion(imageOrGif, parcel.url, NO);
                
                
                //removal
                if (imageLoadingArray.count > NUM_CONCURRENT)
                {
                    DataLoadingParcel *dlp = [imageLoadingArray objectAtIndex:NUM_CONCURRENT];
                    NSAssert(dlp.state != DataLoadingParcelStateDownloading, @"dlp cannot be downloading if it is >= NUM_CONC");
                    [dlp start];
                }
                [imageLoadingOperations removeObjectForKey:parcel.url];
                [imageLoadingArray removeObject:parcel];
            }];
            dlp.metric = metric;
            
            [imageLoadingOperations setObject:dlp forKey:url];
            
        }

        
        if (dlp.state != DataLoadingParcelStateDownloading)
        {
//            NSLog(@"load %d", metric);
            
            [self movePriorityToOperation:dlp];
            [self printRequests];
        } else
        {
//            NSLog(@"block %d", metric);
        }

        
    
    }
}
-(void)printRequests
{
    NSString *str = @"";
    
    int i = 0;
    for (DataLoadingParcel *parcel in imageLoadingArray)
    {
        NSString *metric = [NSString stringWithFormat:@"%d", parcel.metric];
        if (i == NUM_CONCURRENT-1)
        {
            metric = [metric stringByAppendingString:@"|"];
        } else
        {
            metric = [metric stringByAppendingString:@","];
        }
        str = [str stringByAppendingString:metric];
        i++;
    }
    NSLog(@"%@", str);
}

-(void)movePriorityToOperation:(DataLoadingParcel*)targetDlp
{
    [imageLoadingArray removeObject:targetDlp];
    //when i'm under the num_concurrent, go on ahead with this request
    if (imageLoadingArray.count < NUM_CONCURRENT)
    {
        [imageLoadingArray addObject:targetDlp];
        [targetDlp start];
        return;
    }
    
    //grab the top N
    NSRange activeRange;
    activeRange.location = 0;
    activeRange.length = NUM_CONCURRENT;
    
    
    NSArray *activeRequests = [imageLoadingArray subarrayWithRange:activeRange];
    activeRequests = [activeRequests sortedArrayUsingComparator:^(DataLoadingParcel *obj1, DataLoadingParcel *obj2)
    {
        int df1 = abs(obj1.metric - targetDlp.metric);
        int df2 = abs(obj2.metric - targetDlp.metric);
        
        if (df1 > df2)
        {
            return NSOrderedDescending;
        }
        if (df1 < df2)
        {
            return NSOrderedAscending;
        }
        
        return NSOrderedSame;
    }];
    
// activeRequest lastObject is furthest
// activeRequest firstObjct is closest

    
    DataLoadingParcel *furthestRequest = [activeRequests lastObject];
//    NSLog(@"furthestdlp.metric = %d", furthestRequest.metric);
//    NSLog(@"targetdlp.metric = %d", targetDlp.metric);
    
    //set this bugger paused, move him to the NUM_CONCURRENT-1'th place
    [furthestRequest pause];
    
    [imageLoadingArray removeObject:furthestRequest];
    [imageLoadingArray insertObject:furthestRequest atIndex:NUM_CONCURRENT-1];
    [imageLoadingArray insertObject:targetDlp atIndex:0];
    [targetDlp start];
    
    
    
}

//-(void)loadImage:(NSURL*)url completionBlock:(void(^)(id imageOrGif, NSURL *url, BOOL synchronous))completion
//     updateBlock:(void(^)(NSURL *url, float p) )progressBlock isGif:(BOOL)_isGif
//{
//    DiscardableImage *discardableImage = [cache objectForKey:url];
//    if ( discardableImage)
//    {
//        if ([discardableImage isGif])
//        {
//            completion(discardableImage.gif, url, YES);
//        } else
//        {
//            completion(discardableImage.image, url, YES);
//        }
//    } else
//    {
//        __block BOOL isGif = _isGif;
//        
//        id result = [imageLoadingOperations objectForKey:url];
//        if (result)
//        {
//            NSLog(@"already loading this operation %@", url.absoluteString);
//            return;
//        }
//
//        DataLoadingOperation *operation = [[DataLoadingOperation alloc] initWithUrl:url progress:^(DataLoadingOperation *op)
//        {
//            progressBlock(op.url, op.percent);
//        }];
//        [imageLoadingOperations setObject:operation forKey:url];
//        
//        
//        __weak DataLoadingOperation *weakOperation = operation;
//        [operation setCompletionBlock:^
//        {
//            NSData *data = weakOperation.receivedData;
//            NSLog(@"%d", data.length);
//
//            
//            
//            
//            UIImage *img  = nil;
//            AnimatedGif *gif = nil;
//            if (isGif)
//            {
//                gif = [AnimatedGif getAnimationForGifWithData:data];
//                
//            } else
//            {
//                img = [UIImage imageWithData:data];
//            }
//            dispatch_sync(dispatch_get_main_queue(), ^
//            {
//                DiscardableImage *discardableImage = nil;
//                if (img)
//                {
//                    discardableImage = [[DiscardableImage alloc] initWithImage:img];
//                } else
//                if (gif)
//                {
//                    discardableImage = [[DiscardableImage alloc] initWithGif:gif];
//                } else
//                {
//                    NSString *str = [NSString stringWithFormat:@"failed to get either gif or image data from a request: %@", url.absoluteString ];
//                    ESAssert(NO, str);
//                }
//                
//                [cache setObject:discardableImage  forKey:weakOperation.url];
//                id val = gif ? gif : img;
//                completion(val, weakOperation.url, NO);
//            });
//            
//            [imageLoadingOperations removeObjectForKey:weakOperation.url];
//            
//        }];
//        
//        
//        
//        [imageLoadingQueue addOperation:operation];
//        
////        NSLog(@"imageLoadingQueue Count = %d", imageLoadingQueue.operationCount);
//    }
//}

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

////returns 0,0 if that image is not yet loaded, and WxH if it is
//-(CGSize)sizeOfImage:(NSURL*)url
//{
//    CGSize size = CGSizeZero;
//    DiscardableImage *discardableimage = [self.cache objectForKey:url];
//    if (discardableimage)
//    {
//        size = discardableimage.image.size;
//    }
//
//    return size;
//}

-(void)pauseOrUnpauseProcess:(NSURL*)url
{
//    DataLoadingParcel *dlp = [imageLoadingOperations objectForKey:url];
//    if (!dlp)
//    {
//        NSLog(@"image is loaded, it can't be paused");
//    } else
//    {
//        BOOL isPaused = dlp.isPaused;
//        NSLog(@"setIsPaused %@", !isPaused ? @"YES" : @"NO");
//        [dlp setIsPaused:!isPaused];
//        
//    }
}

@end
