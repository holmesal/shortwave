//
//  ESShortbotOverlay.m
//  Shortwave
//
//  Created by Alonso Holmes on 5/20/14.
//  Copyright (c) 2014 Buildco. All rights reserved.
//

#import "ESShortbotOverlay.h"
#import "ESCommandTableViewCell.h"

@interface ESShortbotOverlay()

@property (assign, nonatomic) float animationDuration;
@property (strong, nonatomic) UITableView *tableView;
@property (strong, nonatomic) NSArray *commands;

@end

@implementation ESShortbotOverlay

- (ESShortbotOverlay *)initWithView:(UIView *)overlayView
{
    if (self = [super init]){
        
        self.animationDuration = 0.5;
        
        self.theView = overlayView;
        self.theView.alpha = 0.0f;
        
        // Find and set the table view
        for (UIView *view in self.theView.subviews)
        {
            NSLog(@"%@", view);
            if ([view isKindOfClass:[UITableView class]]){
                NSLog(@"found a table view!");
                self.tableView = (UITableView *)view;
            }
        }
        
        //
        self.commands = @[
                          @{@"title": @"image me <search>",
                            @"command": @"image me",
                            @"description": @"Searches for an image and posts is."},
                          @{@"title": @"animate me <search>",
                            @"command": @"animate me",
                            @"description": @"Like \"image me\", but for GIFs."},
                          @{@"title": @"mustache me <search>",
                            @"command": @"mustache me",
                            @"description": @"Like \"image me\", but adds a mustache."}
                          ];
        
        // Set yourself as a delegate
        self.tableView.dataSource = self;
        self.tableView.delegate = self;
        [self.tableView reloadData];
        
//        self.tableView.contentInset = UIEdgeInsetsMake(20, 0, 20, 0);
    }
    
    return self;
}

- (void)showOverlay
{
    self.theView.hidden = NO;
    [UIView animateWithDuration:self.animationDuration
                          delay:0.0
         usingSpringWithDamping:1.0
          initialSpringVelocity:0.0
                        options:UIViewAnimationOptionBeginFromCurrentState
                     animations:^{
                         self.theView.alpha = 1.0;
                     } completion:^(BOOL finished) {
                         self.theView.userInteractionEnabled = YES;
    }];
}

- (void)hideOverlay
{
    self.theView.userInteractionEnabled = NO;
    [UIView animateWithDuration:self.animationDuration
                          delay:0.0
         usingSpringWithDamping:1.0
          initialSpringVelocity:0.0
                        options:UIViewAnimationOptionBeginFromCurrentState
                     animations:^{
                         self.theView.alpha = 0.0;
                     } completion:^(BOOL finished) {
                         self.theView.hidden = YES;
                     }];
}


// Table view delegate methods
- (NSInteger)numberOfSectionsInTableView:(UITableView *)tableView
{
    return 1;
}

- (NSInteger)tableView:(UITableView *)tV numberOfRowsInSection:(NSInteger)section
{
    return [self.commands count];
}

- (UITableViewCell*)tableView:(UITableView *)tV cellForRowAtIndexPath:(NSIndexPath *)indexPath
{
    ESCommandTableViewCell *cell = [self.tableView dequeueReusableCellWithIdentifier:@"commandCell"];
    
    NSDictionary *command = [self.commands objectAtIndex:[indexPath row]];
    
    [cell setBackgroundColor:[UIColor clearColor]];
    
    [cell.nameLabel setText:[command objectForKey:@"title"]];
    [cell.descriptionLabel setText:[command objectForKey:@"description"]];
    
    cell.tag = [indexPath row];
    
    return cell;
}

- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath
{
    // Get the command
    NSString *command = [[self.commands objectAtIndex:[indexPath row]]objectForKey:@"command"];
//    NSString *commandString = [NSString stringWithFormat:@"%@ ",[command objectForKey:@"command"]];
    // TODO - set the input and focus on the text field
    [self.delegate shortbotOverlay:self didPickCommand:command];
    
    [self hideOverlay];
}

- (CGFloat)tableView:(UITableView *)tableView heightForRowAtIndexPath:(NSIndexPath *)indexPath
{
    return 100;
}


@end
