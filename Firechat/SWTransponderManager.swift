//
//  SWTransponderManager.swift
//  Shortwave
//
//  Created by Alonso Holmes on 7/11/14.
//  Copyright (c) 2014 Buildco. All rights reserved.
//

// This class serves as a wrapper around the ESTransponder class, and should contain all of the iOS App - specific functionality.
// Specifically, UIApplication does not exist in the extension, so we're moving wakeup / sleep functionality out to here.

import Foundation
import CoreLocation
import CoreBluetooth
import ShortwaveiOSFramework

@objc class SWTransponderManager : NSObject {
    
//    let CentralManager: CBCentralManager
    
    @objc init(){
        // Handle app sleep/wakeup
        var trans = Transponder()
        println("hello there!")
        trans.authorize()
    }
    
}