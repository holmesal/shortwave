//
//  ESImageMessage.m
//  Shortwave
//
//  Created by Ethan Sherr on 5/18/14.
//  Copyright (c) 2014 Buildco. All rights reserved.
//

#import "ESImageMessage.h"
#import "FCUser.h"

@implementation ESImageMessage

@synthesize location;
@synthesize text;
@synthesize ownerID;
@synthesize icon;
@synthesize color;
@synthesize type;
@synthesize src;
@synthesize isGif;


-(id)initWithSnapshot:(FDataSnapshot*)snapshot
{
    if (self = [super init])
    {
        NSDictionary *dict = snapshot.value;
        ESAssert([dict isKindOfClass:[NSDictionary class]], @"snapshot.value supplied to ESImageMessage is not a dictionary");
        if ([dict isKindOfClass:[NSDictionary class]])
        {
            text = [dict objectForKey:@"text"];
            ownerID = [[dict objectForKey:@"meta"] objectForKey:@"ownerID"];
            icon = [dict objectForKey:@"icon"];
            color = [dict objectForKey:@"color"];
            type = [dict objectForKey:@"type"];
            src = [dict objectForKey:@"src"];
            
            //is it a gif?
            NSRange gifSuffixRange = [src rangeOfString:@".gif#.png"];
            if (gifSuffixRange.location != NSNotFound &&
                gifSuffixRange.location + gifSuffixRange.length == src.length)
            {
                NSLog(@"it's a giffy!");
                isGif = YES;
            } else
            {
                isGif = NO;
            }

            //ESAssertion check that all values are strings
            [self checkValidityOfValues:dict];
        }
    }
    return self;
}




//validity check
-(void)checkValidityOfValues:(NSDictionary*)dict
{
    NSString *string = [NSString stringWithFormat:@"I was expecting to get strings for text,ownerID,icon,color,type,src: %@", dict];
    
    ESAssert((
             [ownerID isKindOfClass:[NSString class]] &&
             [icon isKindOfClass:[NSString class] ] &&
             [color isKindOfClass:[NSString class] ] &&
             [type isKindOfClass:[NSString class] ] &&
             [src isKindOfClass:[NSString class] ]), string
             );
}

#warning remove these methods, they were only for definining dictionaries anyway.
-(void)testImageStaticMessage
{
    
    NSUserDefaults *prefs = [NSUserDefaults standardUserDefaults];
    NSDictionary *dict = @{@"text": @"",
                           @"meta": @{@"ownerID" : [FCUser owner].id},
                           @"icon": [prefs objectForKey:kNSUSER_DEFAULTS_ICON],
                           @"color": [prefs objectForKey:kNSUSER_DEFAULTS_COLOR],
                           @"type": @"image",
                           @"src": @"http://cdn3.whatculture.com/wp-content/uploads/2013/03/url-711.jpeg"};
    Firebase *mywall = [[[[[FCUser owner].rootRef childByAppendingPath:@"users"] childByAppendingPath:[FCUser owner].id] childByAppendingPath:@"wall"] childByAutoId];
    [mywall setValue:dict];
}
#warning remove these methods, they were only for definining dictionaries anyway.
-(void)testImageGifMessage
{
    NSUserDefaults *prefs = [NSUserDefaults standardUserDefaults];
    NSDictionary *dict = @{@"text": @"",
                            @"meta": @{@"ownerID" : [FCUser owner].id},
                           @"icon": [prefs objectForKey:kNSUSER_DEFAULTS_ICON],
                           @"color": [prefs objectForKey:kNSUSER_DEFAULTS_COLOR],
                           @"type": @"gif",
                           @"src": @"http://a.gifb.in/1601003555.gif"};
    Firebase *mywall = [[[[[FCUser owner].rootRef childByAppendingPath:@"users"] childByAppendingPath:[FCUser owner].id] childByAppendingPath:@"wall"] childByAutoId];
    [mywall setValue:dict];
}

@end
