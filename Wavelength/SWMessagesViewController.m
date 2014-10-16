//
//  SWMessagesViewController.m
//  Shortwave
//
//  Created by Ethan Sherr on 9/4/14.
//  Copyright (c) 2014 Ethan Sherr. All rights reserved.
//

#import "SWMessagesViewController.h"
#import <PHFComposeBarView/PHFComposeBarView.h>
#import "UIColor+HexString.h"
#import "ObjcConstants.h"
#import "MessageCell.h"
#import <Mixpanel/Mixpanel.h>
#import "MessageImage.h"
#import "SWImageCell.h"
#import <AVFoundation/AVFoundation.h>
#import "MessageGif.h"
#import "SWBucketUpload.h"
#import "MessageFile.h"
#import "SWChannelModel.h"
#import "SWAtMentionCell.h"
#import "SWImageLoader.h"
#import "AppDelegate.h"

#define kAutoCompleteCellHeight 40.0f

@interface SWMessagesViewController () <PHFComposeBarViewDelegate, UIActionSheetDelegate, UIImagePickerControllerDelegate, UITextFieldDelegate, UICollectionViewDelegate, UICollectionViewDataSource, UICollectionViewDelegateFlowLayout>

@property (weak, nonatomic) IBOutlet NSLayoutConstraint *collectionViewVerticalSpaceToBottom;
@property (strong, nonatomic) UILabel *membersCountLabel;
@property (assign, nonatomic) NSInteger atMentionStartsAtThisIndex;

@property (strong, nonatomic) NSMutableArray *autoCompleteData;
@property (strong, nonatomic) UIView *autoCompleteContainerView;
@property (strong, nonatomic) UICollectionView *autoCompleteCollectionView;

@property (strong, nonatomic) UIActionSheet *flagMessageActionSheet;
@property (strong, nonatomic) MessageModel *flagMessageModel;

@property (strong, nonatomic) UIView *temporaryEnlargedView;
@property (strong, nonatomic) UIView *uploadProgressView;

@property (weak, nonatomic) IBOutlet PHFComposeBarView *composeBarView;
@property (weak, nonatomic) IBOutlet UICollectionView *collectionView;
@property (weak, nonatomic) IBOutlet NSLayoutConstraint *composeBarBottomConstraint;

//silly animator stuff
@property (strong, nonatomic) UIDynamicAnimator *animator;
@property (strong, nonatomic) UIGravityBehavior *gravity;
@property (strong, nonatomic) UICollisionBehavior *collision;


@property (strong, nonatomic) AVPlayer *player;

////upload specs
//@property (strong, nonatomic) NSString *fileName;
//@property (assign, nonatomic) CGSize imageSize;
//@property (strong, nonatomic) NSString *contentType;

@end


@implementation SWMessagesViewController
@synthesize uploadProgressView;
@synthesize player;

@synthesize channelModel;
-(void)setChannelModel:(SWChannelModel *)newValue
{
    channelModel = newValue;
    //didSet
    {
        [channelModel fetchAllUsersIfNecessary];
        channelModel.scrollViewDelegate = self;
    }
}


@synthesize temporaryEnlargedView;
@synthesize composeBarView;
@synthesize collectionView;
@synthesize composeBarBottomConstraint;

-(void)viewWillDisappear:(BOOL)animated
{
    [super viewWillDisappear:animated];
    
    [self.navigationController setNavigationBarHidden:YES animated:YES];
}
-(void)viewWillAppear:(BOOL)animated
{
    [super viewWillAppear:animated];
    
    [[UIApplication sharedApplication] setStatusBarStyle:UIStatusBarStyleLightContent];
    [self.navigationController setNavigationBarHidden:NO animated:YES];
}

-(void)initAutocompleteViews
{
    _autoCompleteContainerView = [[UIView alloc] initWithFrame:CGRectMake(0, composeBarView.frame.origin.y, self.view.bounds.size.width, 0.0f)];
    [_autoCompleteContainerView setBackgroundColor:[UIColor whiteColor] ];
    [self.view insertSubview:_autoCompleteContainerView belowSubview:composeBarView];
    
    UICollectionViewFlowLayout *layout=[[UICollectionViewFlowLayout alloc] init];
    _autoCompleteCollectionView = [[UICollectionView alloc] initWithFrame:_autoCompleteContainerView.bounds collectionViewLayout:layout];

    UINib *nib = [UINib nibWithNibName:@"SWAtMentionCell" bundle:nil];
    [_autoCompleteCollectionView registerNib:nib forCellWithReuseIdentifier:@"SWAtMentionCell"];
    
    [_autoCompleteCollectionView setBackgroundColor:[UIColor whiteColor] ];
    
    _autoCompleteData = [[NSMutableArray alloc] init];
    
    [_autoCompleteCollectionView setDataSource:self];
    [_autoCompleteCollectionView setDelegate:self];
    
    UIView *topline = [[UIView alloc] initWithFrame:CGRectMake(0, 0, _autoCompleteContainerView.frame.size.width, 1)];
    topline.backgroundColor = [UIColor colorWithWhite:151/255.0f alpha:1.0f];
    
    [_autoCompleteContainerView addSubview:_autoCompleteCollectionView];
    [_autoCompleteContainerView addSubview:topline];
}

