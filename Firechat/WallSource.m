//
//  WallSource.m
//  Shortwave
//
//  Created by Ethan Sherr on 7/19/14.
//  Copyright (c) 2014 Buildco. All rights reserved.
//

#import "WallSource.h"
#import "MessageModel.h"
#import "MessageCell.h"

#define kMAX_NUMBER_OF_MESSAGES 100
#define kWallCollectionView_MAX_CELLS_INSERT 20
#define kWallCollectionView_CELL_INSERT_TIMEOUT 0.1f

@interface WallSource ()

@property (strong, nonatomic) NSMutableArray *wall; //what is actually displayed (models)
@property (strong, nonatomic) NSMutableArray *wallNames; //the order of all cells, some may still be loading

@property (weak, nonatomic) ESSpringFlowLayout *layout;
@property (weak, nonatomic) UICollectionView *collectionView;

@property (strong, nonatomic) NSTimer *wallQueueInsertTimer;

//firebase management
@property (assign, nonatomic) FirebaseHandle wallHandleInsert;
@property (assign, nonatomic) FirebaseHandle wallHandleMove;
@property (strong, nonatomic) FQuery *wallRefQueryLimit;
@property (strong, nonatomic) FDataSnapshot *firstSnapshotFromWall;
@property (atomic, strong) NSMutableArray *wallQueue; //when inserting cells to fast

@property (nonatomic, strong) NSArray *hideCells;
//@property (strong, nonatomic) NSMutableDictionary *messageIdsToReplacingId; //messages are stored
@property (strong, nonatomic) NSMutableDictionary *usersDictionary;
@property (strong, nonatomic) NSMutableDictionary *userNameToModelsArray;

@property (strong, nonatomic) NSMutableArray *namesOfPendingMessages;

@end

@implementation WallSource

@synthesize wall;
@synthesize layout;
@synthesize collectionView;
@synthesize url;
@synthesize firstSnapshotFromWall;
@synthesize wallQueueInsertTimer;
@synthesize wallQueue;

@synthesize userNameToModelsArray;
@synthesize wallNames;
//@synthesize messageIdsToReplacingId;
@synthesize usersDictionary;
@synthesize namesOfPendingMessages;


-(id)initWithUrl:(NSString*)URL collectionView:(UICollectionView*)cv andLayout:(ESSpringFlowLayout*)lay
{
    if (self = [super init])
    {
        url = URL;
        collectionView = cv;
        layout = lay;
        
        wall = [[NSMutableArray alloc] init];
        wallQueue = [[NSMutableArray alloc] initWithCapacity:kWallCollectionView_MAX_CELLS_INSERT];
        wallNames = [[NSMutableArray alloc] init];
//        messageIdsToReplacingId = [[NSMutableDictionary alloc] init];
        
        userNameToModelsArray = [[NSMutableDictionary alloc] init];
        
        usersDictionary = [[NSMutableDictionary alloc] init];
        
        namesOfPendingMessages = [[NSMutableArray alloc] init];
        
        [self bindToWall];
    }
    return self;
}

