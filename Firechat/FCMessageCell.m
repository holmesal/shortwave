//
//  FCMessageCell.m
//  Firechat
//
//  Created by Alonso Holmes on 12/23/13.
//  Copyright (c) 2013 Buildco. All rights reserved.
//

#import "FCMessageCell.h"

@implementation FCMessageCell

- (id)initWithStyle:(UITableViewCellStyle)style reuseIdentifier:(NSString *)reuseIdentifier
{
    self = [super initWithStyle:style reuseIdentifier:reuseIdentifier];
    if (self) {
        // Initialization code
        
    }
    return self;
}

- (void)setSelected:(BOOL)selected animated:(BOOL)animated
{
    [super setSelected:selected animated:animated];

    // Configure the view for the selected state
}

- (void)setMessage:(FCMessage *)message
{
    // Set message text
    self.messageText.text = message.text;
    // Set message icon
    [self setIcon:message.icon withColor:message.color];
}

- (void)setIcon:(NSString *)icon withColor:(NSString *)color
{
    // Grab the icon from the included PNGs
    self.profilePhoto.image = [UIImage imageNamed:[NSString stringWithFormat:@"%@.png",icon]];
    // Set the color
    self.profilePhoto.backgroundColor = [self colorWithHexString:color];
    // Mask, etc
    self.profilePhoto.layer.masksToBounds = YES;
    self.profilePhoto.layer.cornerRadius = self.profilePhoto.layer.frame.size.width/2;
}

- (UIColor *) colorWithHexString: (NSString *) hexString {
    NSString *colorString = [[hexString stringByReplacingOccurrencesOfString: @"#" withString: @""] uppercaseString];
    CGFloat alpha, red, blue, green;
    switch ([colorString length]) {
        case 3: // #RGB
            alpha = 1.0f;
            red   = [self colorComponentFrom: colorString start: 0 length: 1];
            green = [self colorComponentFrom: colorString start: 1 length: 1];
            blue  = [self colorComponentFrom: colorString start: 2 length: 1];
            break;
        case 4: // #ARGB
            alpha = [self colorComponentFrom: colorString start: 0 length: 1];
            red   = [self colorComponentFrom: colorString start: 1 length: 1];
            green = [self colorComponentFrom: colorString start: 2 length: 1];
            blue  = [self colorComponentFrom: colorString start: 3 length: 1];
            break;
        case 6: // #RRGGBB
            alpha = 1.0f;
            red   = [self colorComponentFrom: colorString start: 0 length: 2];
            green = [self colorComponentFrom: colorString start: 2 length: 2];
            blue  = [self colorComponentFrom: colorString start: 4 length: 2];
            break;
        case 8: // #AARRGGBB
            alpha = [self colorComponentFrom: colorString start: 0 length: 2];
            red   = [self colorComponentFrom: colorString start: 2 length: 2];
            green = [self colorComponentFrom: colorString start: 4 length: 2];
            blue  = [self colorComponentFrom: colorString start: 6 length: 2];
            break;
        default:
            [NSException raise:@"Invalid color value" format: @"Color value %@ is invalid.  It should be a hex value of the form #RBG, #ARGB, #RRGGBB, or #AARRGGBB", hexString];
            break;
    }
    return [UIColor colorWithRed: red green: green blue: blue alpha: alpha];
}

- (CGFloat) colorComponentFrom: (NSString *) string start: (NSUInteger) start length: (NSUInteger) length {
    NSString *substring = [string substringWithRange: NSMakeRange(start, length)];
    NSString *fullHex = length == 2 ? substring : [NSString stringWithFormat: @"%@%@", substring, substring];
    unsigned hexComponent;
    [[NSScanner scannerWithString: fullHex] scanHexInt: &hexComponent];
    return hexComponent / 255.0;
}

-(void)setFaded:(BOOL)faded animated:(BOOL)animated
{
    CGFloat targetAlpha = (faded? 0.2f : 1.0f);
    
    if (animated)
    {
        [UIView animateWithDuration:0.6f delay:0.0f usingSpringWithDamping:1.2f initialSpringVelocity:0.0f options:UIViewAnimationOptionCurveEaseInOut animations:^
        {
            self.messageText.alpha = targetAlpha;
        } completion:^(BOOL finishd){}];
    } else
    {
        self.messageText.alpha  = targetAlpha;
    }
}

@end
