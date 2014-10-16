//
//  SWMessageCell.m
//  Shortwave
//
//  Created by Ethan Sherr on 5/19/14.
//  Copyright (c) 2014 Buildco. All rights reserved.
//

#import "SWTextCell.h"
#import "CustomTextView.h"

@interface SWTextCell ()


@property (strong, nonatomic) IBOutlet UITextView *messageText;


@property (weak, nonatomic) IBOutlet NSLayoutConstraint *textHeightConstraint;

@property (weak, nonatomic) IBOutlet UIView *containerVIew;
@property (weak, nonatomic) IBOutlet CustomTextView *customTextView;

@end

@implementation SWTextCell

@synthesize ownerID;
@synthesize messageText;


@synthesize containerVIew;
@synthesize textHeightConstraint;

-(void)awakeFromNib
{
    [super awakeFromNib];
//    [profileImageView setContentMode:UIViewContentModeScaleAspectFill];
    messageText.dataDetectorTypes = UIDataDetectorTypeAll;
    
    [messageText removeFromSuperview];
//    [messageText setScrollEnabled:NO];
    containerVIew.transform = CGAffineTransformMakeRotation(M_PI);
//    containerVIew.backgroundColor = [UIColor colorWithRed:1 green:0 blue:0 alpha:0.5];
//    self.backgroundColor = [UIColor colorWithRed:0 green:1 blue:0 alpha:0.4];
//    messageText.backgroundColor = [UIColor colorWithRed:1 green:1 blue:1 alpha:0.3];
    
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
//             profileImageView.alpha = targetAlpha;
             self.messageText.alpha = targetAlpha;
         } completion:^(BOOL finishd){}];
    } else
    {
//        profileImageView.alpha = targetAlpha;
        self.messageText.alpha  = targetAlpha;
    }
}

-(void)setProfileImage:(UIImage*)image
{
//    self.profileImageView.image = image;
//    self.profileImageView.alpha = 0.0f;
//    [UIView animateWithDuration:0.15 delay:0.0f usingSpringWithDamping:0.8 initialSpringVelocity:1.0 options:UIViewAnimationOptionCurveLinear animations:^
//    {
//        self.profileImageView.alpha = 1.0f;
//    } completion:^(BOOL finished){}];
}

-(void)setModel:(MessageModel *)model
{
    ownerID = model.ownerID;
    messageText.scrollEnabled = NO; //prevent ios7 bug!
    messageText.text = nil; //to prevent ios7 Bug
    
    UIFont *font = [SWTextCell fontForMessageTextView];
    NSAttributedString *attributedText =[[NSAttributedString alloc] initWithString:model.text attributes:
                                         @{ NSFontAttributeName: font }] ;
    
    [_customTextView setLabel:attributedText size:CGSizeMake(_customTextView.frame.size.width, model.cachedCellHeight + 10*3) font:font width:_customTextView.frame.size.width point:CGPointZero alignment:NSTextAlignmentLeft color:[messageText textColor]];
    

    messageText.attributedText = attributedText;
    
//    firstNameLabel.text = model.displayName;
//    priorityLabel.text = [NSString stringWithFormat:@"%f", model.priority];
    
//    self.profileImageView.image = nil;
////    messageText.contentInset = UIEdgeInsetsMake(0, 0, 0, 0);
////    messageText.backgroundColor = [UIColor colorWithRed:0 green:1 blue:0 alpha:0.5];
    textHeightConstraint.constant = model.cachedCellHeight + 10*3 - 7;
    
    
//    - (void)_drawLabel:(NSString *)label withFont:(UIFont *)font forWidth:(CGFloat)width
//atPoint:(CGPoint)point withAlignment:(UITextAlignment)alignment color:(UIColor *)color
    
    super.model = model;
}

+(UIFont*)fontForMessageTextView
{
    return [UIFont fontWithName:@"Avenir-Light" size:14];
}
+(CGSize)heightOfMessageTextViewWithInput:(NSString*)inputText
{

    UIFont *font = [SWTextCell fontForMessageTextView];
    
    UILabel *fakeLabel = [[UILabel alloc] initWithFrame:CGRectMake(0, 0, 232-2-10, 400)];
    fakeLabel.font = font;
    fakeLabel.text = inputText;
    fakeLabel.numberOfLines = 0;
    
    NSAttributedString *attributedText = [[NSAttributedString alloc] initWithString:inputText attributes:@{NSFontAttributeName: font}];
//    CGSize size = [fakeLabel sizeThatFits:fakeLabel.frame.size];//[attributedText boundingRectWithSize:CGSizeMake(232, 400) options:(NSStringDrawingUsesLineFragmentOrigin) context:nil].size;
    CGSize size = [attributedText boundingRectWithSize:CGSizeMake(232-2-10, 400) options:(NSStringDrawingUsesLineFragmentOrigin) context:nil].size;
    
//    size.height = 10*3;
    
    
    return size;
}
+(CGFloat)heightWithMessageModel:(MessageModel*)model
{
    
    NSString *text = model.text;
    CGSize size = [SWTextCell heightOfMessageTextViewWithInput:text];
    
//    size.height = 28 + size.height + 16 + 10;
    size.height = size.height + 16;
    
    return size.height;
}



@end
