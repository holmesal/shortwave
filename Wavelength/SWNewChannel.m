//
//  SWNewChannel.m
//  Shortwave
//
//  Created by Ethan Sherr on 9/3/14.
//  Copyright (c) 2014 Ethan Sherr. All rights reserved.
//

#import "SWNewChannel.h"
#import "UIColor+HexString.h"
#import "ObjcConstants.h"
#import <Mixpanel/Mixpanel.h>


#define TIME_DELAY 0.85f
#define maxCharsInChannelName 20
#define maxCharsInDescription 80

@interface SWNewChannel () <UITextFieldDelegate, UITextViewDelegate>

@property (weak, nonatomic) IBOutlet UIScrollView *scrollView;
@property (weak, nonatomic) IBOutlet UIActivityIndicatorView *activityIndicator;
@property (weak, nonatomic) IBOutlet NSLayoutConstraint *createButtonBottomConstraint;
@property (weak, nonatomic) IBOutlet UILabel *navBarLabel;
@property (weak, nonatomic) IBOutlet UIView *fakeNavBar;
@property (weak, nonatomic) IBOutlet UIButton *goButton;

@property (weak, nonatomic) IBOutlet UILabel *channelNameCharacterCountLabel;
@property (weak, nonatomic) IBOutlet UILabel *hashTagLabel;
@property (weak, nonatomic) IBOutlet UITextField *channelNameTextField;
@property (weak, nonatomic) IBOutlet UIView *descriptionViewContainer;
@property (weak, nonatomic) IBOutlet UILabel *descriptionLabel;
@property (weak, nonatomic) IBOutlet NSLayoutConstraint *descriptionLabelHeightConstraint;

@property (weak, nonatomic) IBOutlet UILabel *descriptionPlaceholderLabel;
@property (weak, nonatomic) IBOutlet UIView *createDescriptionContainer;
@property (weak, nonatomic) IBOutlet UITextView *createDescriptionTextView;
@property (weak, nonatomic) IBOutlet NSLayoutConstraint *heightOfDescription;
@property (weak, nonatomic) IBOutlet UILabel *descriptionCharacterCountLabel;
@property (weak, nonatomic) IBOutlet NSLayoutConstraint *topVerticalSpaceFromDescriptionTVToSuper;
@property (weak, nonatomic) IBOutlet NSLayoutConstraint *verticalSpaceFromDescriptionTVToSuper;//bottom

@property (strong, nonatomic) NSString *channelName; //init to @""
@property (assign, nonatomic) NSNumber* channelNameExists;//has didSet
@property (assign, nonatomic) BOOL isJoining;
@property (strong, nonatomic) NSTimer *timer; //optional


@property (strong, nonatomic) NSNumber *temporaryChannelNameExists;
@property (strong, nonatomic) NSString *joiningDescriptionString;



@end

@implementation SWNewChannel

@synthesize channelNameExists;
-(void)setChannelNameExists:(NSNumber*)newValue
{
    channelNameExists = newValue;
    //didSet
    {
        if (channelNameExists == nil)
        {
            self.activityIndicator.hidden = NO;
            self.goButton.backgroundColor = [UIColor colorWithWhite:205/255.0f alpha:1.0f];
            [self.goButton setTitleColor:[UIColor colorWithWhite:229/255.0f alpha:1.0f] forState:UIControlStateNormal];
            self.goButton.userInteractionEnabled = NO;
        } else
        {
            self.activityIndicator.hidden = YES;
            self.goButton.backgroundColor = [UIColor colorWithHexString:Objc_kNiceColors[@"green"]];
            [self.goButton setTitleColor:[UIColor colorWithWhite:229/255.0f alpha:1.0f] forState:UIControlStateNormal];
            self.goButton.userInteractionEnabled = YES;
        }
    }
}


-(void)viewDidLoad
{
    [super viewDidLoad];
    self.channelName = @"";
    
    self.scrollView.contentSize = CGSizeMake(0, 301);
    
    UIView *whiteLine = [[UIView alloc] initWithFrame:CGRectMake(87, 25, 0.5f, 48.0f)];
    whiteLine.backgroundColor = [UIColor whiteColor];
    [self.fakeNavBar addSubview:whiteLine];
    
    [self.createDescriptionTextView addObserver:self forKeyPath:@"contentSize" options:NSKeyValueObservingOptionNew context:nil];
    
    NSString *clr = @"green";
    self.createDescriptionTextView.tintColor = [UIColor colorWithHexString:Objc_kNiceColors[clr] ];
    self.channelNameTextField.tintColor = [UIColor colorWithHexString:Objc_kNiceColors[clr] ];
    
    [self.channelNameTextField becomeFirstResponder];
    
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(keyboardWillToggle:) name:UIKeyboardWillShowNotification object:nil];
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(keyboardWillToggle:) name:UIKeyboardWillHideNotification object:nil];
    
    NSString *hexString = Objc_kNiceColors[@"bar"];
    self.fakeNavBar.backgroundColor = [UIColor colorWithHexString:hexString];
    self.descriptionViewContainer.alpha = 0.0f;
    
    self.navBarLabel.font = [UIFont fontWithName:@"Avenir-Book" size:15];
    self.navBarLabel.textColor = [UIColor whiteColor];
    
    self.scrollView.alwaysBounceVertical = YES;
    self.channelNameTextField.delegate = self;
    self.createDescriptionTextView.delegate = self;
    self.createDescriptionTextView.backgroundColor = [UIColor clearColor];
    
    [self createInputLayer];
    [self updateUITimer];
    
    self.activityIndicator.hidden = YES;
}

