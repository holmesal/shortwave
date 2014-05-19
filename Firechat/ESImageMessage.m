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
@synthesize url;
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
            ownerID = [dict objectForKey:@"ownerID"];
            icon = [dict objectForKey:@"icon"];
            color = [dict objectForKey:@"color"];
            type = [dict objectForKey:@"type"];
            url = [dict objectForKey:@"url"];
            
            //is it a gif?
            NSString *gifOrStatic = @"static";
            NSArray *components = [type componentsSeparatedByString:@":"];
            if (components.count > 1)
            {
                gifOrStatic = [components objectAtIndex:1];
            }
            
            if ([gifOrStatic isEqualToString:@"gif"])
            {
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
    NSString *string = [NSString stringWithFormat:@"I was expecting to get strings for text,ownerID,icon,color,type,url: %@", dict];
    
    ESAssert(([text isKindOfClass:[NSString class]] &&
             [ownerID isKindOfClass:[NSString class]] &&
             [icon isKindOfClass:[NSString class] ] &&
             [color isKindOfClass:[NSString class] ] &&
             [type isKindOfClass:[NSString class] ] &&
             [url isKindOfClass:[NSString class] ]), string
             );
}

-(void)testImageStaticMessage
{
    
    NSUserDefaults *prefs = [NSUserDefaults standardUserDefaults];
    NSDictionary *dict = @{@"text": @"",
                           @"ownerID": [FCUser owner].id,
                           @"icon": [prefs objectForKey:kNSUSER_DEFAULTS_ICON],
                           @"color": [prefs objectForKey:kNSUSER_DEFAULTS_COLOR],
                           @"type": @"image:static",
                           @"url": @"http://cdn3.whatculture.com/wp-content/uploads/2013/03/url-711.jpeg"};
    Firebase *mywall = [[[[[FCUser owner].rootRef childByAppendingPath:@"users"] childByAppendingPath:[FCUser owner].id] childByAppendingPath:@"wall"] childByAutoId];
    [mywall setValue:dict];
}
-(void)testImageGifMessage
{
    
    NSUserDefaults *prefs = [NSUserDefaults standardUserDefaults];
    NSDictionary *dict = @{@"text": @"",
                           @"ownerID": [FCUser owner].id,
                           @"icon": [prefs objectForKey:kNSUSER_DEFAULTS_ICON],
                           @"color": [prefs objectForKey:kNSUSER_DEFAULTS_COLOR],
                           @"type": @"image:gif",
                           @"url": @"http://a.gifb.in/1601003555.gif"};
    Firebase *mywall = [[[[[FCUser owner].rootRef childByAppendingPath:@"users"] childByAppendingPath:[FCUser owner].id] childByAppendingPath:@"wall"] childByAutoId];
    [mywall setValue:dict];
}

@end
