//
//  ESCommandTableViewCell.m
//  Shortwave
//
//  Created by Alonso Holmes on 5/20/14.
//  Copyright (c) 2014 Buildco. All rights reserved.
//

#import "ESCommandTableViewCell.h"

@implementation ESCommandTableViewCell

- (IBAction)FakeButtonClicked:(id)sender {
    UITableView *tableView = (UITableView *)self.superview.superview;
    [[tableView delegate] tableView:tableView didSelectRowAtIndexPath:[NSIndexPath indexPathForRow:self.tag inSection:0]];
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

@end
