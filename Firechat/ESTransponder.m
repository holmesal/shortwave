//
//  ESTransponder.m
//  Earshot
//
//  Created by Alonso Holmes on 4/1/14.
//  Copyright (c) 2014 Buildco. All rights reserved.
//

#import "ESTransponder.h"
#import <Firebase/Firebase.h>
#import <Mixpanel/Mixpanel.h>

// Extensions
#import "CBCentralManager+Ext.h"
#import "CBPeripheralManager+Ext.h"
#import "CBUUID+Ext.h"

#import "FCUser.h"

#define DEBUG_CENTRAL NO
#define DEBUG_PERIPHERAL NO
#define DEBUG_BEACON YES
#define DEBUG_USERS YES
#define DEBUG_TIMEOUTS NO
#define DEBUG_NOTIFICATIONS NO
#define IS_RUNNING_ON_SIMULATOR NO

#define MAX_BEACON 19 // How many beacons to use (IOS max 19)
#define TIMEOUT 30.0 // How old should a user be before I consider them gone?
#define REPORTING_INTERVAL 12.0 // How often to report to firebase
#define BACKGROUND_REPORTING_INTERVAL 3.0 // How often to report, when in the background
#define BEACON_TIMEOUT 10.0 // How long to range when a beacon is discovered (background only)
#define NOTIFICATION_TIMEOUT 1200.0 // Minimum time between sending discover notifications
#define CHIRP_LENGTH 10.0 // How long to chirp for? NOTE - might take up to 40 seconds more for other devices to exit the region

@interface ESTransponder() <CBPeripheralManagerDelegate, CBCentralManagerDelegate, CLLocationManagerDelegate>

@property (nonatomic) BOOL bluetoothWasTried;
@property (nonatomic) BOOL coreLocationWasTried;
// Bluetooth / main class stuff
@property (strong, nonatomic) CBUUID *identifier;
@property (strong, nonatomic) CBCentralManager *centralManager;
@property (strong, nonatomic) CBPeripheralManager *peripheralManager;
@property (strong, nonatomic) NSDictionary *bluetoothAdvertisingData;
@property (strong, nonatomic) NSMutableDictionary *bluetoothUsers;

// Mixpanel
@property (strong, nonatomic) Mixpanel *mixpanel;

// Beacon broadcasting
@property NSInteger flipCount;
@property BOOL currentlyChirping;
@property BOOL flippingBreaker;
@property BOOL isFlipping;
@property (strong, nonatomic) CLBeaconRegion *chirpBeaconRegion;
@property (strong, nonatomic) NSDictionary *chirpBeaconData;
@property (strong, nonatomic) NSDictionary *identityBeaconData;

// Beacon monitoring
@property (strong, nonatomic) CLLocationManager *locationManager;
@property (strong, nonatomic) NSMutableArray *regions;
@property (strong, nonatomic) NSArray *regionUUIDS;
@property (strong, nonatomic) CLBeaconRegion *rangingRegion;
@property (strong, nonatomic) NSTimer *rangingTimeout;

// Firebase-synced users array
@property (strong, nonatomic) Firebase *rootRef;
@property (strong, nonatomic) Firebase *earshotUsersRef;
//@property (strong, nonatomic) NSMutableDictionary *earshotUsers;
@property (strong, nonatomic) NSTimer *filterTimer;
@property (strong, nonatomic) NSMutableDictionary *lastReported;
@property (assign, nonatomic) BOOL actuallyRemove;
@property (strong, nonatomic) NSDate *lastNotificationEvent;

// Oscillator
@property NSInteger broadcastMode;

@end

@implementation ESTransponder
@synthesize earshotID;
//@synthesize peripheralManagerIsRunning;
@synthesize stackIsRunning;



- (id)initWithEarshotID:(NSString *)userID andFirebaseRootURL:(NSString *)firebaseURL
{
    if ((self = [super init])) {
        self.earshotID = userID;
        self.identifier = [CBUUID UUIDWithString:IDENTIFIER_STRING];
        self.bluetoothUsers = [[NSMutableDictionary alloc] init];
        self.lastReported = [[NSMutableDictionary alloc] init];
        self.mixpanel = [Mixpanel sharedInstance];
        // Set up the allowed beacon regions
        // What are the uuids?
        self.regionUUIDS = @[      @"DDE6C09F-345B-4FC2-80C1-C27977EB35A6",
                                   @"E20DF868-0B06-4361-85DE-EE57A57CAA5F",
                                   @"BCEA644E-3B51-4E6C-8B72-ED204EC5FA36",
                                   @"9CA603ED-7A5D-4F2F-BBB6-70AAC0050C7E",
                                   @"A97C54AA-A7B8-4AED-8542-12BCF12D97DD",
                                   @"6B6ABB05-46D1-4466-BCAC-D6F70CBE1348",
                                   @"F1229A67-42EB-40CB-83F0-32385074F705",
                                   @"259CB377-2CB2-476B-B59A-326CB3315B47",
                                   @"C0A151D2-EC1D-4547-87D8-4C73E94252D3",
                                   @"D64BB228-C3C1-4A16-A1A5-C84785DAAD7B",
                                   @"2DC4D09C-5846-463D-9FFC-BDFE414417BF",
                                   @"5AAFB50C-F795-4818-9433-7197C517B1E0",
                                   @"155E22AE-AE03-4A65-B665-71D9E417146A",
                                   @"19D0C85F-B85E-4DE1-9449-498F62E443FD",
                                   @"554EBF21-D361-41F0-8B93-34E40ABB090B",
                                   @"B8F2B4F6-2771-4B05-BB8B-CBA06A08CC74",
                                   @"43AF147A-2EC5-4357-AD56-AB36B145C2F5",
                                   @"A7CF1269-E65C-4BED-9395-183761DE02DB",
                                   @"9C9FA6DD-B314-429E-A587-37EAA0C5D6B7"];
        // Setup the firebase
        [self initFirebase:firebaseURL];
        // Create the identity iBeacon
        [self initIdentityBeacon:userID];
        // Start off NOT flipping between identity beacon / chirping beacon
        self.currentlyChirping = NO;
        // Start off with a broadcast mode of 0
        self.broadcastMode = 0;
        // Start flipping between the identity beacon and BLE
        [self startFlipping];
        // Chirp another beacona  few times to wake up other users
        [self chirpBeacon];
        // Start the timer to filter the users
        [self startFilterTimer];
        // Start a repeating timer to prune the in-range users, every 10 seconds
//        [NSTimer scheduledTimerWithTimeInterval:10.0 target:self selector:@selector(pruneUsers) userInfo:nil repeats:YES];
        // Start a repeating timer to broadcast as an iBeacon, every 30 seconds
        // Listen for chirpBeacon events
        [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(chirpBeacon) name:kTransponderTriggerChirpBeacon object:nil];
        // Listen for app sleep events
        [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(appWillEnterForeground) name:UIApplicationDidBecomeActiveNotification object:nil];
        // Listen for app wakeup events
        [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(appWillEnterBackground) name:UIApplicationWillResignActiveNotification object:nil];
    }
    return self;
}

