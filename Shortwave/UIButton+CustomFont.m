//
//  UIButton+CustomFont.m
//  Salute
//
//  Created by Ethan Sherr on 6/2/14.
//  Copyright (c) 2014 Ethan Sherr. All rights reserved.
//

#import "UIButton+CustomFont.h"

@implementation UIButton (CustomFont)

- (NSString *)fontName {
    return self.titleLabel.font.fontName;
}

- (void)setFontName:(NSString *)fontName {
    self.titleLabel.font = [UIFont fontWithName:fontName size:self.titleLabel.font.pointSize];
}

@end
