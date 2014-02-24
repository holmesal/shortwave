//
//  FCMessageCell.h
//  Firechat
//
//  Created by Alonso Holmes on 12/23/13.
//  Copyright (c) 2013 Buildco. All rights reserved.
//

#import <UIKit/UIKit.h>
#import "AsyncImageView.h"
#import "FCMessage.h"

@interface FCMessageCell : UITableViewCell
@property (weak, nonatomic) IBOutlet UIImageView *profilePhoto;
@property (weak, nonatomic) IBOutlet UILabel *username;
@property (weak, nonatomic) IBOutlet UILabel *messageText;
@property (weak, nonatomic) IBOutlet UILabel *timestamp;

- (void)setMessage:(FCMessage *)message;
// Not the best place to expose this but whatever you only live once
- (UIColor *) colorWithHexString: (NSString *) hexString;

@end
