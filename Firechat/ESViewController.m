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


typedef enum
{
    NoInternetAlertStatusNone,
    NoInternetAlertStatusPeeking,
    NoInternetAlertStatusFull
}NoInternetAlertStatus;

@interface ESViewController ()


@property (nonatomic) UIPanGestureRecognizer *panGesture;
@property (nonatomic) NoInternetAlertStatus alertStatus;

//dialup stuff
@property (nonatomic) BOOL dialUpCoordIsPluggedIn;
@property (strong, nonatomic) UIPanGestureRecognizer *dialUpPanGesture;
@property (nonatomic) UIView *dialUpView;
@property (nonatomic) CALayer *coordScene;
@property (nonatomic) CALayer *coord;
@property (nonatomic) CALayer *plug;
@property (nonatomic) CALayer *fullCoordMask;
@property (nonatomic) CGPoint lastOffset;
@property (assign) CGPoint movementVector;

@end

@implementation ESViewController
@synthesize composeBarView;
@synthesize noInternetView;
@synthesize alertStatus;
@synthesize panGesture;
@synthesize lastOffset;

//dialup stuff
@synthesize dialUpView;
@synthesize coord;
@synthesize coordScene;
@synthesize plug;
@synthesize movementVector;
@synthesize fullCoordMask;

- (void)viewDidLoad
{
    [super viewDidLoad];
    
    //setup event listening

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
}


-(void)dealloc
{
    [[NSNotificationCenter defaultCenter] removeObserver:self name:kReachabilityChangedNotification object:nil];
}

#pragma mark reachability callback (internte availability)
-(void)internetChangeEvent:(NSNotification*)notification
{
    
    Reachability* curReach = [notification object];
    [self updateNetworkStatus:curReach.currentReachabilityStatus];
    
}

-(void)cancelDialUpSceneIfNecessary
{
    if (alertStatus == NoInternetAlertStatusFull)
    {
        self.alertStatus = NoInternetAlertStatusPeeking;
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
            
            [self setAlertStatus:NoInternetAlertStatusPeeking];
            
        }
            break;
            
        case ReachableViaWiFi:
        {
            NSLog(@"ReachableViaWiFi");
            [self setAlertStatus:NoInternetAlertStatusNone];
        }
            break;
            
        case ReachableViaWWAN:
        {
            NSLog(@"ReachableViaWWAN");
            [self setAlertStatus:NoInternetAlertStatusNone];
        }
            break;
    }
}




-(void)setAlertStatus:(NoInternetAlertStatus)newAlertStatus
{
    if (self.dialUpCoordIsPluggedIn)
        return;
    
    [self.composeBarView setUserInteractionEnabled:(newAlertStatus == NoInternetAlertStatusNone)];
    
    [self.noInternetView setUserInteractionEnabled:NO];
    if (alertStatus == NoInternetAlertStatusNone)
    {
        if (newAlertStatus == NoInternetAlertStatusPeeking)
        {
            [self.composeBarView.superview addSubview:self.noInternetView];
            [self.noInternetView setTransform:CGAffineTransformMakeTranslation(0, self.composeBarView.frame.size.height)];
            
            [UIView animateWithDuration:0.6f delay:0.0f usingSpringWithDamping:0.6 initialSpringVelocity:0 options:UIViewAnimationOptionCurveLinear animations:^
            {
                [self.noInternetView setTransform:CGAffineTransformIdentity];
            } completion:^(BOOL finished)
            {
                [self.noInternetView setUserInteractionEnabled:YES];
            }];
        }
    }
    
    if (alertStatus == NoInternetAlertStatusPeeking)
    {
        if (newAlertStatus == NoInternetAlertStatusNone)
        {
            
            [self.composeBarView.superview addSubview:self.noInternetView];
            [UIView animateWithDuration:0.6f delay:0.0f usingSpringWithDamping:0.6 initialSpringVelocity:0 options:UIViewAnimationOptionCurveLinear animations:^
             {
                 [self.noInternetView setTransform:CGAffineTransformMakeTranslation(0, self.composeBarView.frame.size.height)];
             } completion:^(BOOL finished)
             {
                [self.noInternetView setUserInteractionEnabled:YES];
             }];
        }
        
        if (newAlertStatus == NoInternetAlertStatusFull)
        {
            [self.composeBarView.superview addSubview:self.noInternetView];
            [UIView animateWithDuration:0.6f delay:0.0f usingSpringWithDamping:0.6 initialSpringVelocity:0 options:UIViewAnimationOptionCurveLinear animations:^
             {
                 [self.noInternetView setTransform:CGAffineTransformMakeTranslation(0, -self.noInternetView.frame.size.height+self.composeBarView.frame.size.height+20)];
             } completion:^(BOOL finished)
             {
                [self.noInternetView setUserInteractionEnabled:YES];
             }];
        }
    }
    
    if (alertStatus == NoInternetAlertStatusFull)
    {
        if (newAlertStatus == NoInternetAlertStatusPeeking)
        {
            [self.composeBarView.superview addSubview:self.noInternetView];
            [UIView animateWithDuration:0.6f delay:0.0f usingSpringWithDamping:0.6 initialSpringVelocity:0 options:UIViewAnimationOptionCurveLinear animations:^
             {
                 [self.noInternetView setTransform:CGAffineTransformMakeTranslation(0, 0)];
             } completion:^(BOOL finished)
             {
                 [self.noInternetView setUserInteractionEnabled:YES];
             }];
        }
        
        if (newAlertStatus == NoInternetAlertStatusNone)
        {
            [UIView animateWithDuration:1.2 delay:0.0f usingSpringWithDamping:0.8 initialSpringVelocity:0.0f options:UIViewAnimationOptionCurveLinear animations:^
            {
                CGPoint xy = {169.08543, -98.268471};//{225.42157, -131.0097};
                self.coord.transform = CATransform3DMakeTranslation(xy.x, xy.y, 0);
            } completion:^(BOOL finished)
            {
                [UIView animateWithDuration:0.6f delay:0.7f usingSpringWithDamping:0.6 initialSpringVelocity:0 options:UIViewAnimationOptionCurveLinear animations:^
                 {
                     [self.noInternetView setTransform:CGAffineTransformMakeTranslation(0, self.composeBarView.frame.size.height)];
                 } completion:^(BOOL finished)
                 {
                     [self.noInternetView setUserInteractionEnabled:YES];
                     self.coord.transform = CATransform3DMakeTranslation(0,0, 0);
                 }];
            }];
        }
    }
    
    alertStatus = newAlertStatus;
}


