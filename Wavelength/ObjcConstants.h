//
//  ObjcConstants.h
//  Shortwave
//
//  Created by Ethan Sherr on 9/3/14.
//  Copyright (c) 2014 Ethan Sherr. All rights reserved.
//

#ifdef DEBUG
    #define Objc_kSandbox YES
#else
    #define Objc_kSandbox NO
#endif

#define Objc_kROOT_FIREBASE @"https://shortwave-dev.firebaseio.com/"


#define Objc_kRemoteNotification_JoinChannel @"remoteNotificationJoinChannel"

#define Objc_kNSUSERDEFAULTS_BOOLKEY_userHasSeenWalkthrough @"hasUserSeenWalkthroughKey?"
#define Objc_kNSUSERDEFAULTS_BOOLKEY_userIsLoggedIn @"UserIsLoggedIn"
#define Objc_kNSUSERDEFAULTS_KEY_userId @"hehehloluser"
#define Objc_kNSUSERDEFAULTS_KEY_firebaseKeyForDeviceToken @"deviceTokenKey"

#define Objc_kNiceColors @{@"blue":@"4793E7", @"purple":@"A550F3", @"red":@"E15050", @"pinkRed":@"FA526F", @"orange":@"F1793A", @"yellow":@"E8AD27", @"green":@"00CF69", @"bar":@"323232"}

/*
 let kFacebookOnAppStore = "https://itunes.apple.com/us/app/facebook/id284882215?mt=8"
 */
#define Objc_kFacebookAppId @"684979988223644"
#define Objc_kFacebookPermissions @[]
//["email"]

#define Objc_kMixpanelToken @"b8c0a03029e85ac788e49f10ddb2e80d"


#define Objc_kAWS_ACCESS_KEY_ID @"AKIAJWLORAVT7M4V7IJA"
#define Objc_kAWS_SECRET_KEY @"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"
#define Objc_kAWS_BUCKET @"wavelength-bucket"