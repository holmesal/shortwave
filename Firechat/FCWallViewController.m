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

#import "FCLandingPageViewController.h"


@interface FCWallViewController () <UICollectionViewDataSource, UICollectionViewDelegate, UICollectionViewDelegateFlowLayout>

//firebase handles
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
@property Firebase *ref;
@property NSMutableArray *wall;
@property NSArray *beacons;
@property (weak, nonatomic) IBOutlet UIImageView *bgImage;
@property (weak, nonatomic) IBOutlet UIImageView *backgroundImageView;


@property (weak, nonatomic) IBOutlet UICollectionView *whoIsHereCollectionView;
@property (nonatomic) CGRect originalRectOfIcon;




@property PHFComposeBarView *composeBarView;
@end

@implementation FCWallViewController

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


static CGFloat HeightOfGradient = 60;
static CGFloat HeightOfWhoIsHereView = 20 + 50.0f;//20 is for the status bar.  Eeeewps :)


- (id)initWithCoder:(NSCoder*)aDecoder
{
    if(self = [super initWithCoder:aDecoder])
    {
        self.wall = [NSMutableArray array];
        self.beacons = [[NSArray alloc] init];
        

    }
    return self;
}

-(void)viewDidAppear:(BOOL)animated
{
    [super viewDidAppear:animated];
    
    

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
            frame.origin.y = 20;
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
    

    

    
    [notifyingStr beginEditing];
    [notifyingStr addAttribute:NSFontAttributeName
                         value:[UIFont boldSystemFontOfSize:15]
                         range:rangeOfNumber];//range of normal string, e.g. 2012/10/14];
    [notifyingStr endEditing];
    
    peopleNearbyLabel.attributedText = notifyingStr;
}

-(void)updateLine
{
    //thing is flipped btw!
//    NSArray *visibleIndexPaths = [self.tableView visibleCells];
    
    
    CGFloat heightForZeroPath = [self tableView:tableView heightForRowAtIndexPath:[NSIndexPath indexPathForRow:0 inSection:0] ];
    
    if (self.wall.count)
    {
        CGRect rectOfZeroCell = [self.tableView rectForRowAtIndexPath:[NSIndexPath indexPathForRow:self.wall.count-1 inSection:0 ]];
//        NSLog(@"rectOfZeroCell = %@", NSStringFromCGRect(rectOfZeroCell));
        
        UIBezierPath *linePath = [UIBezierPath bezierPath];
        CGFloat x = self.tableView.frame.size.width - (20 + 35/2.0f);
        CGFloat ystart = rectOfZeroCell.origin.y+rectOfZeroCell.size.height - (7+35/2.0f);
        CGFloat bottomOfScreen = self.tableView.contentOffset.y;
        
        [linePath moveToPoint:CGPointMake(x, ystart) ];//(heightForZeroPath)/2)];
        [linePath addLineToPoint:CGPointMake(x, bottomOfScreen)];
        
        [lineLayer setPath:linePath.CGPath];
    }
}

- (void)viewDidLoad
{
    [super viewDidLoad];
    
    
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
    //begin observing "Beacons Updated" event
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(beaconsUpdated:) name:@"Beacons Updated" object:nil];
    [self updatePeopleNearby:0];

    [self.shadeView insertSubview:peopleNearbyLabel belowSubview:self.iconButton];
//    [self.view addSubview:peopleNearbyLabel];
    /*
     UILabel *displayLabel = [[UILabel alloc] initWithFrame://label frame];
    displayLabel.font = [UIFont boldSystemFontOfSize://bold font size];
    
    NSMutableAttributedString *notifyingStr = [[NSMutableAttributedString alloc] initWithString:@"Updated: 2012/10/14 21:59 PM"];
    [notifyingStr beginEditing];
    [notifyingStr addAttribute:NSFontAttributeName
                         value:[UIFont systemFontOfSize://normal font size]
                         range:NSMakeRange(8,10)//range of normal string, e.g. 2012/10/14];
    [notifyingStr endEditing];
    
    displayLabel.attributedText = notifyingStr;
     */
    
    if (self.shadeView)
    {
        [self.view addSubview:self.shadeView];
        
    } else
    {
        NSLog(@"warning! you are instaniating FCWallViewController without setting it up properly via beginTransitionWithIcon method.  Expect to see no transition");
    }
    
    //Flash yourself demo
