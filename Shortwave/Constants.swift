//
//  Constants.swift
//  Shortwave
//
//  Created by Ethan Sherr on 7/24/14.
//  Copyright (c) 2014 Ethan Sherr. All rights reserved.
//

import Foundation

#if DEBUG
    let kROOT_FIREBASE = "https://shortwave.firebaseio.com/"
#else
    let kROOT_FIREBASE = "https://shortwave-dev.firebaseio.com/"
#endif


let kNSUSERDEFAULTS_BOOLKEY_userIsLoggedIn = "UserIsLoggedIn"
let kNSUSERDEFAULTS_KEY_userId = "hehehloluser"

let kFacebookOnAppStore = "https://itunes.apple.com/us/app/facebook/id284882215?mt=8"
let kFacebookAppId = "684979988223644"
let kFacebookPermissions:Array<AnyObject> = []


let kNiceColors = [
    "blue":"4793E7",
    "purple":"A550F3",
    "red":"E15050",
    "orange":"F1793A",
    "yellow":"E8AD27",
    "green":"02C263"]