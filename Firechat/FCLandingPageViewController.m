//
//  FCLandingPageViewController.m
//  Firechat
//
//  Created by Ethan Sherr on 3/17/14.
//  Copyright (c) 2014 Buildco. All rights reserved.
//

#import "FCLandingPageViewController.h"
#import "FCLiveBlurButton.h"
#import "FCAppDelegate.h"
#import "FCWallViewController.h"
#import <Mixpanel/Mixpanel.h>
#import "ESSwapUserStateMessage.h"
#import "UIImage+Resize.h"
#import "RadarView.h"
#import "UIImage+ImageEffects.h"
#import "UIImage+Resize.h"

typedef enum
{
    PanGestureDirectionNone,
    PanGestureDirectionUp,
    PanGestureDirectionDown,
    PanGestureDirectionLeft,
    PanGestureDirectionRight
}PanGestureDirection;

@interface FCLandingPageViewController () <UITableViewDataSource, UITableViewDelegate, UIAlertViewDelegate, UIGestureRecognizerDelegate>

@property (nonatomic) BOOL hasBeenHereBefore;////this is to fade in the view after splash screen is gone
@property (nonatomic) Firebase *tracking;
@property (nonatomic) BOOL circleIsBouncing;

@property (nonatomic) int alternateBounceCounter;
@property (nonatomic) NSTimer *circleBounceTimer;

@property (strong, nonatomic) UIButton *leftCircleButton;
@property (strong, nonatomic) UIButton *rightCircleButton;

@property (strong, nonatomic) CALayer *rightCircleLayer;;
@property (strong, nonatomic) CALayer *leftCircleLayer;
@property (weak, nonatomic)  IBOutlet UIView *leftCircleColorView;
@property (weak, nonatomic)  IBOutlet UIView *rightCircleColorView;


@property (weak, nonatomic) IBOutlet UILabel *attributionLabel;
@property (nonatomic) CGRect originalFrameForIcon;
@property (nonatomic) NSInteger selectedIconIndex;
@property (nonatomic) UIImageView *extractedImageViewOnDone;
@property (weak, nonatomic) IBOutlet UIView *welcomeView2;
@property (weak, nonatomic) IBOutlet UILabel *welcomeLabel;


//vars for searching view
@property (weak, nonatomic) IBOutlet UIView *searchingView;
@property (assign, nonatomic) NSInteger elipseCount;
@property (strong, nonatomic) NSTimer *searchingElipseTimer;
@property (weak, nonatomic) IBOutlet UILabel *searchingLabel;
@property (weak, nonatomic) IBOutlet UILabel *numberPeopleNearbyLabel;
@property (weak, nonatomic) IBOutlet UILabel *peopleNearbyGrammarLabel;
@property (weak, nonatomic) IBOutlet FCLiveBlurButton *composeBlurButton;
@property (weak, nonatomic) IBOutlet UILabel *sendEarshotLabel;


@property (strong, nonatomic) RadarView *radarView;



@property (weak, nonatomic) IBOutlet FCLiveBlurButton *startTalkingBlurButton;

@property (nonatomic) PanGestureDirection panDirection;
@property (nonatomic) UIPanGestureRecognizer *panGesture;
@property (nonatomic) NSInteger colorIndex;

@property (nonatomic) CGPoint offsetOfTableViewAtStartOfVertical;
@property (nonatomic) BOOL stateChanged;

@property (weak, nonatomic) IBOutlet UIImageView *spinnerImageView;

@property (nonatomic) UITableView *iconTableView;
@property (strong, nonatomic) UIView *iconContainerView;
@property (nonatomic) NSInteger iconIndex;

@property (nonatomic) NSArray *icons;
@property (nonatomic) NSArray *colors;

@property Mixpanel *mixpanel;
@property (nonatomic) BOOL beganShowingSearchingView;

@property (nonatomic) FirebaseSimpleLogin *authClient;
@property (weak, nonatomic) IBOutlet FCLiveBlurButton *doneBlurButton;

@end



@implementation FCLandingPageViewController

@synthesize searchingElipseTimer;
@synthesize elipseCount;

@synthesize tracking;
@synthesize beganShowingSearchingView;
@synthesize circleBounceTimer;
@synthesize welcomeView2;
@synthesize startTalkingBlurButton;
@synthesize radarView;

@synthesize hasBeenHereBefore;
@synthesize colorIndex;
@synthesize panDirection;

@synthesize iconIndex;

@synthesize icons;
@synthesize iconTableView;

@synthesize doneBlurButton;
@synthesize colors;

@synthesize leftCircleButton, rightCircleButton;


-(BOOL)userIsLoggedIn
{
    NSLog(@"userIsLoggedIn = %@", ([[NSUserDefaults standardUserDefaults] boolForKey:@"isLoggedIn"] ? @"YES": @"NO"));
    return [[NSUserDefaults standardUserDefaults] boolForKey:@"isLoggedIn"];
}
-(void)setUserIsLoggedIn:(BOOL)b
{
    [[NSUserDefaults standardUserDefaults] setBool:b forKey:@"isLoggedIn"];
    [[NSUserDefaults standardUserDefaults] synchronize];
}


-(void)reanimate
{
    NSLog(@"reanimate");
    [self.spinnerImageView.layer removeAllAnimations];
    
//    [UIView animateWithDuration:40.0f
//                          delay:0.0f
//                        options:UIViewAnimationOptionRepeat | UIViewAnimationOptionCurveLinear
//                     animations:^{
//                         self.spinnerImageView.transform = CGAffineTransformMakeRotation(M_PI);
//                     }
//                     completion:nil
//     ];


    CABasicAnimation *animation = [CABasicAnimation animationWithKeyPath:@"opacity"];
    
    animation.fromValue       = @0.0f;
    animation.toValue         = @(M_PI*2);
    animation.duration        = 40.0f;
    animation.timingFunction  = [CAMediaTimingFunction functionWithName:kCAMediaTimingFunctionLinear];
    animation.autoreverses    = NO;
    animation.repeatCount     = HUGE_VALF;
    animation.keyPath = @"transform.rotation.z";

    [[self.spinnerImageView layer] addAnimation:animation forKey:@"transform.rotation.z"];
}

