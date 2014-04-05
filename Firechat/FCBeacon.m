//
//  FCBeacon.m
//  Firechat
//
//  Created by Alonso Holmes on 1/12/14.
//  Copyright (c) 2014 Buildco. All rights reserved.
//

#import "FCBeacon.h"
#define IS_RUNNING_ON_SIMULATOR 1

@interface FCBeacon ()
@property NSUUID *uuid;
@property CLBeaconRegion *region;
@end

@implementation FCBeacon
@synthesize peripheralManagerIsRunning;

- (id)init
{
    self = [super init];
    if (self) {
        
    }
    return self;
}

- (id)initWithMajor:(NSNumber *)major andMinor:(NSNumber *)minor
{
    self = [super init];
    if (self) {
        // Set up uuid
        self.major = major;
        self.minor = minor;
        
        NSLog(@"Init with major %@ and minor %@",self.major,self.minor);
        
//        // Init peripheral manager
//        self.peripheralManager = [[CBPeripheralManager alloc] initWithDelegate:self
//                                                                         queue:nil
//                                                                       options:nil];
//        // Init location manager
//        self.locationManager = [[CLLocationManager alloc] init];
        
        self.uuid = [[NSUUID alloc] initWithUUIDString:@"BC43DDCC-AF0C-4A69-9E75-4CDFF8FD5F63"]; //orbiter devices
        // Haha, just kidding, "orbiter"
//        self.uuid = [[NSUUID alloc] initWithUUIDString:@"B9407F30-F5F8-466E-AFF9-25556B57FE6D"]; //estimote
        
        [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(appWentInBackground:) name:UIApplicationDidEnterBackgroundNotification object:nil];
        
    }
    return self;
}

-(void)appWentInBackground:(NSNotification*)notification
{
//    for (CLBeaconRegion *region in self.locationManager.rangedRegions)
//    {
//        [self.locationManager stopRangingBeaconsInRegion:region];
//    }
}

-(void)start
{
    
    int state = [CLLocationManager authorizationStatus];
    [self locationManager:self.locationManager didChangeAuthorizationStatus:state];
    
    self.peripheralManager = [[CBPeripheralManager alloc] initWithDelegate:self
                                                                     queue:nil
                                                                options:nil];
}

#pragma mark - Scanner
- (void) initScanner
{
    // Init location manager
    self.locationManager = [[CLLocationManager alloc] init];
    // Set delegate
    self.locationManager.delegate = self;
    // Create region
    self.region = [[CLBeaconRegion alloc] initWithProximityUUID:self.uuid identifier:@"Orbiter region"];
    // Launch app with display off when inside region
    self.region.notifyEntryStateOnDisplay = YES;
    [self.region setNotifyOnEntry:YES];
    [self.region setNotifyOnExit:YES];
    

    
    
    if ([CLLocationManager isMonitoringAvailableForClass:[CLBeaconRegion class]])
    {
        
        [self.locationManager startMonitoringForRegion:self.region];
        [self.locationManager requestStateForRegion:self.region];
        
        
        // If you want to get the state right away, this is the spot
    }
}

//-(void)peripheralManager:(CBPeripheralManager *)peripheral didChange

-(void)locationManager:(CLLocationManager *)manager didChangeAuthorizationStatus:(CLAuthorizationStatus)status
{
    // Check for supported devices
    switch ([CLLocationManager authorizationStatus])
    {
        case kCLAuthorizationStatusRestricted:
        {
            NSLog(@"kCLAuthorizationStatusRestricted");
            [self blueToothStackNeedsUserToActivateMessage];
        }
            break;
            
        case kCLAuthorizationStatusDenied:
        {
            NSLog(@"kCLAuthorizationStatusDenied");
            [self blueToothStackNeedsUserToActivateMessage];
        }
            break;
            
        case kCLAuthorizationStatusAuthorized:
        {
            NSLog(@"kCLAuthorizationStatusAuthorized");
            [self blueToothStackIsActive];
        }
            break;
            
        case kCLAuthorizationStatusNotDetermined:
        {
            NSLog(@"kCLAuthorizationStatusNotDetermined");//user has not yet said yes or no
        }
            break;
    }
}
//- (void)locationManager:(CLLocationManager *)manager didFailWithError:(NSError *)error {
//    
//    if ([error domain] == kCLErrorDomain) {
//        
//        // We handle CoreLocation-related errors here
//        switch ([error code]) {
//                // "Don't Allow" on two successive app launches is the same as saying "never allow". The user
//                // can reset this for all apps by going to Settings > General > Reset > Reset Location Warnings.
//            case kCLErrorDenied:
//            {
//                NSLog(@"kCLErrorDenied");
//            }
//                
//            case kCLErrorLocationUnknown:
//            {
//                NSLog(@"kCLErrorLocationUnknown");
//            }
//                
//            default:
//                break;
//        }
//        
//    } else {
//        // We handle all non-CoreLocation errors here
//    }
//}

