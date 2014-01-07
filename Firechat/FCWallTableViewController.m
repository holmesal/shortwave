//
//  FCWallTableViewController.m
//  Firechat
//
//  Created by Alonso Holmes on 12/23/13.
//  Copyright (c) 2013 Buildco. All rights reserved.
//

#import "FCWallTableViewController.h"
#import "FCPostMessageViewController.h"
#import <Firebase/Firebase.h>
#import "FCMessage.h"
#import "FCMessageCell.h"

@interface FCWallTableViewController ()
@property Firebase *selfRef;
@property Firebase *usersRef;
@property Firebase *wallRef;
@property FCUser *user;
@property NSString *userID;
@property NSMutableArray *wall;

@end

@implementation FCWallTableViewController

- (IBAction)unwindToList:(UIStoryboardSegue *)segue
{
    // Get controller
    FCPostMessageViewController *source = [segue sourceViewController];
    
    // Get item (if it's there)
    FCMessage *message = source.message;
    
    // Set the user to self
    message.user = self.user;
    
    if (message != nil){
        // Sync with firebase
//        NSLog([message toDictionary]);
//        Firebase *newRef = [[Firebase alloc] initWithUrl:@"https://orbit.firebaseio.com/"];
        [self postMessage:message toUser:@"1234"];
        
    }
    
        // Add to list, sync with people nearby
}

- (void)postMessage:(FCMessage *)message toUser:(NSString *)userID
{
//    listRef = 
//    [[newRef childByAppendingPath:@"testPath"] setValue:[message toDictionary]];
    // Create a firebase ref for the user we're posting to
    // Hmm. Might be easier just to build out of the URL fragments
    Firebase *userRef = [self.usersRef childByAppendingPath:userID];
    Firebase *wallRef = [userRef childByAppendingPath:@"wall"];
    // Append the message
    Firebase *pushRef = [wallRef childByAutoId];
    [pushRef setValue:[message toDictionary]];
    
}

- (id)initWithStyle:(UITableViewStyle)style
{
    self = [super initWithStyle:style];
    if (self) {
        // Custom initialization
        
    }
    return self;
}

- (void)viewDidLoad
{
    [super viewDidLoad];
    
    // Hardcoded id for now
    self.userID = @"1234";
    [self initFirebase];
    
    self.wall = [[NSMutableArray alloc] init];
    
    

    // Uncomment the following line to preserve selection between presentations.
    // self.clearsSelectionOnViewWillAppear = NO;
 
    // Uncomment the following line to display an Edit button in the navigation bar for this view controller.
    // self.navigationItem.rightBarButtonItem = self.editButtonItem;
}

- (void)didReceiveMemoryWarning
{
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

# pragma mark - firebase

- (void)initFirebase
{
    // Firebase ref for the users
    self.usersRef = [[Firebase alloc] initWithUrl:@"https://orbit.firebaseio.com/users"];
    // Setup firebase to observe the wall
    self.selfRef = [self.usersRef childByAppendingPath:self.userID];
    [self.selfRef observeEventType:FEventTypeValue withBlock:^(FDataSnapshot *snapshot) {
        self.user = [[FCUser alloc] initWithSnapshot:snapshot.value andID:self.userID];
    }];
//    self.userRef = [[Firebase alloc] initWithUrl:@"https://orbit.firebaseio.com/user"];
    
    // Observe the wall
    self.wallRef = [self.selfRef childByAppendingPath:@"wall"];
    [self.wallRef observeEventType:FEventTypeChildAdded withBlock:^(FDataSnapshot *snapshot){
        
        // initialize a user
        FCUser *user = [[FCUser alloc] initWithSnapshot:[snapshot.value objectForKey:@"user"]];
        // Make a message
//        NSMutableDictionary *message = [[NSMutableDictionary alloc] init];
//        [message setValue:[snapshot.value objectForKey:@"message"] forKey:@"text"];
//        [message setObject:user forKey:@"user"];
        
        FCMessage *message = [[FCMessage alloc] initWithText:[snapshot.value objectForKey:@"text"] user:user];
        
        // Push onto the wall
        [self.wall insertObject:message atIndex:0];
//        [self.wall addObject:message];
//        NSLog(@"%@", [snapshot.value objectForKey:@"message"]);

        // Update the table view
        [self.tableView reloadData];
    }];
    
}

#pragma mark - Table view data source

- (NSInteger)numberOfSectionsInTableView:(UITableView *)tableView
{
    // Return the number of sections.
    return 1;
}

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section
{
    // Return the number of rows in the section.
    NSLog(@"%lu", (unsigned long)[self.wall count]);
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
    
//    FCUser *user = [message objectForKey:@"user"];
    
    cell.userName.text = message.user.username;
    cell.profilePhoto.imageURL = [[NSURL alloc] initWithString:message.user.imageURL];
    
    return cell;
}

/*
// Override to support conditional editing of the table view.
- (BOOL)tableView:(UITableView *)tableView canEditRowAtIndexPath:(NSIndexPath *)indexPath
{
    // Return NO if you do not want the specified item to be editable.
    return YES;
}
*/

/*
// Override to support editing the table view.
- (void)tableView:(UITableView *)tableView commitEditingStyle:(UITableViewCellEditingStyle)editingStyle forRowAtIndexPath:(NSIndexPath *)indexPath
{
    if (editingStyle == UITableViewCellEditingStyleDelete) {
        // Delete the row from the data source
        [tableView deleteRowsAtIndexPaths:@[indexPath] withRowAnimation:UITableViewRowAnimationFade];
    }   
    else if (editingStyle == UITableViewCellEditingStyleInsert) {
        // Create a new instance of the appropriate class, insert it into the array, and add a new row to the table view
    }   
}
*/

/*
// Override to support rearranging the table view.
- (void)tableView:(UITableView *)tableView moveRowAtIndexPath:(NSIndexPath *)fromIndexPath toIndexPath:(NSIndexPath *)toIndexPath
{
}
*/

/*
// Override to support conditional rearranging of the table view.
- (BOOL)tableView:(UITableView *)tableView canMoveRowAtIndexPath:(NSIndexPath *)indexPath
{
    // Return NO if you do not want the item to be re-orderable.
    return YES;
}
*/

/*
#pragma mark - Navigation

// In a story board-based application, you will often want to do a little preparation before navigation
- (void)prepareForSegue:(UIStoryboardSegue *)segue sender:(id)sender
{
    // Get the new view controller using [segue destinationViewController].
    // Pass the selected object to the new view controller.
}

 */

@end
