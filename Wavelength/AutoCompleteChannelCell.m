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
    data = newValue;
    _nameLabel.text = data.text;
    _countLabel.text = [NSString stringWithFormat:@"%d", data.memberCount];
    
}

-(QueryResult*)data
{
    return data;
}

@end
