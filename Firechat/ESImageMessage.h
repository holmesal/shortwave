//
//  ESImageMessage.h
//  Shortwave
//
//  Created by Ethan Sherr on 5/18/14.
//  Copyright (c) 2014 Buildco. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <CoreLocation/CoreLocation.h>


@interface ESImageMessage : NSObject


@property (strong, nonatomic, readonly) CLLocation *location;
@property (strong, nonatomic, readonly) NSString *text;
@property (strong, nonatomic, readonly) NSString *ownerID;
@property (strong, nonatomic, readonly) NSString *icon;
@property (strong, nonatomic, readonly) NSString *color;
@property (strong, nonatomic, readonly) NSString *type;
@property (strong, nonatomic, readonly) NSString *url;

@property (assign, nonatomic, readonly) BOOL isGif;

-(id)initWithSnapshot:(FDataSnapshot*)snapshot;

-(void)testImageStaticMessage;
-(void)testImageGifMessage;

@end
