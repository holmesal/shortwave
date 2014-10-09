//
//  SWAtMentionCell.m
//  hashtag
//
//  Created by Ethan Sherr on 10/8/14.
//  Copyright (c) 2014 Ethan Sherr. All rights reserved.
//

#import "SWAtMentionCell.h"
#import "SWImageLoader.h"
#import "AppDelegate.h"

@interface SWAtMentionCell ()

@property (weak, nonatomic) IBOutlet UIImageView *imageView;
@property (weak, nonatomic) IBOutlet UILabel *nameLabel;
@property (strong, nonatomic) SWUser *user;

@end

@implementation SWAtMentionCell


-(void)awakeFromNib
{
    [super awakeFromNib];
    
    [self initialize];
}

-(void)initialize
{
    CALayer *roundLayer = [CALayer layer];
    [roundLayer setBackgroundColor:[UIColor whiteColor].CGColor];
    [roundLayer setBorderColor:[UIColor whiteColor].CGColor];
    [roundLayer setBorderWidth:1.0f];
    [roundLayer setCornerRadius:_imageView.frame.size.width/2];
    [roundLayer setFrame:_imageView.bounds];
    
    [_imageView.layer setMask:roundLayer];
    
 
    UIView *line = [[UIView alloc] initWithFrame:CGRectMake(_nameLabel.frame.origin.x, 40, [UIScreen mainScreen].bounds.size.width - _nameLabel.frame.origin.x, 0.5f)];
    [line setBackgroundColor:[UIColor colorWithWhite:151/255.0f alpha:1.0f]];
    
    [self addSubview:line];
}

-(NSString*)reuseIdentifier
{
    return @"SWAtMentionCell";
}

-(SWUser*)getUser
{
    return _user;
}
-(void)setUser:(SWUser*)user isPublic:(BOOL)public
{
    _user = user;
    [self customSetSelected:NO animated:NO];
    [_nameLabel setText:[_user getAutoCompleteKey:public]];
    
    [_imageView setImage:nil];

    SWImageLoader *imageLoader = ((AppDelegate*)([UIApplication sharedApplication].delegate)).imageLoader;
    [imageLoader loadImage:user.photo completionBlock:^(UIImage *image, BOOL synchronous)
    {
        if (_user == user)
        {
            [_imageView setImage:image];
        }
    } progressBlock:^(float p){}];
}

/*
// Only override drawRect: if you perform custom drawing.
// An empty implementation adversely affects performance during animation.
- (void)drawRect:(CGRect)rect
{
    // Drawing code
}
*/
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