-(void)bindToWall
{
    Firebase *wallRef = [[Firebase alloc] initWithUrl:url];
    
    
    _wallRefQueryLimit = [wallRef queryLimitedToNumberOfChildren:kMAX_NUMBER_OF_MESSAGES];
    __weak typeof(self) weakSelf = self;
    self.wallHandleInsert = [self.wallRefQueryLimit observeEventType:FEventTypeChildAdded andPreviousSiblingNameWithBlock:^(FDataSnapshot *messageIdSnapshot, NSString *previous)
    {
        NSLog(@"&&");
        
        NSLog(@"snap.name = %@", messageIdSnapshot.name);
        NSLog(@"previous = %@", previous);
        
        if ([messageIdSnapshot.value isKindOfClass:[NSString class]])
        {
         if (!firstSnapshotFromWall)
             firstSnapshotFromWall = messageIdSnapshot;
         
         //lookup where to place this name..
         NSInteger index = wallNames.count;
         if (previous) //make block to observe child moved events on messages
         {
             //[messageIdsToReplacingId setObject:previous forKey:messageIdSnapshot.name]; //just keeping track of which message this will replace...
             NSInteger integer = [wallNames indexOfObject:previous];
             if (integer < wallNames.count)
             {
                 NSLog(@"was found! %d", index);
                 index = integer;
             } else {NSAssert(NO, @"You needed to found it!");}
         }
         [wallNames insertObject:messageIdSnapshot.name atIndex:index];
         NSLog(@"wallNames = %@", wallNames);
         
         //lookup the message content!...
            [namesOfPendingMessages addObject:messageIdSnapshot.name];
            
         NSString *messageID = messageIdSnapshot.value;
         NSString *messageUrl = [NSString stringWithFormat:@"%@messages/%@/message", FIREBASE_ROOT_URL, messageID];
         Firebase *messageFB = [[Firebase alloc] initWithUrl:messageUrl];
         [messageFB observeSingleEventOfType:FEventTypeValue withBlock:^(FDataSnapshot* messageSnapshot)
          {
              if ([messageSnapshot.value isKindOfClass:[NSDictionary class]])
              {
                  MessageModel *model = [MessageModel messageModelFromValue:messageSnapshot.value];
                  if (model)
                  {
                    
                      model.name = messageSnapshot.name;
                      FCUser *user = [usersDictionary objectForKey:model.ownerID];
                      if (user)
                      {
                          [model setUserData:user];
                          [weakSelf addMessageToWallEventually:model];
                      } else
                      {
                          //save this model!
                          NSMutableArray *arrayOfModelsForUser = [userNameToModelsArray objectForKey:model.ownerID];
                          if (!arrayOfModelsForUser)
                          {
                              arrayOfModelsForUser = [[NSMutableArray alloc] init];
                              [userNameToModelsArray setObject:arrayOfModelsForUser forKey:model.ownerID];
                          }
                          
                          //setting models
                          [arrayOfModelsForUser addObject:model];
                          
                          //lookup user meta
                          //create user
                          //save user in usersDictionary
                      
                          Firebase *userMetaFB = [[Firebase alloc] initWithUrl:[NSString stringWithFormat:@"%@users/%@/meta", FIREBASE_ROOT_URL, model.ownerID] ];
                          [userMetaFB observeSingleEventOfType:FEventTypeValue withBlock:^(FDataSnapshot* snap)
                          {
                              if ([snap.value isKindOfClass:[NSDictionary class]])
                              {
                                  NSDictionary *dictionary = snap.value;
                                  NSString *color = dictionary[@"color"];
                                  NSString *icon = dictionary[@"icon"];
                                  FCUser *user = [[FCUser alloc] init];
                                  
                                  user.icon = icon;
                                  user.color = color;
                                  user.id = model.ownerID;
                                  
                                  //listen for value changes in color and icon
                                  [user registerListenersToMeta]; //when icon and color change, observe
                                  [user addObserver:self forKeyPath:@"color" options:(NSKeyValueObservingOptionNew | NSKeyValueObservingOptionOld) context:nil];
                                  [user addObserver:self forKeyPath:@"icon" options:(NSKeyValueObservingOptionNew | NSKeyValueObservingOptionOld) context:nil];
                                  
                                  
                                  [usersDictionary setObject:user forKey:user.id];
                                  
                                  NSMutableArray *arrayOfModelsForUser = [userNameToModelsArray objectForKey:user.id];
                                  for (MessageModel *messageModel in arrayOfModelsForUser)
                                  {
                                      [messageModel setUserData:user];
                                      [self addMessageToWallEventually:messageModel];
                                  }
                                  [userNameToModelsArray removeObjectForKey:user.id];
                              }
                          }];
                          
                      }
                  }
              }
          }];

        }
    } withCancelBlock:^(NSError *someError)
    {
        NSLog(@"error = %@", someError.localizedDescription);
    }];
    
    self.wallHandleMove = [self.wallRefQueryLimit observeEventType:FEventTypeChildMoved andPreviousSiblingNameWithBlock:^(FDataSnapshot *snap, NSString *previous)
    {
        if ([snap.value isKindOfClass:[NSString class]])
        {
            //current index
//            NSInteger indexOfName = [wallNames indexOfObject:snap.value];
            [wallNames removeObject:snap.value];
            
            //where is the previous child? or last position
            NSInteger indexOfPrevious = wallNames.count;
            if (previous) //make block to observe child moved events on messages
            {
                //[messageIdsToReplacingId setObject:previous forKey:messageIdSnapshot.name]; //just keeping track of which message this will replace...
                NSInteger integer = [wallNames indexOfObject:previous];
                if (integer < wallNames.count)
                {
                    NSLog(@"was found! %d", index);
                    indexOfPrevious = integer;
                } else {NSAssert(NO, @"You needed to found it!");}
            }
            
            //ok now it is time to move object at indexOfName, inserted to indexOfPrevious
            [wallNames insertObject:snap.name atIndex:indexOfPrevious];
            
        }
    } withCancelBlock:^(NSError *error){}];
    
    
}

