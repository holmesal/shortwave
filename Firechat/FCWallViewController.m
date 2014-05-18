//
//  FCWallViewController.m
//  Firechat
//
//  Created by Alonso Holmes on 2/2/14.
//  Copyright (c) 2014 Buildco. All rights reserved.
//


#import "FCWallViewController.h"
#import "FCAppDelegate.h"
#import <Firebase/Firebase.h>
#import "FCMessage.h"
#import "FCMessageCell.h"
#import "ProfileCollectionViewCell.h"
#import "ESSwapUserStateMessage.h"
#import "ESSwapUserStateCell.h"
#import "ESUserPMCell.h"
#import "FCLandingPageViewController.h"
#import <Mixpanel/Mixpanel.h>

#define WIDTH_OF_PM_LIST 75.0f


@interface FCWallViewController () <UICollectionViewDataSource, UICollectionViewDelegate, UICollectionViewDelegateFlowLayout>

typedef enum
{
    WallStateGlobal,
    WallStatePMUsers,
    WallStatePM
    
} WallState;

@property (nonatomic) BOOL initializedTableView;
@property (nonatomic) CGRect lastFrameForSelfView;
@property (nonatomic) NSTimer *autoScrollLockTimer;
@property (nonatomic) UITapGestureRecognizer *singleTapDebugGesture;

@property (nonatomic ) NSString *justAddPmWithUserId;
@property (nonatomic) WallState wallState;

@property (nonatomic) NSArray *tracking;
@property (nonatomic) BOOL topBarHasGesture;

@property (nonatomic) NSInteger elipseCount;
@property (nonatomic) NSTimer *elipseTimer2;
//@property (nonatomic) UIView *searchingLabelView;
@property (nonatomic) NSDate *dateLastVisible;
@property (nonatomic) NSTimer *timerToShowSearchingText;



//firebase handles

@property (nonatomic) CGFloat previousScrollViewYOffset;
@property (nonatomic) CGFloat scrollSpeed;


@property (nonatomic) NSInteger selectedUserPmIndex;
@property (nonatomic) NSMutableArray *userPmList;
@property (nonatomic) NSMutableArray *currentPrivateMessages;

@property (nonatomic) IBOutlet UIView *contentView;
@property (nonatomic) IBOutlet UIView *pmListContainerView;
@property (nonatomic) IBOutlet UITableView *pmUsersTableView;
@property (weak, nonatomic) IBOutlet UITableView *pmTableView;
@property (weak, nonatomic) IBOutlet UIView *pmTableViewContainer;
@property (nonatomic, assign) FirebaseHandle trackingHandle;

@property (nonatomic) FirebaseHandle removeFromUserPmListHandle;
@property (nonatomic) FirebaseHandle bindToUserPmListHandle;
@property (nonatomic) FirebaseHandle bindToWallHandle;
@property (nonatomic) CGFloat buttonImageInset;
@property (nonatomic) BOOL presentAnimated;
@property (assign, nonatomic) NSInteger lastNumberOfPeopleInCollectionView;

@property (nonatomic) BOOL needsToDoTransitionWithShadeView;

@property (nonatomic) UIView *shadeView;
@property (nonatomic) UIButton *iconButton;
@property (nonatomic) UIView *labelMaskView;


@property (nonatomic) CAShapeLayer *lineLayer;
@property (weak, nonatomic) IBOutlet UITableView *tableView;


//SOME KEYBOARD PROPERTIES FOR HIT TESTING A TOUCH
@property (nonatomic) BOOL keyboardIsVisible;
@property (nonatomic) CGRect keyboardRect;


@property (nonatomic) CALayer *tableViewMask;

@property (nonatomic) UILabel *peopleNearbyLabel;
@property FCUser *owner;

@property Firebase *userPmListRef;
@property Firebase *wallRef;
@property NSMutableArray *wall;
@property NSArray *beacons;
@property (weak, nonatomic) IBOutlet UIImageView *bgImage;
@property (weak, nonatomic) IBOutlet UIImageView *backgroundImageView;

@property Firebase *trackingRef;

@property (weak, nonatomic) IBOutlet UICollectionView *whoIsHereCollectionView;
@property (nonatomic) CGRect originalRectOfIcon;


//pm stuff
@property (nonatomic) BOOL isPanAnimating;
@property (nonatomic) UIPanGestureRecognizer *panLeftGesture;

// Mixpanel
@property (strong,nonatomic) Mixpanel *mixpanel;





@end

@implementation FCWallViewController

@synthesize initializedTableView;
@synthesize autoScrollLockTimer;

//searching label stuff
@synthesize elipseCount;
@synthesize elipseTimer2;
@synthesize dateLastVisible;
//@synthesize searchingLabelView;
@synthesize timerToShowSearchingText;

@synthesize tracking;
@synthesize trackingHandle;
@synthesize selectedUserPmIndex;
@synthesize buttonImageInset;
@synthesize peopleNearbyLabel;
@synthesize lastNumberOfPeopleInCollectionView;

@synthesize backgroundImageView;

@synthesize tableViewMask;
@synthesize tableView;
@synthesize whoIsHereCollectionView;

@synthesize lineLayer;

//SOME KEYBOARD PROPERTIES FOR HIT TESTING A TOUCH
@synthesize keyboardIsVisible;
@synthesize keyboardRect;

@synthesize wallState;
@synthesize panLeftGesture;
@synthesize contentView;

@synthesize currentPrivateMessages;
@synthesize userPmList;


static CGFloat HeightOfGradient = 60;
static CGFloat HeightOfWhoIsHereView = 20 + 50.0f;//20 is for the status bar.  Eeeewps :)


- (id)initWithCoder:(NSCoder*)aDecoder
{
    if(self = [super initWithCoder:aDecoder])
    {
        self.wall = [NSMutableArray array];
        
        self.currentPrivateMessages = self.wall;
        self.beacons = [[NSArray alloc] init];
        
        self.userPmList = [[NSMutableArray alloc] init];
        
        self.mixpanel = [Mixpanel sharedInstance];
        

    }
    return self;
}



-(void)viewDidAppear:(BOOL)animated
{
    [super viewDidAppear:animated];
    self.lastFrameForSelfView = self.view.frame;
    
    NSLog(@"self.dateLastVisible = %@", self.dateLastVisible);
    

    //handle the animation where the shadeView slidse up to be the 'navbar' then the icon and peopleNearbyLabel separate animated
    if (self.shadeView && self.needsToDoTransitionWithShadeView)
    {
        self.needsToDoTransitionWithShadeView = NO;
        CGRect targetPeopleNearbyLabelFrame = peopleNearbyLabel.frame;
        
        
        peopleNearbyLabel.frame = CGRectMake(
                                             (self.view.frame.size.width-40)*0.5f,
                                             targetPeopleNearbyLabelFrame.origin.y, targetPeopleNearbyLabelFrame.size.width, targetPeopleNearbyLabelFrame.size.height);
        [peopleNearbyLabel setBackgroundColor:[UIColor clearColor]];
        
        self.labelMaskView = [[UIView alloc] initWithFrame:peopleNearbyLabel.frame];
        {
            UIColor *color = self.shadeView.backgroundColor;
            [self.labelMaskView setBackgroundColor:color];
        }
        [self.shadeView insertSubview:self.labelMaskView aboveSubview:self.peopleNearbyLabel];
        
        [UIView animateWithDuration:0.6f delay:0.0f usingSpringWithDamping:1.2f initialSpringVelocity:0.0f options:UIViewAnimationOptionCurveLinear animations:^
        {
            CGRect frame = self.shadeView.frame;
            frame.size.height = 64;
            frame.origin.y = 0;
            self.shadeView.frame = frame;
            
            frame = self.iconButton.frame;
            frame.origin.y = 23;
            frame.size.width = 35;
            frame.size.height = 35;
            
            self.iconButton.frame = frame;
        } completion:^(BOOL finished)
        {
            [UIView animateWithDuration:1.6f delay:0.0f usingSpringWithDamping:1.2f initialSpringVelocity:0.0f options:UIViewAnimationOptionCurveLinear animations:^
            {
                CGRect frame = self.iconButton.frame;
                frame.origin.x = self.view.frame.size.width - 5 - frame.size.width;
                [self.iconButton setFrame:frame];
                
                //explode grow the status label which explains who is where
                peopleNearbyLabel.frame = targetPeopleNearbyLabelFrame;
                CGRect maskFrame = targetPeopleNearbyLabelFrame;
                maskFrame.origin.x += targetPeopleNearbyLabelFrame.size.width;
                self.labelMaskView.frame = maskFrame;
                
            } completion:^(BOOL finished)
            {
//                [self performSelector:@selector(foreground:) withObject:nil afterDelay:0.0f];
                [self.iconButton setUserInteractionEnabled:YES];
            }];
            
        }];
    }
}

