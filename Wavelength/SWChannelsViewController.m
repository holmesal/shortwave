//
//  SWChannelsViewController.m
//  Shortwave
//
//  Created by Ethan Sherr on 9/3/14.
//  Copyright (c) 2014 Ethan Sherr. All rights reserved.
//

#import "SWChannelsViewController.h"
#import "ObjcConstants.h"
#import "UIColor+HexString.h"
//#import "AppDelegate.h"

#import "SWChannelCell.h"
#import "SWMessagesViewController.h"
#import "SWNewChannel.h"
#import "AppDelegate.h"
#import "AutoCompleteChannelCell.h"
#import "WalkthroughView.h"

#define maxCharsInChannelName NSIntegerMax
#define kCHANNELADDTIMEOUT 0.5f

@interface SWChannelsViewController () <UICollectionViewDataSource, UICollectionViewDelegate, UIGestureRecognizerDelegate, UITextFieldDelegate>


@property (strong, nonatomic) WalkthroughView *firstWalkthrough;
@property (strong, nonatomic) WalkthroughView *secondWalkthrough;
@property (strong, nonatomic) WalkthroughView *thirdWalkthrough;


@property (strong, nonatomic) NSString *userAddedChannelNamedThisDuringWalkthrough;


@property (strong, nonatomic) NSTimer *insertChannelTimer;
@property (strong, nonatomic) NSMutableArray *queuedChannels;

@property (assign, nonatomic) BOOL navBarIsAnimating;
@property (assign, nonatomic ) BOOL isJoiningOrCreatingAChannel;

@property (weak, nonatomic) IBOutlet UIActivityIndicatorView *spinnerView;

@property (weak, nonatomic) IBOutlet NSLayoutConstraint *x1;
@property (weak, nonatomic) IBOutlet NSLayoutConstraint *x2;
//+14
@property (weak, nonatomic) IBOutlet UIView *addOrCreateContainer;
@property (weak, nonatomic) IBOutlet UILabel *addOrCreateLabel;
@property (weak, nonatomic) IBOutlet UILabel *addOrCreateChannelNameLabel;
@property (weak, nonatomic) IBOutlet UIImageView *addChannelHashImageView;
@property (weak, nonatomic) IBOutlet NSLayoutConstraint *addChannelButtonWidthConstraint;

@property (strong, nonatomic) SWChannelCell *selectedSWChannelCell;
@property (weak, nonatomic) IBOutlet UIView *addChannelAutoCompleteContainer;
@property (weak, nonatomic) IBOutlet NSLayoutConstraint *addChannelAutoCompleteContainerSpaceToBottom;

@property (weak, nonatomic) IBOutlet UITextField *addChannelTextField;
@property (weak, nonatomic) IBOutlet UICollectionView *channelsCollectionView;
@property (strong, nonatomic) SWChannelModel *selectedChannel;

@property (strong, nonatomic) NSMutableArray *channels;
@property (strong, nonatomic) NSMutableArray *channelNamesOrdering;
@property (strong, nonatomic) NSMutableDictionary *allChannelsEver;

//@property (strong, nonatomic) UIPanGestureRecognizer *myPanGesture;

@property (weak, nonatomic) IBOutlet UIImageView *navBarImageViewBG;
@property (weak, nonatomic) IBOutlet UIView *navBar;
@property (weak, nonatomic) IBOutlet UIImageView *bluebarFlat;

@property (strong, nonatomic) UIView *plusContainer;
@property (strong, nonatomic) UIView *verticalBeam;
@property (strong, nonatomic) UIView *horizontalBeam;

@property (strong, nonatomic) NSTimer *channelQueryTimer;
@property (strong, nonatomic) NSString *channelQueryTerm;
@property (strong, nonatomic) NSNumber *channelQueryExists; //nil meaning unknown



@property (weak, nonatomic) IBOutlet UICollectionView *autoCompleteCollectionView;
@property (strong, nonatomic) NSArray *autoCompleteResults;



@end


@implementation SWChannelsViewController
@synthesize insertChannelTimer;
@synthesize queuedChannels;

@synthesize navBarIsAnimating;
@synthesize channelsCollectionView;
@synthesize channels;
@synthesize channelNamesOrdering;
@synthesize allChannelsEver;


//-(void)setChannel:(SWChannelModel*)channel loadedState:(BOOL)loadedState
//{
//    [allChannelsEver setObject:[NSNumber numberWithBool:loadedState] forKey:channel.name];
//}
-(BOOL)isChannelLoaded:(NSString*)channelName
{
    SWChannelModel *channelModel = [allChannelsEver objectForKey:channelName];

    return channelModel.isLoaded;
}
-(NSInteger)whatActualIndexIsChannel:(NSString*)channel
{
    NSInteger index = 0;
    for (NSString* otherChannel in channelNamesOrdering)
    {
        if ([otherChannel isEqualToString:channel])
        {
            return index;
        } else
        if ([self isChannelLoaded:otherChannel])
        {
            index++;
        }
        
    }
    return -1;
}
-(NSInteger)whatPredictedIndexIs:(NSString*)channel
{
    if (!channel)
    {
        return channelNamesOrdering.count;
    }
    return [channelNamesOrdering indexOfObject:channel];
}

-(void)setPredictedIndex:(NSInteger)index forChannelName:(NSString*)channelName
{
    [channelNamesOrdering insertObject:channelName atIndex:index];
}


//-(UIStatusBarStyle)preferredStatusBarStyle
//{
//    return UIStatusBarStyleLightContent;
//}

//- (BOOL)gestureRecognizer:(UIGestureRecognizer *)gestureRecognizer shouldReceiveTouch:(UITouch *)touch
//{
//    NSLog(@"WTF!");
//    if([gestureRecognizer isEqual:_myPanGesture])
//    {
//        CGPoint point = [_myPanGesture translationInView:self.channelsCollectionView];
//        NSLog(@"point = %@", NSStringFromCGPoint(point));
//        if(point.x == 0)
//        {
//            
//            //adjust this condition if you want some leniency on the X axis
//            //The translation was on the X axis, i.e. right/left,
//            //so this gesture recognizer shouldn't do anything about it
//            
//            return NO;
//        }
//    }
//    return YES;
//}