-(void)viewDidLoad
{
    [super viewDidLoad];
    [self initAutocompleteViews];



    
    
//    self.navigationController.
    UIImageView *hashtagInTitleImageView = [[UIImageView alloc] initWithFrame:CGRectMake(0, (44-14)*0.5f, 14, 14)];
    [hashtagInTitleImageView setContentMode:UIViewContentModeScaleAspectFill];
    [hashtagInTitleImageView setImage:[UIImage imageNamed:@"small_hashtag"]];
    
    UILabel *channelNameLabel = [[UILabel alloc] initWithFrame:CGRectMake(0, 0, 200, 44)];
    [channelNameLabel setNumberOfLines:1];
    [channelNameLabel setFont:[UIFont fontWithName:@"Avenir-Black" size:33*0.5f]];
    [channelNameLabel setTextColor:[UIColor colorWithHexString:@"464C58"]];
    [channelNameLabel setText:channelModel.name];
    
    CGFloat channelNameLabelWidth = [channelNameLabel sizeThatFits:channelNameLabel.frame.size].width;
    CGRect channelNameLabelRect = channelNameLabel.frame;
    channelNameLabelRect.size.width = channelNameLabelWidth;
    
    channelNameLabelRect.origin.x += hashtagInTitleImageView.frame.size.width + hashtagInTitleImageView.frame.origin.x + 5;
    channelNameLabel.frame = channelNameLabelRect;
    
    CGFloat widthOfTitleView = channelNameLabelRect.origin.x + channelNameLabelWidth;
    
    UIView *titleView = [[UIView alloc ] initWithFrame:CGRectMake(0, 0, widthOfTitleView, 44)];
//    [titleView setBackgroundColor:[UIColor redColor] ];
    [titleView addSubview:channelNameLabel];
    [titleView addSubview:hashtagInTitleImageView];
    
    


    
    [self.navigationItem setTitleView:titleView];
    
    
    [self setAutomaticallyAdjustsScrollViewInsets:NO];
    uploadProgressView = [[UIView alloc] initWithFrame:CGRectMake(0, 0, 320, 3.5)];
    uploadProgressView.backgroundColor = [UIColor colorWithHexString:Objc_kNiceColors[@"green"]];
    uploadProgressView.hidden = YES;
    
    //    UIBarButtonItem *rightButton = [[UIBarButtonItem alloc] initWithTitle:@"Invite" style:UIBarButtonItemStylePlain target:self action:@selector(shareChannelAction:)];

    UIImageView *personIcon = [[UIImageView alloc] initWithFrame:CGRectMake(0, 0, 27*0.5f, 27*0.5f)];
    [personIcon setContentMode:UIViewContentModeScaleAspectFit];
    [personIcon setImage:[UIImage imageNamed:@"person_symbol"]];
    
    _membersCountLabel = [[UILabel alloc] initWithFrame:CGRectMake(0, 0, 75, 44)];
    [_membersCountLabel setTextAlignment:NSTextAlignmentRight];
    [_membersCountLabel setTextColor:[UIColor colorWithHexString:@"464C58"]];
    [_membersCountLabel setFont:[UIFont fontWithName:@"Avenir-Book" size:28*0.5f]];
    [_membersCountLabel setText:@"0"];
    NSString *membersCountUrl = [NSString stringWithFormat:@"%@channels/%@/meta/memberCount", Objc_kROOT_FIREBASE, self.channelModel.name];
    Firebase *memberCount = [[Firebase alloc] initWithUrl:membersCountUrl];
    [memberCount observeEventType:FEventTypeValue withBlock:^(FDataSnapshot *snapshot)
     {
         if (snapshot.value && [snapshot.value isKindOfClass:[ NSNumber class] ])
         {
             int members = [snapshot.value intValue];
             [_membersCountLabel setText:[NSString stringWithFormat:@"%d", members]];
         }
     }];
    
    UIView *rightBarView = [[UIView alloc] initWithFrame:CGRectMake(0, 0, 44, 44)];
    CGRect personIconFrame = personIcon.frame;
    personIconFrame.origin.x = rightBarView.frame.size.width - personIconFrame.size.width;
    personIconFrame.origin.y = (rightBarView.frame.size.height - personIconFrame.size.height)*0.5f;
    personIcon.frame = personIconFrame;
    [rightBarView addSubview:personIcon];
    
    CGRect membersCountFrame = _membersCountLabel.frame;
    membersCountFrame.origin.x = personIconFrame.origin.x - membersCountFrame.size.width - 1;
    membersCountFrame.origin.y = 2;
    _membersCountLabel.frame = membersCountFrame;
    
    [rightBarView addSubview:personIcon];
    [rightBarView setClipsToBounds:NO];
    [rightBarView addSubview:_membersCountLabel];
    
    UIBarButtonItem *rightButton = [[UIBarButtonItem alloc] initWithCustomView:rightBarView];

    
    self.navigationItem.rightBarButtonItem = rightButton;
    
//    self.navigationItem.title = [NSString stringWithFormat:@"#%@", channelModel.name];
    
    [self setupComposeBarView];
    composeBarView.textView.font = [UIFont fontWithName:@"Avenir-Medium" size:14];
    composeBarView.textView.textColor = [UIColor colorWithRed:70/255.0f green:76/255.0f blue:88/255.0f alpha:1.0f];
    composeBarView.textView.tintColor = [UIColor colorWithRed:70/255.0f green:76/255.0f blue:88/255.0f alpha:1.0f];
    [composeBarView setDelegate:self];
    
    
    composeBarView.button.tintColor = [UIColor colorWithRed:70/255.0f green:76/255.0f blue:88/255.0f alpha:1.0f];
    
    [composeBarView addSubview:uploadProgressView];
    
    
    [MessageCell registerCollectionViewCellsForCollectionView:collectionView];
    channelModel.messageCollectionView = collectionView;
    
    collectionView.transform = CGAffineTransformMakeRotation(M_PI);
    collectionView.showsVerticalScrollIndicator = NO;
    NSNotificationCenter *notifCenter = [NSNotificationCenter defaultCenter];
    [notifCenter addObserver:self selector:@selector(keyboardWillToggle:) name:UIKeyboardWillShowNotification object:nil];
    [notifCenter addObserver:self selector:@selector(keyboardWillToggle:) name:UIKeyboardWillHideNotification object:nil];
    
    self.collectionView.alwaysBounceVertical = YES;
    [collectionView setContentInset:UIEdgeInsetsMake(10, 0, 29, 0)];
    channelModel.cellActionDelegate = self;
    
}
-(void)setupComposeBarView
{
    composeBarView.maxLinesCount = 5;
    composeBarView.button.titleLabel.textColor = [UIColor colorWithHexString:@"7E7E7E"];
    composeBarView.delegate = self;
    composeBarView.utilityButtonImage = [UIImage imageNamed:@"plus_icon"];
    
//    composeBarView.utilityButtonImage = [UIImage imageNamed:@"camera.png"];
}

