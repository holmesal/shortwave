//
//  FCLandingPageViewController.m
//  Firechat
//
//  Created by Ethan Sherr on 3/17/14.
//  Copyright (c) 2014 Buildco. All rights reserved.
//

#import "FCLandingPageViewController.h"
#import "FCLiveBlurButton.h"
#import "FCAppDelegate.h"
#import "FCWallViewController.h"
typedef enum
{
    PanGestureDirectionNone,
    PanGestureDirectionUp,
    PanGestureDirectionDown,
    PanGestureDirectionLeft,
    PanGestureDirectionRight
}PanGestureDirection;

@interface FCLandingPageViewController () <UITableViewDataSource, UITableViewDelegate, UIAlertViewDelegate>

@property (nonatomic) BOOL hasBeenHereBefore;////this is to fade in the view after splash screen is gone


@property (weak, nonatomic) IBOutlet UILabel *attributionLabel;
@property (nonatomic) CGRect originalFrameForIcon;
@property (nonatomic) NSInteger selectedIconIndex;
@property (nonatomic) UIImageView *extractedImageViewOnDone;
@property (weak, nonatomic) IBOutlet UIView *welcomeView2;
@property (weak, nonatomic) IBOutlet FCLiveBlurButton *startTalkingBlurButton;

@property (nonatomic) PanGestureDirection panDirection;
@property (nonatomic) UIPanGestureRecognizer *panGesture;
@property (nonatomic) NSInteger colorIndex;

@property (nonatomic) CGPoint offsetOfTableViewAtStartOfVertical;
@property (nonatomic) BOOL stateChanged;

@property (weak, nonatomic) IBOutlet UIImageView *spinnerImageView;

@property (nonatomic) UITableView *iconTableView;
@property (weak, nonatomic) IBOutlet UIView *iconContainerView;
@property (nonatomic) NSInteger iconIndex;

@property (nonatomic) NSArray *icons;
@property (nonatomic) NSArray *colors;


@property (nonatomic) FirebaseSimpleLogin *authClient;
@property (weak, nonatomic) IBOutlet FCLiveBlurButton *doneBlurButton;

@end



@implementation FCLandingPageViewController
@synthesize welcomeView2;
@synthesize startTalkingBlurButton;

@synthesize hasBeenHereBefore;
@synthesize colorIndex;
@synthesize panDirection;

@synthesize iconIndex;

@synthesize icons;
@synthesize iconTableView;

@synthesize doneBlurButton;
@synthesize colors;


-(BOOL)userIsLoggedIn
{
    NSLog(@"userIsLoggedIn = %@", ([[NSUserDefaults standardUserDefaults] boolForKey:@"isLoggedIn"] ? @"YES": @"NO"));
    return [[NSUserDefaults standardUserDefaults] boolForKey:@"isLoggedIn"];
}
-(void)setUserIsLoggedIn:(BOOL)b
{
    [[NSUserDefaults standardUserDefaults] setBool:b forKey:@"isLoggedIn"];
    [[NSUserDefaults standardUserDefaults] synchronize];
}


- (void)viewDidLoad
{
    [super viewDidLoad];
    
    [UIView animateWithDuration:40.0f
                          delay:0.0f
                        options:UIViewAnimationOptionRepeat | UIViewAnimationOptionCurveLinear
                     animations:^{
                         self.spinnerImageView.transform = CGAffineTransformMakeRotation(M_PI);
                     }
                     completion:nil
     ];
    
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(appDidBecomeActive:) name:UIApplicationDidBecomeActiveNotification object:nil];
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(appDidEnterForeground:) name:UIApplicationWillEnterForegroundNotification object:nil];
    
    
    //hide welcomeVIew2
    [welcomeView2 setBackgroundColor:[UIColor clearColor]];
    [welcomeView2 setHidden:YES];
    
    [startTalkingBlurButton addTarget:self action:@selector(startTalkingBlurButtonAction) forControlEvents:UIControlEventTouchUpInside];
    
#pragma mark Alonso put colors here
    NSArray *colorsHex = @[@"4F92E0", @"F1793A", @"AB4EFE", @"FBB829", @"00CF69"];
    NSMutableArray *colorsMutable = [[NSMutableArray alloc] init];
    for (NSString *hexColor in colorsHex)
    {
        [colorsMutable addObject:[UIColor colorWithHexString:hexColor]];
    }
    
    colors = [NSArray arrayWithArray:colorsMutable];

    
    
 
    self.icons = @[@{@"name":@"1", @"attribution":@"FIND THIS1"}, //cloud
                   @{@"name":@"2", @"attribution":@"FIND THIS2"}, //person
                   @{@"name":@"3", @"attribution":@"FIND THIS3"}, //balloon
                   @{@"name":@"4", @"attribution":@"FIND THIS4"},
                   @{@"name":@"5", @"attribution":@"Edward Boatman"},
                   @{@"name":@"6", @"attribution":@"Antonis Makriyannis"},
                   @{@"name":@"7", @"attribution":@"Yaroslav Samoilov"}];//paw
    // @"5", @"6", @"7"];
