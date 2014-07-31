//
//  UITextField+CustomFont.m
//  Salute
//
//  Created by Ethan Sherr on 6/2/14.
//  Copyright (c) 2014 Ethan Sherr. All rights reserved.
//

#import "UITextField+CustomFont.h"

@implementation UITextField (TCCustomFont)

- (NSString *)fontName {
    return self.font.fontName;
}

- (void)setFontName:(NSString *)fontName {
    self.font = [UIFont fontWithName:fontName size:self.font.pointSize];
}

@end