//    FCUser *owner = ((FCAppDelegate*)[ESApplication sharedApplication].delegate).owner;
//    [owner.onOffRef observeEventType:FEventTypeValue withBlock:^(FDataSnapshot *snapShot) //in dealloc
//    {
//        if (snapShot.value == [NSNull null])
//        {
//            return;
//        }
//        BOOL isOn = [snapShot.value boolValue];
//        
//        ProfileCollectionViewCell *pcvc = (ProfileCollectionViewCell *)[whoIsHereCollectionView cellForItemAtIndexPath:[NSIndexPath indexPathForItem:0 inSection:0]];
//        if (pcvc)
//        {
//            NSLog(@"pcvc turn on ? %@", isOn ? @"YES": @"NO");
//            [pcvc setTurnOn:isOn];
//        }
//    }];
    
    
    //whoishereCollectionView
//    {
//        [whoIsHereCollectionView setClipsToBounds:NO];
//        [whoIsHereCollectionView setShowsHorizontalScrollIndicator:NO];
//        [whoIsHereCollectionView setAlwaysBounceHorizontal:YES];
//        whoIsHereCollectionView.delegate = self;
//        whoIsHereCollectionView.dataSource = self;
//        
//        [self.view addSubview:whoIsHereCollectionView];
//    }
    
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
    self.owner = [(FCAppDelegate *)[[UIApplication sharedApplication] delegate] owner];
    NSLog(@"owner's id: %@",self.owner.id);
    [self.tableView reloadData];
    
    // Flip the table view in viewWillLayoutSubviews, frame adjust in viewDidLayoutSubviews
    
    
    // Hide the scroll indicator TEHEHEHEHEHEHE
    [self.tableView setShowsVerticalScrollIndicator:NO];
    
    // Hide the back button
    [self.navigationItem setHidesBackButton:YES];
    
    // Bind to the owner's wall
    [self bindToWall];
    
#warning should not retain
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
#warning should not retain
    UITapGestureRecognizer *tap = [[UITapGestureRecognizer alloc]
                                   initWithTarget:self
                                   action:@selector(dismissKeyboard)];
    [self.view addGestureRecognizer:tap];
    
    // Transparent mask over the top of the table view

    
    // Load the compose view
    [self loadComposeView];
    
}


//is calld after layout is determined for "tableView" due to constraints and scren size.  If you do this in
//view did load, you will get incorrect sizes of tableView, necessary because tableview is upside down!

-(void)viewWillLayoutSubviews
{
    [self.tableView setTransform:CGAffineTransformMakeRotation(-M_PI)];
}
-(void)viewDidLayoutSubviews
{
    
    //tableView setup goes on here!
    {
    
        self.tableView.frame = CGRectMake(0, 0, self.view.frame.size.width, self.view.frame.size.height);
        //table view is upsid down, so insets beware
        self.tableView.contentInset = UIEdgeInsetsMake(40, 0, HeightOfWhoIsHereView+HeightOfGradient, 0);
        
        //setup tableViewMask, remember tableView is upside down
        if (NO) //(!tableViewMask)
        {
            //create tableViewMask
            tableViewMask = [CALayer layer];
            
            
            CGRect tableViewMaskFrame = {0.0f, 0.0f, tableView.frame.size.width, tableView.frame.size.height};
            [tableViewMask setFrame:tableViewMaskFrame];
            [tableViewMask setBackgroundColor:[UIColor clearColor].CGColor];
            tableViewMask.anchorPoint = CGPointZero;
            [tableView.layer setMask:tableViewMask];
            
            
            //the area behind the whosethereview
            CALayer *areaBehindWhoseThereView = [CALayer layer];
            CGRect areaBehindWhoseThereViewFrame = {0.0f, tableViewMaskFrame.size.height-HeightOfWhoIsHereView,
                                                    tableViewMaskFrame.size.width, HeightOfWhoIsHereView};
            areaBehindWhoseThereView.frame = areaBehindWhoseThereViewFrame;
            [areaBehindWhoseThereView setBackgroundColor:[UIColor clearColor].CGColor];
            [tableViewMask addSublayer:areaBehindWhoseThereView];
            
            //the gradient layer underneath
            CAGradientLayer *gradientLayer = [CAGradientLayer layer];
            CGRect gradientLayerFrame = {0.0f, areaBehindWhoseThereViewFrame.origin.y-HeightOfGradient,
                                         tableView.frame.size.width, HeightOfGradient};
            //high resolution drawing for retina, low res for non retina
            [gradientLayer setContentsScale:[[UIScreen mainScreen] scale]];
            [gradientLayer setFrame:gradientLayerFrame];
            [gradientLayer setStartPoint:CGPointMake(0.5, 1)];
            [gradientLayer setEndPoint:CGPointMake(0.5, 0)];
            [gradientLayer setColors:@[(id)[UIColor clearColor].CGColor, (id)[UIColor blackColor].CGColor ] ];
            [tableViewMask addSublayer:gradientLayer];
            
            //all the rest
            CALayer *allTheRest = [CALayer layer];
            CGFloat allRestHeight = tableView.frame.size.height - HeightOfWhoIsHereView - HeightOfGradient;
            CGRect allTheRestFrame = {0.0f, gradientLayerFrame.origin.y-allRestHeight,
                                      tableView.frame.size.width, allRestHeight};
            [allTheRest setFrame:allTheRestFrame];
            [allTheRest setBackgroundColor:[UIColor blackColor].CGColor];
            [tableViewMask addSublayer:allTheRest];
            
            
            //to center the anchor point, act as if tableview did scroll
            [self scrollViewDidScroll:self.tableView];
            
        }
        
    }//end of tableview setup
    
    [self.view layoutSubviews];
    
}