# pragma mark Ethan match these to icons via an attribution at the bottom of the screen
//    self.iconAttributions = @[@"FIND THIS1", @"FIND THIS2", @"FIND THIS3", @"FIND THIS4"];//, @"Edward Boatman", @"Antonis Makriyannis", @"Yaroslav Samoilov"];
    
    int randIcon = esRandomNumberIn(0, icons.count);
    
    if ([self userIsLoggedIn])
    {
        NSString *icon = [[NSUserDefaults standardUserDefaults] objectForKey:@"icon"];
        
        NSPredicate *predicate = [NSPredicate predicateWithFormat:@"SELF.name == %@", icon];
        id theObject = [[self.icons filteredArrayUsingPredicate:predicate] lastObject];
        
        int index = [self.icons indexOfObject:theObject];
        self.selectedIconIndex = index;
        randIcon = index;
    }
    [self setIconIndex:randIcon];
    
    NSString *attribution = [[self.icons objectAtIndex:self.iconIndex] objectForKey:@"attribution"];
    [self.attributionLabel setText:[NSString stringWithFormat:@"Icon by %@", attribution]];//[[self.icons objectAtIndex:self.iconIndex] objectForKey:@"attribution"]];

    iconTableView = [[UITableView alloc] initWithFrame:self.iconContainerView.bounds style:UITableViewStylePlain];
    [iconTableView setBackgroundColor:[UIColor clearColor]];
    [iconTableView setSeparatorColor:[UIColor clearColor]];
    [iconTableView setShowsVerticalScrollIndicator:NO];
    [iconTableView setUserInteractionEnabled:NO];
    
    [iconTableView setContentOffset:CGPointMake(0, self.iconIndex*self.cellHeight)];
    
    {
        CALayer *layer = [CALayer layer];
        [layer setFrame:self.iconContainerView.bounds];
        
        [layer setCornerRadius:self.iconContainerView.bounds.size.height/2];
        [layer setBackgroundColor:[UIColor whiteColor].CGColor];
        
        [self.iconContainerView.layer setMask:layer];
    }
    
    
    iconTableView.delegate = self;
    iconTableView.dataSource = self;
    
    [self.iconContainerView addSubview:iconTableView];

    colorIndex = 0;//esRandomNumberIn(0, self.colors.count);
    
    if ([self userIsLoggedIn])
    {
        NSString *color = [[NSUserDefaults  standardUserDefaults] objectForKey:@"color"];
        
        NSPredicate *predicate = [NSPredicate predicateWithFormat:@"(SELF == %@)", color];
        id theColor = [[colorsHex filteredArrayUsingPredicate:predicate] lastObject];
        int colorIndexActually = [colorsHex indexOfObject:theColor];
        
        
        
        colorIndex = colorIndexActually;
    }
    
    [self.view setBackgroundColor:[colors objectAtIndex:colorIndex] ];
    
    //add gesture listener pan left right
    self.panGesture = [[UIPanGestureRecognizer alloc] initWithTarget:self action:@selector(handlePan:)];
    [self.view addGestureRecognizer:self.panGesture];
    
    
    [self.doneBlurButton addTarget:self action:@selector(doneBlurButtonAction:) forControlEvents:UIControlEventTouchUpInside];
    
    


}

#pragma mark blurActionButton callbacks
-(void)doneBlurButtonAction:(UIButton*)button
{
    
    FCUser *owner =  [FCUser owner];
    
    [self continueWithDonBlurButtonAction];
//    if (!self.authClient)
//    {
//        self.authClient = [[FirebaseSimpleLogin alloc] initWithRef:owner.rootRef];
//    }
//    
//    if (!owner.fuser)
//    {
//        [self.authClient loginAnonymouslywithCompletionBlock:^(NSError* error, FAUser* user) {
//            if (error != nil)
//            {
//                NSLog(@"oh no an error when loginAnonymouselyWithCompletionBlock! %@", error.localizedDescription);
//                UIAlertView *alert = [[UIAlertView alloc] initWithTitle:@"Ahh!" message:error.localizedDescription delegate:self cancelButtonTitle:@"cancel" otherButtonTitles:@"try again", nil];
//                [alert show];
//                // There was an error logging in to this account
//            } else
//            {
//                
//                owner.fuser = user;
//                [self continueWithDonBlurButtonAction];
//                
//                // We are now logged in
//            }
//        }];
//    } else
//    {
//        
//    }
    
    
}

