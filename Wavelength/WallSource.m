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

#import "SWWebSiteCell.h"
#import "MessageWebSite.h"

#import "SWUserManager.h"
#import "SWUser.h"
#import "AppDelegate.h"



#import <Firebase/Firebase.h>

#import "SWImageLoader.h"

#define kMAX_NUMBER_OF_MESSAGES 100
#define kWallCollectionView_MAX_CELLS_INSERT 20
#define kWallCollectionView_CELL_INSERT_TIMEOUT 0.1f

@interface WallSource ()

@property (copy, nonatomic) void (^handleMessageInsert)(FDataSnapshot *messageSnapshot, NSString *previous);
@property (strong, nonatomic) FQuery *historyQuery;
@property (assign, nonatomic) FirebaseHandle historyQueryHandle;

@property (strong, nonatomic) NSMutableArray *wall; //what is actually displayed (models)
@property (strong, nonatomic) NSMutableArray *wallNames; //the order of all cells, some may still be loading

@property (weak, nonatomic) UICollectionViewLayout *layout;

@property (strong, nonatomic) NSTimer *wallQueueInsertTimer;
@property (assign, nonatomic) double startAtDate;
//firebase management
@property (assign, nonatomic) FirebaseHandle wallHandleInsert;
@property (assign, nonatomic) FirebaseHandle wallHandleMove;
@property (strong, nonatomic) FQuery *wallRefQueryLimit;
//@property (strong, nonatomic) FDataSnapshot *firstSnapshotFromWall;
@property (atomic, strong) NSMutableArray *wallQueue; //when inserting cells too fast

@property (nonatomic, strong) NSArray *hideCells;
//@property (strong, nonatomic) NSMutableDictionary *messageIdsToReplacingId; //messages are stored
//@property (strong, nonatomic) NSMutableDictionary *usersDictionary;
//@property (strong, nonatomic) NSMutableDictionary *userNameToModelsArray;

@property (strong, nonatomic) NSMutableArray *namesOfPendingMessages;

@property (assign, nonatomic) BOOL didFinishLoadingWallAtFirst;
@property (strong, nonatomic) NSTimer *firstLoadTimer;

@end

@implementation WallSource

@synthesize wall;
@synthesize layout;
@synthesize collectionView;
@synthesize url;
//@synthesize firstSnapshotFromWall;
@synthesize wallQueueInsertTimer;
@synthesize wallQueue;

//@synthesize userNameToModelsArray;
@synthesize wallNames;


@synthesize namesOfPendingMessages;
@synthesize handleMessageInsert;



-(id)initWithUrl:(NSString*)URL andStartAtDate:(double)startAtDate//collectionView:(UICollectionView*)cv andLayout:(UICollectionViewLayout*)lay
{
    if (self = [super init])
    {
        url = URL;
        
        wall = [[NSMutableArray alloc] init];
        wallQueue = [[NSMutableArray alloc] initWithCapacity:kWallCollectionView_MAX_CELLS_INSERT];
        wallNames = [[NSMutableArray alloc] init];
        //c:1238901
        namesOfPendingMessages = [[NSMutableArray alloc] init];
        _startAtDate = startAtDate;
        
        __weak typeof(self) weakSelf = self;
        handleMessageInsert = ^(FDataSnapshot *messageSnapshot, NSString *previous)
        {
            
            if ([messageSnapshot.value isKindOfClass:[NSDictionary class]])
            {
                //            if (!firstSnapshotFromWall)
                //                firstSnapshotFromWall = messageSnapshot;
                
                //lookup where to place this name..
                NSInteger index = weakSelf.wallNames.count;
                if (previous) //make block to observe child moved events on messages
                {
                    NSInteger integer = [weakSelf.wallNames indexOfObject:previous];
                    if (integer < weakSelf.wallNames.count)
                    {
                        index = integer;
                    } else {NSAssert(NO, @"You needed to found it!");}
                }
                //incase block is run by history fetch... history fetch overlaps, do not add messages that already exist
                if ([wallNames containsObject:messageSnapshot.name])
                {
                    NSLog(@"NO DOUBLE ADD!");
                    return;
                }
                [wallNames insertObject:messageSnapshot.name atIndex:index];
                
                
                [namesOfPendingMessages addObject:messageSnapshot.name];
                
                MessageModel *model = [MessageModel messageModelFromValue:messageSnapshot.value andPriority:[messageSnapshot.priority doubleValue]];
                model.name = messageSnapshot.name;
                
                //for future history fetches
                if (model.priority < _startAtDate)
                {
                    _startAtDate = model.priority;
                }
                
                if (!model)
                {//INVALID MODEL
                    return;
                }
                
                //c:8912309123
                
                //block models that are already fetching
                [SWUserManager userForID:model.ownerID withCompletion:^(SWUser *user, BOOL synchronous)
                 {
#pragma mark Define specific fetch requests here, those which must be done before Model is acceptable to be displayed
                     [model setUserData:user];
                     //c:566549877
                     
                     void (^modelIsReadyForDisplayBlock)(void) = ^{
                         [weakSelf addMessageToWallEventually:model];
                         [weakSelf.target performSelector:@selector(didLoadMessageModel:) withObject:model];
                     };
                     
                     
                      [model fetchRelevantDataWithCompletion:modelIsReadyForDisplayBlock];
                     
                 }];
                
                
                
            }
        };
        
        [self bindToWall];
    }
    return self;
} //x