-(NSInteger)indexInWallToInsertNewModelIn:(NSString*)name
{
    
    
    NSInteger i = 0;
    for (NSString *otherName in wallNames)
    {
        if (otherName == name)
        {
            break;
        } else
        if (![namesOfPendingMessages containsObject:otherName])
        {//then this cell is loaded
            i++;
        }
    }
    
    //now i is the index that "name" should be inserted into, and also "name" is no longer loading
    
    
    return i;
}

-(NSInteger)numberOfSectionsInCollectionView:(UICollectionView *)collectionView
{
    return 1;
}
-(NSInteger)collectionView:(UICollectionView *)collectionView numberOfItemsInSection:(NSInteger)section
{
    return wall.count;
}
-(UICollectionViewCell*)collectionView:(UICollectionView *)cV cellForItemAtIndexPath:(NSIndexPath *)indexPath
{
    
    
    MessageModel *messageModel = [self wallObjectAtIndex:indexPath.row]; //wall[indexPath.row];
    NSLog(@"cellForItemAtIndexPath %d", indexPath.row);
    NSLog(@"messageModel = %@, %@", messageModel.text, messageModel.ownerID);
    
    MessageCell *messageCell = [MessageCell messageCellFromMessageModel:messageModel andCollectionView:collectionView forIndexPath:indexPath andWallSource:self];
    
    CGRect aTempRect = messageCell.frame;
    [messageCell setFrame:aTempRect];
    
    return messageCell;
}
- (CGSize)collectionView:(UICollectionView *)cV layout:(UICollectionViewLayout*)collectionViewLayout sizeForItemAtIndexPath:(NSIndexPath *)indexPath
{
    MessageModel *model = [self wallObjectAtIndex:indexPath.row]; //wall[indexPath.row]
    CGFloat height = [MessageCell heightOfMessageCellForModel:model collectionView:(UICollectionView*)collectionView];
    return CGSizeMake(320, height);
}

//reverse
-(MessageModel*)wallObjectAtIndex:(NSInteger)index
{
    return wall[index];//wall[(wall.count-1)-index];
}

-(void)addMessageToWallEventually:(MessageModel*)messageModel
{
    if (wallQueueInsertTimer)
    {
        [wallQueueInsertTimer invalidate];
        wallQueueInsertTimer = nil;
    }
    
    [wallQueue addObject:messageModel];
    if (wallQueue.count < kWallCollectionView_MAX_CELLS_INSERT)
    {
        //        NSLog(@"begin timer to insert animated");
        //        [self insertMessagesToWallNow];
        wallQueueInsertTimer = [NSTimer timerWithTimeInterval:kWallCollectionView_CELL_INSERT_TIMEOUT target:self selector:@selector(insertMessagesToWallNow) userInfo:nil repeats:NO];
        [[NSRunLoop mainRunLoop] addTimer:wallQueueInsertTimer forMode:NSRunLoopCommonModes];
    } else
    {//drain wallQueue now without animation
        NSLog(@"&&&Drain wallqueue no animation&&&");
        [wall addObjectsFromArray:wallQueue];
        [wallQueue removeAllObjects];
        [collectionView reloadData];
        
        CGRect visibleRect = collectionView.frame;
        visibleRect.origin.y = collectionView.contentSize.height-visibleRect.size.height;
        [collectionView setContentOffset:CGPointMake(0, visibleRect.origin.y)];
        
        
    }
}

