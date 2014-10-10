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

#import "SWMessageHeaderView.h"



#import <Firebase/Firebase.h>

#import "SWImageLoader.h"

#define kMAX_NUMBER_OF_MESSAGES 100
#define kWallCollectionView_MAX_CELLS_INSERT 20
#define kWallCollectionView_CELL_INSERT_TIMEOUT 0.1f



@interface WallSource ()

@property (strong, nonatomic) NSMutableArray *sectionsOrder;
@property (strong, nonatomic) NSMutableArray *sections;

@property (copy, nonatomic) void (^handleMessageInsert)(FDataSnapshot *messageSnapshot, NSString *previous);
@property (strong, nonatomic) FQuery *historyQuery;
@property (assign, nonatomic) FirebaseHandle historyQueryHandle;

//@property (strong, nonatomic) NSMutableArray *wall; //what is actually displayed (models)
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

@property (strong, nonatomic) NSMutableDictionary *allMessagesEver;

@property (assign, nonatomic) BOOL didFinishLoadingWallAtFirst;
@property (strong, nonatomic) NSTimer *firstLoadTimer;

@property (assign, nonatomic) NSInteger count;

@end

@implementation WallSource

//@synthesize wall;
@synthesize layout;
@synthesize collectionView;
@synthesize url;
//@synthesize firstSnapshotFromWall;
@synthesize wallQueueInsertTimer;
@synthesize wallQueue;

//@synthesize userNameToModelsArray;
@synthesize wallNames;


@synthesize allMessagesEver;
@synthesize handleMessageInsert;

@synthesize sections;
@synthesize sectionsOrder;

