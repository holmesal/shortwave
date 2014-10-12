//
//  SWBucketUpload.m
//  Wavelength
//
//  Created by Ethan Sherr on 9/5/14.
//  Copyright (c) 2014 Ethan Sherr. All rights reserved.
//

#import "SWBucketUpload.h"
#import <AWSRuntime/AWSRuntime.h>
#import <AWSS3/AWSS3.h>
#import "ObjcConstants.h"

@interface ProgressAndCompletion : NSObject

@property (nonatomic, copy) void (^progress)(CGFloat p);
@property (nonatomic, copy) void (^completion)(NSError *error);
@property (weak, nonatomic) S3PutObjectRequest *por;

@end

@implementation ProgressAndCompletion
@end

@interface SWBucketUpload () <AmazonServiceRequestDelegate>

@property (nonatomic, retain) AmazonS3Client *s3;
//@property (strong, nonatomic) S3PutObjectRequest *por; //one upload for now

@property (strong, nonatomic) NSMutableDictionary *requests;

@end

static SWBucketUpload *sharedInstance;

@implementation SWBucketUpload
//@synthesize por;
@synthesize s3;
@synthesize requests;

+(SWBucketUpload*)sharedInstance
{
    if (!sharedInstance)
    {
        sharedInstance = [[SWBucketUpload alloc] init];
    }
    return sharedInstance;
}



-(SWBucketUpload*)init
{
    if (self = [super init])
    {
        requests = [[NSMutableDictionary alloc] init];
        @try
        {
            
            s3 = [[AmazonS3Client alloc] initWithAccessKey:Objc_kAWS_ACCESS_KEY_ID withSecretKey:Objc_kAWS_SECRET_KEY];
            s3.endpoint = [AmazonEndpoints s3Endpoint:US_WEST_1];
            

        } @catch(AmazonServiceException* e)
        {
            NSLog(@"e = %@", e);
        }
    }
    return self;
}

-(void)uploadData:(NSData*)data forName:(NSString*)fileName contentType:(NSString*)contentType progress:(void(^)(CGFloat p))progress andComlpetion:(void(^)(NSError *error))completion;
{
    S3PutObjectRequest *por = [[S3PutObjectRequest alloc] initWithKey:fileName inBucket:Objc_kAWS_BUCKET];
    por.cannedACL = [S3CannedACL publicRead];
    por.contentType = contentType;
    por.data = data;
    por.delegate = self;
    NSString *imageUrlString = [NSString stringWithFormat:@"%@/%@/%@", s3.endpoint, Objc_kAWS_BUCKET, fileName];
    NSLog(@"imageUrlString %@", imageUrlString);
    // Put the image data into the specified s3 bucket and object.
    ProgressAndCompletion *pac = [[ProgressAndCompletion alloc] init];
    pac.completion = completion;
    pac.progress = progress;
    pac.por = por;
    
    [s3 putObject:por];

    NSLog(@".url.absoluteString = %@", por.url.absoluteString);
    [requests setObject:pac forKey:por.url.absoluteString];
}

#pragma mark AmazonServiceRequest delegate methods
-(void)request:(AmazonServiceRequest *)request didReceiveResponse:(NSURLResponse *)response
{
    NSLog(@"GOT RESPONSE!~");
    NSHTTPURLResponse *resp = (NSHTTPURLResponse *)response;
    int statusCode = resp.statusCode;
    NSLog(@"status code = %d", statusCode);
    if (statusCode == 200)
    {
        
    }
}


-(void)request:(AmazonServiceRequest *)request didSendData:(long long)bytesWritten totalBytesWritten:(long long)totalBytesWritten totalBytesExpectedToWrite:(long long)totalBytesExpectedToWrite
{
    double p = totalBytesWritten/(double)totalBytesExpectedToWrite;
    
    NSLog(@"percent = %f", p);

    
    
    NSLog(@"request = %@", request);
    S3PutObjectRequest *por = (S3PutObjectRequest*)request;
    NSLog(@"por.url.absoluteString = %@", por.url.absoluteString);
    ProgressAndCompletion *pac = requests[por.url.absoluteString];
    if (pac.progress)
        pac.progress(p);
    
}

-(void)request:(AmazonServiceRequest *)request didCompleteWithResponse:(AmazonServiceResponse *)response
{
//    [s3PutObjectRequests removeObject:request];
//    [self createEventOnFirebase];
    S3PutObjectRequest *por = (S3PutObjectRequest*)request;
    ProgressAndCompletion *pac = requests[por.url.absoluteString];
    if (pac.completion)
        pac.completion(nil);
    [requests removeObjectForKey:por.url.absoluteString];
//    NSLog(@"request %@ finished with response %@", request, response);
//    [[UIApplication sharedApplication] setNetworkActivityIndicatorVisible:NO];
//    
//    [_target performSelector:@selector(uploadCompleted)];
}

@end