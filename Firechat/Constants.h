//
//  Constants.h
//  Earshot
//
//  Created by Alonso Holmes on 4/9/14.
//  Copyright (c) 2014 Buildco. All rights reserved.
//

#ifndef Earshot_Constants_h
#define Earshot_Constants_h




#if TARGET_IPHONE_SIMULATOR
//is simulator?
#define IS_ON_SIMULATOR YES

#elif TARGET_OS_IPHONE
//is real device
#warning "AHHH!"
#define IS_ON_SIMULATOR YES

#else
#define IS_ON_SIMULATOR NO
//unknown target
#endif




#ifdef DEBUG

#define ESAssert(b, s) { NSAssert(b, s);}

// Use the dev firebase
#define FIREBASE_ROOT_URL @"https://earshot-dev.firebaseio.com"
// Show user ids on single tap
#define DEBUG_SHOW_USER_ID_SINGLE_TAP YES
// Show debug local notifications
#define DEBUG_SHOW_NOTIFS YES
#else

#define ESAssert(b,s) if (!b) {NSLog([NSString stringWithFormat:@"ERROR: %@", s])};
// Use the production firebase
#define FIREBASE_ROOT_URL @"https://earshot.firebaseio.com"
// Don't show user ids on single tap
#define DEBUG_SHOW_USER_ID_SINGLE_TAP NO
// Don't show local notifications
#define DEBUG_SHOW_NOTIFS NO

//// Hide NSLogs
#undef NSLog
#define NSLog(args, ...)

#endif



#endif

//events
#define kTrackingUsersNearbyNotification @"Sussess!"
#define kTrackingNoUsersNearbyNotification @"Where you at?"
//user default keys
#define kNSUSER_DEFAULTS_HAS_BEEN_INVITED_IN @"Hands down, boys!"
#define kNSUSER_DEFAULTS_COLOR @"color"
#define kNSUSER_DEFAULTS_ICON @"icon"