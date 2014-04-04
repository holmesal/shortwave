//
//  FCWallViewController.h
//  Firechat
//
//  Created by Alonso Holmes on 2/2/14.
//  Copyright (c) 2014 Buildco. All rights reserved.
//

#import <UIKit/UIKit.h>
#import <PHFComposeBarView/PHFComposeBarView.h>



@interface FCWallViewController : UIViewController <UITableViewDelegate, UITableViewDataSource, PHFComposeBarViewDelegate>

- (NSInteger)numberOfSectionsInTableView:(UITableView *)tableView;


-(void)beginTransitionWithIcon:(UIImage*)image andFrame:(CGRect)frame andColor:(UIColor*)backgroundColor andResetFrame:(CGRect)resetIconFrame isAnimated:(BOOL)animated;
@property (nonatomic) NSString *iconName;
@end
