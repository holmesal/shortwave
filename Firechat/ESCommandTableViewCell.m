//
//  ESCommandTableViewCell.m
//  Shortwave
//
//  Created by Alonso Holmes on 5/20/14.
//  Copyright (c) 2014 Buildco. All rights reserved.
//

#import "ESCommandTableViewCell.h"

@interface ESCommandTableViewCell()

@property (strong, nonatomic) CABasicAnimation *animation;

@end

@implementation ESCommandTableViewCell

- (IBAction)FakeButtonClicked:(id)sender {
    UITableView *tableView = (UITableView *)self.superview.superview;
    [[tableView delegate] tableView:tableView didSelectRowAtIndexPath:[NSIndexPath indexPathForRow:self.tag inSection:0]];
}

-(id)initWithCoder:(NSCoder *)aDecoder
{
    self = [super initWithCoder:aDecoder];
    if (self) {
        // Register for touch events
//        [self.button addTarget:self action:@selector(pulseButton) forControlEvents:UIControlEventTouchUpInside];
//        self.currentlyAnimating = NO;
    }
    return self;
}

- (id)initWithStyle:(UITableViewCellStyle)style reuseIdentifier:(NSString *)reuseIdentifier
{
    self = [super initWithStyle:style reuseIdentifier:reuseIdentifier];
    if (self) {
        // Initialization code
        
        
    }
    return self;
}

- (void)awakeFromNib
{
    // Initialization code
}

- (void)setSelected:(BOOL)selected animated:(BOOL)animated
{
    [super setSelected:selected animated:animated];

    // Configure the view for the selected state
}

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
    
    self.animation = [CABasicAnimation animationWithKeyPath:@"opacity"];
    self.animation.duration = 0.5f;
    self.animation.fromValue = @1;
    self.animation.toValue= @0;
    self.animation.autoreverses = YES;
    self.animation.repeatCount = MAXFLOAT;
    [self.cursor.layer addAnimation:self.animation forKey:@"cursor"];

}

@end