- (void) checkSupport
{
if ([CLLocationManager isMonitoringAvailableForClass:[CLBeaconRegion class]])
    NSLog(@"Beacons available");
    // If you want to get the state right away, this is the spot
}

// Called when the first beacon comes within range
- (void)locationManager:(CLLocationManager *)manager didEnterRegion:(CLRegion *)region
{
    NSLog(@"Entered beacon region!");
    // Start ranging the beacons
    [_locationManager startRangingBeaconsInRegion:self.region];
}

// Called when the last beacon leaves range
- (void)locationManager:(CLLocationManager *)manager didExitRegion:(CLRegion *)region
{
    NSLog(@"Left beacon region!");
    // No need to range the beacons anymore
    [_locationManager stopRangingBeaconsInRegion:self.region];
}


// Called when a beacon is ranged
// beacons is an array. it might be empty for ~20seconds after the last beacon goes out of range


-(void)locationManager:(CLLocationManager *)manager didRangeBeacons:(NSArray *)beacons inRegion:(CLBeaconRegion *)region
{
    NSLog(@"locationManager didRangeBeacons: beacons.count = %d", beacons.count);

//    //determine if a beacon is new.
    NSMutableArray *newBeacons = [[NSMutableArray alloc] initWithCapacity:beacons.count];
    for (CLBeacon *beacon in beacons)
    {
        NSPredicate *predicate = [NSPredicate predicateWithFormat:@"( SELF.major == %@ AND self.minor == %@)", beacon.major, beacon.minor];
        id beaconFound = [[self.beacons filteredArrayUsingPredicate:predicate] lastObject];
        if (!beaconFound)
        {
            [newBeacons addObject:beacon];
        }
    }
    
    if (newBeacons.count)
    {
            NSLog(@"CLRegionStateInside");
//            UILocalNotification *localNotification = [[UILocalNotification alloc] init];
//
//            localNotification.fireDate = [NSDate date];
//            localNotification.alertBody = @"Earshot users nearby!";
//            localNotification.timeZone = [NSTimeZone defaultTimeZone];
//
//            [[UIApplication sharedApplication] scheduleLocalNotification:localNotification];
//        [[NSNotificationCenter defaultCenter] postNotificationName:@"Beacons Added" object:[NSArray arrayWithArray:newBeacons]];
    }
    
    self.beacons = beacons;
    
    [[NSNotificationCenter defaultCenter] postNotificationName:@"Beacons Updated" object:self.beacons];
    
}

// Start montoring for region
- (void)locationManager:(CLLocationManager *)manager didStartMonitoringForRegion:(CLRegion *)region
{
    NSLog(@"locationManager:didStartMonitoringForRegion:");
    [_locationManager startRangingBeaconsInRegion:self.region];
}

#pragma mark - Broadcaster

- (void) startBroadcasting
{
    
//    NSLog(@"Starting to broadcast with major %@ and minor %@",self.major,self.minor);
    
    CLBeaconRegion *region = [[CLBeaconRegion alloc] initWithProximityUUID:self.uuid
                                                                     major:[self.major unsignedIntegerValue]
                                                                     minor:[self.minor unsignedIntegerValue]
                                                                identifier:@"Orbiter beacon"];
    
    NSDictionary *beaconPeripheralData = [region peripheralDataWithMeasuredPower:nil];
    
    [_peripheralManager startAdvertising:beaconPeripheralData];
}

#pragma mark - CBPeripheralManagerDelegate

//- (void)peripheralManagerDid

-(void)peripheralManagerDidStartAdvertising:(CBPeripheralManager *)peripheral error:(NSError *)error
{
//    NSLog(@"peripheralManagerDidStartAdvertising error %@", error.localizedDescription);
}