-(id)initWithUrl:(NSString*)URL andStartAtDate:(double)startAtDate//collectionView:(UICollectionView*)cv andLayout:(UICollectionViewLayout*)lay
{
    if (self = [super init])
    {
        sectionsOrder = [[NSMutableArray alloc] init];
        sections = [[NSMutableArray alloc] init];
        url = URL;
        
//        wall = [[NSMutableArray alloc] init];
        wallQueue = [[NSMutableArray alloc] initWithCapacity:kWallCollectionView_MAX_CELLS_INSERT];
        wallNames = [[NSMutableArray alloc] init];
        //c:1238901
        allMessagesEver = [[NSMutableDictionary alloc] initWithCapacity:200];
        _startAtDate = startAtDate;
        
        __weak typeof(self) weakSelf = self;
        handleMessageInsert = ^(FDataSnapshot *messageSnapshot, NSString *previous)
        {
            NSLog(@"%d message '%@' name ",weakSelf.count, messageSnapshot.name);
            
            weakSelf.count++;
            
            if ([messageSnapshot.value isKindOfClass:[NSDictionary class]])
            {

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
                
                MessageModel *model = [MessageModel messageModelFromValue:messageSnapshot.value andPriority:[messageSnapshot.priority doubleValue]];
                if (!model)
                    return;

                model.name = messageSnapshot.name;
                [wallNames insertObject:model.name  atIndex:index];
                [allMessagesEver setObject:model forKey:model.name];
                model.isPending = YES;
                [self getPossibleParentAndPossibleChild:model.name withCompletion:^(MessageModel *possibleParent, MessageModel *possibleChild)
                {

                    NSLog(@"*******BEFORE");
                    int i = 0;
                    
                    for (Section *section in sectionsOrder)
                    {
                        NSLog(@"section[%d] = %@", i, [section toString]);
                        i++;
                    }
                    
                    if (possibleParent && [possibleParent.ownerID isEqualToString:model.ownerID])
                    {
                        NSAssert(possibleParent.section, @"possibleParent's section must not be nil");
                        model.section = possibleParent.section;
                        //where to put model in section?
                        NSInteger parentIndex = [wallNames indexOfObject:possibleParent.name];
                        NSInteger index = parentIndex - 1;
//                        NSAssert( index > 0, @"index must be strictly less than parentIndex");
                        
                        [model.section.messagesOrder insertObject:model atIndex:index];
                        
                    } else
                    {
                        Section *section = [[Section alloc] init];
                        [section.messagesOrder addObject:model];
                        model.section = section;
                        
                        [sectionsOrder insertObject:section atIndex:0];
                    }
                    
                    NSLog(@"*******AFTER");
                    i = 0;
                    for (Section *section in sectionsOrder)
                    {
                        NSLog(@"section[%d] = %@", i, [section toString]);
                        i++;
                    }
                    //visualize data.
                    
                }];
                
                //for future history fetches
                if (model.priority < _startAtDate)
                {
                    _startAtDate = model.priority;
                }
                
                
                
                //c:8912309123
                
                //block models that are already fetching
                [SWUserManager userForID:model.ownerID withCompletion:^(SWUser *user, BOOL synchronous)
                 {
#pragma mark Define specific fetch requests here, those which must be done before Model is acceptable to be displayed
                     [model setUserData:user];
                     //c:566549877
                     
                     void (^modelIsReadyForDisplayBlock)(void) = ^{
//                         model.isPending = NO;
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
    
    if (_startAtDate == 0)
    {
        _startAtDate = [[NSDate date] timeIntervalSince1970] * 1000;
    }
    
    NSLog(@"channel '%@' starting at '%f'", self.url, _startAtDate);
    
    //right now fetch all messages
    _wallRefQueryLimit = [wallRef queryStartingAtPriority:[NSNumber numberWithDouble:0]]; //_startAtDate]];  //[wallRef queryLimitedToNumberOfChildren:kMAX_NUMBER_OF_MESSAGES];
    
    NSLog(@"wallRefQueryLimit = %@", _wallRefQueryLimit);

    self.wallHandleInsert = [self.wallRefQueryLimit observeEventType:FEventTypeChildAdded andPreviousSiblingNameWithBlock:handleMessageInsert withCancelBlock:^(NSError *error)
    {
        NSLog(@"error on child added to wallSource = %@", error.localizedDescription);
    }];
    
    
}

-(void)getPossibleParentAndPossibleChild:(NSString*)name withCompletion:(void (^)(MessageModel *possibleParent, MessageModel *possibleChild))completion;
{
//    NSLog(@"searching for '%@'", name);
    
    NSInteger i = [wallNames indexOfObject:name];
    
    //now i is the index that "name" should be inserted into, and also "name" is no longer loading
    
    MessageModel *possibleParent = nil;
    if (i+1 < wallNames.count)
    {
        MessageModel *model = allMessagesEver[wallNames[i+1]];
        possibleParent = model;
    }
    
    MessageModel *possibleChild = nil;
    if (i-1 >= 0)
    {
        MessageModel *model = allMessagesEver[wallNames[i-1]];
        possibleChild = model;
    }
    
    completion(possibleParent, possibleChild);
}

-(NSInteger)numberOfSectionsInCollectionView:(UICollectionView *)collectionView
{
    NSInteger s = sections.count;
    return s;
}

-(NSInteger)collectionView:(UICollectionView *)collectionView numberOfItemsInSection:(NSInteger)s
{
    Section *sectionObj = sections[s];
    return sectionObj.messagesDisplay.count;
}

-(UICollectionViewCell*)collectionView:(UICollectionView *)cV cellForItemAtIndexPath:(NSIndexPath *)indexPath
{
    
    
    MessageModel *messageModel = [self wallObjectAtIndex:indexPath];  //[self wallObjectAtIndex:indexPath.row];
    
    [self.target performSelector:@selector(didViewMessageModel:) withObject:messageModel];
    
    MessageCell *messageCell = [MessageCell messageCellFromMessageModel:messageModel andCollectionView:cV forIndexPath:indexPath andWallSource:self];
    

    [self updateCell:messageCell withMoreDataFrom:messageModel];
    
    
    [self setProfileImageOnCell:messageCell withModel:messageModel];
    
    CGRect aTempRect = messageCell.frame;
    [messageCell setFrame:aTempRect];
    
    return messageCell;
}

//-(UIView*)

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
    MessageModel *model = [self wallObjectAtIndex:indexPath]; //wall[indexPath.row]
    CGFloat height = [MessageCell heightOfMessageCellForModel:model collectionView:(UICollectionView*)collectionView];
    return CGSizeMake(320, height);
}

//reverse
-(MessageModel*)wallObjectAtIndex:(NSIndexPath*)indexPath
{
    Section *section = (Section*) sections[indexPath.section];
    
    return section.messagesDisplay[indexPath.row];
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
    NSLog(@"are newest messages first?");
    /*
     NSArray *sortedArray = [unsortedArray sortedArrayUsingComparator:^NSComparisonResult(NSDictionary* a, NSDictionary* b) {
     NSInteger rowA = ((NSIndexPath*)a[@"indexPath"]).row;
     NSInteger rowB = ((NSIndexPath*)b[@"indexPath"]).row;
     return rowA > rowB;
     }];
     */

    [wallQueue sortUsingComparator:^NSComparisonResult(MessageModel* a, MessageModel* b) {
        return a.priority < b.priority;
    }];
    
    for (MessageModel *messageModel in wallQueue)
    {
        messageModel.isPending = NO;
        messageModel.section.isLoaded = YES;
    }
    

    __block NSMutableArray *paths = [[NSMutableArray alloc] initWithCapacity:wallQueue.count];
    __block NSMutableIndexSet *indexSet = [[NSMutableIndexSet alloc] init];
    
    
    void (^addToWallBlock)(void) = ^
    {
        for (MessageModel *messageModel in wallQueue)
        {
            
            NSInteger sectionDisplayIndex = 0;
            for (int index = sectionDisplayIndex; index < sectionsOrder.count; index++)
            {
                Section *section = sectionsOrder[index];
                if (messageModel.section == section)
                {
                    break;
                } else
                if (section.isLoaded)
                {
                    sectionDisplayIndex++;
                }
            }
            
            //ok now sectionDisplayIndex is the display index!
            if (![sections containsObject:messageModel.section])
            {
                [indexSet addIndex:sectionDisplayIndex];
                [sections insertObject:messageModel.section atIndex:sectionDisplayIndex];
            }
            
            //what row should this go into?
            NSInteger displayIndex = [messageModel.section displayIndexForMessageModel:messageModel];
            [messageModel.section.messagesDisplay insertObject:messageModel atIndex:displayIndex];
            
            NSIndexPath *newIndexPath = [NSIndexPath indexPathForItem:displayIndex inSection:sectionDisplayIndex];
            [paths addObject:newIndexPath];
        }
    };
    
    if (!collectionView || !sender)
    {
        addToWallBlock();
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
             addToWallBlock();
             [collectionView insertSections:indexSet];
             [collectionView insertItemsAtIndexPaths:paths];
             
             [wallQueue removeAllObjects];
             
         } completion:^(BOOL finished)
         {
             
             CGRect visibleRect = collectionView.frame;
             visibleRect.origin.y = collectionView.contentSize.height-visibleRect.size.height;
             
             if (collectionView.contentSize.height < collectionView.frame.size.height)
             {
                 return;
             }
             
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
        
//        [wall insertObject:model atIndex:row];
    }
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
    return;
    
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

-(UICollectionReusableView*)collectionView:(UICollectionView *)collectionView viewForSupplementaryElementOfKind:(NSString *)kind atIndexPath:(NSIndexPath *)indexPath
{
    SWMessageHeaderView *headerView = nil;
    
    Section *section = ((Section*)sections[indexPath.section]);
    MessageModel *parent = section.messagesOrder[0];
    
    NSString *ownerPhoto = parent.profileUrl;
    NSString *ownerName = [NSString stringWithFormat:@"%@ %d", parent.firstName, section.messagesOrder.count];
    
    headerView = (SWMessageHeaderView *)[collectionView dequeueReusableSupplementaryViewOfKind:kind withReuseIdentifier:@"SWMessageHeaderView" forIndexPath:indexPath];
    [headerView setPhoto:ownerPhoto andName:ownerName];
    
    return headerView;
}

@end
