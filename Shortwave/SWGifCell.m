//
//  SWGifCell.m
//  Shortwave
//
//  Created by Ethan Sherr on 8/3/14.
//  Copyright (c) 2014 Ethan Sherr. All rights reserved.
//

#import "SWGifCell.h"
#import "MessageGif.h"
#import <AVFoundation/AVFoundation.h>

@interface SWGifCell ()

@property (weak, nonatomic) IBOutlet UIView *gifContainer;
@property (weak, nonatomic) IBOutlet UIView *mp4View;

@property (strong, nonatomic) AVPlayer *player;
@end



@implementation SWGifCell
-(void)awakeFromNib
{
    _gifContainer.transform = CGAffineTransformMakeRotation(M_PI);
}

-(void)setModel:(MessageGif *)model
{
    //cleanup
    if (super.model)
    {
        [[NSNotificationCenter defaultCenter] removeObserver:self];
//        [_player pause];
        
        //cleanup
        for (CALayer *sublayer in _mp4View.layer.sublayers)
        {
            [sublayer removeFromSuperlayer];
        }
    }
    
    _player = model.player;
    AVPlayerLayer *playerLayer = [AVPlayerLayer playerLayerWithPlayer:_player];
    playerLayer.bounds = _mp4View.bounds;
    playerLayer.position = CGPointMake(_mp4View.bounds.size.width*0.5f, _mp4View.bounds.size.height*0.5f);
    playerLayer.backgroundColor = [UIColor redColor].CGColor;
    [_mp4View.layer addSublayer:playerLayer];
    
    [_player play];
    [[NSNotificationCenter defaultCenter] addObserver:self
                                             selector:@selector(playerItemDidReachEnd:)
                                                 name:AVPlayerItemDidPlayToEndTimeNotification
                                               object:[_player currentItem]];

    

    super.model = model;
}

-(void)playerItemDidReachEnd:(NSNotification*)note
{
//    if (note.object == self.gifMessage.playerItem)
//    {
//        
        [_player seekToTime:kCMTimeZero];
//        [_player play];
//
//    }
}

-(MessageGif*)gifMessage
{
    return (MessageGif *)self.model;
}

+(CGFloat)heightWithMessageModel:(MessageModel *)model
{
    return 100;
}

-(void)dealloc
{
    [[NSNotificationCenter defaultCenter] removeObserver:self];
}

@end