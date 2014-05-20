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
#import "ESImageCell.h"
#import "ESImageMessage.h"
#import "ESImageLoader.h"
#import "ESShortbotOverlay.h"
#import "ESSpringFlowLayout.h"



#define WIDTH_OF_PM_LIST 75.0f


@interface FCWallViewController () <UICollectionViewDataSource, UICollectionViewDelegate, UICollectionViewDelegateFlowLayout, ESShortbotOverlayDelegate>

@property (weak, nonatomic) IBOutlet ESSpringFlowLayout *springFlowLayout;
@property (weak, nonatomic) IBOutlet UICollectionView *wallCollectionView;

@property (strong, nonatomic) Firebase *wallRef;
@property (nonatomic, assign) FirebaseHandle bindToWallHandle;
@property (nonatomic, strong) NSMutableArray *wall;


@property (nonatomic) BOOL initializedTableView;
@property (nonatomic) CGRect lastFrameForSelfView;
@property (nonatomic) NSTimer *autoScrollLockTimer;


@property (nonatomic) BOOL topBarHasGesture;

@property (nonatomic) NSInteger elipseCount;
@property (nonatomic) NSTimer *elipseTimer2;
@property (nonatomic) NSDate *dateLastVisible;
@property (nonatomic) NSTimer *timerToShowSearchingText;


@property (nonatomic) IBOutlet UIView *contentView;

@property (nonatomic) NSArray *tracking;
@property (nonatomic, strong) Firebase *trackingRef;
@property (nonatomic, assign) FirebaseHandle trackingHandle;

//@property (nonatomic) FirebaseHandle removeFromUserPmListHandle;
//@property (nonatomic) FirebaseHandle bindToUserPmListHandle;
@property (nonatomic) CGFloat buttonImageInset;
@property (nonatomic) BOOL presentAnimated;

@property (nonatomic) BOOL needsToDoTransitionWithShadeView;

@property (nonatomic) UIView *shadeView;
@property (nonatomic) UIButton *iconButton;
@property (nonatomic) UIView *labelMaskView;


@property (weak, nonatomic) IBOutlet UITableView *tableView;

// The overlay for the shortbot shortcut view
@property (weak, nonatomic) IBOutlet UIView *shortbotOverlayView;
@property (nonatomic) ESShortbotOverlay *shortbotOverlayController;


//SOME KEYBOARD PROPERTIES FOR HIT TESTING A TOUCH
@property (nonatomic) BOOL keyboardIsVisible;
@property (nonatomic) CGRect keyboardRect;


@property (nonatomic) UILabel *peopleNearbyLabel;

@property (nonatomic) CGRect originalRectOfIcon;


@end

@implementation FCWallViewController

@synthesize wallCollectionView;
@synthesize wall;



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
@synthesize buttonImageInset;
@synthesize peopleNearbyLabel;


@synthesize tableView;


//SOME KEYBOARD PROPERTIES FOR HIT TESTING A TOUCH
@synthesize keyboardIsVisible;
@synthesize keyboardRect;

//@synthesize panLeftGesture;
@synthesize contentView;


static CGFloat HeightOfGradient = 60;
static CGFloat HeightOfWhoIsHereView = 20 + 50.0f;//20 is for the status bar.  Eeeewps :)


- (id)initWithCoder:(NSCoder*)aDecoder
{
    if(self = [super initWithCoder:aDecoder])
    {
        wall = [NSMutableArray array];
    }
    return self;
}



-(void)viewDidAppear:(BOOL)animated
{
    [super viewDidAppear:animated];
    self.lastFrameForSelfView = self.view.frame;
    
    wallCollectionView.delegate = self;
    wallCollectionView.dataSource = self;
    wallCollectionView.alwaysBounceVertical = YES;
    
    [wallCollectionView setContentInset:UIEdgeInsetsMake(64+5, 0, 40, 0)];

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
//            [self.shadeView addGestureRecognizer:[[UITapGestureRecognizer alloc] initWithTarget:self action:@selector(showUsersNearby:)]];
        }
    }
}
-(void)showUsersNearby:(UITapGestureRecognizer*)tapGesture
{
    NSString *string = [NSString stringWithFormat:@"%@", self.tracking];
    
    UIAlertView *alertView = [[UIAlertView alloc] initWithTitle:@"DEBUG" message:string delegate:nil cancelButtonTitle:@"ok" otherButtonTitles:nil];
    [alertView show];
}





