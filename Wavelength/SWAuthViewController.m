//
//  SWAuthViewController.m
//  Shortwave
//
//  Created by Ethan Sherr on 9/3/14.
//  Copyright (c) 2014 Ethan Sherr. All rights reserved.
//

#import "SWAuthViewController.h"
#import <Mixpanel/Mixpanel.h>
#import <QuartzCore/QuartzCore.h>
#import <Firebase/Firebase.h>
#import <FirebaseSimpleLogin/FirebaseSimpleLogin.h>
#import "ObjcConstants.h"
#import <Mixpanel/Mixpanel.h>
#import "SWChannelModel.h"
#import "CocoaColaClassic.h"

@interface SWAuthViewController () <UIAlertViewDelegate>


@property (weak, nonatomic) IBOutlet UILabel *welcomeLabel;
@property (weak, nonatomic) IBOutlet NSLayoutConstraint *welcomeCenterConstraint;


@property (weak, nonatomic) IBOutlet UIImageView *hashtagImageView;
@property (weak, nonatomic) IBOutlet NSLayoutConstraint *hashtagCenterVertical;

@property (assign, nonatomic) NSInteger suggestionIndex; //init at 0
//@property (strong, nonatomic) NSTimer *repeatTimer; //may be nil;


@property (assign, nonatomic) BOOL isFirstTime; //init as !(NSUserDefaults.standardUserDefaults().boolForKey(kNSUSERDEFAULTS_BOOLKEY_userIsLoggedIn))
@property (strong, nonatomic) FirebaseSimpleLogin* authClient; //init as kROOT_FIREBASE url

@property (weak, nonatomic) IBOutlet UIView *errorRetryView;
@property (weak, nonatomic) IBOutlet UIView *authorizingView;

@property (weak, nonatomic) IBOutlet UIButton *authButton;


@property (strong, nonatomic) NSMutableArray *suggestions; //init with:
//["str1": "Collaborate with",
// "str2": "#your-community"]

@property (assign, nonatomic) BOOL viewJustLoaded;

@end


@implementation SWAuthViewController

@synthesize errorRetryView;

@synthesize authorizingView;
@synthesize authButton;

@synthesize suggestionIndex;
//@synthesize repeatTimer;
@synthesize isFirstTime;
@synthesize suggestions;
@synthesize authClient;


-(UIStatusBarStyle)preferredStatusBarStyle
{
    return UIStatusBarStyleDefault;
}
-(void)viewDidLoad
{
    _welcomeLabel.alpha = 0.0f;
    _viewJustLoaded = YES;
    [super viewDidLoad];
    [self setNeedsStatusBarAppearanceUpdate];
    suggestionIndex = 0;
    authClient = [[FirebaseSimpleLogin alloc] initWithRef:[[Firebase alloc] initWithUrl:Objc_kROOT_FIREBASE]];
    suggestions = [NSMutableArray arrayWithArray:@[
                            @{@"str1": @"Collaborate with",
                              @"str2": @"#your-community"}]];

    
    errorRetryView.alpha = 0.0f;
    errorRetryView.userInteractionEnabled = NO;
    errorRetryView.backgroundColor = [UIColor clearColor];
    
    [self addParalaxShiftTiltToView:_hashtagImageView];

    authorizingView.alpha = 0.0f;
    CALayer *layer = [CALayer layer];
    layer.frame = authButton.bounds;
    layer.backgroundColor = [UIColor clearColor].CGColor;
    layer.borderColor = [UIColor whiteColor].CGColor;
    layer.cornerRadius = 3.0f;
    layer.borderWidth = 1.0f;
    [authButton.layer addSublayer:layer];
    
    isFirstTime = ![[NSUserDefaults standardUserDefaults] boolForKey:Objc_kNSUSERDEFAULTS_BOOLKEY_userIsLoggedIn];
    if (!isFirstTime)
    {
        [self beginAuthWithFirebase];
    } else
    {}
    
//    [[[Firebase alloc] initWithUrl:[NSString stringWithFormat:@"%@static/useWithSuggestions", Objc_kROOT_FIREBASE]] observeSingleEventOfType:FEventTypeValue withBlock:^(FDataSnapshot *snap)
//    {
//        if ([snap.value isKindOfClass:[NSArray class]])
//        {
//            NSArray *result = snap.value;
//            for (id thing in result)
//            {
//                if ([thing isKindOfClass:[NSDictionary class]])
//                {
//                    [self.suggestions addObject:thing];
//                }
//            }
//            [self startRepeatingIfNotAlready];
//        }
//    }];
    
    [self observeAuthStatus];
    
}