-(void)alertView:(UIAlertView *)alertView clickedButtonAtIndex:(NSInteger)buttonIndex
{
    if (buttonIndex)
    {
        [self doneBlurButtonAction:nil];
    }
}

-(void)continueWithDonBlurButtonAction
{
    //extract current icon
    self.selectedIconIndex = (iconTableView.contentOffset.y/self.cellHeight);
    
    FCUser *owner = [FCUser owner];
    
    NSString *iconIndexStr = [[icons objectAtIndex:self.selectedIconIndex] objectForKey:@"name"];
    //    FCAppDelegate *appDel = (FCAppDelegate *)[UIApplication sharedApplication].delegate;
    owner.color = [self.view.backgroundColor toHexString];
    owner.icon = iconIndexStr;
    
    [self.view removeGestureRecognizer:self.panGesture];
    
    
    
    UITableViewCell * cell = [iconTableView cellForRowAtIndexPath:[NSIndexPath indexPathForRow:self.selectedIconIndex inSection:0] ];
    UIImageView* imageView = (UIImageView*)[cell viewWithTag:5];
    [imageView setHidden:YES];
    CGRect frameForIcon = CGRectMake(self.iconContainerView.frame.origin.x, self.iconContainerView.frame.origin.y, 50, 50);
    frameForIcon.origin.x += (self.iconContainerView.frame.size.width-frameForIcon.size.width)*0.5f;
    frameForIcon.origin.y += (self.iconContainerView.frame.size.height-frameForIcon.size.height)*0.5f;
    
    self.originalFrameForIcon = frameForIcon;
    self.extractedImageViewOnDone = [[UIImageView alloc] initWithFrame:frameForIcon];
    [self.extractedImageViewOnDone setContentMode:UIViewContentModeScaleAspectFit];
    NSString *imageName = [[self.icons objectAtIndex:self.selectedIconIndex] objectForKey:@"name"];
    [self.extractedImageViewOnDone setImage:[UIImage imageNamed:imageName]];
    [self.view addSubview:self.extractedImageViewOnDone];
    
    
    
    
    //welcomeView2 setup centers view unhides and alpha 0 for begin animation
    [welcomeView2 setHidden:NO];
    [welcomeView2 setAlpha:1.0f];//unhide for invalidatePressedLayer on blurButton
    [welcomeView2 setBackgroundColor:self.view.backgroundColor];
    [startTalkingBlurButton invalidatePressedLayer];
    [welcomeView2 setAlpha:0.0f];
    [welcomeView2 setBackgroundColor:[UIColor clearColor] ];
    
    __block CGRect tempFrame = welcomeView2.frame;
    tempFrame.origin.x = (self.view.frame.size.width -tempFrame.size.width)*0.5f;
    tempFrame.origin.y = (self.view.frame.size.height -tempFrame.size.height)*0.5f;
    tempFrame.origin.y += 5;
    [welcomeView2 setFrame:tempFrame];
    
    CGRect targetFrameForExtractedImageView = frameForIcon;
    targetFrameForExtractedImageView.origin.y = welcomeView2.frame.origin.y - 5 - frameForIcon.size.height - 40;
    
    
    
    //    FCUser *owner = ((FCAppDelegate*)[UIApplication sharedApplication].delegate).owner;
    BOOL peripheralManagerIsRunning = owner.beacon.peripheralManagerIsRunning;
    //    if (peripheralManagerIsRunning)
    //    {
    //        targetFrameForExtractedImageView.origin.y = 20;
    //        targetFrameForExtractedImageView.size = CGSizeMake(35, 35);
    //    }
    
    [UIView animateWithDuration:1.2f delay:0.0 usingSpringWithDamping:1.2 initialSpringVelocity:0.0f options:UIViewAnimationOptionCurveLinear animations:^
     {
         
         
         for (UIView *subview in self.view.subviews)
         {
             if (subview == welcomeView2)
             {
                 //                tempFrame.origin.y -=5;
                 //                welcomeView2.frame = tempFrame;
                 //                welcomeView2.alpha = 1.0f;
             } else
                 if (subview != self.extractedImageViewOnDone ) //&& subview != welcomeView2)
                 {
                     subview.alpha = 0.0f;
                     subview.transform = CGAffineTransformMakeTranslation(0, -5);
                 }
         }
         
     } completion:^(BOOL finished)
     {}];
    
    
    
    [UIView animateWithDuration:1.6f delay:0.0 usingSpringWithDamping:1.2 initialSpringVelocity:0.0f options:UIViewAnimationOptionCurveLinear animations:^
     {
         if (!peripheralManagerIsRunning)
         {
             self.extractedImageViewOnDone.frame = targetFrameForExtractedImageView;
         }
     } completion:^(BOOL finished)
     {
         if (peripheralManagerIsRunning)
         {
             [self transitionToFCWallViewControllerWithImage:self.extractedImageViewOnDone.image andFrame:self.extractedImageViewOnDone.frame andColor:self.view.backgroundColor];
         } else
             //             if (!peripheralManagerIsRunning)
         {
             [UIView animateWithDuration:0.4f delay:0.0 usingSpringWithDamping:1.2 initialSpringVelocity:0.0f options:UIViewAnimationOptionCurveLinear animations:^
              {
                  tempFrame.origin.y -= 5;
                  welcomeView2.frame = tempFrame;
                  welcomeView2.alpha = 1.0f;
                  
              } completion:^(BOOL finished)
              {}];
         }
     }];

}





