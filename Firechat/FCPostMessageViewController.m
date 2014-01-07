//
//  FCPostMessageViewController.m
//  Firechat
//
//  Created by Alonso Holmes on 12/26/13.
//  Copyright (c) 2013 Buildco. All rights reserved.
//

#import "FCPostMessageViewController.h"
#import "FCUser.h"

@interface FCPostMessageViewController ()
@property (weak, nonatomic) IBOutlet UIBarButtonItem *postButton;
@property (weak, nonatomic) IBOutlet UITextField *messageText;
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
    if (sender != self.postButton){
        return;
    }
    
   
    
    if (self.messageText.text.length > 0){
        // Create a new post
        self.message = [[FCMessage alloc] init];
        self.message.text = self.messageText.text;
//        self.message.user = [[FCUser alloc] init];
    }
    

}

- (void)viewDidLoad
{
    [super viewDidLoad];
	// Do any additional setup after loading the view.
    
    
}

- (void)viewWillAppear:(BOOL)animated
{
//    [self.messageText becomeFirstResponder];
//    [self.messageText setContentVerticalAlignment:UIControlContentVerticalAlignmentTop];
}

- (void)didReceiveMemoryWarning
{
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

@end
