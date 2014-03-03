//
//  ProfileCollectionViewCell.m
//  Firechat
//
//  Created by Ethan Sherr on 3/3/14.
//  Copyright (c) 2014 Buildco. All rights reserved.
//

#import "ProfileCollectionViewCell.h"
#import "UIView+Glow.h"
#import "UIImage+AverageColor.h"

@interface ProfileCollectionViewCell ()


@property (weak, nonatomic) IBOutlet AsyncImageView *asyncImageView;
@property (nonatomic) UIColor *glowColor; //as calculated by UIImage+AverageColor or retrieved from static NSCache cacheOfUrlsToColors

@end

static NSCache *cacheOfUrlsToColors;
@implementation ProfileCollectionViewCell


@synthesize asyncImageView;
@synthesize glowColor; //default is white for now

- (id)initWithFrame:(CGRect)frame
{
    self = [super initWithFrame:frame];
    if (self)
    {
        //when an image is set, i will call this method
        [self observeValueForKeyPath:@"setImage" ofObject:asyncImageView change:nil context:0];
        
        if (!cacheOfUrlsToColors)
        {
            cacheOfUrlsToColors = [[NSCache alloc] init];
            [cacheOfUrlsToColors setCountLimit:60];
            glowColor = [UIColor whiteColor];
        }
    }
    return self;
}

/*
// Only override drawRect: if you perform custom drawing.
// An empty implementation adversely affects performance during animation.
- (void)drawRect:(CGRect)rect
{
    // Drawing code
}
*/

-(void)boop
{
    [self startGlowingWithColor:[UIColor whiteColor] fromIntensity:0 toIntensity:1 repeat:NO];
}

-(void)setImageURL:(NSURL*)url
{
    [asyncImageView setImageURL:url];
}

-(void)dealloc
{
    [asyncImageView removeObserver:self forKeyPath:@"setImage"];
}

-(void)observeValueForKeyPath:(NSString *)keyPath ofObject:(id)object change:(NSDictionary *)change context:(void *)context
{
    if ([keyPath isEqualToString:@"setImage"] && object == asyncImageView)
    {
#warning what if another async image is set before this one loads; then the image will correspond to the incorrect URL?
        NSURL *theUrl = asyncImageView.imageURL;
        UIImage *theImage = asyncImageView.image;
        
        if ( !(glowColor = [cacheOfUrlsToColors objectForKey:theUrl.absoluteString] ) )
        {
            glowColor = [theImage averageColor];
            [cacheOfUrlsToColors setObject:glowColor forKey:theUrl.absoluteString];
        }
        NSLog(@"image got loaded, color got set to %@", glowColor);
    }
}

@end