- (void)loadComposeView{
    CGRect viewBounds = self.view.bounds;
    
    NSLog(@"%f", viewBounds.origin.x);
    
    CGRect frame = CGRectMake(0.0f,
                              viewBounds.size.height - PHFComposeBarViewInitialHeight,
                              viewBounds.size.width,
                              PHFComposeBarViewInitialHeight);
    self.composeBarView = [[PHFComposeBarView alloc] initWithFrame:frame];
    [self.composeBarView setMaxCharCount:160];
    [self.composeBarView setMaxLinesCount:5];
    [self.composeBarView setPlaceholder:@"Say something..."];
//    [self.composeBarView setUtilityButtonImage:[UIImage imageNamed:[NSString stringWithFormat:@"%@",self.owner.icon]]];
    [self.composeBarView setDelegate:self];
    
    // Style the compose bar view

//    self.composeBarView.textView.keyboardAppearance = UIKeyboardAppearanceDark;
//    self.composeBarView.buttonTintColor = [UIColor whiteColor];
//    self.composeBarView.textView.backgroundColor = [UIColor colorWithWhite:0.1 alpha:0.1];
//    [self.composeBarView setBackgroundColor:UIColor clearColor];
    // Add subview
    [self.view addSubview:self.composeBarView];
    
    // Style the "utility button", a phrase which here means "profile photo"
//    self.composeBarView.utilityButton.imageView.layer.masksToBounds = YES;
//    self.composeBarView.utilityButton.imageView.layer.cornerRadius = self.composeBarView.utilityButton.imageView.frame.size.width/2;
//    // TODO - replace this with the owner's actual color
//    self.composeBarView.utilityButton.imageView.backgroundColor = self.owner.displayColor;
//    
//    // Style the image
//    [self.composeBarView setUtilityButtonImage:[UIImage imageNamed:@"profilepic"]];
}

