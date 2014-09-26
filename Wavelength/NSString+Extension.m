//
//  NSString+Extension.m
//  Shortwave
//
//  Created by Ethan Sherr on 9/3/14.
//  Copyright (c) 2014 Ethan Sherr. All rights reserved.
//

#import "NSString+Extension.h"

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

@end
