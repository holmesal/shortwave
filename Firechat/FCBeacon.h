//
//  FCBeacon.h
//  Firechat
//
//  Created by Alonso Holmes on 1/12/14.
//  Copyright (c) 2014 Buildco. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <CoreLocation/CoreLocation.h>
#import <CoreBluetooth/CoreBluetooth.h>

@interface FCBeacon : NSObject<CBPeripheralManagerDelegate,CLLocationManagerDelegate>


@property (strong, nonatomic) CBPeripheralManager *peripheralManager;
@property (strong, nonatomic) CLLocationManager *locationManager;
@property NSArray *beacons;
@property NSNumber *major;
@property NSNumber *minor;


-(CLLocation*)getLocation;
- (id)initWithMajor:(NSNumber *)major andMinor:(NSNumber *)minor;
- (NSArray *)getBeaconIds;
- (void) checkSupport;

-(void)start;
@property (nonatomic) BOOL peripheralManagerIsRunning;

@end
