//
//  UILabel+CustomFont.m
//  Salute
//
//  Created by Ethan Sherr on 6/2/14.
//  Copyright (c) 2014 Ethan Sherr. All rights reserved.
//

#import "UILabel+CustomFont.h"

@implementation UILabel (CustomFont)

- (NSString *)fontName
{
    return self.font.fontName;
}

- (void)setFontName:(NSString *)fontName
{
//    fontName = [fontName stringByReplacingOccurrencesOfString:@".ttf" withString:@""];
    UIFont *font = [UIFont fontWithName:fontName size:self.font.pointSize];
    if (!font)
    {
        NSLog(@"WARNING FONT IS NULL! font = '%@' for name '%@'", font, fontName);
    }
    self.font = font;
}


@end