-(void)startTalkingBlurButtonAction
{
    FCUser *owner = [FCUser owner];

    
    if (!owner.beacon.peripheralManagerIsRunning)
    {
        [owner.beacon start];
    }
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(pushErrorScreen:) name:@"Bluetooth Disabled" object:nil];
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(continueWithBluetooth:) name:@"Bluetooth Enabled" object:nil];
    return;
    
    
}

-(void)removeBluetoothEvents
{
    [[NSNotificationCenter defaultCenter] removeObserver:self name:@"Bluetooth Disabled" object:nil];
    [[NSNotificationCenter defaultCenter] removeObserver:self name:@"Bluetooth Enabled" object:nil];
}

-(void)continueWithBluetooth:(NSNotification*)notification
{
    [self removeBluetoothEvents];
    [UIView animateWithDuration:0.5 delay:0.0 options:UIViewAnimationOptionCurveLinear animations:^
     {
         for (UIView *subview in self.view.subviews)
         {
             if (subview != self.extractedImageViewOnDone)
             {
                 subview.alpha = 0.0f;
             }
         }
     } completion:^(BOOL finsihed)
     {
         [self transitionToFCWallViewControllerWithImage:self.extractedImageViewOnDone.image andFrame:self.extractedImageViewOnDone.frame andColor:self.view.backgroundColor];
     }];
}

#pragma mark blurActionButton callbacks end


-(void)transitionToFCWallViewControllerWithImage:(UIImage*)image andFrame:(CGRect)startingFrame andColor:(UIColor*)backgroundColor
{
    [self setUserIsLoggedIn:YES];
    UIStoryboard *storyboard = [UIStoryboard storyboardWithName:@"main" bundle:nil];
    FCWallViewController *nextViewController = (FCWallViewController *)[storyboard instantiateViewControllerWithIdentifier:@"FCWallViewController"];

    NSString *iconIndexStr = [[icons objectAtIndex:self.selectedIconIndex] objectForKey:@"name"];
//    FCAppDelegate *appDel = (FCAppDelegate *)[UIApplication sharedApplication].delegate;
//    appDel.owner.color = [backgroundColor toHexString];
//    appDel.owner.icon = iconIndexStr;

    [nextViewController setIconName:iconIndexStr];
    [nextViewController beginTransitionWithIcon:(UIImage*)image andFrame:(CGRect)startingFrame andColor:(UIColor*)backgroundColor andResetFrame:self.originalFrameForIcon isAnimated:YES];

    NSMutableArray *viewControllers = [NSMutableArray arrayWithArray:self.navigationController.viewControllers];
    [viewControllers addObject:nextViewController];
    self.navigationController.viewControllers = viewControllers;
}

-(void)viewWillAppear:(BOOL)animated
{
    [super viewWillAppear:animated];
    ////this is to fade in the view after splash screen is gone
    
    if (!hasBeenHereBefore)
    {
        for (UIView *view in self.view.subviews)
        {
            view.alpha = 0.0f;
        }
    }
    
    NSTimer *timer = [NSTimer timerWithTimeInterval:1.0 target:self selector:@selector(invalidate) userInfo:nil repeats:NO];
    [[NSRunLoop mainRunLoop] addTimer:timer forMode:NSDefaultRunLoopMode];
    [[UIApplication sharedApplication] setStatusBarHidden:YES withAnimation:UIStatusBarAnimationFade];
    
//    [self skipIfLoggedIn];
    
}

-(void)viewWillLayoutSubviews
{
    [super viewWillLayoutSubviews];
//    [super viewWillLayoutSubviews];
//    [self skipIfLoggedIn];
}
-(void)viewDidLayoutSubviews
{
    NSLog(@"viewDidLayoutSubviews");
}


