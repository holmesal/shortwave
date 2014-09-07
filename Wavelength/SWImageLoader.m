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
@interface DataLoadingParcel: NSObject

@property (strong, nonatomic) NSURL *url;
@property (assign, nonatomic) float percent;
@property (assign, nonatomic) DataLoadingParcelState state;
@property (strong, nonatomic) NSMutableArray *eventDispatchers;

@property (strong, nonatomic) ASIHTTPRequest *request;
@property (strong, nonatomic) NSData *receivedData;

@property (assign, nonatomic) BOOL isAwsLoad;
@property (strong, nonatomic) NSString *fileName;

-(id)initWithUrl:(NSURL*)theUrl;
-(id)initWithFileName:(NSString*)fileName;

-(void)initializeReqeuest;
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

-(id)initWithUrl:(NSURL *)theUrl
{
    if (self = [self init])
    {
        isAwsLoad = NO;
        url = theUrl;

        [self initializeReqeuest]; //setups request fresh
    }
    return self;
}

-(id)initWithFileName:(NSString*)theFileName
{
    if (self = [self init])
    {
        isAwsLoad = YES;
        fileName = theFileName;
        
        [self initializeReqeuest];
    }
    return self;
}

-(void)initializeReqeuest
{
    if (isAwsLoad)
    {
        
    } else
    {
        request = [[ASIHTTPRequest alloc] initWithURL:url];
        request.downloadProgressDelegate = self;
        
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
                
                [self performSelectorInBackground:@selector(awsStart) withObject:nil];
                
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
    S3GetObjectRequest *getObjectRequest = [[S3GetObjectRequest alloc] initWithKey:fileName withBucket:Objc_kAWS_BUCKET];

    AmazonS3Client *s3 = [[AmazonS3Client alloc] initWithAccessKey:Objc_kAWS_ACCESS_KEY_ID withSecretKey:Objc_kAWS_SECRET_KEY];

    S3GetObjectResponse *response;
    @try
    {
        response = [s3 getObject:getObjectRequest];
    }
    @catch(NSException* ex)
    {

    }
    
    state = DataLoadingParcelStateComplete;
    receivedData = response.body;
    
    
    
    [[NSOperationQueue mainQueue] addOperationWithBlock: ^
     {
         [self reportFinished];

//         self.c
//         if ([other isEqualToValue:@-1])
//         {
//             completion(bwImage, path, other, YES);
//         } else
//         {
//             completion(img, path, other, NO);
//         }
     }];
}

-(void)requestFailed:(ASIHTTPRequest*)rq
{
    NSLog(@"request failed, %@", rq);
    
    state = DataLoadingParcelStateFailed;
    
    NSLog(@"request.error = %@", rq.error.localizedDescription);
    NSLog(@"request.code = %ld", (long)rq.error.code);
    
    state = DataLoadingParcelStateUnstarted;
    //just auto repeat requests that fail for now.
    [self initializeReqeuest];
    //shuffle it to the back of the request list to be a pro, later.
    [request startAsynchronous];
    
}

-(void)requestFinished:(ASIHTTPRequest*)rq
{
    state = DataLoadingParcelStateComplete;
    receivedData = request.responseData;

    [self reportFinished];
}

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
    percent = p;
    
    for (EventDispatcher *event in eventDispatchers)
    {
        if (event.progress)
        {
            event.progress();
        }
    }
}

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
#warning dead code-store here needs to be inserted into EventDispatcher 
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

-(void)loadImage:(NSString *)urlString completionBlock:(void (^)(UIImage *img, BOOL synchronous))completionBlock progressBlock:(void (^)(float progress))progressBlock
{
    DiscardableImage *discardableImage = [cache objectForKey:urlString];
    if (discardableImage)
    {//synchronous return
        completionBlock(discardableImage.image, YES);
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
            dataLoadingParcel = [[DataLoadingParcel alloc] initWithUrl:[NSURL URLWithString:urlString]];
            
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
        UIImage *image = [UIImage imageWithData:parcel.receivedData];
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

-(void (^)(void))progressBlockForParcel:(DataLoadingParcel*)parcel progressBlock:(void(^)(float progress))progressBlock
{
    return ^{
        progressBlock(parcel.percent);
    };
}




@end
