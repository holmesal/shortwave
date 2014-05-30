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

@property (strong, nonatomic) UIImage *image;
@property (strong, nonatomic) AnimatedGif *gif;

-(id)initWithImage:(UIImage*)daImage;
-(id)initWithGif:(AnimatedGif*)daGif;


- (BOOL)beginContentAccess;
- (void)endContentAccess;
- (void)discardContentIfPossible;
- (BOOL)isContentDiscarded;

-(BOOL)isGif;

@end
