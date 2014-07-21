//
//  ESViewController.m
//  Earshot
//
//  Created by Ethan Sherr on 4/9/14.
//  Copyright (c) 2014 Buildco. All rights reserved.
//

#import "ESViewController.h"
#import "Reachability.h"
#import "FCAppDelegate.h"
#import "ESTransponder.h"
#import "FCLiveBlurButton.h"
#import <MessageUI/MessageUI.h>
#define CHIRP_BEACON_TIME 10.0f

typedef enum
{
    NoInternetAlertStatusNone,
    NoInternetAlertStatusPeeking,
    NoInternetAlertStatusFull
} NoInternetAlertStatus;

typedef enum
{
    NoUsersStatusNone,
    NoUsersStatusPeeking,
    NoUsersStatusFull
} NoUsersStatus;

@interface ESViewController () <MFMessageComposeViewControllerDelegate>

@property (nonatomic) NSTimer *chirpBeaconTimer;
@property (nonatomic) UIPanGestureRecognizer *panGesture;
@property (nonatomic) NoInternetAlertStatus internetAlertStatus;
@property (nonatomic) NoUsersStatus usersAlertStatus;

//dialup stuff
@property (nonatomic) UILabel *noInternetLabel;
@property (nonatomic) BOOL dialUpCoordIsPluggedIn;
@property (strong, nonatomic) UIPanGestureRecognizer *dialUpPanGesture;
@property (nonatomic) UIView *dialUpView;
@property (nonatomic) CALayer *coordScene;
@property (nonatomic) CALayer *coord;
@property (nonatomic) CALayer *plug;
@property (nonatomic) CALayer *outRimPlug;
@property (nonatomic) CALayer *fullCoordMask;
@property (nonatomic) CGPoint lastOffset;
@property (nonatomic) CALayer *maskOfCoord;
@property (assign) CGPoint movementVector;
@property (strong, nonatomic) UIView *fadedOverView;
@property (strong, nonatomic) UIPanGestureRecognizer *fadedOverViewPan;
@property (strong, nonatomic) UITapGestureRecognizer *fadedOverViewTap;

//no users nearby stuff
@property (nonatomic, strong) UIView *noUsersNearbyPopup;
@property (nonatomic) UILabel *noUsersLabel;
@property (nonatomic) FCLiveBlurButton *composeBlurButton;
//@property (nonatomic) UILabel *elipseLabel;
//@property (nonatomic, strong) NSTimer *elipseTimer;
//@property (nonatomic) int numberOfElipses;

@end

@implementation ESViewController
@synthesize noInternetLabel;
@synthesize composeBarView;
@synthesize noInternetView;
@synthesize usersAlertStatus;
@synthesize internetAlertStatus;
@synthesize panGesture;
@synthesize lastOffset;
@synthesize fadedOverViewPan;
@synthesize fadedOverViewTap;

//dialup stuff
@synthesize dialUpView;
@synthesize coord;
@synthesize coordScene;
@synthesize plug;
@synthesize outRimPlug;
@synthesize movementVector;
@synthesize fullCoordMask;
@synthesize maskOfCoord;

//no users nearby stuff
@synthesize noUsersNearbyPopup;
@synthesize noUsersLabel;
@synthesize composeBlurButton;
//@synthesize numberOfElipses;
//@synthesize elipseTimer;
//@synthesize elipseLabel;

@synthesize fadedOverView;
@synthesize chirpBeaconTimer;

@synthesize numberOfPeopleBeingTracked;

- (void)viewDidLoad
{
    [super viewDidLoad];
    
//  actually it's ok to not have this.  listen to it on a per-view controller level, when necessary
//    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(noUsersNearbyEvent:) name:kTrackingNoUsersNearbyNotification object:nil];
//    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(usersNearbyEvent:) name:kTrackingUsersNearbyNotification object:nil];
    
    
    
}

-(void)viewDidAppear:(BOOL)animated
{
    [super viewDidAppear:animated];
    
    FCAppDelegate *appDelegate = (FCAppDelegate*) [UIApplication sharedApplication].delegate;
//    self.alertStatus = [appDelegate getNetworkStatus];
    
    [self updateNetworkStatus:[appDelegate getNetworkStatus]];
}


- (void)didReceiveMemoryWarning
{
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}


-(void)setComposeBarView:(PHFComposeBarView *)cBV
{
    [[NSNotificationCenter defaultCenter] removeObserver:self name:kReachabilityChangedNotification object:nil];
    
    composeBarView = cBV;
    
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(internetChangeEvent:) name:kReachabilityChangedNotification object:nil];
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(appEnteredForeground:) name:UIApplicationWillEnterForegroundNotification object:nil];
}


-(void)dealloc
{
    [[NSNotificationCenter defaultCenter] removeObserver:self name:kReachabilityChangedNotification object:nil];
    [[NSNotificationCenter defaultCenter] removeObserver:self name:UIApplicationWillEnterForegroundNotification object:nil];
//    [[NSNotificationCenter defaultCenter] removeObserver:self name:kTransponderEventTransponderDisabled object:nil];
//    
//    [[NSNotificationCenter defaultCenter] removeObserver:self name:kTrackingNoUsersNearbyNotification object:nil];
}

#pragma mark reachability callback (internet availability)
-(void)internetChangeEvent:(NSNotification*)notification
{
    
    Reachability* curReach = [notification object];
    [self updateNetworkStatus:curReach.currentReachabilityStatus];
    
}

-(void)cancelDialUpSceneIfNecessary
{
    if (internetAlertStatus == NoInternetAlertStatusFull)
    {
        self.internetAlertStatus = NoInternetAlertStatusPeeking;
    }
}

-(void)updateNetworkStatus:(NetworkStatus)status
{
    switch (status)
    {
        case NotReachable:
        {
            NSLog(@"NotReachable");
            //if no internet
            
            [self setInternetAlertStatus:NoInternetAlertStatusPeeking];
            
        }
            break;
            
        case ReachableViaWiFi:
        {
            NSLog(@"ReachableViaWiFi");
            [self setInternetAlertStatus:NoInternetAlertStatusNone];
        }
            break;
            
        case ReachableViaWWAN:
        {
            NSLog(@"ReachableViaWWAN");
            [self setInternetAlertStatus:NoInternetAlertStatusNone];
        }
            break;
    }
}




