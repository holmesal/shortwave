
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

#import "MessageModel.h"
#import "MessageImage.h"
#import "MessageSpotifyTrack.h"
#import "MessageGif.h"

@interface FCUser ()

@property (assign, nonatomic) FirebaseHandle colorHandle;
@property (strong, nonatomic) Firebase *metaColorFB;

@property (assign, nonatomic) FirebaseHandle iconHandle;
@property (strong, nonatomic) Firebase *metaIconFB;

@end

@implementation FCUser
@synthesize color, icon;
@synthesize fuser;//
@synthesize deviceToken;

//firebase variables
@synthesize colorHandle;
@synthesize metaColorFB;

@synthesize iconHandle;
@synthesize metaIconFB;

static FCUser *currentUser;


-(void)unregisterMetaListener
{
    [metaColorFB removeObserverWithHandle:colorHandle];
    [metaIconFB removeObserverWithHandle:iconHandle];
}

-(void)registerListenersToMeta
{
    metaColorFB = [[Firebase alloc] initWithUrl:[NSString stringWithFormat:@"%@users/%@/meta/color", FIREBASE_ROOT_URL, self.id]];
    colorHandle = [metaColorFB observeEventType:FEventTypeValue withBlock:^(FDataSnapshot *snapshot)
    {
        color = snapshot.value;
    }];
    
    
    metaIconFB = [[Firebase alloc] initWithUrl:[NSString stringWithFormat:@"%@users/%@/meta/icon", FIREBASE_ROOT_URL, self.id]];
    iconHandle = [metaIconFB observeEventType:FEventTypeValue withBlock:^(FDataSnapshot *snapshot)
    {
        icon = snapshot.value;
    }];
    
}


+(FCUser*)owner
{
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
        
        // Log the user id change
        [mixpanel track:@"authIdChanged" properties:@{}];
        
        if ([[NSUserDefaults standardUserDefaults] boolForKey:@"mustSendMessage"])
        {
            [[NSUserDefaults standardUserDefaults] setBool:NO forKey:@"mustSendMessage"];
            //greeting msesage post to their wall
            [self postTextFromHubot:@"Hiya! Welcome to Shortwave!"];
            [self postTextFromHubot:@"You can see how many people are in range above."];
            [self postTextFromHubot:@"Tap your icon in the upper right to change your icon/color."];
            [self postTextFromHubot:@"That's it - have fun!"];
            
            
            // Create a few dummy types of posts to show off the functionality of Shortwave
            // Everthing is coming from Shortbot for now, to keep things simple-like
            NSArray *me = @[[FCUser owner].id];
            
            MessageImage *messageImage = [[MessageImage alloc] initWithSrc:@"http://i.imgur.com/cKLrCik.jpg" andIcon:@"shortbot" color:@"292929" ownerID:@"shortbot" text:@"Lol look at this" width:@480 height:@455];
            [messageImage postToUsers:me];

            MessageSpotifyTrack *spotifyTrack = [[MessageSpotifyTrack alloc] initWithTitle:@"I am a Hologram" uri:@"spotify:track:1OpkIbqR0fKlRSt33oiIGa" artist:@"Mister Heavenly" albumImage:@"https://i.scdn.co/image/31d501956beee416abc15c9d7709977afe473634" andIcon:@"shortbot" color:@"292929" ownerID:@"shortbot" text:@"shared a song with you:"];
            [spotifyTrack postToUsers:me];
          
            MessageGif *messageGif = [[MessageGif alloc] initWithSrc:@"http://i.imgur.com/dupSbtr.gif" andIcon:@"shortbot" color:@"292929" ownerID:@"shortbot" text:@"woaaah" width:@400 height:@300];
            [messageGif postToUsers:me];
            
//            // Oh yeah and a web link
//            Firebase *four = [[wall childByAppendingPath:@"wall"] childByAutoId];
//            [four setValue:@{@"color": @"292929" ,
//                             @"icon":@"shortbot",
//                             @"type":@"link-web",
//                             @"content":@{
//                                     @"url":@"http://google.com",
//                                     @"title":@"Google - We're Not Evil, We Promise!",
//                                     @"description":@"Something awful."
//                                     },
//                             @"meta":@{@"ownerID":@"shortbot"}
//                             }];
//            [[four childByAppendingPath:@"timestamp"] setValue:kFirebaseServerValueTimestamp];
            
            
        }
    }
    
    fuser = bewser;
    

}

- (id)init
{
    self = [super init];
    if (self)
    {
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
// Init the transponder class
        if (!IS_ON_SIMULATOR)
        {
            self.beacon = [[ESTransponder alloc] initWithEarshotID:self.id andFirebaseRootURL:FIREBASE_ROOT_URL];
        }
    }
    
    return self;
}


