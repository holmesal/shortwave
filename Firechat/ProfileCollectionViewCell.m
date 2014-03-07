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

#define flash_approach 1

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
        [self initialize];
    }
    return self;
}

-(void)initialize
{


    
    if (!cacheOfUrlsToColors)
    {
        cacheOfUrlsToColors = [[NSCache alloc] init];
        [cacheOfUrlsToColors setCountLimit:60];
        
        
#warning NO!  later
        //            [self observeValueForKeyPath:@"setImage" ofObject:asyncImageView change:nil context:0];
    }
    //when an image is set, i will call this method
    glowColor = [UIColor whiteColor];
    [self addGlowViewOfColor:glowColor];
}

-(void)awakeFromNib
{
    [self initialize];
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
    if (!flash_approach)
        [self startGlowingWithColor:[UIColor whiteColor] fromIntensity:0 toIntensity:1 repeat:YES];
}

-(void)setTurnOn:(BOOL)isOn
{
    if (flash_approach)
        [self setGlowViewHidden:!isOn];
}

-(void)setImageURL:(NSURL*)url
{
    [asyncImageView setImageURL:url];
#warning an interesting idea to bridge cast the @{ } so I lock down the url at the time of the load, incase 1 image does not load next image is set scenario
    
    [self observeValueForKeyPath:@"setImage" ofObject:asyncImageView change:@{@"imageURL": url.absoluteString} context:0];
}

-(void)dealloc
{
    [asyncImageView removeObserver:self forKeyPath:@"setImage"];
}

-(void)observeValueForKeyPath:(NSString *)keyPath ofObject:(id)object change:(NSDictionary *)change context:(void *)context
{
    if ([keyPath isEqualToString:@"setImage"] &&
        object == asyncImageView &&
        change)
    {
        
#warning what if another async image is set before this one loads; then the image will correspond to the incorrect URL?
        NSString *theAbsUrl = [change objectForKey:@"imageURL"];
        UIImage *theImage = asyncImageView.image;
        
        if ( !(glowColor = [cacheOfUrlsToColors objectForKey:theAbsUrl] ) )
        {
            glowColor = [theImage averageColor];
            [cacheOfUrlsToColors setObject:glowColor forKey:theAbsUrl];
            
        }
        
        if (flash_approach)
            [self addGlowViewOfColor:glowColor];
        NSLog(@"image got loaded, color got set to %@ for resource %@", glowColor, theAbsUrl);
    }
}

@end
