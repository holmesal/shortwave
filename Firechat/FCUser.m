
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
#import <FirebaseSimpleLogin/FirebaseSimpleLogin.h>
#import <Mixpanel/Mixpanel.h>


typedef void (^CompletionBlockType)(id);

@interface FCUser ()
@property (nonatomic, copy) CompletionBlockType completionBlock;
@property (strong, nonatomic) Firebase *wall;
@end

@implementation FCUser
@synthesize color, icon;
@synthesize fuser;
@synthesize deviceToken;

static FCUser *currentUser;

/*
 {
 "rules":
 {
 ".read":true,
 ".write":true,
 
 "users":
 {
 "$user":{
 
 "userId":{
 ".read":"auth != null && auth.id == data.val()",
 ".write":true
 },
 
 "$attr":{
 ".read":"auth != null",
 ".write":"auth != null && auth.id == data.parent().child('userId').val()"
 }
 
 
 
 
 }
 }
 }
 
 }
 */


+(FCUser*)owner
{
//    NSAssert(currentUser, @"must have owner");
    return currentUser;
}
+(FCUser*)createOwner
{
    if (![FCUser owner])
    {
        currentUser = [[FCUser alloc] initAsOwner];
    }
    return currentUser;
}

-(void)setFuser:(FAUser *)bewser
{
    
    if (!fuser)
    {
        NSString *userId = bewser.userId;

        self.deviceToken = self.deviceToken;
        self.color = color;
        self.icon = icon;

        [[self.ref childByAppendingPath:@"userId"] setValue:userId];
        [[self.ref childByAppendingPath:@"deviceToken"] setValue:self.deviceToken];
        
        // Set via mixpanel
        Mixpanel *mixpanel = [Mixpanel sharedInstance];
        [mixpanel identify:self.id];
        [mixpanel.people set:@{@"userID": self.id}];
        [mixpanel.people set:@{@"name": self.id}];
        
        if ([[NSUserDefaults standardUserDefaults] boolForKey:@"mustSendMessage"])
        {
            [[NSUserDefaults standardUserDefaults] setBool:NO forKey:@"mustSendMessage"];
            //greeting msesage post to their wall
            [self postHello:@"Hiya! Welcome to Earshot!"];
            [self postHello:@"You can see how many people are in range above."];
            [self postHello:@"Tap your icon in the upper right to change your icon/color."];
            [self postHello:@"That's it - have fun!"];
        }
    }
    
    fuser = bewser;
    

}

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
        if (self.id)
        {
            // Link up with firebase
            [self initFirebase:self.id];
            // Pull from defaults
            [self pullFromDefaults];
        } else
        {
            [self generateNewUser];
        }
        // Init the beacon
//        self.beacon = [[FCBeacon alloc] initWithMajor:self.major andMinor:self.minor];
        // Init the transponder class
        self.beacon = [[ESTransponder alloc] initWithEarshotID:self.id andFirebaseRootURL:FIREBASE_ROOT_URL];
        
        // Listen for beacon discover events
        [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(bluetoothDiscover:) name:kTransponderEventEarshotUserDiscovered object:nil];
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
    self.rootRef = [[Firebase alloc] initWithUrl:FIREBASE_ROOT_URL];
    self.ref = [[self.rootRef childByAppendingPath:@"users"] childByAppendingPath:self.id];
    
    // Start listening to the wall, just to see if it persists better
    self.wall = [self.ref childByAppendingPath:@"wall"];

}

# pragma mark - push notification registration
- (void)sendProviderDeviceToken:(NSData *)token
{
    //setter and getter link this with firebase and NSUserDefaults as appropriate
    self.deviceToken = [self hexStringFromData:token];
    
}
//setter
-(void)setDeviceToken:(NSString *)dvcToken
{
//    NSLog(@"Got token: %@",self.deviceToken);
    deviceToken = dvcToken;
    if (deviceToken)
    {
        // This will fail if not logged in but no big deal
        [[self.ref childByAppendingPath:@"deviceToken"] setValue:self.deviceToken];
        [[NSUserDefaults standardUserDefaults] setObject:dvcToken forKey:@"deviceToken"];
    }
}
//gettter
-(NSString*)deviceToken
{
    if (!deviceToken)
    {
        deviceToken = [[NSUserDefaults standardUserDefaults] objectForKey:@"deviceToken"];
    }
    return deviceToken;
}