// Set up the firebase reference
- (void) initFirebase:(NSString *)id
{
    NSString *refUrl = [NSString stringWithFormat:@"%@users/%@", FIREBASE_ROOT_URL, self.id];
    self.ref = [[Firebase alloc] initWithUrl:refUrl];
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


# pragma mark - generate user
- (void) generateNewUser
{
    // Generate the id
    [self generateIds];
    
    // Create ref via firebase
    [self initFirebase:self.id];
    
    // Call update to set these values on firebase, and save to NSUserDefaults
    [self updateUserData];
    
    // Random icon and color
    self.icon = @"profilepic";
    self.color = @"#1A8DE6";
    
    // Log the new user to mixpanel
    Mixpanel *mixpanel = [Mixpanel sharedInstance];
    [mixpanel track:@"User generated" properties:@{}];
}

- (void) updateUserData
{
    // Init user defaults
    NSUserDefaults *prefs = [NSUserDefaults standardUserDefaults];
//    // Color
    [[[self.ref childByAppendingPath:@"meta"] childByAppendingPath:@"color"] setValue:self.color];
    [prefs setValue:self.color forKey:@"color"];
    // Icon
    [[[self.ref childByAppendingPath:@"meta"] childByAppendingPath:@"icon"] setValue:self.icon];
    [prefs setValue:self.icon forKey:@"icon"];

    [prefs setValue:self.id forKey:@"id"];
    // Synchronize preferences
    [prefs synchronize];
}

- (void) pullFromDefaults
{
    NSUserDefaults *prefs = [NSUserDefaults standardUserDefaults];
    color = [prefs valueForKey:@"color"];
    icon = [prefs valueForKey:@"icon"];
    self.id = [prefs valueForKey:@"id"];
}

-(void)setColor:(NSString *)clr
{
    
    if (![clr isEqualToString:color] && [self isOwner])
    {
        //post to firebase
        [[NSUserDefaults standardUserDefaults] setObject:clr forKey:@"color"];
        [[NSUserDefaults standardUserDefaults] synchronize];
        
        if (self.fuser)
        {
            Firebase *colorRef = [[self.ref childByAppendingPath:@"meta"] childByAppendingPath:@"color"];
            [colorRef setValue:clr];
        }
        
        // Set via mixpanel
        Mixpanel *mixpanel = [Mixpanel sharedInstance];
        [mixpanel.people set:@{@"color": clr}];
    }
    color = clr;
}

-(void)setIcon:(NSString *)icn
{
    if (![icn isEqualToString:icon] && [self isOwner])
    {
        //post to firebase
        [[NSUserDefaults standardUserDefaults] setObject:icn forKey:@"icon"];
        [[NSUserDefaults standardUserDefaults] synchronize];
        
        if (self.fuser)
        {
            Firebase *colorRef = [[self.ref childByAppendingPath:@"meta"] childByAppendingPath:@"icon"];
            [colorRef setValue:icn];
        }
        
        // Set via mixpanel
        Mixpanel *mixpanel = [Mixpanel sharedInstance];
        [mixpanel.people set:@{@"icon": icn}];
    }
    icon = icn;
}

-(BOOL)isOwner
{
    return self == [FCUser owner];
}

//generatesIds but also posts to wall a greeting message!
- (void) generateIds
{
    NSArray *syms = [NSThread  callStackSymbols];
    NSString *caller = [[NSString alloc] init];
    if ([syms count] > 1)
    {
        caller = [NSString stringWithFormat: @"<%@ %p> %@ - caller: %@ ", [self class], self, NSStringFromSelector(_cmd),[syms objectAtIndex:1]];
    } else
    {
        caller = [NSString stringWithFormat: @"<%@ %p> %@", [self class], self, NSStringFromSelector(_cmd)];
    }
    
    // Log via mixpanel
    Mixpanel *mixpanel = [Mixpanel sharedInstance];
    [mixpanel track:@"ID generated" properties:@{@"caller": caller}];
    
    
    
    // Generate an id
    NSInteger idInt = esRandomNumberIn(0, 99999999);

    
    self.id = [NSString stringWithFormat:@"%ld",(long)idInt];
    [[NSUserDefaults standardUserDefaults] setValue:self.id forKey:@"id"];
    [[NSUserDefaults standardUserDefaults] setBool:YES forKey:@"mustSendMessage"];
    // Synchronize preferences
    [[NSUserDefaults standardUserDefaults] synchronize];
}

-(void)postTextFromHubot:(NSString *)message
{
    MessageModel *messageModel = [[MessageModel alloc] initWithOwnerID:@"shortbot" andText:message];
    [messageModel postToAll];
}





@end