-(void)setInternetAlertStatus:(NoInternetAlertStatus)newAlertStatus
{
    if (self.dialUpCoordIsPluggedIn)
        return;
    
    [self.composeBarView setUserInteractionEnabled:(newAlertStatus == NoInternetAlertStatusNone)];
    
    if (newAlertStatus != NoInternetAlertStatusNone)
    {
        if (usersAlertStatus != NoUsersStatusNone)
        {
            [UIView animateWithDuration:0.6f delay:0.0f usingSpringWithDamping:0.6 initialSpringVelocity:0 options:UIViewAnimationOptionCurveLinear animations:^
             {
                 self.fadedOverView.alpha = 0.0f;
//                 [self.noUsersNearbyPopup setTransform:CGAffineTransformMakeTranslation(0, -self.composeBarViewFrame.size.height)];
                 self.noUsersNearbyPopup.alpha = 0.0f;
             } completion:^(BOOL finished)
             {
                 self.noUsersNearbyPopup.alpha = 1.0f;
                 [self.fadedOverView removeFromSuperview];
                 [self.noUsersNearbyPopup removeFromSuperview];
             }];
            usersAlertStatus = NoUsersStatusNone;
        }
    }
    
    [self.noInternetView setUserInteractionEnabled:NO];
    if (internetAlertStatus == NoInternetAlertStatusNone)
    {
        if (newAlertStatus == NoInternetAlertStatusPeeking)
        {
            [self.composeBarView.superview addSubview:self.noInternetView];
            [self.noInternetView setTransform:CGAffineTransformMakeTranslation(0, self.composeBarViewFrame.size.height)];
            
            [UIView animateWithDuration:0.6f delay:0.0f usingSpringWithDamping:0.6 initialSpringVelocity:0 options:UIViewAnimationOptionCurveLinear animations:^
            {
                [self.noInternetView setTransform:CGAffineTransformIdentity];
            } completion:^(BOOL finished)
            {
                [self.noInternetView setUserInteractionEnabled:YES];
            }];
        }
    }
    
    if (internetAlertStatus == NoInternetAlertStatusPeeking )
    {
        if (newAlertStatus == NoInternetAlertStatusNone)
        {
            
            [self.composeBarView.superview addSubview:self.noInternetView];
            [UIView animateWithDuration:0.6f delay:0.0f usingSpringWithDamping:0.6 initialSpringVelocity:0 options:UIViewAnimationOptionCurveLinear animations:^
             {
                 [self.noInternetView setTransform:CGAffineTransformMakeTranslation(0, self.composeBarViewFrame.size.height)];
             } completion:^(BOOL finished)
             {
                [self.noInternetView setUserInteractionEnabled:YES];
                [self checkOnUsersNearbyUpdateUI];
             }];
        }
        
        if (newAlertStatus == NoInternetAlertStatusFull)
        {

            UIView *superView = self.composeBarView.superview;
            UIView *fadedView = [superView viewWithTag:617];
            
            [superView insertSubview:self.fadedOverView belowSubview:fadedView];
            
            self.fadedOverView.alpha = 0.0f;
            [self.composeBarView.superview addSubview:self.noInternetView];
            [UIView animateWithDuration:0.6f delay:0.0f usingSpringWithDamping:0.6 initialSpringVelocity:0 options:UIViewAnimationOptionCurveLinear animations:^
             {
                 [self.noInternetView setTransform:CGAffineTransformMakeTranslation(0, -self.noInternetView.frame.size.height+self.composeBarViewFrame.size.height+20)];
                 self.fadedOverView.alpha = 1.0f;
             } completion:^(BOOL finished)
             {
                [self.noInternetView setUserInteractionEnabled:YES];
             }];
        }
    }
    
    if (internetAlertStatus == NoInternetAlertStatusFull)
    {
        if (newAlertStatus == NoInternetAlertStatusPeeking)
        {
            [self.composeBarView.superview addSubview:self.noInternetView];
            [UIView animateWithDuration:0.6f delay:0.0f usingSpringWithDamping:0.6 initialSpringVelocity:0 options:UIViewAnimationOptionCurveLinear animations:^
             {
                 self.fadedOverView.alpha = 0.0f;
                 [self.noInternetView setTransform:CGAffineTransformMakeTranslation(0, 0)];
             } completion:^(BOOL finished)
             {
                 [self.fadedOverView removeFromSuperview];
                 [self.noInternetView setUserInteractionEnabled:YES];
             }];
        }
        
        if (newAlertStatus == NoInternetAlertStatusNone)
        {
            [UIView animateWithDuration:1.2 delay:0.0f usingSpringWithDamping:0.8 initialSpringVelocity:0.0f options:UIViewAnimationOptionCurveLinear animations:^
            {                
                CGPoint xy = {169.08543, -98.268471};//{225.42157, -131.0097};
                self.coord.transform = CATransform3DMakeTranslation(xy.x, xy.y, 0);
                self.maskOfCoord.transform = CATransform3DMakeTranslation(xy.x, xy.y, 0);
            } completion:^(BOOL finished)
            {
                [UIView animateWithDuration:0.6f delay:0.7f usingSpringWithDamping:0.6 initialSpringVelocity:0 options:UIViewAnimationOptionCurveLinear animations:^
                 {
                     self.fadedOverView.alpha = 0.0f;
                     [self.noInternetView setTransform:CGAffineTransformMakeTranslation(0, self.composeBarViewFrame.size.height)];
                 } completion:^(BOOL finished)
                 {
                     [self.fadedOverView removeFromSuperview];
                     [self.noInternetView setUserInteractionEnabled:YES];
                     self.coord.transform = CATransform3DMakeTranslation(0,0, 0);
                     self.maskOfCoord.transform = CATransform3DMakeTranslation(0,0,0);
                     [self checkOnUsersNearbyUpdateUI];
                 }];
            }];
        }
    }
    
    internetAlertStatus = newAlertStatus;
}

-(void)checkOnUsersNearbyUpdateUI
{
    if (![FCUser owner].beacon.earshotUsers.count)
    {
        self.usersAlertStatus = NoUsersStatusFull;
    }
}

