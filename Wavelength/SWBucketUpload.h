//
//  SWBucketUpload.h
//  Wavelength
//
//  Created by Ethan Sherr on 9/5/14.
//  Copyright (c) 2014 Ethan Sherr. All rights reserved.
//

#import <Foundation/Foundation.h>

@interface SWBucketUpload : NSObject
+(SWBucketUpload*)sharedInstance;
-(void)uploadData:(NSData*)data forName:(NSString*)fileName contentType:(NSString*)contentType progress:(void(^)(CGFloat p))progress andComlpetion:(void(^)(NSError *error))completion;

@end