- (void)viewDidLoad
{
    [super viewDidLoad];


    
    //initialize the circle things
    {
        
        
        
        
        CGRect circleFrame = self.rightCircleColorView.bounds;
        
        self.leftCircleLayer = [CALayer layer];
        [self.leftCircleLayer setBackgroundColor:[UIColor clearColor].CGColor];
        [self.leftCircleLayer setBorderColor:[UIColor whiteColor].CGColor];
        [self.leftCircleLayer setBorderWidth:0.9f];
        [self.leftCircleLayer setCornerRadius:self.leftCircleColorView.frame.size.width*0.5f];
        [self.leftCircleLayer setFrame:circleFrame];
        
        [self.leftCircleColorView.layer addSublayer:self.leftCircleLayer];
        
        
        [self performSelector:@selector(circleBounceTimerAction:) withObject:nil afterDelay:1.0f];
        
        self.rightCircleLayer = [CALayer layer];
        [self.rightCircleLayer setBackgroundColor:[UIColor clearColor].CGColor];
        [self.rightCircleLayer setBorderColor:[UIColor whiteColor].CGColor];
        [self.rightCircleLayer setBorderWidth:0.9f];
        [self.rightCircleLayer setCornerRadius:self.rightCircleColorView.frame.size.width*0.5f];
        [self.rightCircleLayer setFrame:circleFrame];
        [self.rightCircleColorView.layer addSublayer:self.rightCircleLayer];
        
        [self.leftCircleColorView setBackgroundColor:[UIColor clearColor]];
        [self.rightCircleColorView setBackgroundColor:[UIColor clearColor]];
        [self.leftCircleColorView setClipsToBounds:NO];
        [self.rightCircleColorView setClipsToBounds:NO];
        
    }
    
//    CGSize sizeOfIcon = {160.0f, 160.0f};
    CGRect iconContainerViewRect = self.spinnerImageView.frame;//CGRectMake((self.view.frame.size.width - sizeOfIcon.width)*0.5f, (self.view.frame.size.height-sizeOfIcon.height)*0.5f, sizeOfIcon.width, sizeOfIcon.height);
    CGFloat topInset = 31+30-19;
    CGFloat bottomInset = 568-478;
    iconContainerViewRect.origin.y = (([UIScreen mainScreen].bounds.size.height - topInset - bottomInset) - iconContainerViewRect.size.height)*0.5f;
    iconContainerViewRect.origin.y += topInset;
    
    
    self.iconContainerView = [[UIView alloc] initWithFrame:iconContainerViewRect];
    [self.view addSubview:self.iconContainerView];
    
    
    
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(appDidBecomeActive:) name:UIApplicationDidBecomeActiveNotification object:nil];
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(appDidEnterForeground:) name:UIApplicationWillEnterForegroundNotification object:nil];
    
    self.mixpanel = [Mixpanel sharedInstance];
    
    
    //hide welcomeVIew2
    [welcomeView2 setBackgroundColor:[UIColor clearColor]];
    [welcomeView2 setHidden:YES];
    [self.searchingView setHidden:YES];
    [self.searchingView setBackgroundColor:[UIColor clearColor]];
    [self.composeBlurButton setBackgroundColor:[UIColor clearColor]];
    [self.composeBlurButton setRadius:self.composeBlurButton.frame.size.width/2];
    [self.composeBlurButton addTarget:self action:@selector(composeBlurButtonAction) forControlEvents:UIControlEventTouchUpInside];
    
    [startTalkingBlurButton setRadius:startTalkingBlurButton.frame.size.width/2.0f];
    [startTalkingBlurButton addTarget:self action:@selector(startTalkingBlurButtonAction) forControlEvents:UIControlEventTouchUpInside];
    

                        //     blue       purps      red        orng      yellow   realgreen//   seagreen
    NSArray *colorsHex = @[@"4F92E0", @"AB4EFE", @"EF4F4F" ,@"F1793A", @"FBB829",  @"00CF69"];// @"0074D9"];
    NSMutableArray *colorsMutable = [[NSMutableArray alloc] init];
    for (NSString *hexColor in colorsHex)
    {
        [colorsMutable addObject:[UIColor colorWithHexString:hexColor]];
    }
    
    colors = [NSArray arrayWithArray:colorsMutable];
    
 
    self.icons = @[@{@"name":@"1", @"attribution":@"John Caserta"}, //cloud
                   @{@"name":@"2", @"attribution":@"Jardson A."}, //person
                   @{@"name":@"3", @"attribution":@"Yuko Iwai"}, //balloon
                   @{@"name":@"4", @"attribution":@"Mister Pixel"},
                   @{@"name":@"5", @"attribution":@"Edward Boatman"},
                   @{@"name":@"6", @"attribution":@"Antonis Makriyannis"},
                   @{@"name":@"7", @"attribution":@"Yaroslav Samoilov"},
                   @{@"name":@"8", @"attribution":@"Pedro Vidal"}, //sun
                   @{@"name":@"9", @"attribution":@"Daniel Gamage"}, //stunners
                   @{@"name":@"10", @"attribution":@"Jacob Thompson"}, //cherries
                   @{@"name":@"11", @"attribution":@"José Manuel de Laá"}, //diamond
                   @{@"name":@"12", @"attribution":@"Nick Abrams"}, //lightbulb
                   @{@"name":@"13", @"attribution":@"Nick Abrams"}, //dish
                   @{@"name":@"14", @"attribution":@"Christopher T. Howlett"}, //pineapple
                   @{@"name":@"15", @"attribution":@"Agarunov Oktay-Abraham"}, //burger
                   @{@"name":@"16", @"attribution":@"José Manuel de Laá"}, //backetball
                   @{@"name":@"17", @"attribution":@"Kelig Le Luron"}, //moon
                   @{@"name":@"18", @"attribution":@"Maxim Cherenkovsky"}, //snowflake
                   @{@"name":@"19", @"attribution":@"Patrick Morrison"}, //chicken leg
                   @{@"name":@"20", @"attribution":@"Jan-Kanty Pawelski"}, //pacman
                   @{@"name":@"21", @"attribution":@"Matthew Clarke"}, //chef
                   @{@"name":@"22", @"attribution":@"Christopher T. Howlett"} //flask
                   ];
# pragma mark Ethan match these to icons via an attribution at the bottom of the screen
//    self.iconAttributions = @[@"FIND THIS1", @"FIND THIS2", @"FIND THIS3", @"FIND THIS4"];//, @"Edward Boatman", @"Antonis Makriyannis", @"Yaroslav Samoilov"];
    
    // Mixpanel init
    [self.mixpanel track:@"Icon/color select screen loaded" properties:@{@"loggedIn": ([self userIsLoggedIn]?@"true":@"false") }];
    
    int randIcon = 0;//esRandomNumberIn(0, icons.count);
    
    if ([self userIsLoggedIn])
    {
        NSString *icon = [[NSUserDefaults standardUserDefaults] objectForKey:@"icon"];
        
        NSPredicate *predicate = [NSPredicate predicateWithFormat:@"SELF.name == %@", icon];
        id theObject = [[self.icons filteredArrayUsingPredicate:predicate] lastObject];
        
        int index = (int)[self.icons indexOfObject:theObject];
        self.selectedIconIndex = index;
        randIcon = index;
    }
    [self setIconIndex:randIcon];
    
    NSString *attribution = [[self.icons objectAtIndex:self.iconIndex] objectForKey:@"attribution"];
    [self.attributionLabel setText:[NSString stringWithFormat:@"Icon by %@", attribution]];//[[self.icons objectAtIndex:self.iconIndex] objectForKey:@"attribution"]];

    CGFloat heightOfFadedArea = self.cellHeight;//self.cellHeight;//self.cellHeight; //180;
    CGRect rect = self.iconContainerView.bounds;
    rect.origin.y -= self.cellHeight;
    rect.size.height += 2*self.cellHeight;//2*heightOfFadedArea;
    iconTableView = [[UITableView alloc] initWithFrame:rect style:UITableViewStylePlain];
    [iconTableView setBackgroundColor:[UIColor clearColor]];
    [self.iconContainerView setClipsToBounds:NO];
    [self.iconContainerView setBackgroundColor:[UIColor clearColor]];
    [iconTableView setSeparatorColor:[UIColor clearColor]];
    [iconTableView setShowsVerticalScrollIndicator:NO];
//    [iconTableView setScrollEnabled:NO]
    
    [iconTableView setUserInteractionEnabled:NO];
    

    UIButton *top = [UIButton buttonWithType:UIButtonTypeCustom];

    [top setFrame:CGRectMake(
                             self.iconContainerView.frame.origin.x,
                             self.iconContainerView.frame.origin.y-self.cellHeight,
                             iconTableView.frame.size.width,
                             self.cellHeight)];
    [self.view insertSubview:top aboveSubview:self.iconContainerView];
    
    UIButton *mid = [UIButton buttonWithType:UIButtonTypeCustom];

    [mid setFrame:CGRectMake(
                             self.iconContainerView.frame.origin.x,
                             self.iconContainerView.frame.origin.y,
                             iconTableView.frame.size.width,
                             self.cellHeight)];
    [self.view insertSubview:mid aboveSubview:self.iconContainerView];
    
    UIButton *bottom = [UIButton buttonWithType:UIButtonTypeCustom];
    
    [bottom setFrame:CGRectMake(
                             self.iconContainerView.frame.origin.x,
                             self.iconContainerView.frame.origin.y+self.cellHeight,
                             iconTableView.frame.size.width,
                             self.cellHeight)];
    [self.view insertSubview:bottom aboveSubview:self.iconContainerView];
    
//    [top setBackgroundColor:[UIColor colorWithRed:1 green:0 blue:0 alpha:0.2f]];
//    [mid setBackgroundColor:[UIColor colorWithRed:0 green:1 blue:0 alpha:0.2f]];
//    [bottom setBackgroundColor:[UIColor colorWithRed:0 green:0 blue:1 alpha:0.2f]];
    
    
    top.tag = -1;
    mid.tag = 0;
    bottom.tag = 1;
    [top addTarget:self action:@selector(tapIcon:) forControlEvents:UIControlEventTouchUpInside];
    [mid addTarget:self action:@selector(tapIcon:) forControlEvents:UIControlEventTouchUpInside];
    [bottom addTarget:self action:@selector(tapIcon:) forControlEvents:UIControlEventTouchUpInside];
    
    [self.searchingView setUserInteractionEnabled:NO];
    