-(void)viewDidLoad
{
    [super viewDidLoad];
    queuedChannels = [[NSMutableArray alloc] init];
    
    _addOrCreateContainer.alpha = 0.0f;
    _autoCompleteResults = @[];
    [_addChannelAutoCompleteContainer setAlpha:0.0f];
    [_addChannelTextField setHidden:YES];
    [_addChannelTextField setTintColor:[UIColor whiteColor]];
    [_addChannelTextField setDelegate:self];
    
    [_autoCompleteCollectionView setDataSource:self];
    [_autoCompleteCollectionView setDelegate:self];
    [_autoCompleteCollectionView setAlwaysBounceVertical:YES];
    [_autoCompleteCollectionView setBackgroundColor:[UIColor whiteColor]];
    
    
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(keyboardWillToggle:) name:UIKeyboardWillShowNotification object:nil];
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(keyboardWillToggle:) name:UIKeyboardWillHideNotification object:nil];
    
    
    CGFloat plusDim = 17.0f;
    CGFloat thickness = 4.0f;
    _plusContainer = [[UIView alloc] initWithFrame:CGRectMake((_navBar.frame.size.width - plusDim)*0.5f, (_navBar.frame.size.height - plusDim)*0.5f, plusDim, plusDim)];
    [_plusContainer setBackgroundColor:[UIColor clearColor]];
    
    _verticalBeam = [[UIView alloc] initWithFrame:CGRectMake(0, (plusDim-thickness)/2, plusDim, thickness)];
    _horizontalBeam = [[UIView alloc] initWithFrame:CGRectMake(0, (plusDim-thickness)/2, plusDim, thickness)];
    _verticalBeam.backgroundColor = [UIColor whiteColor];
    _horizontalBeam.backgroundColor = [UIColor whiteColor];
    
    [_verticalBeam setTransform:CGAffineTransformMakeRotation(M_PI/2)];
    [_plusContainer addSubview:_verticalBeam];
    [_plusContainer addSubview:_horizontalBeam];
    
    [_navBar addSubview:_plusContainer];
    
    
    
    channels = [[NSMutableArray alloc] init];
    channelNamesOrdering = [[NSMutableArray alloc] init];
    allChannelsEver = [[NSMutableDictionary alloc] init];
    
    NSString *versionString = [[NSBundle mainBundle] objectForInfoDictionaryKey:@"CFBundleShortVersionString"];
    UILabel *topLabel = [[UILabel alloc] initWithFrame:CGRectMake(0, -70, 320, 30)];
    topLabel.font = [UIFont fontWithName:@"Avenir-Book" size:14];
    topLabel.text = [NSString stringWithFormat:@"v%@", versionString];
    topLabel.textColor = [UIColor blackColor];
    topLabel.textAlignment = NSTextAlignmentCenter;
    [channelsCollectionView addSubview:topLabel];
    
    
    
    
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(joinChannelRemoteNotification:) name:Objc_kRemoteNotification_JoinChannel object:nil];
    
//    UIBarButtonItem *backButton = [[UIBarButtonItem alloc] initWithTitle:@"" style:UIBarButtonItemStylePlain target:self action:@selector(back)];
//    self.navigationItem.backBarButtonItem = backButton;
    
    channelsCollectionView.delegate = self;
    channelsCollectionView.dataSource = self;
    channelsCollectionView.alwaysBounceVertical = YES;
    
    
    [self setAutomaticallyAdjustsScrollViewInsets:NO];
//    [self.navigationController setNavigationBarHidden:NO animated:YES];
//    self.navigationController.navigationBar.translucent = NO;
//    self.navigationController.navigationBar.barTintColor = [UIColor colorWithHexString:Objc_kNiceColors[@"bar"] ];
//    self.navigationController.navigationBar.tintColor = [UIColor whiteColor];
    
//    UIFont *font = [UIFont fontWithName:@"Avenir-Black" size:17];
//    NSDictionary *titleDict = @{NSForegroundColorAttributeName : [UIColor whiteColor], NSFontAttributeName: font};
//    UIButton *addButtonButton = [[UIButton alloc] initWithFrame:CGRectMake(12, 0, 70-7, 48)];
//    [addButtonButton addTarget:self action:@selector(addBarButtonAction:) forControlEvents:UIControlEventTouchUpInside];
//    addButtonButton.titleLabel.font = font;
//    [addButtonButton setTitleColor:[UIColor whiteColor] forState:UIControlStateNormal];
//    [addButtonButton setTitle:@"Add" forState:UIControlStateNormal];
    
//    UIView *addButtonView = [[UIView alloc] initWithFrame:CGRectMake(0, 0, 70, 48)];
//    addButtonView.backgroundColor = [UIColor clearColor];
//    [addButtonView addSubview:addButtonButton];
    
//    UIView *whiteLine = [[UIView alloc] initWithFrame:CGRectMake(0, 0, 0.5f, 48)];
//    whiteLine.backgroundColor = [UIColor whiteColor];
//    [addButtonView addSubview:whiteLine];
    
//    UIBarButtonItem *addButton = [[UIBarButtonItem alloc] initWithCustomView:addButtonView];
//    [addButton setTitleTextAttributes:titleDict forState:UIControlStateNormal];
//    self.navigationItem.rightBarButtonItem = addButton;
    
//    self.navigationItem.hidesBackButton = YES;
    
    if (self.hasUserSeenWalkthrough)
    {
        [self bindToChannels];
    }
}
-(BOOL)hasUserSeenWalkthrough
{
    return [[NSUserDefaults standardUserDefaults] boolForKey:Objc_kNSUSERDEFAULTS_BOOLKEY_userHasSeenWalkthrough];
}

-(void)back
{
    [self.navigationController popViewControllerAnimated:YES];
}
-(void)addBarButtonAction:(id)sender
{
    [self performSegueWithIdentifier:@"Add" sender:self];
}

