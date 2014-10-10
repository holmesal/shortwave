//
//  SWChannelModel.m
//  Shortwave
//
//  Created by Ethan Sherr on 9/3/14.
//  Copyright (c) 2014 Ethan Sherr. All rights reserved.
//

#import "SWChannelModel.h"
#import "ObjcConstants.h"

#import "SWUserManager.h"

@implementation QueryChannelRequest
@end

@implementation QueryResult

-(id)initWithDictionary:(NSDictionary*)result
{
    if (self = [super init])
    {
        _score = result[@"score"];
        if (_score == nil || ![_score isKindOfClass:[NSNumber class]])
        {
            return nil;
        }
        _text = result[@"text"];
        if (_text == nil || ![_text isKindOfClass:[NSString class]])
        {
            return nil;
        }
        NSNumber *memberCountObj = nil;
        
        NSDictionary *payload = result[@"payload"];
        if (payload == nil || ![payload isKindOfClass:[NSDictionary class]])
        {
            return nil;
        }
        
        memberCountObj = payload[@"memberCount"];
        if (memberCountObj == nil || ![memberCountObj isKindOfClass:[NSNumber class]])
        {
            return nil;
        }
        _memberCount = [memberCountObj integerValue];
        
        
    }
    return self;
}

@end


@interface SWChannelModel ()



@property (assign, nonatomic) double lastPriorityToSet; //initialize 0
@property (strong, nonatomic) NSTimer *setPriorityTimer; //may be nil

@property (strong, nonatomic) NSTimer *reorderChannelsTimer;
@property (assign, nonatomic) BOOL didFetchUsers;

@property (strong, nonatomic) NSMutableSet *usersSet;

@end


@implementation SWChannelModel

static QueryChannelRequest *pendingRequest;
//query & return the suggested channel name!
+(void)query:(NSString*)queryTerm andCompletionHandler:(void(^)(QueryChannelRequest *request, NSString *originalQuery, BOOL hasExactMatch))queryResultHandler;
{
    
    QueryChannelRequest *f = [[QueryChannelRequest alloc] init];
    f.put = [[[Firebase alloc] initWithUrl:[NSString stringWithFormat:@"%@searchQueue/query", Objc_kROOT_FIREBASE]] childByAutoId];
    f.get = [[Firebase alloc] initWithUrl:[NSString stringWithFormat:@"%@searchQueue/result/%@", Objc_kROOT_FIREBASE, f.put.name]];
    f.results = [[NSMutableArray alloc] init];
    pendingRequest = f;
    __weak QueryChannelRequest *weakF = f;
    f.listener = [f.get observeEventType:FEventTypeValue withBlock:^(FDataSnapshot *snapshot)
    {
        //if snapshot.value then remove event listener, otherwise keep listening, waiting for elastic search
        if (snapshot.value && [snapshot.value isKindOfClass:[NSDictionary class]])
        {
            BOOL hasExactMatch = NO;
            NSDictionary *value = snapshot.value;
            if ([value isKindOfClass:[NSDictionary class]])
            {
                NSArray *results = value[@"results"];
                if (results && [results isKindOfClass:[NSArray class]])
                {
                    for (NSDictionary *result in results)
                    {
                        if ([result isKindOfClass:[NSDictionary class]])
                        {
                            QueryResult *queryResult = [[QueryResult alloc] initWithDictionary:result];
                            if (queryResult)
                            {
                                [weakF.results addObject:queryResult];
                                if ([queryResult.text isEqualToString:queryTerm])
                                {
                                    hasExactMatch = YES;
                                }
                            }
                            
                        }
                    }
                }
            }
            
            //remove this listener
            [weakF.get removeObserverWithHandle:weakF.listener];
        
            //return queryJoin
            queryResultHandler(weakF, queryTerm, hasExactMatch);
        }
    }];
    //stash the request maybe to avoid multiples? or timer on UI fixes it too
    NSDictionary *queryValue = @{@"query" : queryTerm};
    [f.put setValue:queryValue withCompletionBlock:^(NSError *error, Firebase *ref)
    {}];
}



@synthesize reorderChannelsTimer;
@synthesize latestMessagePriority;


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
             [SWChannelModel localAddChannel:channelName withCompletion:(void(^)(NSError *error))completion];
         }
     }];
    
}

