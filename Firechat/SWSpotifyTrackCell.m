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

@end

@implementation SWSpotifyTrackCell

@synthesize titleLabel;
@synthesize artistLabel;

//- (instancetype)initWithFrame:(CGRect)frame
//{
//    self = [super initWithFrame:frame];
//    if (self) {
//        // Initialization code
//    }
//    return self;
//}

/*
// Only override drawRect: if you perform custom drawing.
// An empty implementation adversely affects performance during animation.
- (void)drawRect:(CGRect)rect
{
    // Drawing code
}
*/
-(void)setMessageModel:(MessageSpotifyTrack *)spotifyTrack
{
    titleLabel.text = spotifyTrack.title;
    artistLabel.text = spotifyTrack.artist;
    
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
