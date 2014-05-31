//
//  DiscardableImage.h
//  ESImageLoader
//
//  Created by Ethan Sherr on 5/15/14.
//  Copyright (c) 2014 Ethan Sherr. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <UIKit/UIKit.h>
#import "AnimatedGif.h"

@interface DiscardableImage : NSObject <NSDiscardableContent>

@property (strong, nonatomic) id imageOrGif;
//-(id)initWithImage:(UIImage*)daImage;
//-(id)initWithGif:(AnimatedGif*)daGif;
-(id)initWithImageOrGif:(id)imageOrGif isGif:(BOOL)isGif;


- (BOOL)beginContentAccess;
- (void)endContentAccess;
- (void)discardContentIfPossible;
- (BOOL)isContentDiscarded;

@property (assign, nonatomic, readonly) BOOL isGif;

@end