- (void)peripheralManagerDidUpdateState:(CBPeripheralManager *)peripheral
{
    NSLog(@"DID UPDATE STATE");
    
    /*
     CBPeripheralManagerStateUnknown = 0,
     CBPeripheralManagerStateResetting,
     CBPeripheralManagerStateUnsupported,
     CBPeripheralManagerStateUnauthorized,
     CBPeripheralManagerStatePoweredOff,
     CBPeripheralManagerStatePoweredOn
     */
    NSLog(@"\n");
    switch (peripheral.state) {
        case CBPeripheralManagerStateUnknown:
        {
            NSLog(@"CBPeripheralManagerStateUnknown");
        }
            break;
        case CBPeripheralManagerStateResetting:
        {
            NSLog(@"CBPeripheralManagerStateResetting");
        }
            break;
        case CBPeripheralManagerStateUnsupported:
        {
            //just for when I am running on simulator,
            if (!IS_RUNNING_ON_SIMULATOR)
            {
                //unsuported state means the device cannot do bluetooth low energy
                UIAlertView *alert = [[UIAlertView alloc] initWithTitle:@"Oh noes" message:@"The platform doesn't support the Bluetooth low energy peripheral/server role." delegate:nil cancelButtonTitle:@"Dang!" otherButtonTitles:nil];
                [alert show];
                self.peripheralManagerIsRunning = NO;
                NSLog(@"CBPeripheralManagerStateUnsupported");
            } else
            {
                NSLog(@"FAKE CBPeripheralManagerStateUnauthorized");
                self.peripheralManagerIsRunning = NO;
                
                [self blueToothStackNeedsUserToActivateMessage];
            }
        }
            break;
        case CBPeripheralManagerStateUnauthorized:
        {
            NSLog(@"CBPeripheralManagerStateUnauthorized");
            self.peripheralManagerIsRunning = NO;
            
            [self blueToothStackNeedsUserToActivateMessage];
            
        }
            break;
        case CBPeripheralManagerStatePoweredOff:
        {
            NSLog(@"CBPeripheralManagerStatePoweredOff");
            self.peripheralManagerIsRunning = NO;
            
            [self blueToothStackNeedsUserToActivateMessage];
            
        }
            break;
        case CBPeripheralManagerStatePoweredOn:
        {
            NSLog(@"CBPeripheralManagerStatePoweredOn");
//            if (!self.peripheralManagerIsRunning)
//            {

                // Setup the scanner
                [self initScanner];
                // Start broadcasting
                [self startBroadcasting];

//            }
        }
            break;
    }
    NSLog(@"\n");
    

}

# pragma mark - transform beacons into ids
- (NSArray *)getBeaconIds
{
    NSMutableArray *beaconIds = [[NSMutableArray alloc] init];
    for (CLBeacon *beacon in self.beacons) {
        NSString *idString = [[NSString alloc] initWithFormat:@"%@:%@",beacon.major,beacon.minor];
        [beaconIds addObject:idString];
    }
    return beaconIds;
}


- (void)locationManager:(CLLocationManager *)manager didDetermineState:(CLRegionState)state forRegion:(CLRegion *)region
{
    NSLog(@"locationManager::%@", region);
    switch (state)
    {
        case CLRegionStateInside:
        {
//            //ranging is shot off here by calling didEnterRegion
            [self locationManager:manager didEnterRegion:region];
            

            
            UILocalNotification *localNotification = [[UILocalNotification alloc] init];

            localNotification.fireDate = [NSDate date];
            localNotification.alertBody = @"Earshot users nearby!";
            localNotification.timeZone = [NSTimeZone defaultTimeZone];

            [[UIApplication sharedApplication] scheduleLocalNotification:localNotification];
            
        }
        break;
            
        case CLRegionStateOutside:
        {
            NSLog(@"CLRegionStateOutside");
            [self locationManager:manager didExitRegion:region];
        }
        break;
        case CLRegionStateUnknown:
        {
            NSLog(@"CLRegionStateUnknown");
        }
            break;
            
        default:
            break;
    }
    
    
}

-(void)blueToothStackIsActive
{
    self.peripheralManagerIsRunning = YES;
    [[NSNotificationCenter defaultCenter] postNotificationName:@"Bluetooth Enabled" object:nil];
}
-(void)blueToothStackNeedsUserToActivateMessage
{
    if (IS_RUNNING_ON_SIMULATOR)
    {
        [self blueToothStackIsActive];
    } else
    {
        [[NSNotificationCenter defaultCenter] postNotificationName:@"Bluetooth Disabled" object:nil];
    }
}

-(BOOL)peripheralManagerIsRunning
{
    BOOL isOK = NO;
    switch ([ CLLocationManager authorizationStatus] ) {
        case kCLAuthorizationStatusAuthorized:
            isOK = YES;
            break;
        case kCLAuthorizationStatusDenied:
            isOK = NO;
            break;
        case kCLAuthorizationStatusNotDetermined:
            isOK = NO;
            break;
        case kCLAuthorizationStatusRestricted:
            isOK = NO;
            break;

    }
    
    BOOL val = peripheralManagerIsRunning && isOK;
    return val;
}

-(CLLocation*)getLocation
{
    return self.locationManager.location;
}

-(void)dealloc
{
    [[NSNotificationCenter defaultCenter] removeObserver:self];
}

@end
