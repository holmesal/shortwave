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
        
//            let optionalLinkDetector = NSDataDetector.dataDetectorWithTypes(NSTextCheckingType.Link.toRaw(), error: nil)
//
//            let urlStringRange = NSMakeRange(0, urlString.length)
//            let matchingOptions = NSMatchingOptions.fromRaw(0)!
//
//            if let linkDetector = optionalLinkDetector
//            {
//                if 1 != linkDetector.numberOfMatchesInString(urlString, options:matchingOptions , range: urlStringRange)
//                {
//                    return false
//                }
//            }
//
//            let checkingResult:NSTextCheckingResult = linkDetector.firstMatchInString(urlString, options: matchingOptions, range: urlStringRange)
        return YES;
    }
    

    return NO;
}

@end