//all composeBarView functionality can be abstracted to another class, ideally.  Probably the composebarView
-(void)composeBarViewDidPressUtilityButton:(PHFComposeBarView *)composeBarView
{
    NSLog(@"pick image!");
    UIActionSheet *actionSheet = [[UIActionSheet alloc] initWithTitle:nil delegate:self cancelButtonTitle:@"Cancel" destructiveButtonTitle:nil otherButtonTitles:@"Photo from camera", @"Photo from library", @"Image from hubot", @"GIF from hubot", nil];
    [actionSheet showInView:self.view];
//    self.navigationController.navigationBar.tintColor = [UIColor blackColor];
}



- (void)navigationController:(UINavigationController *)navigationController willShowViewController:(UIViewController *)viewController animated:(BOOL)animated
{
    UILabel *label = [[UILabel alloc] initWithFrame:CGRectMake(0, 0, 100, 44)];
    [label setTextColor:[UIColor blackColor] ];
    label.text = @"Photos";
    CGRect labelRect = label.frame;
    labelRect.size = [label sizeThatFits:label.frame.size];
    [label setFrame:labelRect];
    
    [label setTextAlignment:NSTextAlignmentCenter];
    
    viewController.navigationItem.titleView = label;
}

-(void)actionSheet:(UIActionSheet *)actionSheet clickedButtonAtIndex:(NSInteger)buttonIndex
{
    if (actionSheet == _flagMessageActionSheet)
    {
        NSLog(@"flagMessageActionSheet!");
        NSLog(@"buttonIndex = %d", buttonIndex);
        if (buttonIndex == 0)
        {
            NSString *messageId = _flagMessageModel.name;
            NSString *channelId = channelModel.name;
            NSLog(@"flag messageId '%@' and channelId '%@' as inappropriate", messageId, channelId);
            
            Firebase *flagQueue = [[[Firebase alloc] initWithUrl:[NSString stringWithFormat:@"%@flagQueue", Objc_kROOT_FIREBASE]] childByAutoId];
            [flagQueue setValue:
             @{@"channel": channelId,
               @"message": messageId}
            withCompletionBlock:^(NSError *error, Firebase *ref)
            {
                if (error)
                {
                    NSLog(@"error while adding flagQueue '%@'", error.localizedDescription);
                }
            }];
            
            
        }
    } else
    {
        switch (buttonIndex) {
            case 0:
            {
                //camera
                NSLog(@"open camera");
                UIImagePickerController *picker = [[UIImagePickerController alloc ] init];

                picker.delegate = self;
                picker.sourceType = UIImagePickerControllerSourceTypeCamera;
                [self presentViewController:picker animated:YES completion:nil];
                
            }
                break;
            case 1:
            {
                //library
                NSLog(@"open library");
                UIImagePickerController *picker = [[UIImagePickerController alloc ] init];
    //            NSLog(@"picker.navigationItem %@", picker.navigationItem);
    //            
    //            NSLog(@"picker.navigationItem.titleView = %@", picker.navigationItem.titleView);
                
                picker.delegate = self;
                picker.sourceType = UIImagePickerControllerSourceTypePhotoLibrary;
                [self presentViewController:picker animated:YES completion:nil];
                
                [[UIApplication sharedApplication] setStatusBarStyle:UIStatusBarStyleDefault];
                
            }
            break;
            case 2:
            {
                //hubot imaeg
                NSLog(@"hubot imaeg");
                UITextRange *textRange = composeBarView.textView.selectedTextRange;
                NSString *replaceString = @"hubot image me ";
                [composeBarView.textView replaceRange:textRange withText:replaceString];
                [composeBarView.textView becomeFirstResponder];
            }
            break;
                
            case 3:
            {
                UITextRange *textRange = composeBarView.textView.selectedTextRange;
                NSString *replaceString = @"hubot animate me ";
                [composeBarView.textView replaceRange:textRange withText:replaceString];
                [composeBarView.textView becomeFirstResponder];
            }
                break;
            default:
                return;
                break;
        }
    }
    
    
    
}