//    [iconTableView setBackgroundColor:[UIColor colorWithRed:1 green:0 blue:0 alpha:0.2f]];
    
    [iconTableView setContentOffset:CGPointMake(0, self.iconIndex*self.cellHeight)];
    
    {
        //create my mask layer
        
        CALayer *layer = [CALayer layer];
        [layer setBackgroundColor:[UIColor clearColor].CGColor];
        layer.frame = self.iconTableView.frame;
        
        
        CALayer *centerSqr = [CALayer layer];
        [centerSqr setBackgroundColor:[UIColor whiteColor].CGColor];
        CGRect centerRct = self.spinnerImageView.bounds;
        centerRct.origin.y += heightOfFadedArea;
        centerSqr.frame = centerRct;
        [layer addSublayer:centerSqr];
        
        //image layer
        CALayer *topFade = [CALayer layer];
        [topFade setFrame:CGRectMake(0, 0, centerSqr.frame.size.width, heightOfFadedArea)];
        UIImage *image = [UIImage imageNamed:@"icongradient.png"];
        UIImage *scaledImg = [image scaleToSize:CGSizeMake(topFade.frame.size.width, topFade.frame.size.height)];
        [topFade setContentsScale:[UIScreen mainScreen].scale];
        [topFade setContents:(id)scaledImg.CGImage];
        [topFade setTransform:CATransform3DMakeRotation(M_PI, 0, 0, 1)];
        [layer addSublayer:topFade];

        
        CALayer *bottomFade = [CALayer layer];
        [bottomFade setFrame:CGRectMake(0, heightOfFadedArea+centerSqr.frame.size.height, centerSqr.frame.size.width, heightOfFadedArea)];
        [bottomFade setTransform:CATransform3DMakeRotation(0, 0, 0, 1)];
        [bottomFade setContentsScale:[UIScreen mainScreen].scale];
        [bottomFade setContents:(id)scaledImg.CGImage];
        
        
        [layer addSublayer:bottomFade];
        
        
//        [self.iconContainerView.layer addSublayer:layer];
        self.iconContainerView.layer.mask = layer;
    
    }
    
    
    iconTableView.delegate = self;
    iconTableView.dataSource = self;
    
    [self.iconContainerView addSubview:iconTableView];
    [self.iconContainerView setClipsToBounds:NO];

    colorIndex = 0;//esRandomNumberIn(0, self.colors.count);
    
    if ([self userIsLoggedIn])
    {
        NSString *color = [[NSUserDefaults  standardUserDefaults] objectForKey:@"color"];
        
//        NSPredicate *predicate = [NSPredicate predicateWithFormat:@"(SELF == %@)", color];
//        id theColor = [[colorsHex filteredArrayUsingPredicate:predicate] lastObject];
//        int colorIndexActually = [colorsHex indexOfObject:theColor];
//
//        colorIndex = colorIndexActually;
        UIColor *clr = [UIColor colorWithHexString:color];
        [self.view setBackgroundColor:clr];
        
    } else
    {
        [self.view setBackgroundColor:[colors objectAtIndex:colorIndex] ];
    }
    
    
    //add gesture listener pan left right
    self.panGesture = [[UIPanGestureRecognizer alloc] initWithTarget:self action:@selector(handlePan:)];
    [self.panGesture setDelegate:self];
    [self.view addGestureRecognizer:self.panGesture];
    
    
//    [self.doneBlurButton setBackgroundColor:[UIColor clearColor]];
    [self.doneBlurButton addTarget:self action:@selector(doneBlurButtonAction:) forControlEvents:UIControlEventTouchUpInside];
    [self.doneBlurButton setRadius:self.doneBlurButton.frame.size.height/2];
    
    


}
-(void)tapIcon:(UIButton*)button
{
    NSInteger tag = button.tag;
    int currentIndex = ((iconTableView.contentOffset.y)/self.cellHeight)+1;
    
    int touchedIndex = currentIndex+tag;
    
    UITableViewCell *cell = [iconTableView cellForRowAtIndexPath:[NSIndexPath indexPathForRow:touchedIndex inSection:0]];
    UIView *underView = [cell viewWithTag:4];
    underView.alpha = 1.0f;
    
    [UIView animateWithDuration:0.5f delay:0.0f options:UIViewAnimationOptionCurveEaseIn animations:^
    {
        underView.alpha = 0.0f;
    } completion:^(BOOL finished){}];
    
    //scroll to this one
//    if (tag)
//    {
//        int direction = tag;//fabsf(percent)/percent;
//        
//        int numberOfWraps = 1;//abs((int)percent);
//        numberOfWraps = MAX(1, numberOfWraps);
//        
//        
//        __block CGFloat y = self.iconTableView.contentOffset.y - direction*self.cellHeight;
//        
//        
////        
////        [UIView animateWithDuration:0.25f delay:0.0f usingSpringWithDamping:1.25f initialSpringVelocity:0 options:UIViewAnimationOptionCurveLinear animations:^
////         {
////             
////
////             [self reshuffleTableViewForOffset:y andPercent:direction];
//////             [self.iconTableView setContentOffset:CGPointMake(0, y)];
////
////             int index = y/self.cellHeight;
//////             NSDictionary *dc = [self.icons objectAtIndex:index];
//////             NSString *attribution = [dc objectForKey:@"attribution"];
//////             [self.attributionLabel setText:[NSString stringWithFormat:@"Icon by %@", attribution]];
////             self.iconIndex = iconIndex - numberOfWraps;
////             
////         } completion:^(BOOL finished)
////         {
////             
////         }];
//    }
    
    
    //end
//    NSLog(@"tag = %d", tag);
//    NSLog(@"currently %d touching index %d", currentIndex, touchedIndex);
}
-(void)initializeCircleBounceTimerIfNecessary
{
    if (circleBounceTimer)
    {
        [circleBounceTimer invalidate];
        circleBounceTimer = nil;
    }
    circleBounceTimer = [NSTimer timerWithTimeInterval:6 target:self selector:@selector(circleBounceTimerAction:) userInfo:nil repeats:YES];
    [[NSRunLoop mainRunLoop] addTimer:circleBounceTimer forMode:NSDefaultRunLoopMode];
}



#pragma mark blurActionButton callbacks
-(void)doneBlurButtonAction:(UIButton*)button
{
    
    [self continueWithDoneBlurButtonAction];
}

-(void)alertView:(UIAlertView *)alertView clickedButtonAtIndex:(NSInteger)buttonIndex
{
    if (buttonIndex)
    {
        [self doneBlurButtonAction:nil];
    }
}

-(void)continueWithDoneBlurButtonAction
{
    //extract current icon
    self.selectedIconIndex = ((iconTableView.contentOffset.y)/self.cellHeight)+1;
    
    FCUser *owner = [FCUser owner];
    
    NSString *iconIndexStr = [[icons objectAtIndex:self.selectedIconIndex] objectForKey:@"name"];
    
    
    if ([[NSUserDefaults standardUserDefaults] boolForKey:@"shouldPostSwapUserMessageWhenStateChange"])
    {
        //if state actually changed
        NSString *oldIcon = owner.icon;
        NSString *oldColor = owner.color;
        
        NSString *newIcon = iconIndexStr;
        NSString *newColor = [self.view.backgroundColor toHexString];
        if (![oldColor isEqualToString:newColor] || ![oldIcon isEqualToString:newIcon])
        {
            //post a change message
            ESSwapUserStateMessage *swapStateMessage = [[ESSwapUserStateMessage alloc] initWithOldIcon:oldIcon oldColor:oldColor newIcon:newIcon newColor:newColor];
            [swapStateMessage postMessageAsOwner];
            
        }
    }
    
    
    owner.color = [self.view.backgroundColor toHexString];
    owner.icon = iconIndexStr;
    
    [self.view removeGestureRecognizer:self.panGesture];
    
    
    
    UITableViewCell * cell = [iconTableView cellForRowAtIndexPath:[NSIndexPath indexPathForRow:self.selectedIconIndex inSection:0] ];
    UIImageView* imageView = (UIImageView*)[cell viewWithTag:5];
    [imageView setHidden:YES];
    CGRect frameForIcon = CGRectMake(self.iconContainerView.frame.origin.x, self.iconContainerView.frame.origin.y, 50, 50);
    frameForIcon.origin.x += (self.iconContainerView.frame.size.width-frameForIcon.size.width)*0.5f;
    frameForIcon.origin.y += (self.iconContainerView.frame.size.height-frameForIcon.size.height)*0.5f;
    
    self.originalFrameForIcon = frameForIcon;
    self.extractedImageViewOnDone = [[UIImageView alloc] initWithFrame:frameForIcon];
    [self.extractedImageViewOnDone setContentMode:UIViewContentModeScaleAspectFit];
    NSString *imageName = [[self.icons objectAtIndex:self.selectedIconIndex] objectForKey:@"name"];
    [self.extractedImageViewOnDone setImage:[UIImage imageNamed:imageName]];
    [self.view addSubview:self.extractedImageViewOnDone];
    

    //welcomeView2 setup centers view unhides and alpha 0 for begin animation
    [welcomeView2 setHidden:NO];
    [welcomeView2 setAlpha:1.0f];//unhide for invalidatePressedLayer on blurButton
    [welcomeView2 setBackgroundColor:self.view.backgroundColor];
//    [startTalkingBlurButton invalidatePressedLayer];
    [welcomeView2 setAlpha:0.0f];
    [welcomeView2 setBackgroundColor:[UIColor clearColor] ];
    
    [self.mixpanel track:@"Second welcome screen loaded"];
    
    __block CGRect tempFrame = welcomeView2.frame;
    tempFrame.origin.x = (self.view.frame.size.width -tempFrame.size.width)*0.5f;
    tempFrame.origin.y = (self.view.frame.size.height -tempFrame.size.height)*0.5f;
    tempFrame.origin.y += 5;
    [welcomeView2 setFrame:tempFrame];
    
    CGRect targetFrameForExtractedImageView = frameForIcon;
    targetFrameForExtractedImageView.origin.y = (self.welcomeLabel.frame.origin.y-frameForIcon.size.height)*0.5f + 8;
    
    BOOL peripheralManagerIsRunning = owner.beacon.stackIsRunning;

    
    [self.doneBlurButton setUserInteractionEnabled:NO];
    [UIView animateWithDuration:1.2f delay:0.0 usingSpringWithDamping:1.2 initialSpringVelocity:0.0f options:UIViewAnimationOptionCurveLinear animations:^
     {
         
         for (UIView *subview in self.view.subviews)
         {
             if (subview == self.doneBlurButton)
             {
                 
             } else
             if (subview == welcomeView2)
             {

             } else
             if (subview != self.extractedImageViewOnDone ) //&& subview != welcomeView2)
             {
                 subview.alpha = 0.0f;
                 subview.transform = CGAffineTransformMakeTranslation(0, 0);
             }
         }
         
         [self.iconContainerView setTransform:CGAffineTransformMakeScale(0.7, 0.7)];
         
     } completion:^(BOOL finished)
     {
         [self.iconContainerView setTransform:CGAffineTransformIdentity];
     }];
    
    
    
    [UIView animateWithDuration:1.6f delay:0.0 usingSpringWithDamping:1.2 initialSpringVelocity:0.0f options:UIViewAnimationOptionCurveLinear animations:^
     {
         if (!peripheralManagerIsRunning)
         {
             self.extractedImageViewOnDone.frame = targetFrameForExtractedImageView;
         }
     } completion:^(BOOL finished)
     {
         if (peripheralManagerIsRunning)
         {
             [self transitionToFCWallViewControllerWithImage:self.extractedImageViewOnDone.image andFrame:self.extractedImageViewOnDone.frame andColor:self.view.backgroundColor];
         } else
             //             if (!peripheralManagerIsRunning)
         {
             self.startTalkingBlurButton.alpha = 0.0f;
             [UIView animateWithDuration:1.4f delay:0.0 usingSpringWithDamping:1.2 initialSpringVelocity:0.0f options:UIViewAnimationOptionCurveLinear animations:^
              {
                  tempFrame.origin.y -= 5;
                  welcomeView2.frame = tempFrame;
                  welcomeView2.alpha = 1.0f;
                  
              } completion:^(BOOL finished)
              {
                  [startTalkingBlurButton invalidatePressedLayer];
                  self.doneBlurButton.alpha = 0.0f;
                  self.startTalkingBlurButton.alpha = 1.0f;
                  [self.doneBlurButton setUserInteractionEnabled:YES];
              }];
         }
     }];

}





