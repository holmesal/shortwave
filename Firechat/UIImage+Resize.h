//
//  UIImage+Resize.h
//  Earshot
//
//  Created by Ethan Sherr on 4/5/14.
//  Copyright (c) 2014 Buildco. All rights reserved.
//

#import <Foundation/Foundation.h>

@interface UIImage(Resize)

- (UIImage *)scaleToSize:(CGSize)size ;
- (UIImage *)scaleByFactor:(CGFloat)factor;


- (UIImage *)transparentBorderImage:(NSUInteger)borderSize;
@end