-(void)updatePeopleNearby:(int)numPeople
{
    NSRange rangeOfNumber;
    NSMutableAttributedString *notifyingStr;
    NSString *numPeopleStr = [NSString stringWithFormat:@"%d", numPeople];
    rangeOfNumber.length = numPeopleStr.length;
    if (numPeople == 1)
    {
        rangeOfNumber.location = 9;
        notifyingStr = [[NSMutableAttributedString alloc] initWithString:[NSString stringWithFormat:@"There is %d person nearby.", numPeople] ];
    } else
    {
        rangeOfNumber.location = 10;
        notifyingStr = [[NSMutableAttributedString alloc] initWithString:[NSString stringWithFormat:@"There are %d people nearby.", numPeople] ];
    }
    
    //invalidate our 'searching...' navBar message if that is necessary
    if (numPeople > self.numberOfPeopleBeingTracked && self.timerToShowSearchingText)
    {
        [self timerToShowSearchingTextAction:nil];
    }
    [self setNumberOfPeopleBeingTracked:numPeople];
    //timerToShowSearchingText will be nil if at anypoint timerToShowSearchingTextAction was called with param or not
    if (timerToShowSearchingText)
    {//hack
        return;
    }
    
    if (!self.numberOfPeopleBeingTracked)
    {
        if (!timerToShowSearchingText)
        {
            [self startSearchingBehavior];
        }
        return;
    }

    //make sure invalidate Searching... behavior if must.
    if (timerToShowSearchingText)
    {
        //invalidates current timer to show searching text stuff
        [self timerToShowSearchingTextAction:nil];
    }

    
    
    [notifyingStr beginEditing];
    [notifyingStr addAttribute:NSFontAttributeName
                         value:[UIFont boldSystemFontOfSize:15]
                         range:rangeOfNumber];//range of normal string, e.g. 2012/10/14];
    [notifyingStr endEditing];
    
    peopleNearbyLabel.attributedText = notifyingStr;

    if (DEBUG_SHOW_USER_ID_SINGLE_TAP)
    {
        
        if (!self.topBarHasGesture)
        {
            self.topBarHasGesture = YES;
            [self.shadeView addGestureRecognizer:[[UITapGestureRecognizer alloc] initWithTarget:self action:@selector(showUsersNearby:)]];
        }
    }
}
-(void)showUsersNearby:(UITapGestureRecognizer*)tapGesture
{
    NSString *string = [NSString stringWithFormat:@"%@", self.tracking];
    
    UIAlertView *alertView = [[UIAlertView alloc] initWithTitle:@"DEBUG" message:string delegate:nil cancelButtonTitle:@"ok" otherButtonTitles:nil];
    [alertView show];
}

-(void)updateLine
{
    //table view is flipped keep in mind
    
    if (self.wall.count)
    {
        CGRect rectOfZeroCell = [self.tableView rectForRowAtIndexPath:[NSIndexPath indexPathForRow:self.wall.count-1 inSection:0 ]];
//        NSLog(@"rectOfZeroCell = %@", NSStringFromCGRect(rectOfZeroCell));
        
        UIBezierPath *linePath = [UIBezierPath bezierPath];
        CGFloat x = self.tableView.frame.size.width - (19.5 + 35/2.0f);
        CGFloat ystart = rectOfZeroCell.origin.y+rectOfZeroCell.size.height - (7+35/2.0f);
        CGFloat bottomOfScreen = self.tableView.contentOffset.y;
        
        [linePath moveToPoint:CGPointMake(x, ystart) ];//(heightForZeroPath)/2)];
        [linePath addLineToPoint:CGPointMake(x, bottomOfScreen)];
        
        [lineLayer setPath:linePath.CGPath];
    }
}

-(void)readTime
{
    NSLog(@"sex.view bouns is %@", NSStringFromCGRect(self.view.frame));
    NSLog(@"self.contentVIew bounds changed to : %@", NSStringFromCGRect(self.contentView.frame));
}

- (void)viewDidLoad
{
    [super viewDidLoad];
    
    [self performSelector:@selector(readTime) withObject:nil afterDelay:2];
    
    [self.view addObserver:self forKeyPath:@"frame" options:0 context:nil];
    
    [self performSelector:@selector(foreground:) withObject:nil afterDelay:0.5f];
//    [self foreground:nil];
//    [self foreground:nil];
    //for cold launch, show the searching... label in the nav bar.  NSDate will be loaded from NSUserDefaults
//    [self foreground:nil];
//    [self performSelector:@selector(foreground:) withObject:nil afterDelay:5.0f];
    
    wallState = WallStateGlobal;
    selectedUserPmIndex = -1;// no selected UserPm
    
    [[NSUserDefaults standardUserDefaults] setBool:YES forKey:@"shouldPostSwapUserMessageWhenStateChange"];
    
    
    lineLayer = [CAShapeLayer layer];
    [lineLayer setLineWidth:0.5f];
    [lineLayer setStrokeColor:[UIColor colorWithWhite:225/255.0f alpha:1.0f].CGColor];//[UIColor colorWithWhite:228/255.0f alpha:1.0f].CGColor];
    [lineLayer setFillColor:[UIColor clearColor].CGColor];
    [self.tableView.layer insertSublayer:lineLayer atIndex:0];
    [self updateLine];
    
    
    //use updatePeoplNearby in order to do so
    peopleNearbyLabel = [[UILabel alloc] initWithFrame:CGRectMake(9, 20, self.view.frame.size.width-40, 44)];
    peopleNearbyLabel.font = [UIFont systemFontOfSize:15];
    [peopleNearbyLabel setTextColor:[UIColor whiteColor]];
    [peopleNearbyLabel setClipsToBounds:YES];

    // Start off with 0 people
    [self updatePeopleNearby:0];

    [self.shadeView insertSubview:peopleNearbyLabel belowSubview:self.iconButton];

    
    if (self.shadeView)
    {
        [self.contentView addSubview:self.shadeView];
        
    } else
    {
        NSLog(@"warning! you are instaniating FCWallViewController without setting it up properly via beginTransitionWithIcon method.  Expect to see no transition");
    }
    
    //paralax?
//    {
//        // Set vertical effect
//        UIInterpolatingMotionEffect *verticalMotionEffect =
//        [[UIInterpolatingMotionEffect alloc]
//         initWithKeyPath:@"center.y"
//         type:UIInterpolatingMotionEffectTypeTiltAlongVerticalAxis];
//        
//        static CGFloat wiggle = 50;
//        
//        verticalMotionEffect.minimumRelativeValue = @(-wiggle);
//        verticalMotionEffect.maximumRelativeValue = @(wiggle);
//        
//        // Set horizontal effect
//        UIInterpolatingMotionEffect *horizontalMotionEffect =
//        [[UIInterpolatingMotionEffect alloc]
//         initWithKeyPath:@"center.x"
//         type:UIInterpolatingMotionEffectTypeTiltAlongHorizontalAxis];
//        horizontalMotionEffect.minimumRelativeValue = @(-wiggle);
//        horizontalMotionEffect.maximumRelativeValue = @(wiggle);
//        
//        // Create group to combine both
//        UIMotionEffectGroup *group = [UIMotionEffectGroup new];
//        group.motionEffects = @[horizontalMotionEffect, verticalMotionEffect];
//        
//        // Add both effects to your view
//        [backgroundImageView addMotionEffect:group];
//    }
    
    
    [self.tableView setBackgroundColor:[UIColor whiteColor]];
    
    // Show the navbar and the status bar
    self.navigationController.navigationBarHidden = YES;
    [[UIApplication sharedApplication] setStatusBarHidden:NO];
    // Init table view
    self.tableView.delegate = self;
    self.tableView.dataSource = self;
	// Get the owner
    self.owner = [FCUser owner];
    NSLog(@"owner's id: %@",self.owner.id);
    [self.tableView reloadData];
    
    // Flip the table view in viewWillLayoutSubviews, frame adjust in viewDidLayoutSubviews
    
    
    // Hide the scroll indicator TEHEHEHEHEHEHE
    [self.tableView setShowsVerticalScrollIndicator:NO];
    
    // Hide the back button
    [self.navigationItem setHidesBackButton:YES];
    
    // Bind to the owner's wall
    [self bindToWall];
    
    // Bind to the owner's userPmList
    [self bindToUserPmList];
    
    // Bind to the owner's tracking, updates UI cells
    [self bindToTracking];
    
    // Log this on mixpanel
//    [self.mixpanel track:@"Wall Loaded" properties:@{@"inRangeCount":[NSNumber numberWithInt[self.owner.beacon.earshotUsers count]]}];
    
    // Bind to keyboard notifications
    [[NSNotificationCenter defaultCenter] addObserver:self
                                             selector:@selector(keyboardWillToggle:)
                                                 name:UIKeyboardWillShowNotification
                                               object:nil];
    [[NSNotificationCenter defaultCenter] addObserver:self
                                             selector:@selector(keyboardWillToggle:)
                                                 name:UIKeyboardWillHideNotification
                                               object:nil];
    
    // Hide the keyboard on taps
    UITapGestureRecognizer *tap = [[UITapGestureRecognizer alloc]
                                   initWithTarget:self
                                   action:@selector(dismissKeyboard)];
    [self.view addGestureRecognizer:tap];
    
    // Transparent mask over the top of the table view

    
    // Load the compose view
//    [self loadComposeView];
    
    //pm stuff setup
    
    panLeftGesture = [[UIPanGestureRecognizer alloc] initWithTarget:self action:@selector(handlePan:)];
//    [self.view addGestureRecognizer:panLeftGesture];
    

//    self.contentView.frame = self.view.bounds;
    [self.contentView setClipsToBounds:YES];
    [self.contentView setBackgroundColor:[UIColor clearColor]];
    
    self.pmListContainerView.frame = CGRectMake(self.view.frame.size.width-WIDTH_OF_PM_LIST, 0, WIDTH_OF_PM_LIST, self.view.frame.size.height);
    // Set the PM view to use user's current ID color as background. That color can be grabbed from the shadeview for the title bar.
    CGFloat h;
    CGFloat s;
    CGFloat b;
    CGFloat a;
    [self.shadeView.backgroundColor getHue:&h saturation:&s brightness:&b alpha:&a];
    UIColor *pmListColor = [UIColor colorWithHue:h saturation:(s*0.15) brightness:(b*0.9) alpha:a];
    [self.pmListContainerView setBackgroundColor:pmListColor];
    //[self.pmListContainerView setBackgroundColor:[UIColor grayColor]];
    
    self.pmUsersTableView.frame = self.pmListContainerView.bounds;
    [self.pmUsersTableView setSeparatorColor:[UIColor clearColor]];
    self.pmUsersTableView.delegate = self;
    self.pmUsersTableView.dataSource = self;
    [self.pmUsersTableView setBackgroundColor:[UIColor clearColor]];

    
    [self.view insertSubview:self.pmListContainerView atIndex:0];
    

    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(background:) name:UIApplicationDidEnterBackgroundNotification object:nil];
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(foreground:) name:UIApplicationWillEnterForegroundNotification object:nil];
}