-(void)startTalkingBlurButtonAction
{
    
    FCUser *owner = [FCUser owner];
    
    

    if (owner.beacon.stackIsRunning != ESTransponderStackStateActive && !IS_ON_SIMULATOR)
    {
        [owner.beacon startBroadcasting];
        [owner.beacon startDetecting];
        [[FCUser owner].beacon chirpBeacon];
        
        [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(pushErrorScreen:) name:kTransponderEventTransponderDisabled object:nil];
        [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(continueWithBluetooth:) name:kTransponderEventTransponderEnabled object:nil];
        
        // Log via mixpanel
        [self.mixpanel track:@"Start talking button clicked"];
    } else
    {
        [self continueWithBluetooth:nil];
    }
    


    
}

-(void)removeBluetoothEvents
{
    [[NSNotificationCenter defaultCenter] removeObserver:self name:kTransponderEventTransponderDisabled object:nil];
    [[NSNotificationCenter defaultCenter] removeObserver:self name:kTransponderEventTransponderEnabled object:nil];
}

-(void)continueWithBluetooth:(NSNotification*)notification
{
    [self removeBluetoothEvents];
    //after bluetooth stack is active
    //either you go to the wallviewcontroller or you become "Searching", based on kNSUSER_DEFAULTS_HAS_BEEN_INVITED_IN
    
    if ([[NSUserDefaults standardUserDefaults] boolForKey:kNSUSER_DEFAULTS_HAS_BEEN_INVITED_IN])
    {
        [self removeBluetoothEvents];
        [UIView animateWithDuration:0.5 delay:0.0 options:UIViewAnimationOptionCurveLinear animations:^
         {
             for (UIView *subview in self.view.subviews)
             {
                 if (subview != self.extractedImageViewOnDone)
                 {
                     subview.alpha = 0.0f;
                 }
             }
         } completion:^(BOOL finsihed)
         {
             [self transitionToFCWallViewControllerWithImage:self.extractedImageViewOnDone.image andFrame:self.extractedImageViewOnDone.frame andColor:self.view.backgroundColor];
         }];
    } else
    {
        __block NSTimer *chirpTimer = [NSTimer timerWithTimeInterval:20 target:[FCUser owner].beacon selector:@selector(chirpBeacon) userInfo:nil repeats:YES];
        [[NSRunLoop mainRunLoop] addTimer:chirpTimer forMode:NSDefaultRunLoopMode];
        
        tracking = [[FCUser owner].ref childByAppendingPath:@"tracking"];
        __weak typeof (self) weakSelf = self;
        
        NSLog(@"tracking = %@", tracking);
        __block FirebaseHandle handle = [tracking observeEventType:FEventTypeValue withBlock:^(FDataSnapshot *snapshot)
        {
            if (snapshot.value != [NSNull null])
            {
                [chirpTimer invalidate];
                
                [weakSelf.tracking removeObserverWithHandle:handle];
                weakSelf.tracking = nil;
                NSDictionary *users = snapshot.value;
                int numUsers = users.count;
                if ((!weakSelf.beganShowingSearchingView && numUsers))
                {//go right on ahead to the app
                    weakSelf.beganShowingSearchingView = NO;
                    NSLog(@"interupt!");
                    [weakSelf.searchingView setHidden:YES];
                    //and go on
                    [weakSelf transitionToFCWallViewControllerWithImage:weakSelf.extractedImageViewOnDone.image andFrame:weakSelf.extractedImageViewOnDone.frame andColor:weakSelf.view.backgroundColor];
                } else
                {
                    weakSelf.tracking = nil;
                    NSLog(@"found a user! %d", numUsers);
                    
                    weakSelf.numberPeopleNearbyLabel.text = [NSString stringWithFormat:@"%d", numUsers];
                    weakSelf.peopleNearbyGrammarLabel.text = (numUsers == 1 ? @"person nearby": @"people nearby");
                    if (numUsers)
                    {//success!
                        [weakSelf prepareToTransitionDramatically];
                    }
                }
            } else
            if (IS_ON_SIMULATOR)
            {
                [weakSelf performSelector:@selector(prepareToTransitionDramatically) withObject:nil afterDelay:2];
            }
        }];
        [self.radarView buildRoundMaskAtRadius:4+28.0f];
        //buildMaskWithImage:self.extractedImageViewOnDone.image atScale:1.2f];
        [self.radarView animate];
        


        CGPoint point = CGPointMake(
                                    self.extractedImageViewOnDone.frame.size.width*0.5f+self.extractedImageViewOnDone.frame.origin.x,
                                    self.extractedImageViewOnDone.frame.size.height*0.5f+self.extractedImageViewOnDone.frame.origin.y);
        [self.radarView setPosition:point];
        
        [self.searchingView addSubview:self.radarView];

        self.searchingView.alpha = 0.0f;
        [self.searchingView setHidden:NO];
        
        [UIView animateWithDuration:0.9f delay:0.0f usingSpringWithDamping:1.0f initialSpringVelocity:5 options:UIViewAnimationOptionCurveLinear animations:^
        {
            self.welcomeView2.alpha = 0.0f;
        } completion:^(BOOL finished)
        {
            beganShowingSearchingView = YES;
            // Log via mixpanel
            [self.mixpanel track:@"Searching view shown"];
            // Animate dat shit
            [UIView animateWithDuration:1.1f delay:0.0f usingSpringWithDamping:1.2f initialSpringVelocity:0 options:UIViewAnimationOptionCurveLinear animations:^
             {
                 self.searchingView.alpha = 1.0f;
             } completion:^(BOOL finished)
             {
                 [[NSUserDefaults standardUserDefaults] setBool:YES forKey:@"showSearchingScreen"];
                 
                 [self.searchingView setUserInteractionEnabled:YES];
             }];
        }];
    }
}

-(void)prepareToTransitionDramatically
{
    [UIView animateWithDuration:0.8f delay:0.0f options:UIViewAnimationOptionCurveEaseInOut animations:^
    {
        self.searchingLabel.alpha = 0.0f;
        self.composeBlurButton.alpha = 0.0f;
        self.sendEarshotLabel.alpha = 0.0f;
        self.radarView.alpha = 0.0f;
    } completion:^(BOOL finished)
    {
        [self performSelector:@selector(continueTransitionDramatically) withObject:nil afterDelay:1];
    }];

}
-(void)continueTransitionDramatically
{
    NSLog(@"prepareToTransitionDramatically!");
    [self transitionToFCWallViewControllerWithImage:self.extractedImageViewOnDone.image andFrame:self.extractedImageViewOnDone.frame andColor:self.view.backgroundColor];
}

