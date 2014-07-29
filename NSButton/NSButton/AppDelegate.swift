//
//  AppDelegate.swift
//  NSButton
//
//  Created by Ethan Sherr on 7/28/14.
//  Copyright (c) 2014 Ethan Sherr. All rights reserved.
//

import Cocoa

class AppDelegate: NSObject, NSApplicationDelegate {
                            
    @IBOutlet weak var window: NSWindow!


    func applicationDidFinishLaunching(aNotification: NSNotification?) {
        // Insert code here to initialize your application
        let button = NSButton()
        button.target = self
        button.action = "myAction:"
        
    }

    func applicationWillTerminate(aNotification: NSNotification?) {
        // Insert code here to tear down your application
    }


}

