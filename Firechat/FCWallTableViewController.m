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
#import "FCAppDelegate.h"

//#import <CoreBluetooth/CoreBluetooth.h>
#import <CoreLocation/CoreLocation.h>

@interface FCWallTableViewController ()
@property Firebase *ref;
//@property Firebase *usersRef;
//@property Firebase *wallRef;
@property FCUser *owner;
@property NSString *userID;
@property NSMutableArray *wall;
@property NSArray *beacons;

@end

@implementation FCWallTableViewController

- (IBAction)unwindToList:(UIStoryboardSegue *)segue
{
    
    // Doesn't work without this, need to figure out how to take it out...
    
//    // Get controller
//    if([[segue sourceViewController] isKindOfClass:[FCPostMessageViewController class]])
//    {
//        
////        FCPostMessageViewController *source = [segue sourceViewController];
//        
//        // Get item (if it's there)
////        FCMessage *message = source.message;
//        
//        // Set the user to self
//        //    message.user = self.owner.id;
//        
////        if (message != nil){
//            // Sync with firebase
//            //        NSLog([message toDictionary]);
//            //        Firebase *newRef = [[Firebase alloc] initWithUrl:@"https://orbit.firebaseio.com/"];
////            [self postMessage:message toUser:@"1234"];
//            
////        }
//        
//    }
    
    
        // Add to list, sync with people nearby
}

//- (void)postMessage:(FCMessage *)message toUser:(NSString *)userID
//{
////    listRef = 
////    [[newRef childByAppendingPath:@"testPath"] setValue:[message toDictionary]];
//    // Create a firebase ref for the user we're posting to
//    // Hmm. Might be easier just to build out of the URL fragments
////    Firebase *userRef = [self.usersRef childByAppendingPath:userID];
////    Firebase *wallRef = [userRef childByAppendingPath:@"wall"];
//    // Append the message
//    Firebase *pushRef = [self.ref childByAutoId];
//    [pushRef setValue:[message toDictionary]];
//    
//}



// THIS DOESN'T GET CALLED WHY
//- (id)init
//{
//    self = [super init];
//    NSLog(@"INITIALIZING");
//    if (self) {
//        
//        self.wall = [NSMutableArray array];
//        [self.wall addObject:@"hi there"];
//        self.beacons = [[NSArray alloc] init];
//    }
//    return self;
//}

- (id)initWithStyle:(UITableViewStyle)style
{
    self = [super initWithStyle:style];
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
    
    self.navigationController.navigationBarHidden = NO;
    
    // Get the owner
    self.owner = [(FCAppDelegate *)[[UIApplication sharedApplication] delegate] owner];
    
    // Listen for beacon updates
//    [[NSNotificationCenter defaultCenter] addObserver:self
//                                             selector:@selector(beaconsUpdated:)
//                                                 name:@"Beacons Updated"
//                                               object:nil];
    
//    [self initFirebase];
    NSLog(@"owner's id: %@",self.owner.id);
    
    [self.tableView reloadData];
    
    // Bind to the owner's wall
    [self bindToWall];
    
    
    
    

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
            [self.wall insertObject:message atIndex:0];
            
//            NSLog(@"Wall count is %i",[self.wall count]);
            
            // Update the table view
            [self.tableView reloadData];
        }];
        
//        FCMessage *message = [[FCMessage alloc] initWithSnapshot:snapshot];
        // Unshift
//        [self.wall insertObject:message atIndex:0];
        // Update the table view
//        [self.tableView reloadData];
    }];
}

//# pragma mark - beacon ranging
//- (void)beaconsUpdated:(NSNotification *)notification
//{
//    NSLog(@"Got notification from center!");
//    
//    NSLog(@"%@",notification.object);
//    self.beacons = notification.object;
//}

//- (void)initFirebase
//{
//    // Firebase ref for the users
//    self.usersRef = [[Firebase alloc] initWithUrl:@"https://orbit.firebaseio.com/users"];
//    // Setup firebase to observe the wall
//    self.selfRef = [self.usersRef childByAppendingPath:self.userID];
//    [self.selfRef observeEventType:FEventTypeValue withBlock:^(FDataSnapshot *snapshot) {
//        self.owner = [[FCUser alloc] initWithSnapshot:snapshot.value andID:self.userID];
//    }];
//    
//    
//    
////    self.userRef = [[Firebase alloc] initWithUrl:@"https://orbit.firebaseio.com/user"];
//    
//    // Observe the wall
//    self.wallRef = [self.selfRef childByAppendingPath:@"wall"];
//    [self.wallRef observeEventType:FEventTypeChildAdded withBlock:^(FDataSnapshot *snapshot){
//        
//        // initialize a user
//        FCUser *user = [[FCUser alloc] initWithSnapshot:[snapshot.value objectForKey:@"user"]];
//        // Make a message
////        NSMutableDictionary *message = [[NSMutableDictionary alloc] init];
////        [message setValue:[snapshot.value objectForKey:@"message"] forKey:@"text"];
////        [message setObject:user forKey:@"user"];
//        
//        FCMessage *message = [[FCMessage alloc] initWithText:[snapshot.value objectForKey:@"text"] user:user];
//        
//        // Push onto the wall
//        [self.wall insertObject:message atIndex:0];
////        [self.wall addObject:message];
////        NSLog(@"%@", [snapshot.value objectForKey:@"message"]);
//
//        // Update the table view
//        [self.tableView reloadData];
//    }];
//    
//}