-(RadarView*)radarView
{
    if (!radarView)
    {
        radarView = [[RadarView alloc] initWithDim:150];
    }
    return radarView;
}

#pragma mark blurActionButton callbacks end


-(void)transitionToFCWallViewControllerWithImage:(UIImage*)image andFrame:(CGRect)startingFrame andColor:(UIColor*)backgroundColor
{
    [self setUserIsLoggedIn:YES];
    UIStoryboard *storyboard = [UIStoryboard storyboardWithName:@"main" bundle:nil];
    FCWallViewController *nextViewController = (FCWallViewController *)[storyboard instantiateViewControllerWithIdentifier:@"FCWallViewController"];

    NSString *iconIndexStr = [[icons objectAtIndex:self.selectedIconIndex] objectForKey:@"name"];
//    FCAppDelegate *appDel = (FCAppDelegate *)[UIApplication sharedApplication].delegate;
//    appDel.owner.color = [backgroundColor toHexString];
//    appDel.owner.icon = iconIndexStr;

    [nextViewController setIconName:iconIndexStr];
    [nextViewController beginTransitionWithIcon:(UIImage*)image andFrame:(CGRect)startingFrame andColor:(UIColor*)backgroundColor andResetFrame:self.originalFrameForIcon isAnimated:YES];

    NSMutableArray *viewControllers = [NSMutableArray arrayWithArray:self.navigationController.viewControllers];
    [viewControllers addObject:nextViewController];
    self.navigationController.viewControllers = viewControllers;
}

-(void)viewWillAppear:(BOOL)animated
{
    [super viewWillAppear:animated];
    

    ////this is to fade in the view after splash screen is gone
    
    if (!hasBeenHereBefore)
    {
        for (UIView *view in self.view.subviews)
        {
            view.alpha = 0.0f;
        }
    }
    
    NSTimer *timer = [NSTimer timerWithTimeInterval:1.0 target:self selector:@selector(invalidate) userInfo:nil repeats:NO];
    [[NSRunLoop mainRunLoop] addTimer:timer forMode:NSDefaultRunLoopMode];
    [[UIApplication sharedApplication] setStatusBarHidden:YES withAnimation:UIStatusBarAnimationFade];
    
    
    
    if (!IS_ON_SIMULATOR &&
        [[NSUserDefaults standardUserDefaults] boolForKey:@"showSearchingScreen"])
//        &&
        
        //![FCUser owner].beacon.stackIsRunning)
    {
        hasBeenHereBefore = YES;
        [self skipToSearchingScreen];
    }
    
    
}

-(void)skipToSearchingScreen
{
    
    UITableViewCell * cell = [iconTableView cellForRowAtIndexPath:[NSIndexPath indexPathForRow:self.selectedIconIndex inSection:0] ];
    UIImageView* imageView = (UIImageView*)[cell viewWithTag:5];
    [imageView setHidden:YES];
    CGRect frameForIcon = CGRectMake(self.iconContainerView.frame.origin.x, self.iconContainerView.frame.origin.y, 50, 50);
    frameForIcon.origin.x += (self.iconContainerView.frame.size.width-frameForIcon.size.width)*0.5f;
    frameForIcon.origin.y += (self.iconContainerView.frame.size.height-frameForIcon.size.height)*0.5f;
    
    
    self.originalFrameForIcon = frameForIcon;
    self.extractedImageViewOnDone = [[UIImageView alloc] initWithFrame:frameForIcon];
    [self.extractedImageViewOnDone setContentMode:UIViewContentModeScaleAspectFit];
    NSString *imageName = [[self.icons objectAtIndex:self.selectedIconIndex] objectForKey:@"name"];
    [self.extractedImageViewOnDone setImage:[UIImage imageNamed:imageName]];
    //        [self.view addSubview:self.extractedImageViewOnDone];
    self.extractedImageViewOnDone.alpha = 1.0f;
    
    for (UIView *subview in self.view.subviews)
    {
//        if (subview == self.doneBlurButton)
//        {
//            
//        } else
        if (subview == self.searchingView)
        {
            //                tempFrame.origin.y -=5;
            //                welcomeView2.frame = tempFrame;
            //                welcomeView2.alpha = 1.0f;
        } else
        if (subview != self.extractedImageViewOnDone ) //&& subview != welcomeView2)
        {
            subview.alpha = 0.0f;
            subview.transform = CGAffineTransformMakeTranslation(0, 0);
        }
    }
    
    [self.view addSubview:self.extractedImageViewOnDone];
    
    [self.view removeGestureRecognizer:self.panGesture];
    
    FCUser *owner = [FCUser owner];
    __block CGRect tempFrame = welcomeView2.frame;
    tempFrame.origin.x = (self.view.frame.size.width -tempFrame.size.width)*0.5f;
    tempFrame.origin.y = (self.view.frame.size.height -tempFrame.size.height)*0.5f;
    tempFrame.origin.y += 5;
    [welcomeView2 setFrame:tempFrame];
    
    CGRect targetFrameForExtractedImageView = frameForIcon;
    targetFrameForExtractedImageView.origin.y = (self.welcomeLabel.frame.origin.y-frameForIcon.size.height)*0.5f + 8;
    
    BOOL peripheralManagerIsRunning = owner.beacon.stackIsRunning;
    
    [UIView animateWithDuration:1.6f delay:0.0 usingSpringWithDamping:1.2 initialSpringVelocity:0.0f options:UIViewAnimationOptionCurveLinear animations:^
    {
         self.extractedImageViewOnDone.frame = targetFrameForExtractedImageView;
    } completion:^(BOOL finished)
    {
        [self continueWithBluetooth:nil];
        // ALONSO COMMENTED THIS OUT
//        [[FCUser owner].beacon startBroadcasting];
//        [[FCUser owner].beacon startDetecting];
//        [[FCUser owner].beacon chirpBeacon];
        
        id own = [FCUser owner];
        id baccon = [FCUser owner].beacon;
    }];
    
    

}

-(void)viewWillLayoutSubviews
{
    [super viewWillLayoutSubviews];
}
-(void)viewDidLayoutSubviews
{
    [super viewDidLayoutSubviews];
    
    //buttons setup
    if (!self.leftCircleButton)
    {
        leftCircleButton = [UIButton buttonWithType:UIButtonTypeCustom];
        rightCircleButton = [UIButton buttonWithType:UIButtonTypeCustom];
        
        leftCircleButton.backgroundColor = [UIColor clearColor];//[UIColor colorWithRed:1 green:0 blue:0 alpha:0.2f];
        rightCircleButton.backgroundColor = [UIColor clearColor];//[UIColor colorWithRed:1 green:0 blue:0 alpha:0.2f];
        
        [leftCircleButton setFrame:CGRectMake(0, 0, 55, 55)];
        [rightCircleButton setFrame:CGRectMake(0, 0, 55, 55)];
        
        [self.leftCircleColorView.superview addSubview:leftCircleButton];
        [self.rightCircleColorView.superview addSubview:rightCircleButton];
        
        
        CGRect leftFrame = leftCircleButton.frame;
        CGRect rightFrame = rightCircleButton.frame;
        
        leftFrame.origin.x = self.leftCircleColorView.frame.origin.x + ( self.leftCircleColorView.frame.size.width-leftCircleButton.frame.size.width)*0.5f;
        leftFrame.origin.y = self.leftCircleColorView.frame.origin.y + ( self.leftCircleColorView.frame.size.height-leftCircleButton.frame.size.height)*0.5f;
        
        rightFrame.origin.x = self.rightCircleColorView.frame.origin.x;
        rightFrame.origin.y = self.rightCircleColorView.frame.origin.y;
        
        rightFrame.origin.x = self.rightCircleColorView.frame.origin.x + ( self.rightCircleColorView.frame.size.width-rightCircleButton.frame.size.width)*0.5f;
        rightFrame.origin.y = self.rightCircleColorView.frame.origin.y + ( self.rightCircleColorView.frame.size.height-rightCircleButton.frame.size.height)*0.5f;
        
        
        [leftCircleButton setFrame:leftFrame];
        [rightCircleButton setFrame:rightFrame];
        leftCircleButton.tag = 1;
        rightCircleButton.tag = 0;
        
        
        [leftCircleButton addTarget:self action:@selector(circleTap:) forControlEvents:UIControlEventTouchUpInside];
        [rightCircleButton addTarget:self action:@selector(circleTap:) forControlEvents:UIControlEventTouchUpInside];
        
    }
}
-(void)circleTap:(UIButton*)button
{
    
    NSInteger index = button.tag;
    NSInteger direction = (index ? -1 : 1);
    NSLog(@"direction = %d", direction);
    
    [self animateBounceCircle:index];
    
//    int start = self.colorIndex;
    int end = self.colorIndex+direction;
    if (end < 0)
    {
        end = colors.count-1;
    } else
    if (end >= colors.count)
    {
        end = 0;
    }
    
    [UIView animateWithDuration:0.28f delay:0.0f usingSpringWithDamping:1.25f initialSpringVelocity:0 options:UIViewAnimationOptionCurveLinear animations:^
     {
         self.view.backgroundColor = [colors objectAtIndex:end];
         self.colorIndex = end;
     } completion:^(BOOL finished)
     {
         [doneBlurButton invalidatePressedLayer];
     }];
    
}