-(NSString *) genARandStringLength: (int) len {
    NSString *letters = @"abcdefghijklmnopqrstuvwxyzABCDEFGHIJKLMNOPQRSTUVWXYZ0123456789";
    NSMutableString *randomString = [NSMutableString stringWithCapacity: len];
    
    for (int i=0; i<len; i++) {
        [randomString appendFormat: @"%C", [letters characterAtIndex: arc4random() % [letters length]]];
    }
    
    return randomString;
}

-(void)imagePickerController:(UIImagePickerController *)picker didFinishPickingMediaWithInfo:(NSDictionary *)info
{

    //image
    UIImage *img = info[@"UIImagePickerControllerOriginalImage"];
    NSData *imageData = UIImageJPEGRepresentation(img, 0.9);
    NSString *randomString = [self genARandStringLength:25];
    
    
    //on complete upload, will upload this message
    NSString *fileName = [NSString stringWithFormat:@"%@.jpg", randomString];
    NSString *contentType = @"image/jpeg";
    CGSize imageSize = img.size;
    
    [[SWBucketUpload sharedInstance] uploadData:imageData forName:fileName contentType:contentType progress:^(CGFloat progress)
    {
        [uploadProgressView setTransform:CGAffineTransformMakeTranslation(-320 + 320*progress, 0)];
        [uploadProgressView setHidden:NO];
        
        NSLog(@"returend progress = %f", progress);
    } andComlpetion:^(NSError *error)
    {
        [uploadProgressView setTransform:CGAffineTransformMakeTranslation(-320, 0)];
        [uploadProgressView setHidden:YES];
        
        NSLog(@"completion! %@", error);
        if (error)
        {
            NSLog(@"error = %@", error);
        } else
        {
            NSString *ownerID = [[NSUserDefaults standardUserDefaults] objectForKey:Objc_kNSUSERDEFAULTS_KEY_userId];
            //post a file message to this channel
//            MessageFile *fileMessage = [[MessageFile alloc] initWithFileName:fileName contentType:contentType andImageSize:imageSize andOwnerID:ownerID];
            NSString *src = [NSString stringWithFormat:@"https://s3-us-west-1.amazonaws.com/wavelength-bucket/%@", fileName];
            MessageImage *imageMessage = [[MessageImage alloc] initWithSrc:src ownerID:ownerID];
            [imageMessage sendMessageToChannel:channelModel.name];
        }
    }];
    
    
    [picker dismissViewControllerAnimated:YES completion:^{}];
}


