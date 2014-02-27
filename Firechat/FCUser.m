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
//#import "FirebaseSimpleLogin/FirebaseSimpleLogin.h"

typedef void (^CompletionBlockType)(id);

@interface FCUser ()
@property (nonatomic, copy) CompletionBlockType completionBlock;
@end

@implementation FCUser
//
//
//
//// Make that shit a singleton
//+ (void) initialize
//{
//    static BOOL initialized = NO;
//    if(!initialized){
//        initialized = YES;
//        self = [[self alloc] init];
//    }
//}

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
    self.rootRef = [[Firebase alloc] initWithUrl:@"https://orbit.firebaseio.com/"];
    self.ref = [[self.rootRef childByAppendingPath:@"users"] childByAppendingPath:self.id];
}

# pragma mark - push notification registration
- (void)sendProviderDeviceToken:(NSData *)token
{
    NSString *hexToken = [self hexStringFromData:token];
    NSLog(@"Got token, sending this to firebase: %@",hexToken);
    [[self.ref childByAppendingPath:@"pushToken"] setValue:hexToken];
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

- (void) pullFromFirebase
{
    
}

- (void) startBroadcasting
{
    
}

# pragma mark - generate user
- (void) generateNewUser
{
    NSLog(@"Generating new user...");
    // Random icon and color
    self.icon = [self getRandomIcon];
    self.color = [self getRandomColor];
    // Display color for things
    self.displayColor = [self colorWithHexString:self.color];
    
    // Generate the id
    [self generateIds];
    
    // Create ref via firebase
    [self initFirebase:self.id];
    
    // Call update to set these values on firebase, and save to NSUserDefaults
    [self updateUserData];
    
    // Start broadcasting with a beacon
//    [self.beacon startBroadcastingWithMajor:self.major andMinor:self.minor];
    
    // Set on the app delegate
//    FCAppDelegate *del =[[UIApplication sharedApplication] delegate];
//    del.owner = self;
    
    // Finally, emit a "complete" event, so the view can proceed
//    [[NSNotificationCenter defaultCenter] postNotificationName:@"Signup Success" object:nil];
    
    // Return the user
//    return self;
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
    self.displayColor = [self colorWithHexString:self.color];
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


- (void) generateIds
{
    // Generate an id
    self.major = [[NSNumber alloc] initWithInt:arc4random() % 65535];
    //    self.major = [self formatValue:self.major forDigits:@4[self.major length]]
    self.minor = [[NSNumber alloc] initWithInt:arc4random() % 65535];
    self.id = [NSString stringWithFormat:@"%@:%@", self.major, self.minor];
    NSLog(@"Generated id: %@",self.id);
}

- (NSString *)getRandomColor
{
//    return @"#FFA400";
    return @"#1A8DE6";
}

- (NSString *)getRandomIcon
{
    return @"profilepic";
}

# pragma mark - color hex conversion
- (UIColor *) colorWithHexString: (NSString *) hexString {
    NSString *colorString = [[hexString stringByReplacingOccurrencesOfString: @"#" withString: @""] uppercaseString];
    CGFloat alpha, red, blue, green;
    switch ([colorString length]) {
        case 3: // #RGB
            alpha = 1.0f;
            red   = [self colorComponentFrom: colorString start: 0 length: 1];
            green = [self colorComponentFrom: colorString start: 1 length: 1];
            blue  = [self colorComponentFrom: colorString start: 2 length: 1];
            break;
        case 4: // #ARGB
            alpha = [self colorComponentFrom: colorString start: 0 length: 1];
            red   = [self colorComponentFrom: colorString start: 1 length: 1];
            green = [self colorComponentFrom: colorString start: 2 length: 1];
            blue  = [self colorComponentFrom: colorString start: 3 length: 1];
            break;
        case 6: // #RRGGBB
            alpha = 1.0f;
            red   = [self colorComponentFrom: colorString start: 0 length: 2];
            green = [self colorComponentFrom: colorString start: 2 length: 2];
            blue  = [self colorComponentFrom: colorString start: 4 length: 2];
            break;
        case 8: // #AARRGGBB
            alpha = [self colorComponentFrom: colorString start: 0 length: 2];
            red   = [self colorComponentFrom: colorString start: 2 length: 2];
            green = [self colorComponentFrom: colorString start: 4 length: 2];
            blue  = [self colorComponentFrom: colorString start: 6 length: 2];
            break;
        default:
            [NSException raise:@"Invalid color value" format: @"Color value %@ is invalid.  It should be a hex value of the form #RBG, #ARGB, #RRGGBB, or #AARRGGBB", hexString];
            break;
    }
    return [UIColor colorWithRed: red green: green blue: blue alpha: alpha];
}

- (CGFloat) colorComponentFrom: (NSString *) string start: (NSUInteger) start length: (NSUInteger) length {
    NSString *substring = [string substringWithRange: NSMakeRange(start, length)];
    NSString *fullHex = length == 2 ? substring : [NSString stringWithFormat: @"%@%@", substring, substring];
    unsigned hexComponent;
    [[NSScanner scannerWithString: fullHex] scanHexInt: &hexComponent];
    return hexComponent / 255.0;
}


@end