-(void)skipIfLoggedIn
{
    //It is time to Just Present the wallView controller view controller
    if ([self userIsLoggedIn])
    {
        self.hasBeenHereBefore = YES;
        UITableViewCell * cell = [iconTableView cellForRowAtIndexPath:[NSIndexPath indexPathForRow:self.selectedIconIndex inSection:0] ];
        UIImageView* imageView = (UIImageView*)[cell viewWithTag:5];
        [imageView setHidden:YES];
        CGRect frameForIcon = CGRectMake(self.iconContainerView.frame.origin.x, self.iconContainerView.frame.origin.y, 50, 50);
        frameForIcon.origin.x += (self.iconContainerView.frame.size.width-frameForIcon.size.width)*0.5f;
        frameForIcon.origin.y += (self.iconContainerView.frame.size.height-frameForIcon.size.height)*0.5f;

        
        self.originalFrameForIcon = frameForIcon;
        self.extractedImageViewOnDone = [[UIImageView alloc] initWithFrame:frameForIcon];
        [self.extractedImageViewOnDone setContentMode:UIViewContentModeScaleAspectFit];
        NSString *imageName = [[self.icons objectAtIndex:self.selectedIconIndex] objectForKey:@"name"];
        [self.extractedImageViewOnDone setImage:[UIImage imageNamed:imageName]];
//        [self.view addSubview:self.extractedImageViewOnDone];
        self.extractedImageViewOnDone.alpha = 1.0f;
        
        UIStoryboard *storyboard = [UIStoryboard storyboardWithName:@"main" bundle:nil];
        FCWallViewController *nextViewController = (FCWallViewController *)[storyboard instantiateViewControllerWithIdentifier:@"FCWallViewController"];
        
        NSString *iconIndexStr = [[icons objectAtIndex:self.selectedIconIndex] objectForKey:@"name"];
        //    FCAppDelegate *appDel = (FCAppDelegate *)[UIApplication sharedApplication].delegate;
        //    appDel.owner.color = [backgroundColor toHexString];
        //    appDel.owner.icon = iconIndexStr;
        
        [nextViewController setIconName:iconIndexStr];
        CGFloat dim = 50;
        CGRect startingFrame = CGRectMake((self.view.frame.size.width-dim)*0.5f,(self.view.frame.size.height-dim)*0.5f,dim,dim);
        NSString *icon = [[NSUserDefaults standardUserDefaults] objectForKey:@"icon"];
        [nextViewController beginTransitionWithIcon:[UIImage imageNamed:icon] andFrame:startingFrame andColor:self.view.backgroundColor andResetFrame:CGRectMake(0, 0, 0, 0) isAnimated:NO];
        
        NSMutableArray *viewControllers = [NSMutableArray arrayWithArray:self.navigationController.viewControllers];
        [viewControllers addObject:nextViewController];
        [self.navigationController pushViewController:nextViewController animated:NO];

        [[FCUser owner].beacon start];
        
    }
}
-(CGRect)getOriginalRect
{
    UITableViewCell * cell = [iconTableView cellForRowAtIndexPath:[NSIndexPath indexPathForRow:self.selectedIconIndex inSection:0] ];
    UIImageView* imageView = (UIImageView*)[cell viewWithTag:5];
    [imageView setHidden:YES];
    CGRect frameForIcon = CGRectMake(self.iconContainerView.frame.origin.x, self.iconContainerView.frame.origin.y, 50, 50);
    frameForIcon.origin.x += (self.iconContainerView.frame.size.width-frameForIcon.size.width)*0.5f;
    frameForIcon.origin.y += (self.iconContainerView.frame.size.height-frameForIcon.size.height)*0.5f;

    self.originalFrameForIcon = frameForIcon;
    
    if (![self.extractedImageViewOnDone superview])
    {
//        CGRect jkFrame = self.originalFrameForIcon;
//        jkFrame.origin.y -= 20;
//        [self.extractedImageViewOnDone setFrame:jkFrame];
//        [self.view addSubview:self.extractedImageViewOnDone];
    }

    frameForIcon.origin.y += 20;
    
    return frameForIcon;
}

-(void)invalidate
{
    [doneBlurButton invalidatePressedLayer];
}

-(void)viewDidAppear:(BOOL)animated
{
    [super viewDidAppear:animated];
    
    
    
    //this is to fade in the view after splash screen is gone
    if (!hasBeenHereBefore)
    {
        hasBeenHereBefore = YES;

        [UIView animateWithDuration:0.8f delay:0.25f usingSpringWithDamping:1.2 initialSpringVelocity:0.0f options:UIViewAnimationOptionCurveEaseIn animations:^
        {
            
            for (UIView *view in self.view.subviews)
            {
                view.alpha = 1.0f;
            }
        } completion:^(BOOL finishd)
         {
         }];
    }

    
    [self skipIfLoggedIn];


}