#pragma mark noInternetView creation methods
-(UIView*)noInternetView
{
    if (!noInternetView)
    {
        CGRect noInternetViewRect = self.composeBarView.frame;
        noInternetViewRect.size.height += 178+40;
        noInternetView = [[UIView alloc] initWithFrame:noInternetViewRect];
        
        
        CGFloat h;
        CGFloat s;
        CGFloat b;
        CGFloat a;
        UIColor *userColor = [UIColor colorWithHexString:[[NSUserDefaults standardUserDefaults] objectForKey:@"color"]];
        [userColor getHue:&h saturation:&s brightness:&b alpha:&a];
        
        CGFloat red, green, blue, alpha;
        [userColor getRed:&red green:&green blue:&blue alpha:&alpha];
        UIColor *errorColor = [UIColor colorWithHue:h saturation:(s*0.15) brightness:(b*0.9) alpha:a];
        
        [noInternetView setBackgroundColor:errorColor];
        
        
        UILabel *noInternetLabel = [[UILabel alloc] initWithFrame:self.composeBarView.bounds];
        [noInternetLabel setTextAlignment:NSTextAlignmentCenter];
        [noInternetLabel setBackgroundColor:[UIColor clearColor]];
        [noInternetLabel setTextColor:[UIColor whiteColor]];
        [noInternetLabel setText:@"You have no internets."];
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
        [dialUpScene setBackgroundColor:[UIColor colorWithRed:0.2 green:0.2 blue:0.2 alpha:0.05f]];
        [noInternetView addSubview:dialUpScene];
        
        
    }
    
    return noInternetView;
}
#pragma mark UI callbacks for noInternetView
-(void)panHandle:(UIPanGestureRecognizer*)pan
{
    CGFloat yVelocity = [pan velocityInView:self.noInternetView].y;
    if (yVelocity < 0)
    {
        self.alertStatus = NoInternetAlertStatusFull;
    } else
    {
        self.alertStatus = NoInternetAlertStatusPeeking;
    }
}
-(void)openNoInternetAlert:(UIButton*)button
{
    if (alertStatus == NoInternetAlertStatusFull)
    {
        self.alertStatus = NoInternetAlertStatusPeeking;
    } else
    {
        self.alertStatus = NoInternetAlertStatusFull;
    }
}

#pragma mark DialUp scene
-(UIView*)setupDialUpSceneWithDistance:(CGFloat)distance containingSize:(CGSize)containingSize