//-(void)elipseTimerAction
//{
//    NSString *elipses = @"";
//    for (int i = 0; i < numberOfElipses; i++)
//    {
//        elipses = [NSString stringWithFormat:@"%@.", elipses];
//    }
//    
//    [elipseLabel setText:elipses];
//    numberOfElipses = (numberOfElipses+1)%4;
//}

-(UIView*)noUsersNearbyPopup
{
    if (!noUsersNearbyPopup)
    {
        CGRect noUsersNearbyPopupRect = self.composeBarViewFrame;
        noUsersNearbyPopupRect.size.height += 155;//141;
        noUsersNearbyPopup = [[UIView alloc] initWithFrame:noUsersNearbyPopupRect];
    
        UIColor *userColor = [UIColor colorWithHexString:[[NSUserDefaults standardUserDefaults] objectForKey:@"color"]];
        [noUsersNearbyPopup setBackgroundColor:userColor];
        
        noUsersLabel = [self generateATopLabel];
        [noUsersLabel setText:@"Send Shortwave to a friend?"];
        CGFloat height = noUsersLabel.frame.size.height;
        [noUsersLabel sizeToFit];
        CGRect newFrame = noUsersLabel.frame;
        newFrame.size.height = height;
        newFrame.origin.x = (noUsersNearbyPopup.frame.size.width-newFrame.size.width)*0.5f;
        [noUsersLabel setFrame:newFrame];
        
//        elipseLabel = [[UILabel alloc] initWithFrame:CGRectMake(noUsersLabel.frame.size.width+noUsersLabel.frame.origin.x, 0, 50, 44)];
//        [elipseLabel setFont:noUsersLabel.font];
//        [elipseLabel setTextColor:[UIColor whiteColor]];
//        [elipseLabel setText:@""];
//        [elipseLabel setTextAlignment:NSTextAlignmentLeft];
        
        
        [noUsersNearbyPopup addSubview:noUsersLabel];
//        [noUsersNearbyPopup addSubview:elipseLabel];
        
        UIButton *invisibutton = [UIButton buttonWithType:UIButtonTypeCustom];
        [invisibutton setFrame:noUsersLabel.frame];
        [invisibutton addTarget:self action:@selector(searchingForOthersButtonAction:) forControlEvents:UIControlEventTouchUpInside];
        [noUsersNearbyPopup addSubview:invisibutton];
        
        UIPanGestureRecognizer *panUserAlertDown = [[UIPanGestureRecognizer alloc] initWithTarget:self action:@selector(panHandleUsersAlert:)];
        [noUsersNearbyPopup addGestureRecognizer:panUserAlertDown];
        
        UIView *darkUnderLayer = [[UIView alloc] initWithFrame:CGRectMake(
                                                                          0,
                                                                          noUsersLabel.frame.size.height,
                                                                          noUsersNearbyPopup.frame.size.width,
                                                                          -noUsersLabel.frame.size.height+noUsersNearbyPopup.frame.size.height)];
        [darkUnderLayer setBackgroundColor:self.darkOpacity];
        [noUsersNearbyPopup addSubview:darkUnderLayer];
        
        
        CGFloat buttonDim = 69.0f;//142*0.5f;
        CGFloat diff = 458-568-20;
        
        
        composeBlurButton = [[FCLiveBlurButton alloc] initWithFrame:CGRectMake(
                                                      (noUsersNearbyPopup.frame.size.width-buttonDim)*0.5f,
                                                      noUsersNearbyPopupRect.size.height+diff,
                                                      //((noUsersNearbyPopup.frame.size.height-noUsersLabel.frame.size.height)-buttonDim)*0.5f+noUsersLabel.frame.size.height*0.5f + 15,//noUsersLabel.frame.size.height + //+25*0.5f,//
                                                      buttonDim,buttonDim)];
        

        
        CGFloat iconDim = 28;
        UIImageView *smsImageView = [[UIImageView alloc] initWithFrame:CGRectMake((buttonDim-iconDim)*0.5f, (buttonDim-iconDim)*0.5f+2, iconDim, iconDim)];
        [smsImageView setContentMode:UIViewContentModeScaleAspectFit];
        [smsImageView setImage:[UIImage imageNamed:@"message.png"]];
        [composeBlurButton addSubview:smsImageView];
        [composeBlurButton setRadius:buttonDim*0.5f];
        [composeBlurButton performSelector:@selector(invalidatePressedLayer) withObject:nil afterDelay:0.5];
        [composeBlurButton addTarget:self action:@selector(composeBlurButtonAction) forControlEvents:UIControlEventTouchUpInside];
        
        [noUsersNearbyPopup addSubview:composeBlurButton];
        
//        UILabel *sendEarshotToFriend = [[UILabel alloc] initWithFrame:CGRectMake(0, composeBlurButton.frame.size.height+composeBlurButton.frame.origin.y+14, noUsersNearbyPopup.frame.size.width, 12)];
//        [sendEarshotToFriend setTextColor:[UIColor whiteColor]];
//        [sendEarshotToFriend setTextAlignment:NSTextAlignmentCenter];
//        [sendEarshotToFriend setText:@"Send Earshot to a friend?"];
//        
//        [sendEarshotToFriend setFont:[UIFont systemFontOfSize:12.0f] ];
//        [noUsersNearbyPopup addSubview:sendEarshotToFriend];
    }
    return noUsersNearbyPopup;
}
-(void)searchingForOthersButtonAction:(UIButton*)button
{
    if (internetAlertStatus == NoInternetAlertStatusNone)
    {
        if (usersAlertStatus == NoUsersStatusFull)
        {
            self.usersAlertStatus = NoUsersStatusPeeking;
        } else
        if (usersAlertStatus == NoUsersStatusPeeking)
        {
            self.usersAlertStatus = NoUsersStatusFull;
        }
    }
}