- (void)dealloc
{
    [self.ref removeObserverWithHandle:self.bindToWallHandle];
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

- (void)bindToWall
{
    self.ref = [self.owner.ref childByAppendingPath:@"wall"];
    // Watch for changes
    
    __weak typeof(self) weakSelf = self;
    self.bindToWallHandle = [self.ref observeEventType:FEventTypeChildAdded withBlock:^(FDataSnapshot *snapshot)
    {
//        for (int i = 0; i < 1; i++)
//        {
        
            NSLog(@"GOT MESSAGE!");
            
            FCMessage *message = [[FCMessage alloc] initWithSnapshot:snapshot];
            // Init a new message
            [weakSelf.wall insertObject:message atIndex:0];
            NSArray *paths = [NSArray arrayWithObject:[NSIndexPath indexPathForRow:0 inSection:0]];
            [weakSelf.tableView insertRowsAtIndexPaths:paths withRowAnimation:UITableViewRowAnimationTop];
            
            // Scroll to the new message
            [weakSelf.tableView scrollToRowAtIndexPath:[NSIndexPath indexPathForRow:0 inSection:0] atScrollPosition:UITableViewScrollPositionTop animated:YES];
            
            [weakSelf updateLine];
            
//        }
    }];
}

#pragma mark - Table view data source

- (NSInteger)numberOfSectionsInTableView:(UITableView *)tableView
{
    // Return the number of sections.
//    NSLog(@"ASKED FOR SECTIONS");
    return 1;
}

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section
{
    // Return the number of rows in the section.
//    NSLog(@"wall length count: %lu", (unsigned long)[self.wall count]);
    return [self.wall count];
}

- (UITableViewCell *)tableView:(UITableView *)tV cellForRowAtIndexPath:(NSIndexPath *)indexPath
{
    if (tableView == tV)
    {
        static NSString *CellIdentifier = @"MessageCell";
        FCMessageCell *cell = [tableView dequeueReusableCellWithIdentifier:CellIdentifier forIndexPath:indexPath];

//        [cell setBackgroundColor:[UIColor yellowColor]];
        
        // Flip the cell 180 degrees
        cell.transform = CGAffineTransformMakeRotation(M_PI);
        
        // Configure the cell...
        FCMessage *message = [self.wall objectAtIndex:indexPath.row];
        
        // Set message cell values
        [cell setMessage:message];
        
        // This message tracks whether it's owner is in range or not, and fade out if appropriate via the NSNotification @"Beacon update"
        cell.ownerID = message.ownerID;
        NSNumber *major = [NSNumber numberWithInt: [[[cell.ownerID componentsSeparatedByString:@":"] objectAtIndex:0] integerValue] ];
        NSNumber *minor = [NSNumber numberWithInt: [[[cell.ownerID componentsSeparatedByString:@":"] objectAtIndex:1] integerValue] ];
        
        NSPredicate *predicate = [NSPredicate predicateWithFormat:@"(SELF.major == %@ AND SELF.minor == %@)", major, minor];

        BOOL beaconFound = [[self.beacons filteredArrayUsingPredicate:predicate] lastObject] ? YES : NO;
        
        FCUser *me = ((FCAppDelegate*)[ESApplication sharedApplication].delegate).owner;
        NSString *myId = me.id;
        BOOL messageBelongsToMe = [myId isEqualToString:message.ownerID];
        
        BOOL isFaded = !beaconFound && !messageBelongsToMe;
        [cell setFaded:isFaded animated:NO];

        
        return cell;
    }
    
    return nil;
}

- (CGFloat) tableView:(UITableView *)tableView heightForRowAtIndexPath:(NSIndexPath *)indexPath
{
    if (indexPath.row >= self.wall.count)
    {
        return 0.0f;
    }
    FCMessage *message = [self.wall objectAtIndex:indexPath.row];
    
    UIFont *font = [UIFont fontWithName:@"HelveticaNeue-Light" size:13];
    CGSize constraintSize = {225.0f, 700};
    CGSize actualSize = [message.text sizeWithFont:font constrainedToSize:constraintSize];
    CGFloat height = MAX(actualSize.height+14.0f*2, 75.0f);//14 is top and bottom padding of label
    

    return height;
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
    
    //ethan did some stuff here.  Needs revision if support multiple orientation!
    keyboardIsVisible = (sizeChange < 0);
    keyboardRect = [[userInfo objectForKey:@"UIKeyboardFrameEndUserInfoKey"] CGRectValue];
    
    CGRect newContainerFrame = [[self tableView] frame];
    newContainerFrame.size.height += sizeChange;
    
    CGRect newComposeBarFrame = [[self composeBarView] frame];
    newComposeBarFrame.origin.y += sizeChange;
    
    CGPoint contentOffset = {0.0f, tableView.contentOffset.y + sizeChange};
    
    //ethan changed this because edge insets is the way to go when resizing from keyboard
    UIEdgeInsets edgeInsets = self.tableView.contentInset;
    edgeInsets.top -= sizeChange;
    
    [UIView animateWithDuration:duration
                          delay:0
                        options:(animationCurve << 16)|UIViewAnimationOptionBeginFromCurrentState
                     animations:^
                    {
//                         [[self tableView] setFrame:newContainerFrame];
                        [self.tableView setContentInset:edgeInsets];
                        [self.tableView setContentOffset:contentOffset];
                        
//                        [[self tableView] setContentInset:UIEdgeInsetsMake(0, 0, HeightOfWhoseHereView+HeightOfGradient, 0)];
                         [[self composeBarView] setFrame:newComposeBarFrame];
                    }
                     completion:NULL];
}
- (void)composeBarViewDidPressUtilityButton:(PHFComposeBarView *)composeBarView {
    NSLog(@"Utility button pressed");
}

// Pressed "send"
- (void)composeBarViewDidPressButton:(PHFComposeBarView *)composeBarView {
    // Send the message
    FCMessage *message = [[FCMessage alloc] init];
    
    FCUser *owner = ((FCAppDelegate*)[UIApplication sharedApplication].delegate).owner;
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
        //disable animations, then move the tableViewMask layer
        [CATransaction begin];
        [CATransaction setDisableActions:YES];
        tableViewMask.position = CGPointMake(0, scrollView.contentOffset.y);
        [CATransaction commit];
    }
}