- (void)pruneUsers
{
    // Only do this if you're in the foreground
    UIApplication *application = [UIApplication sharedApplication];
    
    if (application.applicationState == UIApplicationStateActive) {
        
        if (DEBUG_USERS) NSLog(@"Pruning BLE users!");
        
        // WHATTIMEISITRIGHTNOW.COM
        NSDate *now = [[NSDate alloc] init];
        // Check every user
        for(NSString *userBeaconKey in [self.bluetoothUsers.allKeys copy])
        {
            NSMutableDictionary *userBeacon = [self.bluetoothUsers objectForKey:userBeaconKey];
            // How long ago was this?
            float lastSeen = [now timeIntervalSinceDate:[userBeacon objectForKey:@"lastSeen"]];
            if (DEBUG_USERS) NSLog(@"time interval for %@ -> %f",[userBeacon objectForKey:@"earshotID"],lastSeen);
            // If it's longer than 20 seconds, they're probs gone
            if (lastSeen > TIMEOUT) {
                if (DEBUG_USERS) NSLog(@"Removing user: %@",userBeacon);
                // Remove from earshotUsers, if it's actually in there
    //            if ([userBeacon objectForKey:@"earshotID"] != [NSNull null]) {
    //                [self removeUser:[userBeacon objectForKey:@"earshotID"]];
    //            }
                // Remove from bluetooth users
                [self.bluetoothUsers removeObjectForKey:userBeaconKey];
            } else {
                if (DEBUG_USERS) NSLog(@"Not removing user: %@",userBeacon);
            }
        }
    } else {
        if (DEBUG_USERS) NSLog(@"Not pruning BLE users - app is in the background");
    }
    
}

- (void)initFirebase:(NSString *)baseURL
{
    self.earshotUsers = [[NSMutableDictionary alloc] init];
    self.rootRef = [[Firebase alloc] initWithUrl:baseURL];
    self.earshotUsersRef = [[[self.rootRef childByAppendingPath:@"users"] childByAppendingPath:self.earshotID] childByAppendingPath:@"tracking"];
    [self.earshotUsersRef observeEventType:FEventTypeValue withBlock:^(FDataSnapshot *snapshot)
    {
        // Update the locally-stored earshotUsers array
        NSLog(@"Got data from firebase");
        NSLog(@"%@",snapshot.value);
        if (snapshot.value != [NSNull null]){
            self.earshotUsers = [NSMutableDictionary dictionaryWithDictionary:snapshot.value];
        } else
        {
            self.earshotUsers = [[NSMutableDictionary alloc] init];
            self.lastReported = [[NSMutableDictionary alloc] init];
        }
        // Filter the users based on timeout
        [self filterFirebaseUsers];
    }];
}

- (void)filterFirebaseUsers
{
    if (DEBUG_USERS) NSLog(@"Filtering firebase users with actuallyRemove = %d",self.actuallyRemove);
    // Store the current time
    NSDate *currentDate = [NSDate date];
    // Track whether a user to remove was found
    BOOL removeUserInTheFuture = NO;
    for (NSString *userKey in self.earshotUsers) {
        // If the timeout is too old, clear it out
        NSNumber *timestampNumber = [self.earshotUsers objectForKey:userKey];
        // Protect against weird values here
        if ([timestampNumber isKindOfClass:[NSNumber class]]) {
            long timestamp = [timestampNumber longValue];
            
            NSDate *beforeDate = [[NSDate alloc] initWithTimeIntervalSince1970:timestamp];
            
            NSTimeInterval interval = [currentDate timeIntervalSinceDate:beforeDate];
            
            NSLog(@"Long filter timeout for user %@ --> %f",userKey,interval);
            
            if (interval > TIMEOUT)
            {
                NSLog(@"Lost user %@ - has been too long: %f",userKey,interval);
                if (self.actuallyRemove) {
                    // Remove the user
                    [self removeUser:userKey];
                } else{
                    // Remove this user the next time through
                    removeUserInTheFuture = YES;
                }
                
            }
        } else {
            // There's a weird value here
            [self removeUser:userKey];
        }
    }
    
    // If we just removed stuff, set actually remove back to NO for the regularly scheduled program
    if (self.actuallyRemove) {
        self.actuallyRemove = NO;
    }
    
    // If we found a user to remove, then set an interval for a few seconds from now and set actually remove to true
    if (removeUserInTheFuture) {
        // Chirp the beacon to see if you can get dem users back.
        [self chirpBeacon];
        // set actually remove for the next run through
        self.actuallyRemove = YES;
        // Call this again in a couple of seconds, at which point the user will be actually removed
        [self performSelector:@selector(filterFirebaseUsers) withObject:nil afterDelay:10.0];
    }
}

