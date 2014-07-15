//
//  MessageCell.m
//  Shortwave
//
//  Created by Ethan Sherr on 7/14/14.
//  Copyright (c) 2014 Buildco. All rights reserved.
//

#import "MessageCell.h"

#import "FCMessage.h"
#import "SWImageCell.h"
#import "SWTextCell.h"

@implementation MessageCell

+(void)registerCollectionViewCellsForCollectionView:(UICollectionView*)collectionView
{
    NSArray *cellIds = @[SWTextCellIdentifier, SWImageCellIdentifier];
    
    for (NSString *cellId in cellIds)
    {
        UINib *nib = [UINib nibWithNibName:cellId bundle:nil];
        [collectionView registerNib:nib forCellWithReuseIdentifier:cellId];
    }

}

+(MessageCell*)messageCellFromMessageModel:(MessageModel*)messageModel andCollectionView:(UICollectionView*)collectionView forIndexPath:(NSIndexPath*)indexPath
{
    
    switch (messageModel.type)
    {
        case MessageModelTypePlainText:
        {//no owner differentiation
            
            
            
            SWTextCell *textCell = (SWTextCell*)[collectionView dequeueReusableCellWithReuseIdentifier:SWTextCellIdentifier forIndexPath:indexPath];
            return textCell;
            
            NSLog(@"textCell = %@", textCell);
            
        }
        break;
        
        case MessageModelTypeImage:
        {
            NSLog(@"MessageModelTypeImage");
            
            SWImageCell *imageCell = (SWImageCell*)[collectionView dequeueReusableCellWithReuseIdentifier:SWImageCellIdentifier forIndexPath:indexPath];
            return imageCell;
        }
        break;
        
        case MessageModelTypeGif:
        {
            NSLog(@"MessageModelTypeGif");
        }
        break;
        
        case MessageModelTypeSpotifyTrack:
        {
            NSLog(@"MessageModelTypeSpotifyTrack");
        }
        break;
            
        case MessageModelTypeLinkWeb:
        {
            NSLog(@"MessageModelTypeLinkWeb");
        }
        break;
            
        case MessageModelTypePersonalPhoto:
        {
            NSLog(@"MessageModelTypePersonalPhoto");
        }
        break;
        
        case MessageModelTypePersonalVideo:
        {
            NSLog(@"MessageModelTypePersonalVideo");
        }
        break;
        
        case MessageModelTypeYoutubeVideo:
        {
            NSLog(@"MessageModelTypeYoutubeVideo");
        }
        break;
        
        default:
        {
            NSLog(@"NONE!");
            return nil;
        }
        break;
    }
    
    return nil;

}

-(void)setMessageModel:(MessageModel*)messageModel
{
    
}

@end
