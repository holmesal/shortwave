//
//  MessageFile.m
//  Wavelength
//
//  Created by Ethan Sherr on 9/5/14.
//  Copyright (c) 2014 Ethan Sherr. All rights reserved.
//

#import "MessageFile.h"

@implementation MessageFile

-(id)initWithDictionary:(NSDictionary *)dictionary andPriority:(double)priority
{
    if (self = [super initWithDictionary:dictionary andPriority:priority])
    {
        
    }
    return self;
}

-(id)initWithFileName:(NSString*)fileName contentType:(NSString*)contentType andImageSize:(CGSize)imageSize andOwnerID:(NSString*)ownerID
{
    if (self = [super initWithOwnerID:ownerID andText:@""])
    {
        _fileName = fileName;
        _contentType = contentType;
        _imageSize = imageSize;
    }
    return self;
}

-(id)initWithFileName:(NSString*)fileName contentType:(NSString*)contentType andOwnerID:(NSString*)ownerID
{
    self = [self initWithFileName:fileName contentType:contentType andImageSize:CGSizeZero andOwnerID:ownerID];
    return self;
}

-(BOOL)setDictionary:(NSDictionary *)dictionary
{
    BOOL success = [super setDictionary:dictionary];
    
    NSDictionary *content = dictionary[@"content"];
    if (content && [content isKindOfClass:[NSDictionary class]])
    {
        _fileName = content[@"fileName"];
        success = success && (_fileName && [_fileName isKindOfClass:[NSString class]]);
        
        _contentType = content[@"contentType"];
        success = success && (_contentType && [_contentType isKindOfClass:[NSString class]]);
        
        NSString *sizeString = content[@"imageSize"];
        if (sizeString)
        {
            success = success && (sizeString && [sizeString isKindOfClass:[NSString class]]);
            _imageSize = CGSizeFromString(sizeString);
        } else
        {
            _imageSize = CGSizeZero;
        }
    }
    return NO;
}

-(MessageModelType)type
{
    return MessageModelTypeFile;
}

-(NSDictionary*)toDictionary
{
    NSDictionary *content = (_imageSize.width == 0 && _imageSize.height == 0) ?
                            @{@"fileName": _fileName,
                              @"contentType": _contentType} :
                            @{@"fileName": _fileName,
                              @"contentType": _contentType,
                              @"imageSize": NSStringFromCGSize(_imageSize)};
//    NSLog(@"content = %@", content);
    return [self toDictionaryWithContent:content andType:@"file"];
}

-(CGSize)size
{
    return _imageSize;
}

-(NSString*)key
{
    return self.fileName;
}

@end