-(void)observeAuthStatus
{
    Firebase *authRef = [[Firebase alloc] initWithUrl:[NSString stringWithFormat:@"%@.info/authenticated", Objc_kROOT_FIREBASE]];
    [authRef observeEventType:FEventTypeValue withBlock:^(FDataSnapshot *snap)
    {
        NSNumber *number = snap.value;
        if ([number isKindOfClass:[NSNumber class]])
        {
            BOOL isAuthenticated = [number boolValue];
//            NSLog(@"isAuthenticated? %d", isAuthenticated);
        }
    }];
}

-(void)addParalaxShiftTiltToView:(UIView*)view
{
    UIInterpolatingMotionEffect *verticalMotionEffect =
    [[UIInterpolatingMotionEffect alloc]
     initWithKeyPath:@"center.y"
     type:UIInterpolatingMotionEffectTypeTiltAlongVerticalAxis];
    verticalMotionEffect.minimumRelativeValue = @(-25);
    verticalMotionEffect.maximumRelativeValue = @(25);
    
    // Set horizontal effect
    UIInterpolatingMotionEffect *horizontalMotionEffect =
    [[UIInterpolatingMotionEffect alloc]
     initWithKeyPath:@"center.x"
     type:UIInterpolatingMotionEffectTypeTiltAlongHorizontalAxis];
    horizontalMotionEffect.minimumRelativeValue = @(-25);
    horizontalMotionEffect.maximumRelativeValue = @(25);
    
    // Create group to combine both
    UIMotionEffectGroup *group = [UIMotionEffectGroup new];
    group.motionEffects = @[horizontalMotionEffect, verticalMotionEffect];
    
    // Add both effects to your view
    [view addMotionEffect:group];
}


//-(void)startRepeatingIfNotAlready
//{
//    if (repeatTimer != nil)
//    {
//        
//    } else
//    {
//        repeatTimer = [NSTimer timerWithTimeInterval:4 target:self selector:@selector(repeat) userInfo:nil repeats:YES];
//        [[NSRunLoop mainRunLoop] addTimer:repeatTimer forMode:NSDefaultRunLoopMode];
//    }
//}
-(void)viewDidAppear:(BOOL)animated
{
    [super viewDidAppear:animated];
    
    if (_viewJustLoaded)
    {
        _viewJustLoaded = NO;
        [UIView animateWithDuration:1.3f delay:0.1f usingSpringWithDamping:1.2f initialSpringVelocity:2.0f options:UIViewAnimationOptionCurveLinear animations:^
        {
            _hashtagCenterVertical.constant = 76.5f;
            if (isFirstTime)
            {
                _welcomeLabel.alpha = 1.0f;
            }
            _welcomeCenterConstraint.constant = -30.0f;
            [self.hashtagImageView.superview layoutIfNeeded];
        } completion:^(BOOL finished){}];
    }
    
    
    //    [self repeat]; //get the first one!
}

-(UILabel*)copyLabel:(UILabel*)label
{
    UILabel *newLabel = [[UILabel alloc] initWithFrame:label.frame];
    newLabel.textColor = label.textColor;
    newLabel.font = label.font;
    newLabel.textAlignment = label.textAlignment;
    
    return newLabel;
}

//-(void)repeat
//{
//    NSDictionary *dict = suggestions[suggestionIndex % suggestions.count];
//    
//    NSString *str1 = dict[@"str1"];
//    NSString *str2 = dict[@"str2"];
//    if (str1 && str2)
//    {
//        [self animateReplaceWithFirstString:str1 andSecondString:str2];
//    }
//    suggestionIndex ++;
//}


