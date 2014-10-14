//
//  NSString+Extension.h
//  Shortwave
//
//  Created by Ethan Sherr on 9/3/14.
//  Copyright (c) 2014 Ethan Sherr. All rights reserved.
//

#import <Foundation/Foundation.h>

@interface NSString(Extension)
+(BOOL)validateUrlString:(NSString*)str;
- (NSString *)MD5String;
@end