{
    
    self.dialUpView = [[UIView alloc] initWithFrame:CGRectMake(0, 0, containingSize.width, containingSize.height)];
    
    //425, 235 - wxh ratio
    CGSize expectedSize = {425, 245};//235};//185};//235};//285};
    CGFloat graphicScaleRatio = 1/5.0f;
    
    CGPoint expectedDirection = {expectedSize.width, expectedSize.height+2};
    CGFloat magnitude = sqrtf(expectedDirection.x*expectedDirection.x + expectedDirection.y*expectedDirection.y);
    self.movementVector = CGPointMake(expectedDirection.x/magnitude, -expectedDirection.y/magnitude);
    
    
    CGRect sceneRect = CGRectMake(0, 0, distance, distance*expectedSize.height/expectedSize.width);
    sceneRect.origin.x = (self.dialUpView.frame.size.width-sceneRect.size.width)*0.5f;
    sceneRect.origin.y = (self.dialUpView.frame.size.height-sceneRect.size.height)*0.5f;
    
    
    UIView *boundsRect = [[UIView alloc] initWithFrame:sceneRect];
    [boundsRect setBackgroundColor:[UIColor clearColor]];
    [self.dialUpView addSubview:boundsRect];
    
    
    UIImage *plugImg = [[UIImage imageNamed:@"Phone-cord-export-02.png"] scaleByFactor:graphicScaleRatio*1.1f];
    UIImage *coordImg = [[UIImage imageNamed:@"Phone-cord-export-03.png"] scaleByFactor:graphicScaleRatio];
    UIImage *mask = [[UIImage imageNamed:@"Phone-cord-export-04.png"] scaleByFactor:graphicScaleRatio*1.1f];
    
    
    plug = [CALayer layer];
    plug.contentsScale = [UIScreen mainScreen].scale;
    plug.contents = (id)plugImg.CGImage;
    CGRect plugFrame = CGRectMake(0, 0, plugImg.size.width, plugImg.size.height);
    plugFrame.origin.x = (sceneRect.origin.x+sceneRect.size.width) - plugFrame.size.width*0.5f;
    plugFrame.origin.y = (sceneRect.origin.y) - plugFrame.size.height*0.5f;//upper right
    plug.frame = plugFrame;
    
    
    coordScene = [CALayer layer];
    [coordScene setFrame:dialUpView.bounds];
    
    coord = [CALayer layer];
    coord.contents = (id)coordImg.CGImage;
    coord.contentsScale = [UIScreen mainScreen].scale;
    CGRect coordFrame = CGRectMake(0, 0, coordImg.size.width, coordImg.size.height);
    coordFrame.origin.x = sceneRect.origin.x - coordFrame.size.width;
    coordFrame.origin.y = sceneRect.origin.y + sceneRect.size.height;
    CGPoint offsetFromUpperRightCorner = CGPointMake(248*graphicScaleRatio, 210*graphicScaleRatio);
    coordFrame.origin.x += offsetFromUpperRightCorner.x;
    coordFrame.origin.y -= offsetFromUpperRightCorner.y;
    coord.frame = coordFrame;
    
    
    
    fullCoordMask = [CALayer layer];
    CGRect fullCoordMaskFrame = coordScene.bounds;
    fullCoordMaskFrame.origin.x -= 2;
    fullCoordMaskFrame.origin.y += 2;//shift that mask  just a bit so it does not disapear the edge of the socket
    fullCoordMask.frame = fullCoordMaskFrame;
    
    [fullCoordMask setBackgroundColor:[UIColor clearColor].CGColor];
    
    
    CALayer *coordMask = [CALayer layer];
    coordMask.contents = (id)mask.CGImage;
    coordMask.contentsScale = [UIScreen mainScreen].scale;
    CGRect coordMaskFrame = {0,0,mask.size.width, mask.size.height};
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
    CGPoint deltaDirectionNormalized = {deltaDirection.x/deltaMagnitude, deltaDirection.y/deltaMagnitude};
    

    
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
            
            NSLog(@"xy = %@", NSStringFromCGPoint(xy));
            if (xy.x >= 165 && self.dialUpCoordIsPluggedIn)
            {
                //apply no transform
            } else
            if (xy.x >= 165 && !self.dialUpCoordIsPluggedIn)
            {
                self.dialUpCoordIsPluggedIn = YES;
                self.coord.transform = CATransform3DMakeTranslation(xy.x, xy.y, 0);
                //oh ok.  just this onc tho
            } else
            {
                self.coord.transform = CATransform3DMakeTranslation(xy.x, xy.y, 0);
            }
            [CATransaction commit];
        }
        break;
            
        case UIGestureRecognizerStateEnded:
        {
            if (self.dialUpCoordIsPluggedIn)
            {
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
         //                [CATransaction commit];
     } completion:^(BOOL finished)
     {
         [self.noInternetView setUserInteractionEnabled:YES];
     }];
}
@end