-(void)bindToChannels
{
    NSString *userID = [[NSUserDefaults standardUserDefaults] objectForKey:Objc_kNSUSERDEFAULTS_KEY_userId];
    NSString *url = [NSString stringWithFormat:@"%@users/%@/channels/", Objc_kROOT_FIREBASE, userID];
    
    Firebase *f = [[Firebase alloc] initWithUrl:url];
    
    __weak SWChannelsViewController *weakSelf = self;
    //ADD&INSERT
    [f observeEventType:FEventTypeChildAdded andPreviousSiblingNameWithBlock:^(FDataSnapshot *snap, NSString *replacingName)
    {
        if ([snap.value isKindOfClass:[NSDictionary class]])
        {
            NSString *name = snap.name;
            

            
            NSDictionary *dictionary = snap.value;
            
            if ([channelNamesOrdering containsObject:name])
            {
                NSLog(@"CONFUSION: channelNamesOrdering already contains %@", name);
                return;
            }
            
            

            SWChannelModel *channel = [[SWChannelModel alloc] initWithoutData];
            channel.name = name;
            
            [self setPredictedIndex:[self whatPredictedIndexIs:replacingName] forChannelName:name];
            [allChannelsEver setObject:channel forKey:name];
            
            Firebase *f2 = [[Firebase alloc] initWithUrl:[NSString stringWithFormat:@"%@channels/%@/meta", Objc_kROOT_FIREBASE, name]];
            [f2 observeSingleEventOfType:FEventTypeValue withBlock:^(FDataSnapshot *f2Snapshot)
            {
                if ([f2Snapshot.value isKindOfClass:[NSDictionary class]])
                {
                    NSDictionary *meta = f2Snapshot.value;
                    [channel doInitializationWithDictionary:dictionary andUrl:[NSString stringWithFormat:@"%@%@", url, snap.name] andChannelMeta:meta]; 
                    
                    
                    double priority = snap.priority == [NSNull null] ? 0 : [snap.priority doubleValue];
                    
                    channel.priority = priority;
                    
                    
                    //JAVA STOPPED HERE
                    channel.delegate = self; //updating channel activity indicator
                    
                    
                    //check if this already exists?
                    NSArray *result = [weakSelf.channels filteredArrayUsingPredicate:[NSPredicate predicateWithFormat:@"SELF.name == %@", channel.name]];
                    if (result.count != 0)
                    {
                        return;
                    }
                    
                    //what index? a reordering may have occured while iw as fetching f2's single value event
//                    NSInteger index = [self whatActualIndexIsChannel:name];
//                    [self setChannel:name loadedState:YES];
                    
                    

                    AppDelegate *appDelegate = ((AppDelegate*)[UIApplication sharedApplication].delegate);
                    NSString *channelFromRemoteNotification = appDelegate.channelFromRemoteNotification;
                    if (channelFromRemoteNotification && [channelFromRemoteNotification isEqualToString:channel.name])
                    {
                        [weakSelf openChannel:channel];
                        appDelegate.channelFromRemoteNotification = nil;
                    }
                    [weakSelf insertChannelEventually:channel];//:channelModel atIndex:index];
                    
                }
            }];
            
        }
    }];
    
    //MOVED
    [f observeEventType:FEventTypeChildMoved andPreviousSiblingNameWithBlock:^(FDataSnapshot *snap, NSString *replacingName)
    {
        NSString *name = snap.name;
        

        
        
        NSInteger oldDisplayIndex = [self whatActualIndexIsChannel:name];
        NSInteger oldFinalIndex = [self whatPredictedIndexIs:name];

        SWChannelModel *model = [allChannelsEver objectForKey:name];
        BOOL channelIsLoaded = model.isLoaded;
        
        if (channelIsLoaded)
        {
            model = [channels objectAtIndex:oldDisplayIndex];
            [channels removeObject:model];
        }
        [channelNamesOrdering removeObjectAtIndex:oldFinalIndex];
        
        NSInteger newFinalIndex = [self whatPredictedIndexIs:replacingName];
        [self setPredictedIndex:newFinalIndex forChannelName:name];
        NSInteger newDisplayIndex = [self whatActualIndexIsChannel:name];
        if (channelIsLoaded)
        {
            [channels insertObject:model atIndex:newDisplayIndex];
            [channelsCollectionView reloadData];
        }
        
        double priority = snap.priority == [NSNull null] ? 0 : [snap.priority doubleValue];
        model.priority = priority;
        
        
        
    }];
    
    //REMOVE
    [f observeEventType:FEventTypeChildRemoved withBlock:^(FDataSnapshot *snapshot)
    {
        NSString *name = snapshot.name;
        NSArray *names = [self.channels filteredArrayUsingPredicate:[NSPredicate predicateWithFormat:@"SELF.name == %@", name]];
        if (names.count > 0)
        {
            SWChannelModel *channelModel = names[0];
            NSInteger removeIndex = [self.channels indexOfObject:channelModel];
            
            
            [weakSelf.channelsCollectionView performBatchUpdates:^
            {
                [weakSelf.channels removeObjectAtIndex:removeIndex];
                [weakSelf.channelNamesOrdering removeObjectAtIndex:[self whatPredictedIndexIs:name]];
//                [weakSelf.channelLoadedState removeObjectForKey:name];
                [weakSelf.allChannelsEver removeObjectForKey:name];
                [weakSelf.channelsCollectionView deleteSections:[NSIndexSet indexSetWithIndex:removeIndex]];
            } completion:^(BOOL finished){
                if (weakSelf.thirdWalkthrough)
                {
                    [weakSelf endTutorial];
                }
            }];
            
            
        }
    }];
    
}

-(void)openChannel:(SWChannelModel*)channel
{
    self.selectedChannel = channel;
    UIBarButtonItem *barBtnItem = [[UIBarButtonItem alloc]initWithTitle:@"" style:UIBarButtonItemStyleBordered target:self action:@selector(pop)];
//    [barBtnItem setTintColor:[UIColor colorWithHexString:@"464C58"]];
    self.navigationItem.backBarButtonItem = barBtnItem;
    
    
    self.navigationController.navigationBar.tintColor = [UIColor colorWithHexString:@"464C58"];

    [self performSegueWithIdentifier:@"Messages" sender:self];
}
//-(void)insertChannel:(SWChannelModel*)channel atIndex:(NSInteger)i
//{
//    __weak SWChannelsViewController *weakSelf = self;
//    [channelsCollectionView performBatchUpdates:^
//    {
//        [weakSelf.channels insertObject:channel atIndex:i];
//        [weakSelf.channelsCollectionView insertSections:[NSIndexSet indexSetWithIndex:i]];
//    } completion:^(BOOL finished){}];
//}
-(void)insertChannelEventually:(SWChannelModel*)channel
{
    if (insertChannelTimer)
    {
        [insertChannelTimer invalidate];
        insertChannelTimer = nil;
    }
    
    [queuedChannels addObject:channel];
    insertChannelTimer = [NSTimer timerWithTimeInterval:kCHANNELADDTIMEOUT target:self selector:@selector(insertChannelNow) userInfo:nil repeats:NO];
    [[NSRunLoop mainRunLoop] addTimer:insertChannelTimer forMode:NSDefaultRunLoopMode];
    
}

