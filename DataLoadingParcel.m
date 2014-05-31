//
//  DataLoadingParcel.m
//  Shortwave
//
//  Created by Ethan Sherr on 5/30/14.
//  Copyright (c) 2014 Buildco. All rights reserved.
//

#import "DataLoadingParcel.h"
#import "ASIHTTPRequest.h"
#import "ASIProgressDelegate.h"

@interface DataLoadingParcel () <ASIProgressDelegate>

@property (strong, nonatomic) void (^completionBlock)(DataLoadingParcel *this);
@property (strong, nonatomic) void (^progressBlock)(DataLoadingParcel *this);
@property (strong, nonatomic) ASIHTTPRequest *request;

@end

@implementation DataLoadingParcel

@synthesize progressBlock;
@synthesize completionBlock;


@synthesize url;
@synthesize percent;
@synthesize error;

@synthesize receivedData;
@synthesize request;

@synthesize state;

-(id)init
{
    NSAssert(NO, @"Call initWithUrl:progress:");
    return nil;
}

-(id)initWithUrl:(NSURL *)theUrl progress:(void (^)(DataLoadingParcel *itself))pBlock completion:(void (^)(DataLoadingParcel *itself))compl
{
    if (self = [super init])
    {
        state = DataLoadingParcelStateUnstarted;
        
        url = theUrl;
        progressBlock = pBlock;
        completionBlock = compl;
    }
    return self;
}

//pause control
-(void)pause
{
    NSLog(@"\tPAUSE %d", self.metric);
    if (state == DataLoadingParcelStateDownloading)
    {
        
        state = DataLoadingParcelStatePaused;
        [request cancel];
        
    }

}

-(void)start
{
    NSLog(@"\tSTART %d", self.metric);
    request = [ASIHTTPRequest requestWithURL:url];
    request.downloadProgressDelegate = self;
    
    
    NSString *fileName = [self encodeString:url.absoluteString];
    
    NSString *file = [self pathForFileNamed:fileName];
    NSString *tempFile = [self pathForFileNamed:[fileName stringByAppendingString:@".download"]];

    
    [request setDownloadDestinationPath:file];
    [request setTemporaryFileDownloadPath:tempFile];
    [request setAllowResumeForFileDownloads:YES];
    [request setNumberOfTimesToRetryOnTimeout:NSIntegerMax];
    
    [request setDidFinishSelector:@selector(requestFinished:)];
    [request setDidFailSelector:@selector(requestFailed:)];
    [request setDelegate:self];
    
    
    [request startAsynchronous];
state = DataLoadingParcelStateDownloading;
    
}

//asihttp request callbacks
-(void)requestFinished:(ASIHTTPRequest*)r
{
    NSLog(@"\trequest finisehd");
    
    NSData *data = [NSData dataWithContentsOfFile:request.downloadDestinationPath];
    receivedData = data;
state = DataLoadingParcelStateComplete;
    completionBlock(self);
    
    NSFileManager *fileManager = [NSFileManager defaultManager];
    NSError *deleteError = nil;
    [fileManager removeItemAtPath:request.downloadDestinationPath error:&deleteError];
    if (deleteError)
    {
        NSLog(@"error deletingError = %@", deleteError.localizedDescription);
    }
    
    NSError *deleteError2 = nil;
    [fileManager removeItemAtPath:request.temporaryFileDownloadPath error:&deleteError2];
    if (deleteError2)
    {
        NSLog(@"error deletingError = %@", deleteError.localizedDescription);
    }
}


-(void)requestFailed:(ASIHTTPRequest*)r
{
//    NSLog(@"request failed");
//    error = r.error;
//state = DataLoadingParcelStateFailed;
    //k!
}

-(void)setProgress:(float)newProgress
{
    //what thread?
//    NSLog(@"progress %f for %@", newProgress, url.absoluteString);
    percent = newProgress;
    progressBlock(self);
}

//temporary file storage
-(NSString*)pathForFileNamed:(NSString*)name
{
    NSArray *paths = NSSearchPathForDirectoriesInDomains(NSDocumentDirectory, NSUserDomainMask, YES);
    NSString *documentsDirectory = [paths objectAtIndex:0];
    
    return [NSString stringWithFormat:@"%@/%@", documentsDirectory, name];
}
//base64 encode the url
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


@end
