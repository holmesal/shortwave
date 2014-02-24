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

@interface FCWallViewController ()
@property (weak, nonatomic) IBOutlet UITableView *tableView;
@property FCUser *owner;
@property Firebase *ref;
@property NSMutableArray *wall;
@property NSArray *beacons;
@property PHFComposeBarView *composeBarView;
@end

@implementation FCWallViewController

- (id)initWithNibName:(NSString *)nibNameOrNil bundle:(NSBundle *)nibBundleOrNil
{
    self = [super initWithNibName:nibNameOrNil bundle:nibBundleOrNil];
    if (self) {
        // Custom initialization

    }
    return self;
}

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
    
    // Flip the table view
    self.tableView.transform = CGAffineTransformMakeRotation(-M_PI);
    // Hide the scroll indicator TEHEHEHEHEHEHE
    [self.tableView setShowsVerticalScrollIndicator:NO];
    
    // Offset the height of the tableView by whatever the compose bar height is
    CGRect newTableFrame = self.tableView.frame;
    NSLog(@"start frame %f",self.tableView.frame.size.height);
    
    newTableFrame.size.height -= 200;
    NSLog(@"end frame %f",newTableFrame.size.height);
    [self.tableView setFrame:newTableFrame];
    
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
    
    // Load the compose view
    [self loadComposeView];
    
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

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath
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
    
    return cell;
}

- (CGFloat) tableView:(UITableView *)tableView heightForRowAtIndexPath:(NSIndexPath *)indexPath
{
    FCMessage *message = [self.wall objectAtIndex:indexPath.row];
//    NSString *text =  message.text;
//    message.text sizeWithFont:[ ] constrainedToSize:<#(CGSize)#>
    return 75;
}

# pragma mark - keyboard did show/hide
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
    
    CGRect newContainerFrame = [[self view] frame];
    newContainerFrame.origin.y += sizeChange;
    
    [UIView animateWithDuration:duration
                          delay:0
                        options:(animationCurve << 16)|UIViewAnimationOptionBeginFromCurrentState
                     animations:^{
                         [[self view] setFrame:newContainerFrame];
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
    [self.tableView setFrame:newFrame];
}

@end
