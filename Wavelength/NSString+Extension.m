//
//  NSString+Extension.m
//  Shortwave
//
//  Created by Ethan Sherr on 9/3/14.
//  Copyright (c) 2014 Ethan Sherr. All rights reserved.
//

#import "NSString+Extension.h"
#import <CommonCrypto/CommonDigest.h>

@implementation NSString(Extension)

+(BOOL)validateUrlString:(NSString*)str
{
    if (str)
    {
        NSDataDetector *linkDetector = [NSDataDetector dataDetectorWithTypes:NSTextCheckingTypeLink error:nil];
        NSRange urlStringRange;
        urlStringRange.length = str.length;
        urlStringRange.location = 0;
        
        NSMatchingOptions matchingOptions = 0;
        if (1 != [linkDetector numberOfMatchesInString:str options:matchingOptions range:urlStringRange])
        {
            return NO;
        }
        
        return YES;
    }
    

    return NO;
}

- (NSString *)MD5String {
    const char *cstr = [self UTF8String];
    unsigned char result[16];
    CC_MD5(cstr, strlen(cstr), result);
    
    return [NSString stringWithFormat:
            @"%02X%02X%02X%02X%02X%02X%02X%02X%02X%02X%02X%02X%02X%02X%02X%02X",
            result[0], result[1], result[2], result[3],
            result[4], result[5], result[6], result[7],
            result[8], result[9], result[10], result[11],
            result[12], result[13], result[14], result[15]
            ];  
}

@end
