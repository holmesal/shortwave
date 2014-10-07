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
#define maxCharsInChannelName NSIntegerMax

@interface SWChannelsViewController () <UICollectionViewDataSource, UICollectionViewDelegate, UIGestureRecognizerDelegate, UITextFieldDelegate>
@property (weak, nonatomic) IBOutlet UIView *addChannelAutoCompleteContainer;
@property (weak, nonatomic) IBOutlet NSLayoutConstraint *addChannelAutoCompleteContainerSpaceToBottom;

@property (weak, nonatomic) IBOutlet UITextField *addChannelTextField;
@property (weak, nonatomic) IBOutlet UICollectionView *channelsCollectionView;
@property (strong, nonatomic) SWChannelModel *selectedChannel;

@property (strong, nonatomic) NSMutableArray *channels;
@property (strong, nonatomic) NSMutableArray *channelNamesOrdering;
@property (strong, nonatomic) NSMutableDictionary *channelLoadedState;

//@property (strong, nonatomic) UIPanGestureRecognizer *myPanGesture;

@property (weak, nonatomic) IBOutlet UIImageView *navBarImageViewBG;
@property (weak, nonatomic) IBOutlet UIView *navBar;
@property (weak, nonatomic) IBOutlet UIImageView *bluebarFlat;

@property (strong, nonatomic) UIView *plusContainer;
@property (strong, nonatomic) UIView *verticalBeam;
@property (strong, nonatomic) UIView *horizontalBeam;


@property (weak, nonatomic) IBOutlet UICollectionView *autoCompleteCollectionView;
@property (strong, nonatomic) NSArray *autoCompleteResults;



@end


@implementation SWChannelsViewController
@synthesize channelsCollectionView;
@synthesize channels;
@synthesize channelNamesOrdering;
@synthesize channelLoadedState;


-(void)setChannel:(NSString*)channel loadedState:(BOOL)loadedState
{
    [channelLoadedState setObject:[NSNumber numberWithBool:loadedState] forKey:channel];
}
-(BOOL)isChannelLoaded:(NSString*)channel
{

    return [[channelLoadedState objectForKey:channel] boolValue];
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
    _autoCompleteResults = @[];
    [_addChannelAutoCompleteContainer setAlpha:0.0f];
    [_addChannelTextField setHidden:YES];
    [_addChannelTextField setTintColor:[UIColor whiteColor]];
    [_addChannelTextField setDelegate:self];
    
    [_autoCompleteCollectionView setDataSource:self];
    [_autoCompleteCollectionView setDelegate:self];
    
    
    
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
    channelLoadedState = [[NSMutableDictionary alloc] init];
    
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
    NSLog(@"pangesture in channelscollectionview = %@", channelsCollectionView.panGestureRecognizer);
    
    
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
    
            [self setPredictedIndex:[self whatPredictedIndexIs:replacingName] forChannelName:name];
            [self setChannel:name loadedState:NO];
            
            Firebase *f2 = [[Firebase alloc] initWithUrl:[NSString stringWithFormat:@"%@channels/%@/meta", Objc_kROOT_FIREBASE, name]];
            [f2 observeSingleEventOfType:FEventTypeValue withBlock:^(FDataSnapshot *f2Snapshot)
            {
                if ([f2Snapshot.value isKindOfClass:[NSDictionary class]])
                {
                    NSDictionary *meta = f2Snapshot.value;
                    SWChannelModel *channelModel = [[SWChannelModel alloc] initWithDictionary:dictionary andUrl:[NSString stringWithFormat:@"%@%@", url, snap.name] andChannelMeta:meta];
                    
                    //JAVA STOPPED HERE
                    channelModel.delegate = self; //updating channel activity indicator
                    
                    
                    //check if this already exists?
                    NSArray *result = [weakSelf.channels filteredArrayUsingPredicate:[NSPredicate predicateWithFormat:@"SELF.name == %@", channelModel.name]];
                    if (result.count != 0)
                    {
                        return;
                    }
                    
                    //what index? a reordering may have occured while iw as fetching f2's single value event
                    NSInteger index = [self whatActualIndexIsChannel:name];
                    [self setChannel:name loadedState:YES];
                    
                    

                    AppDelegate *appDelegate = ((AppDelegate*)[UIApplication sharedApplication].delegate);
                    NSString *channelFromRemoteNotification = appDelegate.channelFromRemoteNotification;
                    if (channelFromRemoteNotification && [channelFromRemoteNotification isEqualToString:channelModel.name])
                    {
                        [weakSelf openChannel:channelModel];
                        appDelegate.channelFromRemoteNotification = nil;
                    }
                    [weakSelf insertChannel:channelModel atIndex:index];
                    
                }
            }];
            
        }
    }];
    
    //MOVED
    [f observeEventType:FEventTypeChildMoved andPreviousSiblingNameWithBlock:^(FDataSnapshot *snap, NSString *replacingName)
    {
        NSString *name = snap.name;
        
        BOOL channelIsLoaded = [self isChannelLoaded:name];
        
        
        NSInteger oldDisplayIndex = [self whatActualIndexIsChannel:name];
        NSInteger oldFinalIndex = [self whatPredictedIndexIs:name];
        SWChannelModel *model = nil;
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
                [weakSelf.channelLoadedState removeObjectForKey:name];
                
                [weakSelf.channelsCollectionView deleteSections:[NSIndexSet indexSetWithIndex:removeIndex]];
            } completion:^(BOOL finished){}];
            
            
        }
    }];
    
}

