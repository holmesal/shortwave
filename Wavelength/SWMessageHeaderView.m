//
//  SWMessageHeaderView.m
//  hashtag
//
//  Created by Ethan Sherr on 10/9/14.
//  Copyright (c) 2014 Ethan Sherr. All rights reserved.
//

#import "SWMessageHeaderView.h"

@interface SWMessageHeaderView ()

@property (weak, nonatomic) IBOutlet UILabel *nameLabel;
@property (weak, nonatomic) IBOutlet UIView *containerView;


@end

@implementation SWMessageHeaderView
//@synthesize user;
- (id)initWithFrame:(CGRect)frame
{
    self = [super initWithFrame:frame];
    if (self) {
        // Initialization code
    }
    return self;
}
-(void)awakeFromNib
{
    [super awakeFromNib];
    
    [_containerView setTransform:CGAffineTransformMakeRotation(M_PI)];
}
//-(void)setUser:(SWUser*)newValue
//{
//    user = newValue;
//    [_nameLabel setText:user.firstName];
//}

-(void)setPhoto:(NSString *)ownerPhoto andName:(NSString *)ownerName
{
    [_nameLabel setText:ownerName];
}

/*
// Only override drawRect: if you perform custom drawing.
// An empty implementation adversely affects performance during animation.
- (void)drawRect:(CGRect)rect
{
    // Drawing code
}
*/

@end