- (void)startFilterTimer
{
    if (self.filterTimer) {
        [self.filterTimer invalidate];
    }
    self.filterTimer = [NSTimer timerWithTimeInterval:TIMEOUT target:self selector:@selector(filterFirebaseUsers) userInfo:nil repeats:YES];
    [[NSRunLoop mainRunLoop] addTimer:self.filterTimer forMode:NSDefaultRunLoopMode];
}

// Takes in a bluetooth or iBeacon user and adds it to earshotUsers
- (void)addUser:(NSString *)userID
{
//    NSLog(@"Adding user to firebase: %@",userID);
//    // Get the rounded date/time
//    uint rounded = [self roundTime:[[NSDate date] timeIntervalSince1970]];
//    // Add the user for yourself
//    [[self.earshotUsersRef childByAppendingPath:userID] setValue:[[NSNumber alloc] initWithInt:rounded]];
//    // Add yourself for the user
//    [[[[[self.rootRef childByAppendingPath:@"users"] childByAppendingPath:userID] childByAppendingPath:@"tracking"] childByAppendingPath:self.earshotID] setValue:[[NSNumber alloc] initWithInt:rounded]];
//    [self.lastReported setObject:[[NSNumber alloc] initWithDouble:now] forKey:userID];
//    NSLog(@"Rounded time is %d",rounded);
    uint now = [[NSDate date] timeIntervalSince1970];
    // Make sure it's not the time we already have
    NSNumber *last = [self.lastReported objectForKey:userID];
    uint then = [last intValue];
//    NSLog(@"Time difference for user %@ is %u",userID,(now - then));
    uint howLong = now - then;
    if (howLong > REPORTING_INTERVAL){
        if(DEBUG_USERS) NSLog(@"Adding/updating user on firebase: %@",userID);
        // Add the user for yourself
        [[self.earshotUsersRef childByAppendingPath:userID] setValue:[[NSNumber alloc] initWithInt:now]];
        // Add yourself for the user
        [[[[[self.rootRef childByAppendingPath:@"users"] childByAppendingPath:userID] childByAppendingPath:@"tracking"] childByAppendingPath:self.earshotID] setValue:[[NSNumber alloc] initWithInt:now]];
        [self.lastReported setObject:[[NSNumber alloc] initWithInt:now] forKey:userID];
    } else {
        if(DEBUG_TIMEOUTS) NSLog(@"Timeout not long enough, doing nothing.");
    }
}

- (uint)roundTime:(NSTimeInterval)time
{
    // Round to the nearest 5 seconds
    //    NSLog(@"time = %f", time);
    double rounded = REPORTING_INTERVAL * floor((time/REPORTING_INTERVAL)+0.5);
    return rounded;
}

- (void)removeUser:(NSString *)userID
{
#warning not sure this is the right way to handle removing users...
#warning - add feature to not remove this user if it exists elsewhere in the bluetooth array
    // Only do this if you're in the foreground
    UIApplication *application = [UIApplication sharedApplication];
    
    if (application.applicationState == UIApplicationStateActive) {
        // Remove the user for yourself
        [[self.earshotUsersRef childByAppendingPath:userID] removeValue];
    }
    // Remove yourself for the user
//    [[[[[self.rootRef childByAppendingPath:@"users"] childByAppendingPath:userID] childByAppendingPath:@"tracking"] childByAppendingPath:self.earshotID] removeValue];
}



# pragma mark - FOREGROUND vs BACKGROUND modes
- (void)appWillEnterForeground
{
    NSLog(@"Transponder -- App is entering foreground");
    // Start ranging beacons in Region 19
    [self.locationManager startRangingBeaconsInRegion:self.rangingRegion];
    // Start flipping between an iBeacon and a BLE peripheral
    // If you aren't already
    if (!self.isFlipping) [self startFlipping];
    // Chirp the discovery iBeacon for a few seconds
    [self chirpBeacon];
    // Update the date we use for the notification timeout
    self.lastNotificationEvent = [NSDate date];
}

- (void)appWillEnterBackground
{
    NSLog(@"Transponder -- App is entering background");
    // Stop chirping as a beacon
    [self stopChirping];
    // Start advertising only as a BLE peripheral
    [self stopFlipping];
    // Stop ranging beacons
    [self stopRanging];
    // Pause the filter timer
//    self.filterTimer
}

