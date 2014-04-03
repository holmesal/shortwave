//
//  ESTransponder.m
//  Earshot
//
//  Created by Alonso Holmes on 4/1/14.
//  Copyright (c) 2014 Buildco. All rights reserved.
//

#import "ESTransponder.h"
#import <CoreBluetooth/CoreBluetooth.h>

@interface ESTransponder() <CBPeripheralManagerDelegate, CBCentralManagerDelegate>

@end

@implementation ESTransponder

- (void)setEarshotID:(NSString *)earshotID
{
    self.earshotID = earshotID;
    [self startBroadcasting];
}

# pragma mark - core bluetooth
- (void)startBroadcasting
{
    
}



@end