-(void)viewDidAppear:(BOOL)animated
{
    [super viewDidAppear:animated];
    [[Mixpanel sharedInstance] track:@"Add Channel Open"];
}

-(void)createInputLayer
{
    CGFloat insetVertical = 5.0f;
    CGFloat insetHorizontal = 5.0f;
    
    CGSize textViewSize = self.createDescriptionTextView.frame.size;
    CALayer *layer = [CALayer layer];
    
    CGRect frame = self.createDescriptionTextView.frame;
    frame.origin.y = -(insetVertical);
    frame.origin.x = -(insetHorizontal);
    frame.size.width = 2*insetHorizontal + frame.size.width;
    frame.size.height = 2*insetVertical + frame.size.height;
    
    layer.frame = frame;
    
    layer.cornerRadius = 3.0f;
    layer.borderColor = UIColor.redColor.CGColor;
    layer.borderWidth = 0.5f;
    layer.backgroundColor = [UIColor colorWithRed:1.0f green:1.0f blue:1.0f alpha:1.0f].CGColor;
    
    [self.createDescriptionTextView.layer insertSublayer:layer atIndex:0];
    
}


-(IBAction)completeButtonAction:(id)sender
{
    self.goButton.userInteractionEnabled = NO;
    
    [self performFirebaseFetchForChannel:self.channelName result:^(BOOL exists, NSString *descrption)
    {
        if (exists)
        {
            [self joinChannel];
        } else
        {
            [self createChannel];
        }
    }];
}


-(IBAction)cancelButtonAction:(id)sender
{
    if (sender)
    {
        [[Mixpanel sharedInstance] track:@"Add Channel Cancel"];
    }

    [self dismissViewControllerAnimated:YES completion:^
    {
        if (self.isJoining)
        {
            [self.channelViewController openChannelForChannelName:self.channelName];
        }
    }];
}

-(void)performFirebaseFetchForChannel:(NSString*)channel result:(void (^)(BOOL exists, NSString *description))result
{
    Firebase *channelExistenceFetch = [[Firebase alloc] initWithUrl:[NSString stringWithFormat:@"%@channels/%@/meta", Objc_kROOT_FIREBASE, channel]];
    NSLog(@"channel fetch %@", channelExistenceFetch);
    
    [channelExistenceFetch observeSingleEventOfType:FEventTypeValue withBlock:^(FDataSnapshot *snapshot){
        if ([snapshot.value isKindOfClass: [NSDictionary class]])
        {
            NSDictionary *meta = snapshot.value;
            NSString *description = meta[@"description"];
            result(YES, description);
        } else
        {
            result(NO, nil);
        }
    
    } withCancelBlock:^(NSError *error)
    {
        NSLog(@"error lskfj = %@", error);
    }];
}


-(BOOL)textFieldShouldReturn:(UITextField *)textField
{
    [self completeButtonAction:nil];
    return YES;
}