- (void)viewDidLoad
{
    [super viewDidLoad];
    //state of login flow
    [[NSUserDefaults standardUserDefaults] setBool:NO forKey:@"showSearchingScreen"];
    
    // Init the shortbot overlay view
    self.shortbotOverlayController = [[ESShortbotOverlay alloc] initWithView:self.shortbotOverlayView andColor:self.shadeView.backgroundColor];
    self.shortbotOverlayController.delegate = self;
    

    
    [self.view addObserver:self forKeyPath:@"frame" options:0 context:nil];
    
    [self performSelector:@selector(foreground:) withObject:nil afterDelay:0.5f];

    
    [[NSUserDefaults standardUserDefaults] setBool:YES forKey:@"shouldPostSwapUserMessageWhenStateChange"];
    

    
    
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
    
    [self.tableView setBackgroundColor:[UIColor whiteColor]];
    
    // Show the navbar and the status bar
    self.navigationController.navigationBarHidden = YES;
    [[UIApplication sharedApplication] setStatusBarHidden:NO];
    // Init table view
    self.tableView.delegate = self;
    self.tableView.dataSource = self;
	// Get the owner
    
    [self.tableView reloadData];
    
    // Flip the table view in viewWillLayoutSubviews, frame adjust in viewDidLayoutSubviews
    
    
    // Hide the scroll indicator TEHEHEHEHEHEHE
    [self.tableView setShowsVerticalScrollIndicator:NO];
    
    // Hide the back button
    [self.navigationItem setHidesBackButton:YES];
    
    // Bind to the owner's wall
    [self bindToWall];
    
    
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
//    UITapGestureRecognizer *tap = [[UITapGestureRecognizer alloc]
//                                   initWithTarget:self
//                                   action:@selector(dismissKeyboard)];
//    [self.view addGestureRecognizer:tap];

//    panLeftGesture = [[UIPanGestureRecognizer alloc] initWithTarget:self action:@selector(handlePan:)];

    
    [self.contentView setClipsToBounds:YES];
    [self.contentView setBackgroundColor:[UIColor clearColor]];
    

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


-(void)viewWillLayoutSubviews
{
    [self.tableView setTransform:CGAffineTransformMakeRotation(-M_PI)];
}
-(void)viewDidLayoutSubviews
{
    //tableView setup goes on here!
    if (!initializedTableView)
    {
        initializedTableView = YES;
        CGFloat bottomEdgeInset = 50;
        self.tableView.frame = CGRectMake(0, 0, self.view.frame.size.width, self.view.frame.size.height);

        self.tableView.contentInset = UIEdgeInsetsMake(bottomEdgeInset+(568-self.view.frame.size.height), 0, HeightOfWhoIsHereView+HeightOfGradient, 0);
   
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

    [self.composeBarView setUtilityButtonImage:[UIImage imageNamed:@"shortbot-dark"]];
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
    NSLog(@"FCWallViewController dealloc");
    [self.wallRef removeObserverWithHandle:self.bindToWallHandle];

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
    self.trackingRef = [[FCUser owner].ref childByAppendingPath:@"tracking"];
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
    if ([[FCUser owner].id isEqualToString:userId] || [userId isEqualToString:@"shortbot"])
        return YES;
    
    NSPredicate *predicate = [NSPredicate predicateWithFormat:@"(SELF == %@)", userId];
    NSArray *results = [tracking filteredArrayUsingPredicate:predicate];
    
    return results.count;
}

- (void)bindToWall
{
    self.wallRef = [[FCUser owner].ref childByAppendingPath:@"wall"];
    
    __weak typeof(self) weakSelf = self;
    self.bindToWallHandle = [self.wallRef observeEventType:FEventTypeChildAdded withBlock:^(FDataSnapshot *snapshot)
    {
        if ([snapshot.value isKindOfClass:[NSDictionary class]])
        {
            id unknownTypeOfMessage = nil;
            if ([snapshot.value objectForKey:@"type"] && ([[snapshot.value objectForKey:@"type"] rangeOfString:@"image"].location != NSNotFound))
            {
                NSLog(@"snapshot.value = %@", snapshot.value);
                if ([snapshot.value objectForKey:@"type"] && ([[snapshot.value objectForKey:@"type"] rangeOfString:@"image"].location != NSNotFound))
                {
                    NSLog(@"this is an image cell! %@", snapshot.value);
                    
                    
                    
                    ESImageMessage *imageMessage = [[ESImageMessage alloc] initWithSnapshot:snapshot];
                    //imageMessage
                    [weakSelf.wall insertObject:imageMessage atIndex:0];
                    NSArray *paths = [NSArray arrayWithObject:[NSIndexPath indexPathForRow:0 inSection:0]];
                    [weakSelf.tableView insertRowsAtIndexPaths:paths withRowAnimation:UITableViewRowAnimationTop];
                    if (!weakSelf.autoScrollLockTimer)
                    {
                        [weakSelf.tableView scrollToRowAtIndexPath:[NSIndexPath indexPathForRow:0 inSection:0] atScrollPosition:UITableViewScrollPositionTop animated:YES];
                    }
                    [weakSelf updateLine];
                    
                } else
                if ([[snapshot.value objectForKey:@"type"] isEqualToString:@"ESSwapUserStateMessage"])
                {
                    ESSwapUserStateMessage *swapMsg = [[ESSwapUserStateMessage alloc] initWithSnapshot:snapshot];
                    

                unknownTypeOfMessage = [[FCMessage alloc] initWithSnapshot:snapshot];
//                [weakSelf.wallCollectionView performBatchUpdates:^
//                 {
//                     FCMessage *message = [[FCMessage alloc] initWithSnapshot:snapshot];
//                     NSArray *paths = [NSArray arrayWithObject:[NSIndexPath indexPathForRow:0 inSection:0]];
//                     [weakSelf.wall insertObject:message atIndex:0];
//                     [weakSelf.wallCollectionView insertItemsAtIndexPaths:paths];
//                 } completion:nil];
                
//                FCMessage *message = [[FCMessage alloc] initWithSnapshot:snapshot];
//                // Init a new message
//                [weakSelf.wall insertObject:message atIndex:0];
//                NSArray *paths = [NSArray arrayWithObject:[NSIndexPath indexPathForRow:0 inSection:0]];
//                [weakSelf.tableView insertRowsAtIndexPaths:paths withRowAnimation:UITableViewRowAnimationTop];
//                
//                // Scroll to the new message
//                if (!weakSelf.autoScrollLockTimer)
//                {
//                    [weakSelf.tableView scrollToRowAtIndexPath:[NSIndexPath indexPathForRow:0 inSection:0] atScrollPosition:UITableViewScrollPositionTop animated:YES];
//                }
            }
            [weakSelf.wallCollectionView performBatchUpdates:^
             {
                 
                 NSArray *paths = @[ [NSIndexPath indexPathForRow:weakSelf.wall.count inSection:0] ];
                 [weakSelf.wall insertObject:unknownTypeOfMessage atIndex:weakSelf.wall.count];
                 [weakSelf.wallCollectionView insertItemsAtIndexPaths:paths];
             } completion:nil];
        }
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

    }
}
-(void)tableView:(UITableView *)tV didDoubleTapCellAtIndexPath:(NSIndexPath *)indexPath
{
    if (tV == self.tableView)
    {

    }
}





#pragma mark - Table view data source


- (NSInteger)numberOfSectionsInTableView:(UITableView *)tableView
{
    return 1;
}

- (NSInteger)tableView:(UITableView *)tV numberOfRowsInSection:(NSInteger)section
{
    if (tV == self.tableView)
    {
        return [wall count];
    }
    return 0;
}

- (UITableViewCell*)tableView:(UITableView *)tV cellForRowAtIndexPath:(NSIndexPath *)indexPath
{
    if (tableView == tV)
    {
        id unknownTypeOfMessage = [self.wall objectAtIndex:indexPath.row];
    
        if ([unknownTypeOfMessage isKindOfClass:[ESImageMessage class]])
        {
            NSLog(@"making an image cell");
            ESImageMessage *imageMessage = unknownTypeOfMessage;
            ESImageCell *imageCell = [tableView dequeueReusableCellWithIdentifier:@"ESImageCell"];
            [imageCell setBackgroundColor:[UIColor clearColor]];
            
            [imageCell setImage:nil];
            [imageCell setProfileColor:imageMessage.color];
            [imageCell setProfileImage:imageMessage.icon];
            
            [[ESImageLoader sharedImageLoader] loadImage:[NSURL URLWithString:imageMessage.src] completionBlock:^(UIImage *image, NSURL *url, BOOL synchronous)
            {
                if (synchronous)
                {
                    [imageCell setImage:image];
                } else
                {
                    NSIndexPath *currentIndexPath;
                    for (NSIndexPath *indexPaths in [tableView indexPathsForVisibleRows])
                    {
                        if ([[self.wall objectAtIndex:indexPath.row] isKindOfClass:[ESImageMessage class]])
                        {
                            ESImageMessage *imageMessage = [self.wall objectAtIndex:indexPath.row];
                            if ([url.absoluteString isEqualToString:imageMessage.src])
                            {
                                currentIndexPath  = indexPath;
                                break;
                            }
                        }
                    }
                    if (currentIndexPath)
                    {
                        ESImageCell *imageCell = (ESImageCell*)[tableView cellForRowAtIndexPath:currentIndexPath];
                        if (imageCell)
                        {
                    
                            ESAssert([imageCell isKindOfClass:[ESImageCell class]], @"a cell was supposed to be an imagecell but is not");
                            [imageCell setImage:image];
                        }
                    }
                    
                    
                    
                    
                }
            } isGif:imageMessage.isGif];
            
            //load image time
            
            
            imageCell.tag = indexPath.row;
            return imageCell;
            
        } else
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
            cell.tag = indexPath.row;
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
            cell.tag = indexPath.row;
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
    NSLog(@"never called");
    if (tV == self.tableView)
    {
        if (indexPath.row >= wall.count)
        {
            return 0.0f;
        }
        id unknownType = [wall objectAtIndex:indexPath.row];
        NSLog(@"unknownType = %@", unknownType);
        if ([unknownType isKindOfClass:[FCMessage class]])
        {

            FCMessage *message = [wall objectAtIndex:indexPath.row];
            
            UIFont *font = [UIFont fontWithName:@"HelveticaNeue-Light" size:13];
            CGSize constraintSize = {225.0f, 700};
            CGSize actualSize = [message.text sizeWithFont:font constrainedToSize:constraintSize];
            CGFloat height = MAX(actualSize.height+14.0f*2, 75.0f);//14 is top and bottom padding of label
            return height;
        } else
        if ([unknownType isKindOfClass:[ESSwapUserStateMessage class] ] )
        {
            return 50;
        } else
        if ([unknownType isKindOfClass:[ESImageMessage class]])
        {
            return ESImageCell_IMAGE_CELL_HEIGHT;
        }
    }
    return 0;
}

# pragma mark - keyboard did show/hide
// Handles the resizing on a keyboard show or hide event
- (void)keyboardWillToggle:(NSNotification *)notification
{
    
    
    
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
                        [self.tableView setContentOffset:contentOffset];//scrollview scroll up
                        
//                        NSLog(@"edgeInset <- %@", NSStringFromUIEdgeInsets(edgeInsets));
                        
                        
                        [[self tableView] setContentInset:edgeInsets];
                         [[self composeBarView] setFrame:newComposeBarFrame]; //move composeBarView up
                    } completion:NULL];
    
    // If the keyboard is coming up, broadcast as an iBeacon to sync surrounding users
    if (heightChange < 0) {
        [[FCUser owner].beacon chirpBeacon];
    }
    
}
- (void)composeBarViewDidPressUtilityButton:(PHFComposeBarView *)composeBarView {
    // Drop the text view
    [self.composeBarView resignFirstResponder];
    // Show the shortbot overlay
    [self.shortbotOverlayController showOverlay];
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
    [message postText:self.composeBarView.text asOwner:[FCUser owner]];
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
    
    if (self.tableView.contentOffset.y + self.tableView.contentInset.top == 0)
    {
        [self cleanUpAutoScrollLockTimer:nil];
        
    } else
    {

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

//-(NSInteger)numberOfSectionsInCollectionView:(UICollectionView *)collectionView
//{
//    return 1;
//}

//-(NSInteger)collectionView:(UICollectionView *)collectionView numberOfItemsInSection:(NSInteger)section
//{
//    
//    FCUser *owner = [FCUser owner];
//    NSInteger numberOfBecons = (!owner) ? 0 :  [owner.beacon earshotUsers].count;
//    
//    NSInteger returnValue = numberOfBecons + 1;//change this value for now
//    
//    if (returnValue != lastNumberOfPeopleInCollectionView)
//    {
//        lastNumberOfPeopleInCollectionView = returnValue;
//        CGFloat span = 50*returnValue+(10*returnValue-1);
//        CGFloat leftInset = MAX((self.view.frame.size.width - span)/2, 10); //center the cells
//        
////        [UIView animateWithDuration:1 delay:0.0f usingSpringWithDamping:1 initialSpringVelocity:0.0f options:UIViewAnimationOptionCurveLinear animations:^
////        {
//            [collectionView setContentInset:UIEdgeInsetsMake(0, leftInset, 0, 0)];
////        } completion:^(BOOL finished){}];
//    }
//    
//    return returnValue;
//}
//-(UICollectionViewCell*)collectionView:(UICollectionView *)collectionView cellForItemAtIndexPath:(NSIndexPath *)indexPath
//{
//    UICollectionViewCell *collectionViewCell = [collectionView dequeueReusableCellWithReuseIdentifier:@"ProfileCollectionViewCell" forIndexPath:indexPath];
//    
//    NSLog(@"collectionViewCell = %@", collectionViewCell);
//    return collectionViewCell;
//}
//
//-(void)randomBing
//{
//    NSLog(@"randomBing");
//    NSInteger randomInteger = esRandomNumberIn(0, [self collectionView:whoIsHereCollectionView numberOfItemsInSection:0]);
//    
//    ProfileCollectionViewCell *pcvc = (ProfileCollectionViewCell *)[whoIsHereCollectionView cellForItemAtIndexPath:[NSIndexPath indexPathForItem:randomInteger inSection:0]];
//    if (!pcvc)
//    {
//        return;
//    }
//    [pcvc boop];
//    
//}


#pragma mark UICollectionViewDelegate, UICollectionViewDataSource end



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
    
    UIViewController *landingPageViewController = nil;
    for (UIViewController *viewController in vc)
    {
        if ([viewController isKindOfClass:[FCLandingPageViewController class]])
        {
            landingPageViewController = viewController;
        }
    }
    
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

# pragma mark - shortbot delegate methods
- (void)shortbotOverlay:(ESShortbotOverlay *)overlay didPickCommand:(NSString *)command
{
    NSLog(@"Picked command: %@", command);
    // Set the text to the command response
    [self.composeBarView setText:[NSString stringWithFormat:@"shortbot %@ ", command]];
    // Set focus on the view
    [self.composeBarView.textView becomeFirstResponder];
}



#pragma mark collection view stuff
- (NSInteger)collectionView:(UICollectionView *)collectionView numberOfItemsInSection:(NSInteger)section
{
    return wall.count;
}



- (UICollectionViewCell *)collectionView:(UICollectionView *)collectionView cellForItemAtIndexPath:(NSIndexPath *)indexPath
{
    id unknownTypeOfMessage = [wall objectAtIndex:indexPath.row];
    
    
    UICollectionViewCell *otherCell = [collectionView dequeueReusableCellWithReuseIdentifier:@"cell" forIndexPath:indexPath];
    return otherCell;
}

-(void)collectionView:(UICollectionView *)collectionView didSelectItemAtIndexPath:(NSIndexPath *)indexPath
{
    UICollectionViewCell *cell = [collectionView cellForItemAtIndexPath:indexPath];
    
    [UIView transitionWithView:collectionView duration:.5 options:UIViewAnimationTransitionCurlUp animations:^{
        
        //any animateable attribute here.
        
        cell.frame = CGRectMake(cell.frame.origin.x, cell.frame.origin.y, cell.frame.size.width, cell.frame.size.height+100);
        
    } completion:^(BOOL finished) {
        //whatever you want to do upon completion
    }];
    
}
@end