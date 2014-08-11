//
//  SWAuthViewController.swift
//  Shortwave
//
//  Created by Ethan Sherr on 7/24/14.
//  Copyright (c) 2014 Ethan Sherr. All rights reserved.
//

import Foundation
import UIKit

class SWAuthViewController: UIViewController, UIAlertViewDelegate
{
    
    @IBOutlet var authButton: UIButton!
    lazy var authClient:FirebaseSimpleLogin = FirebaseSimpleLogin(ref: Firebase(url: kROOT_FIREBASE) )
    
    
    override func viewDidLoad()
    {
        super.viewDidLoad()
        
        //if i'm already logged in just push ahead
        if NSUserDefaults.standardUserDefaults().boolForKey(kNSUSERDEFAULTS_BOOLKEY_userIsLoggedIn)
        {
//            var viewControllers:Array<UIViewController> = navigationController.viewControllers as Array<UIViewController>
//            var channelViewController:UIViewController = storyboard.instantiateViewControllerWithIdentifier("SWChannelsViewController") as UIViewController
//            viewControllers += channelViewController;
//            navigationController.viewControllers = viewControllers;
        }
        
        observeAuthStatus()
    }
    
    func observeAuthStatus()
    {
        var authRef = Firebase(url: "\(kROOT_FIREBASE).info/authenticated")
        authRef.observeEventType(FEventTypeValue, withBlock:
            {(snap:FDataSnapshot!) in
                
                if let isAuthenticated:Bool = snap.value.boolValue
                {
                    println("isAuthenticated? \(isAuthenticated)")
                } else
                {
                    println("no, isnotAuthenticated?")
                }
            })
    }
    
    func beginAuthWithFirebase()
    {
        authClient.loginToFacebookAppWithId(kFacebookAppId, permissions: kFacebookPermissions, audience: ACFacebookAudienceOnlyMe, withCompletionBlock:
        {(error:NSError!, user:FAUser!) in
            
            let completion:()->() =
            {
                self.authButton.userInteractionEnabled = true
                if let e = error
                {
                    //Code=-4
                    if e.code == -4
                    {
                        println("error: \(error)");
                        let isMain = NSThread.isMainThread()
                        println("isMainthread? \(isMain)")
                        var alert: UIAlertView = UIAlertView(title:"No account found.", message: "I was unable to find a Facebook account on this device, are you sure your phone has a Facebook account?  Go to settings > facebook.", delegate: self, cancelButtonTitle: nil, otherButtonTitles:"I'll check")
                        alert.show()
                    } else
                    {
                        var alert: UIAlertView = UIAlertView(title:"No account found.", message: "error: \(error.localizedDescription) code = \(error.code)", delegate: self, cancelButtonTitle: nil, otherButtonTitles:"I'll check")
                        alert.show()
                    }
                } else
                {//complete login
                    println("user: \(user)");

                    self.createUser(user)

                    self.navigationItem.hidesBackButton = true;//for the next viewcontroller
                    self.performSegueWithIdentifier("next", sender: self)
                }
            }
            
            if !NSThread.isMainThread()
            {
                dispatch_sync(dispatch_get_main_queue())
                {
                    completion()
                }
            } else
            {
                completion()
            }
        })
    }
    
    func createUser(user:FAUser)
    {
//        println("uid = \(user.uid)")
//        println("userID = \(user.userId)")
        
        
        let thirdPartyUserData:NSDictionary = user.thirdPartyUserData["thirdPartyUserData"] as NSDictionary
//        println("thirdPartyUserData = \(thirdPartyUserData)")

        
        let firstName = thirdPartyUserData["first_name"]!
        let picture:NSDictionary = thirdPartyUserData["picture"] as NSDictionary
        let datas = picture["data"] as NSDictionary
        let photo = datas["url"]

        
        Firebase(url: "\(kROOT_FIREBASE)users/\(user.uid)/profile/firstName/").setValue(firstName)
        Firebase(url: "\(kROOT_FIREBASE)users/\(user.uid)/profile/photo/").setValue(photo)
        
        
        
        
        let prefs = NSUserDefaults.standardUserDefaults();
        prefs.setBool(true, forKey: kNSUSERDEFAULTS_BOOLKEY_userIsLoggedIn)
        prefs.setObject(user.uid, forKey: kNSUSERDEFAULTS_KEY_userId)
        
        prefs.synchronize()
        
        //difference between ios8 and 7 registration
        let version =  UIDevice.currentDevice().systemVersion //([currSysVer compare:reqSysVer options:NSNumericSearch] != NSOrderedAscending)
        let reqVersin = "8.0"
        let name = UIDevice.currentDevice().systemName
        
//        println("version \(version) name \(name)")
        
        let elems = version.componentsSeparatedByString(".")
//        println("elems \(elems)")
        
        //Cocoa Cola, the classic beverage
        CocoaColaClassic.RegisterRemoteNotifications()
                
    }
    
    
    func alertView(alertView: UIAlertView!, clickedButtonAtIndex buttonIndex: Int)
    {
//        if buttonIndex == 0
//        {
//            //open a link to facebook on the appstore
//            UIApplication.sharedApplication().openURL(NSURL(string: kFacebookOnAppStore))
//        }
        
    }
    
    
    @IBAction func authButtonPress(sender: AnyObject)
    {
        authButton.userInteractionEnabled = false
        beginAuthWithFirebase()
    }
}