-(void)insertChannelNow
{
    NSLog(@"*****insertChannelNow**** %@", _userAddedChannelNamedThisDuringWalkthrough);
    [queuedChannels sortUsingComparator:^(SWChannelModel *a, SWChannelModel *b)
    {
        if (a.priority == b.priority)
        {
            int aIndx = [channelNamesOrdering indexOfObject:a.name];
            int bIndx = [channelNamesOrdering indexOfObject:b.name];
            
            return aIndx > bIndx;
        }
        return a.priority < b.priority;
    }];
    
    NSLog(@"**printing channelNamesOrdering");
    int i = 0;
    for (NSString *name in channelNamesOrdering)
    {
        NSLog(@"[%d] = %@", i, name);
        i++;
    }
    

    
    __weak SWChannelsViewController *weakSelf = self;
    [channelsCollectionView performBatchUpdates:^
    {
        NSMutableIndexSet *indexSet = [[NSMutableIndexSet alloc] init];
        NSMutableArray *removeObjects = [[NSMutableArray alloc] initWithCapacity:queuedChannels.count];
        for (SWChannelModel *channel in queuedChannels)
        {
            NSString *name = channel.name;
            BOOL canAddChannelNow = NO;
            if (![self hasUserSeenWalkthrough])
            {
                if ([name isEqualToString:_userAddedChannelNamedThisDuringWalkthrough])
                {
                    canAddChannelNow = YES;
                    [removeObjects addObject:channel];
                } else
                {
                    canAddChannelNow = NO;
                    
                }
            } else
            {
                canAddChannelNow = YES;
                [removeObjects addObject:channel];
            }
            
            if (canAddChannelNow)
            {
                channel.isLoaded = YES;
                NSInteger index = [self whatActualIndexIsChannel:name];
                [indexSet addIndex:index];
                SWChannelModel *model = [allChannelsEver objectForKey:name];
                NSLog(@"inserting channel '%@' at index \t\t'%d' priority = \t\t'%f' ", name, index, model.priority);
                [self.channels insertObject:channel atIndex:index];
            }
        }
        
        [weakSelf.channelsCollectionView insertSections:indexSet];
        
        [queuedChannels removeObjectsInArray:removeObjects];
        
        
    } completion:^(BOOL finished){}];

    
    
}

#pragma mark UICollectionViewDelegate /DataSource methods
-(NSInteger)numberOfSectionsInCollectionView:(UICollectionView *)collectionView
{
    if (collectionView == channelsCollectionView)
    {
        return channels.count;
    } else
    if (collectionView == _autoCompleteCollectionView)
    {
        return 1;
    }
    return -1;
}
-(NSInteger)collectionView:(UICollectionView *)collectionView numberOfItemsInSection:(NSInteger)section
{
    if (collectionView == channelsCollectionView)
    {
        return 1;
    } else
    if (collectionView == _autoCompleteCollectionView)
    {
        return _autoCompleteResults.count;
    }
    return -1;
}
-(UICollectionViewCell*)collectionView:(UICollectionView *)collectionView cellForItemAtIndexPath:(NSIndexPath *)indexPath
{
    if (collectionView == channelsCollectionView)
    {
        SWChannelCell *channelCell = [collectionView dequeueReusableCellWithReuseIdentifier:@"SWChannelCell" forIndexPath:indexPath];
        if (!channelCell.panGesture.delegate)
        {
            channelCell.panGesture.delegate = self;
            
        }
        channelCell.contentView.frame = channelCell.bounds;
        channelCell.contentView.clipsToBounds = YES;
        channelCell.channelModel = channels[indexPath.section];
        return channelCell;
    } else
    if (collectionView == _autoCompleteCollectionView)
    {
        AutoCompleteChannelCell *channelCell = [collectionView dequeueReusableCellWithReuseIdentifier:@"AutoCompleteChannelCell" forIndexPath:indexPath];
        
        
        [channelCell setData:(QueryResult*)_autoCompleteResults[indexPath.row]];
        
        return channelCell;
    }
    return nil;
}

-(void)viewDidAppear:(BOOL)animated
{
    [super viewDidAppear:animated];


    if (_selectedSWChannelCell)
    {
        [_selectedSWChannelCell customSetSelected:NO animated:YES];
        _selectedSWChannelCell = nil;
    }
    
    if (! self.hasUserSeenWalkthrough )
    {
        [self createFirstWalkThrough];
    }

}



-(void)viewDidDisappear:(BOOL)animated
{
    [super viewDidDisappear:animated];
    
    NSArray *selectedPaths = channelsCollectionView.indexPathsForSelectedItems;
    
    for (NSIndexPath *indexPath in selectedPaths)
    {
        [channelsCollectionView deselectItemAtIndexPath:indexPath animated:NO];
    }
}

-(void)collectionView:(UICollectionView *)collectionView didSelectItemAtIndexPath:(NSIndexPath *)indexPath
{
    if (collectionView == channelsCollectionView)
    {
        SWChannelCell *channelCell = (SWChannelCell*)[collectionView cellForItemAtIndexPath:indexPath];
        _selectedSWChannelCell = channelCell;
        [channelCell customSetSelected:YES animated:NO];
        [self endTutorial];
        [self openChannel:channels[indexPath.section]];
    } else
    if (collectionView == _autoCompleteCollectionView && !_isJoiningOrCreatingAChannel)
    {
        _isJoiningOrCreatingAChannel = YES;
        
        AutoCompleteChannelCell *channelCell = (AutoCompleteChannelCell*)[collectionView cellForItemAtIndexPath:indexPath];
        [channelCell customSetSelected:YES animated:NO];
        QueryResult *queryResult = [channelCell data];
        

        [self removeAllAutoCompletesExcept:queryResult.text];
        
        __weak SWChannelsViewController *weakSelf = self;
        [SWChannelModel joinChannel:queryResult.text withCompletion:^(NSError *error)
        {
            NSLog(@"done joining channel queryResult.text = %@, error = %@", queryResult.text, error.localizedDescription);
            [weakSelf setNavBarHighlighted:NO];
            if (![self hasUserSeenWalkthrough])
            {
                _userAddedChannelNamedThisDuringWalkthrough = _channelQueryTerm;
                [self createThirdWalkthroughWithChannelName:_channelQueryTerm];
            }
        }];
    }
}

