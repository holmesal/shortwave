//
//  ESCommandTableViewCell.m
//  Shortwave
//
//  Created by Alonso Holmes on 5/20/14.
//  Copyright (c) 2014 Buildco. All rights reserved.
//

#import "ESCommandTableViewCell.h"
#import "FCLiveBlurButton.h"
@interface ESCommandTableViewCell()

//no need to own animations like this unless we need to reference it again
@property (strong, nonatomic) CABasicAnimation *animation;

@property (weak, nonatomic) IBOutlet UILabel *nameLabel;
@property (weak, nonatomic) IBOutlet UILabel *descriptionLabel;
@property (weak, nonatomic) IBOutlet UILabel *nonQueryNameLabel;
@property (weak, nonatomic) IBOutlet UIButton *button;
@property (weak, nonatomic) IBOutlet UIView *colorBar;
@property (weak, nonatomic) IBOutlet UIView *cursor;
@property (weak, nonatomic) IBOutlet FCLiveBlurButton *blurButton;

@property (assign, nonatomic) BOOL setup;
@end

@implementation ESCommandTableViewCell
@synthesize colorBar;
@synthesize descriptionLabel;
@synthesize nameLabel;
@synthesize blurButton;
@synthesize nonQueryNameLabel;


- (void)awakeFromNib
{
    // Initialization code
    
//    [cell.button.layer setBorderWidth:0.5f];
//    [cell.button.layer setBorderColor:[UIColor whiteColor].CGColor];
//    [cell.button.layer setCornerRadius:cell.button.layer.bounds.size.height/2];
//    [cell.button addTarget:cell action:@selector(pulseButton) forControlEvents:UIControlEventTouchUpInside];
    
}

-(void)pressedButton
{
    UITableView *tableView =  (UITableView *)self.superview.superview;
//    [tableView.delegate tableView:tableView didSelectRowAtIndexPath:[NSIndexPath indexPathForRow:self.tag inSection:0]];

    [tableView.delegate performSelector:@selector(customCellSelectAtIndexPath:) withObject:[NSIndexPath indexPathForRow:self.tag inSection:0] ];
}

//- (void)setSelected:(BOOL)selected animated:(BOOL)animated
//{
//    [super setSelected:selected animated:animated];
//
//    // Configure the view for the selected state
//}

- (void)pulseButton
{
    [UIView animateWithDuration:0.3f
                          delay:0.0f
                        options:UIViewAnimationOptionAutoreverse
                     animations:^{
                         self.button.backgroundColor = [[UIColor whiteColor] colorWithAlphaComponent:1.0f];
                     }
                     completion:nil
     ];
}

- (void)startAnimating
{
    if (!self.setup)
    {
        self.setup = YES;
        float radius = blurButton.frame.size.height/2;
        [blurButton invalidatePressedLayer];
        [blurButton setRadius:radius];
        [blurButton setBackgroundColor:[UIColor clearColor]];
        [blurButton invalidatePressedLayer];
        [blurButton addTarget:self action:@selector(pressedButton) forControlEvents:UIControlEventTouchUpInside];
        [self setBackgroundColor:[UIColor clearColor]];
        [self setSelectionStyle:UITableViewCellSelectionStyleNone];
    }
    
    self.cursor.alpha = 1;
    
    CAAnimationGroup *animationGroup = [CAAnimationGroup animation];
    animationGroup.duration = 1.2f;
    animationGroup.repeatCount = INFINITY;
    animationGroup.autoreverses = YES;
    
    CAMediaTimingFunction *easeOut = [CAMediaTimingFunction functionWithName:kCAMediaTimingFunctionEaseInEaseOut];
    
    CABasicAnimation *show = [CABasicAnimation animationWithKeyPath:@"opacity"];
    show.duration = 0.5f;
    show.fromValue = @0;
    show.toValue = @1;
    show.timingFunction = easeOut;
    
    animationGroup.animations = @[show];
    
    [self.cursor.layer addAnimation:animationGroup forKey:@"cursor"];

}

-(void)setBarColor:(UIColor *)barColor
{
    colorBar.backgroundColor = barColor;
}
-(void)setDescription:(NSString *)description
{
    [descriptionLabel setText:description];
}
-(void)setCommand:(NSString *)command
{
    [nameLabel setText:command];
}
-(void)setNonQueryCommand:(NSString *)command
{
    [nonQueryNameLabel setText:command];
}
-(void)setBarVisible:(NSNumber*)isVisible
{
    self.colorBar.hidden = ![isVisible boolValue];
    self.cursor.hidden = ![isVisible boolValue];
}
@end
