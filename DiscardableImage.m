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

@synthesize imageOrGif;
@synthesize isGif;

-(id)initWithImageOrGif:(id)obj isGif:(BOOL)isGifff
{
    if (self = [super init])
    {
        imageOrGif = obj;
        isGif = isGifff;
        contentHasBeenAccessed = NO;
    }
    return self;
}
-(id)imageOrGif
{
    contentHasBeenAccessed = YES;
    return imageOrGif;
}


#pragma mark NSDiscardableContent stuff

- (BOOL)beginContentAccess
{
    return contentHasBeenAccessed && (imageOrGif);
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
    imageOrGif = nil;
}
- (BOOL)isContentDiscarded
{
    return (!imageOrGif);
}




-(void)dealloc
{
    NSLog(@"DiscardableImage");
}

@end