#pragma mark UICollectionViewDelegate, UICollectionViewDataSource start

-(NSInteger)numberOfSectionsInCollectionView:(UICollectionView *)collectionView
{
    return 1;
}

-(NSInteger)collectionView:(UICollectionView *)collectionView numberOfItemsInSection:(NSInteger)section
{
    
    FCAppDelegate *appDelegate = (FCAppDelegate *)[UIApplication sharedApplication].delegate;
    FCUser *owner = appDelegate.owner;
    NSInteger numberOfBecons = (!owner) ? 0 :  [owner.beacon getBeaconIds].count;
    
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
            
            
            FCUser *owner = ((FCAppDelegate*)[ESApplication sharedApplication].delegate).owner;
            
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
    [self.view addSubview:self.shadeView];
    
    UINavigationController *navContr = self.navigationController;
    NSMutableArray *vc = [NSMutableArray arrayWithArray:navContr.viewControllers];
    
    UIViewController *landingPageViewController = [vc objectAtIndex:vc.count-2];
    
    [UIView animateWithDuration:1.6f delay:0.0f usingSpringWithDamping:1.2f initialSpringVelocity:0.0f options:UIViewAnimationOptionCurveLinear animations:^
     {
         CGRect frame = self.iconButton.frame;
         frame.origin.x = (self.view.frame.size.width - frame.size.width)*0.5f;
         [self.iconButton setFrame:frame];
         
         [self.labelMaskView setFrame:newTargetFrame];
         [self.peopleNearbyLabel setFrame:newTargetFrame];

     } completion:^(BOOL finished)
     {
         [UIView animateWithDuration:1.6f delay:0.0f usingSpringWithDamping:1.2f initialSpringVelocity:0.0f options:UIViewAnimationOptionCurveLinear animations:^
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

#pragma mark NSNotificationCenter beaconsUpdated start
-(void)beaconsUpdated:(NSNotification*)notification
{
    self.beacons = notification.object;
    
    for (FCMessageCell *mssgCell in tableView.visibleCells)
    {
        NSNumber *major = [NSNumber numberWithInt: [[[mssgCell.ownerID componentsSeparatedByString:@":"] objectAtIndex:0] integerValue] ];
        NSNumber *minor = [NSNumber numberWithInt: [[[mssgCell.ownerID componentsSeparatedByString:@":"] objectAtIndex:1] integerValue] ];
        
        NSPredicate *predicate = [NSPredicate predicateWithFormat:@"(SELF.major == %@ AND SELF.minor == %@)", major, minor];
        
        id obj = [[self.beacons filteredArrayUsingPredicate:predicate] lastObject];
        BOOL beaconFound = obj ? YES : NO;
        
        FCUser *me = ((FCAppDelegate*)[ESApplication sharedApplication].delegate).owner;
        NSString *myId = me.id;
        BOOL messageBelongsToMe = [myId isEqualToString:mssgCell.ownerID];
        
        BOOL isFaded = !beaconFound && !messageBelongsToMe;
        
        
        [mssgCell setFaded:isFaded animated:YES];
    }
    
    [self updatePeopleNearby:self.beacons.count];
}
#pragma mark NSNotificationCenter beaconsUpdated end


@end
