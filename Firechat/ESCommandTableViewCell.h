//
//  ESCommandTableViewCell.h
//  Shortwave
//
//  Created by Alonso Holmes on 5/20/14.
//  Copyright (c) 2014 Buildco. All rights reserved.
//

#import <UIKit/UIKit.h>

@interface ESCommandTableViewCell : UITableViewCell

//make these internal to the view to have some kind of incapsulation
//@property (weak, nonatomic) IBOutlet UILabel *nameLabel;
//@property (weak, nonatomic) IBOutlet UILabel *descriptionLabel;
//@property (weak, nonatomic) IBOutlet UIButton *button;
//@property (weak, nonatomic) IBOutlet UIView *colorBar;
//@property (weak, nonatomic) IBOutlet UIView *cursor;

- (void)startAnimating;

-(void)setCommand:(NSString*)command;
-(void)setNonQueryCommand:(NSString*)command;
-(void)setBarColor:(UIColor*)barColor;
-(void)setBarVisible:(NSNumber*)isVisible;
-(void)setDescription:(NSString*)description;

@end