-(void)shareChannelAction:(id)sender
{
    NSString *UID = [[NSUserDefaults standardUserDefaults] objectForKey:Objc_kNSUSERDEFAULTS_KEY_userId];
    NSString *skimmedId = [UID stringByReplacingOccurrencesOfString:@"facebook:" withString:@""];
    
    NSString *shareUrl = [NSString stringWithFormat:@"http://wavelength.im/%@?ref=%@", channelModel.name, skimmedId];
    UIActivityViewController *activityView = [[UIActivityViewController alloc] initWithActivityItems:@[shareUrl] applicationActivities:nil];
    
    activityView.completionHandler = ^(NSString *activityType, BOOL done)
    {
        NSMutableDictionary *mixpanelProperties = [[NSMutableDictionary alloc] initWithDictionary:@{@"channel":channelModel.name, @"done":[NSNumber numberWithBool:done]}];
        if (activityType)
        {
            [mixpanelProperties setObject:activityType forKey:@"activityType"];
        }
        [[Mixpanel sharedInstance] track:@"Invite" properties:mixpanelProperties];
    };
    
    [self presentViewController:activityView animated:YES completion:nil];
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
    
    CGFloat dy = startFrame.origin.y - endFrame.origin.y;
    CGFloat constraintHeight = (dy < 0 ? 0 : dy);
    
    UIEdgeInsets contentInset = self.collectionView.contentInset;
    contentInset.top = constraintHeight;
    
    //very last cell
//    NSInteger lastIndex = channelModel.messages.count -1;
    
    NSInteger signCorrection = -1;
    if (startFrame.origin.y < 0 || startFrame.origin.x < 0 || endFrame.origin.y < 0 || endFrame.origin.x)
    {
        signCorrection = 1;
    }
    
    CGFloat heightChange = (endFrame.origin.y - endFrame.origin.y) * signCorrection;
    CGPoint newContentOffset = CGPointMake(0, collectionView.contentOffset.y - heightChange);
    
    [UIView animateWithDuration:0.3f delay:0.0f options:(UIViewAnimationOptionBeginFromCurrentState | animationCurve << 16) animations:^
    {
        self.collectionView.contentInset = contentInset;
        self.composeBarBottomConstraint.constant = constraintHeight;
        
        CGRect r = _autoCompleteContainerView.frame;
        r.origin.y = [UIScreen mainScreen].bounds.size.height - composeBarView.frame.size.height - r.size.height - constraintHeight;
        _autoCompleteContainerView.frame = r;
        _autoCompleteCollectionView.frame = _autoCompleteContainerView.bounds;
        
        [self.composeBarView layoutIfNeeded];
        self.collectionView.contentOffset = newContentOffset;
        
        NSLog(@"constraintHeight+40 = %f", (constraintHeight + 40));
        _collectionViewVerticalSpaceToBottom.constant = constraintHeight + 40;
        [collectionView.superview layoutIfNeeded];
        
    } completion:^(BOOL finished){}];
    
}

-(void)composeBarViewDidPressButton:(PHFComposeBarView *)_composeBarView
{
    NSString *text = self.composeBarView.text;
    
    NSString *lowercase = [text lowercaseString];
    if ([lowercase rangeOfString:@"helix"].location != NSNotFound || [lowercase rangeOfString:@"fossil"].location != NSNotFound)
    {
        [self helixFossil];
        [composeBarView resignFirstResponder];
        [[Mixpanel sharedInstance] track:@"Helix Fossil" properties:@{@"message": text}];
        return;
    }
    
    NSString *ownerId = [[NSUserDefaults standardUserDefaults] objectForKey:Objc_kNSUSERDEFAULTS_KEY_userId];
    
    MessageModel *message = [[MessageModel alloc] initWithOwnerID:ownerId andText:text];
    message.isPublic = YES;
    message.usersMentioned = [self.channelModel scanString:text forAllAtMentionsIsPublic:message.isPublic];
    [message sendMessageToChannel:channelModel.name];
    
    [self.composeBarView setText:@"" animated:YES];
    [self.composeBarView resignFirstResponder];
    
}

