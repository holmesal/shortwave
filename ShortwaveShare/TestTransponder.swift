//
//  TestTransponder.swift
//  Shortwave
//
//  Created by Alonso Holmes on 7/11/14.
//  Copyright (c) 2014 Buildco. All rights reserved.
//

import Foundation
import CoreBluetooth
import CoreLocation

class Transponder : NSObject, CBCentralManagerDelegate {
    
    // Location manager handles iBeacons and significant location changes
    let locationManager: CLLocationManager!
    // List of region UUIDs to listen and broadcast on
    let regionUUIDs = [
        "DDE6C09F-345B-4FC2-80C1-C27977EB35A6",
        "E20DF868-0B06-4361-85DE-EE57A57CAA5F",
        "BCEA644E-3B51-4E6C-8B72-ED204EC5FA36",
        "9CA603ED-7A5D-4F2F-BBB6-70AAC0050C7E",
        "A97C54AA-A7B8-4AED-8542-12BCF12D97DD",
        "6B6ABB05-46D1-4466-BCAC-D6F70CBE1348",
        "F1229A67-42EB-40CB-83F0-32385074F705",
        "259CB377-2CB2-476B-B59A-326CB3315B47",
        "C0A151D2-EC1D-4547-87D8-4C73E94252D3",
        "D64BB228-C3C1-4A16-A1A5-C84785DAAD7B",
        "2DC4D09C-5846-463D-9FFC-BDFE414417BF",
        "5AAFB50C-F795-4818-9433-7197C517B1E0",
        "155E22AE-AE03-4A65-B665-71D9E417146A",
        "19D0C85F-B85E-4DE1-9449-498F62E443FD",
        "554EBF21-D361-41F0-8B93-34E40ABB090B",
        "B8F2B4F6-2771-4B05-BB8B-CBA06A08CC74",
        "43AF147A-2EC5-4357-AD56-AB36B145C2F5",
        "A7CF1269-E65C-4BED-9395-183761DE02DB",
        "9C9FA6DD-B314-429E-A587-37EAA0C5D6B7"
    ]
    // This is the uuid we'll use to range the beacons
    let rangingUUID = "A48639FC-CC79-4A8E-8E35-DF080B9C72E3"
    // Current state of regions, defaults to false (outside)
    var regionStates: Bool[]
    
    // CoreBluetooth central manager listens for other anonymous users
    let centralManager: CBCentralManager!
    
    
    
    
//    let centralManager : CBCentralManager
//    let peripheralManager : CBPeripheralManager
    
    init() {
        // Init region states
        regionStates = Bool[](count: regionUUIDs.count, repeatedValue: false)
        super.init()
//        centralManager = CBCentralManager(delegate: self, queue: dispatch_get_main_queue())
//        println("State is \(centralManager.state.toRaw())")
        
        locationManager = CLLocationManager()
        locationManager.delegate = self
        // Watch for large location changes
        locationManager.startMonitoringSignificantLocationChanges()
        println("Location is available what say you: \(CLLocationManager.significantLocationChangeMonitoringAvailable())")
        println("Location is \(locationManager.location)")
        
        // Start listening for beacons
        listenForBeacons()
    }
    
    func authorize() {
        // TODO - split this into different flows, depending on whether the user has iOS7 or 8
        // Request "always" authorization from the user
        locationManager.requestAlwaysAuthorization()
    }
    

    
    
    
//    
//  Central Manager delegate methods
//    
    
    func centralManagerDidUpdateState(central: CBCentralManager!) {
        println("Did update state! State is now \(central.state.toRaw())")
    }
    
    
//
// Beacons
//
    
    func listenForBeacons() {
        func bootRegion(uuidString: String, identifier: String) {
            // Make a beacon region
            let uuid = NSUUID(UUIDString: uuidString)
            let region = CLBeaconRegion(proximityUUID: uuid, identifier: identifier)
            // Set some options
            region.notifyEntryStateOnDisplay = true
            region.notifyOnEntry = true
            region.notifyOnExit = true
            // Start listening
            locationManager.startMonitoringForRegion(region)
            // Update the state
            locationManager.requestStateForRegion(region)
        }
        // Go through each wakeup region and start listening
        for (idx,uuid) in enumerate(regionUUIDs){
            bootRegion(uuid, "Wakeup region \(idx)")
        }
        
        // Create the ranging region separately
        bootRegion(rangingUUID, "Ranging region")
        // TODO - start ranging here
    }
    
}

extension Transponder: CLLocationManagerDelegate {
    
    func locationManager(manager: CLLocationManager!, didChangeAuthorizationStatus status: CLAuthorizationStatus){
        println("Location manager changed auth state to: \(status.toRaw())")
    }
    
    func locationManager(manager: CLLocationManager!, didUpdateLocations locations: AnyObject[]!){
        println("Updated locations! \(locations)")
    }
    
    func locationManager(manager: CLLocationManager!, didEnterRegion region: CLRegion!){
        // Update the state of regions
        println(region)
    }
    
    func locationManager(manager: CLLocationManager!, didExitRegion region: CLRegion!){
        // Update the state of regions
        println(region)
    }
    
    func locationManager(manager: CLLocationManager!, didDetermineState state: CLRegionState, forRegion region: CLRegion!){
        println("Got state \(state.toRaw()) for region:")
        println(region)
    }
    
}