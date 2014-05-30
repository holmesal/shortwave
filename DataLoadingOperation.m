//
//  DataLoadingOperation.m
//  ESImageLoader
//
//  Created by Ethan Sherr on 5/17/14.
//  Copyright (c) 2014 Ethan Sherr. All rights reserved.
//

#import "DataLoadingOperation.h"
#import "ASIHTTPRequest.h"
#import "ASIHTTPRequestDelegate.h"
#import "ASIProgressDelegate.h"
@interface DataLoadingOperation () <ASIProgressDelegate, ASIHTTPRequestDelegate> //<NSURLConnectionDelegate>

//@property (strong, nonatomic) NSURLConnection *connection;
@property (assign, nonatomic) BOOL finished;

//@property (assign, nonatomic) long long contentSize;

//@property (strong, nonatomic) void (^completionBlock)(DataLoadingOperation *this);
//@property (strong, nonatomic) void (^failureBlock)(DataLoadingOperation *this);
@property (strong, nonatomic) void (^progressBlock)(DataLoadingOperation *this);
//@property (strong, nonatomic) void (^beganBlock)(DataLoadingOperation *this);

@property (strong, nonatomic) ASIHTTPRequest *request;

@end

@implementation DataLoadingOperation

@synthesize url;
//@synthesize connection;
@synthesize finished;


//@synthesize completionBlock;
//@synthesize failureBlock;
@synthesize progressBlock;
//@synthesize beganBlock;

@synthesize response;
@synthesize percent;
@synthesize error;
@synthesize receivedData;
@synthesize wasCancelled;

@synthesize request;
//-(id)initWithUrl:(NSURL *)theUrl
//      completion:(void(^)(DataLoadingOperation *this))comp
//         failure:(void(^)(DataLoadingOperation *this))fail
//        progress:(void(^)(DataLoadingOperation *this))prog
//           began:(void(^)(DataLoadingOperation *this))beg
//{
//    if (self = [super init])
//    {
//        NSLog(@"INIT DLO %@", theUrl.absoluteString);
//        //set completion
////        completionBlock = comp;
////        failureBlock = fail;
//        progressBlock = prog;
//        beganBlock = beg;
//        
//        //some vars
//        finished = NO;
//        url = theUrl;
//        connection = nil;
//    
//        
//    }
//    return self;
//}

-(id)initWithUrl:(NSURL *)theUrl progress:(void(^)(DataLoadingOperation *this))prog
{
    if (self = [super init])
    {
        finished = NO;
        url = theUrl;
        self.progressBlock = prog;
    }
    return self;
}

//-(void)cancel
//{
//    if (connection)
//    {
//        [connection cancel];
//        connection = nil;
//        finished = YES;
//        wasCancelled = YES;
//        failureBlock(self);
//    }
//}

static char *alphabet = "ABCDEFGHIJKLMNOPQRSTUVWXYZabcdefghijklmnopqrstuvwxyz0123456789+/";
- (NSString *)encodeString:(NSString *)data
{
    const char *input = [data cStringUsingEncoding:NSUTF8StringEncoding];
    unsigned long inputLength = [data length];
    unsigned long modulo = inputLength % 3;
    unsigned long outputLength = (inputLength / 3) * 4 + (modulo ? 4 : 0);
    unsigned long j = 0;
    
    // Do not forget about trailing zero
    unsigned char *output = malloc(outputLength + 1);
    output[outputLength] = 0;
    
    // Here are no checks inside the loop, so it works much faster than other implementations
    for (unsigned long i = 0; i < inputLength; i += 3) {
        output[j++] = alphabet[ (input[i] & 0xFC) >> 2 ];
        output[j++] = alphabet[ ((input[i] & 0x03) << 4) | ((input[i + 1] & 0xF0) >> 4) ];
        output[j++] = alphabet[ ((input[i + 1] & 0x0F)) << 2 | ((input[i + 2] & 0xC0) >> 6) ];
        output[j++] = alphabet[ (input[i + 2] & 0x3F) ];
    }
    // Padding in the end of encoded string directly depends of modulo
    if (modulo > 0) {
        output[outputLength - 1] = '=';
        if (modulo == 1)
            output[outputLength - 2] = '=';
    }
    NSString *s = [NSString stringWithUTF8String:(const char *)output];
    free(output);
    return s;
}

