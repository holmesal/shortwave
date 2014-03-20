//
//  UIColor.h
//  Sharalike
//
//  Created by Ethan Sherr on 1/13/14.
//  Copyright (c) 2014 Avincel Inc. All rights reserved.
//

#import <Foundation/Foundation.h>

@interface UIColor(HexString)

+ (UIColor *) colorWithHexString: (NSString *) hexString;
- (NSString *)toHexString;
@end