-(void)handlePan:(UIPanGestureRecognizer*)panGesture
{
//    NSLog(@"panGesture = %@", panGesture);

    CGPoint velocity = [panGesture velocityInView:self.view];
//    CGPoint location = [panGesture locationInView:self.view];
    CGPoint translation = [panGesture translationInView:self.view];

    
    static CGFloat swipeWidth = 320;
    CGFloat swipeHeight = self.view.frame.size.height;
    
    switch((int)panGesture.state)
    {
            //determine what kind of swipe, up down left or right
        case UIGestureRecognizerStateBegan:
        {
//            NSLog(@"UIGestureRecognizerStateBegan");
            self.stateChanged = NO;
            
//            NSLog(@"velocity = %@", NSStringFromCGPoint(velocity));
//            NSLog(@"location = %@", NSStringFromCGPoint(location));
//            NSLog(@"translation = %@", NSStringFromCGPoint(translation));
            if (fabsf(velocity.x) > fabsf(velocity.y))
            {
                if (velocity.x < 0)
                {
                 
                    panDirection = PanGestureDirectionLeft;
                } else
                {
                 
                    panDirection = PanGestureDirectionRight;
                }
            } else
            {
                if (velocity.y < 0)
                {

                    panDirection = PanGestureDirectionUp;
                } else
                {

                    panDirection = PanGestureDirectionDown;
                }
                
                self.offsetOfTableViewAtStartOfVertical = self.iconTableView.contentOffset;
            }
        }
        break;
        case UIGestureRecognizerStateChanged:
        {
//            NSLog(@"UIGestureRecognizerStateChanged");
            self.stateChanged = YES;
            
            CGFloat percent = 0;
            
            switch (panDirection)
            {

                case PanGestureDirectionLeft:
                {
                    percent = translation.x/swipeWidth;
                }
                break;
                case PanGestureDirectionRight:
                {
                    percent = translation.x/swipeWidth;
                }
                break;
                case PanGestureDirectionUp:
                {
                    percent = translation.y/swipeHeight;
                }
                break;
                case PanGestureDirectionDown:
                {
                    percent = translation.y/swipeHeight;
                }
                break;
                case PanGestureDirectionNone:
                {
                    NSLog(@"PanGestureDirectionNone on state changed! WARNING!");
                }
                break;
            }

            if (PanGestureDirectionLeft == panDirection || PanGestureDirectionRight == panDirection )
            {//Left Right color change CHANGE
                int direction = fabsf(percent)/percent;
                while (fabsf(percent >= 1))
                {
                    
                    percent += -direction;
                    [self setColorIndex:colorIndex+direction];
                }
                
                int start = self.colorIndex;
                int end = self.colorIndex+direction;
                if (end < 0)
                {
                    end = colors.count-1;
                } else
                if (end >= colors.count)
                {
                    end = 0;
                }
                
                if (direction < 0)
                {//switch start and end colors
                    int tempStart = start;
                    start = end;
                    end = tempStart;
                    percent += 1.0f;
                }
                //percent always positive here
                [self.view setBackgroundColor:[self colorLerpFrom:[colors objectAtIndex:start] to:[colors objectAtIndex:end] withDuration:percent]];
                
                
            } else
            if (PanGestureDirectionUp == panDirection || PanGestureDirectionDown == panDirection)
            {
                //up is negative, down is positive
                int direction = fabsf(percent)/percent;
                
                CGFloat y = self.offsetOfTableViewAtStartOfVertical.y - percent*self.cellHeight;
                
                //following if else clause will appear to loop the tableview, aka: no top nor bottom.
                if (y < 0)
                {
                    NSLog(@"reshuffle bottom to top");
                    id lastObject = [self.icons lastObject];
                    
                    
//                    id lastAttrib = [self.iconAttributions lastObject];
//                    NSMutableArray *iconAttribsMutable = [NSMutableArray arrayWithArray:self.iconAttributions];
//                    [iconAttribsMutable removeLastObject];
//                    [iconAttribsMutable insertObject:lastAttrib atIndex:0];
//                    self.iconAttributions = [NSArray arrayWithArray:iconAttribsMutable];
                    
                    
                    
                    NSMutableArray *iconNamesMutable = [NSMutableArray arrayWithArray:self.icons];
                    [iconNamesMutable removeLastObject];
                    [iconNamesMutable insertObject:lastObject atIndex:0];
                    self.icons = [NSArray arrayWithArray:iconNamesMutable];
                    [self.iconTableView reloadData];
                
                    //move tableView
                    CGPoint offset = {0, self.cellHeight};
                    
                    self.offsetOfTableViewAtStartOfVertical = offset; //{0, self.offsetOfTableViewAtStartOfVertical.y + self.cellHeight};
                    
                    y = self.offsetOfTableViewAtStartOfVertical.y - percent*self.cellHeight;
                    
                    
                    
                } else
                if (y > self.cellHeight*(self.icons.count-1))
                {
                    NSLog(@"reshuffle top to bottom");
                    //reshuffle top to bottom
                    id firstObject = [self.icons objectAtIndex:0];
                    
//                    id firstAttrib = [self.iconAttributions objectAtIndex:0];
//                    NSMutableArray *iconAttribsMutable = [NSMutableArray arrayWithArray:self.iconAttributions];
//                    [iconAttribsMutable removeObject:firstAttrib];
//                    [iconAttribsMutable addObject:firstAttrib];
//                    self.iconAttributions = [NSArray arrayWithArray:iconAttribsMutable];
                    
                    
                    NSMutableArray *iconNamesMutable = [NSMutableArray arrayWithArray:self.icons];
                    [iconNamesMutable removeObject:firstObject];
                    [iconNamesMutable addObject:firstObject];
                    self.icons = [NSArray arrayWithArray:iconNamesMutable];
                    [self.iconTableView reloadData];
                    
                    //move tableView
                    CGPoint offset = {0, self.cellHeight*(self.icons.count-1)-self.cellHeight};
                    
                    self.offsetOfTableViewAtStartOfVertical = offset; //{0, self.offsetOfTableViewAtStartOfVertical.y + self.cellHeight};
                    
                    y = self.offsetOfTableViewAtStartOfVertical.y - percent*self.cellHeight;

                    
                }
                
                [self.iconTableView setContentOffset:CGPointMake(0, y)];
                
            }
//            NSLog(@"percent = %f", percent);
        }
        break;
        case UIGestureRecognizerStateEnded:
        {
            if (!self.stateChanged)
            {
                return;
            } else
            {
                self.stateChanged = NO;
            }

            CGFloat percent = 0;
            switch (panDirection)
            {
                    
                case PanGestureDirectionLeft:
                {
                    percent = translation.x/swipeWidth;
                }
                    break;
                case PanGestureDirectionRight:
                {
                    percent = translation.x/swipeWidth;
                }
                    break;
                case PanGestureDirectionUp:
                {
                    percent = translation.y/swipeHeight;
                }
                    break;
                case PanGestureDirectionDown:
                {
                    percent = translation.y/swipeHeight;
                }
                    break;
                case PanGestureDirectionNone:
                {
                    NSLog(@"PanGestureDirectionNone on state ENDED! WARNING!");
                }
                break;
            }
            int direction = fabsf(percent)/percent;
            
            if (PanGestureDirectionLeft == panDirection || PanGestureDirectionRight == panDirection )
            {//Left Right color change END
                
                int start = self.colorIndex;
                int end = self.colorIndex+direction;
                if (end < 0)
                {
                    end = colors.count-1;
                } else
                if (end >= colors.count)
                {
                    end = 0;
                }
                
//switch back if not going fast enough for a certain percent traveled
                if (fabsf(velocity.x) < 40 && fabsf(percent) < 0.7f)
                {
                    end = start;
                }
                
                [UIView animateWithDuration:0.25f delay:0.0f usingSpringWithDamping:1.25f initialSpringVelocity:0 options:UIViewAnimationOptionCurveLinear animations:^
                {
                    self.view.backgroundColor = [colors objectAtIndex:end];
                    self.colorIndex = end;
                } completion:^(BOOL finished)
                {
                    [doneBlurButton invalidatePressedLayer];
                }];
                
            } else
            if (PanGestureDirectionUp == panDirection || PanGestureDirectionDown == panDirection)
            {
                int direction = fabsf(percent)/percent;
                
                int numberOfWraps = abs((int)percent);
                numberOfWraps = MAX(1, numberOfWraps);
                
                
                CGFloat y = self.offsetOfTableViewAtStartOfVertical.y - numberOfWraps*direction*self.cellHeight;
                
                [UIView animateWithDuration:0.25f delay:0.0f usingSpringWithDamping:1.25f initialSpringVelocity:0 options:UIViewAnimationOptionCurveLinear animations:^
                {
                    
                    int index = y/self.cellHeight;
                    NSDictionary *dc = [self.icons objectAtIndex:index];
                    NSString *attribution = [dc objectForKey:@"attribution"];
                    [self.attributionLabel setText:[NSString stringWithFormat:@"Icon by %@", attribution]];
                    [self.iconTableView setContentOffset:CGPointMake(0, y)];
                    self.iconIndex = iconIndex - numberOfWraps;
                    
                } completion:^(BOOL finished)
                {
                    
                }];
                
            }
        }
        break;
            
            
            
    }
    
}