-(void)background:(NSNotification*)notification
{
    self.dateLastVisible = [NSDate date];
}
//setters, getters linked to NSUserDefaults to persist this data across cold launch
-(void)setDateLastVisible:(NSDate *)dLV
{
    dateLastVisible = dLV;
    [[NSUserDefaults standardUserDefaults] setObject:dateLastVisible forKey:@"dateLastVisible"];
}
-(NSDate*)dateLastVisible
{
    if (!dateLastVisible)
    {
        dateLastVisible = [[NSUserDefaults standardUserDefaults] objectForKey:@"dateLastVisible"];
    }
    return dateLastVisible;
}

-(void)foreground:(NSNotification*)notification
{
    if (self.dateLastVisible)
    {
        NSTimeInterval timeInterval = [[NSDate date] timeIntervalSinceDate:self.dateLastVisible];
        if (timeInterval > TIMEOUT)// TIMEOUT about 30 secs
        {
            [self startSearchingBehavior];
        }
    }
}
//helpy helperton
-(void)startSearchingBehavior
{
    //hide peopleNearbyLabel;
    //            [self.peopleNearbyLabel.superview addSubview:self.searchingLabelView];
    //            [self.peopleNearbyLabel setHidden:YES];
    self.peopleNearbyLabel.text = @"Searching for others";
    timerToShowSearchingText = [NSTimer timerWithTimeInterval:5.0f target:self selector:@selector(timerToShowSearchingTextAction:) userInfo:nil repeats:NO];
    if (elipseTimer2)
    {//nevr happn
        [elipseTimer2 invalidate];
        elipseTimer2 = nil;
    }
    elipseTimer2 = [NSTimer timerWithTimeInterval:0.3f target:self selector:@selector(elipseTimerAction2:) userInfo:nil repeats:YES];
    [[NSRunLoop mainRunLoop] addTimer:elipseTimer2 forMode:NSDefaultRunLoopMode];
    [[NSRunLoop mainRunLoop] addTimer:timerToShowSearchingText forMode:NSDefaultRunLoopMode];
}
//callthis to end this nav-bar 'searching' state
-(void)timerToShowSearchingTextAction:(NSTimer*)trw
{
    //if trw is nil it means I called this function manually bcause I see an increase in tracking.count.  it must not return
    if (!self.numberOfPeopleBeingTracked && trw)
    {
        return;
    }
    [timerToShowSearchingText invalidate];
    timerToShowSearchingText = nil;
    
    [elipseTimer2 invalidate];
    elipseTimer2 = nil;
    [self updatePeopleNearby:self.numberOfPeopleBeingTracked];

//    self.peopleNearbyLabel.alpha = 0.0f;
//    [self.peopleNearbyLabel setHidden:NO];
//    [UIView animateWithDuration:0.2f animations:^
//    {
//        self.searchingLabelView.alpha = 0.0f;
//        
//    } completion:^(BOOL finished)
//    {
//        self.searchingLabelView.alpha = 1.0f;
//        [self.searchingLabelView removeFromSuperview];
//    }];
//    
//    [UIView animateWithDuration:0.2f animations:^
//     {
//         self.peopleNearbyLabel.alpha = 1.0f;
//     } completion:^(BOOL finished)
//     {
//         
//     }];
}
//updates the . .. ...
-(void)elipseTimerAction2:(NSTimer*)timer
{
    
    if ([peopleNearbyLabel.text rangeOfString:@"Searching"].location != NSNotFound)
        //searchingLabelView && searchingLabelView.superview && !searchingLabelView.isHidden)
    {
//        UILabel *elipseLabel = (UILabel*)[searchingLabelView viewWithTag:2];
        elipseCount = (elipseCount+1)%4;
        NSString *elipses = @"";
        for (int i = 0; i < elipseCount; i++)
        {
            elipses = [NSString stringWithFormat:@"%@.", elipses];
        }
        
        [peopleNearbyLabel setText:[NSString stringWithFormat:@"Searching for others%@", elipses]];;
    } else
    {
        [elipseTimer2 invalidate];
        elipseTimer2 = nil;
    }
}

//-(UIView*)searchingLabelView
//{
//    if (!searchingLabelView)
//    {
//        CGFloat height = self.peopleNearbyLabel.frame.size.height;
//
//        
//        UILabel *searchingLabel = [[UILabel alloc] initWithFrame:self.peopleNearbyLabel.frame];
//        [searchingLabel setText:@"Searching for others"];
//        [searchingLabel sizeToFit];
//        CGRect rect = searchingLabel.frame;
//        rect.size.height = height;
//        [searchingLabel setFrame:rect];
//        [searchingLabel setTextColor:[UIColor whiteColor]];
//       
//        searchingLabel.tag = 1;
//        searchingLabelView = [[UIView alloc] initWithFrame:self.shadeView.bounds];
//        [searchingLabelView addSubview:searchingLabel];
//        
//        UILabel *elipseLabel = [[UILabel alloc] initWithFrame:CGRectMake(
//                                                                         searchingLabel.frame.origin.x + searchingLabel.frame.size.width,
//                                                                         searchingLabel.frame.origin.y,
//                                                                         100, height)];
//        elipseLabel.tag = 2;
//        [elipseLabel setText:@""];
//        [elipseLabel setFont:searchingLabel.font];
//        [elipseLabel setTextColor:[UIColor whiteColor]];
//        [elipseLabel setBackgroundColor:[UIColor clearColor]];
//        
//        [searchingLabelView addSubview:elipseLabel];
//        
//        
//    }
//    return searchingLabelView;
//}




-(void)viewWillDisappear:(BOOL)animated
{
    [super viewWillDisappear:animated];
    
    
}


//is calld after layout is determined for "tableView" due to constraints and scren size.  If you do this in
//view did load, you will get incorrect sizes of tableView, necessary because tableview is upside down!



-(void)viewWillLayoutSubviews
{
    [self.tableView setTransform:CGAffineTransformMakeRotation(-M_PI)];
    [self.pmTableView setTransform:CGAffineTransformMakeRotation(-M_PI)];
    
    //stuff here!lol ok!
    

}
-(void)viewDidLayoutSubviews
{
    
    {
        [self.pmTableViewContainer setFrame:CGRectMake(WIDTH_OF_PM_LIST, 0, self.view.frame.size.width-WIDTH_OF_PM_LIST, self.view.frame.size.height)];
        [self.pmTableViewContainer setClipsToBounds:YES];//CGRectMake(WIDTH_OF_PM_LIST+900, 100, 50,50)];// 5, self.view.frame.size.height)]

        CGRect tvRect = self.pmTableViewContainer.bounds;
        tvRect.size.width -=2;
        [self.pmTableView setFrame:tvRect];
        [self.pmUsersTableView setContentInset:UIEdgeInsetsMake(14, 0, 0, 0)];
        [self.view insertSubview:self.pmTableViewContainer atIndex:0];
        [self.pmTableView setSeparatorColor:[UIColor redColor]];
        
        [self.pmTableView setDelegate:self];
        [self.pmTableView setDataSource:self];

        [self.pmTableView setBackgroundColor:[UIColor clearColor]];
        [self.pmTableViewContainer setBackgroundColor:[UIColor clearColor]];
    }
    
    //tableView setup goes on here!
    if (!initializedTableView)
    {
        initializedTableView = YES;
        CGFloat bottomEdgeInset = 50;
        self.tableView.frame = CGRectMake(0, 0, self.view.frame.size.width, self.view.frame.size.height);
        //table view is upsid down, so insets beware
//        self.tableView.contentInset = UIEdgeInsetsMake(bottomEdgeInset, 0, HeightOfWhoIsHereView+HeightOfGradient, 0);
        
//        if (self.view.frame.size.height == 480 || self.view.frame.size.height == 460)
//        {
//            // fix for 3.5" screen is 88px shorter than the 4". yuckys
//            
            self.tableView.contentInset = UIEdgeInsetsMake(bottomEdgeInset+(568-self.view.frame.size.height), 0, HeightOfWhoIsHereView+HeightOfGradient, 0);
//        }
        
    }//end of tableview setup
    
    [self.view layoutSubviews];
    
}