-(void)skipIfLoggedIn
{
    //It is time to Just Present the wallView controller view controller
    if ([self userIsLoggedIn])
    {
        self.hasBeenHereBefore = YES;
        UITableViewCell * cell = [iconTableView cellForRowAtIndexPath:[NSIndexPath indexPathForRow:self.selectedIconIndex inSection:0] ];
        UIImageView* imageView = (UIImageView*)[cell viewWithTag:5];
        [imageView setHidden:YES];
        CGRect frameForIcon = CGRectMake(self.iconContainerView.frame.origin.x, self.iconContainerView.frame.origin.y, 50, 50);
        frameForIcon.origin.x += (self.iconContainerView.frame.size.width-frameForIcon.size.width)*0.5f;
        frameForIcon.origin.y += (self.iconContainerView.frame.size.height-frameForIcon.size.height)*0.5f;

        
        self.originalFrameForIcon = frameForIcon;
        self.extractedImageViewOnDone = [[UIImageView alloc] initWithFrame:frameForIcon];
        [self.extractedImageViewOnDone setContentMode:UIViewContentModeScaleAspectFit];
        NSString *imageName = [[self.icons objectAtIndex:self.selectedIconIndex] objectForKey:@"name"];
        [self.extractedImageViewOnDone setImage:[UIImage imageNamed:imageName]];
//        [self.view addSubview:self.extractedImageViewOnDone];
        self.extractedImageViewOnDone.alpha = 1.0f;
        
        UIStoryboard *storyboard = [UIStoryboard storyboardWithName:@"main" bundle:nil];
        FCWallViewController *nextViewController = (FCWallViewController *)[storyboard instantiateViewControllerWithIdentifier:@"FCWallViewController"];
        
        NSString *iconIndexStr = [[icons objectAtIndex:self.selectedIconIndex] objectForKey:@"name"];
        //    FCAppDelegate *appDel = (FCAppDelegate *)[UIApplication sharedApplication].delegate;
        //    appDel.owner.color = [backgroundColor toHexString];
        //    appDel.owner.icon = iconIndexStr;
        
        [nextViewController setIconName:iconIndexStr];
        CGFloat dim = 50;
        CGRect startingFrame = CGRectMake((self.view.frame.size.width-dim)*0.5f,(self.view.frame.size.height-dim)*0.5f,dim,dim);
        NSString *icon = [[NSUserDefaults standardUserDefaults] objectForKey:@"icon"];
        [nextViewController beginTransitionWithIcon:[UIImage imageNamed:icon] andFrame:startingFrame andColor:self.view.backgroundColor andResetFrame:CGRectMake(0, 0, 0, 0) isAnimated:NO];
        
        NSMutableArray *viewControllers = [NSMutableArray arrayWithArray:self.navigationController.viewControllers];
        [viewControllers addObject:nextViewController];
        [self.navigationController pushViewController:nextViewController animated:NO];


        // ALONSO COMMENTED THIS OUT
//        [[FCUser owner].beacon startBroadcasting];
//        [[FCUser owner].beacon startDetecting];
//        [[FCUser owner].beacon chirpBeacon];
        
    }
}
-(CGRect)getOriginalRect
{
    UITableViewCell * cell = [iconTableView cellForRowAtIndexPath:[NSIndexPath indexPathForRow:self.selectedIconIndex inSection:0] ];
    UIImageView* imageView = (UIImageView*)[cell viewWithTag:5];
    [imageView setHidden:YES];
    CGRect frameForIcon = CGRectMake(self.iconContainerView.frame.origin.x, self.iconContainerView.frame.origin.y, 50, 50);
    frameForIcon.origin.x += (self.iconContainerView.frame.size.width-frameForIcon.size.width)*0.5f;
    frameForIcon.origin.y += (self.iconContainerView.frame.size.height-frameForIcon.size.height)*0.5f;

    self.originalFrameForIcon = frameForIcon;
    
    if (![self.extractedImageViewOnDone superview])
    {
//        CGRect jkFrame = self.originalFrameForIcon;
//        jkFrame.origin.y -= 20;
//        [self.extractedImageViewOnDone setFrame:jkFrame];
//        [self.view addSubview:self.extractedImageViewOnDone];
    }

    frameForIcon.origin.y += 20;
    
    return frameForIcon;
}

-(void)invalidate
{
    [doneBlurButton invalidatePressedLayer];
}

-(void)viewDidAppear:(BOOL)animated
{
    [super viewDidAppear:animated];
    
    
    [self reanimate];
    
    
    
    //this is to fade in the view after splash screen is gone
    if (!hasBeenHereBefore)
    {
        hasBeenHereBefore = YES;

        [UIView animateWithDuration:0.8f delay:0.25f usingSpringWithDamping:1.2 initialSpringVelocity:0.0f options:UIViewAnimationOptionCurveEaseIn animations:^
        {
            
            for (UIView *view in self.view.subviews)
            {
                view.alpha = 1.0f;
            }
        } completion:^(BOOL finishd)
         {
         }];
    }

    
    [self skipIfLoggedIn];


}



