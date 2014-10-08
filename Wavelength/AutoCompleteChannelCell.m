//
//  AutoCompleteChannelCell.m
//  hashtag
//
//  Created by Ethan Sherr on 10/6/14.
//  Copyright (c) 2014 Ethan Sherr. All rights reserved.
//

#import "AutoCompleteChannelCell.h"

@interface AutoCompleteChannelCell ()
@property (weak, nonatomic) IBOutlet UILabel *nameLabel;
@property (strong, nonatomic) QueryResult *data;
@property (weak, nonatomic) IBOutlet UILabel *countLabel;

@end


@implementation AutoCompleteChannelCell

@synthesize data;

-(void)awakeFromNib
{
    [super awakeFromNib];
    
    
}

-(void)setData:(QueryResult*)newValue
{
    [self customSetSelected:NO animated:NO];
    data = newValue;
    _nameLabel.text = data.text;
    _countLabel.text = [NSString stringWithFormat:@"%d", data.memberCount];
    
}

-(QueryResult*)data
{
    return data;
}


-(void)customSetSelected:(BOOL)selected animated:(BOOL)animated
{
    if (animated)
    {
        
        [UIView animateWithDuration:0.3f delay:0.0 options:UIViewAnimationOptionCurveEaseIn animations:^
         {
             [self customSetSelectedState:selected];
         } completion:^(BOOL finished){}];
    }
    else
    {
        [self customSetSelectedState:selected];
    }
}

-(void)customSetSelectedState:(BOOL)selected
{
    self.backgroundColor = selected ? [UIColor colorWithWhite:235/255.0f alpha:1.0f] : [UIColor whiteColor];
}


@end
