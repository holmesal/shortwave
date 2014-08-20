//
//  Constants.swift
//  Shortwave
//
//  Created by Ethan Sherr on 7/24/14.
//  Copyright (c) 2014 Ethan Sherr. All rights reserved.
//

import Foundation



var kROOT_FIREBASE:String {
    get
        {
            if CocoaColaClassic.debug()
            {
                return "https://shortwave-dev.firebaseio.com/"
            }
            return "https://shortwave-dev.firebaseio.com/"
    }
}
var kSANDBOX:Bool
{
    get {
        if CocoaColaClassic.debug()
        {
            return true
        }
        return false
    }
}


let kRemoteNotification_JoinChannel = "remoteNotificationJoinChannel"


let kNSUSERDEFAULTS_BOOLKEY_userIsLoggedIn = "UserIsLoggedIn"
let kNSUSERDEFAULTS_KEY_userId = "hehehloluser"
let kNSUSERDEFAULTS_KEY_firebaseKeyForDeviceToken = "deviceTokenKey"

let kFacebookOnAppStore = "https://itunes.apple.com/us/app/facebook/id284882215?mt=8"
let kFacebookAppId = "684979988223644"
let kFacebookPermissions:Array<AnyObject> = []//["email"]

let kMixpanelToken = ""
//"public_profile",

let kNiceColors = [
    "blue":"4793E7",
    "purple":"A550F3",
    "red":"E15050",
    "pinkRed":"FA526F",
    "orange":"F1793A",
    "yellow":"E8AD27",
    "green":"00CF69",
    "bar":"323232"]