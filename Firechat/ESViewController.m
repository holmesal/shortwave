//
//  ESViewController.m
//  Earshot
//
//  Created by Ethan Sherr on 4/9/14.
//  Copyright (c) 2014 Buildco. All rights reserved.
//

#import "ESViewController.h"
#import <PHFComposeBarView/PHFComposeBarView.h>

@interface ESViewController ()

@property (nonatomic) PHFComposeBarView *composeBarView;

@end

@implementation ESViewController
@synthesize composeBarView;

- (void)viewDidLoad
{
    [super viewDidLoad];

    //find a certain view
    
    composeBarView = [self findComposeBarView:self.view];
    if (composeBarView)
    {
        
    }
}


//recursive (depth-first) method to exhaustively search for composeBarView
-(PHFComposeBarView *)findComposeBarView:(UIView*)parent
{
    for (UIView *subView in parent.subviews)
    {
        NSLog(@"subview = %@", subView);
        if ([subView isKindOfClass:[PHFComposeBarView class]])
        {
            return (PHFComposeBarView*)subView;
        } else
        {
            return [self findComposeBarView:subView];
        }
    }
    //none found
    return nil;
}

- (void)didReceiveMemoryWarning
{
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

/*
#pragma mark - Navigation

// In a storyboard-based application, you will often want to do a little preparation before navigation
- (void)prepareForSegue:(UIStoryboardSegue *)segue sender:(id)sender
{
    // Get the new view controller using [segue destinationViewController].
    // Pass the selected object to the new view controller.
}
*/

@end