#pragma mark noInternetView creation methods
-(UIView*)noInternetView
{
    if (!noInternetView)
    {
        CGRect noInternetViewRect = self.composeBarViewFrame;
        noInternetViewRect.size.height += 178+40;
        noInternetView = [[UIView alloc] initWithFrame:noInternetViewRect];
        
        
        NSString *coiov = [[NSUserDefaults standardUserDefaults] objectForKey:@"color"];
        
        if (!coiov)
        {
            coiov = @"FFFFFF";
        }
        
        UIColor *userColor = [UIColor colorWithHexString:coiov];
        [noInternetView setBackgroundColor:userColor];
        
        
        noInternetLabel = [self generateATopLabel];
//        [noInternetLabel setTextAlignment:NSTextAlignmentCenter];
//        [noInternetLabel setBackgroundColor:[UIColor clearColor]];
//        [noInternetLabel setTextColor:[UIColor whiteColor]];
        [self setNoInternetLabelTextRandomly];
        [noInternetView addSubview:noInternetLabel];
        
        UIButton *invisiButton = [UIButton buttonWithType:UIButtonTypeCustom];
        [invisiButton setFrame:noInternetLabel.frame];
        [invisiButton setBackgroundColor:[UIColor clearColor]];
        [invisiButton addTarget:self action:@selector(openNoInternetAlert:) forControlEvents:UIControlEventTouchUpInside];
        [noInternetView addSubview:invisiButton];
        
        
        panGesture = [[UIPanGestureRecognizer alloc] initWithTarget:self action:@selector(panHandle:)];
        [noInternetView addGestureRecognizer:panGesture];
        
        UIView *dialUpScene = [self setupDialUpSceneWithDistance:150 containingSize:CGSizeMake(noInternetView.frame.size.width, noInternetView.frame.size.height-noInternetLabel.frame.size.height-20)];
        [panGesture requireGestureRecognizerToFail:self.dialUpPanGesture];
        
        CGRect dialUpSceneRect = dialUpScene.frame;
        dialUpSceneRect.origin.y = noInternetLabel.frame.origin.y+noInternetLabel.frame.size.height;
        [dialUpScene setFrame:dialUpSceneRect];
        [dialUpScene setBackgroundColor:self.darkOpacity];
        [noInternetView addSubview:dialUpScene];
        
    }
    
    return noInternetView;
}
-(UIColor*)darkOpacity
{
    return [UIColor colorWithRed:0.2 green:0.2 blue:0.2 alpha:0.0f];//[UIColor colorWithRed:0.2 green:0.2 blue:0.2 alpha:0.05f];
}
-(UILabel*)generateATopLabel
{
    UILabel *aLabel = [[UILabel alloc] initWithFrame:self.composeBarView.bounds];
    [aLabel setTextAlignment:NSTextAlignmentCenter];
    [aLabel setBackgroundColor:[UIColor clearColor]];
    [aLabel setTextColor:[UIColor whiteColor]];
    return aLabel;
}

-(void)setNoInternetLabelTextRandomly
{
    [self setNoInternetLabelTextRandomlyWithStill:NO];
}
-(void)setNoInternetLabelTextRandomlyWithStill:(BOOL)still
{
    NSString *stillString = @"";
    if (still)
    {
        NSArray *modifiers = @[@"really ", @"still ", @"surely ", @"absolutely ", @"kinda ", @"positively ", @"frankly ", @"sir/madam, ", @"unapologetically "];
        int modifierIndex = esRandomNumberIn(0, modifiers.count);
        
        stillString = [modifiers objectAtIndex:modifierIndex];
    }

    NSArray *thingsToSay = @[
                             [NSString stringWithFormat:@"You %@have no internets.", stillString],
                             [NSString stringWithFormat:@"You %@have no interwebs.", stillString]
                            ];
    int index = esRandomNumberIn(0, thingsToSay.count);
    [noInternetLabel setText:[thingsToSay objectAtIndex:index]];
}
#pragma mark UI callbacks for noInternetView

-(void)panHandleUsersAlert:(UIPanGestureRecognizer*)pan
{
   
    CGFloat yVelocity = [pan velocityInView:self.noUsersNearbyPopup].y;
    if (yVelocity < 0)
    {
        [self setUsersAlertStatus:NoUsersStatusFull];
    } else
    {
        [self setUsersAlertStatus:NoUsersStatusPeeking];
    }
}
-(void)panHandle:(UIPanGestureRecognizer*)pan
{
    CGFloat yVelocity = [pan velocityInView:self.noInternetView].y;
    if (yVelocity < 0)
    {
        [self setInternetAlertStatus:NoInternetAlertStatusFull];
    } else
    {
        [self setInternetAlertStatus:NoInternetAlertStatusPeeking];
    }
}
-(void)openNoInternetAlert:(UIButton*)button
{
    if (internetAlertStatus == NoInternetAlertStatusFull)
    {
        [self setInternetAlertStatus:NoInternetAlertStatusPeeking];
    } else
    {
        [self setInternetAlertStatus:NoInternetAlertStatusFull];
    }
}