-(void)dealloc
{
    [[NSNotificationCenter defaultCenter] removeObserver:nil];
    if (channelModel.messageCollectionView == self.collectionView)
    {
        channelModel.scrollViewDelegate = nil;
        channelModel.cellActionDelegate = nil;
        channelModel.messageCollectionView = nil; // no more collecitonView associated with channelModel dataSource Delegate
    }
    
}

-(void)viewDidDisappear:(BOOL)animated
{
    [super viewDidDisappear:animated];
    
}

-(void)didLongPress:(MessageCell *)cell
{
//    CGPoint location = [longPress locationInView:collectionView];
//    NSIndexPath *indexPath = [collectionView indexPathForItemAtPoint:location];
//    
//    if (indexPath)
//    {
//        return;
////        
////        MessageModel *messageModel = [channelModel.wallSource wallObjectAtIndex:indexPath.item];
////        UICollectionViewCell *cell = [collectionView cellForItemAtIndexPath:indexPath];
////        if (cell)
////        {
////            [self handleLongPress:longPress withMessageModel:messageModel andCollectionViewCell:cell];
////            return;
////        }
//        
//    }
//    
//    [self handleLongPress:longPress withMessageModel:nil andCollectionViewCell:nil];
    NSLog(@"longPress in messagesViewController on %@", cell);
    if (cell)
    {
        [self handleLongPress:cell.longPress withMessageModel:cell.model andCollectionViewCell:cell];
    }
}

-(void)handleLongPress:(UILongPressGestureRecognizer*)longPressGesture withMessageModel:(MessageModel*)messageModel andCollectionViewCell:(UICollectionViewCell*)cell
{
    switch (longPressGesture.state) {
        case UIGestureRecognizerStateBegan:
        {
            __weak SWMessagesViewController *weakSelf = self;
            void (^createTemopraryEnlargedView)(void) = ^{
                weakSelf.temporaryEnlargedView = [[UIView alloc] initWithFrame:weakSelf.view.bounds];
                weakSelf.temporaryEnlargedView.backgroundColor = [UIColor colorWithWhite:0 alpha:0.8f];
                weakSelf.temporaryEnlargedView.alpha = 0.0f;
                [weakSelf.view addSubview:weakSelf.temporaryEnlargedView];
                
                [UIView animateWithDuration:0.3f delay:0.0f usingSpringWithDamping:1.0f initialSpringVelocity:0.0f options:UIViewAnimationOptionCurveEaseInOut animations:^
                {
                    if (weakSelf.temporaryEnlargedView)
                    {
                        weakSelf.temporaryEnlargedView.alpha = 1.0f;
                    }
                } completion:^(BOOL finished)
                {}];
            };
            
            if ((messageModel && [messageModel isKindOfClass:[MessageImage class]]) ||
                (messageModel && [messageModel isKindOfClass:[MessageFile class]] && [((MessageFile*)messageModel).contentType isEqualToString:@"image/jpeg"])
                 )
            {
//                MessageImage *imageMessage = messageModel;
                createTemopraryEnlargedView();
                SWImageCell *imageCell = (SWImageCell*)cell;
                UIImageView *imageView = [[UIImageView alloc] initWithFrame:self.view.bounds];
                imageView.contentMode = UIViewContentModeScaleAspectFit;
                imageView.image = [imageCell getImage];
                
                [temporaryEnlargedView addSubview:imageView];
            } else
            if ([messageModel isKindOfClass:[MessageGif class]])
            {
                MessageGif *gifMessage = (MessageGif*)messageModel;
                createTemopraryEnlargedView();
                
                
                AppDelegate *appDelegate = (AppDelegate*)[UIApplication sharedApplication].delegate;
                SWImageLoader *imageLoader = appDelegate.imageLoader;
                
                player = [AVPlayer playerWithURL:[NSURL fileURLWithPath:[imageLoader filePathForMp4Url:gifMessage.mp4]]];
                player.muted = YES;
                
                //    playerLayer = [AVPlayerLayer playerLayerWithPlayer:_player];
                
                player.actionAtItemEnd = AVPlayerActionAtItemEndNone;
                
                AVPlayerLayer *playerLayer = [AVPlayerLayer playerLayerWithPlayer:player];
                [player play];
                playerLayer.bounds = self.view.bounds;
                playerLayer.position = CGPointMake(playerLayer.bounds.size.width*0.5f, playerLayer.bounds.size.height*0.5f);
                
                [[NSNotificationCenter defaultCenter] addObserver:self
                                                         selector:@selector(playerItemDidReachEnd:)
                                                             name:AVPlayerItemDidPlayToEndTimeNotification
                                                           object:[player currentItem]];
                
                [temporaryEnlargedView.layer addSublayer:playerLayer];
            }
            
        }
        break;
        case UIGestureRecognizerStateCancelled:
        case UIGestureRecognizerStateEnded:
        {
            if (temporaryEnlargedView)
            {
                [UIView animateWithDuration:0.3f delay:0.0f usingSpringWithDamping:1.0f initialSpringVelocity:0.0f options:UIViewAnimationOptionCurveEaseInOut animations:^
                {
                    temporaryEnlargedView.alpha = 0.0f;
                } completion:^(BOOL finished){
                    [temporaryEnlargedView removeFromSuperview];
                    temporaryEnlargedView = nil;
                    [[NSNotificationCenter defaultCenter] removeObserver:self name:AVPlayerItemDidPlayToEndTimeNotification object:[player currentItem]];
                    player = nil;

                }];
            }
        }
        break;
            
        default:
            break;
    }
}

