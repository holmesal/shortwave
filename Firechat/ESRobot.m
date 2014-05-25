//
//  ESRobot.m
//  Shortwave
//
//  Created by Alonso Holmes on 5/24/14.
//  Copyright (c) 2014 Buildco. All rights reserved.
//

#import "ESRobot.h"
#import "NSObject+SBJson.h"

@implementation ESRobot

- (void)checkForCommand:(NSString *)text
{
    
    
    NSString *pattern = @"(image|img)( me)?(.*)";
    
    NSString *queryText = [self matchText:text toPattern:pattern];
    if (queryText) {
        NSLog(@"Matched! Query is %@",queryText);
        
        NSString *encodedQuery = [queryText stringByAddingPercentEscapesUsingEncoding:NSASCIIStringEncoding];
        
        NSString *fullURL = [NSString stringWithFormat:@"http://ajax.googleapis.com/ajax/services/search/images?v=1.0&rsz=8&safe=active&imgsz=medium&q=%@",encodedQuery];
        
        NSMutableURLRequest *request = [NSMutableURLRequest requestWithURL:[NSURL URLWithString:fullURL]];
        [request setHTTPMethod:@"GET"];
        
        
        dispatch_async(dispatch_get_global_queue(0, 0), ^{
            NSURLResponse *response = nil;
            NSError *error = nil;
            NSData *data = [NSURLConnection sendSynchronousRequest:request returningResponse:&response error:&error];
            NSString *stringData = [[NSString alloc] initWithData:data encoding:NSUTF8StringEncoding];
            NSDictionary *imageResults = [stringData JSONValue];
            dispatch_sync(dispatch_get_main_queue(), ^{
                // Post to firebase
                NSLog(@"Got dictionary: %@", imageResults);
                NSLog(@"Response code: %@", [imageResults valueForKey:@"responseStatus"]);
                NSLog(@"done!");
                
                if (!error && [(NSNumber *)[imageResults valueForKey:@"responseStatus"]  isEqual: @200]) {
                    NSLog(@"OK!");
                    // Get a random result
                    NSArray *imageArray = [[imageResults objectForKey:@"responseData"] objectForKey:@"results"];
                    NSLog(@"Image array: %@", imageArray);
                    NSDictionary *randomImage = [imageArray objectAtIndex:esRandomNumberIn(0, (int)[imageArray count])];
                    NSLog(@"Random image: %@", randomImage);
                    NSLog(@"Random image title: %@", [randomImage objectForKey:@"unescapedUrl"]);
                    
                    // Post the image to firebase
                    NSLog(@"Do this...");
                }
            });
        });
    }

    
    
    
    
    
    
    
    
    
    
//    NSLog(@"group4: %@", [searchedString substringWithRange:[match rangeAtIndex:4]]);
    
    
    NSLog(@"done!");
    
}

- (NSString *)matchText:(NSString *)text toPattern:(NSString *)pattern
{
    NSLog(@"Matching string %@ to pattern %@",text,pattern);
    
    NSString *searchedString = text;
    NSRange searchedRange = NSMakeRange(0, [text length]);
    
    NSError *error = nil;
    
    NSRegularExpression *regex = [NSRegularExpression regularExpressionWithPattern:pattern options:NSRegularExpressionCaseInsensitive error:&error];
    NSTextCheckingResult *match = [regex firstMatchInString:searchedString options:0 range:searchedRange];
    
    NSLog(@"ranges: %lu", (unsigned long)[match numberOfRanges]);
    
    if ([match numberOfRanges] > 0)
    {
        // Get the last result
        NSString *lastResult = [searchedString substringWithRange:[match rangeAtIndex:[match numberOfRanges]-1]];
    
        // Trim any whitespace from the string
        NSString *trimmedString = [lastResult stringByTrimmingCharactersInSet:
                                   [NSCharacterSet whitespaceCharacterSet]];
        
        return trimmedString;
        
        NSLog(@"Query: %@", trimmedString);
    } else {
        return nil;
    }
}



@end