-(void)bindToWall
{

    Firebase *wallRef = [[Firebase alloc] initWithUrl:url];
    
    _wallRefQueryLimit = [wallRef queryStartingAtPriority:[NSNumber numberWithDouble:_startAtDate]];  //[wallRef queryLimitedToNumberOfChildren:kMAX_NUMBER_OF_MESSAGES];

    self.wallHandleInsert = [self.wallRefQueryLimit observeEventType:FEventTypeChildAdded andPreviousSiblingNameWithBlock:handleMessageInsert withCancelBlock:^(NSError *error)
    {
        NSLog(@"error on child added to wallSource = %@", error.localizedDescription);
    }];
    
    
}

-(NSInteger)indexInWallToInsertNewModelIn:(NSString*)name
{
//    NSLog(@"searching for '%@'", name);
    
    NSInteger i = 0;
    for (NSString *otherName in wallNames)
    {
        if (otherName == name)
        {
//            NSLog(@"FOUND IT i = %d", i);
            break;
        } else
        if (![namesOfPendingMessages containsObject:otherName])
        {//then this cell is loaded
//            NSLog(@"'%@' != '%@'", name, otherName);
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
    
    
    MessageModel *messageModel = [self wallObjectAtIndex:indexPath.row];
    
    [self.target performSelector:@selector(didViewMessageModel:) withObject:messageModel];
    
    MessageCell *messageCell = [MessageCell messageCellFromMessageModel:messageModel andCollectionView:cV forIndexPath:indexPath andWallSource:self];
    

    [self updateCell:messageCell withMoreDataFrom:messageModel];
    
    
    [self setProfileImageOnCell:messageCell withModel:messageModel];
    
    CGRect aTempRect = messageCell.frame;
    [messageCell setFrame:aTempRect];
    
    return messageCell;
}

-(void)updateCell:(MessageCell*)cell withMoreDataFrom:(MessageModel*)model
{
    
    
    switch (model.type) {
        case MessageModelTypeImage:
        {
            
        }
        break;
        case MessageModelTypeWebSite:
        {
            SWWebSiteCell *webSiteCell = (SWWebSiteCell*)cell;
            MessageWebSite *webSiteModel = (MessageWebSite*)model;
            
            
                [self loadImageUrl:webSiteModel.favicon intoCell:webSiteCell fromModel:webSiteModel withCompletion:^(UIImage *img, MessageCell* cell, BOOL animated)
                 {
                     [((SWWebSiteCell*)cell) setFavIconImg:img animated:animated];
                 }];
            
            
                [self loadImageUrl:webSiteModel.image intoCell:webSiteCell fromModel:webSiteModel withCompletion:^(UIImage *img, MessageCell* cell, BOOL animated)
                {
                     [((SWWebSiteCell*)cell) setImg:img animated:animated];
                }];
            
            
            
        }
        break;
            
        default:
            break;
    }
}

-(void)loadImageUrl:(NSString*)imageUrl intoCell:(MessageCell*)originalCell fromModel:(MessageModel*)model withCompletion:(void(^)(UIImage *image, MessageCell *completionCell, BOOL animated))completion
{
    if (!imageUrl)
        return;
    
    SWImageLoader *imageLoader = ((AppDelegate*)[UIApplication sharedApplication].delegate).imageLoader;
    [imageLoader loadImage:imageUrl completionBlock:^(UIImage *image, BOOL synchronous)
     {
         if (synchronous)
         {
             completion(image, originalCell, !synchronous);
         } else
         {
             NSArray *currentlyVisibleCells = collectionView.visibleCells;
             MessageCell *fetchedCell = (SWWebSiteCell *)[[currentlyVisibleCells filteredArrayUsingPredicate:[NSPredicate predicateWithFormat:@"(SELF.model == %@)", model]] lastObject];
             if (fetchedCell)
             {
                 completion(image, fetchedCell, !synchronous);
             }
             
         }
     } progressBlock:^(float progress)
     {
         
     }];
    
}

-(void)setProfileImageOnCell:(MessageCell*)messageCell withModel:(MessageModel*)messageModel
{
    //if it needs it, try to set the profile image
    if ([messageCell respondsToSelector:@selector(setProfileImage:)])
    {
        SWImageLoader *imageLoader = ((AppDelegate*)[UIApplication sharedApplication].delegate).imageLoader;
        [imageLoader loadImage:messageModel.profileUrl completionBlock:^(UIImage *image, BOOL synchronous)
         {
             if (synchronous)
             {
                 [messageCell performSelector:@selector(setProfileImage:) withObject:image];
             } else
             {
                 NSArray *currentlyVisibleCells = collectionView.visibleCells;
                 MessageCell *fetchedCell = [[currentlyVisibleCells filteredArrayUsingPredicate:[NSPredicate predicateWithFormat:@"(SELF.model == %@)", messageModel]] lastObject];
                 if (fetchedCell)
                 {
                     [fetchedCell performSelector:@selector(setProfileImage:) withObject:image];
                 }
                 
             }
         } progressBlock:^(float progress)
         {
             
         }];
    }
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
    return wall[[self displayIndexForDataIndex:index]];//wall[(wall.count-1)-index];
}
-(NSInteger)displayIndexForDataIndex:(NSInteger)index
{
    NSInteger result = wall.count-1-index;
    
    return index;
}

-(void)addMessageToWallEventually:(MessageModel*)messageModel
{
    if ([wallQueue containsObject:messageModel])
    {
        return;
    }
    
    if (wallQueueInsertTimer)
    {
        [wallQueueInsertTimer invalidate];
        wallQueueInsertTimer = nil;
    }
    

    [wallQueue addObject:messageModel];
    if (wallQueue.count < kWallCollectionView_MAX_CELLS_INSERT)
    {
        
        wallQueueInsertTimer = [NSTimer timerWithTimeInterval:kWallCollectionView_CELL_INSERT_TIMEOUT target:self selector:@selector(insertMessagesToWallNow:) userInfo:nil repeats:NO];
        [[NSRunLoop mainRunLoop] addTimer:wallQueueInsertTimer forMode:NSRunLoopCommonModes];
    } else
    {//drain wallQueue now without animation

        [self insertMessagesToWallNow:nil];
//        [wall addObjectsFromArray:wallQueue];
//        [wallQueue removeAllObjects];
//        [collectionView reloadData];
//        
//        CGRect visibleRect = collectionView.frame;
//        visibleRect.origin.y = collectionView.contentSize.height-visibleRect.size.height;
//        [collectionView setContentOffset:CGPointMake(0, visibleRect.origin.y)];
        
        
    }
}//imp

-(void)insertMessagesToWallNow:(id)sender
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
        [paths addObject: [NSIndexPath indexPathForRow:[self displayIndexForDataIndex:row] inSection:0] ];
    }
    
    if (!collectionView || !sender)
    {
        [self insertToWall:wallQueue inOrder:paths];
        [wallQueue removeAllObjects];
        if (collectionView)
        {
            [collectionView reloadData];
        }
    }
    
    if (sender)
    {
        [collectionView performBatchUpdates:^
         {
             
    //         self.hideCells = [NSArray arrayWithArray:paths];
             
             [collectionView insertItemsAtIndexPaths:paths];
    //         NSLog(@"**before wall = %@", wall);
             [self insertToWall:wallQueue inOrder:paths];
    //         NSLog(@"wallQueue = %@", wallQueue);
    //         NSLog(@"wall = %@", wall);
             
             [wallQueue removeAllObjects];
             
         } completion:^(BOOL finished)
         {
             

             CGRect visibleRect = collectionView.frame;
             visibleRect.origin.y = collectionView.contentSize.height-visibleRect.size.height;
             
             if (collectionView.contentSize.height < collectionView.frame.size.height)
             {
                 return;
             }
             
    //         [UIView animateWithDuration:1 delay:0.0 usingSpringWithDamping:1 initialSpringVelocity:1 options:UIViewAnimationOptionCurveLinear animations:^
    //         {
    //            [collectionView setContentOffset:CGPointMake(0, visibleRect.origin.y)];
    //         } completion:^(BOOL finished){}];
            
         }];
    }
}