-(void)openChannel:(SWChannelModel*)channel
{
    self.selectedChannel = channel;
    [self performSegueWithIdentifier:@"Messages" sender:self];
}
-(void)insertChannel:(SWChannelModel*)channel atIndex:(NSInteger)i
{
    __weak SWChannelsViewController *weakSelf = self;
    [channelsCollectionView performBatchUpdates:^
    {
        [weakSelf.channels insertObject:channel atIndex:i];
        [weakSelf.channelsCollectionView insertSections:[NSIndexSet indexSetWithIndex:i]];
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
    [self bindToChannels];
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
        [self openChannel:channels[indexPath.section]];
    } else
    if (collectionView == _autoCompleteCollectionView)
    {
        NSAssert(NO, @"LOL");
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
    _navBarImageViewBG.highlighted = highlighted;

    [_plusContainer setHidden:NO];
    [UIView animateWithDuration:0.4f delay:0.0f options:UIViewAnimationOptionCurveEaseInOut animations:^
    {
        [_horizontalBeam setTransform: highlighted ?
         CGAffineTransformMakeRotation(M_PI/2) : CGAffineTransformMakeRotation(0)];
    
        [_addChannelAutoCompleteContainer setAlpha:highlighted ? 1.0f : 0.0f];
        
    } completion:^(BOOL finished)
    {
        if (highlighted)
        {
            [_plusContainer setHidden:YES];
            [_addChannelTextField setHidden:NO];
            [_addChannelTextField becomeFirstResponder];
        }
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
    
//    self.channelNameCharacterCountLabel.text = [NSString stringWithFormat:@"%d / %d", result.length, maxCharsInChannelName];
//    
//    if (self.timer != nil)
//    {
//        [self.timer invalidate];
//        self.timer = nil;
//    }
//    self.channelName = result;
//    self.channelNameExists = nil;
//    self.temporaryChannelNameExists = nil;
//    [self animateDescriptionContainer:self.descriptionViewContainer visible:NO];
//    [self animateDescriptionContainer:self.createDescriptionContainer visible:NO];
//    
//    if (result.length == 0)
//    {
//        self.activityIndicator.hidden = YES;
//    }
//    NSTimeInterval timeRequestStarted = [[NSDate date] timeIntervalSince1970];
//    
//    [self performFirebaseFetchForChannel:result result:^(BOOL exists, NSString *description)
//     {
//         NSLog(@"channel %@ exists ? %d", result, exists );
//         
//         self.joiningDescriptionString = description;
//         if (self.channelName == result)
//         {
//             self.temporaryChannelNameExists = [NSNumber numberWithBool:exists];
//             
//             NSTimeInterval elapsedTimeOfRequest = [[NSDate date] timeIntervalSince1970] - timeRequestStarted;
//             NSTimeInterval timeRemaining = TIME_DELAY - elapsedTimeOfRequest;
//             
//             if (timeRemaining > 0)
//             {
//                 self.timer = [NSTimer timerWithTimeInterval:timeRemaining target:self selector:@selector(updateUITimer) userInfo:nil repeats:NO];
//                 [[NSRunLoop mainRunLoop] addTimer:self.timer forMode:NSDefaultRunLoopMode];
//             } else
//             {
//                 [self updateUITimer];
//             }
//         }
//         
//     }];
//    
    textField.text = result;
    
    [SWChannelModel query:result andCompletionHandler:^(QueryChannelRequest *request, NSString *originalQuery)
    {
        NSLog(@"done query '%@' with requests: '%d'", originalQuery, request.results.count);
        _autoCompleteResults = request.results;
        [_autoCompleteCollectionView reloadData];
    }];
    
    return NO;
    
}


@end