-(void)handlePan:(UIPanGestureRecognizer*)panGesture
{
//    NSLog(@"panGesture = %@", panGesture);

    
    CGPoint velocity = [panGesture velocityInView:self.view];
    CGPoint translation = [panGesture translationInView:self.view];

    
    static CGFloat swipeWidth = 320;
    CGFloat swipeHeight = self.view.frame.size.height;
    
    switch((int)panGesture.state)
    {
            //determine what kind of swipe, up down left or right
        case UIGestureRecognizerStateBegan:
        {
            [circleBounceTimer invalidate];
//            NSLog(@"UIGestureRecognizerStateBegan");
            self.stateChanged = NO;
            
            if (fabsf(velocity.x) > fabsf(velocity.y))
            {
                NSLog(@"velocity.x = %f", velocity.x);
                if (velocity.x < 0)
                {
                 
                    panDirection = PanGestureDirectionLeft;
                } else
                {
                 
                    panDirection = PanGestureDirectionRight;
                }
            } else
            {
                if (velocity.y < 0)
                {

                    panDirection = PanGestureDirectionUp;
                } else
                {

                    panDirection = PanGestureDirectionDown;
                }
                
                self.offsetOfTableViewAtStartOfVertical = self.iconTableView.contentOffset;
            }
        }
        break;
        case UIGestureRecognizerStateChanged:
        {
//            NSLog(@"UIGestureRecognizerStateChanged translation.x = %f", translation.x);
            self.stateChanged = YES;
            
            CGFloat percent = 0;
            
            switch (panDirection)
            {

                case PanGestureDirectionLeft:
                {

                    percent = translation.x/swipeWidth;
//                    NSLog(@"PanGestureDirectionLeft %f", percent);
                }
                break;
                case PanGestureDirectionRight:
                {
//                    NSLog(@"PanGestureDirectionRight");
                    percent = translation.x/swipeWidth;
//                    NSLog(@"PanGestureDirectionLeft %f", percent);
                }
                break;
                case PanGestureDirectionUp:
                {
//                    NSLog(@"PanGestureDirectionUp");
                    percent = translation.y/swipeHeight;
                }
                break;
                case PanGestureDirectionDown:
                {
//                    NSLog(@"PanGestureDirectionDown");
                    percent = translation.y/swipeHeight;
                }
                break;
                case PanGestureDirectionNone:
                {
//                    NSLog(@"PanGestureDirectionNone on state changed! WARNING!");
                }
                break;
            }

            if (PanGestureDirectionLeft == panDirection || PanGestureDirectionRight == panDirection )
            {//Left Right color change CHANGE
                int direction =  (percent < 0 ? -1 : 1);
                
//                NSLog(@"dirction = %d", direction);
                
                while (fabsf(percent >= 1))
                {
                    
                    percent += -direction;
                    [self setColorIndex:colorIndex+direction];
                }
                
                NSInteger start = self.colorIndex;
                NSInteger end = self.colorIndex+direction;
                
                
//                NSLog(@"1. start, end -> %ld, %ld", start, end);
                
                if (end < 0)
                {
                    end = colors.count-1;
                } else
                if (end >= colors.count)
                {
                    end = 0;
                }
                
//                NSLog(@"2. start, end -> %ld, %ld", start, end);
                
                if (direction < 0)
                {//switch start and end colors
                    NSInteger tempStart = start;
                    start = end;
                    end = tempStart;
                    percent += 1.0f;
                }
                
                //apply a transform to the dots
                {
                    CGFloat dist = translation.x*0.15f;
                    if (self.panDirection == PanGestureDirectionRight)
                    {
//                        NSLog(@"moveLeft");
                        self.leftCircleColorView.transform = CGAffineTransformMakeTranslation(dist, 0);
//                        self.leftCircleColorView.transform = CGAffineTransformMakeTranslation(translation.x*0.25f, 0);
//                        self.rightCircleColorView.transform = CGAffineTransformMakeTranslation(-translation.x*0.25f, 0);
                    } else
                    if (self.panDirection == PanGestureDirectionLeft)
                    {
                        dist *= -1;
//                        NSLog(@"moveRight");
                        self.rightCircleColorView.transform = CGAffineTransformMakeTranslation(-dist, 0);
//                        self.rightCircleColorView.transform = CGAffineTransformMakeTranslation(translation.x*0.25f, 0);
//                        self.leftCircleColorView.transform = CGAffineTransformMakeTranslation(-translation.x*0.25f, 0);
                        
                    } else
                    {
                        dist = 0;
                    }
                    
//                        self.rightCircleColorView.transform = CGAffineTransformMakeTranslation(-dist, 0);
//                        self.leftCircleColorView.transform = CGAffineTransformMakeTranslation(dist, 0);
                    
                }
                
//                NSLog(@"3. start, end -> %ld, %ld", start, end);
                //percent always positive here
                [self.view setBackgroundColor:[self colorLerpFrom:[colors objectAtIndex:start] to:[colors objectAtIndex:end] withDuration:percent]];
                
                
            } else
            if (PanGestureDirectionUp == panDirection || PanGestureDirectionDown == panDirection)
            {
                //up is negative, down is positive
//                int direction = (percent < 0 ? -1 : 1);//fabsf(percent)/percent;
                
                CGFloat y = self.offsetOfTableViewAtStartOfVertical.y - percent*self.cellHeight;
                
                //following if else clause will appear to loop the tableview, aka: no top nor bottom.
                y = [self reshuffleTableViewForOffset:y andPercent:percent];
                [self.iconTableView setContentOffset:CGPointMake(0, y)];
                
            }
        }
        break;
        case UIGestureRecognizerStateEnded:
        {
//            NSLog(@"UIGestureRecognizerStateEnded");
            if (!self.stateChanged)
            {
                return;
            } else
            {
                self.stateChanged = NO;
            }

            CGFloat percent = 0;
            switch (panDirection)
            {
                    
                case PanGestureDirectionLeft:
                {
                    percent = translation.x/swipeWidth;
                }
                    break;
                case PanGestureDirectionRight:
                {
                    percent = translation.x/swipeWidth;
                }
                    break;
                case PanGestureDirectionUp:
                {
                    percent = translation.y/swipeHeight;
                }
                    break;
                case PanGestureDirectionDown:
                {
                    percent = translation.y/swipeHeight;
                }
                    break;
                case PanGestureDirectionNone:
                {
                    NSLog(@"PanGestureDirectionNone on state ENDED! WARNING!");
                }
                break;
            }
            int direction = (percent < 0 ? -1 : 1) ;//fabsf(percent)/percent;
            
            //dots snap back
            {
//                int direction = 1;
//                CGFloat dist = translation.x * 0.25f;
                CGFloat velocity = 0;//dist;
                [UIView animateWithDuration:0.2f delay:0.0f usingSpringWithDamping:0.7f initialSpringVelocity:velocity options:UIViewAnimationOptionCurveLinear animations:^
                {
                    self.leftCircleColorView.transform = CGAffineTransformIdentity;
                    self.rightCircleColorView.transform = CGAffineTransformIdentity;
                } completion:^(BOOL finished)
                {
                
                }];
            }
            
            if (PanGestureDirectionLeft == panDirection || PanGestureDirectionRight == panDirection )
            {//Left Right color change END
                
                int start = self.colorIndex;
                int end = self.colorIndex+direction;
                if (end < 0)
                {
                    end = colors.count-1;
                } else
                if (end >= colors.count)
                {
                    end = 0;
                }
                
//switch back if not going fast enough for a certain percent traveled
                if (fabsf(velocity.x) < 40 && fabsf(percent) < 0.7f)
                {
                    end = start;
                }
                
                [UIView animateWithDuration:0.08f delay:0.0f usingSpringWithDamping:1.25f initialSpringVelocity:0 options:UIViewAnimationOptionCurveLinear animations:^
                {
                    self.view.backgroundColor = [colors objectAtIndex:end];
                    self.colorIndex = end;
                } completion:^(BOOL finished)
                {
                    [doneBlurButton invalidatePressedLayer];
                }];
                
            } else
            if (PanGestureDirectionUp == panDirection || PanGestureDirectionDown == panDirection)
            {
                int direction = (percent < 0 ? -1 : 1);//fabsf(percent)/percent;
                
                int numberOfWraps = abs((int)percent);
                numberOfWraps = MAX(1, numberOfWraps);
                
                
                CGFloat y = self.offsetOfTableViewAtStartOfVertical.y - numberOfWraps*direction*self.cellHeight;
                
                [UIView animateWithDuration:0.25f delay:0.0f usingSpringWithDamping:1.25f initialSpringVelocity:0 options:UIViewAnimationOptionCurveLinear animations:^
                {
                    
                    int index = y/self.cellHeight;
                    NSDictionary *dc = [self.icons objectAtIndex:index];
                    NSString *attribution = [dc objectForKey:@"attribution"];
                    [self.attributionLabel setText:[NSString stringWithFormat:@"Icon by %@", attribution]];
                    [self.iconTableView setContentOffset:CGPointMake(0, y)];
                    self.iconIndex = iconIndex - numberOfWraps;
                    
                } completion:^(BOOL finished)
                {
                    
                }];
            }
            
            self.panDirection = PanGestureDirectionNone;
            [self initializeCircleBounceTimerIfNecessary];
        }
        break;
            
    }
    
}

-(CGFloat)reshuffleTableViewForOffset:(CGFloat)y andPercent:(CGFloat)percent
{
    if (y < 0)
    {
        NSLog(@"reshuffle bottom to top");
        id lastObject = [self.icons lastObject];
        
        
        
        
        NSMutableArray *iconNamesMutable = [NSMutableArray arrayWithArray:self.icons];
        [iconNamesMutable removeLastObject];
        [iconNamesMutable insertObject:lastObject atIndex:0];
        self.icons = [NSArray arrayWithArray:iconNamesMutable];
        [self.iconTableView reloadData];
        
        //move tableView
        CGPoint offset = {0, self.cellHeight};
        
        self.offsetOfTableViewAtStartOfVertical = offset; //{0, self.offsetOfTableViewAtStartOfVertical.y + self.cellHeight};
        
        y = self.offsetOfTableViewAtStartOfVertical.y - percent*self.cellHeight;
        
        
        
    } else
    if (y > self.cellHeight*(self.icons.count-3))
    {
        NSLog(@"reshuffle top to bottom");
        //reshuffle top to bottom
        id firstObject = [self.icons objectAtIndex:0];
        
        
        NSMutableArray *iconNamesMutable = [NSMutableArray arrayWithArray:self.icons];
        [iconNamesMutable removeObject:firstObject];
        [iconNamesMutable addObject:firstObject];
        self.icons = [NSArray arrayWithArray:iconNamesMutable];
        [self.iconTableView reloadData];
        
        //move tableView
        CGPoint offset = {0, self.cellHeight*(self.icons.count-3)-self.cellHeight};
        
        self.offsetOfTableViewAtStartOfVertical = offset; //{0, self.offsetOfTableViewAtStartOfVertical.y + self.cellHeight};
        
        y = self.offsetOfTableViewAtStartOfVertical.y - percent*self.cellHeight;
        
        
    }
    return y;
}

-(void)animateBounceCircle:(NSInteger)circle
{
    CGFloat distance = 5*(circle ? 1 : -1);
    UIView *circleView = (circle ? self.leftCircleColorView : self.rightCircleColorView);
    self.circleIsBouncing = YES;
    [self.circleBounceTimer invalidate];
    if (self.panDirection == PanGestureDirectionNone)
    {
        [UIView animateWithDuration:0.1f delay:0.0f options:UIViewAnimationOptionCurveEaseIn animations:^
         {
             circleView.transform = CGAffineTransformMakeTranslation(distance, 0);
         } completion:^(BOOL finished)
         {
             [UIView animateWithDuration:0.4f delay:0.0f usingSpringWithDamping:0.1f initialSpringVelocity:2 options:UIViewAnimationOptionCurveLinear animations:^
              {
                  circleView.transform = CGAffineTransformMakeTranslation(0, 0);
              } completion:^(BOOL finished)
              {
                  self.circleIsBouncing = NO;
                  [self initializeCircleBounceTimerIfNecessary];
              }];
         }];
    }
}