-(CGSize)collectionView:(UICollectionView *)collectionView layout:(UICollectionViewLayout *)collectionViewLayout sizeForItemAtIndexPath:(NSIndexPath *)indexPath
{
    if (collectionView == channelsCollectionView)
    {
        SWChannelModel *channel = channels[indexPath.section];
        return CGSizeMake(320, [SWChannelCell cellHeightGivenChannel:channel]);
    } else
    if (collectionView == _autoCompleteCollectionView)
    {
        return CGSizeMake(320, 55);
    }
    return CGSizeMake(320, 30);
}
-(UIEdgeInsets)collectionView:(UICollectionView *)collectionView layout:(UICollectionViewLayout *)collectionViewLayout insetForSectionAtIndex:(NSInteger)section
{
    return UIEdgeInsetsZero;
}
-(CGFloat)collectionView:(UICollectionView *)collectionView layout:(UICollectionViewLayout *)collectionViewLayout minimumInteritemSpacingForSectionAtIndex:(NSInteger)section
{
    return 0.0f;
}
-(CGFloat)collectionView:(UICollectionView *)collectionView layout:(UICollectionViewLayout *)collectionViewLayout minimumLineSpacingForSectionAtIndex:(NSInteger)section
{
    return 0.0f;
}

//-(CGPoint)targetContentOffsetForProposedContentOffset:(CGPoint)contentOffset
//{
//    CGSize collectionViewContentSize = self.view.bounds.size;
//    if (collectionViewContentSize.height <= self.channelsCollectionView.bounds.size.height)
//    {
//        return CGPointMake(0, contentOffset.y);
//    }
//    return contentOffset;
//}

-(void)dealloc
{
    [[NSNotificationCenter defaultCenter] removeObserver:self];
}
-(void)prepareForSegue:(UIStoryboardSegue *)segue sender:(id)sender
{
    if ([segue.destinationViewController isKindOfClass:[SWMessagesViewController class]])
    {
        SWMessagesViewController *messagesViewController = segue.destinationViewController;
        messagesViewController.channelModel = self.selectedChannel;
    } else
    if ([segue.destinationViewController isKindOfClass:[SWNewChannel class]])
    {
        SWNewChannel *addViewController = segue.destinationViewController;
        addViewController.channelViewController = self;
    }
}

-(void)scrollViewDidScroll:(UIScrollView *)scrollView
{
//    for (SWChannelCell *channelCell in channelsCollectionView.visibleCells)
//    {
//        [channelCell hideLeaveChannelConfirmUI];
//    }
}

-(void)joinChannelRemoteNotification:(NSNotification*)notification
{
    NSLog(@"joinChannelRemoteNotification to be handled by SWChannelsViewController");
    
    AppDelegate *appDelegate = ((AppDelegate*)[UIApplication sharedApplication].delegate);
    NSString *channelName = appDelegate.channelFromRemoteNotification;
    if (channelName)
    {
        NSArray *channelsWithSameName = [channels filteredArrayUsingPredicate:[NSPredicate predicateWithFormat:@"SELF.name == %@", channelName] ];
        if (channelsWithSameName.count > 0)
        {
            [self openChannel:channelsWithSameName.lastObject];
            appDelegate.channelFromRemoteNotification = nil;
        }
    }
    
}

#pragma ChannelModel callbacks
-(void)channel:(SWChannelModel*)channel hasNewActivity:(BOOL)activity
{
    SWChannelCell *channelCell = nil;
    
    NSInteger index = [channels indexOfObject:channel];
    
    if (index != NSNotFound)
    {
        channelCell = (SWChannelCell *)[channelsCollectionView cellForItemAtIndexPath:[NSIndexPath indexPathForItem:0 inSection:index]];
    }
    
    if (channelCell)
    {
        [channelCell setIsSynchronized:!activity];
    }
}

-(void) channel:(SWChannelModel*)channel isReorderingWithMessage:(MessageModel*)lastMessage
{
//    NSLog(@"channel %@ reorderingWithMessage %f", channel.name, lastMessage.priority);
    [self.channels sortUsingComparator:^(SWChannelModel* channel1, SWChannelModel* channel2)
    {
        
        NSNumber *priority1 = [NSNumber numberWithDouble:channel1.lastMessage.priority];
        NSNumber *priority2 = [NSNumber numberWithDouble:channel2.lastMessage.priority];
        
        return [priority2 compare:priority1];
        
    }];
    
    [self.channelsCollectionView reloadData];
    
    
}

#pragma mark Public Functions

-(void)openChannelForChannelName:(NSString*)channelName;
{
    NSArray *filteredChannels = [channels filteredArrayUsingPredicate:[NSPredicate predicateWithFormat:@"SELF.name == %@", channelName]];
    if (filteredChannels.count)
    {
        [self openChannel:filteredChannels.lastObject];
    }
}

-(BOOL)gestureRecognizer:(UIGestureRecognizer *)gestureRecognizer shouldRecognizeSimultaneouslyWithGestureRecognizer:(UIGestureRecognizer *)otherGestureRecognizer
{
    return YES;
}

-(BOOL)gestureRecognizerShouldBegin:(UIGestureRecognizer *)gestureRecognizer
{
    if ([gestureRecognizer isKindOfClass:[UIPanGestureRecognizer class]])
    {
        UIPanGestureRecognizer *pan = (UIPanGestureRecognizer*)gestureRecognizer;
        CGPoint translation = [pan translationInView:self.view];
        if (fabs(translation.x) == 0 || (fabsf(translation.x) < fabsf(translation.y)) )
        {
            return NO;
        }
    }
    return YES;
}

- (IBAction)touchUpNavBar:(id)sender
{
    if (!_navBarImageViewBG.highlighted)
    {
        [self setNavBarHighlighted:!_navBarImageViewBG.highlighted];
    }
}

