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
    messageText.dataDetectorTypes = UIDataDetectorTypeAll;
    
    
    CALayer *circle = [CALayer layer];
    circle.cornerRadius = profileImageView.frame.size.height/2;
    circle.frame = profileImageView.bounds;
    circle.backgroundColor = [UIColor blackColor].CGColor;
    
    profileImageView.layer.mask = circle;
    containerVIew.transform = CGAffineTransformMakeRotation(M_PI);
    
    messageText.contentInset = UIEdgeInsetsMake(0, 0, 0, 0);
    messageText.contentOffset = CGPointMake(0,0);
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
    self.profileImageView.alpha = 0.0f;
    [UIView animateWithDuration:0.15 delay:0.0f usingSpringWithDamping:0.8 initialSpringVelocity:1.0 options:UIViewAnimationOptionCurveLinear animations:^
    {
        self.profileImageView.alpha = 1.0f;
    } completion:^(BOOL finished){}];
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
//    messageText.backgroundColor = [UIColor redColor];
    
    firstNameLabel.text = model.firstName;
    priorityLabel.text = [NSString stringWithFormat:@"%f", model.priority];
    
    self.profileImageView.image = nil;
    
//    [self.coloredCircleLayer setBackgroundColor:model.color.CGColor];
//    UIImage *img = [UIImage imageNamed:[NSString stringWithFormat:@"%@.png", model.icon] ];
//    iconImageView.image = img;
    
    super.model = model;
}
+(CGFloat)heightWithMessageModel:(MessageModel*)model
{
    
    NSString *text = model.text;
    
    //    UIFont *font = [UIFont fontWithName:@"HelveticaNeue-Light" size:14];
    //    NSAttributedString *attributedText =[[NSAttributedString alloc] initWithString:text attributes:
    //                                         @{ NSFontAttributeName: font }] ;
    
//    UITextView *fakeTextField = [[UITextView alloc] initWithFrame:CGRectMake(0, 0, 232, 29)];
//    fakeTextField.font = [UIFont fontWithName:@"Avenir-Light" size:14];
//    fakeTextField.text = model.text;
//    CGSize size = fakeTextField.contentSize;

    UIFont *font = [UIFont fontWithName:@"Avenir-Light" size:14];
    NSAttributedString *attributedText = [[NSAttributedString alloc] initWithString:text attributes:@{NSFontAttributeName: font}];
    CGSize size = [attributedText boundingRectWithSize:CGSizeMake(232, 400) options:(NSStringDrawingUsesLineFragmentOrigin) context:nil].size;
    
    
    NSLog(@"Calculated Height '%@' for text '%@'", NSStringFromCGSize(size), text);
    
    size.height = 28 + size.height + 16 + 11 + 6; //(12+15+8*2) + size.height;//MAX(17*2+40, 15*2 + size.height);
    
    return size.height;
}

@end