+(void)createChannel:(NSString *)channelName withCompletion:(void (^)(NSError *))completion
{
    NSString *userId = [[NSUserDefaults standardUserDefaults] objectForKey:Objc_kNSUSERDEFAULTS_KEY_userId];
    
    NSDictionary *value = @{@"moderators": @{userId: @YES},
                            @"members": @{userId: @YES},
                            @"meta":
                                @{@"public": @YES,
                                  @"latestMessagePriority" : kFirebaseServerValueTimestamp}
                            };
    Firebase *channelRoot = [[Firebase alloc] initWithUrl:[NSString stringWithFormat:@"%@channels/%@", Objc_kROOT_FIREBASE, channelName]];
    [channelRoot setValue:value withCompletionBlock:^(NSError *error, Firebase *firebase)
     {
         if (error)
         {
             completion(error);
         } else
         {
             [SWChannelModel localAddChannel:channelName withCompletion:completion];
         }
     }];
}

+(void)localAddChannel:(NSString*)channelName withCompletion:(void(^)(NSError *error))completion
{
    NSString *userId = [[NSUserDefaults standardUserDefaults] objectForKey:Objc_kNSUSERDEFAULTS_KEY_userId];
    
    NSString *url2 = [NSString stringWithFormat:@"%@users/%@/channels/%@", Objc_kROOT_FIREBASE, userId, channelName];
    Firebase *myChannelsRef = [[Firebase alloc] initWithUrl:url2];
    [myChannelsRef setValue:@{@"lastSeen":@0, @"muted":@NO} andPriority:[NSNumber numberWithDouble:[[NSDate date] timeIntervalSince1970] *1000] withCompletionBlock:^(NSError *error2, Firebase *firebase)
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
} //x
-(void)setMutedToFirebase
{
    [mutedFirebase setValue:[NSNumber numberWithBool:muted]];
} //x

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
            [wallSource fetchNMessages];
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
        
        
#warning what the fuck is going down below here? It does not update UI, only key-values and no keyvalue observing?  I think this is antiquated.
//        //firebase observing bellow
        NSString *myId = [[NSUserDefaults standardUserDefaults] objectForKey:Objc_kNSUSERDEFAULTS_KEY_userId];
        NSString *lastSeenUrl = [NSString stringWithFormat:@"%@users/%@/channels/%@/lastSeen", Objc_kROOT_FIREBASE, myId, name];
//        Firebase *lastSeenFB = [[Firebase alloc] initWithUrl:lastSeenUrl];
//        
//        [lastSeenFB observeEventType:FEventTypeValue withBlock:^(FDataSnapshot* snap)
//        {
//            
//            if ([snap.value isKindOfClass:[NSNumber class]])
//            {
//                double newLastSeen = [((NSNumber*)snap.value) doubleValue];
//                if (lastSeen != newLastSeen)
//                {
//                    lastSeen = newLastSeen;
//                    isSynchronized = NO;
//                    //self.delegate?.channel(self, receivedNewMessage: nil)
//                }
//            }
//        }];
        
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
        
        //channelReorder listener! set priority on this when value change on latestMessagePriorityUrl
        NSString *latestMessagePriorityUrl = [NSString stringWithFormat:@"%@channels/%@/meta/latestMessagePriority", Objc_kROOT_FIREBASE, name];
        latestMessagePriority = [[Firebase alloc] initWithUrl:latestMessagePriorityUrl];
        [latestMessagePriority observeEventType:FEventTypeValue withBlock:^(FDataSnapshot *snapshot)
        {
            NSNumber *priority = snapshot.value;
            if (priority && [priority isKindOfClass:[NSNumber class]])
            {
                [[[Firebase alloc] initWithUrl:[NSString stringWithFormat:@"%@users/%@/channels/%@", Objc_kROOT_FIREBASE, myId, name]]
                 setPriority:priority];
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
    
    double startDate = [meta[@"latestMessagePriority"] doubleValue];
    
    name = [[url componentsSeparatedByString:@"/"] lastObject];
    
    channelRoot = [[Firebase alloc] initWithUrl:[NSString stringWithFormat:@"%@channels/%@", Objc_kROOT_FIREBASE, name]];
    NSString *messagesUrl = [NSString stringWithFormat:@"%@messages/%@", Objc_kROOT_FIREBASE, name];
    messagesRoot = [[Firebase alloc] initWithUrl:messagesUrl];
    
    wallSource = [[WallSource alloc] initWithUrl:messagesUrl andStartAtDate:startDate];
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
-(void)userTappedFlagOnMessageModel:(MessageModel*)messageModel
{
    if (self.cellActionDelegate)
    {
        [self.cellActionDelegate userTappedFlagOnMessageModel:messageModel];
    }
}


-(void)didLoadMessageModel:(MessageModel*)message
{
//    if (reorderChannelsTimer)
//    {
//        [reorderChannelsTimer invalidate];
//        reorderChannelsTimer = nil;
//    }
    if (!self.lastMessage || self.lastMessage.priority < message.priority)
    {
        self.lastMessage = message;
    }
//    reorderChannelsTimer = [NSTimer timerWithTimeInterval:0.1 target:self selector:@selector(reorderChannels:) userInfo:nil repeats:NO];
//    [[NSRunLoop mainRunLoop] addTimer:reorderChannelsTimer forMode:NSDefaultRunLoopMode];
    
    if (message.priority > lastSeen)
    {
        isSynchronized = NO;
        if (self.delegate)
        {
            [self.delegate channel:self hasNewActivity:!isSynchronized];
        }
    }
} //imp

-(NSArray*)suggestionsForAutoCompleteOnInput:(NSString*)input givenUsers:(NSArray*)users
{
    NSMutableArray *filteredUsers = [[NSMutableArray alloc] init];
    
    NSString *lowercaseInput = [input lowercaseString];
    
    for (SWUser *user in users)
    {
        if ([user isKindOfClass:[SWUser class]])
        {
            NSString *title = [user.firstName lowercaseString];
            if ([title hasPrefix:lowercaseInput] && ![user isMe])
            {
                [filteredUsers addObject:user];
            }
        } else
        {
            NSLog(@"object provided to suggestionsForAutoCompleteOnInput:givenUsers:  is not a user: '%@'", user);
        }
    }
    
    return [NSArray arrayWithArray:filteredUsers];
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
    NSString *myId = [[NSUserDefaults standardUserDefaults] objectForKey:Objc_kNSUSERDEFAULTS_KEY_userId];
    isSynchronized = YES;
    if (self.delegate)
    {
        [self.delegate channel:self hasNewActivity:!isSynchronized];
    }
    NSString *setLastSeenUrl = [NSString stringWithFormat:@"%@users/%@/channels/%@/lastSeen", Objc_kROOT_FIREBASE, myId, name];
    Firebase *lastSeenFB = [[Firebase alloc] initWithUrl:setLastSeenUrl];
    [lastSeenFB setValue:kFirebaseServerValueTimestamp];
}

-(void)fetchAllUsersIfNecessary
{
    if (!_didFetchUsers)
    {
        _didFetchUsers = YES;
        _usersSet = [[NSMutableSet alloc] init];
        
        NSString *membersUrl = [NSString stringWithFormat:@"%@channels/%@/members", Objc_kROOT_FIREBASE, self.name];
        Firebase *fetchAllUsers = [[Firebase alloc] initWithUrl:membersUrl];
        
        __weak SWChannelModel *weakSelf = self;
        [fetchAllUsers observeEventType:FEventTypeChildAdded withBlock:^(FDataSnapshot *snapshot)
        {
            NSString *nameString = snapshot.name;
            if (nameString && [nameString isKindOfClass:[NSString class] ])
            {
                [SWUserManager userForID:nameString withCompletion:^(SWUser *user, BOOL synchronous)
                {
                    [weakSelf.usersSet addObject:user];
                }];
            }
        }];
        
    }
}

-(NSMutableArray*)usersThatBeginWith:(NSString*)prefix isPublic:(BOOL)isPublic
{
    prefix = [prefix lowercaseString];
    NSMutableArray *usersStartingWithPrefix = [[NSMutableArray alloc] initWithCapacity:_usersSet.count];
    
    if (_usersSet)
    {
        for (SWUser *user in _usersSet)
        {
            NSString *key = [[user getAutoCompleteKey:isPublic] lowercaseString];
            if ([key hasPrefix:prefix])
            {
                [usersStartingWithPrefix addObject:user];
            }
        }
    }
    
    return usersStartingWithPrefix;
}

-(NSArray*)scanString:(NSString*)text forAllAtMentionsIsPublic:(BOOL)isPublic
{
    NSMutableArray *usersMentioned = [[NSMutableArray alloc] init];
    
    int length = text.length;
    for (int i = 0; i < length; i++)
    {
        char c = [text characterAtIndex:i];
        if (c == '@')
        {
            int start = i+1;
            int end = start;
            while (end <= length)
            {
                if (end == length || [text characterAtIndex:end] == ' ')
                {
                    //done
                    NSString *atMentionKey = [text substringWithRange:NSMakeRange(start, end-start)];
                    SWUser *user = [self getUserForAtMentionKey:atMentionKey andIsPublic:isPublic];
                    if (user && ![user isMe])
                    {
                        [usersMentioned addObject:user];
                    }
                    break;
                }
                end++;
                
            }
        }
    }
    
    return [NSArray arrayWithArray:usersMentioned];
}

-(SWUser*)getUserForAtMentionKey:(NSString*)atMentionKey andIsPublic:(BOOL)isPublic
{
    for (SWUser * user in _usersSet)
    {
        if ([[user getAutoCompleteKey:isPublic] isEqualToString:atMentionKey ])
        {
            return user;
        }
    }
    return nil;
}

@end
