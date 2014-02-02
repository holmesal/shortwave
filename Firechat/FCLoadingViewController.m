//
//  FCLoginViewController.m
//  Firechat
//
//  Created by Alonso Holmes on 12/31/13.
//  Copyright (c) 2013 Buildco. All rights reserved.
//

#import "FCLoadingViewController.h"
#import <Firebase/Firebase.h>
#import "FirebaseSimpleLogin/FirebaseSimpleLogin.h"
#import "FCAppDelegate.h"
#import "FCUser.h"


@interface FCLoadingViewController ()
@property FirebaseSimpleLogin *authClient;
@property FCUser *owner;
@end

@implementation FCLoadingViewController

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
	// Auth with Firebase
    [self authWithFirebase];
    // Load shared user
    self.owner = [(FCAppDelegate *)[[UIApplication sharedApplication] delegate] owner];
    self.navigationController.navigationBarHidden = YES;
}

- (void)authWithFirebase
{
    Firebase *ref = [[Firebase alloc] initWithUrl:@"https://orbit.firebaseio.com"];
    self.authClient = [[FirebaseSimpleLogin alloc] initWithRef: ref];
    
    [self.authClient checkAuthStatusWithBlock:^(NSError *error, FAUser *user) {
        if (error != nil) {
            NSLog(@"%@",[error localizedDescription]);
            
        } else if (user == nil) {
            // Show the login button
            NSLog(@"%@",@"User is NOT logged in :(");
        } else {
            // User is logged in
            // Segue to the wall view
            NSLog(@"%@",@"User is already logged in!");
            [self.owner setupWithTwitter:user withCompletionBlock:^(NSError *error) {
                if(!error){
                    [self performSegueWithIdentifier:@"SegueLoadingToWall" sender:self];
                }
            }];
//            [self.authClient logout];
            // At this point, user is stored on the root
            
        }
    }];
}
- (IBAction)twitterLoginClicked:(id)sender {
    NSLog(@"Twitter click");
    [self.authClient loginToTwitterAppWithId:@"fBiYsDwLbLCknW4mdlUV5w" multipleAccountsHandler:^int(NSArray *usernames) {
        // Handle multiple accounts
        NSLog(@"%@",usernames);
        // return [self selectUsername:usernames]
        // TODO - choose the correct account
        // TODO - test this - might not be necessary
        // Necessary to handle case where no accounts are linked?
//        if ([usernames count]>1) {
//            return [self selectUsername:usernames];
//        } else{
//            return 0;
//        }
        // Need to find a way to open the picker modal from within this block, and return the value that the login modal returns
        return 0;
    } withCompletionBlock:^(NSError *error, FAUser *twitterUser) {
        if (error!=nil) {
            NSLog(@"%@",error);
        } else{
            NSLog(@"Logged in user successfully.");
            // Setup with twitter
            [self.owner setupWithTwitter:twitterUser withCompletionBlock:^(NSError *error) {
                if(!error){
                    [self performSegueWithIdentifier:@"SegueLoadingToWall" sender:self];
                }
            }];
        }
    }];
}

//- (NSInteger)selectUsername:(NSArray *)usernames
//{
//    UIViewController *viewPicker = [[UIViewController alloc] init];
////    [self performSeg]
//    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(loginComplete:) name:@"LoginComplete" object:nil];
//
//}

- (void)didReceiveMemoryWarning
{
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

@end