# pragma mark - push notifications
- (void)wakeup
{
    // Only do this if the app is in the background
    //    NSLog(@"Current app state is %ld",[[UIApplication sharedApplication] applicationState]);
    UIApplication *app = [UIApplication sharedApplication];
    if ([app applicationState] == UIApplicationStateBackground) {
        NSLog(@"App is in the background!");
        // If there aren't any user notifications, add a new earshot notification
        NSArray *notificationArray = [app scheduledLocalNotifications];
        NSLog(@"notificationArray count is %d", [notificationArray count]);
        //        if ([notificationArray count] != 0) {
        //            // Delete all the existing notifications
        //            NSLog(@"Deleting local notifications");
        //            [app cancelAllLocalNotifications];
        ////            for (UILocalNotification *toDelete in notificationArray) {
        ////                app cancelAllLocalNotifications
        ////            }
        //        }
        //        [app cancelAllLocalNotifications];
        // Add a new notifications
        UILocalNotification *notice = [[UILocalNotification alloc] init];
        notice.alertBody = [NSString stringWithFormat:@"Earshot users nearby."];
        notice.alertAction = @"Converse";
        [app scheduleLocalNotification:notice];
    } else
    {
        NSLog(@"App is not in the background - ignoring wakeup call.");
    }
    // If there aren't any user notifications, add a new earshot notification
    // TODO - check if there are already notifications
    // If there are currently notifications, add this one and then delete it right away
}

# pragma mark - core bluetooth

- (void)startDetecting
{
    // Setup beacon monitoring for regions
    [self setupBeaconRegions];
    // Listen for bluetooth LE
    [self startDetectingTransponders];
}

- (void)startBroadcasting
{
    
    [self startBluetoothBroadcast];
    
}

- (void)startDetectingTransponders
{
    if (!self.centralManager)
        NSLog(@"New central created");
    self.centralManager = [[CBCentralManager alloc] initWithDelegate:self queue:nil];
    
    // Uncomment this timer if you need to report ranges in a timer
    //    detectorTimer = [NSTimer scheduledTimerWithTimeInterval:UPDATE_INTERVAL target:self
    //                                                   selector:@selector(reportRanges:) userInfo:nil repeats:YES];
}

- (void)startBluetoothBroadcast
{
    // start broadcasting if it's stopped
    if (!self.peripheralManager) {
        self.peripheralManager = [[CBPeripheralManager alloc] initWithDelegate:self queue:nil];
    }
}

- (void)startScanning
{
    
    NSDictionary *scanOptions = @{CBCentralManagerScanOptionAllowDuplicatesKey:@(YES)};
    
    [self.centralManager scanForPeripheralsWithServices:@[self.identifier] options:scanOptions];
    _isDetecting = YES;
    if (DEBUG_CENTRAL) NSLog(@"Scanning!");
}

- (void)startAdvertising
{
    
    self.bluetoothAdvertisingData = @{CBAdvertisementDataServiceUUIDsKey:@[self.identifier], CBAdvertisementDataLocalNameKey:self.earshotID};
    
    // Start advertising over BLE
    [self.peripheralManager startAdvertising:self.bluetoothAdvertisingData];
}


#pragma mark - CBCentralManagerDelegate
- (void)centralManager:(CBCentralManager *)central didDiscoverPeripheral:(CBPeripheral *)peripheral
     advertisementData:(NSDictionary *)advertisementData RSSI:(NSNumber *)RSSI
{
    if (DEBUG_CENTRAL) {
        NSLog(@"did discover peripheral: %@, data: %@, %1.2f", [peripheral.identifier UUIDString], advertisementData, [RSSI floatValue]);
        
        CBUUID *uuid = [advertisementData[CBAdvertisementDataServiceUUIDsKey] firstObject];
        NSLog(@"service uuid: %@", [uuid representativeString]);
    }
    
    // Create a user if there isn't one
    NSMutableDictionary *existingUser = [self.bluetoothUsers objectForKey:[peripheral.identifier UUIDString]];
    if ([existingUser count] == 0) {
        // No user yet, make one
        NSMutableDictionary *newUser = [[NSMutableDictionary alloc] initWithDictionary:@{@"lastSeen": [[NSDate alloc] init],
                                                                                         @"earshotID": [NSNull null]}];
        // Insert
        [self.bluetoothUsers setObject:newUser forKey:[peripheral.identifier UUIDString]];
        
        // Alias
        existingUser = newUser;
        
        // Send a local notification to tell the user we discovered a device
        [self sendDiscoverNotification];
        
        // Send the new (anonymous) user notification
//        [[NSNotificationCenter defaultCenter] postNotificationName:kTransponderEventNewUserDiscovered object:self userInfo:@{@"user":existingUser}];
        
        // Chirp the beacon!
        [self chirpBeacon];
    } else{
        // Update the time last seen
        [existingUser setObject:[[NSDate alloc] init] forKey:@"lastSeen"];
    }
    
    // Update local name if included in advertisement
    NSString *localName = [advertisementData valueForKey:@"kCBAdvDataLocalName"];
    if (localName){
        [existingUser setValue:localName forKey:@"earshotID"];
        // Add to earshot users
    }
    
    // If it has a local name (whether just set or actively being broadcast), call addUser
    NSString *userID = [existingUser objectForKey:@"earshotID"];
    if (userID && userID != (NSString*)[NSNull null])
    {
//        NSLog(@"%@ addUser %@ <centralManager:didDiscoverPeripheral:advertisementData:RSSI:>", [FCUser owner].id, userID);
        [self addUser:userID];

    }
    
    if (DEBUG_CENTRAL) NSLog(@"%@",self.bluetoothUsers);
    
    // Notify peeps that an earshot user was discovered
        [[NSNotificationCenter defaultCenter] postNotificationName:kTransponderEventEarshotUserDiscovered
                                                            object:self
                                                          userInfo:@{@"user":existingUser,
                                                                     @"identifiedUsers":self.earshotUsers,
                                                                     @"bluetoothUsers":self.bluetoothUsers}];
    
}

