//
//  FCSignupViewController.m
//  Firechat
//
//  Created by Alonso Holmes on 2/2/14.
//  Copyright (c) 2014 Buildco. All rights reserved.
//

#import "FCSignupViewController.h"
#import "FCAnonOverlayViewController.h"
#import "FCBeacon.h"

@interface FCSignupViewController ()
@property (weak, nonatomic) IBOutlet UIButton *getStartedButton;
@property (weak, nonatomic) IBOutlet UIView *signupOverlay;

@property (weak, nonatomic) IBOutlet UILabel *titleLabel;
@property (weak, nonatomic) IBOutlet UILabel *supportingLabel;
@property (weak, nonatomic) IBOutlet UILabel *requirementsLabel;
@property FCAnonOverlayViewController *overlayViewController;
@end

@implementation FCSignupViewController

- (id)initWithNibName:(NSString *)nibNameOrNil bundle:(NSBundle *)nibBundleOrNil
{
    self = [super initWithNibName:nibNameOrNil bundle:nibBundleOrNil];
    if (self) {
        // Custom initialization
    }
    return self;
}

- (void)viewDidLoad
{
    [super viewDidLoad];
    self.navigationController.navigationBarHidden = YES;
    
    // Button should be square with a white border
    self.getStartedButton.layer.borderWidth = 0.6f;
    self.getStartedButton.layer.borderColor = [UIColor whiteColor].CGColor;
    
    // Listen for the "Signup Success" event to move forward
    [[NSNotificationCenter defaultCenter] addObserver:self
                                             selector:@selector(signupSuccess:)
                                                 name:@"Signup Success"
                                               object:nil];
}

// Get the container view's embedded view controller
- (void) prepareForSegue:(UIStoryboardSegue *)segue sender:(id)sender
{
    NSString * segueName = segue.identifier;
    if ([segueName isEqualToString: @"embedSignupOverlay"]) {
        self.overlayViewController = (FCAnonOverlayViewController *) [segue destinationViewController];
//        AlertView * alertView = childViewController.view;
        // do something with the AlertView's subviews here...
    }
}

- (void)didReceiveMemoryWarning
{
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}







//-(void)setProfileImage
//{
//    [self.profileImageButton setBackgroundImage:self.image forState:UIControlStateNormal];
//}


- (IBAction)signupButtonTapped:(id)sender {
    // Ask for beacon support
    [[FCBeacon alloc] init];
    
    // For now - show the signup overlay
    self.signupOverlay.hidden = NO;
    // Animate it in
    [UIView animateWithDuration:0.2f
                     animations:^{
                         // Hide the get started button so the text doesn't clash
                         [self.getStartedButton setAlpha:0];
                         [self.titleLabel setAlpha:0];
                         [self.supportingLabel setAlpha:0];
                         [self.requirementsLabel setAlpha:0];
                         
                         
                         // Show the overlay
                         [self.signupOverlay setAlpha:1.0f];
                         
                         
//                         [self.signupOverlay setCenter:CGPointMake(200, 200)];
                     }
     ];
    // Have the child view controller do it's thing
    [self.overlayViewController showWithAnimation];
    
    // Create a new user
//    [[FCUser alloc] signupWithUsername:self.usernameTextField.text andImage:self.image];
//    // Disable the button
//    [sender setEnabled:NO];
//    [sender setTitle:@"Please wait." forState:UIControlStateNormal];
    // Wait for the success notification
}

- (void)signupSuccess:(NSNotification *)notification
{
    
    NSLog(@"Signup was a success!");
    [self performSegueWithIdentifier:@"showHomescreen" sender:self];
}

@end
