//
//  MessageSpotifyTrack.h
//  Shortwave
//
//  Created by Ethan Sherr on 7/14/14.
//  Copyright (c) 2014 Buildco. All rights reserved.
//

#import "MessageModel.h"

@interface MessageSpotifyTrack : MessageModel

@property (strong, nonatomic) NSString *title;
@property (strong, nonatomic) NSString *artist;
@property (strong, nonatomic) NSString *uri;
@property (strong, nonatomic) NSString *albumImage;


-(id)initWithTitle:(NSString*)Title uri:(NSString*)Uri artist:(NSString*)Artist albumImage:(NSString*)AlbumImage andIcon:(NSString *)icon color:(NSString *)color ownerID:(NSString *)ownerID text:(NSString *)text;

@end