- (void)centralManagerDidUpdateState:(CBCentralManager *)central
{
    if (DEBUG_CENTRAL) NSLog(@"-- central state changed: %@", self.centralManager.stateString);
    
    // Emit the state, if state != unknown
    if (central.state)
    {
        self.bluetoothWasTried = YES;
        [self emitBluetoothState];
    }
    // If powered on, start scanning
    if (central.state == CBCentralManagerStatePoweredOn)
    {
        [self startScanning];
    }
    
}

#pragma mark - CBPeripheralManagerDelegate
- (void)peripheralManagerDidUpdateState:(CBPeripheralManager *)peripheral
{
    if (DEBUG_PERIPHERAL) NSLog(@"-- peripheral state changed: %@", peripheral.stateString);
    // Emit the state if stat is known.
    if (peripheral.state)
    {
        self.bluetoothWasTried = YES;
        [self emitBluetoothState];
    }
    // If powered on, start scanning
    if (peripheral.state == CBPeripheralManagerStatePoweredOn)
    {
        [self startAdvertising];
    }
}

- (void)peripheralManagerDidStartAdvertising:(CBPeripheralManager *)peripheral error:(NSError *)error
{
    if (DEBUG_PERIPHERAL)
    {
        if (error)
            NSLog(@"error starting advertising: %@", [error localizedDescription]);
        else
            NSLog(@"did start advertising!");
    }
}


#pragma mark - iBeacon broadcasting

// Setup the beacon responsible for communicating the user's earshot ID
- (void)initIdentityBeacon:(NSString *)userID
{
    
    // Convert the userID into a major and minor value to transmit
    NSLog(@"Decomposing UUID %@",userID);
    uint16_t major, minor;
    esDecomposeIdToMajorMinor([userID intValue], &major, &minor);
    NSLog(@"Got major: %hu and minor:%hu",major,minor);
    
    CLBeaconRegion *identityBeaconRegion = [[CLBeaconRegion alloc] initWithProximityUUID:[[NSUUID alloc] initWithUUIDString: IDENTITY_BEACON_UUID]
                                                                         major:major
                                                                         minor:minor
                                                                    identifier:[NSString stringWithFormat:@"Broadcast region %d",19]];
    self.identityBeaconData = [identityBeaconRegion peripheralDataWithMeasuredPower:nil];
    
}


// Below lie the functions for interacting with iBeacon
- (void)chirpBeacon
{
    NSLog(@"chirpBeacon");
    UIApplication *application = [UIApplication sharedApplication];
    if ([application applicationState] == UIApplicationStateActive) {
        if (DEBUG_BEACON) NSLog(@"Attempting to create new beacon!");
        if (DEBUG_BEACON) NSLog(@"Current regions: %@",self.regions);

        // Don't do anything if you're already chirping
        if (self.currentlyChirping == YES) {
            if (DEBUG_BEACON) NSLog(@"Currently chirping, creation CANCELLED");
        } else{
            // Build an array to sort
            NSMutableArray *fucker = [[NSMutableArray alloc] init];

            for (NSNumber *isInside in self.regions) {
                NSDictionary *bullshit = @{@"some": [[NSDate alloc] init],@"isInside":isInside};
                [fucker addObject:bullshit];
            }

            // Preticate - filter self.regions
            NSPredicate *predicate = [NSPredicate predicateWithFormat:@"(SELF.isInside == %@)", @NO];
            NSArray *availableNos = [fucker filteredArrayUsingPredicate:predicate];
            if ([availableNos count])
            {
                NSInteger randomChoice = esRandomNumberIn(0, (int)[availableNos count]);
                id aNo = [availableNos objectAtIndex:randomChoice];

                NSUInteger chosenIndex = [availableNos indexOfObject:aNo];
                
                NSString *regionUUID = [self.regionUUIDS objectAtIndex:chosenIndex];

                if (DEBUG_BEACON) NSLog(@"Creating a new chirping beacon broadcast region in slot number %lu -> %@",(unsigned long)chosenIndex, regionUUID);
                self.chirpBeaconRegion = [[CLBeaconRegion alloc] initWithProximityUUID:[[NSUUID alloc] initWithUUIDString: regionUUID]
                                                                                     major:0
                                                                                     minor:0
                                                                                identifier:[NSString stringWithFormat:@"Broadcast region %@",regionUUID]];
                self.chirpBeaconData = [self.chirpBeaconRegion peripheralDataWithMeasuredPower:nil];

                // Start chirping
                self.currentlyChirping = YES;
                // Stop chirping after 10 seconds
                [self performSelector:@selector(stopChirping) withObject:nil afterDelay:CHIRP_LENGTH];
                // This region should be off-limits for a bit
                [self disallowRegion:chosenIndex];
            } else
            {
                int timeoutSeconds = 10;
                NSLog(@"Couldn't find an open region, trying again in %i seconds.",timeoutSeconds);
                dispatch_after(dispatch_time(DISPATCH_TIME_NOW,  timeoutSeconds*1000* NSEC_PER_MSEC), dispatch_get_main_queue(),                ^{
                    // note - it's okay if this fires in the background
                    // this only sets the beacon data and the currentlyChirping flag, but it will be overridden by the flippingBreaker flag if the app is in the background
                    [self chirpBeacon];
                });
            }
        }
    } else{
        if (DEBUG_BEACON) NSLog(@"Application isn't in the foreground - not creating a beacon");
    }
    
}

