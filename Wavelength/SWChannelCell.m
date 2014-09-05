//
//  SWChannelCell.m
//  Shortwave
//
//  Created by Ethan Sherr on 9/3/14.
//  Copyright (c) 2014 Ethan Sherr. All rights reserved.
//

#import "SWChannelCell.h"
#import <Mixpanel/Mixpanel.h>
#import "ObjcConstants.h"
#import "UIColor+HexString.h"


@interface SWChannelCell () //<UIGestureRecognizerDelegate>

@property (weak, nonatomic) IBOutlet UIView *containerView;



@property (weak, nonatomic) IBOutlet NSLayoutConstraint *topInsetConstraint;


@property (weak, nonatomic) IBOutlet UILabel *titleLabel;

@property (weak, nonatomic) IBOutlet NSLayoutConstraint *titleLabelHeightConstraint;

@property (weak, nonatomic) IBOutlet UILabel *descriptionLabel;

@property (weak, nonatomic) IBOutlet NSLayoutConstraint *descriptionLabelHeightConstraint;

@property (weak, nonatomic) IBOutlet UIButton *muteButton;

@property (weak, nonatomic) IBOutlet UIImageView *muteButtonImageSelected;
@property (weak, nonatomic) IBOutlet UIImageView *muteButtonImageUnselected;

@property (weak, nonatomic) IBOutlet UIView *sideView;

@property (weak, nonatomic) IBOutlet UIButton *leaveButton;

@property (strong ,nonatomic) UIView *confirmDeleteView;

@property (weak, nonatomic) IBOutlet NSLayoutConstraint *verticalSpaceBetweenTitleAndDescriptionConstraint;

@property (weak, nonatomic) IBOutlet UIView *indicatorView;

@property (assign, nonatomic) CGFloat distance; //5


@end

@implementation SWChannelCell

+(CGFloat)cellHeightGivenChannel:(SWChannelModel*)channel
{
    UIFont *descriptionFont = [UIFont fontWithName:@"Avenir-Light" size:14];
    CGFloat descriptionMaxWidth = 222.0f;
    UILabel *fakeDescriptionLabel = [[UILabel alloc] initWithFrame:CGRectMake(0, 0, descriptionMaxWidth, 80)];
    fakeDescriptionLabel.font = descriptionFont;
    fakeDescriptionLabel.numberOfLines = 0;
    fakeDescriptionLabel.text = channel.channelDescription;
    CGSize descriptionSize = [fakeDescriptionLabel sizeThatFits:fakeDescriptionLabel.frame.size];
    
    UIFont *titleFont = [UIFont fontWithName:@"Avenir-Light" size:16];
    CGFloat titleMaxWidth = 222.0f;
    UILabel *fakeTitleLabel = [[UILabel alloc] initWithFrame:CGRectMake(0, 0, titleMaxWidth, 80)];
    fakeTitleLabel.numberOfLines = 0;
    fakeTitleLabel.font = titleFont;
    fakeTitleLabel.text = channel.name;
    CGSize titleSize = [fakeTitleLabel sizeThatFits:fakeTitleLabel.frame.size];
    
    CGFloat result = 1 * 21 + 2 + titleSize.height + descriptionSize.height + 57;
    return result;
}


@synthesize distance;
@synthesize confirmDeleteView;
@synthesize titleLabel;
@synthesize descriptionLabel;


@synthesize channelModel;
-(void)setChannelModel:(SWChannelModel *)newValue
{
    //willSet
    {
        if (channelModel)
        {
            //prevent responce from other channel's muted event if reused cell
            channelModel.mutedDelegate = nil;
        }
    }
    channelModel = newValue;
    //didSet
    {
        titleLabel.text = channelModel.name;
        [self setIsSynchronized:channelModel.isSynchronized];
        
        if (channelModel.channelDescription)
        {
            descriptionLabel.text = channelModel.channelDescription;
        } else
        {
            descriptionLabel.text = @"";
        }
        NSDictionary *attributes = @{NSFontAttributeName : descriptionLabel.font};
        CGSize constraintSize = CGSizeMake(descriptionLabel.frame.size.width, 300);
        NSString *string = descriptionLabel.text;
        CGSize actualSize = [descriptionLabel sizeThatFits:CGSizeMake(descriptionLabel.frame.size.width, 80)];
        
        channelModel.mutedDelegate = self;
        [self updateMutedState:channelModel.muted];
        
        self.descriptionLabelHeightConstraint.constant = actualSize.height;
        
        
        confirmDeleteView.transform = CGAffineTransformMakeTranslation(0, 0);
        CGFloat yForConfirmDelete = self.frame.size.height - 40;
        CGRect frame = confirmDeleteView.frame;
        frame.origin.y = yForConfirmDelete;
        confirmDeleteView.frame = frame;
        confirmDeleteView.transform = CGAffineTransformMakeTranslation(320, 0);
        
        
    }
}

