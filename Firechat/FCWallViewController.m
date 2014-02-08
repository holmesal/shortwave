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
    // Show the navbar
    self.navigationController.navigationBarHidden = NO;
    // Init table view
    self.tableView.delegate = self;
    self.tableView.dataSource = self;
	// Get the owner
    self.owner = [(FCAppDelegate *)[[UIApplication sharedApplication] delegate] owner];
    NSLog(@"owner's id: %@",self.owner.id);
    [self.tableView reloadData];
    
    // Bind to the owner's wall
    [self bindToWall];
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
        
        // Init a new message
        // the message will take care of loading the user, so give it a callback for finishing that
        // when that callback fires, add it to the messages array
        // MAYBE - add a placeholder, and call reload data when it loads?
        // Create the message
        //        NSLog(@"%@",snapshot.value);
        [[FCMessage alloc] initWithSnapshot:snapshot withLoadedBlock:^(NSError *error, FCMessage *message) {
            //            NSLog(@"RAN MESSAGE USER LOADED CALLBACK BLOCK with message");
            //            NSLog(@"%@",message.text);
            // Push onto the wall array
            //            [self.wall addObject:message];
            //            NSLog(@"%@",self.wall);
//            [self.wall insertObject:message atIndex:0];
            [self.wall addObject:message];
            
            //            NSLog(@"Wall count is %i",[self.wall count]);
            
            // Update the table view
            [self.tableView reloadData];
            [self.tableView scrollToRowAtIndexPath:[NSIndexPath indexPathForRow:[self.wall count] - 1 inSection:0]
                                  atScrollPosition:UITableViewScrollPositionTop animated:YES];
        }];
        
        //        FCMessage *message = [[FCMessage alloc] initWithSnapshot:snapshot];
        // Unshift
        //        [self.wall insertObject:message atIndex:0];
        // Update the table view
        //        [self.tableView reloadData];
    }];
}

#pragma mark - Table view data source

- (NSInteger)numberOfSectionsInTableView:(UITableView *)tableView
{
    // Return the number of sections.
    NSLog(@"ASKED FOR SECTIONS");
    return 1;
}

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section
{
    // Return the number of rows in the section.
    NSLog(@"wall length count: %lu", (unsigned long)[self.wall count]);
    return [self.wall count];
}

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath
{
    static NSString *CellIdentifier = @"MessageCell";
    FCMessageCell *cell = [tableView dequeueReusableCellWithIdentifier:CellIdentifier forIndexPath:indexPath];
    
    // Configure the cell...
    FCMessage *message = [self.wall objectAtIndex:indexPath.row];
    //    cell.messageText.text = [message valueForKey:@"text"];
    cell.messageText.text = message.text;
    //    cell.profilePhoto.imageURL
//    cell.profilePhoto.imageURL = message.imageUrl;
    //    NSLog(@"image url is: %@",message.imageUrl);
//    //    cell.profilePhoto.imageURL = [[NSURL alloc] initWithString:@"http://upload.wikimedia.org/wikipedia/en/4/4e/Shibe_Inu_Doge_meme.jpg"];
    cell.username.text = message.username;
    // Rounded profile photo
    cell.profilePhoto.layer.masksToBounds = YES;
    cell.profilePhoto.layer.cornerRadius = 25;
    
    //    FCUser *user = [message objectForKey:@"user"];
    
    //    cell.username.text = message.user.username;
    //    cell.profilePhoto.imageURL = [[NSURL alloc] initWithString:message.user.imageURL];
    
    return cell;
}

- (IBAction)unwindToList:(UIStoryboardSegue *)segue
{
}

@end
