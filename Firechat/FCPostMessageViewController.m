//
//  FCPostMessageViewController.m
//  Firechat
//
//  Created by Alonso Holmes on 12/26/13.
//  Copyright (c) 2013 Buildco. All rights reserved.
//

#import "FCPostMessageViewController.h"
#import "FCUser.h"
#import "FCAppDelegate.h"
#import <Firebase/Firebase.h>

@interface FCPostMessageViewController ()
@property (weak, nonatomic) IBOutlet UIBarButtonItem *postButton;
@property (weak, nonatomic) IBOutlet UITextField *messageText;
@property FCUser *owner;
@property Firebase *rootRef;
@end

@implementation FCPostMessageViewController

- (id)initWithNibName:(NSString *)nibNameOrNil bundle:(NSBundle *)nibBundleOrNil
{
    self = [super initWithNibName:nibNameOrNil bundle:nibBundleOrNil];
    if (self) {
        // Custom initialization
    }
    return self;
}
- (IBAction)fieldChanged:(id)sender {
    if (self.messageText.text.length > 0){
        self.postButton.enabled = YES;
    } else{
        self.postButton.enabled = NO;
    }
}

- (void) prepareForSegue:(UIStoryboardSegue *)segue sender:(id)sender
{
    NSLog(@"PREPARE!");
    if (sender != self.postButton){
        return;
    }

    if (self.messageText.text.length > 0){
        // Create a new post
//        self.message = [[FCMessage alloc] init];
//        self.message.text = self.messageText.text;
//        self.message.owner = self.owner.id;
        
        // Create the message object
        NSDictionary *message = @{@"ownerID": self.owner.id,
                                     @"text": self.messageText.text};
        
        [self postMessage:message];
        // Post to everyone in that list
        // If successful, return
//        return;
    }
    

}

- (void)viewDidLoad
{
    [super viewDidLoad];
	// Do any additional setup after loading the view.
    self.owner = [(FCAppDelegate *)[[UIApplication sharedApplication] delegate] owner];
    // Setup the firebase ref
    self.rootRef = [[Firebase alloc] initWithUrl:@"https://orbit.firebaseio.com/"];
    
}

- (void)viewWillAppear:(BOOL)animated
{
    [self.messageText becomeFirstResponder];
//    [self.messageText setContentVerticalAlignment:UIControlContentVerticalAlignmentTop];
}

- (void)didReceiveMemoryWarning
{
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

# pragma mark - posting a message
- (void)postMessage:(NSDictionary *)message
{
    // Grab the current list of iBeacons
    NSArray *beaconIds = [self.owner.beacon getBeaconIds];
    
    // Loop through and post to the firebase of every beacon in range
    for (NSString *beaconId in beaconIds)
    {
        // Post to the firebase wall of this beacon
        [[[[[self.rootRef childByAppendingPath:@"users"] childByAppendingPath:beaconId] childByAppendingPath:@"wall"] childByAutoId] setValue:message];
        NSLog(@"Beacon loop says: %@",beaconId);
    }
    
    // Also post to yourself
    [[[self.owner.ref childByAppendingPath:@"wall"] childByAutoId] setValue:message];
    
}

@end