@synthesize temporaryChannelNameExists;
@synthesize joiningDescriptionString;
-(BOOL)textField:(UITextField *)textField shouldChangeCharactersInRange:(NSRange)range replacementString:(NSString *)string
{
    NSString *result = [[textField.text stringByReplacingCharactersInRange:range withString:string] lowercaseString];
    
    NSArray *illegalCharacters = @[@"$", @"[", @"]", @"/", @".", @"#"];
    for (NSString *c in illegalCharacters)
    {
        result = [result stringByReplacingOccurrencesOfString:c withString:@""];
    }
    result = [result stringByReplacingOccurrencesOfString:@" " withString:@"-"];
    self.hashTagLabel.highlighted = result.length != 0;
    
    if (result.length > maxCharsInChannelName)
    {
        return NO;
    }
    
    self.channelNameCharacterCountLabel.text = [NSString stringWithFormat:@"%d / %d", result.length, maxCharsInChannelName];
    
    if (self.timer != nil)
    {
        [self.timer invalidate];
        self.timer = nil;
    }
    self.channelName = result;
    self.channelNameExists = nil;
    self.temporaryChannelNameExists = nil;
    [self animateDescriptionContainer:self.descriptionViewContainer visible:NO];
    [self animateDescriptionContainer:self.createDescriptionContainer visible:NO];
    
    if (result.length == 0)
    {
        self.activityIndicator.hidden = YES;
    }
    NSTimeInterval timeRequestStarted = [[NSDate date] timeIntervalSince1970];
    
    [self performFirebaseFetchForChannel:result result:^(BOOL exists, NSString *description)
    {
        NSLog(@"channel %@ exists ? %d", result, exists );
        
        self.joiningDescriptionString = description;
        if (self.channelName == result)
        {
            self.temporaryChannelNameExists = [NSNumber numberWithBool:exists];
            
            NSTimeInterval elapsedTimeOfRequest = [[NSDate date] timeIntervalSince1970] - timeRequestStarted;
            NSTimeInterval timeRemaining = TIME_DELAY - elapsedTimeOfRequest;
            
            if (timeRemaining > 0)
            {
                self.timer = [NSTimer timerWithTimeInterval:timeRemaining target:self selector:@selector(updateUITimer) userInfo:nil repeats:NO];
                [[NSRunLoop mainRunLoop] addTimer:self.timer forMode:NSDefaultRunLoopMode];
            } else
            {
                [self updateUITimer];
            }
        }
        
    }];
    
    textField.text = result;
    return NO;
    
}

-(void)updateUITimer
{
    if (self.timer)
    {
        [self.timer invalidate];
        self.timer = nil;
    }
    
    self.channelNameExists = self.temporaryChannelNameExists;
    
    if ([self.channelName isEqualToString:@""]) //invalid
    {
        
    } else
    if (self.channelNameExists && ![self.channelNameExists boolValue])
    {
        [self animateDescriptionContainer:self.descriptionViewContainer visible:NO];
        [self animateDescriptionContainer:self.createDescriptionContainer visible:YES];
        
        [self.goButton setTitle:@"Create" forState:UIControlStateNormal];
        self.goButton.alpha = 1.0f;
    } else
    {
        [self animateDescriptionContainer:self.createDescriptionContainer visible:NO];
        if (self.joiningDescriptionString)
        {
            self.descriptionLabel.text = self.joiningDescriptionString;
            NSDictionary *attributes = @{NSFontAttributeName : self.descriptionLabel.font};
            CGSize actualSize = [self.joiningDescriptionString boundingRectWithSize:CGSizeMake(self.descriptionLabel.frame.size.width, 300) options:NSStringDrawingUsesLineFragmentOrigin attributes:attributes context:nil].size;
            
            [self animateDescriptionContainer:self.descriptionLabel visible:YES];
        } else
        {
            [self animateDescriptionContainer:self.descriptionViewContainer visible: NO];
        }
        
        [self.goButton setTitle:@"Join" forState:UIControlStateNormal];
        self.goButton.alpha = 1.0f;
        
    }
    
}

-(void)animateDescriptionContainer:(UIView*)descContainer visible:(BOOL)visible
{
    if ((visible && descContainer.alpha == 1.0f) || (!visible && descContainer.alpha == 0.0f))
    {
        return;
    }
    
    descContainer.alpha = visible ? 0.0f : 1.0f;
    [UIView animateWithDuration:0.4 animations:^
    {
        descContainer.alpha = visible ? 1.0f : 0.0f;
    }];
}

-(void)joinChannel
{
    void (^mixpanelErrorReport)(NSError *error) = ^(NSError *error)
    {
        [[Mixpanel sharedInstance] track:@"Add Channel Error" properties:
            @{@"code": [NSNumber numberWithInt:error.code],
              @"error": error.localizedDescription,
              @"isCreate": @NO,
              @"channel": self.channelName}];
    };
    
    NSString *userId = [[NSUserDefaults standardUserDefaults] objectForKey:Objc_kNSUSERDEFAULTS_KEY_userId];
    Firebase *membersFB = [[Firebase alloc] initWithUrl:[NSString stringWithFormat:@"%@channels/%@/members/%@/", Objc_kROOT_FIREBASE, self.channelName, userId]];
    
    [membersFB setValue:@YES withCompletionBlock:^(NSError *error, Firebase *firebase)
    {
        if (error)
        {
            mixpanelErrorReport(error);
            NSLog(@"error adding myself to channel %@", error);
        } else
        {
            Firebase *myChannels = [[Firebase alloc] initWithUrl:[NSString stringWithFormat:@"%@users/%@/channels/%@", Objc_kROOT_FIREBASE, userId, self.channelName]];
            [myChannels setValue:@{@"lastSeen":@0, @"muted":@NO} andPriority:[NSNumber numberWithDouble:[[NSDate date] timeIntervalSince1970] *1000] withCompletionBlock:^(NSError *error, Firebase *firebase)
            {
                if (error)
                {
                    mixpanelErrorReport(error);
                    NSLog(@"error getting my user to join channel %@", error);
                } else
                {
                    [[Mixpanel sharedInstance] track:@"Add Channel" properties:@{@"channel": self.channelName, @"isCreate": @NO} ];
                    self.isJoining = YES;
                    [self cancelButtonAction:nil];
                }
            }];
        }
    }];
}