-(void)insertToWall:(NSArray*)wQ inOrder:(NSArray*)paths
{
    
    NSMutableArray *unsortedArray = [[NSMutableArray alloc] initWithCapacity:paths.count];
    for (int i = 0; i < paths.count; i++)
    {
        [unsortedArray addObject:@{@"model":wQ[i],
                           @"indexPath":paths[i]}];
    }
    
    //sort array on obj.indexPath.row
    
    NSArray *sortedArray = [unsortedArray sortedArrayUsingComparator:^NSComparisonResult(NSDictionary* a, NSDictionary* b) {
        NSInteger rowA = ((NSIndexPath*)a[@"indexPath"]).row;
        NSInteger rowB = ((NSIndexPath*)b[@"indexPath"]).row;
        return rowA > rowB;
    }];
    
    for (NSInteger i = 0 ; i < sortedArray.count; i++)
    {
        NSIndexPath *indexPath = sortedArray[i][@"indexPath"];
        NSInteger row = indexPath.row;

        MessageModel *model = sortedArray[i][@"model"];
        
        [wall insertObject:model atIndex:row];
    }
}

-(void)observeValueForKeyPath:(NSString *)keyPath ofObject:(id)object change:(NSDictionary *)change context:(void *)context
{
//    if ([object isKindOfClass:[FCUser class]])
//    {
//        FCUser *user = object;
//        //gather all relevant models
//        NSArray *modelsFromWall = [wall filteredArrayUsingPredicate:[NSPredicate predicateWithFormat:@"(SELF.ownerID == %@)", user.id]];
//        
////        NSMutableArray *arrayOfIndexPaths = [[NSMutableArray alloc] init];
//        for (MessageModel *model in modelsFromWall)
//        {
//            [model setUserData:user];
//            NSInteger row = [wall indexOfObject:model];
//            row = (row < wall.count) ? row : -1;
//            
//            //if row is valid
//            if (row >= 0)
//            {
////                [arrayOfIndexPaths addObject:[NSIndexPath indexPathForItem:row inSection:0]];
//                MessageCell *messageCell = (MessageCell*)[collectionView cellForItemAtIndexPath:[NSIndexPath indexPathForItem:row inSection:0]];
//                if (messageCell)
//                {//live update!
//                    [messageCell setMessageModel:model]; //will update cell
//                }
//            }
//
//        } //now the models are updated, and arrayOfIndexPaths is an array of all index paths that must be updated!
//        
//        
//
//        
//    }
}