-(void)setNavBarHighlighted:(BOOL)highlighted
{
    
    if (_firstWalkthrough)
    {
        [self animateTheDisappearanceOfWalkthroughView:_firstWalkthrough delay:0.0f completionBlock:^
        {
            [_firstWalkthrough removeFromSuperview];
            _firstWalkthrough = nil;
            
            [self createSecondWalkthrough];
        }];
    }
    
    if (_thirdWalkthrough)
    {
        [self endTutorial];
    }
    
    [_addOrCreateContainer setBackgroundColor:[UIColor whiteColor]];
    _isJoiningOrCreatingAChannel = NO;
    if (navBarIsAnimating)
    {
        return;
    }
    navBarIsAnimating = YES;
    _navBarImageViewBG.highlighted = highlighted;
    if (!highlighted)
    {
        [_addChannelTextField resignFirstResponder];
//        _plusContainer.alpha = 0.0f;
    }
    [_plusContainer setHidden:NO];
    [UIView animateWithDuration:0.4f delay:0.0f options:UIViewAnimationOptionCurveEaseInOut animations:^
    {
        [_horizontalBeam setTransform: highlighted ?
         CGAffineTransformMakeRotation(M_PI/2) : CGAffineTransformMakeRotation(0)];
    
        [_addChannelAutoCompleteContainer setAlpha:highlighted ? 1.0f : 0.0f];
        
        if (!highlighted)
        {
            [_addChannelTextField setTransform:CGAffineTransformMakeScale(0.1, 1.0)];
             _plusContainer.alpha = 1.0f;
        }
        
        
    } completion:^(BOOL finished)
    {
        if (highlighted)
        {
            [_plusContainer setHidden:YES];
            [_addChannelTextField setHidden:NO];
            [_addChannelTextField becomeFirstResponder];
        }
        
        if (!highlighted)
        {
            _spinnerView.alpha = 0.0f;
            [_addChannelTextField setTransform:CGAffineTransformIdentity];
            [_addChannelTextField setHidden:YES];
            [_addChannelTextField setText:@""];
            _autoCompleteResults = @[];
            _addOrCreateContainer.alpha = 0.0f;
            [_autoCompleteCollectionView reloadData];
        }
        navBarIsAnimating = NO;
    }];

}

-(void)keyboardWillToggle:(NSNotification*)notification
{
    NSDictionary *userInfo = notification.userInfo;
    
    NSTimeInterval duration;
    UIViewAnimationCurve animationCurve;
    CGRect startFrame;
    CGRect endFrame;
    
    [[userInfo objectForKey:UIKeyboardAnimationDurationUserInfoKey] getValue:&duration];
    [[userInfo objectForKey:UIKeyboardAnimationCurveUserInfoKey]    getValue:&animationCurve];
    [[userInfo objectForKey:UIKeyboardFrameBeginUserInfoKey]        getValue:&startFrame];
    [[userInfo objectForKey:UIKeyboardFrameEndUserInfoKey]          getValue:&endFrame];
    
    NSInteger signCorrection = -1;
    
    CGFloat dy = startFrame.origin.y - endFrame.origin.y;
    CGFloat constraintHeight = dy < 0 ? 0 : dy;
    
    if (startFrame.origin.y < 0 || startFrame.origin.x < 0 || endFrame.origin.y < 0 || endFrame.origin.x < 0)
    {
        signCorrection = 1;
    }
    
    
    if (constraintHeight > 300)
    {
        constraintHeight = 216;
        self.addChannelAutoCompleteContainerSpaceToBottom.constant = constraintHeight;
    } else
    {
        [UIView animateWithDuration:0.3f delay:0.0f options:(UIViewAnimationOptionBeginFromCurrentState | animationCurve << 16) animations:^
         {
             self.addChannelAutoCompleteContainerSpaceToBottom.constant = constraintHeight;
             [self.addChannelAutoCompleteContainer.superview layoutIfNeeded];
         } completion:^(BOOL finished){}];
    }
    
}

//UITextField delegate methods
-(BOOL)textField:(UITextField *)textField shouldChangeCharactersInRange:(NSRange)range replacementString:(NSString *)string
{
    if (_isJoiningOrCreatingAChannel)
    {
        return NO;
    }
    NSString *result = [[textField.text stringByReplacingCharactersInRange:range withString:string] lowercaseString];
    
    NSArray *illegalCharacters = @[@"$", @"[", @"]", @"/", @".", @"#"];
    for (NSString *c in illegalCharacters)
    {
        result = [result stringByReplacingOccurrencesOfString:c withString:@""];
    }
    result = [result stringByReplacingOccurrencesOfString:@" " withString:@"-"];
//    self.hashTagLabel.highlighted = result.length != 0;
    
    if (result.length > maxCharsInChannelName)
    {
        return NO;
    }
    
    if (_channelQueryTimer)
    {
        [_channelQueryTimer invalidate];
        _channelQueryTimer = nil;
    }
    
    _channelQueryTimer = [NSTimer timerWithTimeInterval:0.85f target:self selector:@selector(queryTimerEvent:) userInfo:nil repeats:NO];
    [[NSRunLoop mainRunLoop] addTimer:_channelQueryTimer forMode:NSDefaultRunLoopMode];
    textField.text = result;
    
    _channelQueryTerm = result;
    _channelQueryExists = nil; //unknown
    
    if (_addOrCreateContainer.alpha == 1.0f)
    {
        [UIView animateWithDuration:0.3f animations:^
        {
            _addOrCreateContainer.alpha = 0.5f;
        }];
    }
    
    return NO;
    
}

-(void)queryTimerEvent:(NSTimer*)tmrw
{
    [_channelQueryTimer invalidate];
    _channelQueryTimer = nil;
    
    
    __weak SWChannelsViewController *weakSelf = self;
    [SWChannelModel query:_channelQueryTerm andCompletionHandler:^(QueryChannelRequest *request, NSString *originalQuery, BOOL hasExactMatch)
     {
         NSLog(@"done query '%@' with requests: '%d'", originalQuery, request.results.count);
         if ([originalQuery isEqualToString:weakSelf.channelQueryTerm])
         {
             if (_secondWalkthrough)
             {
                 [self animateTheDisappearanceOfWalkthroughView:_secondWalkthrough delay:0.0f completionBlock:^{
                     [_secondWalkthrough removeFromSuperview];
                     _secondWalkthrough = nil;
                 }];
             }
             weakSelf.channelQueryExists = [NSNumber numberWithBool:hasExactMatch];
             weakSelf.autoCompleteResults = request.results;
             [weakSelf.autoCompleteCollectionView reloadData];
             
             [weakSelf setAddOrCreateButton:hasExactMatch ? @"Join" : @"Create" andChannel:originalQuery];
         }
     }];
    
}

