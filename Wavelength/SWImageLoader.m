//
//  SWImageLoader.m
//  Shortwave
//
//  Created by Ethan Sherr on 9/3/14.
//  Copyright (c) 2014 Ethan Sherr. All rights reserved.
//

#import "SWImageLoader.h"
#import "ASIHTTPRequest.h"

#import <AWSS3/AWSS3.h>
#import <AWSRuntime/AWSRuntime.h>
#import "ObjcConstants.h"
#import "NSString+Extension.h"

#pragma mark DiscardableImage declaration
@interface DiscardableImage : NSObject <NSDiscardableContent>

@property (strong, nonatomic) UIImage *image;
@property (assign, nonatomic) BOOL contentHasBeenAccessed;

-(id)initWithImage:(UIImage*)img;

@end

@implementation DiscardableImage

-(id)initWithImage:(UIImage *)img
{
    if (self = [super init])
    {
        self.image = img;
    }
    return self;
}
-(UIImage*)getImage
{
    self.contentHasBeenAccessed = YES;
    return self.image;
}
-(void)discardContentIfPossible
{
    self.image = nil;
}
-(BOOL)isContentDiscarded
{
    return (self.image == nil);
}
-(void)endContentAccess
{
    
}
-(BOOL)beginContentAccess
{
    return self.contentHasBeenAccessed && (self.image != nil);
}

@end


#pragma mark EventDispatcher
@interface EventDispatcher: NSObject

@property (nonatomic, copy) void (^completion)(void);
@property (nonatomic, copy) void (^progress)(void);

-(id)initWithCompletion:(void (^)(void))c progress:(void (^)(void))p;

@end

@implementation EventDispatcher

-(id)initWithCompletion:(void (^)(void))c progress:(void (^)(void))p
{
    if (self = [super init])
    {
        self.completion = c;
        self.progress = p;
    }
    return self;
}
@end




#pragma mark DataLoadingParcel declaration
@interface DataLoadingParcel: NSObject <AmazonServiceRequestDelegate>

@property (strong, nonatomic) NSURL *url;
@property (assign, nonatomic) float percent;
@property (assign, nonatomic) DataLoadingParcelState state;
@property (strong, nonatomic) NSMutableArray *eventDispatchers;

@property (strong, nonatomic) ASIHTTPRequest *request;
@property (strong, nonatomic) NSData *receivedData;

@property (assign, nonatomic) BOOL isAwsLoad;
@property (strong, nonatomic) NSString *fileName;
@property (strong, nonatomic) S3GetObjectRequest *s3GetObjectRequest;
@property (strong, nonatomic) NSMutableData *mutableData;
@property (assign, nonatomic) long long expectedContentLenght;

@property (strong, nonatomic) NSString *downloadDestinationPath;

-(id)initWithUrl:(NSURL *)theUrl andDownloadDestinationPath:(NSString*)downloadDestinationPath;
-(id)initWithFileName:(NSString*)fileName;

-(void)initializeRequest;
-(void)addListeners:(void (^)(void))completion progress:(void (^)(void))progress;
-(void)start;

-(NSString*)key;


@end

@implementation DataLoadingParcel
@synthesize url;
@synthesize percent;
@synthesize state;
@synthesize eventDispatchers;
@synthesize request;
@synthesize receivedData;


@synthesize isAwsLoad;
@synthesize fileName;
@synthesize s3GetObjectRequest;

-(id)init
{
    if (self = [super init])
    {
        percent = 0.0f;
        state = DataLoadingParcelStateUnstarted;
        eventDispatchers = [[NSMutableArray alloc] init];
    }
    return self;
}

-(id)initWithUrl:(NSURL *)theUrl andDownloadDestinationPath:(NSString*)downloadDestinationPath
{
    if (self = [self init])
    {
        _downloadDestinationPath = downloadDestinationPath;
        isAwsLoad = NO;
        url = theUrl;

        [self initializeRequest]; //setups request fresh
    }
    return self;
}

-(id)initWithFileName:(NSString*)theFileName
{
    if (self = [self init])
    {
        isAwsLoad = YES;
        fileName = theFileName;
        
        [self initializeRequest];
    }
    return self;
}

-(void)initializeRequest
{
    _mutableData = [[NSMutableData alloc] init];
    if (isAwsLoad)
    {
//        s3GetObjectRequest = [[S3GetObjectRequest alloc] initWithKey:fileName withBucket:Objc_kAWS_BUCKET];
//        s3GetObjectRequest.delegate = self;
    } else
    {
        request = [[ASIHTTPRequest alloc] initWithURL:url];
        request.downloadProgressDelegate = self;
        request.downloadDestinationPath = _downloadDestinationPath;
        
        request.numberOfTimesToRetryOnTimeout = 2;
        request.didFinishSelector = @selector(requestFinished:);
        request.didFailSelector = @selector(requestFailed:);
        request.delegate = self;
    }
}