-(void)main
{

    
    request = [ASIHTTPRequest requestWithURL:url];
    [request setDownloadProgressDelegate:self];
    
    NSString *fileName = [self encodeString:url.absoluteString];

    
    NSString *tempFile = [self pathForFileNamed:[NSString stringWithFormat:@"%@.download", fileName]];
    NSString *file = [self pathForFileNamed:fileName];
    
    [request setDownloadDestinationPath:file];
    [request setTemporaryFileDownloadPath:tempFile];
    [request setAllowResumeForFileDownloads:YES];

    [request startSynchronous];
    
    NSFileManager *fileManager = [NSFileManager defaultManager];
    receivedData = [NSData dataWithContentsOfFile:file];
    BOOL fileExists1 = [fileManager fileExistsAtPath:file];
    error = request.error;
    if (error)
    {
        NSLog(@"MAIN: error DLO %@", error.localizedDescription);
    }
    
    NSError *deleteError= nil;
    if (![fileManager removeItemAtPath:file error:&deleteError])
    {
        NSLog(@"error while deleteing file %@[%@] : %@", url.absoluteString, fileName, deleteError.localizedDescription);
    } else
    {
        NSLog(@"removed %@[%@]", url.absoluteString, fileName);
    }
    NSURL *url = [NSURL fileURLWithPath:file];
    BOOL fileExists2 = [fileManager fileExistsAtPath:file];
    id something = [NSData dataWithContentsOfFile:file];
    NSLog(@"somethign = %@", something);
}


//-(void)createTempDirectory
//{
//    NSError *createDirectoryError = nil;
//    NSURL *directoryURL = [NSURL fileURLWithPath:[NSTemporaryDirectory() stringByAppendingPathComponent:[[NSProcessInfo processInfo] globallyUniqueString]] isDirectory:YES];
//    [[NSFileManager defaultManager] createDirectoryAtURL:directoryURL withIntermediateDirectories:YES attributes:nil error:&createDirectoryError];
//}

-(NSString*)pathForFileNamed:(NSString*)name
{
    NSArray *paths = NSSearchPathForDirectoriesInDomains(NSDocumentDirectory, NSUserDomainMask, YES);
    NSString *documentsDirectory = [paths objectAtIndex:0];

    return [NSString stringWithFormat:@"%@/%@", documentsDirectory, name];
}
- (void)removeImage:(NSString *)fileName
{
    NSFileManager *fileManager = [NSFileManager defaultManager];
    NSString *documentsPath = [NSSearchPathForDirectoriesInDomains(NSDocumentDirectory, NSUserDomainMask, YES) objectAtIndex:0];
    
    NSString *filePath = [documentsPath stringByAppendingPathComponent:fileName];
    NSError *error;
    BOOL success = [fileManager removeItemAtPath:filePath error:&error];
    if (success)
    {
        UIAlertView *removeSuccessFulAlert=[[UIAlertView alloc]initWithTitle:@"Congratulation:" message:@"Successfully removed" delegate:self cancelButtonTitle:@"Close" otherButtonTitles:nil];
        [removeSuccessFulAlert show];
    }
    else
    {
        NSLog(@"Could not delete file -:%@ ",[error localizedDescription]);
    }
}

-(void)resume
{
    NSURL *url = [NSURL URLWithString:
                  @"http://allseeing-i.com/ASIHTTPRequest/Tests/the_great_american_novel.txt"];
    ASIHTTPRequest *request = [ASIHTTPRequest requestWithURL:url];
    
    NSString *downloadPath = @"/Users/ben/Desktop/my_work_in_progress.txt";
    
    // The full file will be moved here if and when the request completes successfully
    [request setDownloadDestinationPath:downloadPath];
    
    // This file has part of the download in it already
    [request setTemporaryFileDownloadPath:@"/Users/ben/Desktop/my_work_in_progress.txt.download"];
    [request setAllowResumeForFileDownloads:YES];
    [request startSynchronous];
    
    //The whole file should be here now.
    NSString *theContent = [NSString stringWithContentsOfFile:downloadPath];
}


-(void)setProgress:(float)newProgress
{
    percent = newProgress;
    progressBlock(self);
}

#pragma mark NSURLConnectionDelegate methods

//-(void)connection:(NSURLConnection *)connection didReceiveResponse:(NSHTTPURLResponse *)theResponse
//{
//    
//    response = theResponse;
//    int statusCode_ = [response statusCode];
//    if (statusCode_ == 200)
//    {
//        self.contentSize = [response expectedContentLength];
////        NSLog(@"%@ contentSize = %lld", self.url.absoluteString, self.contentSize);
//    }
//    
//    began(self);
//    
//    
//    [receivedData  setLength:0];
//    
//}
//-(void)connection:(NSURLConnection *)connection didReceiveData:(NSData *)data
//{
//    NSLog(@"%@ prog = %lu", url.absoluteString, (unsigned long)[data length]);
//    [receivedData appendData:data];
//    percent = ((float)[receivedData length]) / self.contentSize;
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
////    NSLog(@"%@ success %lu", url.absoluteString, (unsigned long)[receivedData length]);
//    
//
//
//    
//    completion(self);
//    
//    
//    connection = nil;
//    receivedData = nil;
//    finished = YES;
//
//    
//    
//}
//
//
//#pragma mark DataLoadingOperation override methods
//-(BOOL)isConcurrent
//{
//    return NO;
//}
////-(BOOL)isExecuting
////{
////    return (connection != nil);
////}
//-(BOOL)isFinished
//{
//    return finished;
//}
//-(void)clearAllBlocks
//{
//
//}

-(void)dealloc
{
//    NSLog(@"dealloc dataLoadingOperation %@", url.absoluteString);
}

@end