-(void)updateViewConstraints
{
    [super updateViewConstraints];
    if (!self.composeBarView)
    {//make sure updateViewConstraint being called doesn't mean loadComposeBarView always gets initialized.  Not sure when this function happens
        [self loadComposeView];
    }
}


- (void)loadComposeView
{
    CGRect viewBounds = self.view.bounds;
    
    NSLog(@"%f", viewBounds.origin.x);
    
    //try to set constraints on this object
//    NSLayoutConstraint *constraint = [NSLayoutConstraint constraint]
    
    CGRect frame = CGRectMake(0.0f,
                              viewBounds.size.height - PHFComposeBarViewInitialHeight,
                              self.view.frame.size.width,
                              PHFComposeBarViewInitialHeight);
    self.composeBarView = [[PHFComposeBarView alloc] initWithFrame:frame];
    [self.composeBarView setMaxCharCount:160];
    [self.composeBarView setMaxLinesCount:5];

//    [self.composeBarView setUtilityButtonImage:[UIImage imageNamed:[NSString stringWithFormat:@"%@",self.owner.icon]]];
    [self.composeBarView setDelegate:self];
    
    // Style the compose bar view
    [self setComposeBarWithRandomHint];
    

    [self.contentView addSubview:self.composeBarView];

    
    
    UIView *composeBarView = self.composeBarView;
//    NSArray *fixedHeight = [NSLayoutConstraint constraintsWithVisualFormat:[NSString stringWithFormat:@"H:[composeBarView(==%d)]", (int)PHFComposeBarViewInitialHeight ]
//                                                                              options:0
//                                                                              metrics:nil
//                                                                     views:NSDictionaryOfVariableBindings(composeBarView)];
//    [self.composeBarView addConstraints:fixedHeight];
    
    
//    [self.composeBarView addConstraints:[NSLayoutConstraint constraintsWithVisualFormat:[NSString stringWithFormat:@"V:[composeBarView(==%d)]", (int)320 ]
//                                                                                options:0
//                                                                                metrics:nil
//                                                                                  views:NSDictionaryOfVariableBindings(composeBarView)]];
    NSLayoutConstraint *constraint1Y =  [NSLayoutConstraint constraintWithItem:composeBarView
                                                                 attribute:NSLayoutAttributeTop
                                                                 relatedBy:NSLayoutRelationEqual
                                                                    toItem:self.contentView
                                                                 attribute:NSLayoutAttributeBottom
                                                                multiplier:1.0
                                                                  constant:-PHFComposeBarViewInitialHeight];
    [self.contentView addConstraint:constraint1Y];
    
    NSLayoutConstraint *constraint2CenterX =  [NSLayoutConstraint constraintWithItem:composeBarView
                                                                   attribute:NSLayoutAttributeCenterX
                                                                   relatedBy:NSLayoutRelationEqual
                                                                      toItem:self.contentView
                                                                   attribute:NSLayoutAttributeCenterX
                                                                  multiplier:1.0
                                                                    constant:0];
    [self.contentView addConstraint:constraint2CenterX];
    
    
    
}

- (void)dealloc
{
    [self.wallRef removeObserverWithHandle:self.bindToWallHandle];
    [self.userPmListRef removeObserverWithHandle:self.bindToUserPmListHandle];
    [self.userPmListRef removeObserverWithHandle:self.removeFromUserPmListHandle];
    [self.trackingRef removeObserverWithHandle:trackingHandle];
    [self.view removeObserver:self forKeyPath:@"frame"];
    [[NSNotificationCenter defaultCenter] removeObserver:self];
}


-(void)dismissKeyboard
{
    [self.composeBarView resignFirstResponder];
}

