//
//  FCAccountPickerViewController.h
//  Firechat
//
//  Created by Alonso Holmes on 12/31/13.
//  Copyright (c) 2013 Buildco. All rights reserved.
//

#import <UIKit/UIKit.h>

@protocol PickerDelegate
- (void) pickComplete:(NSInteger *)pick;
- (void) pickFailed;
@end

@interface FCAccountPickerViewController : UIViewController{
    UIViewController *delegate;
}

@property UIViewController *delegate;
@end