-(void)setAddOrCreateButton:(NSString*)addOrCreate andChannel:(NSString*)channelName
{
    if (_addOrCreateContainer.alpha != 1.0f)
    {
        [UIView animateWithDuration:0.3f animations:^{
            _addOrCreateContainer.alpha = 1.0f;
        }];
    }
    _addOrCreateLabel.text = addOrCreate;
    _addOrCreateChannelNameLabel.text = channelName;
    
    CGSize s1 = [_addOrCreateLabel sizeThatFits:CGSizeMake(300, 50)];
    CGSize s2 = [_addOrCreateChannelNameLabel sizeThatFits:CGSizeMake(300, 50)];
    
    CGFloat width = s1.width + s2.width + 14 + _x1.constant + _x2.constant;
    
    _addChannelButtonWidthConstraint.constant = width;
}

- (IBAction)addOrCreateChannel:(id)sender
{
    if (_channelQueryExists && !_isJoiningOrCreatingAChannel)
    {
        [_addOrCreateContainer setBackgroundColor:[UIColor colorWithWhite:230/255.0f alpha:1.0f]];
        _isJoiningOrCreatingAChannel = YES;
        __weak SWChannelsViewController *weakSelf = self;
        

        
        [self removeAllAutoCompletesExcept:_channelQueryTerm];
        
        if ([_channelQueryExists boolValue])
        {
            [SWChannelModel joinChannel:_channelQueryTerm withCompletion:^(NSError *error)
            {
                [weakSelf setNavBarHighlighted:NO];
                if (![self hasUserSeenWalkthrough])
                {
                    _userAddedChannelNamedThisDuringWalkthrough = _channelQueryTerm;
                    [self createThirdWalkthroughWithChannelName:_channelQueryTerm];
                }
            }];
        } else
        {
            [SWChannelModel createChannel:_channelQueryTerm withCompletion:^(NSError *error)
            {
                [weakSelf setNavBarHighlighted:NO];
                if (![self hasUserSeenWalkthrough])
                {
                    _userAddedChannelNamedThisDuringWalkthrough = _channelQueryTerm;
                    [self createThirdWalkthroughWithChannelName:_channelQueryTerm];
                }
            }];
        }
    }
}

-(void)removeAllAutoCompletesExcept:(NSString*)term
{
    NSArray *results = [_autoCompleteResults filteredArrayUsingPredicate:[NSPredicate predicateWithFormat:@"SELF.text == %@", term]];
    QueryResult *result = [results lastObject];
    
    NSInteger index = [_autoCompleteResults indexOfObject:result];
    
    NSMutableArray *removeIndexPaths = [[NSMutableArray alloc] init];
    for (int i = 0; i < _autoCompleteResults.count ; i++)
    {
        if (i != index)
        {
            [removeIndexPaths addObject:[NSIndexPath indexPathForItem:i inSection:0]];
        }
    }
    
    if (index == NSNotFound)
    {
        _autoCompleteResults = @[ ];
    } else
    {
        _autoCompleteResults = @[ result ];
    }
    [_autoCompleteCollectionView deleteItemsAtIndexPaths:removeIndexPaths];
    
    [UIView animateWithDuration:0.3f animations:^{
        _spinnerView.alpha = 1.0f;
    }];
}

-(BOOL)textFieldShouldReturn:(UITextField *)textField
{
    [self addOrCreateChannel:nil];
    return NO;
}

//generate walktrhoughs
-(void)createFirstWalkThrough
{
    CGSize viewSize = CGSizeMake(584*0.5f, 140*0.5f);
    UILabel *pressThePlusLabel = [[UILabel alloc] initWithFrame:CGRectMake( 0, 0, viewSize.width, viewSize.height)];
    [pressThePlusLabel setTextAlignment:NSTextAlignmentCenter];
    [pressThePlusLabel setFont:[UIFont fontWithName:@"Avenir-Book" size:15]];
    [pressThePlusLabel setTextColor:[UIColor colorWithHexString:@"464C58"]];
    [pressThePlusLabel setText:@"Press the plus button to get started."];
    
    
    _firstWalkthrough = [[WalkthroughView alloc] initWithFrame:CGRectMake( (self.view.bounds.size.width - viewSize.width)*0.5f, 308*0.5f, viewSize.width, viewSize.height)];
    [_firstWalkthrough addSubview:pressThePlusLabel];

    [self.view addSubview:_firstWalkthrough];
    [self addParalaxShiftTiltToView:_firstWalkthrough];
    [self animateTheAppearanceOfWalkthroughView:_firstWalkthrough delay:0.0f completionBlock:^{}];
}

-(void)animateTheAppearanceOfWalkthroughView:(UIView*)walkthroughView delay:(CGFloat)delay completionBlock:(void(^)(void))completionBlock
{
    walkthroughView.alpha = 0.0f;
    walkthroughView.transform = CGAffineTransformConcat( CGAffineTransformMakeScale(0.7f, 0.7f), CGAffineTransformMakeTranslation(0, 40) );
    
    [UIView animateWithDuration:1.3f delay:delay usingSpringWithDamping:1.2 initialSpringVelocity:1.2 options:UIViewAnimationOptionCurveEaseIn animations:^
    {
        walkthroughView.alpha = 1.0f;
        walkthroughView.transform = CGAffineTransformMakeTranslation(0, 0);
    } completion:^(BOOL finished)
    {
        if (completionBlock)
        {
            completionBlock();
        }
    }];
}