- (void)stopChirping
{
    if (DEBUG_BEACON) NSLog(@"Stopping chirping!");
    self.currentlyChirping = NO;
}

- (void)disallowRegion:(NSUInteger)regionNumber
{
    if (DEBUG_BEACON) NSLog(@"Disallowing region %lu",(unsigned long)regionNumber);
    [self.regions replaceObjectAtIndex:regionNumber withObject:@YES];
    // In a while, re-allow the region
    [self performSelector:@selector(allowRegion:) withObject:[NSNumber numberWithInteger:regionNumber] afterDelay:30];
}

- (void)allowRegion:(NSNumber *)regionNumber
{
    if (DEBUG_BEACON) NSLog(@"Re-enabling region %@",regionNumber);
    [self.regions replaceObjectAtIndex:[regionNumber integerValue] withObject:@NO];
}

- (void)startFlipping
{
    self.isFlipping = YES;
    self.broadcastMode = 0;
    self.flippingBreaker = NO;
    [self flipState];
}

- (void)stopFlipping
{
    // Set the flag
    self.isFlipping = NO;
    // Stop flipState from continuing to flip
    self.flippingBreaker = YES;
    // Reset the bluetooth right now to broadcast BLE
    if (DEBUG_BEACON) NSLog(@"-- broadcasting as BLE");
    [self resetBluetooth];
    // Just in case, reset the bluetooth stack again in a few seconds (to miss any timeouts in the meantime)
//    [self performSelector:@selector(resetBluetooth) withObject:nil afterDelay:1.5];
    
}

- (void)flipState
{
    if (IS_RUNNING_ON_SIMULATOR)
        return;
    
    // There are three states:
    // State 0: Broadcasting using normal BLE
    // State 1: Broadcasting as an iBeacon on a wakeup region (0-18)
    // State 2: Broadcasting as an iBeacon as this device on Region 19
    
    // ^ optional, only available is self.discoveryBeacon == @YES
    
    if (!self.flippingBreaker) {
        // Increment the broadcast mode
        self.broadcastMode++;
        
        // Reset it if necessary
        if (self.broadcastMode > 2) {
            self.broadcastMode = 0;
        }
        
        // Check the broadcast mode
        switch (self.broadcastMode) {
            case 0:
                // Start broadcasting using normal bluetooth low energy
                if (DEBUG_BEACON) NSLog(@"-- broadcasting as BLE");
                [self resetBluetooth];
                break;
            case 1:
                // Is this flag set?
                if (self.currentlyChirping == YES) {
                    // Start broadcasting as a wakeup region
                    if (DEBUG_BEACON) NSLog(@"-- broadcasting as chirp iBeacon");
                    [self startBeacon:self.chirpBeaconData];
                } else{
                    // Broadcast as normal BLE
                    if (DEBUG_BEACON) NSLog(@"-- broadcasting as BLE (no chirp fallback)");
                    [self resetBluetooth];
                }
                // Start broadcasting on a wakeup region
                break;
            case 2:
                // Start broadcasting as an iBeacon on identity beacon
                if (DEBUG_BEACON) NSLog(@"-- broadcasting as identity iBeacon");
                [self startBeacon:self.identityBeaconData];
                break;
            default:
                break;
        }
        
        // Do this again after a while
        [self performSelector:@selector(flipState) withObject:nil afterDelay:1.0];
    }
    
}

- (void)resetBluetooth
{
    // Stop what you're doing and advertise with bluetooth
    [self.peripheralManager stopAdvertising];
    [self.peripheralManager startAdvertising:self.bluetoothAdvertisingData];
}

// Start broadcasting as an iBeacon. Works with either the identity or wakeup beacon data
- (void)startBeacon:(NSDictionary *)beaconData
{
    // Stop what you're doing and advertise as a beacon
    [self.peripheralManager stopAdvertising];
    // Broadcast
    [self.peripheralManager startAdvertising:beaconData];
}