@synthesize highlighted;
-(void)setHighlighted:(BOOL)newValue
{
    [super setHighlighted:newValue];
    //didSet
    {
        if (highlighted)
        {
            self.backgroundColor = [UIColor whiteColor];
        } else
        {
            self.backgroundColor = [UIColor clearColor];
        }
    }
}


-(void)awakeFromNib
{
    [super awakeFromNib];
    distance = 5.0f;
    
    confirmDeleteView = [[UIView alloc] initWithFrame:CGRectMake(0, 0, 320, 40)];
    confirmDeleteView.backgroundColor = [UIColor colorWithHexString:Objc_kNiceColors[@"pinkRed"]];
    
    //UIColor(hexString: kNiceColors["pinkRed"])
    
    [self addSubview:confirmDeleteView];
    
    UIButton *deleteButton = [[UIButton alloc] initWithFrame:confirmDeleteView.bounds];
    [deleteButton setTitle:@"Leave Channel" forState:UIControlStateNormal];
    [deleteButton setTitleColor:[UIColor whiteColor] forState:UIControlStateNormal];
    [confirmDeleteView addSubview:deleteButton];
    deleteButton.titleLabel.font = [UIFont fontWithName:@"Avenir-Black" size:17];
    [deleteButton addTarget:self action:@selector(confirmDeleteAction:) forControlEvents:UIControlEventTouchUpInside];
}

-(void)setIsSynchronized:(BOOL)synchronized
{
    self.sideView.alpha = synchronized ? 0.0f : 1.0f;
}
-(void)updateMutedState:(BOOL)isMuted
{
    self.muteButtonImageSelected.alpha = isMuted ? 1.0f : 0.0f;
    self.muteButtonImageUnselected.alpha = !isMuted ? 1.0f : 0.0f;
}


- (IBAction)muteAction:(id)sender
{
    channelModel.muted = !channelModel.muted;
    [channelModel setMutedToFirebase];
    
    [[Mixpanel sharedInstance] track:@"Mute Channel" properties:
     @{
        @"channel": channelModel.name,
        @"isMuted": [NSNumber numberWithBool:channelModel.muted]
      }];
}

-(void)channel:(SWChannelModel*)channel isMuted:(BOOL)muted
{
    [self updateMutedState:muted];
}

-(void)push
{
    [UIView animateWithDuration:0.1f delay:0.0f options:UIViewAnimationOptionCurveEaseIn animations:^
    {
        self.sideView.alpha = 1.0f;
        self.sideView.transform = CGAffineTransformMakeTranslation(-self.distance, 0);
    } completion:^(BOOL finished)
    {
        [UIView animateWithDuration:0.4f delay:0.0f usingSpringWithDamping:0.1f initialSpringVelocity:2.0f options:UIViewAnimationOptionCurveLinear animations:^
        {
            self.sideView.transform = CGAffineTransformMakeTranslation(0, 0);
        } completion:^(BOOL finished){}];
    }];
}

-(void)confirmDeleteAction:(id)sender
{
    NSString *userID = [[NSUserDefaults standardUserDefaults] objectForKey:Objc_kNSUSERDEFAULTS_KEY_userId];
    NSString *userChannelUrl = [NSString stringWithFormat:@"%@users/%@/channels/%@", Objc_kROOT_FIREBASE, userID, channelModel.name];
    Firebase *userChannelFB = [[Firebase alloc] initWithUrl:userChannelUrl];
    [userChannelFB setValue:nil];
    
    NSString *userInChannelMemeberUrl = [NSString stringWithFormat:@"%@channels/%@/members/%@", Objc_kROOT_FIREBASE, channelModel.name, userID];
    Firebase *userInChannelFB = [[Firebase alloc] initWithUrl:userInChannelMemeberUrl];
    [userInChannelFB setValue:nil];
    
    [[Mixpanel sharedInstance] track:@"Leave Channel" properties:@{@"channel": self.channelModel.name}];
    
}

- (IBAction)leaveAction:(id)sender
{
    NSLog(@"leave action");
    [UIView animateWithDuration:0.4f delay:0.0f usingSpringWithDamping:2.0f initialSpringVelocity:2.0f options:UIViewAnimationOptionCurveLinear animations:^
    {
        self.confirmDeleteView.transform = CGAffineTransformMakeTranslation(0, 0);
    } completion:^(BOOL finished){}];
}

-(void)hideLeaveChannelConfirmUI
{
    [UIView animateWithDuration:0.2f delay:0.0f usingSpringWithDamping:2.0f initialSpringVelocity:2.0f options:UIViewAnimationOptionCurveLinear animations:^
    {
        self.confirmDeleteView.transform = CGAffineTransformMakeTranslation(320, 0);
    } completion:^(BOOL finished){}];
}

@end