- (UIColor *)colorLerpFrom:(UIColor *)start to:(UIColor *)end withDuration:(float)t
{
    if(t < 0.0f) t = 0.0f;
    if(t > 1.0f) t = 1.0f;
    
    const CGFloat *startComponent = CGColorGetComponents(start.CGColor);
    const CGFloat *endComponent = CGColorGetComponents(end.CGColor);
    
    float startAlpha = CGColorGetAlpha(start.CGColor);
    float endAlpha = CGColorGetAlpha(end.CGColor);
    
    float r = startComponent[0] + (endComponent[0] - startComponent[0]) * t;
    float g = startComponent[1] + (endComponent[1] - startComponent[1]) * t;
    float b = startComponent[2] + (endComponent[2] - startComponent[2]) * t;
    float a = startAlpha + (endAlpha - startAlpha) * t;
    
    return [UIColor colorWithRed:r green:g blue:b alpha:a];
}

- (void)didReceiveMemoryWarning
{
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

-(void)setIconIndex:(NSInteger)newIconIndex
{
    while (newIconIndex < 0)
    {
        newIconIndex += icons.count;
    }
    

    
    iconIndex = newIconIndex%icons.count;
    

}

-(void)setColorIndex:(NSInteger)newColorIndex
{
    while (newColorIndex < 0)
    {
        newColorIndex += colors.count;
    }
    
    colorIndex = newColorIndex%colors.count;
}

#pragma mark iconTableView delegate callback
-(NSInteger) numberOfSectionsInTableView:(UITableView *)tableView
{
    return 1;
}
-(NSInteger) tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section
{
    return icons.count;
}
-(UITableViewCell*)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath
{
    UITableViewCell *iconCell = [tableView dequeueReusableCellWithIdentifier:@"IconCell"];
    if (!iconCell)
    {
        
        iconCell = [[UITableViewCell alloc] initWithStyle:UITableViewCellStyleDefault reuseIdentifier:@"IconCell"];
        [iconCell setBackgroundColor:[UIColor clearColor]];
        UIImageView *imageView = [[UIImageView alloc] initWithFrame:CGRectMake((self.iconContainerView.bounds.size.width-50)*0.5, (self.iconContainerView.bounds.size.height-50)*0.5, 50, 50)];
        [imageView setContentMode:UIViewContentModeScaleAspectFit];
        imageView.tag = 5;
        [imageView setBackgroundColor:[UIColor clearColor]];
        
        [iconCell.contentView addSubview:imageView];
    }
    
    
    
    UIImageView *imageView = (UIImageView*)[iconCell viewWithTag:5];
    [imageView setHidden:NO];
    [imageView setImage:[UIImage imageNamed: [ [icons objectAtIndex:indexPath.row] objectForKey:@"name"] ] ];
//    [iconCell setBackgroundColor:[UIColor colorWithRed:1 green:0 blue:0 alpha:0.2f]];

    return iconCell;
}

-(CGFloat)tableView:(UITableView *)tableView heightForRowAtIndexPath:(NSIndexPath *)indexPath
{
    return self.cellHeight;
}

-(CGFloat)cellHeight
{
    return self.iconContainerView.bounds.size.height;
}


#pragma mark iconTableView datasource callback

#pragma mark Notifications
- (void)appDidBecomeActive:(NSNotification *)notification
{
//    [UIView animateWithDuration:40.0f
//                          delay:0.0f
//                        options:UIViewAnimationOptionRepeat | UIViewAnimationOptionCurveLinear
//                     animations:^{
//                         self.spinnerImageView.transform = CGAffineTransformMakeRotation(M_PI);
//                     }
//                     completion:nil
//     ];
//    NSLog(@"did become active notification");
}

- (void)appDidEnterForeground:(NSNotification *)notification
{
    NSLog(@"did enter foreground notification");
}
#pragma mark Notifications end

//redraw the view as if it were the first time.
-(void)resetAsNewAnimated
{
    [self setUserIsLoggedIn:NO];
    [self.view addGestureRecognizer:self.panGesture];
    [self.iconTableView reloadData];
    self.extractedImageViewOnDone.frame = self.originalFrameForIcon;
    
    for (UIView *view in self.view.subviews)
    {
        if (view != self.extractedImageViewOnDone)
        {
            view.transform = CGAffineTransformIdentity;
        }
    }
    [UIView animateWithDuration:0.5f delay:0.2f usingSpringWithDamping:1.2f initialSpringVelocity:0.0f options:UIViewAnimationOptionCurveLinear animations:^{
        for (UIView *view in self.view.subviews)
        {
            if (view != self.welcomeView2)
            {
                view.alpha = 1.0f;

            }
        }
    } completion:^(BOOL finished)
    {
        [self.extractedImageViewOnDone removeFromSuperview];
    }];
}

-(void)pushErrorScreen:(NSNotification*)notification
{
    [self removeBluetoothEvents];
    [self performSegueWithIdentifier:@"errorPush" sender:self];
}
-(void)prepareForSegue:(UIStoryboardSegue *)segue sender:(id)sender
{
    if ([segue.identifier isEqualToString:@"errorPush"])
    {
        UIViewController *viewController = segue.destinationViewController;
        [viewController.view setBackgroundColor:self.view.backgroundColor];
    }
}

@end
