//
//  ESViewController.h
//  Earshot
//
//  Created by Ethan Sherr on 4/9/14.
//  Copyright (c) 2014 Buildco. All rights reserved.
//
#import <PHFComposeBarView/PHFComposeBarView.h>
#import <UIKit/UIKit.h>
#import "UIImage+Resize.h"


@interface ESViewController : UIViewController

@property (nonatomic) PHFComposeBarView *composeBarView;
@property (nonatomic, strong) UIView *noInternetView;
-(void)esDealloc;

-(void)cancelDialUpSceneIfNecessary;

@end