-(NSString*)key
{
    if (isAwsLoad)
    {
        return self.fileName;
    } else
    {
        return self.url.absoluteString;
    }
}

-(void)addListeners:(void (^)(void))completion progress:(void (^)(void))progress
{
    [eventDispatchers addObject:[[EventDispatcher alloc] initWithCompletion:completion progress:progress]];
}

-(void)start
{
    switch (state)
    {
        case DataLoadingParcelStateUnstarted:
        {
            if (isAwsLoad)
            {
//                state = DataLoadingParcelStateDownloading;
//                [self awsStart];
//                
            } else
            {
                state = DataLoadingParcelStateDownloading;
                [request startAsynchronous];
            }
            
            break;
        }
        default:
        {
            NSLog(@"Download's state for %d is invalid to call load on. url %@", state, url);
        }
    }
}

-(void)awsStart
{
    AmazonS3Client *s3 = [[AmazonS3Client alloc] initWithAccessKey:Objc_kAWS_ACCESS_KEY_ID withSecretKey:Objc_kAWS_SECRET_KEY];

    S3GetObjectResponse *response;
    @try
    {
        response = [s3 getObject:s3GetObjectRequest];
    }
    @catch(NSException* ex)
    {

    }
    return;
}



-(void)requestFailed:(ASIHTTPRequest*)rq
{
    NSLog(@"request failed, %@", rq.url);
    
    state = DataLoadingParcelStateFailed;
    
    NSLog(@"request.error = %@", rq.error.localizedDescription);
    NSLog(@"request.code = %ld", (long)rq.error.code);
    
    if (rq.error.code == 1)
    {
        return;
    }
    
    state = DataLoadingParcelStateUnstarted;
    //just auto repeat requests that fail for now.
    [self initializeRequest];
    //shuffle it to the back of the request list to be a pro, later.
//    [request startAsynchronous];
    [self start];
    
}


-(void)requestFinished:(ASIHTTPRequest*)rq
{
//    NSLog(@"'%@', is '%@'", rq.url.absoluteString, (request.responseData ? @"NULL" : @"YES") );
    state = DataLoadingParcelStateComplete;
   
    receivedData = [NSData dataWithContentsOfFile:_downloadDestinationPath];//rq.responseData;

    [self reportFinished];
}

////aws didcompleteresopnse
//-(void)request:(AmazonServiceRequest *)request didCompleteWithResponse:(AmazonServiceResponse *)response
//{
//    state = DataLoadingParcelStateComplete;
//    receivedData = response.body;
//    
////    receivedData = _mutableData;
//    [self reportFinished];
//}

-(void)reportFinished
{
    
    //completion reporting
    
    NSArray *eventDispatchersCopy = [eventDispatchers copy];
    [eventDispatchers removeAllObjects];
    for (EventDispatcher *event in eventDispatchersCopy)
    {
        if (event.completion)
        {
            event.completion();
        }
    }
}

-(void)setProgress:(float)p
{
//    NSLog(@"progress at this point is = %d", p);
    percent = p;
    
    for (EventDispatcher *event in eventDispatchers)
    {
        if (event.progress)
        {
            event.progress();
        }
    }
}



-(void)request:(AmazonServiceRequest *)request didReceiveResponse:(NSURLResponse *)response
{
    _expectedContentLenght = response.expectedContentLength;
}

//-(void)request:(NSObject *)request didReceiveData:(NSData *)data
//{
//    [_mutableData appendData:data];
//    float progress = 0.0f;
//    
//    if ([request isKindOfClass:[AmazonServiceRequest class]])
//    {//then _expectedContentLength has been init
//        progress = (float)_mutableData.length / (float)_expectedContentLenght;
//    } else
//    {
//        ASIHTTPRequest *asiHttpRequest = (ASIHTTPRequest*)request;
//        progress = _mutableData.length/(float)asiHttpRequest.contentLength;
//    }
//    
//    [self setProgress:progress];
//}

-(void)dealloc
{

}

@end



#pragma mark SWImageLoader
@interface SWImageLoader ()

@property (assign, nonatomic) NSInteger numConcurrent;
@property (strong, nonatomic) NSCache *cache;
@property (strong, nonatomic) NSMutableDictionary *dataLoadingParcels;
@property (strong, nonatomic) NSMutableArray *dataLoadingParcelOrder;