-(void)playerItemDidReachEnd:(NSNotification*)note
{
    //    if (note.object == self.gifMessage.playerItem)
    //    {
    //
    NSLog(@"playerItemDidReachEnd");
    
    [player seekToTime:kCMTimeZero];
    //        [_player play];
    //
    //    }
}

-(void)scrollViewWillBeginDragging:(UIScrollView *)scrollView
{
    [composeBarView.textView resignFirstResponder];
}

@synthesize animator;
@synthesize gravity;
@synthesize collision;

-(void)createAnimatorStuffIfNotAlready
{
    if (!animator)
    {
        animator = [[UIDynamicAnimator alloc] initWithReferenceView:self.view];
        gravity = [[UIGravityBehavior alloc] init];
        collision = [[UICollisionBehavior alloc] init];
        collision.translatesReferenceBoundsIntoBoundary = YES;
        [animator addBehavior:gravity];
        [animator addBehavior:collision];
    }
}

-(void)fossilTap:(UIButton*)helixButton
{
    [helixButton removeFromSuperview];
    [gravity removeItem:helixButton];
    [collision removeItem:helixButton];
    
    UIAlertView *alert = [[UIAlertView alloc] initWithTitle:nil message:@"Now is not the time to consult the helix fossil." delegate:nil cancelButtonTitle:nil otherButtonTitles:nil];
    [alert show];
    
    UInt64 dealyInSecond = 2;
    dispatch_time_t popTime = dispatch_time(DISPATCH_TIME_NOW, dealyInSecond * NSEC_PER_SEC);
    dispatch_after(popTime, dispatch_get_main_queue(), ^{
        [alert dismissWithClickedButtonIndex:0 animated:YES];
    });
}

-(void)helixFossil
{
    UIButton *square = [[UIButton alloc] initWithFrame:CGRectMake((320-56)*0.5f, 100, 56, 60)];
    [square setBackgroundImage:[UIImage imageNamed:@"fossil"] forState:UIControlStateNormal];
    square.contentMode = UIViewContentModeScaleToFill;
    [self.view addSubview:square];
    
    square.alpha = 0.2f;
    square.transform = CGAffineTransformMakeScale(1.6, 1.6);
    
    [UIView animateWithDuration:0.7f delay:0.0f usingSpringWithDamping:1.0f initialSpringVelocity:1.0f options:UIViewAnimationOptionCurveLinear animations:^
    {
        square.transform = CGAffineTransformIdentity;
        square.alpha = 1.0f;
    } completion:^(BOOL finished){
    }];
    
    [square addTarget:self action:@selector(fossilTap:) forControlEvents:UIControlEventTouchDown];
    [self createAnimatorStuffIfNotAlready];
    
    [gravity addItem:square];
    [collision addItem:square];
    
    //push behavior
    UIPushBehavior *pushBehavior = [[UIPushBehavior alloc] initWithItems:@[square] mode:UIPushBehaviorModeInstantaneous];
    pushBehavior.magnitude = 1;
    double d = random()%2;
    pushBehavior.angle = d * M_PI;
    [animator addBehavior:pushBehavior];
    [animator addBehavior:collision];
}

-(void)viewDidAppear:(BOOL)animated
{
    [super viewDidAppear:animated];
}