-(void)insertMessagesToWallNow
{
    //no longer consider messages in queue as 'pending'
    for (MessageModel *messageModel in wallQueue)
    {
        [namesOfPendingMessages removeObject:messageModel.name];
    }
    
    NSMutableArray *paths = [[NSMutableArray alloc] initWithCapacity:wallQueue.count];
    for (int i = 0; i < wallQueue.count; i++)
    {
        MessageModel *messageModel = wallQueue[i];
        
        NSInteger row = [self indexInWallToInsertNewModelIn:messageModel.name];
        [paths addObject: [NSIndexPath indexPathForRow:row inSection:0] ];
    }

    [collectionView performBatchUpdates:^
     {
         
         self.hideCells = [NSArray arrayWithArray:paths];
//         [self.wall addObjectsFromArray:wallQueue];//insertObject:unknownTypeOfMessage atIndex:weakSelf.wall.count];
         
         [collectionView insertItemsAtIndexPaths:paths];
         NSLog(@"**before wall = %@", wall);
         [self insertToWall:wallQueue inOrder:paths];
//         NSLog(@"indexPaths = %@", paths);
         NSLog(@"wallQueue = %@", wallQueue);
         NSLog(@"wall = %@", wall);
         
         [wallQueue removeAllObjects];
         //         NSLog(@"last indexPath = %@", [paths lastObject]);
         //         [wallCollectionView scrollToItemAtIndexPath:[paths lastObject] atScrollPosition:UICollectionViewScrollPositionTop animated:YES];
         
     } completion:^(BOOL finished)
     {
         
         //        CGRect tempRect = self.wallCollectionView.frame;
         //        tempRect.size.height -= 100;
         //        self.wallCollectionView.frame = tempRect;
         //
         //        CGPoint wallOffset = wallCollectionView.contentOffset;
         //        wallOffset.y += 100;
         //        wallCollectionView.contentOffset = wallOffset;
         
         
         
         for (NSIndexPath *indexPath in self.hideCells)
         {
             [collectionView cellForItemAtIndexPath:indexPath].contentView.alpha = 1.0f;
         }
         self.hideCells = @[];
         CGRect visibleRect = collectionView.frame;
         visibleRect.origin.y = collectionView.contentSize.height-visibleRect.size.height;
         
         //        NSLog(@"visibleRect = %@", NSStringFromCGRect(visibleRect));
         //        NSLog(@"contentOffset = %@", NSStringFromCGPoint(wallCollectionView.contentOffset));
         //        NSLog(@"contentSize = %@", NSStringFromCGSize(wallCollectionView.contentSize));
         //        NSLog(@"collview size = %@", NSStringFromCGSize(wallCollectionView.frame.size));
         
         if (collectionView.contentSize.height < collectionView.frame.size.height)
         {
//             NSLog(@"NO SCROLL!");
             return;
         }
         
        
     }];
}

-(void)insertToWall:(NSArray*)wQ inOrder:(NSArray*)paths
{
    for (NSInteger i = 0 ; i < wallQueue.count; i++)
    {
        NSIndexPath *indexPath = paths[i];
        NSInteger row = indexPath.row;
//        if (wall.count == 1)
//        {
//            row ++;
//        }
        MessageModel *model = wQ[i];
        
        [wall insertObject:model atIndex:row];
    }
}

-(void)observeValueForKeyPath:(NSString *)keyPath ofObject:(id)object change:(NSDictionary *)change context:(void *)context
{
    if ([object isKindOfClass:[FCUser class]])
    {
        FCUser *user = object;
        //gather all relevant models
        NSArray *modelsFromWall = [wall filteredArrayUsingPredicate:[NSPredicate predicateWithFormat:@"(SELF.ownerID == %@)", user.id]];
        
//        NSMutableArray *arrayOfIndexPaths = [[NSMutableArray alloc] init];
        for (MessageModel *model in modelsFromWall)
        {
            [model setUserData:user];
            NSInteger row = [wall indexOfObject:model];
            row = (row < wall.count) ? row : -1;
            
            //if row is valid
            if (row >= 0)
            {
//                [arrayOfIndexPaths addObject:[NSIndexPath indexPathForItem:row inSection:0]];
                MessageCell *messageCell = (MessageCell*)[collectionView cellForItemAtIndexPath:[NSIndexPath indexPathForItem:row inSection:0]];
                if (messageCell)
                {//live update!
                    [messageCell setMessageModel:model]; //will update cell
                }
            }

        } //now the models are updated, and arrayOfIndexPaths is an array of all index paths that must be updated!
        
        

        
    }
}

-(void)dealloc
{
    [self.wallRefQueryLimit removeObserverWithHandle:self.wallHandleInsert];
    [self.wallRefQueryLimit removeObserverWithHandle:self.wallHandleMove];
    
    for (FCUser *user in [usersDictionary allValues])
    {
        [user unregisterMetaListener];
        [user removeObserver:self forKeyPath:@"color"];
        [user removeObserver:self forKeyPath:@"icon"];
    }
}


@end