@end

@implementation SWImageLoader
@synthesize numConcurrent;
@synthesize cache;
@synthesize dataLoadingParcels;
@synthesize dataLoadingParcelOrder;

-(id)init
{
    return [self initWithConcurrent:5];
}
-(id)initWithConcurrent:(NSInteger)conc
{
    if (self = [super init])
    {
        numConcurrent = conc;
        cache = [[NSCache alloc] init];
        dataLoadingParcels = [[NSMutableDictionary alloc] init];
        dataLoadingParcelOrder = [[NSMutableArray alloc] init];
        
    }
    return self;
}




-(void)loadAwsImage:(NSString*)fileName completionBlock:(void(^)(UIImage *image, BOOL synchronous))completion progressBlock:(void(^)(float progress))progressBlock
{
    DiscardableImage *discardableImage = [cache objectForKey:fileName];
    if (discardableImage)
    {
        completion(discardableImage.image, YES);
    } else
    {
        DataLoadingParcel *dataLoadingParcel = dataLoadingParcels[fileName];
        if (dataLoadingParcel)
        {
            
        } else
        {
            dataLoadingParcel = [[DataLoadingParcel alloc] initWithFileName:fileName];
            
            if (dataLoadingParcelOrder.count <= numConcurrent)
            {
                [dataLoadingParcel start];
            }
            
            dataLoadingParcels[fileName] = dataLoadingParcel;
            [dataLoadingParcelOrder addObject:dataLoadingParcel];
        }
        
        [dataLoadingParcel addListeners:[self completionBlockForParcel:dataLoadingParcel completionBlock:completion] progress:[self progressBlockForParcel:dataLoadingParcel progressBlock:progressBlock]];
        
    }
}

-(NSString*) cacheDirectoryName
{
    
    NSArray *paths = NSSearchPathForDirectoriesInDomains(NSCachesDirectory, NSUserDomainMask, YES);
    NSString *documentsDirectory = [paths objectAtIndex:0];
//    NSString *cacheDirectoryName = [documentsDirectory stringByAppendingPathComponent:@"HashtagImages"];
    return documentsDirectory;
}

-(NSString*)filePathForMp4Url:(NSString*)mp4url
{
    NSString *name = [mp4url MD5String];
    NSString *filePathFromUrl = [[self cacheDirectoryName] stringByAppendingPathComponent:[NSString stringWithFormat:@"%@.mp4", name]];
    return filePathFromUrl;
}

-(void)loadVideo:(NSString*)mp4Url completionBlock:(void (^)(NSString *videoFilePathPath, BOOL synchronous))completionBlock progressBlock:(void (^)(float progress))progressBlock
{
    NSString *filePathFromUrl = [self filePathForMp4Url:mp4Url];
//    NSLog(@"filePathFromUrlMp4 = %@", filePathFromUrl);
    
    if ([[NSFileManager defaultManager] fileExistsAtPath:filePathFromUrl])
    {
        completionBlock(filePathFromUrl, YES);
    } else
    {
        DataLoadingParcel *dataLoadingParcel = dataLoadingParcels[mp4Url];
        if (dataLoadingParcel)
        {} else
        {
            //does not exist, create parcel & book-keeping
            
            dataLoadingParcel = [[DataLoadingParcel alloc] initWithUrl:[NSURL URLWithString:mp4Url] andDownloadDestinationPath:filePathFromUrl];
            
            if (dataLoadingParcelOrder.count <= numConcurrent)
            {
                [dataLoadingParcel start];
            }
            
            dataLoadingParcels[mp4Url] = dataLoadingParcel;
            [dataLoadingParcelOrder addObject:dataLoadingParcel];
            
        }
        
        [dataLoadingParcel
         addListeners: [self completionBlockForVideoParcel:dataLoadingParcel completionBlock:completionBlock] //completion
         progress:[self progressBlockForParcel:dataLoadingParcel progressBlock:progressBlock]]; //progress
        
    }
}

