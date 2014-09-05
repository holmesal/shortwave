//
//  SWSpotifyTrackCell.m
//  Shortwave
//
//  Created by Ethan Sherr on 7/15/14.
//  Copyright (c) 2014 Buildco. All rights reserved.
//

#import "SWSpotifyTrackCell.h"
#import "MessageSpotifyTrack.h"

@interface SWSpotifyTrackCell ()

@property (weak, nonatomic) IBOutlet UILabel *titleLabel;
@property (weak, nonatomic) IBOutlet UILabel *artistLabel;
@property (weak, nonatomic) IBOutlet UIButton *playButton;

@property (weak, nonatomic) IBOutlet UIImageView *iconImageView;
@property (weak, nonatomic) IBOutlet UIView *iconImageViewContainer;

@property (nonatomic, strong) CALayer *coloredCircleLayer;
@property (weak, nonatomic) IBOutlet UITextView *textLabel;

@end

@implementation SWSpotifyTrackCell

@synthesize titleLabel;
@synthesize artistLabel;
@synthesize coloredCircleLayer;

@synthesize iconImageViewContainer;
@synthesize iconImageView;
@synthesize textLabel;

/*
// Only override drawRect: if you perform custom drawing.
// An empty implementation adversely affects performance during animation.
- (void)drawRect:(CGRect)rect
{
    // Drawing code
}
*/

-(CALayer*)coloredCircleLayer
{
    if (!coloredCircleLayer)
    {
        CGFloat radius = iconImageViewContainer.frame.size.width/2;
        coloredCircleLayer = [CALayer layer];
        [coloredCircleLayer setBackgroundColor:[UIColor blackColor].CGColor];
        [coloredCircleLayer setBorderColor:[UIColor clearColor].CGColor];
        [coloredCircleLayer setCornerRadius:radius];
        
        
        CGRect frame = CGRectMake(-0.5f, -0.0f, radius*2+1, radius*2+1);
        frame.origin.x += (iconImageViewContainer.frame.size.width-frame.size.width)*0.5f;
        frame.origin.y += (iconImageViewContainer.frame.size.height-frame.size.height)*0.5f;
        [coloredCircleLayer setFrame:frame];
        
        [iconImageViewContainer.layer insertSublayer:coloredCircleLayer atIndex:0];
    }
    return coloredCircleLayer;
}

-(void)setModel:(MessageSpotifyTrack *)spotifyTrack
{
    textLabel.text = spotifyTrack.text;
    titleLabel.text = spotifyTrack.title;
    artistLabel.text = spotifyTrack.artist;
    
//    [self.coloredCircleLayer setBackgroundColor:spotifyTrack.color.CGColor];
//    UIImage *img = [UIImage imageNamed:[NSString stringWithFormat:@"%@.png", spotifyTrack.icon] ];
//    iconImageView.image = img;
    
    super.model = spotifyTrack;
}

- (IBAction)playButtonAction:(id)sender
{
    MessageSpotifyTrack *spotifyTrack = (MessageSpotifyTrack*)self.model;
    NSString *uri = spotifyTrack.uri;
    
    [[UIApplication sharedApplication] openURL:[NSURL URLWithString:uri]];
}

+(CGFloat)heightWithMessageModel:(MessageModel *)model
{
    return 135.0f;
}

@end