-(void)dealloc
{
    [self.wallRefQueryLimit removeObserverWithHandle:self.wallHandleInsert];
    [self.wallRefQueryLimit removeObserverWithHandle:self.wallHandleMove];
}

-(void)scrollViewWillBeginDragging:(UIScrollView *)scrollView
{
    [self.target performSelector:@selector(scrollViewWillBeginDragging:) withObject:scrollView];
}

-(void)userTappedFlagOnMessageModel:(MessageModel*)messageModel
{
    [self.target performSelector:@selector(userTappedFlagOnMessageModel:) withObject:messageModel];
}

-(void)didLongPress:(UILongPressGestureRecognizer*)longPress
{
    [self.target performSelector:@selector(didLongPress:) withObject:longPress];
}


-(void)performHistoryQuery:(NSInteger)n
{
    if (_historyQuery)
    {
        //remove listener
        [_historyQuery removeObserverWithHandle:_historyQueryHandle];
    }
    
    _historyQuery = [[[[Firebase alloc] initWithUrl:url] queryLimitedToNumberOfChildren:100] queryEndingAtPriority:[NSNumber numberWithDouble:_startAtDate]];
    _historyQueryHandle = [_historyQuery observeEventType:FEventTypeChildAdded andPreviousSiblingNameWithBlock:handleMessageInsert];
}

-(void)fetchNMessages
{
    int number = kMAX_NUMBER_OF_MESSAGES - wallNames.count;
    if (number <= 0)
    {
        return;
    }
    [self performHistoryQuery:number ];
}

@end
