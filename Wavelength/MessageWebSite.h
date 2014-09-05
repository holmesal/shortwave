//
//  MessageWebSite.h
//  Shortwave
//
//  Created by Ethan Sherr on 8/11/14.
//  Copyright (c) 2014 Ethan Sherr. All rights reserved.
//

#import "MessageCell.h"

@interface MessageWebSite : MessageModel

@property (strong, nonatomic) NSString *url;
@property (strong, nonatomic) NSString *siteName;
@property (strong, nonatomic) NSString *image;
@property (strong, nonatomic) NSString *description;
@property (strong, nonatomic) NSString *favicon;
@property (strong, nonatomic) NSString *title;

@end
