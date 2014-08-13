//
//  SWMessageCell.m
//  Shortwave
//
//  Created by Ethan Sherr on 5/19/14.
//  Copyright (c) 2014 Buildco. All rights reserved.
//

#import "SWTextCell.h"

@interface SWTextCell ()


@property (weak, nonatomic) IBOutlet UIImageView *profileImageView;
@property (weak, nonatomic) IBOutlet UITextView *messageText;

@property (weak, nonatomic) IBOutlet UILabel *firstNameLabel;
@property (weak, nonatomic) IBOutlet NSLayoutConstraint *heightOfTextConstraint;
@property (weak, nonatomic) IBOutlet UILabel *priorityLabel;

@property (weak, nonatomic) IBOutlet UIView *containerVIew;

@end

@implementation SWTextCell

@synthesize ownerID;
@synthesize messageText;
@synthesize profileImageView;
@synthesize firstNameLabel;

@synthesize priorityLabel;
@synthesize containerVIew;

-(void)awakeFromNib
{
    [super awakeFromNib];
    [profileImageView setContentMode:UIViewContentModeScaleAspectFit];
    profileImageView.backgroundColor = [UIColor greenColor];
    messageText.dataDetectorTypes = UIDataDetectorTypeAll;
    
    
    CALayer *circle = [CALayer layer];
    circle.cornerRadius = profileImageView.frame.size.height/2;
    circle.frame = profileImageView.bounds;
    circle.backgroundColor = [UIColor blackColor].CGColor;
    
    profileImageView.layer.mask = circle;
    containerVIew.transform = CGAffineTransformMakeRotation(M_PI);
}


-(void)setFaded:(BOOL)faded animated:(BOOL)animated
{
    CGFloat targetAlpha = (faded? 0.2f : 1.0f);
    
    if (animated)
    {
        [UIView animateWithDuration:0.6f delay:0.0f usingSpringWithDamping:1.2f initialSpringVelocity:0.0f options:UIViewAnimationOptionCurveEaseInOut animations:^
         {
             profileImageView.alpha = targetAlpha;
             self.messageText.alpha = targetAlpha;
         } completion:^(BOOL finishd){}];
    } else
    {
        profileImageView.alpha = targetAlpha;
        self.messageText.alpha  = targetAlpha;
    }
}

-(void)setProfileImage:(UIImage*)image
{
    self.profileImageView.image = image;
}

-(void)setModel:(MessageModel *)model
{
    ownerID = model.ownerID;
    messageText.scrollEnabled = NO; //prevent ios7 bug!
    messageText.text = nil; //to prevent ios7 Bug
    
    UIFont *font = messageText.font;
    NSAttributedString *attributedText =[[NSAttributedString alloc] initWithString:model.text attributes:
                                         @{ NSFontAttributeName: font }] ;
    messageText.attributedText = attributedText;
    
    firstNameLabel.text = model.firstName;
    priorityLabel.text = [NSString stringWithFormat:@"%f", model.priority];
    
//    [self.coloredCircleLayer setBackgroundColor:model.color.CGColor];
//    UIImage *img = [UIImage imageNamed:[NSString stringWithFormat:@"%@.png", model.icon] ];
//    iconImageView.image = img;
    
    super.model = model;
}

@end