#pragma mark - Table view data source

- (NSInteger)numberOfSectionsInTableView:(UITableView *)tableView
{
    // Return the number of sections.
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
    cell.profilePhoto.imageURL = [[NSURL alloc] initWithString:@"http://upload.wikimedia.org/wikipedia/en/4/4e/Shibe_Inu_Doge_meme.jpg"];
    cell.username.text = message.username;
    // Rounded profile photo
    cell.profilePhoto.layer.masksToBounds = YES;
    cell.profilePhoto.layer.cornerRadius = 25;
    
//    FCUser *user = [message objectForKey:@"user"];
    
//    cell.username.text = message.user.username;
//    cell.profilePhoto.imageURL = [[NSURL alloc] initWithString:message.user.imageURL];
    
    return cell;
}
//
//- (CGFloat)tableView:(UITableView *)tableView heightForRowAtIndexPath:(NSIndexPath *)indexPath
//{
//    // Similar to tableView:cellForRowAtIndexPath: you can dequeue a cell here just like you did there.
//    // But it may be better to instead hold a single (offscreen) instance of a cell for each cell identifier in a private property.
//    // (If you have more than a couple unique layouts/reuse identifiers, use an NSDictionary and fill it with once cell for each.)
//    // So instead, if you only had one reuse identifier your code might look like:
//    // if (!self.offscreenCell) {
//    //     self.offscreenCell = [[MyTableViewCellClass alloc] init];
//    // }
//    // Then just use self.offscreenCell throughout this method. (You're just using this cell as a template to get the height out.)
//    FCMessageCell *cell = [tableView dequeueReusableCellWithIdentifier:@"MessageCell"];
//    
//    // Configure the cell with content for the given indexPath, for example:
//    // cell.textLabel.text = someTextForThisCell;
//    // ...
//    
//    // Make sure the constraints have been set up for this cell, since it may have just been created from scratch.
//    // If you're setting up constraints from within the cell's updateConstraints method, add the following lines:
//    [cell setNeedsUpdateConstraints];
//    [cell updateConstraintsIfNeeded];
//    
//    // Set the width of the cell to match the width of the table view. This is important so that we'll get the
//    // correct cell height for different table view widths if the cell's height depends on its width (due to
//    // multi-line UILabels word wrapping, etc). We don't need to do this above in -[tableView:cellForRowAtIndexPath]
//    // because it happens automatically when the cell is used in the table view.
//    cell.bounds = CGRectMake(0.0f, 0.0f, CGRectGetWidth(tableView.bounds), CGRectGetHeight(cell.bounds));
//    
//    // Do the layout pass on the cell, which will calculate the frames for all the views based on the constraints.
//    // (Note that you must set the preferredMaxLayoutWidth on multi-line UILabels inside the -[layoutSubviews] method
//    // of the UITableViewCell subclass, or do it manually at this point before the below 2 lines!)
//    cell.messageText.preferredMaxLayoutWidth = 200.0f;
//    [cell setNeedsLayout];
//    [cell layoutIfNeeded];
//    
//    // Get the actual height required for the cell's contentView
//    CGFloat height = [cell.contentView systemLayoutSizeFittingSize:UILayoutFittingCompressedSize].height;
//    
//    // Add an extra point to the height to account for the cell separator, which is added between the bottom
//    // of the cell's contentView and the bottom of the table view cell.
//    height += 1.0f;
//    
////    height = 200.0f;
//    
//    return height;
//}
//
//- (CGFloat)tableView:(UITableView *)tableView estimatedHeightForRowAtIndexPath:(NSIndexPath *)indexPath
//{
//    // Return a fixed constant if possible, or do some minimal calculations if needed to be able to return an
//    // estimated row height that's at least within an order of magnitude of the actual height.
//    // For example:
//    return 200.0f;
////    if ([self isTallCellAtIndexPath:indexPath]) {
////        return 150.0f;
////    } else {
////        return 60.0f;
////    }
//}

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