-(void)userTappedFlagOnMessageModel:(MessageModel*)messageModel
{
    _flagMessageModel = messageModel;
    if (!_flagMessageActionSheet)
    {
        _flagMessageActionSheet = [[UIActionSheet alloc] initWithTitle:nil delegate:self cancelButtonTitle:@"Cancel" destructiveButtonTitle:nil otherButtonTitles:@"Flag as inappropriate", nil];
    }
    [_flagMessageActionSheet showInView:self.view];
}

-(BOOL)textField:(UITextField *)textField shouldChangeCharactersInRange:(NSRange)range replacementString:(NSString *)string
{
    
    return YES;
}

-(void)textViewDidChange:(UITextView *)textView
{
    
    NSUInteger s = textView.selectedRange.location;

    int end = s - 1;
    int start = -1;
    
    
    for (int i = s - 1; i >= 0; i--)
    {
        char c = [textView.text characterAtIndex:i];
        
        if (c == ' ')
        {
            break;
        }
        
        if (c == '@')
        {
            _atMentionStartsAtThisIndex = i;
            start = i;
            break;
        }
    }
    
    NSMutableArray *users = nil;
    if (start >= 0)
    {
        NSRange range;
        range.location = start + 1;
        range.length = end-start ;
        NSString *queryString = [textView.text substringWithRange:range];
        users = [self.channelModel usersThatBeginWith:queryString isPublic:YES];
    }
    
    NSLog(@"fetched : %d", users.count);
    if (users.count != 0)
    {
        [self updateCurrentFetchedUsersWithUsers:users];
    }
    
    int count = users.count;
    [UIView animateWithDuration:0.38f delay:0.0f usingSpringWithDamping:1.0 initialSpringVelocity:1.2 options:UIViewAnimationOptionCurveLinear animations:^
    {
        
        CGRect endFrame = CGRectMake(0, composeBarView.frame.origin.y, _autoCompleteContainerView.frame.size.width, kAutoCompleteCellHeight*count);
        endFrame.origin.y -= endFrame.size.height;
        _autoCompleteContainerView.frame = endFrame;
        _autoCompleteCollectionView.frame = _autoCompleteContainerView.bounds;
        
    } completion:^(BOOL finished)
    {
        if (users.count == 0)
        {
            [self updateCurrentFetchedUsersWithUsers:users];
        }
    }];
    

    
}

-(void)updateCurrentFetchedUsersWithUsers:(NSMutableArray*)newAutoComplete
{
    
    _autoCompleteData = newAutoComplete;
    [_autoCompleteCollectionView reloadData];
    
    
}


-(NSInteger)collectionView:(UICollectionView *)collectionView numberOfItemsInSection:(NSInteger)section
{
    return _autoCompleteData.count;
}

-(NSInteger)numberOfSectionsInCollectionView:(UICollectionView *)collectionView
{
    return 1;
}

-(void)collectionView:(UICollectionView *)collectionView didSelectItemAtIndexPath:(NSIndexPath *)indexPath
{
    SWAtMentionCell *atMentionCell = (SWAtMentionCell*) [_autoCompleteCollectionView cellForItemAtIndexPath:indexPath];
    [atMentionCell customSetSelected:YES animated:NO];
    
    //perform an insert action
    UITextView *textView = composeBarView.textView;
    
    UITextPosition *beginning = textView.beginningOfDocument;
    UITextPosition *start = [textView positionFromPosition:beginning offset:_atMentionStartsAtThisIndex+1];
    UITextPosition *end = textView.selectedTextRange.start;

    UITextRange *textRange = [textView textRangeFromPosition:start toPosition:end];
    
    //[textView  textRangeFromPosition:textView.selectedTextRange.start toPosition:_atMentionStartsAtThisIndex+1];
    
    SWUser *user = [atMentionCell getUser];
    
    NSString *replaceString = [NSString stringWithFormat:@"%@ ", [user getAutoCompleteKey:YES]];
 
    [textView replaceRange:textRange withText:replaceString];
    
}

-(UICollectionViewCell*)collectionView:(UICollectionView *)collectionView cellForItemAtIndexPath:(NSIndexPath *)indexPath
{
    SWAtMentionCell *atMentionCell = (SWAtMentionCell*)[_autoCompleteCollectionView dequeueReusableCellWithReuseIdentifier:@"SWAtMentionCell" forIndexPath:indexPath];
    [atMentionCell setUser:_autoCompleteData[indexPath.row] isPublic:YES];
    return atMentionCell;
}

-(CGSize)collectionView:(UICollectionView *)collectionView layout:(UICollectionViewLayout *)collectionViewLayout sizeForItemAtIndexPath:(NSIndexPath *)indexPath
{
    return CGSizeMake(320, kAutoCompleteCellHeight);
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

@end
