//
//  SWGifCell.m
//  Shortwave
//
//  Created by Ethan Sherr on 8/3/14.
//  Copyright (c) 2014 Ethan Sherr. All rights reserved.
//

#import "SWGifCell.h"
#import "MessageGif.h"
#import "AppDelegate.h"
#import <AVFoundation/AVFoundation.h>

@interface SWGifCell ()

@property (weak, nonatomic) IBOutlet UIView *gifContainer;
@property (weak, nonatomic) IBOutlet UIView *mp4View;

@property (strong, nonatomic) AVPlayer *player;

@property (strong, nonatomic) UILongPressGestureRecognizer *longPressGesture;
@end



@implementation SWGifCell

@synthesize longPressGesture;

-(void)awakeFromNib
{
    _gifContainer.transform = CGAffineTransformMakeRotation(M_PI);
    
    
    longPressGesture = [[UILongPressGestureRecognizer alloc] initWithTarget:self action:@selector(didLongPress:)];
    longPressGesture.cancelsTouchesInView = NO;
    longPressGesture.minimumPressDuration = 0.04f;
    [self.mp4View setUserInteractionEnabled:YES];
    [self.mp4View addGestureRecognizer:longPressGesture];

    
}

-(void)didLongPress:(id)sender
{
    UICollectionView *collectionView = (UICollectionView *)self.superview;
    
    if ([collectionView.delegate respondsToSelector:@selector(didLongPress:)])
    {
        self.longPress = sender;
        [collectionView.delegate performSelector:@selector(didLongPress:) withObject:self];
    } else
    {
        NSLog(@"WARNING: SWImageCell fails to LongPress, collectionView.delegate does not respond to selector %@", NSStringFromSelector(_cmd));
    }
    
    self.longPress = nil;
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
    if (_player)
    {
        [_player pause];
    }
    _player = model.player;

    AppDelegate* appDelegate = (AppDelegate*)[UIApplication sharedApplication].delegate;
    __weak SWGifCell *weakSelf = self;
    
    __block AVPlayerLayer *playerLayer = [model avplayerlayer];
    if (playerLayer && playerLayer.superlayer)
    {
        [playerLayer removeFromSuperlayer];
    }
    
    NSString *mp4Str = model.mp4;
    [appDelegate.imageLoader loadVideo:mp4Str completionBlock:^(NSString *videoPath, BOOL synchronous)
    {
        if (model.mp4 && [mp4Str isEqualToString:model.mp4])
        {
            if (!_player)
            {
                [model generatePlayer];
                weakSelf.player = model.player;
                playerLayer = [model avplayerlayer];
            }
            playerLayer.bounds = _mp4View.bounds;
            playerLayer.position = CGPointMake(_mp4View.bounds.size.width*0.5f, _mp4View.bounds.size.height*0.5f);
            playerLayer.backgroundColor = [UIColor clearColor].CGColor;
            [weakSelf.mp4View.layer addSublayer:playerLayer];

            [weakSelf.player play];
            [[NSNotificationCenter defaultCenter] addObserver:self
                                                     selector:@selector(playerItemDidReachEnd:)
                                                         name:AVPlayerItemDidPlayToEndTimeNotification
                                                       object:[weakSelf.player currentItem]];
            
            
        }
    } progressBlock:^(float progress)
    {
        if (model.mp4 && [mp4Str isEqualToString:model.mp4])
        {
            NSLog(@"videoProgress %f", progress);
        }
        
    }];


    

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

- (IBAction)flagButtonAction:(id)sender
{
    UICollectionView *collectionView = (UICollectionView *)self.superview;
    if ([collectionView.delegate respondsToSelector:@selector(userTappedFlagOnMessageModel:)])
    {
        [collectionView.delegate performSelector:@selector(userTappedFlagOnMessageModel:) withObject:self.model];
    }
}

-(void)dealloc
{
    [[NSNotificationCenter defaultCenter] removeObserver:self];
}

@end
