//
//  FCAccountPickerViewController.m
//  Firechat
//
//  Created by Alonso Holmes on 12/31/13.
//  Copyright (c) 2013 Buildco. All rights reserved.
//

#import "FCAccountPickerViewController.h"

@interface FCAccountPickerViewController ()

@end

@implementation FCAccountPickerViewController

- (id)initWithNibName:(NSString *)nibNameOrNil bundle:(NSBundle *)nibBundleOrNil
{
    self = [super initWithNibName:nibNameOrNil bundle:nibBundleOrNil];
    if (self) {
        // Custom initialization
        delegate = nil;
    }
    return self;
}

- (void)viewDidLoad
{
    [super viewDidLoad];
	// Do any additional setup after loading the view.
}

- (void)didReceiveMemoryWarning
{
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

@end
