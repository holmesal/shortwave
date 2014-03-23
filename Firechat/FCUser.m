
//
//  FCUser.m
//  Firechat
//
//  Created by Alonso Holmes on 12/26/13.
//  Copyright (c) 2013 Buildco. All rights reserved.
//

#import "FCUser.h"
#import <Firebase/Firebase.h>
#include <stdlib.h>
#include "FCAppDelegate.h"
#import "UIColor+HexString.h"

typedef void (^CompletionBlockType)(id);

@interface FCUser ()
@property (nonatomic, copy) CompletionBlockType completionBlock;
@end

@implementation FCUser
@synthesize color, icon;



- (id)init
{
    self = [super init];
    if (self) {
        // This should probably happen earlier, depending on where we want to pop up permissions
    }
    return self;
}

// Only run once from appdelegate - initialize as an owner - if the first run, this will be set later and called
- (id) initAsOwner
{
    self = [self init];
    if (self) {
        NSUserDefaults *prefs = [NSUserDefaults standardUserDefaults];
        self.id = [prefs stringForKey:@"id"];
        if (self.id) {
            // Link up with firebase
            [self initFirebase:self.id];
            // Pull from defaults
            [self pullFromDefaults];
        } else{
            [self generateNewUser];
        }
        // Init the beacon
        self.beacon = [[FCBeacon alloc] initWithMajor:self.major andMinor:self.minor];
    }
    
    return self;
}

// Initialize with an ID, pull data from firebase, and run the callback block
//- (id) initWithId:(NSString *)id
//{
////    [self initFirebase];
//    return self;
//}

// Set up the firebase reference
- (void) initFirebase:(NSString *)id
{
    self.rootRef = [[Firebase alloc] initWithUrl:@"https://earshot.firebaseio.com/"];
    self.ref = [[self.rootRef childByAppendingPath:@"users"] childByAppendingPath:self.id];
//    self.onOffRef = [self.ref childByAppendingPath:@"onOff"];
//    [self.onOffRef setValue:[NSNumber numberWithBool:NO]];
}

# pragma mark - push notification registration
- (void)sendProviderDeviceToken:(NSData *)token
{
    NSString *hexToken = [self hexStringFromData:token];
    NSLog(@"Got token, sending this to firebase: %@",hexToken);
    [[self.ref childByAppendingPath:@"deviceToken"] setValue:hexToken];
}

- (NSString *)hexStringFromData:(NSData *)data
{
	NSMutableString *hex = [NSMutableString stringWithCapacity:[data length]*2];
	[data enumerateByteRangesUsingBlock:^(const void *bytes, NSRange byteRange, BOOL *stop) {
		const unsigned char *dataBytes = (const unsigned char *)bytes;
		for (NSUInteger i = byteRange.location; i < byteRange.length; ++i) {
			[hex appendFormat:@"%02x", dataBytes[i]];
		}
	}];
	return hex;
}



# pragma mark - generate user
- (void) generateNewUser
{
    NSLog(@"Generating new user...");
    // Random icon and color
    self.icon = [self getRandomIcon];
    self.color = [self getRandomColor];
    // Display color for things
    self.displayColor = [UIColor colorWithHexString:self.color];
    
    // Generate the id
    [self generateIds];
    
    // Create ref via firebase
    [self initFirebase:self.id];
    
    // Call update to set these values on firebase, and save to NSUserDefaults
    [self updateUserData];
    
}

- (void) updateUserData
{
    // Init user defaults
    NSUserDefaults *prefs = [NSUserDefaults standardUserDefaults];
    // Color
    [[self.ref childByAppendingPath:@"color"] setValue:self.color];
    [prefs setValue:self.color forKey:@"color"];
    // Icon
    [[self.ref childByAppendingPath:@"icon"] setValue:self.icon];
    [prefs setValue:self.icon forKey:@"icon"];
    // Major/minor
    [[self.ref childByAppendingPath:@"major"] setValue:self.major];
    [[self.ref childByAppendingPath:@"minor"] setValue:self.minor];
    [prefs setValue:self.major forKey:@"major"];
    [prefs setValue:self.minor forKey:@"minor"];
    
    [prefs setValue:self.id forKey:@"id"];
    
    // Synchronize preferences
    [prefs synchronize];
}

- (void) pullFromDefaults
{
    // Init
    NSUserDefaults *prefs = [NSUserDefaults standardUserDefaults];
    // Color
    self.color = [prefs valueForKey:@"color"];
    self.displayColor = [UIColor colorWithHexString:self.color];
    // Icon
    self.icon = [prefs valueForKey:@"icon"];
    // Major/minor
    self.major = [prefs valueForKey:@"major"];
    self.minor = [prefs valueForKey:@"minor"];
    // id
    self.id = [prefs valueForKey:@"id"];
    
    NSLog(@"COLOR IS %@",self.color);
    NSLog(@"Got id: %@:%@",self.major,self.minor);
}

-(void)setColor:(NSString *)clr
{
    color = clr;
    if ([self isOwner])
    {
        //post to firebase
        [[self.ref childByAppendingPath:@"color"] setValue:color];
        [[NSUserDefaults standardUserDefaults] setObject:color forKey:@"color"];
        [[NSUserDefaults standardUserDefaults] synchronize];
    }
}

-(void)setIcon:(NSString *)icn
{
    NSLog(@"icon set as %@", icn);
    icon = icn;
    if ([self isOwner])
    {
        //post to firebase
        [[self.ref childByAppendingPath:@"icon"] setValue:icon];
        [[NSUserDefaults standardUserDefaults] setObject:icon forKey:@"icon"];
        [[NSUserDefaults standardUserDefaults] synchronize];
    }
}

-(BOOL)isOwner
{
    return self == ((FCAppDelegate*)([UIApplication sharedApplication].delegate)).owner;
}


//generatesIds but also posts to wall a greeting message!
- (void) generateIds
{
    // Generate an id
    self.major = [[NSNumber alloc] initWithInt:arc4random() % 65535];
    //    self.major = [self formatValue:self.major forDigits:@4[self.major length]]
    self.minor = [[NSNumber alloc] initWithInt:arc4random() % 65535];
    self.id = [NSString stringWithFormat:@"%@:%@", self.major, self.minor];
    
    
    //greeting msesage post to their wall
    [self postHello];
}
-(void)postHello
{
    Firebase *wall = [[[[Firebase alloc] initWithUrl:@"https://earshot.firebaseio.com/"] childByAppendingPath:@"users"] childByAppendingPath:self.id];
    Firebase *post = [[wall childByAppendingPath:@"wall"] childByAutoId];
    [post setValue:self.generateFirstPost];
}

-(NSDictionary*)generateFirstPost
{
    NSString *whiteHex = @"ffffff";
    
    
    return @{@"color": @"FFFFFF" ,
             @"icon":@"nakedicon",
             @"ownerID":self.id,
             @"text":@"Hey! Welcome to Earshot!",
             @"timestamp": [NSNumber numberWithDouble:[[NSDate date] timeIntervalSince1970]]};
}

- (NSString *)getRandomColor
{
    return @"#1A8DE6";
}

- (NSString *)getRandomIcon
{
    return @"profilepic";
}




@end