#pragma mark DialUp scene
-(UIView*)setupDialUpSceneWithDistance:(CGFloat)distance containingSize:(CGSize)containingSize
{
    
    self.dialUpView = [[UIView alloc] initWithFrame:CGRectMake(0, 0, containingSize.width, containingSize.height)];
    
    //425, 235 - wxh ratio
    CGSize expectedSize = {425, 245};//235};//185};//235};//285};
    CGFloat graphicScaleRatio = 1/2.0f;
    
    CGPoint expectedDirection = {expectedSize.width, expectedSize.height+2};
    CGFloat magnitude = sqrtf(expectedDirection.x*expectedDirection.x + expectedDirection.y*expectedDirection.y);
    self.movementVector = CGPointMake(expectedDirection.x/magnitude, -expectedDirection.y/magnitude);
    
    
    CGRect sceneRect = CGRectMake(0, 0, distance, distance*expectedSize.height/expectedSize.width);
    sceneRect.origin.x = (self.dialUpView.frame.size.width-sceneRect.size.width)*0.5f;
    sceneRect.origin.y = (self.dialUpView.frame.size.height-sceneRect.size.height)*0.5f;
    
    
    UIView *boundsRect = [[UIView alloc] initWithFrame:sceneRect];
    [boundsRect setBackgroundColor:[UIColor clearColor]];
    [self.dialUpView addSubview:boundsRect];
    

    UIImage *_plugImg = [UIImage imageNamed:@"plug.png"];//[UIImage imageNamed:@"Phone-cord-export-02.png"];
    UIImage *_coordImg = [UIImage imageNamed:@"cord.png"];//[UIImage imageNamed:@"Phone-cord-export-03.png"];
    UIImage *_mask = [UIImage imageNamed:@"plugmask.png"];//[UIImage imageNamed:@"Phone-cord-export-04.png"];
    UIImage *_coordMask = [UIImage imageNamed:@"cordmask.png"];
    UIImage *_outRimPlug = [UIImage imageNamed:@"plugline.png"];

    CGFloat yShiftForPlugThings = 3.0f;
    CGFloat forPlugScale = 1.05f;
    CGSize plugImageSize = {_plugImg.size.width*graphicScaleRatio*forPlugScale, _plugImg.size.height*graphicScaleRatio*forPlugScale};
        CGSize outRimPlugImageSize = {_outRimPlug.size.width*graphicScaleRatio*forPlugScale, _outRimPlug.size.height*graphicScaleRatio*forPlugScale};
    
    CGSize coordImageSize = {_coordImg.size.width*graphicScaleRatio, _coordImg.size.height*graphicScaleRatio};
    CGSize maskImageSize = {_mask.size.width*graphicScaleRatio*forPlugScale, _mask.size.height*graphicScaleRatio*forPlugScale};
    CGSize coordMaskImageSize = {_coordMask.size.width*graphicScaleRatio, _coordMask.size.height*graphicScaleRatio};


    
    plug = [CALayer layer];
    [plug setContentsGravity:kCAGravityResizeAspectFill];
    plug.contentsScale = [UIScreen mainScreen].scale;
    plug.contents = (id)_plugImg.CGImage;
    CGRect plugFrame = CGRectMake(0, 0, plugImageSize.width, plugImageSize.height);
    plugFrame.origin.x = (sceneRect.origin.x+sceneRect.size.width) - plugFrame.size.width*0.5f;
    plugFrame.origin.y = (sceneRect.origin.y) - plugFrame.size.height*0.5f;//upper right
    plugFrame.origin.y -= yShiftForPlugThings;
    plug.frame = plugFrame;
    
    outRimPlug = [CALayer layer];
    [outRimPlug setContentsGravity:kCAGravityResizeAspectFill];
    outRimPlug.contentsScale = [UIScreen mainScreen].scale;
    outRimPlug.contents = (id)_outRimPlug.CGImage;
    CGRect outRimPlugFrame = CGRectMake(0, 0, outRimPlugImageSize.width, outRimPlugImageSize.height);
    outRimPlugFrame.origin.x = (sceneRect.origin.x+sceneRect.size.width) - outRimPlugFrame.size.width*0.5f;
    outRimPlugFrame.origin.y = (sceneRect.origin.y) - outRimPlugFrame.size.height*0.5f;//upper right
    outRimPlugFrame.origin.y -= yShiftForPlugThings;
    outRimPlug.frame = outRimPlugFrame;
    
    
    coordScene = [CALayer layer];
    [coordScene setFrame:dialUpView.bounds];
    
    coord = [CALayer layer];
    [coord setContentsGravity:kCAGravityResizeAspectFill];
    coord.contentsScale = [UIScreen mainScreen].scale;
    coord.contents = (id)_coordImg.CGImage;
    CGRect coordFrame = CGRectMake(0, 0, coordImageSize.width, coordImageSize.height);
    coordFrame.origin.x = sceneRect.origin.x - coordFrame.size.width;
    coordFrame.origin.y = sceneRect.origin.y + sceneRect.size.height;
    CGPoint offsetFromUpperRightCorner = CGPointMake(94*0.5f, 84*0.5f);//CGPointMake(248*graphicScaleRatio, 210*graphicScaleRatio);
    coordFrame.origin.x += offsetFromUpperRightCorner.x;
    coordFrame.origin.y -= offsetFromUpperRightCorner.y;
    coord.frame = coordFrame;
    
    
    maskOfCoord = [CALayer layer];
    [maskOfCoord setContentsGravity:kCAGravityResizeAspectFill];
    maskOfCoord.contentsScale = [UIScreen mainScreen].scale;
    maskOfCoord.contents = (id)_coordMask.CGImage;
    CGRect maskOfCoordFrame = CGRectMake(0, 0, coordMaskImageSize.width, coordMaskImageSize.height);
    maskOfCoordFrame.origin.x = sceneRect.origin.x - maskOfCoordFrame.size.width;
    maskOfCoordFrame.origin.y = sceneRect.origin.y + sceneRect.size.height;
    CGPoint offsetFromUpperRightCornerMask = CGPointMake(94*0.5f, 84*0.5f);//CGPointMake(248*graphicScaleRatio, 210*graphicScaleRatio);
    
    maskOfCoordFrame.origin.x += offsetFromUpperRightCornerMask.x;
    maskOfCoordFrame.origin.y -= offsetFromUpperRightCornerMask.y;
    
    maskOfCoordFrame.origin.x -= plugFrame.origin.x;
    maskOfCoordFrame.origin.y -= plugFrame.origin.y;
    
//    maskOfCoordFrame.origin.x += -2;
//    maskOfCoordFrame.origin.y -= -2;
    
    //add walls to the maskOfCoord
    {
        CGFloat targetWidth = 250;
        CGFloat targetHeight = 150;
        CALayer *upper = [CALayer layer];
        [upper setBackgroundColor:[UIColor blackColor].CGColor];
        upper.frame = CGRectMake(maskOfCoordFrame.size.width-targetWidth, -targetHeight, targetWidth, targetHeight);
        [maskOfCoord addSublayer:upper];
        
        CALayer *right = [CALayer layer];
        [right setBackgroundColor:[UIColor blackColor].CGColor];
        right.frame = CGRectMake(maskOfCoordFrame.size.width, -targetHeight, targetWidth, targetHeight*2);
        [maskOfCoord addSublayer:right];
    }
    
    maskOfCoord.frame = maskOfCoordFrame;
    [plug setMask:maskOfCoord];
    
    
    
    fullCoordMask = [CALayer layer];
    CGRect fullCoordMaskFrame = coordScene.bounds;
    fullCoordMaskFrame.origin.x -= 2;
    fullCoordMaskFrame.origin.y += 2;//shift that mask  just a bit so it does not disapear the edge of the socket
    fullCoordMaskFrame.origin.y -= yShiftForPlugThings;
    fullCoordMask.frame = fullCoordMaskFrame;
    
    [fullCoordMask setBackgroundColor:[UIColor clearColor].CGColor];
    
    
    CALayer *coordMask = [CALayer layer];
    [coordMask setContentsGravity:kCAGravityResizeAspectFill];
    coordMask.contents = (id)_mask.CGImage;
    coordMask.contentsScale = [UIScreen mainScreen].scale;
    CGRect coordMaskFrame = {0,0,maskImageSize.width, maskImageSize.height};
    coordMaskFrame.origin.x = plug.frame.origin.x + plug.superlayer.frame.origin.x;
    coordMaskFrame.origin.y = plug.frame.origin.y + plug.superlayer.frame.origin.y;
    coordMask.frame = coordMaskFrame;
    
    CAShapeLayer *shapeLayer = [CAShapeLayer layer];
    {
        //draw mask shape extended
        [shapeLayer setFrame:coordScene.bounds];
        [shapeLayer setStrokeColor:[UIColor blackColor].CGColor];
        [shapeLayer setLineWidth:1.0f];
        [shapeLayer setFillColor:[UIColor blackColor].CGColor];
        
        CGFloat topOffset = 16*graphicScaleRatio;
        CGFloat rightOffset = 14*graphicScaleRatio;
        
        CGPoint upperLeft = {coordMask.frame.origin.x, coordMask.frame.origin.y+topOffset};
        CGPoint lowerRight = {coordMask.frame.origin.x+coordMask.frame.size.width-rightOffset, coordMask.frame.origin.y+coordMask.frame.size.height};
        
        UIBezierPath *path = [UIBezierPath bezierPath];
        [path moveToPoint:upperLeft];
        [path addLineToPoint:lowerRight];
        
        [path addLineToPoint:CGPointMake(lowerRight.x, lowerRight.y+500)];
        [path addLineToPoint:CGPointMake(0, lowerRight.y+500)];
        [path addLineToPoint:CGPointMake(0, upperLeft.y)];
        [path addLineToPoint:upperLeft];
        
        [shapeLayer setPath:path.CGPath];
    }
    
    
    [self.dialUpView.layer addSublayer:plug];
    [self.dialUpView.layer addSublayer:outRimPlug];
    
    [self.dialUpView.layer addSublayer:coordScene];
    [coordScene addSublayer:coord];
    [fullCoordMask addSublayer:coordMask];
    [fullCoordMask addSublayer:shapeLayer];
    [coordScene setMask:fullCoordMask];
    
    self.dialUpPanGesture = [[UIPanGestureRecognizer alloc] initWithTarget:self action:@selector(dialUpPan:)];
    [self.dialUpView addGestureRecognizer:self.dialUpPanGesture];
    
    return self.dialUpView;
    
}

