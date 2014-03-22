//
//  FCLEErrorViewController.m
//  Firechat
//
//  Created by Ethan Sherr on 3/22/14.
//  Copyright (c) 2014 Buildco. All rights reserved.
//

#import "FCLEErrorViewController.h"
#import "FCLiveBlurButton.h"
@interface FCLEErrorViewController ()
@property (weak, nonatomic) IBOutlet UILabel *label;
@property (weak, nonatomic) IBOutlet FCLiveBlurButton *tryAgainBlurButton;
@end

@implementation FCLEErrorViewController
@synthesize tryAgainBlurButton;


-(void)viewDidLoad
{
    [super viewDidLoad];
}

-(void)viewDidAppear:(BOOL)animated
{
    [super viewDidAppear:animated];
    
    [tryAgainBlurButton invalidatePressedLayer];
    
    [tryAgainBlurButton addTarget:self action:@selector(tryAgainBlurButtonAction:) forControlEvents:UIControlEventTouchUpInside];
}

-(void)tryAgainBlurButtonAction:(UIButton*)button
{
    [self.navigationController popViewControllerAnimated:YES];
}





@end
