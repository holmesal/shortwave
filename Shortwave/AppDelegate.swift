//
//  AppDelegate.swift
//  Shortwave
//
//  Created by Ethan Sherr on 7/24/14.
//  Copyright (c) 2014 Ethan Sherr. All rights reserved.
//

import UIKit

@UIApplicationMain
@objc class AppDelegate: UIResponder, UIApplicationDelegate {
                            
    var window: UIWindow?
    var imageLoader:SWImageLoader = SWImageLoader()

    func application(application: UIApplication, didFinishLaunchingWithOptions launchOptions: NSDictionary?) -> Bool {

        Crashlytics.startWithAPIKey("4a71d4033d33d194e246ada67acce08c24c06e80")
        
        //audio session
        let audioSession = AVAudioSession.sharedInstance()
        audioSession.setCategory(AVAudioSessionCategoryAmbient, error: nil)
        
        UIApplication.sharedApplication().statusBarStyle = UIStatusBarStyle.LightContent
        return true
    }

    func applicationWillResignActive(application: UIApplication) {
        // Sent when the application is about to move from active to inactive state. This can occur for certain types of temporary interruptions (such as an incoming phone call or SMS message) or when the user quits the application and it begins the transition to the background state.
        // Use this method to pause ongoing tasks, disable timers, and throttle down OpenGL ES frame rates. Games should use this method to pause the game.
    }

    func applicationDidEnterBackground(application: UIApplication) {
        // Use this method to release shared resources, save user data, invalidate timers, and store enough application state information to restore your application to its current state in case it is terminated later.
        // If your application supports background execution, this method is called instead of applicationWillTerminate: when the user quits.
    }

    func applicationWillEnterForeground(application: UIApplication) {
        // Called as part of the transition from the background to the inactive state; here you can undo many of the changes made on entering the background.
    }

    func applicationDidBecomeActive(application: UIApplication) {
        // Restart any tasks that were paused (or not yet started) while the application was inactive. If the application was previously in the background, optionally refresh the user interface.
    }

    func applicationWillTerminate(application: UIApplication) {
        // Called when the application is about to terminate. Save data if appropriate. See also applicationDidEnterBackground:.
    }

    
    
    func application(application: UIApplication!, didRegisterUserNotificationSettings notificationSettings: UIUserNotificationSettings!)
    {
        //register to receive notifications!
        application.registerForRemoteNotifications()
    
    }
    
    func application(application: UIApplication!, handleActionWithIdentifier identifier: String!, forRemoteNotification userInfo: [NSObject : AnyObject]!, completionHandler: (() -> Void)!)
    
    {
        if identifier == "declineAction"
        {
            println("**DECLINEACTION**")
        } else
        if identifier == "answerAction"
        {
            println("**ANSWERACTION**")
        }
    
    }
    
    
    func application(application: UIApplication!, didRegisterForRemoteNotificationsWithDeviceToken deviceToken: NSData!)
    {
        var aofb = [UInt8](count:deviceToken.length, repeatedValue:0)
        deviceToken.getBytes(&aofb, length:deviceToken.length)
        
        var token = ""
        for c in aofb
        {
            token += String(format: "%02x", c)
        }
        println("i converted it to \(token)")
        
        //must have userID, else crash!
        let userID = NSUserDefaults.standardUserDefaults().objectForKey(kNSUSERDEFAULTS_KEY_userId) as String
       
        
        let url = kROOT_FIREBASE + "users/" + userID + "/devices/"
        

        
        var saveTokenFirebase:Firebase!
        
        
        if let knownDeviceTokenKey = NSUserDefaults.standardUserDefaults().objectForKey(kNSUSERDEFAULTS_KEY_firebaseKeyForDeviceToken) as? String
        {
            saveTokenFirebase = Firebase(url: url + knownDeviceTokenKey)
            saveTokenFirebase.setValue(
                ["type":"ios",
                    "token":token], withCompletionBlock:
                {(error:NSError?, firebase:Firebase?) in
                    if let e = error
                    {
                        println("token saving wiht error = \(error?.localizedDescription)")
                    }
                })
            NSUserDefaults.standardUserDefaults().setObject(saveTokenFirebase.name, forKey: kNSUSERDEFAULTS_KEY_firebaseKeyForDeviceToken)
            NSUserDefaults.standardUserDefaults().synchronize()
            
        } else
        {
//            saveTokenFirebase = Firebase(url: url).childByAutoId()
            let loadDevices = Firebase(url: url)
            loadDevices .observeEventType(FEventTypeValue, withBlock:
                {(snap:FDataSnapshot!) in
                    if let devicesDict = snap.value as? Dictionary<NSString, AnyObject>
                    {
                        for (keyName, anyValue) in devicesDict
                        {
                            if let device = anyValue as? NSDictionary
                            {
                                if let optionalToken = device["token"]? as? NSString
                                {
                                    if optionalToken == token
                                    {
                                        NSUserDefaults.standardUserDefaults().setObject(keyName, forKey: kNSUSERDEFAULTS_KEY_firebaseKeyForDeviceToken)
                                        NSUserDefaults.standardUserDefaults().synchronize()
                                        
                                        return;
                                    } else
                                    {}
                                }
                            }
                        }
                    } //end of devicesDict existence 
                    
                    
                    //if I'm here then I have not found my token
                    println("no token found!")
                    
                    saveTokenFirebase = Firebase(url: url).childByAutoId()
                    saveTokenFirebase.setValue(
                        ["type":"ios",
                            "token":token,
                            "sandbox":kSANDBOX], withCompletionBlock:
                        {(error:NSError?, firebase:Firebase?) in
                            println("token saving wiht error = \(error?.localizedDescription)")
                        })
                    NSUserDefaults.standardUserDefaults().setObject(saveTokenFirebase.name, forKey: kNSUSERDEFAULTS_KEY_firebaseKeyForDeviceToken)
                    NSUserDefaults.standardUserDefaults().synchronize()
                    
                })
        }
        
        
        
        
        


        
    }
    
    func application(application: UIApplication!, didFailToRegisterForRemoteNotificationsWithError error: NSError!)
    {
        println("failedToRegisterForRemoteNotifications \(error.localizedDescription)")
    }

    func application(application: UIApplication!, didReceiveRemoteNotification userInfo: [NSObject : AnyObject]!)
    {
        if UIApplication.sharedApplication().applicationState == .Active
        {
            println("##notification## received by running app")
        } else
            //            if UIApplication.sharedApplication().applicationState == .Active
        {
            println("##notification## opened from notification")
        }
        
    }
    
//    -(void) application:(UIApplication *)application didReceiveRemoteNotification:(NSDictionary *)userInfo {
//    if ([UIApplication sharedApplication].applicationState==UIApplicationStateActive) {
//    NSLog(@"Notification recieved by running app");
//    }
//    else{
//    NSLog(@"App opened from Notification");
//    }
//    
//    }

}