-(void)dialUpPan:(UIPanGestureRecognizer*)pan
{
    CGPoint translation = [pan translationInView:self.dialUpView];

    CGPoint deltaDirection = {translation.x - lastOffset.x, translation.y - lastOffset.y};
    CGFloat deltaMagnitude = sqrtf(deltaDirection.x*deltaDirection.x + deltaDirection.y*deltaDirection.y);
    
    switch ((int)pan.state)
    {

        case UIGestureRecognizerStateBegan:
        {

        }
            break;
        case UIGestureRecognizerStateChanged:
        {
            [CATransaction begin];
            [CATransaction setDisableActions:YES];
//            CGPoint xy = {translation.x*movementVector.x*1.5, translation.x*movementVector.y*1.5};
            CGPoint xy = {lastOffset.x + deltaMagnitude*movementVector.x*1.8f,
                          lastOffset.y + deltaMagnitude*movementVector.y*1.8f};
            
            
            CGPoint maxPosition = {184.95949362360801, -107.49410570595572};
            //{184.95949362360801, -107.49410570595572}
            if (xy.x >= maxPosition.x)
            {
                xy = maxPosition;
            }
            
            if (xy.x >= 165 && self.dialUpCoordIsPluggedIn)
            {
                //apply no transform
            } else
            if (xy.x >= 165 && !self.dialUpCoordIsPluggedIn)
            {
                self.dialUpCoordIsPluggedIn = YES;
                self.maskOfCoord.transform = CATransform3DMakeTranslation(xy.x, xy.y, 0);
                self.coord.transform = CATransform3DMakeTranslation(xy.x, xy.y, 0);
                //oh ok.  just this onc tho
            } else
            {
                self.dialUpCoordIsPluggedIn = NO;
                self.maskOfCoord.transform = CATransform3DMakeTranslation(xy.x, xy.y, 0);
                self.coord.transform = CATransform3DMakeTranslation(xy.x, xy.y, 0);
            }
            [CATransaction commit];
        }
        break;
            
        case UIGestureRecognizerStateEnded:
        {
            if (self.dialUpCoordIsPluggedIn)
            {
                [self.noInternetLabel setText:@"Checking your connection"];
                //it is stuck now!
                [self.noInternetView setUserInteractionEnabled:NO];
                [self performSelector:@selector(unStuckTheDialUpCoord) withObject:nil afterDelay:1.5f];
            }
            else
            {
                [UIView animateWithDuration:1.8f delay:0.0f usingSpringWithDamping:1.2f initialSpringVelocity:0.0f options:UIViewAnimationOptionCurveLinear animations:^
                 {
                     //                [CATransaction begin];
                     //                [CATransaction setDisableActions:YES];
                     self.coord.transform = CATransform3DMakeTranslation(0,0,0);
                     self.maskOfCoord.transform = CATransform3DMakeTranslation(0,0,0);
                     //                [CATransaction commit];
                 } completion:^(BOOL finished)
                 {
                 }];
            }
        }
        break;
            
        lastOffset = translation;
    }
}
-(void)unStuckTheDialUpCoord
{
    self.dialUpCoordIsPluggedIn = NO;
    
    FCAppDelegate *appDelegat = (FCAppDelegate*)[UIApplication sharedApplication].delegate;
    if (appDelegat.getNetworkStatus != NotReachable)
    {
        [self updateNetworkStatus:appDelegat.getNetworkStatus];
        return;
    }

    [UIView animateWithDuration:1.8f delay:0.0f usingSpringWithDamping:1.2f initialSpringVelocity:0.0f options:UIViewAnimationOptionCurveLinear animations:^
     {
         //                [CATransaction begin];
         //                [CATransaction setDisableActions:YES];
         self.coord.transform = CATransform3DMakeTranslation(0,0,0);
         self.maskOfCoord.transform = CATransform3DMakeTranslation(0,0,0);
         //                [CATransaction commit];
     } completion:^(BOOL finished)
     {
        [self.noInternetView setUserInteractionEnabled:YES];
         [self setNoInternetLabelTextRandomlyWithStill:YES];
     }];
}


