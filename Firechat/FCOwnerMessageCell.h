//
//  FCOwnerMessageCell.h
//  Earshot
//
//  Created by Ethan Sherr on 4/3/14.
//  Copyright (c) 2014 Buildco. All rights reserved.
//

#import <UIKit/UIKit.h>
#import "AsyncImageView.h"
#import "FCMessage.h"

@interface FCOwnerMessageCell : UITableViewCell
@property (nonatomic) NSString *ownerID;

//@property (weak, nonatomic) IBOutlet UIImageView *profilePhoto;
//@property (weak, nonatomic) IBOutlet UILabel *username;
//@property (weak, nonatomic) IBOutlet UILabel *messageText;
//@property (weak, nonatomic) IBOutlet UILabel *timestamp;
@property (weak, nonatomic) IBOutlet UILabel *messageText;

@property (nonatomic) CAShapeLayer *lineLayer;
@property (weak, nonatomic) IBOutlet UIImageView *profilePhoto;

- (void)setMessage:(FCMessage *)message;

-(void)setFaded:(BOOL)faded animated:(BOOL)animated;

-(void)addTapDebugGestureIfNecessary;

@end