-(void)loadImage:(NSString *)urlString completionBlock:(void (^)(UIImage *img, BOOL synchronous))completionBlock progressBlock:(void (^)(float progress))progressBlock
{
    NSString *name = [urlString MD5String];
    NSString *filePathFromUrl = [[self cacheDirectoryName] stringByAppendingPathComponent:[NSString stringWithFormat:@"%@.data", name ]];
    
    
//    NSLog(@"cacheDirectoryName = %@", [self cacheDirectoryName]);
    
    DiscardableImage *discardableImage = [cache objectForKey:urlString];
    if (discardableImage)
    {//synchronous return
        completionBlock(discardableImage.image, YES);
    } else
    if ([[NSFileManager defaultManager] fileExistsAtPath:filePathFromUrl])
    {
        NSData *imgData = [[NSData alloc] initWithContentsOfURL:[NSURL fileURLWithPath:filePathFromUrl]];
        UIImage *img = [[UIImage alloc] initWithData:imgData];
        
        DiscardableImage *discardableImage = [[DiscardableImage alloc] initWithImage:img];
        NSString *key = urlString;
        [self.cache setObject:discardableImage forKey:key];
        completionBlock(img, YES);
        
    } else
    {
        //does this request already exist?
        DataLoadingParcel *dataLoadingParcel = dataLoadingParcels[urlString];
        if (dataLoadingParcel)
        {
            //exists, add callback blocks
//            [dataLoadingParcel
//             addListeners: [self completionBlockForParcel:dataLoadingParcel completionBlock:completionBlock] //completion
//             progress:[self progressBlockForParcel:dataLoadingParcel progressBlock:progressBlock]]; //progress
        } else
        {
            //does not exist, create parcel & book-keeping
            
            dataLoadingParcel = [[DataLoadingParcel alloc] initWithUrl:[NSURL URLWithString:urlString] andDownloadDestinationPath:filePathFromUrl];
            
            if (dataLoadingParcelOrder.count <= numConcurrent)
            {
                [dataLoadingParcel start];
            }
            
            dataLoadingParcels[urlString] = dataLoadingParcel;
            [dataLoadingParcelOrder addObject:dataLoadingParcel];
            
        }
        
        [dataLoadingParcel
         addListeners: [self completionBlockForParcel:dataLoadingParcel completionBlock:completionBlock] //completion
         progress:[self progressBlockForParcel:dataLoadingParcel progressBlock:progressBlock]]; //progress
        
        
    }
}



-(BOOL)hasImage:(NSString *)urlString
{
    DiscardableImage *discardableImage = [cache objectForKey:urlString];
    return discardableImage && [discardableImage getImage];
}

//internal helper methods
-(void (^)(void))completionBlockForParcel:(DataLoadingParcel*)parcel completionBlock:(void (^)(UIImage *img, BOOL syncrhonous))completionBlock
{
    return ^{
        NSData *data = parcel.receivedData;
        UIImage *image = [UIImage imageWithData:data];
        //store discardableImage
        DiscardableImage *discardableImage = [[DiscardableImage alloc] initWithImage:image];
        NSString *key = [parcel key];
        
        [self.cache setObject:discardableImage forKey:key];
        

        
        if (self.dataLoadingParcelOrder.count > self.numConcurrent)
        {
            DataLoadingParcel *nextDLP = dataLoadingParcelOrder[self.numConcurrent];
            [nextDLP start];
        }
        
        //remove this parcel from dataLoadingParcels url -> Parcel mapping
        [self.dataLoadingParcels removeObjectForKey:key];
        
        //remove this parcel from DataLoadingParcelOrder
        [self.dataLoadingParcelOrder removeObject:parcel];
        
        completionBlock(image, NO);
    
    };
}

-(void(^)(void))completionBlockForVideoParcel:(DataLoadingParcel*)parcel completionBlock:(void (^)(NSString *videoFilePathPath, BOOL synchronous))completionBlock
{
    return ^{
//        NSData *data = parcel.receivedData;
//        UIImage *image = [UIImage imageWithData:data];
//        //store discardableImage
//        DiscardableImage *discardableImage = [[DiscardableImage alloc] initWithImage:image];
        NSString *key = [parcel key];
//
//        [self.cache setObject:discardableImage forKey:key];

        if (self.dataLoadingParcelOrder.count > self.numConcurrent)
        {
            DataLoadingParcel *nextDLP = dataLoadingParcelOrder[self.numConcurrent];
            [nextDLP start];
        }
        
        //remove this parcel from dataLoadingParcels url -> Parcel mapping
        [self.dataLoadingParcels removeObjectForKey:key];
        
        //remove this parcel from DataLoadingParcelOrder
        [self.dataLoadingParcelOrder removeObject:parcel];
        
        completionBlock(parcel.downloadDestinationPath, NO);
        
    };
}

-(void (^)(void))progressBlockForParcel:(DataLoadingParcel*)parcel progressBlock:(void(^)(float progress))progressBlock
{
    return ^{
        progressBlock(parcel.percent);
    };
}



@end
