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



@interface FCWallViewController () <UICollectionViewDataSource, UICollectionViewDelegate, UICollectionViewDelegateFlowLayout>
@property (assign, nonatomic) NSInteger lastNumberOfPeopleInCollectionView;



@property (weak, nonatomic) IBOutlet UITableView *tableView;
@property (nonatomic) CALayer *tableViewMask;

@property FCUser *owner;
@property Firebase *ref;
@property NSMutableArray *wall;
@property NSArray *beacons;
@property (weak, nonatomic) IBOutlet UIImageView *bgImage;
@property (weak, nonatomic) IBOutlet UIImageView *backgroundImageView;


@property (weak, nonatomic) IBOutlet UICollectionView *whoIsHereCollectionView;





@property PHFComposeBarView *composeBarView;
@end

@implementation FCWallViewController

@synthesize lastNumberOfPeopleInCollectionView;

@synthesize backgroundImageView;

@synthesize tableViewMask;
@synthesize tableView;
@synthesize whoIsHereCollectionView;


static CGFloat HeightOfGradient = 60;
static CGFloat HeightOfWhoIsHereView = 20 + 50.0f;

//- (id)initWithNibName:(NSString *)nibNameOrNil bundle:(NSBundle *)nibBundleOrNil
//{
//    self = [super initWithNibName:nibNameOrNil bundle:nibBundleOrNil];
//    if (self) {
//        // Custom initialization
//
//    }
//    return self;
//}

- (id)initWithCoder:(NSCoder*)aDecoder
{
    if(self = [super initWithCoder:aDecoder])
    {
        self.wall = [NSMutableArray array];
        self.beacons = [[NSArray alloc] init];
        

    }
    return self;
}

- (void)viewDidLoad
{
    [super viewDidLoad];
    
    NSTimer *timer = [NSTimer timerWithTimeInterval:0.25 target:self selector:@selector(randomBing) userInfo:nil repeats:YES];
    [[NSRunLoop mainRunLoop] addTimer:timer forMode:NSDefaultRunLoopMode];
    
    
    //whoishereCollectionView
    {
        [whoIsHereCollectionView setClipsToBounds:NO];
        [whoIsHereCollectionView setShowsHorizontalScrollIndicator:NO];
        [whoIsHereCollectionView setAlwaysBounceHorizontal:YES];
        whoIsHereCollectionView.delegate = self;
        whoIsHereCollectionView.dataSource = self;
        
        [self.view addSubview:whoIsHereCollectionView];
    }
    
    //paralax?
    {
        // Set vertical effect
        UIInterpolatingMotionEffect *verticalMotionEffect =
        [[UIInterpolatingMotionEffect alloc]
         initWithKeyPath:@"center.y"
         type:UIInterpolatingMotionEffectTypeTiltAlongVerticalAxis];
        
        static CGFloat wiggle = 50;
        
        verticalMotionEffect.minimumRelativeValue = @(-wiggle);
        verticalMotionEffect.maximumRelativeValue = @(wiggle);
        
        // Set horizontal effect
        UIInterpolatingMotionEffect *horizontalMotionEffect =
        [[UIInterpolatingMotionEffect alloc]
         initWithKeyPath:@"center.x"
         type:UIInterpolatingMotionEffectTypeTiltAlongHorizontalAxis];
        horizontalMotionEffect.minimumRelativeValue = @(-wiggle);
        horizontalMotionEffect.maximumRelativeValue = @(wiggle);
        
        // Create group to combine both
        UIMotionEffectGroup *group = [UIMotionEffectGroup new];
        group.motionEffects = @[horizontalMotionEffect, verticalMotionEffect];
        
        // Add both effects to your view
        [backgroundImageView addMotionEffect:group];
    }
    
    
    [self.tableView setBackgroundColor:[UIColor clearColor]];
    
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
        if (!tableViewMask)
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
    [self.composeBarView setUtilityButtonImage:[UIImage imageNamed:[NSString stringWithFormat:@"%@",self.owner.icon]]];
    [self.composeBarView setDelegate:self];
    
    // Style the compose bar view
    self.composeBarView.textView.keyboardAppearance = UIKeyboardAppearanceDark;
    self.composeBarView.buttonTintColor = [UIColor whiteColor];
//    self.composeBarView.textView.backgroundColor = [UIColor colorWithWhite:0.1 alpha:0.1];
//    [self.composeBarView setBackgroundColor:UIColor clearColor];
    // Add subview
    [self.view addSubview:self.composeBarView];
    
    // Style the "utility button", a phrase which here means "profile photo"
    self.composeBarView.utilityButton.imageView.layer.masksToBounds = YES;
    self.composeBarView.utilityButton.imageView.layer.cornerRadius = self.composeBarView.utilityButton.imageView.frame.size.width/2;
    // TODO - replace this with the owner's actual color
    self.composeBarView.utilityButton.imageView.backgroundColor = self.owner.displayColor;
    
    // Style the image
    [self.composeBarView setUtilityButtonImage:[UIImage imageNamed:@"profilepic"]];
}

- (void)dealloc {
    [[NSNotificationCenter defaultCenter] removeObserver:self
                                                    name:UIKeyboardWillShowNotification
                                                  object:nil];
    [[NSNotificationCenter defaultCenter] removeObserver:self
                                                    name:UIKeyboardWillHideNotification
                                                  object:nil];
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
    [self.ref observeEventType:FEventTypeChildAdded withBlock:^(FDataSnapshot *snapshot) {
        NSLog(@"GOT MESSAGE!");
        
        FCMessage *message = [[FCMessage alloc] initWithSnapshot:snapshot];
        // Init a new message
        [self.wall insertObject:message atIndex:0];
        //[self.wall addObject:message]; // For right-side up table view
        NSArray *paths = [NSArray arrayWithObject:[NSIndexPath indexPathForRow:0 inSection:0]];
        [self.tableView insertRowsAtIndexPaths:paths withRowAnimation:UITableViewRowAnimationTop];
        
        // Scroll to the new message
                [self.tableView scrollToRowAtIndexPath:[NSIndexPath indexPathForRow:0 inSection:0]
                                      atScrollPosition:UITableViewScrollPositionTop animated:YES];
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
        
        // Flip the cell 180 degrees
        cell.transform = CGAffineTransformMakeRotation(M_PI);
        
        // Configure the cell...
        FCMessage *message = [self.wall objectAtIndex:indexPath.row];
        // Hardcoding message icon and color for now
    //    message.color = @"#FFA400";
    //    message.icon = @"profilepic";
        // Set message cell values
        [cell setMessage:message];
        
        // This message should track whether it's owner is in range or not, and fade out if appropriate...
        if ([message.text  isEqual: @"Wat"]) {
            cell.contentView.alpha = 0.2;
        } else { // Must be reset, because the cell gets recycled
            cell.contentView.alpha = 1.0;
        }
        
        return cell;
    }
    
    return nil;
}

- (CGFloat) tableView:(UITableView *)tableView heightForRowAtIndexPath:(NSIndexPath *)indexPath
{
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
    
    CGRect newContainerFrame = [[self tableView] frame];
    newContainerFrame.size.height += sizeChange;
    
    NSLog(@"sizeChange = %f", sizeChange);
    
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
    
    NSInteger returnValue = 7;//change this value for now
    
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


@end
