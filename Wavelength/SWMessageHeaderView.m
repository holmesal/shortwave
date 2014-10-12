//
//  SWMessageHeaderView.m
//  hashtag
//
//  Created by Ethan Sherr on 10/9/14.
//  Copyright (c) 2014 Ethan Sherr. All rights reserved.
//

#import "SWMessageHeaderView.h"
#import "SWImageLoader.h"
#import "AppDelegate.h"

@interface SWMessageHeaderView ()

@property (strong, nonatomic) NSString *ownerPhoto;
@property (weak, nonatomic) IBOutlet UILabel *nameLabel;
@property (weak, nonatomic) IBOutlet UIView *containerView;
@property (weak, nonatomic) IBOutlet UIImageView *imageView;


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
    
    CALayer *roundLayer = [CALayer layer];
    [roundLayer setCornerRadius:_imageView.frame.size.width/2];
    [roundLayer setBackgroundColor:[UIColor whiteColor].CGColor];
    [roundLayer setBorderColor:[UIColor whiteColor].CGColor];
    [roundLayer setBorderWidth:1.0f];
    [roundLayer setFrame:_imageView.bounds];
    
    [_imageView.layer setMask:roundLayer];
    
    
}
//-(void)setUser:(SWUser*)newValue
//{
//    user = newValue;
//    [_nameLabel setText:user.firstName];
//}

-(void)setPhoto:(NSString *)ownerPhoto andName:(NSString *)ownerName
{
    [_nameLabel setText:ownerName];
    _ownerPhoto = ownerPhoto;
    [_imageView setImage:nil];
    
    
    AppDelegate *app = (AppDelegate*)[UIApplication sharedApplication].delegate;
    [app.imageLoader loadImage:ownerPhoto completionBlock:^(UIImage *image, BOOL synch)
    {
        if ([_ownerPhoto isEqualToString:ownerPhoto])
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

@end