-(void)setComposeBarWithRandomHint
{
    FCAppDelegate *appDelegate = (FCAppDelegate*)[UIApplication sharedApplication].delegate;
    NSString *randomSaying = [appDelegate getRandomMessageInputHint];
    [self.composeBarView.placeholderLabel setText:randomSaying];
}

-(void)appEnteredForeground:(NSNotification*)notification
{
    [self setComposeBarWithRandomHint];
}

//callback for when something got disabled in our bluetooth stack

-(void)esTransponderStackFailed:(NSNotification*)notification
{
    [self performSegueWithIdentifier:@"fail" sender:self];
}






-(void)setUsersAlertStatus:(NoUsersStatus)newUsersAlertStatus
{//ui change, do not ever do this
    return;
    if (IS_ON_SIMULATOR)
    {
        return;
    }
    if (usersAlertStatus == NoUsersStatusNone)
    {
        if (newUsersAlertStatus == NoUsersStatusFull)
        {
            //order of conditions is important, ...must have noUsersNearbyPopup AFTER composeBarView is set
            if ( self.composeBarView.superview && !self.noUsersNearbyPopup.superview)
            {
                UIView *superView = self.composeBarView.superview;
                UIView *fadedView = [superView viewWithTag:617];
                
                [superView insertSubview:self.fadedOverView belowSubview:fadedView];
                self.fadedOverView.alpha = 0.0f;
                [self.composeBarView.superview addSubview:noUsersNearbyPopup];
///wait please

                [self.noUsersNearbyPopup setTransform:CGAffineTransformMakeTranslation(0, -noUsersLabel.frame.size.height)];
                [UIView animateWithDuration:0.6f delay:0.0f usingSpringWithDamping:0.6 initialSpringVelocity:0 options:UIViewAnimationOptionCurveLinear animations:^
                 {
                     self.fadedOverView.alpha = 1.0f;
                     [self.noUsersNearbyPopup setTransform:CGAffineTransformMakeTranslation(0, -self.noUsersNearbyPopup.frame.size.height+self.composeBarViewFrame.size.height+20)];
                 } completion:^(BOOL finished)
                 {
                     [self.noUsersNearbyPopup setUserInteractionEnabled:YES];
                 }];
            } else{//invalid, just return do not assign
                return;
            }
            
        }
    }
    
    if (usersAlertStatus == NoUsersStatusPeeking)
    {
        if (newUsersAlertStatus == NoUsersStatusNone)
        {
            [UIView animateWithDuration:0.6f delay:0.0f usingSpringWithDamping:0.6 initialSpringVelocity:0 options:UIViewAnimationOptionCurveLinear animations:^
             {
                 self.fadedOverView.alpha = 0.0f;
                 [self.noUsersNearbyPopup setTransform:CGAffineTransformMakeTranslation(0, -self.composeBarViewFrame.size.height)];
                 
             } completion:^(BOOL finished)
             {
                 [self.fadedOverView removeFromSuperview];
                 [self.noUsersNearbyPopup removeFromSuperview];
             }];
        }
        
        if (newUsersAlertStatus == NoUsersStatusFull)
        {
            //order of conditions is important, ...must have noUsersNearbyPopup AFTER composeBarView is set
            UIView *superView = self.composeBarView.superview;
            UIView *fadedView = [superView viewWithTag:617];
            
            [superView insertSubview:self.fadedOverView belowSubview:fadedView];
            
            self.fadedOverView.alpha = 0.0f;
            [self.composeBarView.superview addSubview:noUsersNearbyPopup];
            ///wait please
            
            [self.noUsersNearbyPopup setTransform:CGAffineTransformMakeTranslation(0, -noUsersLabel.frame.size.height)];
            [UIView animateWithDuration:0.6f delay:0.0f usingSpringWithDamping:0.6 initialSpringVelocity:0 options:UIViewAnimationOptionCurveLinear animations:^
             {
                 self.fadedOverView.alpha = 1.0f;
                 [self.noUsersNearbyPopup setTransform:CGAffineTransformMakeTranslation(0, -self.noUsersNearbyPopup.frame.size.height+self.composeBarViewFrame.size.height+20)];
             } completion:^(BOOL finished)
             {
                 [self.noUsersNearbyPopup setUserInteractionEnabled:YES];
             }];
        }
    }
    
    if (usersAlertStatus == NoUsersStatusFull)
    {
        if (newUsersAlertStatus == NoUsersStatusNone)
        {
            [UIView animateWithDuration:0.6f delay:0.0f usingSpringWithDamping:0.6 initialSpringVelocity:0 options:UIViewAnimationOptionCurveLinear animations:^
             {
                 self.fadedOverView.alpha = 0.0f;
                 [self.noUsersNearbyPopup setTransform:CGAffineTransformMakeTranslation(0, self.composeBarViewFrame.size.height)];

             } completion:^(BOOL finished)
             {
                 [self.fadedOverView removeFromSuperview];
                 [noUsersNearbyPopup removeFromSuperview];
             }];
        }
        
        if (newUsersAlertStatus == NoUsersStatusPeeking)
        {
            [UIView animateWithDuration:0.6f delay:0.0f usingSpringWithDamping:0.6 initialSpringVelocity:0 options:UIViewAnimationOptionCurveLinear animations:^
             {
                 [self.noUsersNearbyPopup setTransform:CGAffineTransformMakeTranslation(0, 0)];
                 self.fadedOverView.alpha = 0.0f;
                 
                 
             } completion:^(BOOL finished)
             {
                 [self.fadedOverView removeFromSuperview];
             }];
        }
    }
    
    //setup chirpbeacon timer 10 seconds if necessary
    usersAlertStatus = newUsersAlertStatus;
    if (usersAlertStatus != NoUsersStatusNone)
    {
        [self.composeBarView.textView resignFirstResponder];
        if (!self.chirpBeaconTimer.isValid)
        {
            chirpBeaconTimer = [NSTimer timerWithTimeInterval:CHIRP_BEACON_TIME target:[FCUser owner].beacon selector:@selector(chirpBeacon) userInfo:nil repeats:YES];
            [[NSRunLoop mainRunLoop] addTimer:chirpBeaconTimer forMode:NSDefaultRunLoopMode];
        }
//        if (!self.elipseTimer.isValid)
//        {
//            elipseTimer = [NSTimer timerWithTimeInterval:0.35f target:self selector:@selector(elipseTimerAction) userInfo:nil repeats:YES];
//            [[NSRunLoop mainRunLoop] addTimer:elipseTimer forMode:NSDefaultRunLoopMode];
//        }
    } else
    {
//        [elipseTimer invalidate];
        [chirpBeaconTimer invalidate];
        chirpBeaconTimer = nil;
//        elipseTimer = nil;
    }
}