- (void)didReceiveMemoryWarning
{
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

# pragma mark - firebase

- (void)bindToTracking
{
    self.trackingRef = [self.owner.ref childByAppendingPath:@"tracking"];
    __weak typeof(self) weakSelf = self;
    trackingHandle = [self.trackingRef observeEventType:FEventTypeValue withBlock:^(FDataSnapshot *snapshot)
    {
        NSLog(@"tracking users update!");
        if ([snapshot value] && [snapshot value] != [NSNull null])
        {
            NSLog(@"Tracking length is %lu",(unsigned long)[snapshot.value count]);
            [weakSelf updatePeopleNearby:(int)[snapshot.value count]];
            
            //setter for tracking updates UI
            weakSelf.tracking = [snapshot.value allKeys];
            
        } else
        {
            NSLog(@"Count is nothing! %@", snapshot.value);
            [weakSelf updatePeopleNearby:0];
            
            weakSelf.tracking = @[ ];
        }
    }];
    
    
}

//this setter expects an array of user ids.  It is used to fade in/out messages based on whether that userId is in range (i.e., in tracking array).  this setter updates UI.
-(void)setTracking:(NSArray *)Tracking
{
    tracking = Tracking;
    
    for (UITableViewCell *messageCell in tableView.visibleCells)
    {
        if ([messageCell isKindOfClass:[FCMessageCell class]])
        {
            FCMessageCell *fcMssageCell = (FCMessageCell*)messageCell;
            BOOL isTracked = [self isUserBeingTracked:fcMssageCell.ownerID];
            
            [fcMssageCell setFaded:!isTracked animated:YES];
        }
    }
}

//uses tracking array to determine if the current user is being tracked.  Also, it returns YES for ids that are yourself / the welcome bot
-(BOOL)isUserBeingTracked:(NSString*)userId
{
    if ([[FCUser owner].id isEqualToString:userId] || [userId isEqualToString:@"Welcome:Bot"])
        return YES;
    
    NSPredicate *predicate = [NSPredicate predicateWithFormat:@"(SELF == %@)", userId];
    NSArray *results = [tracking filteredArrayUsingPredicate:predicate];
    
    return results.count;
}

//handles adding users to the pmUserList for displayed on the right panel.
-(void) bindToUserPmList
{
    
    self.userPmListRef = [self.owner.ref childByAppendingPath:@"userPmList"];
    NSLog(@"self.userPmListRf = %@", self.userPmListRef);
    
    __weak typeof(self) weakSelf = self;
    self.bindToUserPmListHandle = [self.userPmListRef observeEventType:FEventTypeChildAdded withBlock:^(FDataSnapshot *snapshot)
   {
       NSLog(@"added pm user");
       
       if ([snapshot.value isKindOfClass:[NSDictionary class]])
       {

           NSDictionary *userDict = snapshot.value;
           
           //here are my keys
           NSString *userId = [userDict objectForKey:@"theirUserId"];
//           NSString *userColor = [userDict objectForKey:@"theirColor"];
//           NSString *icon = [userDict objectForKey:@"theirIcon"];
           
           NSInteger indexOfPmUser = [weakSelf.userPmList indexOfObject:userDict];
           
           NSLog(@"indexOfPmUser = %d", indexOfPmUser);
           NSLog(@"%@", (indexOfPmUser == NSNotFound ? @"not found" : @"found"));
           
           
           //animate an insert in this tableView
           if (indexOfPmUser == NSNotFound)
           {
               [weakSelf.pmUsersTableView beginUpdates];

               [weakSelf.userPmList addObject:userDict];
               
               NSIndexPath *indexPath = [NSIndexPath indexPathForRow:weakSelf.userPmList.count-1 inSection:0];
               [weakSelf.pmUsersTableView insertRowsAtIndexPaths:@[indexPath] withRowAnimation:UITableViewRowAnimationFade];
               [weakSelf.pmUsersTableView endUpdates];
           }
           
           
           //maybe this is occuring because I just tapped on a user, if that's the case justAddPmWithUserId is not nil
           if (weakSelf.justAddPmWithUserId && [weakSelf.justAddPmWithUserId isEqualToString:userId])
           {
               weakSelf.justAddPmWithUserId = nil;
               
               [weakSelf didSelectPmWithUserAtIndex:[NSNumber numberWithInt:weakSelf.userPmList.count-1]];
           }
       }
   }];
    
    self.removeFromUserPmListHandle = [self.userPmListRef observeEventType:FEventTypeChildRemoved withBlock:^(FDataSnapshot *snapshot)
    {
        
        NSLog(@"removed pm user");
        
       if ([snapshot.value isKindOfClass:[NSDictionary class]])
       {
           
//           NSDictionary *userDict = snapshot.value;
           
           //here are my keys
//           NSString *userId = [userDict objectForKey:@"withUserId"];
//           NSString *userColor = [userDict objectForKey:@"userColor"];
//           NSString *icon = [userDict objectForKey:@"userIcon"];
           
           
       }
    }];
}

- (void)bindToWall
{
    self.wallRef = [self.owner.ref childByAppendingPath:@"wall"];
    // Watch for changes
    
    __weak typeof(self) weakSelf = self;

    
    self.bindToWallHandle = [self.wallRef observeEventType:FEventTypeChildAdded withBlock:^(FDataSnapshot *snapshot)
    {
            if ([snapshot.value isKindOfClass:[NSDictionary class]])
            {
            
                if ([[snapshot.value objectForKey:@"type"] isEqualToString:@"ESSwapUserStateMessage"])
                {
                    ESSwapUserStateMessage *swapMsg = [[ESSwapUserStateMessage alloc] initWithSnapshot:snapshot];
                    

                    [weakSelf.wall insertObject:swapMsg atIndex:0];
                    NSArray *paths = [NSArray arrayWithObject:[NSIndexPath indexPathForRow:0 inSection:0]];
                    [weakSelf.tableView insertRowsAtIndexPaths:paths withRowAnimation:UITableViewRowAnimationTop];
                    
                    // Scroll to the new message
                    if (!weakSelf.autoScrollLockTimer)
                    {
                        [weakSelf.tableView scrollToRowAtIndexPath:[NSIndexPath indexPathForRow:0 inSection:0] atScrollPosition:UITableViewScrollPositionTop animated:YES];
                    }
                    [weakSelf updateLine];
                    
                    //timer to prform some operation on this cell
                    
                } else
                {//implies type isEqual "ESMessage" or no type exists or self message
                    
                    FCMessage *message = [[FCMessage alloc] initWithSnapshot:snapshot];
                    // Init a new message
                    [weakSelf.wall insertObject:message atIndex:0];
                    NSArray *paths = [NSArray arrayWithObject:[NSIndexPath indexPathForRow:0 inSection:0]];
                    [weakSelf.tableView insertRowsAtIndexPaths:paths withRowAnimation:UITableViewRowAnimationTop];
                    
                    // Scroll to the new message
                    if (!weakSelf.autoScrollLockTimer)
                    {
                        [weakSelf.tableView scrollToRowAtIndexPath:[NSIndexPath indexPathForRow:0 inSection:0] atScrollPosition:UITableViewScrollPositionTop animated:YES];
                    }
                    [weakSelf updateLine];
                }
                
                [weakSelf.pmTableView reloadData];
            }
//        }
    } withCancelBlock:^(NSError *someError)
    {
        NSLog(@"error = %@", someError.localizedDescription);
    }];
}

#pragma mark - custom Table View delegate methods
-(void)tableView:(UITableView*)tV didLongPressCellAtIndexPath:(NSIndexPath*)indexPath
{
    if (tV == self.tableView)
    {
        NSLog(@"definitely long press on %@", indexPath);
        [self startPmWithWallMessage:indexPath.row];
    }
}
-(void)tableView:(UITableView *)tV didDoubleTapCellAtIndexPath:(NSIndexPath *)indexPath
{
    if (tV == self.tableView)
    {
        NSLog(@"definitely double tap on  press on %@", indexPath);
        [self startPmWithWallMessage:indexPath.row];
    }
}

//setter automatically deslects the last selectd index
//-(void)selectedUserPmIndex:(int)index
//{
//    
//    if (selectedUserPmIndex != -1)
//    {//stop glowing last cell
//        ESUserPMCell *lastSelectedCell = (ESUserPMCell *)[self.pmUsersTableView cellForRowAtIndexPath:[NSIndexPath indexPathForRow:selectedUserPmIndex inSection:0]];
//        if (lastSelectedCell)
//        {
//            [lastSelectedCell mySetSelected:NO];
//        }
//    }
//    selectedUserPmIndex = index;
//}


-(void)startPmWithWallMessage:(NSInteger)index
{
    FCMessage *fcMessage = [self.wall objectAtIndex:index];
    
//    if (selectedUserPmIndex != -1)
//    {//stop glowing last cell
//        ESUserPMCell *lastSelectedCell = (ESUserPMCell *)[self.pmUsersTableView cellForRowAtIndexPath:[NSIndexPath indexPathForRow:selectedUserPmIndex inSection:0]];
//        if (lastSelectedCell)
//        {
//            [lastSelectedCell mySetSelected:NO];
//        }
//    }
//    selectedUserPmIndex = index;

    self.selectedUserPmIndex = index;
    
    
    NSAssert( [fcMessage isKindOfClass:[FCMessage class]], @"someMessageObject needs to be FCMessage, %@", fcMessage);
    
    NSString *theirId = fcMessage.ownerID;
    self.justAddPmWithUserId = theirId; //listen for the callback on self.userPmListRef childAdded event
    NSString *theirIcon = fcMessage.icon;
    NSString *theirColor = fcMessage.color;
    
    
    /*
     theirUserId: userId,
     theirColor: color,
     theirIcon: icon,
     */
    NSDictionary *newPmUserDict = @{@"theirUserId": theirId,
                                    @"theirIcon": theirIcon,
                                    @"theirColor": theirColor};
    
    [ [self.userPmListRef childByAutoId] setValue:newPmUserDict];
    
}

#pragma mark - Table view data source


-(void)didSelectPmWithUserAtIndex:(NSNumber*)indexNumber
{
    NSLog(@"selected user %@", indexNumber);
    
    if (selectedUserPmIndex != -1)
    {//stop glowing last cell
        ESUserPMCell *lastSelectedCell = (ESUserPMCell *)[self.pmUsersTableView cellForRowAtIndexPath:[NSIndexPath indexPathForRow:selectedUserPmIndex inSection:0]];
        if (lastSelectedCell)
        {
            [lastSelectedCell mySetSelected:NO];
        }
    }
//    selectedUserPmIndex = indexNumber.intValue;
    self.selectedUserPmIndex = indexNumber.intValue;//also does deselect the last one
    ESUserPMCell *userPMCell = (ESUserPMCell *)[self.pmUsersTableView cellForRowAtIndexPath:[NSIndexPath indexPathForRow:selectedUserPmIndex inSection:0]];
    if (userPMCell)
    {
        [userPMCell mySetSelected:YES];
    }
    
    
    self.wallState = WallStatePM;
    
    [UIView animateWithDuration:0.6f delay:0.0f usingSpringWithDamping:1.6f initialSpringVelocity:0.0f options:UIViewAnimationOptionCurveLinear animations:^
    {
        CGRect contentFrame = self.contentView.frame;
        contentFrame.origin.x = -contentFrame.size.width;
        
        [self.contentView setFrame:contentFrame];
        
        CGRect pmListViewRect = self.pmListContainerView.frame;
        pmListViewRect.origin.x = 0;
        [self.pmListContainerView setFrame:pmListViewRect];
        
    } completion:^(BOOL finished){}];
}

//-(void)tableView:(UITableView *)tV didSelectRowAtIndexPath:(NSIndexPath *)indexPath
//{
//    
//    if (tV == self.tableView)
//    {
//        NSLog(@"add pm!");
//    } else
//    if (tV == self.pmUsersTableView)
//    {
//        NSLog(@"begin pm!");
//    }
//}

- (NSInteger)numberOfSectionsInTableView:(UITableView *)tableView
{
    // Return the number of sections.
//    NSLog(@"ASKED FOR SECTIONS");
    return 1;
}

- (NSInteger)tableView:(UITableView *)tV numberOfRowsInSection:(NSInteger)section
{
    if (tV == self.tableView)
    {
        return [self.wall count];
    } else
    if (tV == self.pmUsersTableView)
    {
        return [userPmList count];
    } else
    if (tV == self.pmTableView)
    {
        NSInteger count = [self.currentPrivateMessages count];
        return count;
    }
    return 0;
}

- (UITableViewCell*)tableView:(UITableView *)tV cellForRowAtIndexPath:(NSIndexPath *)indexPath
{
    if (tableView == tV)
    {
        id unknownTypeOfMessage = [self.wall objectAtIndex:indexPath.row];
    
        if ([unknownTypeOfMessage isKindOfClass:[FCMessage class]])
        {
            FCMessage *message = unknownTypeOfMessage;
            
            static NSString *CellIdentifier = @"MessageCell";
            static NSString *ownerCellIdentifire = @"OwnerMessageCell";
            
            
            FCMessageCell *cell;
            if ([[FCUser owner].id isEqualToString:message.ownerID])
            {
                cell = [tableView dequeueReusableCellWithIdentifier:ownerCellIdentifire forIndexPath:indexPath];
            } else
            {
                cell = [tableView dequeueReusableCellWithIdentifier:CellIdentifier forIndexPath:indexPath];
//                [cell initializeLongPress];
//                [cell initializeDoubleTap];
            }
            
            if (DEBUG_SHOW_USER_ID_SINGLE_TAP)
            {//setup a single tap alert, who does this message belong to?
                [cell addTapDebugGestureIfNecessary];
            }
            
            
            // Flip the cell 180 degrees
            cell.transform = CGAffineTransformMakeRotation(M_PI);
            
            
            
            // Set message cell values
            [cell setMessage:message];
            
            //associate cells with owners, to fade out owners who are not in range when cell is served or tracking changes!
            cell.ownerID = message.ownerID;
            
            
            //check tracking for this person b4 serving cell to the tableview
            BOOL userIsInTracking = [self isUserBeingTracked:cell.ownerID];
            
            [cell setFaded:!userIsInTracking animated:NO];

            return cell;
        } else
        if ([unknownTypeOfMessage isKindOfClass:[ESSwapUserStateMessage class]])
        {
            static NSString *swapIdentifier = @"SwapCell";
            
            ESSwapUserStateMessage *message = unknownTypeOfMessage;
            ESSwapUserStateCell *cell = [tableView dequeueReusableCellWithIdentifier:swapIdentifier forIndexPath:indexPath];
            
            // [cell setBackgroundColor:[UIColor yellowColor]];
            
            // Flip the cell 180 degrees
            cell.transform = CGAffineTransformMakeRotation(M_PI);
            [cell setFromColor:message.fromColor andIcon:message.fromIcon toColor:message.toColor andIcon:message.toIcon];
            
            if (!message.hasDoneFirstTimeAnimation)
            {
                message.hasDoneFirstTimeAnimation = YES;
                
                [cell doFirstTimeAnimation];
            }
            
            return cell;
        }
    } else
    if (self.pmUsersTableView == tV)
    {
        ESUserPMCell *pmCell = [self.pmUsersTableView dequeueReusableCellWithIdentifier:@"pm"];
        
        NSDictionary *pmUserData = [self.userPmList objectAtIndex:indexPath.row];
//        NSString *theirId = [pmUserData objectForKey:@"theirUserId"];
        NSString *theirColor = [pmUserData objectForKey:@"theirColor"];
        NSString *theirIcon = [pmUserData objectForKey:@"theirIcon"];
        
        
        //set their color
        [pmCell setColor:theirColor andImage:theirIcon];
        pmCell.tag = indexPath.row;
        
        //glow to the color if it is selected, else do not
        if (indexPath.row == self.selectedUserPmIndex)
        {
            [pmCell mySetSelected:YES];
        } else
        {
            [pmCell mySetSelected:NO];
        }
        

        return pmCell;
    } else
    if (self.pmTableView == tV)
    {
        id unknownTypeOfMessage = [self.currentPrivateMessages objectAtIndex:indexPath.row];
        
        if ([unknownTypeOfMessage isKindOfClass:[FCMessage class]])
        {
            FCMessage *message = unknownTypeOfMessage;
            
            static NSString *CellIdentifier = @"MessageCell";
            static NSString *ownerCellIdentifire = @"OwnerMessageCell";
            
            
            FCMessageCell *cell;
            if ([[FCUser owner].id isEqualToString:message.ownerID])
            {
                cell = [tableView dequeueReusableCellWithIdentifier:ownerCellIdentifire forIndexPath:indexPath];
            } else
            {
                cell = [tableView dequeueReusableCellWithIdentifier:CellIdentifier forIndexPath:indexPath];
            }
            
            // [cell setBackgroundColor:[UIColor yellowColor]];
            
            // Flip the cell 180 degrees
            cell.transform = CGAffineTransformMakeRotation(M_PI);
            
            
            
            // Set message cell values
            [cell setMessage:message];
            
            BOOL isFaded = NO;//!beaconFound && !messageBelongsToMe && ![message.ownerID isEqualToString:@"Welcome:Bot"];
            
            [cell setFaded:isFaded animated:NO];
            
            return cell;
        }  else
        if ([unknownTypeOfMessage isKindOfClass:[ESSwapUserStateMessage class]])
        {
            static NSString *swapIdentifier = @"SwapCell";
            
            ESSwapUserStateMessage *message = unknownTypeOfMessage;
            ESSwapUserStateCell *cell = [tableView dequeueReusableCellWithIdentifier:swapIdentifier forIndexPath:indexPath];
            
            // [cell setBackgroundColor:[UIColor yellowColor]];
            
            // Flip the cell 180 degrees
            cell.transform = CGAffineTransformMakeRotation(M_PI);
            [cell setFromColor:message.fromColor andIcon:message.fromIcon toColor:message.toColor andIcon:message.toIcon];
            
            if (!message.hasDoneFirstTimeAnimation)
            {
                message.hasDoneFirstTimeAnimation = YES;
                
                [cell doFirstTimeAnimation];
            }
            
            return cell;
        }
    }
    return nil;
}

-(void)singleTapDebugGestureAction:(UITapGestureRecognizer*)tapGesture
{
    NSLog(@"DEBUG TAP %@ ", tapGesture);
    
}

- (CGFloat) tableView:(UITableView *)tV heightForRowAtIndexPath:(NSIndexPath *)indexPath
{
    if (tV == self.tableView)
    {
        if (indexPath.row >= self.wall.count)
        {
            return 0.0f;
        }
        id unknownType = [self.wall objectAtIndex:indexPath.row];

        if ([unknownType isKindOfClass:[FCMessage class]])
        {

            FCMessage *message = [self.wall objectAtIndex:indexPath.row];
            
            UIFont *font = [UIFont fontWithName:@"HelveticaNeue-Light" size:13];
            CGSize constraintSize = {225.0f, 700};
            CGSize actualSize = [message.text sizeWithFont:font constrainedToSize:constraintSize];
            CGFloat height = MAX(actualSize.height+14.0f*2, 75.0f);//14 is top and bottom padding of label
            return height;
        } else
        if ([unknownType isKindOfClass:[ESSwapUserStateMessage class] ] )
        {
            return 50;
        }
    } else
    if (tV == self.pmUsersTableView)
    {
        return WIDTH_OF_PM_LIST;
    } else
    if (tV == self.pmTableView)
    {
        if (indexPath.row >= self.currentPrivateMessages.count)
        {
            return 0.0f;
        }
        id unknownType = [self.currentPrivateMessages objectAtIndex:indexPath.row];
        
        if ([unknownType isKindOfClass:[FCMessage class]])
        {
            
            FCMessage *message = [self.wall objectAtIndex:indexPath.row];
            
            UIFont *font = [UIFont fontWithName:@"HelveticaNeue-Light" size:13];
            CGSize constraintSize = {225.0f, 700};
            CGSize actualSize = [message.text sizeWithFont:font constrainedToSize:constraintSize];
            CGFloat height = MAX(actualSize.height+14.0f*2, 75.0f);//14 is top and bottom padding of label
            return height;
        } else
        if ([unknownType isKindOfClass:[ESSwapUserStateMessage class] ] )
        {
            return 50;
        }
    }
    return 0;


}

# pragma mark - keyboard did show/hide
// Handles the resizing on a keyboard show or hide event
- (void)keyboardWillToggle:(NSNotification *)notification {
    
    
    
    NSDictionary* userInfo = [notification userInfo];
    
    NSTimeInterval duration;
    UIViewAnimationCurve animationCurve;
    CGRect startFrame;
    CGRect endFrame;
    [[userInfo objectForKey:UIKeyboardAnimationDurationUserInfoKey] getValue:&duration];
    [[userInfo objectForKey:UIKeyboardAnimationCurveUserInfoKey]    getValue:&animationCurve];
    [[userInfo objectForKey:UIKeyboardFrameBeginUserInfoKey]        getValue:&startFrame];
    [[userInfo objectForKey:UIKeyboardFrameEndUserInfoKey]          getValue:&endFrame];
    
    NSInteger signCorrection = 1;
    if (startFrame.origin.y < 0 || startFrame.origin.x < 0 || endFrame.origin.y < 0 || endFrame.origin.x < 0)
        signCorrection = -1;
    
    CGFloat widthChange  = (endFrame.origin.x - startFrame.origin.x) * signCorrection;
    CGFloat heightChange = (endFrame.origin.y - startFrame.origin.y) * signCorrection;
    
    CGFloat sizeChange = UIInterfaceOrientationIsLandscape([self interfaceOrientation]) ? widthChange : heightChange;
    
    keyboardIsVisible = (sizeChange < 0);
    keyboardRect = [[userInfo objectForKey:@"UIKeyboardFrameEndUserInfoKey"] CGRectValue];
    
//    CGRect newContainerFrame = [[self tableView] frame];
//    newContainerFrame.size.height += sizeChange;
    
    CGRect newComposeBarFrame = [[self composeBarView] frame];
    newComposeBarFrame.origin.y += sizeChange;
    
    CGPoint contentOffset = {0.0f, tableView.contentOffset.y + sizeChange};
    
    //ethan changed this because edge insets is the way to go when resizing from keyboard
//    float bottomEdgeInset = 50;
    UIEdgeInsets edgeInsets = self.tableView.contentInset;// UIEdgeInsetsMake(bottomEdgeInset, 0, HeightOfWhoIsHereView+HeightOfGradient, 0);
    
//    if (self.view.frame.size.height == 480)
//    {
//        // fix for the fact that the 3.5" screen is 88px shorter than the 4"
//        edgeInsets = UIEdgeInsetsMake(bottomEdgeInset+88, 0, HeightOfWhoIsHereView+HeightOfGradient, 0);
//    }
//    if (keyboardIsVisible)
//    {
        edgeInsets.top -= sizeChange;
//    }
//    self.tableView.contentInset;
//    edgeInsets.top -= sizeChange;
    
    
    [UIView animateWithDuration:duration
                          delay:0
                        options:(animationCurve << 16)|UIViewAnimationOptionBeginFromCurrentState
                     animations:^
                    {
//                         [[self tableView] setFrame:newContainerFrame];
//                        [self.tableView setContentInset:edgeInsets];    //edges pull content on bottom
                        [self.tableView setContentOffset:contentOffset];//scrollview scroll up
                        
                        NSLog(@"edgeInset <- %@", NSStringFromUIEdgeInsets(edgeInsets));
                        
                        
                        [[self tableView] setContentInset:edgeInsets];
                         [[self composeBarView] setFrame:newComposeBarFrame]; //move composeBarView up
                    } completion:NULL];
    
    // If the keyboard is coming up, broadcast as an iBeacon to sync surrounding users
    if (heightChange < 0) {
        [self.owner.beacon chirpBeacon];
    }
    
}
- (void)composeBarViewDidPressUtilityButton:(PHFComposeBarView *)composeBarView {
    NSLog(@"Utility button pressed");
}

// Pressed "send"
- (void)composeBarViewDidPressButton:(PHFComposeBarView *)composeBarView {
    // Send the message
    FCMessage *message = [[FCMessage alloc] init];
    
    FCUser *owner = [FCUser owner];
    CLLocation *location = [owner.beacon getLocation];
    message.location = location;
    
//    message.lat =
//    message.lon = ;
    [message postText:self.composeBarView.text asOwner:self.owner];
    [composeBarView setText:@"" animated:YES];
    [self.composeBarView resignFirstResponder];
}

// Handle growing/shrinking
- (void)composeBarView:(PHFComposeBarView *)composeBarView
   willChangeFromFrame:(CGRect)startFrame
               toFrame:(CGRect)endFrame
              duration:(NSTimeInterval)duration
        animationCurve:(UIViewAnimationCurve)animationCurve
{
    
    // Calc the offset
    CGFloat sizeChange = endFrame.size.height - startFrame.size.height;
    CGRect newFrame = [self.tableView frame];
    newFrame.origin.y -= sizeChange;
    // Animate the scrollview to match
    
    sizeChange *= -1;
    CGPoint contentOffset = {0.0f, tableView.contentOffset.y + sizeChange};
    //ethan changed this because edge insets is the way to go when resizing from keyboard
    UIEdgeInsets edgeInsets = self.tableView.contentInset;
    edgeInsets.top -= sizeChange;
    
    [self.tableView setContentInset:edgeInsets];
    [self.tableView setContentOffset:contentOffset];
}



-(CGAffineTransform)transformForTableViewMask
{
    return CGAffineTransformMakeTranslation(0, self.tableView.contentOffset.y);
}

-(void)scrollViewDidScroll:(UIScrollView *)scrollView
{
    if (scrollView == tableView)
    {
        [self updateLine];
        
        self.scrollSpeed = scrollView.contentOffset.y - self.previousScrollViewYOffset;
        self.previousScrollViewYOffset = scrollView.contentOffset.y;
        
    }
}
-(void)scrollViewDidEndDragging:(UIScrollView *)scrollView willDecelerate:(BOOL)decelerate
{
//    NSLog(@"scrollViewDidEndDragging:willDecelerate:%d", decelerate);
    
    if (scrollView == self.tableView && !decelerate)
    {
        [self ifTableViewIsNotAtBottomStartATimer];
    }
}
-(void)scrollViewDidEndDecelerating:(UIScrollView *)scrollView
{
//    NSLog(@"scrollViewDidEndDecelerating");
    [self ifTableViewIsNotAtBottomStartATimer];
}
-(void)scrollViewDidEndScrollingAnimation:(UIScrollView *)scrollView
{
//    NSLog(@"scrollViewDidEndScrollingAnimation");
    if (scrollView == self.tableView)
    {
        [self ifTableViewIsNotAtBottomStartATimer];
    }
}

-(void)ifTableViewIsNotAtBottomStartATimer
{
//    NSLog(@"self.tableView = %f", self.tableView.contentOffset.y);
//    NSLog(@"edgeinset top = %f", self.tableView.contentInset.top);
    
    if (self.tableView.contentOffset.y + self.tableView.contentInset.top == 0)
    {
//        NSLog(@"ok we ar at the bottom of the scroll view");
        [self cleanUpAutoScrollLockTimer:nil];
        
    } else
    {
//        NSLog(@"begin the autoScrollLockTimer");
        //begin the autoScrollLockTimer
        if (autoScrollLockTimer)
        {
            [autoScrollLockTimer invalidate];
            autoScrollLockTimer = nil;
        }
        autoScrollLockTimer = [NSTimer timerWithTimeInterval:5 target:self selector:@selector(cleanUpAutoScrollLockTimer:) userInfo:nil repeats:NO];
        [[NSRunLoop mainRunLoop] addTimer:autoScrollLockTimer forMode:NSDefaultRunLoopMode];
    }
}
-(void)cleanUpAutoScrollLockTimer:(NSTimer*)theTimr
{
    [autoScrollLockTimer invalidate];
    autoScrollLockTimer = nil;
}

#pragma mark UICollectionViewDelegate, UICollectionViewDataSource start

-(NSInteger)numberOfSectionsInCollectionView:(UICollectionView *)collectionView
{
    return 1;
}

-(NSInteger)collectionView:(UICollectionView *)collectionView numberOfItemsInSection:(NSInteger)section
{
    
    FCUser *owner = [FCUser owner];
    NSInteger numberOfBecons = (!owner) ? 0 :  [owner.beacon earshotUsers].count;
    
    NSInteger returnValue = numberOfBecons + 1;//change this value for now
    
    if (returnValue != lastNumberOfPeopleInCollectionView)
    {
        lastNumberOfPeopleInCollectionView = returnValue;
        CGFloat span = 50*returnValue+(10*returnValue-1);
        CGFloat leftInset = MAX((self.view.frame.size.width - span)/2, 10); //center the cells
        
//        [UIView animateWithDuration:1 delay:0.0f usingSpringWithDamping:1 initialSpringVelocity:0.0f options:UIViewAnimationOptionCurveLinear animations:^
//        {
            [collectionView setContentInset:UIEdgeInsetsMake(0, leftInset, 0, 0)];
//        } completion:^(BOOL finished){}];
    }
    
    return returnValue;
}
-(UICollectionViewCell*)collectionView:(UICollectionView *)collectionView cellForItemAtIndexPath:(NSIndexPath *)indexPath
{
    UICollectionViewCell *collectionViewCell = [collectionView dequeueReusableCellWithReuseIdentifier:@"ProfileCollectionViewCell" forIndexPath:indexPath];
    
    NSLog(@"collectionViewCell = %@", collectionViewCell);
    return collectionViewCell;
}

-(void)randomBing
{
    NSLog(@"randomBing");
    NSInteger randomInteger = esRandomNumberIn(0, [self collectionView:whoIsHereCollectionView numberOfItemsInSection:0]);
    
    ProfileCollectionViewCell *pcvc = (ProfileCollectionViewCell *)[whoIsHereCollectionView cellForItemAtIndexPath:[NSIndexPath indexPathForItem:randomInteger inSection:0]];
    if (!pcvc)
    {
        return;
    }
    [pcvc boop];
    
}


#pragma mark UICollectionViewDelegate, UICollectionViewDataSource end


#pragma mark trickle-down touche-event
//test to see if it is on the keyboard, and light up firebase reference to onOff if yes
-(void)receiveTouchEvent:(UIEvent*)touchEvent
{
    if (keyboardIsVisible)
    {
        NSSet *allTouches = [touchEvent allTouches];
        for (UITouch *touch in allTouches)
        {
            CGPoint position = [touch locationInView:self.view];
            
            FCUser *owner = [FCUser owner];
            
            if (touch.phase == UITouchPhaseBegan &&
                CGRectContainsPoint(keyboardRect, position))
            {
                [owner.onOffRef setValue:[NSNumber numberWithBool:YES]];

            } else
            if (touch.phase == UITouchPhaseEnded)
            {
                [owner.onOffRef setValue:[NSNumber numberWithBool:NO]];

            }
        }
    }
}

#pragma mark called by FCWallViewController when initializing this ViewController as the next
-(void)beginTransitionWithIcon:(UIImage*)image andFrame:(CGRect)frame andColor:(UIColor*)backgroundColor andResetFrame:(CGRect)resetIconFrame isAnimated:(BOOL)animated
{
    self.presentAnimated = animated;
    self.needsToDoTransitionWithShadeView = YES;
    self.shadeView = [[UIView alloc] initWithFrame:[UIScreen mainScreen].bounds];
    self.shadeView.tag = 617;
    [self.shadeView setBackgroundColor:backgroundColor];
    
    
    
    self.iconButton = [UIButton buttonWithType:UIButtonTypeCustom];
    
    //input for sizing down image
    self.buttonImageInset = 4.5;
    UIEdgeInsets insets = UIEdgeInsetsMake(buttonImageInset, buttonImageInset, buttonImageInset, buttonImageInset);
    [self.iconButton setContentEdgeInsets:insets];
    
    [self.iconButton setUserInteractionEnabled:NO];
    //correct image to be correct size despite edge inset
    frame.origin.y -= buttonImageInset;
    frame.origin.x -= buttonImageInset;
    frame.size.width += 2*buttonImageInset;
    frame.size.height += 2*buttonImageInset;
    
    resetIconFrame.origin.y -= buttonImageInset;
    resetIconFrame.origin.x -= buttonImageInset;
    resetIconFrame.size.width += 2*buttonImageInset;
    resetIconFrame.size.height += 2*buttonImageInset;
    
    [self.iconButton setFrame:frame];
    self.originalRectOfIcon = resetIconFrame;
    [self.iconButton setImage:image forState:UIControlStateNormal];
    [self.iconButton.imageView setContentMode:UIViewContentModeScaleAspectFit];
    [self.iconButton addTarget:self action:@selector(iconButtonAction:) forControlEvents:UIControlEventTouchUpInside];
    
    //[[UIImageView alloc] initWithFrame:frame];
                 
                 //CGRectMake((self.shadeView.frame.size.width-50)*0.5f, (self.shadeView.frame.size.height-50)*0.5f, 50, 50)];

    [self.iconButton setContentMode:UIViewContentModeScaleAspectFit];

    [self.shadeView addSubview:self.iconButton];
}

-(void)iconButtonAction:(UIButton*)iconButtonThe
{
    if (keyboardIsVisible)
    {
        [self.composeBarView.textView resignFirstResponder];
    }
    
    CGRect realPeopleNearbyLabelFrame = self.peopleNearbyLabel.frame;
    //labelMaskView
    CGRect newTargetFrame = realPeopleNearbyLabelFrame;
    newTargetFrame.origin.x = (self.view.frame.size.width*0.5f);
    
    //moving shadeView to the top
    [self.shadeView removeFromSuperview];
    [self.contentView addSubview:self.shadeView];
    
    UINavigationController *navContr = self.navigationController;
    NSMutableArray *vc = [NSMutableArray arrayWithArray:navContr.viewControllers];
    
    UIViewController *landingPageViewController = [vc objectAtIndex:vc.count-2];
    
    [UIView animateWithDuration:0.4f delay:0.0f usingSpringWithDamping:1.0f initialSpringVelocity:10.0f options:UIViewAnimationOptionCurveLinear animations:^
     {
         CGRect frame = self.iconButton.frame;
         frame.origin.x = (self.view.frame.size.width - frame.size.width)*0.5f;
         [self.iconButton setFrame:frame];
         
         [self.labelMaskView setFrame:newTargetFrame];
         [self.peopleNearbyLabel setFrame:newTargetFrame];

     } completion:^(BOOL finished)
     {
         [UIView animateWithDuration:0.7f delay:0.0f usingSpringWithDamping:1.2f initialSpringVelocity:0.0f options:UIViewAnimationOptionCurveLinear animations:^
         {
             
             [self.shadeView setFrame:self.view.bounds];
             
             if (self.originalRectOfIcon.origin.y < 0)
             {
                 CGRect rect = [((FCLandingPageViewController*)landingPageViewController) getOriginalRect];
                 rect.origin.y -= 20;

                 
                 CGRect resetIconFrame = rect;
                 resetIconFrame.origin.y -= buttonImageInset;
                 resetIconFrame.origin.x -= buttonImageInset;
                 resetIconFrame.size.width += 2*buttonImageInset;
                 resetIconFrame.size.height += 2*buttonImageInset;
                 
                  self.originalRectOfIcon = resetIconFrame;
                 

             }
             [self.iconButton setFrame:self.originalRectOfIcon];
         } completion:^(BOOL finished)
         {
//             UINavigationController *navContr = self.navigationController;
//             NSMutableArray *vc = [NSMutableArray arrayWithArray:navContr.viewControllers];
//             
//             UIViewController *landingPageViewController = [vc objectAtIndex:vc.count-2];
             [landingPageViewController performSelector:@selector(resetAsNewAnimated)];
             [vc removeLastObject];
             
             navContr.viewControllers = vc;
         }];
     }];
    
}



-(void)handlePan:(UIPanGestureRecognizer*)panGesture
{
    if (!self.isPanAnimating)
    {
        self.isPanAnimating = YES;
//        CGPoint translation = [panLeftGesture translationInView:self.view];
        CGPoint velocity = [panLeftGesture velocityInView:self.view];

        if (velocity.x < 0 && (self.wallState == WallStateGlobal || self.wallState == WallStatePMUsers))
        {
//            [self.view setUserInteractionEnabled:NO];
            [UIView animateWithDuration:0.8f delay:0.0f usingSpringWithDamping:1.2f initialSpringVelocity:0.0f options:UIViewAnimationOptionCurveLinear animations:^
            {
                CGRect frame = self.contentView.frame;
                frame.origin.x = -WIDTH_OF_PM_LIST;
                [self.contentView setFrame:frame];

            } completion:^(BOOL finished)
            {
                //ready!
                self.wallState = WallStatePMUsers;
                self.isPanAnimating = NO;

            }];
        } else
        {
//            [self.view setUserInteractionEnabled:NO];
            [UIView animateWithDuration:0.4f delay:0.0f usingSpringWithDamping:1.2f initialSpringVelocity:10.0f options:UIViewAnimationOptionCurveLinear animations:^
             {
                 CGRect frame = self.contentView.frame;
                 frame.origin.x = 0;
                 [self.contentView setFrame:frame];
                 
                 CGRect pmListFrame = self.pmListContainerView.frame;
                 pmListFrame.origin.x = (self.contentView.frame.size.width - WIDTH_OF_PM_LIST);
                 self.pmListContainerView.frame = pmListFrame;
             } completion:^(BOOL finished)
             {
                 //ready!
                 self.wallState = WallStateGlobal;
                 self.selectedUserPmIndex = -1;
                  self.isPanAnimating = NO;
             }];
        }
    }
}
//PM stuff
//-(void)handlePanLeft:(UIPanGestureRecognizer*)panGesture //aka panLeftGesture
//{
//    CGPoint translation = [panLeftGesture translationInView:self.view];
//    CGPoint velocity = [panLeftGesture velocityInView:self.view];
//
//    
//    CGAffineTransform transform;
//    if (self.canPanRight)
//    {
//        translation.x += -WIDTH_OF_PM_LIST;
//    }
//    
//    
////    if (-translation.x < WIDTH_OF_PM_LIST)
////    {
////        transform = CGAffineTransformMakeTranslation(translation.x, 0);
////    } else
////    {
////        //smooth
////        transform = CGAffineTransformMakeTranslation(-WIDTH_OF_PM_LIST, 0);
////    }
//    
//        self.contentView.transform = transform;
//    
//    switch (panLeftGesture.state)
//    {
//
//        
//        case UIGestureRecognizerStateBegan:
//        {
//            
//        }
//        break;
//        case UIGestureRecognizerStateEnded:
//        {
//            
//            if (velocity.x < 0)
//            {
//            
//                [self.view setUserInteractionEnabled:NO];
//                [UIView animateWithDuration:0.8f delay:0.0f usingSpringWithDamping:1.2f initialSpringVelocity:10.0f options:UIViewAnimationOptionCurveLinear animations:^
//                {
//                    self.contentView.transform = CGAffineTransformMakeTranslation(-WIDTH_OF_PM_LIST, 0);
//                } completion:^(BOOL finished)
//                {
//                    //ready!
//                    [self.view setUserInteractionEnabled:YES];
//                    self.canPanRight = YES;
//                }];
//            } else
//            {
//                [self.view setUserInteractionEnabled:NO];
//                [UIView animateWithDuration:0.4f delay:0.0f usingSpringWithDamping:1.2f initialSpringVelocity:10.0f options:UIViewAnimationOptionCurveLinear animations:^
//                 {
//                     self.contentView.transform = CGAffineTransformMakeTranslation(0, 0);
//                 } completion:^(BOOL finished)
//                 {
//                     //ready!
//                     [self.view setUserInteractionEnabled:YES];
//                     self.canPanRight = NO;
//                 }];
//            }
//        }
//        break;
//            
//        case UIGestureRecognizerStateChanged:
//        {
//            
//        }
//            break;
//            
//        default:
//            break;
//    }
//}


- (void)observeValueForKeyPath:(NSString *)keyPath ofObject:(id)object change:(NSDictionary *)change context:(void *)context
{
    if (object == self.view && [keyPath isEqualToString:@"frame"])
    {
        CGRect currentFrame = self.view.frame;
        NSLog(@"currentFrame -> %@", NSStringFromCGRect(currentFrame));
        NSLog(@"fromFrame -> %@", NSStringFromCGRect(self.lastFrameForSelfView));

        CGFloat diffHeight = currentFrame.size.height-self.lastFrameForSelfView.size.height;
//        CGRect tableViewRect = CGRectMake(0, 0, self.view.frame.size.width, self.view.frame.size.height);
        UIEdgeInsets e = self.tableView.contentInset;
        e.top -= diffHeight;
        
        [UIView animateWithDuration:0.3f animations:^
        {
            CGRect tempFrame = self.composeBarView.frame;
            tempFrame.origin.y += diffHeight;
            self.composeBarView.frame = tempFrame;
            self.tableView.contentInset = e;
        }];
        
        
        
        self.lastFrameForSelfView = currentFrame;
    }
}

@end