//@synthesize channelNameLabel;
//-(void)animateReplaceWithFirstString:(NSString*)str1 andSecondString:(NSString*)str2
//{
//    CGFloat duration = 1.0f;
//    CGFloat fadeOutDisplacement = 12.0f;
//    CGFloat fadeInDisplacement = 40.0f;
//    CGFloat scaleAway = 0.7f;
//    
//    UILabel *actionLabel2 = [self copyLabel:actionLabel];
//    actionLabel2.text = str1;
//    UILabel *channelNameLabel2 = [self copyLabel:channelNameLabel];
//    channelNameLabel2.text = str2;
//    [centerView addSubview:actionLabel2];
//    [centerView addSubview:channelNameLabel2];
//    
//    actionLabel2.transform = CGAffineTransformMakeTranslation(0, -fadeInDisplacement);
//    channelNameLabel2.transform = CGAffineTransformMakeTranslation(0, fadeInDisplacement);
//    actionLabel2.alpha = 0.0f;
//    channelNameLabel2.alpha = 0.0f;
//    
//    __weak SWAuthViewController *weakSelf = self;
//    void (^outgoingChange)(void) = ^{
//        weakSelf.actionLabel.transform = CGAffineTransformConcat(CGAffineTransformMakeScale(scaleAway, scaleAway), CGAffineTransformMakeTranslation(0, fadeInDisplacement));
//        weakSelf.channelNameLabel.transform = CGAffineTransformConcat(CGAffineTransformMakeScale(scaleAway, scaleAway), CGAffineTransformMakeTranslation(0, -fadeInDisplacement));
//    
//        weakSelf.actionLabel.alpha = 0.0f;
//        weakSelf.channelNameLabel.alpha = 0.0f;
//    
//    };
//    void (^incomingChange)(void) = ^{
//        actionLabel2.transform = CGAffineTransformIdentity;
//        channelNameLabel2.transform = CGAffineTransformIdentity;
//        actionLabel2.alpha = 1.0f;
//        channelNameLabel2.alpha = 1.0f;
//    };
//    
//    
//    [UIView animateWithDuration:duration*1.2f delay:0.0f usingSpringWithDamping:0.5f initialSpringVelocity:0.5f options:UIViewAnimationOptionCurveLinear animations:^
//    {
//        outgoingChange();
//        
//    } completion:^(BOOL finished)
//    {
//        [weakSelf.actionLabel removeFromSuperview];
//        [weakSelf.channelNameLabel removeFromSuperview];
//        
//        weakSelf.actionLabel = actionLabel2;
//        weakSelf.channelNameLabel = channelNameLabel2;
//    }];
//    
//    [UIView animateWithDuration:duration delay:0.0f usingSpringWithDamping:1.5f initialSpringVelocity:0.5f options:UIViewAnimationOptionCurveLinear animations:^
//    {
//        incomingChange();
//    } completion:^(BOOL finished){}];
//    
//}

-(void)showValidatingUI
{
    errorRetryView.alpha = 0.0f;
    [UIView animateWithDuration:0.4f delay:0.0f usingSpringWithDamping:2.0f initialSpringVelocity:2.0f options:UIViewAnimationOptionCurveLinear animations:^
    {
        _welcomeLabel.alpha = 0.0f;
        self.authorizingView.alpha = 1.0f;
    } completion:^(BOOL finished){}];
}