# pragma mark - iBeacon discovery
// K this shit gets crazy so stay with me. We're going to listen for "chirps" (broadcasts under 10 seconds for the purpose of wakeup) on regions 0-18. Region 19 is special. Region 19 is where we will actually range beacons. Therefore a phone can chirp on region 10, and ranging will start on region 19.
- (void)setupBeaconRegions
{
    NSLog(@"Setting up beacon regions...");
    // Make the location manager
    self.locationManager = [[CLLocationManager alloc] init];
    // Set the delegate
    self.locationManager.delegate = self;
    
//    BOOL what = [CLLocationManager isMonitoringAvailableForClass:[CLBeacon class]];
//    int [CLLocationManager] auth
    // Init the region tracker
    self.regions = [[NSMutableArray alloc] init];
    
//    for (CLRegion *monitored in [self.locationManager monitoredRegions]){
//        [self.locationManager stopMonitoringForRegion:monitored];
//    }
    
    // Regions 0-18 are available for wakeup chirps
    for (int major=0; major< MAX_BEACON; major++) {
        NSString *regionUUID = [self.regionUUIDS objectAtIndex:major];
        if (DEBUG_BEACON) NSLog(@"Starting to monitor for region %@",regionUUID);
        // Start outside the region
        [self.regions addObject:@NO];
        // Create a region with this minor
        CLBeaconRegion *region = [[CLBeaconRegion alloc] initWithProximityUUID:[[NSUUID alloc] initWithUUIDString: regionUUID]
                                                                    identifier:[NSString stringWithFormat:@"Listen region %@",regionUUID]];
        // Wake up the app when you enter this region
//        region.notifyEntryStateOnDisplay = YES;
        region.notifyOnEntry = YES;
        region.notifyOnExit = YES;
        // Start monitoring via location manager
        [self.locationManager startMonitoringForRegion:region];
        // OPTIONAL - if we need to initialize this region with an inside/outside state, do it here
        [self.locationManager requestStateForRegion:region];
    }
    
    
    // Region 19 is available for ranging - totally separate
    // This might look like duplicate code, but it's way easier to understand if this gets set up as a separate region
    if (DEBUG_BEACON) NSLog(@"Setting up the mystical region %@",IDENTITY_BEACON_UUID);
    self.rangingRegion = [[CLBeaconRegion alloc] initWithProximityUUID:[[NSUUID alloc] initWithUUIDString: IDENTITY_BEACON_UUID]
                                                            identifier:[NSString stringWithFormat:@"Identity region %@",IDENTITY_BEACON_UUID]];
//    self.rangingRegion = [[CLBeaconRegion alloc] initWithProximityUUID:[[NSUUID alloc] initWithUUIDString: IBEACON_UUID]
//                                                            identifier:[NSString stringWithFormat:@"Minor mod region:%d",19]];
    // Why not also wake up when we enter this region
//    self.rangingRegion.notifyEntryStateOnDisplay = YES;
    self.rangingRegion.notifyOnEntry = YES;
    self.rangingRegion.notifyOnExit = YES;
    // Start monitoring via location manager
    [self.locationManager startMonitoringForRegion:self.rangingRegion];
    // OPTIONAL - if we need to initialize this region with an inside/outside state, do it here
    [self.locationManager requestStateForRegion:self.rangingRegion];
    // Start ranging for beacons in this region
    [self.locationManager startRangingBeaconsInRegion:self.rangingRegion];
    
    
}

- (void)stopRanging
{
    [self.locationManager stopRangingBeaconsInRegion:self.rangingRegion];
}

#pragma mark - CLLocationManagerDelegate
//- (void)locationManager:(CLLocationManager *)manager didEnterRegion:(CLRegion *)region
//{
//    NSLog(@"AHH DID EENTER REGION");
//}

- (void)locationManager:(CLLocationManager *)manager didChangeAuthorizationStatus:(CLAuthorizationStatus)status
{
    // Emit that shit, unless underetmined state.
    if (status == kCLAuthorizationStatusNotDetermined)
    {
        return;
    }
    self.coreLocationWasTried = YES;
    [self emitBluetoothState];
}

- (void)locationManager:(CLLocationManager *)manager didDetermineState:(CLRegionState)state forRegion:(CLBeaconRegion *)region
{
    // What region?
    NSUUID *uuidVal = [region proximityUUID];
    NSString *uuid = [uuidVal UUIDString];
    NSUInteger indexOfThisRegion = [self.regionUUIDS indexOfObject:uuid];
//    NSLog(@"Got state %ld for region %lu", state, (unsigned long)indexOfThisRegion);
//    NSLog(@"Got state %li for region %@ : %@",state,minor,region);
    switch (state) {
        case CLRegionStateInside:
            // Update the beacon regions dictionary if it's not Region 19
            if (![uuid  isEqual: IDENTITY_BEACON_UUID]) {
                if (indexOfThisRegion != NSNotFound){
                    [self.regions replaceObjectAtIndex:indexOfThisRegion withObject:@YES];
                }
            }
            // Regardless, start ranging on Region 19
            [self.locationManager startRangingBeaconsInRegion:self.rangingRegion];
            // Kill any existing timeouts
            if (self.rangingTimeout) {
                [self.rangingTimeout invalidate];
            }
            // If we're in the background, don't do this forever
            if ([[UIApplication sharedApplication] applicationState] != UIApplicationStateActive) {
                // Make a new timer
                self.rangingTimeout = [NSTimer timerWithTimeInterval:BEACON_TIMEOUT target:self selector:@selector(stopRanging) userInfo:nil repeats:NO];
                // Actually start the timer
                [[NSRunLoop mainRunLoop] addTimer:self.rangingTimeout forMode:NSDefaultRunLoopMode];
            }
            
            // Send a local notification to tell the user we discovered a device
            [self sendDiscoverNotification];
            
            if (DEBUG_BEACON){
                NSLog(@"--- Entered region: %@", region);
//                UILocalNotification *notice = [[UILocalNotification alloc] init];
//                notice.alertBody = [NSString stringWithFormat:@"Entered region %@",uuid];
//                notice.alertAction = @"Open";
//                [[UIApplication sharedApplication] presentLocalNotificationNow:notice];
                NSLog(@"%@",self.regions);
            }
            break;
        case CLRegionStateOutside:
            if (![uuid  isEqual: IDENTITY_BEACON_UUID]) {
                if (indexOfThisRegion != NSNotFound){
                    [self.regions replaceObjectAtIndex:indexOfThisRegion withObject:@NO];
                }
            }
            if (DEBUG_BEACON){
                NSLog(@"--- Exited region: %@", region);
//                UILocalNotification *notice = [[UILocalNotification alloc] init];
//                notice.alertBody = [NSString stringWithFormat:@"Exited region %@",major];
//                notice.alertAction = @"Open";
//                [[UIApplication sharedApplication] scheduleLocalNotification:notice];
                NSLog(@"%@",self.regions);
            }
            break;
        case CLRegionStateUnknown:
            if (DEBUG_BEACON) NSLog(@"Region %@ in unknown state - doing nothing...",uuid);
            break;
        default:
            NSLog(@"This is never supposed to happen.");
            break;
    }
    
    // Doing this for some reason scans forever...
    //    [self.locationManager startRangingBeaconsInRegion:self.rangingRegion];
}

