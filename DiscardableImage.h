//
//  DiscardableImage.h
//  ESImageLoader
//
//  Created by Ethan Sherr on 5/15/14.
//  Copyright (c) 2014 Ethan Sherr. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <UIKit/UIKit.h>

@interface DiscardableImage : NSObject <NSDiscardableContent>

@property (strong, nonatomic) UIImage *image;

-(id)initWithImage:(UIImage*)daImage;


- (BOOL)beginContentAccess;
- (void)endContentAccess;
- (void)discardContentIfPossible;
- (BOOL)isContentDiscarded;


@end
