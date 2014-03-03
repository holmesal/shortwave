//
//  UIImage+AverageColor.h
//  Firechat
//
//  Created by Ethan Sherr on 3/3/14.
//  Copyright (c) 2014 Buildco. All rights reserved.
//


//#import &lt;UIKit/UIKit.h&gt;
#import <UIKit/UIKit.h>




@interface UIImage(AverageColor)

//gets the average color via super speedy vector graphic renderer
-(UIColor*)averageColor;

@end