-(void)beginAuthWithFirebase
{
    [[Mixpanel sharedInstance] track:@"Authentication Start"];
    
    authButton.userInteractionEnabled = NO;
    [self showValidatingUI];
    
    
    [authClient loginToFacebookAppWithId:Objc_kFacebookAppId permissions:Objc_kFacebookPermissions audience:ACFacebookAudienceOnlyMe withCompletionBlock:^(NSError *error, FAUser *user)
    {
        void (^completion)(void) = ^
        {
            self.authButton.userInteractionEnabled = YES;
            if (error)
            {
                //Code=-4
                [[Mixpanel sharedInstance] track:@"Authentication Fail" properties:@{@"error":error.localizedDescription, @"code":[NSNumber numberWithInt:error.code]}];
                
                [UIView animateWithDuration:0.3f delay:0.2f usingSpringWithDamping:1.0f initialSpringVelocity:0.0f options:UIViewAnimationOptionCurveLinear animations:^
                {
                    self.errorRetryView.alpha = 1.0f;
                    self.authorizingView.alpha = 0.0f;
                } completion:^(BOOL finished){}];
                
                if (error.code == -4)
                {
                    NSLog(@"error = %@", error);
                    UIAlertView *alert = [[UIAlertView alloc] initWithTitle:@"No account found." message:@"I was unable to find a Facebook account on this device.  Are you sure your device has a Facebook account linked?  Go to Settings > Facebook." delegate:self cancelButtonTitle:nil otherButtonTitles:@"I'll check", nil];
                    [alert show];
                } else
                {
                    UIAlertView *alert = [[UIAlertView alloc] initWithTitle:@"Error Occured" message:[NSString stringWithFormat:@"Error %@ code %d", error.localizedDescription, error.code] delegate:self cancelButtonTitle:nil otherButtonTitles:@"It's happening!!", nil];
                    [alert show];
                }
            } else
            {//complete login
                NSLog(@"user: %@", user);
                
                [self createUser:user];
                
                self.navigationItem.hidesBackButton = YES;
                [self performSegueWithIdentifier:@"next" sender:self];
                
                if (self.isFirstTime)
                {
                    self.isFirstTime = NO;
                    
                    Firebase *defaultChannelsFb = [[Firebase alloc] initWithUrl:[NSString stringWithFormat:@"%@static/defaultChannels", Objc_kROOT_FIREBASE]];
                    [defaultChannelsFb observeEventType:FEventTypeValue withBlock:^(FDataSnapshot *snap)
                    {
                        if ([snap.value isKindOfClass:[NSArray class]])
                        {
                            NSArray *result = snap.value;
                            for (NSString *r in result)
                            {
                                if ([r isKindOfClass:[NSString class] ])
                                {
                                    NSLog(@"Join channel '%@'", r);
                                    [SWChannelModel joinChannel:r withCompletion:^(NSError *error)
                                    {
                                        NSLog(@"error = %@", error.localizedDescription);
                                    }];
                                }
                            }
                            //[self startRepaetingIfNotAlready];
                        }
                    }];
                }
                
            }
        };
        
        if (![NSThread isMainThread])
        {
            dispatch_sync(dispatch_get_main_queue(), ^
            {
                completion();
            });
        } else
        {
            completion();
        }
    }];
}

-(void)createUser:(FAUser*)user
{
    NSDictionary *thirdPartyUserData = user.thirdPartyUserData;
    NSString *firstName = thirdPartyUserData[@"first_name"];
    NSDictionary *picture = thirdPartyUserData[@"picture"];
    
    Firebase *setPhotoFB = [[Firebase alloc] initWithUrl:[NSString stringWithFormat:@"%@users/%@/profile/photo/", Objc_kROOT_FIREBASE, user.uid]];
    if (picture && [picture isKindOfClass:[NSDictionary class]])
    {
        NSDictionary *datas = picture[@"data"];
        NSString *photo = datas[@"url"];
        [setPhotoFB setValue:photo];
    } else
    {
        NSString *ID = thirdPartyUserData[@"id"];
        NSString *photo = [NSString stringWithFormat:@"http://graph.facebook.com/%@/picture?type=normal", ID];
        [setPhotoFB setValue:photo];
    }
    [[[Firebase alloc] initWithUrl:[NSString stringWithFormat:@"%@users/%@/profile/firstName/", Objc_kROOT_FIREBASE, user.uid]] setValue:firstName];
    
    NSUserDefaults *prefs = [NSUserDefaults standardUserDefaults];
    [prefs setBool:YES forKey:Objc_kNSUSERDEFAULTS_BOOLKEY_userIsLoggedIn];
    [prefs setObject:user.uid forKey:Objc_kNSUSERDEFAULTS_KEY_userId];
    [prefs synchronize];
    
    
    [[Mixpanel sharedInstance] createAlias:firstName forDistinctID:user.uid];
    [[Mixpanel sharedInstance] identify:user.uid];
    [[Mixpanel sharedInstance] track:@"Authentication Success"];
    
    [CocoaColaClassic RegisterRemoteNotifications];
    
}

- (IBAction)authButtonPress:(id)sender
{
    [self beginAuthWithFirebase];
}


-(void)alertView:(UIAlertView *)alertView clickedButtonAtIndex:(NSInteger)buttonIndex
{
    
}


-(void)viewWillDisappear:(BOOL)animated
{
//    if (repeatTimer)
//    {
//        [repeatTimer invalidate];
//        repeatTimer = nil;
//    }
}


@end