-(void)locationManager:(CLLocationManager *)manager didRangeBeacons:(NSArray *)beacons inRegion:(CLBeaconRegion *)region
{
    if ([beacons count] != 0){
        if (DEBUG_BEACON) NSLog(@"Ranged beacons from identity region!");
        if (DEBUG_BEACON) NSLog(@"%@",beacons);
    }
    for (CLBeacon *beacon in beacons) {
//        NSString *userID = [NSString stringWithFormat:@"%@",beacon.minor];
        
        uint32_t recomposed;
        esRecomposeMajorMinorToId([beacon.major intValue], [beacon.minor intValue], &recomposed);
//        NSLog(@"Recomposed major: %@ and minor:%@   ->   %d",beacon.major,beacon.minor,recomposed);
        
        NSString *userID = [NSString stringWithFormat:@"%u",recomposed];
        
        NSLog(@"%@ addUser %@ <locationManager:didRangeBeacons:inRegion:>", [FCUser owner].id, userID);
        [self addUser:userID];
    }
}

- (ESTransponderStackState)stackIsRunning
{
    if (self.coreLocationWasTried && self.bluetoothWasTried)
    {
        
        if (self.peripheralManager.state == CBPeripheralManagerStatePoweredOn &&
            self.centralManager.state == CBPeripheralManagerStatePoweredOn &&
            [CLLocationManager authorizationStatus] == kCLAuthorizationStatusAuthorized)
        {
            return ESTransponderStackStateActive;
        } else
        {
            return ESTransponderStackStateDisabled;
        }
    }
    return ESTransponderStackStateUnknown;
}

- (void)emitBluetoothState
{
    if (self.coreLocationWasTried && self.bluetoothWasTried)
    {
        if (self.peripheralManager.state == CBPeripheralManagerStatePoweredOn &&
            self.centralManager.state == CBPeripheralManagerStatePoweredOn &&
            [CLLocationManager authorizationStatus] == kCLAuthorizationStatusAuthorized)
        {
            [[NSNotificationCenter defaultCenter] postNotificationName:kTransponderEventTransponderEnabled object:nil];
        } else
        {
            [[NSNotificationCenter defaultCenter] postNotificationName:kTransponderEventTransponderDisabled object:nil];
        }
    }
}

-(CLLocation*)getLocation
{
    return self.locationManager.location;
}

- (void)locationManager:(CLLocationManager *)manager monitoringDidFailForRegion:(CLRegion *)region withError:(NSError *)error
{
    NSLog(@"Region monitoring failed with error: %@", [error localizedDescription]);
    
}

- (void)locationManager:(CLLocationManager *)manager didFailWithError:(NSError *)error
{
    NSLog(@"ERROR - %@",error);
}

- (void)locationManager:(CLLocationManager *)manager didStartMonitoringForRegion:(CLRegion *)region
{
    NSLog(@"Started monitoring for region: %@",region);
}

# pragma mark - local notifications
- (void)sendDiscoverNotification

{
    // Only do this if the app is in the background
    //    NSLog(@"Current app state is %ld",[[UIApplication sharedApplication] applicationState]);
    UIApplication *app = [UIApplication sharedApplication];
    if ([app applicationState] == UIApplicationStateBackground) {
        // If there aren't any existing discover notifications
        NSArray *notificationArray = [app scheduledLocalNotifications];
        if ([notificationArray count] == 0) {
            // If it's been more than 20 minutes since the last notification OR app open
            NSDate *currentDate = [NSDate date];
            NSTimeInterval howLong = [currentDate timeIntervalSinceDate:self.lastNotificationEvent];
            if (howLong > NOTIFICATION_TIMEOUT) {
                NSLog(@"Sending a local discover notification!");
                // Cancel all of the existing notifications
                [app cancelAllLocalNotifications];
                // Add a new notification
                UILocalNotification *notice = [[UILocalNotification alloc] init];
                notice.alertBody = [NSString stringWithFormat:@"There is a new Earshot user nearby - say hi!"];
                notice.alertAction = @"Converse";
                [app scheduleLocalNotification:notice];
                // Update the date we use for the notification timeout
                self.lastNotificationEvent = [NSDate date];
                // Track this via mixpanel
                [self.mixpanel track:@"Notified of user nearby" properties:@{}];
            } else{
                NSLog(@"It has only been %f seconds of the %f second notification timeout - ignoring notification call.", howLong, NOTIFICATION_TIMEOUT);
            }
        } else {
            NSLog(@"There is already an existing discover notification - ignoring notification call");
        }
        
    } else
    {
        NSLog(@"App is not in the background - ignoring notication call.");
    }
}

@end
