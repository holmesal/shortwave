//
//  UITextView+CustomFont.m
//  Shortwave
//
//  Created by Ethan Sherr on 8/12/14.
//  Copyright (c) 2014 Ethan Sherr. All rights reserved.
//

#import "UITextView+CustomFont.h"

@implementation UITextView (CustomFont)

- (NSString *)fontName {
    return self.font.fontName;
}

- (void)setFontName:(NSString *)fontName {
    self.font = [UIFont fontWithName:fontName size:self.font.pointSize];
}

@end
