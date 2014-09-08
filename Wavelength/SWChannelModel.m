//
//  SWChannelModel.m
//  Shortwave
//
//  Created by Ethan Sherr on 9/3/14.
//  Copyright (c) 2014 Ethan Sherr. All rights reserved.
//

#import "SWChannelModel.h"
#import "ObjcConstants.h"

@interface SWChannelModel ()

@property (assign, nonatomic) double lastPriorityToSet; //initialize 0
@property (strong, nonatomic) NSTimer *setPriorityTimer; //may be nil

@property (strong, nonatomic) NSTimer *reorderChannelsTimer;

@end


@implementation SWChannelModel


@synthesize reorderChannelsTimer;

//1. add myself as a member of the channel, (if fail, completion is run)
//2. add the channel to my list of channels (if fail, completion is run)
//3. completion is run

+(void)joinChannel:(NSString*)channelName withCompletion:(void (^)(NSError *error))completion
{
    //1.
    NSString *userId = [[NSUserDefaults standardUserDefaults] objectForKey:Objc_kNSUSERDEFAULTS_KEY_userId];
    NSString *url1 = [NSString stringWithFormat:@"%@channels/%@/members/%@", Objc_kROOT_FIREBASE, channelName, userId];
    Firebase *membersFB = [[Firebase alloc] initWithUrl:url1];
    
    [membersFB setValue:@YES withCompletionBlock:^(NSError *error1, Firebase *firebase)
    {
        if (error1)
        {
            NSLog(@"<error adding self to members> '%@' : %@", url1, error1.localizedDescription);
            completion(error1);
        } else
        {
            //2.
            NSString *url2 = [NSString stringWithFormat:@"%@users/%@/channels/%@", Objc_kROOT_FIREBASE, userId, channelName];
            Firebase *myChannelsRef = [[Firebase alloc] initWithUrl:url2];
            [myChannelsRef setValue:@{} withCompletionBlock:^(NSError *error2, Firebase *firebase)
            {
                if (error2)
                {
                    NSLog(@"<error adding channel to channels> '%@' : %@", url2, error2.localizedDescription);
                    completion(error2);
                } else
                {
                    //3.
                    completion(nil);
                }
            }];
        }
    }];
    
}

@synthesize isSynchronized;
@synthesize mutedDelegate;


@synthesize lastSeen;
@synthesize channelDescription;

@synthesize name;

@synthesize channelRoot;
@synthesize messagesRoot;
@synthesize mutedFirebase;

@synthesize wallSource;


#pragma mark setters getters, didSet, willSet
@synthesize muted;
-(void)setMuted:(BOOL)newValue
{
    muted = newValue;
    //didSet functionality
    if (mutedDelegate)
    {
        [mutedDelegate channel:self isMuted:muted];
    }
}
-(void)setMutedToFirebase
{
    [mutedFirebase setValue:[NSNumber numberWithBool:muted]];
}

@synthesize setPriorityTimer;
@synthesize lastPriorityToSet;
@synthesize messageCollectionView;
-(void)setMessageCollectionView:(UICollectionView *)newValue
{
    //willSet
    {
        if (!newValue && messageCollectionView)
        {
            wallSource.collectionView = nil;
            messageCollectionView.delegate = nil;
            messageCollectionView.dataSource = nil;
            
        }
    }
    messageCollectionView = newValue;
    //didSet
    {
        if (messageCollectionView)
        {
//            lastPriorityToSet = [[NSDate date] timeIntervalSince1970]*1000;
//            [self setPriority]; //sets priority now
            [self setPriorityToNow];
            
            
            wallSource.collectionView = messageCollectionView;
            messageCollectionView.delegate = wallSource;
            messageCollectionView.dataSource = wallSource;
            [messageCollectionView reloadData];
        }
    }
}
//helper
-(void)setPriority
{
    lastSeen = lastPriorityToSet;
    NSString *myId = [[NSUserDefaults standardUserDefaults] objectForKey:Objc_kNSUSERDEFAULTS_KEY_userId];
    isSynchronized = YES;
    //if the timer is setting priority, that means the lastSeen < priority
    
    Firebase *setLastSeenFb = [[Firebase alloc] initWithUrl:[NSString stringWithFormat:@"%@users/%@/channels/%@/lastSeen", Objc_kROOT_FIREBASE, myId, name]];
    [setLastSeenFb setValue:[NSNumber numberWithDouble:lastSeen]];
    NSLog(@"lastSeen set to %f", lastSeen);
}