-(void)createChannel
{
    void (^mixpanelErrorReport)(NSError *error) = ^(NSError *error)
    {
        [[Mixpanel sharedInstance] track:@"Add Channel Error" properties:
         @{@"code": [NSNumber numberWithInt:error.code],
           @"error": error.localizedDescription,
           @"isCreate": @YES,
           @"channel": self.channelName}];
    };
    NSString *userId = [[NSUserDefaults standardUserDefaults] objectForKey:Objc_kNSUSERDEFAULTS_KEY_userId];
    
    NSDictionary *value = @{@"moderators": @{userId: @YES},
                            @"members": @{userId: @YES},
                            @"meta":
                                    @{@"public": @YES,
                                      @"description": self.createDescriptionTextView.text}
                            };
    Firebase *channelRoot = [[Firebase alloc] initWithUrl:[NSString stringWithFormat:@"%@channels/%@", Objc_kROOT_FIREBASE, self.channelName]];
    [channelRoot setValue:value withCompletionBlock:^(NSError *error, Firebase *firebase)
    {
        if (error)
        {
            mixpanelErrorReport(error);
        } else
        {
            NSTimeInterval t = [[NSDate date] timeIntervalSince1970]*1000;
            NSNumber *priority = [NSNumber numberWithDouble:t];
            Firebase *yourChannels = [[Firebase alloc] initWithUrl:[NSString stringWithFormat:@"%@users/%@/channels/%@", Objc_kROOT_FIREBASE, userId, self.channelName]];
            [yourChannels setValue:@{@"lastSeen":@0, @"muted":@NO} andPriority:priority withCompletionBlock:^(NSError *error, Firebase *firebase)
            {
                if (error)
                {
                    mixpanelErrorReport(error);
                } else
                {
                    [[Mixpanel sharedInstance] track:@"Add Channel" properties:@{@"channel": self.channelName, @"isCreate": @YES}];
                    self.isJoining = YES;
                    [self cancelButtonAction:nil];
                }
            }];
            
            
        }
    }];
    
}


-(BOOL)textView:(UITextView *)textView shouldChangeTextInRange:(NSRange)range replacementText:(NSString *)text
{
    if (textView == self.createDescriptionTextView)
    {
        NSString *result = [[textView.text stringByReplacingCharactersInRange:range withString:text] lowercaseString];
        if (result.length > maxCharsInDescription)
        {
            return NO;
        }
        
        self.descriptionPlaceholderLabel.hidden = result.length != 0;
        self.descriptionCharacterCountLabel.text = [NSString stringWithFormat:@"%d / %d", result.length, maxCharsInDescription];
        
        if ([text isEqualToString:@"\n"])
        {
            [self completeButtonAction:nil];
            return NO;
        }
        
    }
    return YES;
}

-(void)dealloc
{
    [self.createDescriptionTextView removeObserver:self forKeyPath:@"contentSize"];
    [[NSNotificationCenter defaultCenter] removeObserver:self];
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
        self.createButtonBottomConstraint.constant = constraintHeight;
    } else
    {
        [UIView animateWithDuration:0.3f delay:0.0f options:(UIViewAnimationOptionBeginFromCurrentState | animationCurve << 16) animations:^
        {
            self.createButtonBottomConstraint.constant = constraintHeight;
            [self.goButton.superview layoutIfNeeded];
        } completion:^(BOOL finished){}];
    }
    
}



-(void)observeValueForKeyPath:(NSString *)keyPath ofObject:(id)object change:(NSDictionary *)change context:(void *)context
{
    if ([keyPath isEqualToString:@"contentSize"] && object == self.createDescriptionTextView)
    {
        CGFloat newHeight = self.createDescriptionTextView.contentSize.height;
        newHeight = MIN(newHeight, 100.0f);
        self.heightOfDescription.constant = self.topVerticalSpaceFromDescriptionTVToSuper.constant + self.verticalSpaceFromDescriptionTVToSuper.constant + newHeight;
        
    }
}



@end
