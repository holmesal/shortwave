//
//  DataLoadingOperation.m
//  ESImageLoader
//
//  Created by Ethan Sherr on 5/17/14.
//  Copyright (c) 2014 Ethan Sherr. All rights reserved.
//

#import "DataLoadingOperation.h"

@interface DataLoadingOperation () <NSURLConnectionDelegate>

@property (strong, nonatomic) NSURLConnection *connection;
@property (assign, nonatomic) BOOL finished;



@property (strong, nonatomic) void (^completion)(DataLoadingOperation *this);
@property (strong, nonatomic) void (^failure)(DataLoadingOperation *this);
@property (strong, nonatomic) void (^progress)(DataLoadingOperation *this);
@property (strong, nonatomic) void (^began)(DataLoadingOperation *this);


@end

@implementation DataLoadingOperation

@synthesize url;
@synthesize connection;
@synthesize finished;

@synthesize completion;
@synthesize failure;
@synthesize progress;
@synthesize began;

@synthesize response;
@synthesize percent;
@synthesize error;
@synthesize receivedData;
@synthesize wasCancelled;

-(id)initWithUrl:(NSURL *)theUrl
      completion:(void(^)(DataLoadingOperation *this))comp
         failure:(void(^)(DataLoadingOperation *this))fail
        progress:(void(^)(DataLoadingOperation *this))prog
           began:(void(^)(DataLoadingOperation *this))beg
{
    if (self = [super init])
    {
        //set completion
        completion = comp;
        failure = fail;
        progress = prog;
        began = beg;
        
        //some vars
        finished = NO;
        url = theUrl;
        connection = nil;
    }
    return self;
}

-(void)cancel
{
    if (connection)
    {
        [connection cancel];
        connection = nil;
        finished = YES;
        wasCancelled = YES;
        failure(self);
    }
}

-(void)main
{
//    NSLog(@"main of data loading operation %@", [url.absoluteString substringToIndex:5]);
    NSURLRequest *request = [NSURLRequest requestWithURL:url cachePolicy:NSURLRequestUseProtocolCachePolicy timeoutInterval:60.0];
    began(self);
    receivedData = [[NSMutableData alloc] init];
    //starts the connection
    
    NSURLResponse *r = nil;
    NSError *e = nil;
    
    NSData *data = [NSURLConnection sendSynchronousRequest:request returningResponse:&r error:&e];
    error = e;
    response = r;
    receivedData = data;
    
    if (error)
    {
        failure(self);
    } else
    if (data)
    {
        completion(self);
    }
    
//    connection = [NSURLConnection connectionWithRequest:request delegate:self];
//    if (!connection)
//    {
//        // Release the receivedData object.
//        receivedData = nil;
//        finished = YES;
//        error = [[NSError alloc] initWithDomain:@"idk" code:12345 userInfo:nil];
//        failure(self);
//        // Inform the user that the connection failed.
//    }
}
#pragma mark NSURLConnectionDelegate methods

//-(void)connection:(NSURLConnection *)connection didReceiveResponse:(NSURLResponse *)theResponse
//{
//    response = theResponse;
//    began(self);
//    
//    
//    [receivedData setLength:0];
//}
//-(void)connection:(NSURLConnection *)connection didReceiveData:(NSData *)data
//{
//    NSLog(@"progress happened!");
//    [receivedData appendData:data];
//    progress(self);
//}
//- (void)connection:(NSURLConnection *)cnn didFailWithError:(NSError *)err
//{
//    connection = nil;
//    receivedData = nil;
//    error = err;
//    finished = YES;
//    
//    // inform the user
//    NSLog(@"Connection failed! Error - %@ %@",
//          [error localizedDescription],
//          [[error userInfo] objectForKey:NSURLErrorFailingURLStringErrorKey]);
//    
//    failure(self);
//}
//- (void)connectionDidFinishLoading:(NSURLConnection *)cnn
//{
//    NSLog(@"Succeeded! Received %lu bytes of data",(unsigned long)[receivedData length]);
//
//    connection = nil;
//    receivedData = nil;
//    finished = YES;
//
//    completion(self);
//    
//}


#pragma mark DataLoadingOperation override methods
-(BOOL)isConcurrent
{
    return NO;
}
//-(BOOL)isExecuting
//{
//    return (connection != nil);
//}
//-(BOOL)isFinished
//{
//    return finished;
//}
-(void)clearAllBlocks
{

}

@end