#pragma mark functions
-(id)initWithDictionary:(NSDictionary*)dictionary andUrl:(NSString*)url andChannelMeta:(NSDictionary*)meta
{
    if (self = [super init])
    {
        isSynchronized = YES;
        lastSeen = 0.0;
        lastPriorityToSet = 0.0;
        
        [self initializeFrom:dictionary meta:meta andUrl:url];
        
        //firebase observing bellow
        NSString *myId = [[NSUserDefaults standardUserDefaults] objectForKey:Objc_kNSUSERDEFAULTS_KEY_userId];
        NSString *lastSeenUrl = [NSString stringWithFormat:@"%@users/%@/channels/%@/lastSeen", Objc_kROOT_FIREBASE, myId, name];
        Firebase *lastSeenFB = [[Firebase alloc] initWithUrl:lastSeenUrl];
        
        [lastSeenFB observeEventType:FEventTypeValue withBlock:^(FDataSnapshot* snap)
        {
            
            if ([snap.value isKindOfClass:[NSNumber class]])
            {
                double newLastSeen = [((NSNumber*)snap.value) doubleValue];
                if (lastSeen != newLastSeen)
                {
                    lastSeen = newLastSeen;
                    isSynchronized = NO;
                    //self.delegate?.channel(self, receivedNewMessage: nil)
                }
            }
        }];
        
        NSString *mutedUrl = [NSString stringWithFormat:@"%@users/%@/channels/%@/muted", Objc_kROOT_FIREBASE, myId, name];
        mutedFirebase = [[Firebase alloc] initWithUrl:mutedUrl];
        [mutedFirebase observeEventType:FEventTypeValue withBlock:^(FDataSnapshot* snapshot)
        {
            if ([snapshot.value isKindOfClass:[NSNumber class]])
            {
                BOOL isMuted = [((NSNumber*)snapshot.value) boolValue];
                if (isMuted != muted)
                {
                    self.muted = isMuted; //setMuted:(BOOL) called
                }
            }
        }];
        
    }
    return self;
}
//extracts all data from dictionary (muted, lastSeen) and more from meta.
//extracts name from end of url,
//initializes channelRoot & messagesRoot Firebase references
//creates wallSource
-(void)initializeFrom:(NSDictionary*)dictionary meta:(NSDictionary*)meta andUrl:(NSString*)url
{
    NSNumber *lastSeenNumb = dictionary[@"lastSeen"];
    if (lastSeenNumb)
    {
        lastSeen = [lastSeenNumb doubleValue];
    }
    
    channelDescription = meta[@"description"];
    
    self.muted = [(NSNumber*)dictionary[@"muted"] boolValue]; //setMuted:(BOOL) called
    self.url = url;
    
    name = [[url componentsSeparatedByString:@"/"] lastObject];
    
    channelRoot = [[Firebase alloc] initWithUrl:[NSString stringWithFormat:@"%@channels/%@", Objc_kROOT_FIREBASE, name]];
    NSString *messagesUrl = [NSString stringWithFormat:@"%@messages/%@", Objc_kROOT_FIREBASE, name];
    messagesRoot = [[Firebase alloc] initWithUrl:messagesUrl];
    
    wallSource = [[WallSource alloc] initWithUrl:messagesUrl];
    wallSource.target = self;
    
}


-(void)scrollViewWillBeginDragging:(UIScrollView *)scrollView
{
    if (self.scrollViewDelegate)
    {
        [self.scrollViewDelegate scrollViewWillBeginDragging:scrollView];
    }
}


-(void)didLongPress:(UILongPressGestureRecognizer*)longPressGesture
{
    if (self.cellActionDelegate)
    {
        [self.cellActionDelegate didLongPress:longPressGesture];
    }
}

-(void)didLoadMessageModel:(MessageModel*)message
{
    if (reorderChannelsTimer)
    {
        [reorderChannelsTimer invalidate];
        reorderChannelsTimer = nil;
    }
    if (!self.lastMessage || self.lastMessage.priority < message.priority)
    {
        self.lastMessage = message;
    }
    reorderChannelsTimer = [NSTimer timerWithTimeInterval:0.1 target:self selector:@selector(reorderChannels:) userInfo:nil repeats:NO];
    [[NSRunLoop mainRunLoop] addTimer:reorderChannelsTimer forMode:NSDefaultRunLoopMode];
    
    if (message.priority > lastSeen)
    {
        isSynchronized = NO;
        if (self.delegate)
        {
            [self.delegate channel:self hasNewActivity:!isSynchronized];
        }
    }
}

-(void)reorderChannels:(NSTimer*)sender
{
    [reorderChannelsTimer invalidate];
    reorderChannelsTimer = nil;
    
    if (self.delegate)
    {
        [self.delegate channel:self isReorderingWithMessage:self.lastMessage];
    }
    
}

-(void)didViewMessageModel:(MessageModel*)message
{
    if (message.priority >= lastSeen && message.priority > lastPriorityToSet)
    {
        lastPriorityToSet = message.priority;
        [self setPriorityEventually];
    }
}
-(void)setPriorityEventually
{
    if (setPriorityTimer)
    {
        [setPriorityTimer invalidate];
        setPriorityTimer = nil;
    }
    
    setPriorityTimer = [NSTimer timerWithTimeInterval:0.3 target:self selector:@selector(setPriority) userInfo:nil repeats:NO];
    [[NSRunLoop mainRunLoop] addTimer:setPriorityTimer forMode:NSDefaultRunLoopMode];
}
-(void)setPriorityToNow
{
    NSString *myId = [[NSUserDefaults standardUserDefaults] objectForKey:Objc_kROOT_FIREBASE];
    isSynchronized = YES;
    if (self.delegate)
    {
        [self.delegate channel:self hasNewActivity:!isSynchronized];
    }
    NSString *setLastSeenUrl = [NSString stringWithFormat:@"%@users/%@/channels/%@/lastSeen", Objc_kROOT_FIREBASE, myId, name];
    Firebase *lastSeenFB = [[Firebase alloc] initWithUrl:setLastSeenUrl];
    [lastSeenFB setValue:kFirebaseServerValueTimestamp];
}



@end