-(void)circleBounceTimerAction:(NSTimer*)theTimer
{
    self.alternateBounceCounter = (self.alternateBounceCounter+1)%2;    
    if (self.panDirection == PanGestureDirectionNone && !self.circleIsBouncing)
    {
        [self animateBounceCircle:self.alternateBounceCounter];
        
        NSTimer *timer = [NSTimer timerWithTimeInterval:0.07f target:self selector:@selector(bounceTimerQuick) userInfo:nil repeats:NO];
        [[NSRunLoop mainRunLoop] addTimer:timer forMode:NSDefaultRunLoopMode];
    }
    
    if (!theTimer)
    {
        [self initializeCircleBounceTimerIfNecessary];
    }
}
-(void)bounceTimerQuick
{
    [self animateBounceCircle:(self.alternateBounceCounter+1)%2];
}

- (UIColor *)colorLerpFrom:(UIColor *)start to:(UIColor *)end withDuration:(float)t
{
    if(t < 0.0f) t = 0.0f;
    if(t > 1.0f) t = 1.0f;
    
    const CGFloat *startComponent = CGColorGetComponents(start.CGColor);
    const CGFloat *endComponent = CGColorGetComponents(end.CGColor);
    
    float startAlpha = CGColorGetAlpha(start.CGColor);
    float endAlpha = CGColorGetAlpha(end.CGColor);
    
    float r = startComponent[0] + (endComponent[0] - startComponent[0]) * t;
    float g = startComponent[1] + (endComponent[1] - startComponent[1]) * t;
    float b = startComponent[2] + (endComponent[2] - startComponent[2]) * t;
    float a = startAlpha + (endAlpha - startAlpha) * t;
    
    return [UIColor colorWithRed:r green:g blue:b alpha:a];
}

- (void)didReceiveMemoryWarning
{
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

-(void)setIconIndex:(NSInteger)newIconIndex
{
    while (newIconIndex < 0)
    {
        newIconIndex += icons.count;
    }
    

    
    iconIndex = newIconIndex%icons.count;
    

}

-(void)setColorIndex:(NSInteger)newColorIndex
{
    while (newColorIndex < 0)
    {
        newColorIndex += colors.count;
    }
    
    colorIndex = newColorIndex%colors.count;
    
    NSLog(@"color = %@", [self.colors objectAtIndex:colorIndex]);
}

#pragma mark iconTableView delegate callback
-(NSInteger) numberOfSectionsInTableView:(UITableView *)tableView
{
    return 1;
}
-(NSInteger) tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section
{
    return icons.count;
}
-(UITableViewCell*)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath
{
    UITableViewCell *iconCell = [tableView dequeueReusableCellWithIdentifier:@"IconCell"];
    if (!iconCell)
    {
        
        iconCell = [[UITableViewCell alloc] initWithStyle:UITableViewCellStyleDefault reuseIdentifier:@"IconCell"];
        [iconCell setBackgroundColor:[UIColor clearColor]];
        UIImageView *imageView = [[UIImageView alloc] initWithFrame:CGRectMake((self.iconContainerView.bounds.size.width-50)*0.5, (self.iconContainerView.bounds.size.height-50)*0.5, 50, 50)];
        [imageView setContentMode:UIViewContentModeScaleAspectFit];
        imageView.tag = 5;
        [imageView setBackgroundColor:[UIColor clearColor]];
        
        
        CGFloat border = 10;
        CGSize underViewSize = {border+50, border+50};
        UIImageView *underView = [[UIImageView alloc] initWithFrame:CGRectMake((self.iconContainerView.bounds.size.width-underViewSize.width)*0.5, (self.iconContainerView.bounds.size.height-underViewSize.height)*0.5, underViewSize.width, underViewSize.height)];
        [underView setContentMode:UIViewContentModeScaleAspectFit];
        underView.tag = 4;
        [underView setBackgroundColor:[UIColor clearColor]];
        underView.alpha = 0.0f;
        
        [iconCell.contentView addSubview:underView];
        [iconCell.contentView addSubview:imageView];
//        [iconCell setBackgroundColor:[UIColor colorWithRed:1 green:0 blue:0 alpha:0.5f]];
    }
    
    
    
    UIImageView *imageView = (UIImageView*)[iconCell viewWithTag:5];
    UIImageView *underView = (UIImageView*)[iconCell viewWithTag:4];
    
    [imageView setHidden:NO];
    [imageView setImage:[UIImage imageNamed: [ [icons objectAtIndex:indexPath.row] objectForKey:@"name"] ] ];
    
    UIImage *image = [imageView.image transparentBorderImage:5];
    
    underView.image = [image applyBlurWithRadius:5 tintColor:[UIColor clearColor] saturationDeltaFactor:1 maskImage:nil];
    
    
    return iconCell;
}

-(CGFloat)tableView:(UITableView *)tableView heightForRowAtIndexPath:(NSIndexPath *)indexPath
{
    return self.cellHeight;
}

-(CGFloat)cellHeight
{//127
    
    CGFloat scaledHeight = 111.0f;//self.spinnerImageView.bounds.size.height*0.75f;
//    NSLog(@"scaledHeight = %f", scaledHeight);
    return scaledHeight;
}


#pragma mark iconTableView datasource callback

#pragma mark Notifications
- (void)appDidBecomeActive:(NSNotification *)notification
{
//    [UIView animateWithDuration:40.0f
//                          delay:0.0f
//                        options:UIViewAnimationOptionRepeat | UIViewAnimationOptionCurveLinear
//                     animations:^{
//                         self.spinnerImageView.transform = CGAffineTransformMakeRotation(M_PI);
//                     }
//                     completion:nil
//     ];
//    NSLog(@"did become active notification");
}

- (void)appDidEnterForeground:(NSNotification *)notification
{
    NSLog(@"did enter foreground notification");
    [self reanimate];
}
#pragma mark Notifications end

//redraw the view as if it were the first time.
-(void)resetAsNewAnimated
{
#warning userInteractionDisabled:NO set
    [self.view setUserInteractionEnabled:NO];
    
    self.welcomeView2.alpha = 0.0f;
    self.searchingView.alpha = 0.0f;
    
    [self setUserIsLoggedIn:NO];
    [self.view addGestureRecognizer:self.panGesture];
    
    CGFloat expectedOffset = (self.selectedIconIndex-1)*self.cellHeight;
    [self.iconTableView reloadData];
    [self.iconTableView setContentOffset:CGPointMake(self.iconTableView.contentOffset.x, expectedOffset)];
    
    UITableViewCell *iconCell = [self.iconTableView cellForRowAtIndexPath:[NSIndexPath indexPathForItem:self.selectedIconIndex inSection:0]];
    UIImageView *imageView = (UIImageView*)[iconCell viewWithTag:5];
    [imageView setHidden:NO];

    
    self.extractedImageViewOnDone.frame = self.originalFrameForIcon;
    
    for (UIView *view in self.view.subviews)
    {
        if (view != self.extractedImageViewOnDone)
        {
            view.transform = CGAffineTransformIdentity;
        }
    }
    [UIView animateWithDuration:0.5f delay:0.2f usingSpringWithDamping:1.2f initialSpringVelocity:0.0f options:UIViewAnimationOptionCurveLinear animations:^{
        for (UIView *view in self.view.subviews)
        {
            if (view != self.welcomeView2 && view != self.searchingView)
            {
                view.alpha = 1.0f;
            }
        }
    } completion:^(BOOL finished)
    {
        [self.extractedImageViewOnDone removeFromSuperview];
        [self.view setUserInteractionEnabled:YES];
        
    }];
    
    [self.doneBlurButton setUserInteractionEnabled:YES];
    
    NSLog(@"contentOffset = %f", self.iconTableView.contentOffset.y);
}

-(void)pushErrorScreen:(NSNotification*)notification
{
    [self removeBluetoothEvents];
    [self performSegueWithIdentifier:@"fail" sender:self];
}
-(void)prepareForSegue:(UIStoryboardSegue *)segue sender:(id)sender
{
    if ([segue.identifier isEqualToString:@"fail"])
    {
        UIViewController *viewController = segue.destinationViewController;
        [viewController.view setBackgroundColor:self.view.backgroundColor];
    }
}



#pragma mark PanGestureRecognizer delegate callbacks to enable button press while pan
- (BOOL)gestureRecognizer:(UIGestureRecognizer *)gestureRecognizer shouldReceiveTouch:(UITouch *)touch {
    if (touch.view == self.doneBlurButton.theButton)
    {
        return NO; // ignore the touch
    }
    NSLog(@"//handle the touch");
    return YES; // handle the touch
}
- (IBAction)forceDramaticTransition:(id)sender
{
    [self prepareToTransitionDramatically];
}

@end
