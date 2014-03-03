//
//  FCBeacon.m
//  Firechat
//
//  Created by Alonso Holmes on 1/12/14.
//  Copyright (c) 2014 Buildco. All rights reserved.
//

#import "FCBeacon.h"

@interface FCBeacon ()
@property NSUUID *uuid;
@property CLBeaconRegion *region;
@end

@implementation FCBeacon

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
        
        // Init peripheral manager
        self.peripheralManager = [[CBPeripheralManager alloc] initWithDelegate:self
                                                                         queue:nil
                                                                       options:nil];
        // Init location manager
        self.locationManager = [[CLLocationManager alloc] init];
        
//        self.uuid = [[NSUUID alloc] initWithUUIDString:@"BC43DDCC-AF0C-4A69-9E75-4CDFF8FD5F63"]; //orbiter devices
        self.uuid = [[NSUUID alloc] initWithUUIDString:@"B9407F30-F5F8-466E-AFF9-25556B57FE6D"]; //estimote
        
    }
    return self;
}

#pragma mark - Scanner
- (void) initScanner
{
    
    // Set delegate
    self.locationManager.delegate = self;
    // Create region
    self.region = [[CLBeaconRegion alloc] initWithProximityUUID:self.uuid identifier:@"Orbiter region"];
    // Launch app with display off when inside region
    self.region.notifyEntryStateOnDisplay = YES;
    
    // Check for supported devices
    if ([CLLocationManager isMonitoringAvailableForClass:[CLBeaconRegion class]])
    {
        [self.locationManager startMonitoringForRegion:self.region];
        // If you want to get the state right away, this is the spot
    }
}

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
//    NSLog(@"Got beacon ranges");
    self.beacons = beacons;
//    NSLog(@"%@",self.beacons);
    [[NSNotificationCenter defaultCenter] postNotificationName:@"Beacons Updated" object:self.beacons];
    // Will parse and push if necessary
//    // Clear existing beacons
//    self.beacons = [[NSMutableArray alloc] init];
//    // Parse and push beacons
//    for (CLBeacon *beacon in beacons)
//    {
//        NSLog(@"%@:%@ at range %d",beacon.major,beacon.minor, beacon.proximity);
//        NSDictionary *user = [[NSDictionary alloc] init];
//    }
//    CLBeacon *beacon = [[CLBeacon alloc] init];
//    beacon = [beacons lastObject];
//    NSLog(@"%@:%@ at range %d",beacon.major,beacon.minor, beacon.proximity);
}

// Start montoring for region
- (void)locationManager:(CLLocationManager *)manager didStartMonitoringForRegion:(CLRegion *)region {
    [_locationManager startRangingBeaconsInRegion:self.region];
}

#pragma mark - Broadcaster

- (void) startBroadcasting
{
    
    NSLog(@"Starting to broadcast with major %@ and minor %@",self.major,self.minor);
    
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
    NSLog(@"peripheralManagerDidStartAdvertising error %@", error.localizedDescription);
}

- (void)peripheralManagerDidUpdateState:(CBPeripheralManager *)peripheral
{
    NSLog(@"DID UPDATE STATE");
    
    /*CBPeripheralManagerStateUnknown = 0,
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
            //unsuported state means the device cannot do bluetooth low energy
            UIAlertView *alert = [[UIAlertView alloc] initWithTitle:@"Oh noes" message:@"The platform doesn't support the Bluetooth low energy peripheral/server role." delegate:nil cancelButtonTitle:@"Dang!" otherButtonTitles:nil];
            [alert show];
            NSLog(@"CBPeripheralManagerStateUnsupported");
        }
            break;
        case CBPeripheralManagerStateUnauthorized:
        {
            NSLog(@"CBPeripheralManagerStateUnauthorized");
        }
            break;
        case CBPeripheralManagerStatePoweredOff:
        {
            NSLog(@"CBPeripheralManagerStatePoweredOff");
            
        }
            break;
        case CBPeripheralManagerStatePoweredOn:
        {
            NSLog(@"CBPeripheralManagerStatePoweredOn");
        }
            break;
    }
    NSLog(@"\n");
    
    if (peripheral.state == CBPeripheralManagerStatePoweredOn){
        // Setup the scanner
        [self initScanner];
        // Start broadcasting
        [self startBroadcasting];
    }
//    CBCentralManagerStatePoweredOn
//    [self _updateEmitterForDesiredState];
}

# pragma mark - transform beacons into ids
- (NSArray *)getBeaconIds
{
    NSLog(@"got beacon ids");
    // Array to hold beacon ids
    NSMutableArray *beaconIds = [[NSMutableArray alloc] init];
    for (CLBeacon *beacon in self.beacons) {
        NSString *idString = [[NSString alloc] initWithFormat:@"%@:%@",beacon.major,beacon.minor];
        [beaconIds addObject:idString];
    }
    return beaconIds;
}

@end
