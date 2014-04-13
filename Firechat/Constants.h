//
//  Constants.h
//  Earshot
//
//  Created by Alonso Holmes on 4/9/14.
//  Copyright (c) 2014 Buildco. All rights reserved.
//

#ifndef Earshot_Constants_h
#define Earshot_Constants_h


#ifdef DEBUG


// Use the dev firebase
#define FIREBASE_ROOT_URL @"https://earshot-dev.firebaseio.com"
// Show user ids on single tap
#define DEBUG_SHOW_USER_ID_SINGLE_TAP YES
#else

// Use the production firebase
#define FIREBASE_ROOT_URL @"https://earshot.firebaseio.com"
// Don't show user ids on single tap
#define DEBUG_SHOW_USER_ID_SINGLE_TAP NO

//// Hide NSLogs
#undef NSLog
#define NSLog(args, ...)

#endif



#endif



#define kNSUSER_DEFAULTS_HAS_BEEN_INVITED_IN @"Hands down, boys!"