- (NSString *)hexStringFromData:(NSData *)data
{
	NSMutableString *hex = [NSMutableString stringWithCapacity:[data length]*2];
	[data enumerateByteRangesUsingBlock:^(const void *bytes, NSRange byteRange, BOOL *stop)
    {
		const unsigned char *dataBytes = (const unsigned char *)bytes;
		for (NSUInteger i = byteRange.location; i < byteRange.length; ++i)
        {
			[hex appendFormat:@"%02x", dataBytes[i]];
		}
	}];
	return hex;
}

# pragma mark - bluetooth discover events
- (void)bluetoothDiscover:(NSNotification *)note
{
    // Got a beacon from the bluetooth stack
//    NSLog(@"Got a discover event!");
//    NSLog(@"%@",note.userInfo);
    // Check if this user already exists in this array
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
//    [[self.ref childByAppendingPath:@"major"] setValue:self.major];
//    [[self.ref childByAppendingPath:@"minor"] setValue:self.minor];
//    [prefs setValue:self.major forKey:@"major"];
//    [prefs setValue:self.minor forKey:@"minor"];
    
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
//    self.major = [prefs valueForKey:@"major"];
//    self.minor = [prefs valueForKey:@"minor"];
    // id
    self.id = [prefs valueForKey:@"id"];
    
    NSLog(@"COLOR IS %@",self.color);
//    NSLog(@"Got id: %@:%@",self.major,self.minor);
}

-(void)setColor:(NSString *)clr
{
    color = clr;
    if ([self isOwner])
    {
        //post to firebase
        [[NSUserDefaults standardUserDefaults] setObject:color forKey:@"color"];
        [[NSUserDefaults standardUserDefaults] synchronize];
        
        if (self.fuser)
        {
            Firebase *colorRef = [self.ref childByAppendingPath:@"color"];
            [colorRef setValue:color];
        }
        
        // Set via mixpanel
        Mixpanel *mixpanel = [Mixpanel sharedInstance];
        [mixpanel.people set:@{@"color": clr}];
    }
}

-(void)setIcon:(NSString *)icn
{
    NSLog(@"icon set as %@", icn);
    icon = icn;
    if ([self isOwner])
    {
        //post to firebase
//        [[self.ref childByAppendingPath:@"icon"] setValue:icon];
        [[NSUserDefaults standardUserDefaults] setObject:icon forKey:@"icon"];
        [[NSUserDefaults standardUserDefaults] synchronize];
        
        if (self.fuser)
        {
            Firebase *colorRef = [self.ref childByAppendingPath:@"icon"];
            [colorRef setValue:icon];
        }
        
        // Set via mixpanel
        Mixpanel *mixpanel = [Mixpanel sharedInstance];
        [mixpanel.people set:@{@"icon": icn}];
    }
}

-(void)synchWithFirebase
{
    if ([self isOwner] && self.fuser && self.fuser.userId)
    {
        [[self.ref childByAppendingPath:@"color"] setValue:color];
    }
}

-(BOOL)isOwner
{
    return self == [FCUser owner];
}


//generatesIds but also posts to wall a greeting message!
- (void) generateIds
{
    // Generate an id
    NSInteger idInt = esRandomNumberIn(0, 99999999);
    
    self.id = [NSString stringWithFormat:@"%ld",(long)idInt];
    [[NSUserDefaults standardUserDefaults] setValue:self.id forKey:@"id"];
    [[NSUserDefaults standardUserDefaults] setBool:YES forKey:@"mustSendMessage"];
}
-(void)postHello:(NSString *)message
{
    Firebase *wall = [[[[Firebase alloc] initWithUrl:FIREBASE_ROOT_URL] childByAppendingPath:@"users"] childByAppendingPath:self.id];
    Firebase *post = [[wall childByAppendingPath:@"wall"] childByAutoId];
    [post setValue:[self generateFirstPost:message]];
    [[post childByAppendingPath:@"timestamp"] setValue:kFirebaseServerValueTimestamp];
}

-(NSDictionary*)generateFirstPost:(NSString *)message
{
    return @{@"color": @"FFFFFF" ,
             @"icon":@"nakedicon",
             @"text":message,
             @"meta":@{@"ownerID":@"Welcome:Bot"}
             };
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