-(void)createSecondWalkthrough
{
    CGSize size = CGSizeMake(555*0.5f, 291*0.5f);
 
    
    UILabel *thisIsHow = [[UILabel alloc] initWithFrame:CGRectMake( 0, 25, size.width, 20.5f)];
    [thisIsHow setTextAlignment:NSTextAlignmentCenter];
    [thisIsHow setFont:[UIFont fontWithName:@"Avenir-Book" size:15]];
    [thisIsHow setTextColor:[UIColor colorWithHexString:@"464C58"]];
    [thisIsHow setText:@"This is how you add hashtags."];
    
    
    UILabel *tryAddingTheHashtag = [[UILabel alloc] initWithFrame:CGRectMake( 0, thisIsHow.frame.size.height + thisIsHow.frame.origin.y + 4.5f, size.width, 20.5f)];
    [tryAddingTheHashtag setTextAlignment:NSTextAlignmentCenter];
    [tryAddingTheHashtag setFont:[UIFont fontWithName:@"Avenir-Book" size:15]];
    [tryAddingTheHashtag setTextColor:[UIColor colorWithHexString:@"464C58"]];
    [tryAddingTheHashtag setText:@"Try adding the hashtag:"];
    
    
    UIImageView *imageView = [[UIImageView alloc] initWithFrame:CGRectMake(158*0.5f, 198*0.5, 39*0.5f, 39*0.5f)];
    [imageView setContentMode:UIViewContentModeScaleAspectFit];
    [imageView setImage:[UIImage imageNamed:@"small_hashtag"]];
    UILabel *channelName = [[UILabel alloc] initWithFrame:CGRectMake( 210*0.5f, 194*0.5f-2, 181*0.5f, 47*0.5f)];
    [channelName setTextAlignment:NSTextAlignmentLeft];
    [channelName setFont:[UIFont fontWithName:@"Avenir-Black" size:34/2]];
    [channelName setTextColor:[UIColor colorWithHexString:@"464C58"]];
    [channelName setText:@"newusers"];
    
    
    _secondWalkthrough = [[WalkthroughView alloc] initWithFrame:CGRectMake((self.view.frame.size.width-size.width)*0.5f, 211*0.5f, size.width, size.height)];
    [_secondWalkthrough addSubview:thisIsHow];
    [_secondWalkthrough addSubview:tryAddingTheHashtag];
    [_secondWalkthrough addSubview:imageView];
    [_secondWalkthrough addSubview:channelName];
    
    
    [self.view addSubview:_secondWalkthrough];
    [self animateTheAppearanceOfWalkthroughView:_secondWalkthrough delay:0.0f completionBlock:^{}];
    [self addParalaxShiftTiltToView:_secondWalkthrough];
    
}

-(void)createThirdWalkthroughWithChannelName:(NSString*)channelName
{
    CGSize size = CGSizeMake(555*0.5f, 316*0.5f);
    
    [self bindToChannels];
    
    _thirdWalkthrough = [[WalkthroughView alloc] initWithFrame:CGRectMake((self.view.frame.size.width-size.width)*0.5f, 378*0.5f, size.width, size.height)];
    
    
    UILabel *yourFirstHashtag = [[UILabel alloc] initWithFrame:CGRectMake( 0, 25, size.width, 20.5f)];
    [yourFirstHashtag setTextAlignment:NSTextAlignmentCenter];
    [yourFirstHashtag setFont:[UIFont fontWithName:@"Avenir-Book" size:15]];
    [yourFirstHashtag setTextColor:[UIColor colorWithHexString:@"464C58"]];
    [yourFirstHashtag setText:@"Your first hashtag! W00t!"];
    
    UILabel *swipeSuggestion = [[UILabel alloc] initWithFrame:CGRectMake( 0, yourFirstHashtag.frame.size.height + yourFirstHashtag.frame.origin.y + 43.0f * 0.5f, size.width, 20.5f)];
    [swipeSuggestion setTextAlignment:NSTextAlignmentCenter];
    [swipeSuggestion setFont:[UIFont fontWithName:@"Avenir-Book" size:15]];
    [swipeSuggestion setTextColor:[UIColor colorWithHexString:@"464C58"]];
    [swipeSuggestion setText:@"Swipe a hashtag to mute or leave it."];
    
    UILabel *tapSuggestion = [[UILabel alloc] initWithFrame:CGRectMake( 0, swipeSuggestion.frame.size.height + swipeSuggestion.frame.origin.y + 44.0f * 0.5f, size.width, 20.5f)];
    [tapSuggestion setTextAlignment:NSTextAlignmentCenter];
    [tapSuggestion setFont:[UIFont fontWithName:@"Avenir-Book" size:15]];
    [tapSuggestion setTextColor:[UIColor colorWithHexString:@"464C58"]];
    [tapSuggestion setText:@"Tap a hashtag to chat."];
    
    
    [_thirdWalkthrough addSubview:yourFirstHashtag];
    [_thirdWalkthrough addSubview:swipeSuggestion];
    [_thirdWalkthrough addSubview:tapSuggestion];
    
    [self.view addSubview:_thirdWalkthrough];
    
    [self addParalaxShiftTiltToView:_thirdWalkthrough];
    
    
    [self animateTheAppearanceOfWalkthroughView:_thirdWalkthrough delay:0.0f completionBlock:^{}];
    
}

-(void)animateTheDisappearanceOfWalkthroughView:(UIView*)walkthroughView delay:(CGFloat)delay completionBlock:(void(^)(void))completionBlock
{

    
    [UIView animateWithDuration:1.3f delay:delay usingSpringWithDamping:1.2 initialSpringVelocity:1.2 options:UIViewAnimationOptionCurveEaseOut animations:^
     {
         walkthroughView.alpha = 0.0f;
         walkthroughView.transform = CGAffineTransformMakeScale(0.7f, 0.7f);
//         walkthroughView.transform = CGAffineTransformMakeTranslation(-320, 0);
     } completion:^(BOOL finished)
     {
         if (completionBlock)
         {
             completionBlock();
         }
     }];
}

-(void)addParalaxShiftTiltToView:(UIView*)view
{
    UIInterpolatingMotionEffect *verticalMotionEffect =
    [[UIInterpolatingMotionEffect alloc]
     initWithKeyPath:@"center.y"
     type:UIInterpolatingMotionEffectTypeTiltAlongVerticalAxis];
    verticalMotionEffect.minimumRelativeValue = @(-25);
    verticalMotionEffect.maximumRelativeValue = @(25);
    
    // Set horizontal effect
    UIInterpolatingMotionEffect *horizontalMotionEffect =
    [[UIInterpolatingMotionEffect alloc]
     initWithKeyPath:@"center.x"
     type:UIInterpolatingMotionEffectTypeTiltAlongHorizontalAxis];
    horizontalMotionEffect.minimumRelativeValue = @(-10);
    horizontalMotionEffect.maximumRelativeValue = @(10);
    
    // Create group to combine both
    UIMotionEffectGroup *group = [UIMotionEffectGroup new];
    group.motionEffects = @[horizontalMotionEffect, verticalMotionEffect];
    
    // Add both effects to your view
    [view addMotionEffect:group];
}

-(void)endTutorial
{
    [self animateTheDisappearanceOfWalkthroughView:_thirdWalkthrough delay:0.0f completionBlock:^{
        [_thirdWalkthrough removeFromSuperview];
        _thirdWalkthrough = nil;
        
        NSUserDefaults *prefs = [NSUserDefaults standardUserDefaults];
        [prefs setBool:YES forKey:Objc_kNSUSERDEFAULTS_BOOLKEY_userHasSeenWalkthrough];
        [prefs synchronize];
        
        [self insertChannelNow];
        
    }];
}




@end
