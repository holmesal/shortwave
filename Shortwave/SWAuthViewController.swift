//
//  SWAuthViewController.swift
//  Shortwave
//
//  Created by Ethan Sherr on 7/24/14.
//  Copyright (c) 2014 Ethan Sherr. All rights reserved.
//

import Foundation
import UIKit
import QuartzCore

class SWAuthViewController: UIViewController, UIAlertViewDelegate
{
    var suggestionIndex:Int = 0
    var repeatTimer:NSTimer?
    
    @IBOutlet weak var authorizingView: UIView!
    @IBOutlet weak var titleContainerView: UIView!
    @IBOutlet weak var channelNameLabel: UILabel!
    @IBOutlet weak var actionLabel: UILabel!
    @IBOutlet var authButton: UIButton!
    lazy var authClient:FirebaseSimpleLogin = FirebaseSimpleLogin(ref: Firebase(url: kROOT_FIREBASE) )
    
    @IBOutlet weak var centerView: UIView!
    
    var suggestions:Array<NSDictionary> =
    [
        ["str1": "s1",
            "str2": "s2"]
    ]
    
    override func viewDidLoad()
    {
        super.viewDidLoad()
        
        centerView.backgroundColor = UIColor.clearColor()
        authorizingView.alpha = 0.0
        var layer = CALayer()
        layer.frame = authButton.bounds
        layer.backgroundColor = UIColor.clearColor().CGColor
        layer.borderColor = UIColor.whiteColor().CGColor
        layer.cornerRadius = 3
        layer.borderWidth = 1
        authButton.layer.addSublayer(layer)
        
        //if i'm already logged in just push ahead
        if NSUserDefaults.standardUserDefaults().boolForKey(kNSUSERDEFAULTS_BOOLKEY_userIsLoggedIn)
        {
            beginAuthWithFirebase()
        } else
        {

        }
        

        Firebase(url: kROOT_FIREBASE + "useWithSuggestions").observeEventType(FEventTypeValue, withBlock:
            {(snap:FDataSnapshot!) in
                if let result = snap.value as? Array<NSDictionary> {
                    for r in result {
                        self.suggestions += r
                    }
                    
                    self.startRepeatingIfNotAlready()
                }
            })
        
        observeAuthStatus()
    }
    
    func startRepeatingIfNotAlready()
    {
        if repeatTimer
        {
            
        } else
        {
            repeatTimer = NSTimer(timeInterval: 4, target: self, selector: "repeat", userInfo: nil, repeats: true)
            NSRunLoop.mainRunLoop().addTimer(repeatTimer, forMode: NSDefaultRunLoopMode)
        }
    }
    
    override func viewDidAppear(animated: Bool)
    {
        super.viewDidAppear(animated)
        repeat()
    }
    
    func copyLabel(label:UILabel) -> UILabel
    {
        var newLabel = UILabel(frame: label.frame)
        newLabel.textColor = label.textColor
        newLabel.font = label.font
        newLabel.textAlignment = label.textAlignment
        
        return newLabel
    }
    
    func repeat()
    {
        
        let dict = suggestions[suggestionIndex % suggestions.count]
        
        if let str1 = dict["str1"] as? String
        {
            if let str2 = dict["str2"] as? String
            {
                animateReplace(str1, andSecondString: str2)
            }
        }
        
        
        suggestionIndex++
    }
    
    
    func animateReplace( str1:String, andSecondString str2:String)
    {
        let fadeOutDisplacement = CGFloat(12.0)
        let fadeInDisplacement = CGFloat(40.0)
        let scaleAway = CGFloat(0.7)
        
        var actionLabel2 = copyLabel(actionLabel)
        actionLabel2.text = str1
        var channelNameLabel2 = copyLabel(channelNameLabel)
        channelNameLabel2.text = str2
        centerView.addSubview(actionLabel2)
        centerView.addSubview(channelNameLabel2)
        
        actionLabel2.transform = CGAffineTransformMakeTranslation(CGFloat(0), -fadeInDisplacement)
        channelNameLabel2.transform = CGAffineTransformMakeTranslation(CGFloat(0), fadeInDisplacement)
        actionLabel2.alpha = 0.0
        channelNameLabel2.alpha = 0.0
        
        let outgoingChange:()->() = {
            self.actionLabel.transform = CGAffineTransformConcat(CGAffineTransformMakeScale(scaleAway, scaleAway), CGAffineTransformMakeTranslation(0, fadeOutDisplacement))
            self.channelNameLabel.transform = CGAffineTransformConcat(CGAffineTransformMakeScale(scaleAway, scaleAway), CGAffineTransformMakeTranslation(0, -fadeOutDisplacement))
            self.actionLabel.alpha = 0.0
            self.channelNameLabel.alpha = 0.0
        }
        let incomingChange:()->() = {
            actionLabel2.transform = CGAffineTransformIdentity
            channelNameLabel2.transform = CGAffineTransformIdentity
            actionLabel2.alpha = 1.0
            channelNameLabel2.alpha = 1.0
        }
        
        let duration = 1.35
        
        UIView.animateWithDuration(duration*1.2, delay: 0.0, usingSpringWithDamping: 0.5, initialSpringVelocity: 0.5, options: .CurveLinear, animations:
            {

                outgoingChange()
                
                
                
                
            }, completion: {(b:Bool) in
                
                self.actionLabel.removeFromSuperview()
                self.channelNameLabel.removeFromSuperview()
                
                self.actionLabel = actionLabel2
                self.channelNameLabel = channelNameLabel2
                
            })
        UIView.animateWithDuration(duration, delay: 0.0, usingSpringWithDamping: 1.5, initialSpringVelocity: 0.5, options: .CurveLinear, animations:
            {
                incomingChange()
            }, completion: {(b:Bool) in })
        
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
    
    func showValidatingUI()
    {
        UIView.animateWithDuration(0.4, delay: 0.0, usingSpringWithDamping: 2, initialSpringVelocity: 2, options: .CurveLinear, animations: {
                self.centerView.alpha = 0.0
                self.authorizingView.alpha = 1.0
            }, completion:
            {(b:Bool) in })
    }
    
    func beginAuthWithFirebase()
    {
        authButton.userInteractionEnabled = false
        showValidatingUI()
        
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
        beginAuthWithFirebase()
    }
    
    override func viewWillDisappear(animated: Bool)
    {
        if repeatTimer
        {
            repeatTimer!.invalidate()
            repeatTimer = nil
        }
    }
}
