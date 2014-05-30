//
//  DiscardableImage.m
//  Sharalike
//
//  Created by Ethan Sherr on 11/12/13.
//

#import "DiscardableImage.h"


@interface DiscardableImage ()

@property (assign, nonatomic) BOOL contentHasBeenAccessed;


@end


@implementation DiscardableImage
@synthesize contentHasBeenAccessed;

@synthesize gif;
@synthesize image;

-(id)initWithImage:(UIImage *)daImage
{
    if (self = [super init])
    {
        self.image = daImage;
        contentHasBeenAccessed = NO;
    }
    return self;
}
-(id)initWithGif:(AnimatedGif *)daGif
{
    if (self = [super init])
    {
        self.gif = daGif;
        contentHasBeenAccessed = NO;
    }
    return self;
}

-(UIImage*)image
{
    contentHasBeenAccessed = YES;
    return image;
}
-(AnimatedGif*)gif
{
    contentHasBeenAccessed = YES;
    return gif;
}

#pragma mark NSDiscardableContent stuff

- (BOOL)beginContentAccess
{
    return contentHasBeenAccessed && (image || gif);
}
- (void)endContentAccess
{
    /** DISCUSSION ** (From the docs)
     *    This method decrements the counter variable of the object,
     *    which will usually bring the value of the counter variable
     *    back down to 0, which allows the discardable contents of the
     *    object to be thrown away if necessary.
     */
    //what about arc!?
}
- (void)discardContentIfPossible
{
    self.image = nil;
    self.gif = nil;
}
- (BOOL)isContentDiscarded
{
    return (!image);
}


-(BOOL)isGif
{
    return gif ? YES : NO;
}

@end