//text message compose
-(void)composeBlurButtonAction
{
    if([MFMessageComposeViewController canSendText])
    {
        Mixpanel *mixpanel = [Mixpanel sharedInstance];
        NSString *whatClass = NSStringFromClass([self class]);
        [mixpanel track:@"Text message button clicked" properties:@{@"fromView": whatClass}];
        
        NSArray *recipents = nil;
        NSString *message = @"You should get on Shortwave! getshortwave.com";
        
        MFMessageComposeViewController *messageController = [[MFMessageComposeViewController alloc] init];
        messageController.messageComposeDelegate = self;
        [messageController setRecipients:recipents];
        [messageController setBody:message];
        //         [self presentModalViewController:messageController animated:YES];
        [self presentViewController:messageController animated:YES completion:^{}];
    }
}

-(void)messageComposeViewController:(MFMessageComposeViewController *)controller didFinishWithResult:(MessageComposeResult)result
{
    switch (result) {
        case MessageComposeResultCancelled:
        {
            
        }
            break;
        case MessageComposeResultFailed:
        {
            
        }
            break;
        case MessageComposeResultSent:
        {
            Mixpanel *mixpanel = [Mixpanel sharedInstance];
            NSString *whatClass = NSStringFromClass([self class]);
            [mixpanel track:@"Text message sent" properties:@{@"fromView": whatClass}];
        }
            break;
    }
    [controller dismissViewControllerAnimated:YES completion:^{}];
}

-(UIView*)fadedOverView
{
    if (!fadedOverView)
    {
        fadedOverView = [[UIView alloc] initWithFrame:CGRectMake(0, 64, [UIScreen mainScreen].bounds.size.width, [UIScreen mainScreen].bounds.size.height)];
        [fadedOverView setBackgroundColor:[UIColor colorWithWhite:1.0f alpha:0.8f]];
        
        
        fadedOverViewPan = [[UIPanGestureRecognizer alloc] initWithTarget:self action:@selector(fadedOverViewPanAction:)];
        fadedOverViewTap = [[UITapGestureRecognizer alloc] initWithTarget:self action:@selector(fadedOverViewTapAction:)];
        [fadedOverView addGestureRecognizer:fadedOverViewPan];
        [fadedOverView addGestureRecognizer:fadedOverViewTap];
        [fadedOverViewTap requireGestureRecognizerToFail:fadedOverViewPan];
    }
    return fadedOverView;
}

-(void)fadedOverViewPanAction:(UIPanGestureRecognizer*)pan
{
    CGPoint vel = [pan velocityInView:fadedOverView];
    NSLog(@"pan! vel.y = %f", vel.y);
    if (vel.y > 0)
    {
        if (self.internetAlertStatus == NoInternetAlertStatusFull)
        {
            self.internetAlertStatus = NoInternetAlertStatusPeeking;
        }
//        else
        if (self.usersAlertStatus == NoUsersStatusFull)
        {
            self.usersAlertStatus = NoUsersStatusPeeking;
        }
        
    }
}
-(void)fadedOverViewTapAction:(UITapGestureRecognizer*)tap
{
    NSLog(@"tap!");
    if (tap.state == UIGestureRecognizerStateEnded)
    {
        if (self.internetAlertStatus == NoInternetAlertStatusFull)
        {
            self.internetAlertStatus = NoInternetAlertStatusPeeking;
        }
        else
        if (self.usersAlertStatus == NoUsersStatusFull)
        {
            self.usersAlertStatus = NoUsersStatusPeeking;
        }
    }
}

-(CGRect)composeBarViewFrame
{
//    CGRect rect = self.composeBarView.frame;
//    NSLog(@"composeBarViewFrame = %@", NSStringFromCGRect(rect));

    CGRect rect = CGRectMake(0, [UIScreen mainScreen].bounds.size.height-44, [UIScreen mainScreen].bounds.size.width, 44);
    return rect;
}

-(void)setNumberOfPeopleBeingTracked:(NSInteger)people
{
    if (!people)
    {
        if (internetAlertStatus == NoInternetAlertStatusNone)
        {
            [self setUsersAlertStatus:NoUsersStatusFull];
        }
    } else
    {
        if (usersAlertStatus == NoUsersStatusFull)
        {
            [self setUsersAlertStatus:NoUsersStatusNone];
        }
    }
    numberOfPeopleBeingTracked = people;
}
//when nobody is nearby
//-(void)noUsersNearbyEvent:(NSNotificationCenter*)notification
//{
//    if (internetAlertStatus == NoInternetAlertStatusNone)
//    {
//        [self setUsersAlertStatus:NoUsersStatusFull];
//    }
//}
//-(void)usersNearbyEvent:(NSNotificationCenter*)notification
//{
//    if (usersAlertStatus == NoUsersStatusFull)
//    {
//        [self setUsersAlertStatus:NoUsersStatusNone];
//    }
//}


@end
