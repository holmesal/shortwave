//
//  MessageCell.m
//  Shortwave
//
//  Created by Ethan Sherr on 7/14/14.
//  Copyright (c) 2014 Buildco. All rights reserved.
//

#import "MessageCell.h"
//#import "SWImageCell.h"
#import "SWTextCell.h"

//#import "ESImageLoader.h"
#import "MessageImage.h"
#import "SWSpotifyTrackCell.h"
#import "SWUserManager.h"

@implementation MessageCell

@synthesize model;

+(NSArray*)cellIds
{
    return @[SWTextCellIdentifier];//@[SWTextCellIdentifier, SWImageCellIdentifier, SWSpotifyTrackCellIdentifier];
}

+(void)registerCollectionViewCellsForCollectionView:(UICollectionView*)collectionView
{
    NSArray *cellIds = [MessageCell cellIds];
    
    for (NSString *cellId in cellIds)
    {
        UINib *nib = [UINib nibWithNibName:cellId bundle:nil];
        [collectionView registerNib:nib forCellWithReuseIdentifier:cellId];
    }
}

+(MessageCell*)messageCellFromMessageModel:(MessageModel*)messageModel andCollectionView:(UICollectionView*)collectionView forIndexPath:(NSIndexPath*)indexPath andWallSource:(WallSource*)wallSource;

{
    MessageCell *messageCell = nil;
    
    switch (messageModel.type)
    {
        case MessageModelTypePlainText:
        {//no owner differentiation
            
            SWTextCell *textCell = (SWTextCell*)[collectionView dequeueReusableCellWithReuseIdentifier:SWTextCellIdentifier forIndexPath:indexPath];
            
            messageCell = textCell;
            
        }
        break;
        
        case MessageModelTypeImage:
        {
////            SWImageCell *imageCell = (SWImageCell*)[collectionView dequeueReusableCellWithReuseIdentifier:SWImageCellIdentifier forIndexPath:indexPath];
//            [imageCell setModel:messageModel];
//            [imageCell loadImage:((MessageImage*)messageModel).src withImageCell:imageCell imageMessage:messageModel collectionView:collectionView wallSource:wallSource andIndexPath:indexPath];
//            
//            [imageCell initializeTouchGesturesFromCollectionViewIfNecessary:collectionView];
//            imageCell.tag = indexPath.row;
//            return imageCell;
            return nil;
        }
        break;
        
        case MessageModelTypeGif:
        {
            
//            SWImageCell *imageCell = (SWImageCell*)[collectionView dequeueReusableCellWithReuseIdentifier:SWImageCellIdentifier forIndexPath:indexPath];
//            [imageCell setModel:messageModel];
//            
//            [imageCell loadImage:((MessageImage*)messageModel).src withImageCell:imageCell imageMessage:messageModel collectionView:collectionView wallSource:wallSource andIndexPath:indexPath];
//            [imageCell initializeTouchGesturesFromCollectionViewIfNecessary:collectionView];
//            imageCell.tag = indexPath.row;
//            return imageCell;
            return nil;
        }
        break;
        
        case MessageModelTypeSpotifyTrack:
        {
            SWSpotifyTrackCell *spotifyTrackCell = (SWSpotifyTrackCell*)[collectionView dequeueReusableCellWithReuseIdentifier:SWSpotifyTrackCellIdentifier forIndexPath:indexPath];
            messageCell = spotifyTrackCell;
            
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

        }
        break;
    }
    //should always be non nil
    [messageCell setModel:messageModel];
    messageCell.tag = indexPath.row;
    return messageCell;

}




//BOOL hasCalculatedHeights;
+(CGFloat)heightOfMessageCellForModel:(MessageModel*)messageModel collectionView:(UICollectionView*)collectionView
{
    CGFloat height = 0;
    
//    if (!hasCalculatedHeights)
//    {
//        hasCalculatedHeights = YES;
//        for (NSString* cellId in [MessageCell cellIds])
//        {
//            //to initialize fonts and other things specified by xib, ensure fonts and frames & static values are initialized.
//            UITableViewCell *cell = [collectionView dequeueReusableCellWithReuseIdentifier:cellId forIndexPath:[NSIndexPath indexPathForItem:0 inSection:0]];
//            [cell setFrame:CGRectMake(0, 0, 320, 100)];
//        }
//    }
    
    switch (messageModel.type)
    {
        
        
        case MessageModelTypePlainText:
        {
            height = [SWTextCell heightWithMessageModel:messageModel];
        }
            break;
            
        case MessageModelTypeImage:
        {
//            height = [SWImageCell heightWithMessageModel:messageModel];
        }
            break;
            
        case MessageModelTypeGif:
        {
//            height = [SWImageCell heightWithMessageModel:messageModel];
        }
            break;
            
        case MessageModelTypeSpotifyTrack:
        {
            height = [SWSpotifyTrackCell heightWithMessageModel:messageModel];
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
            break;
    }

    
    
    return height;
    
}

//fill data, reset content & 
-(void)setModel:(MessageModel*)messageModel
{
    model = messageModel;
}


//programmatic counterpart ot resize logic
+(CGFloat)heightWithMessageModel:(MessageModel*)model
{

    NSString *text = model.text;
    
    UIFont *font = [UIFont fontWithName:@"HelveticaNeue-Light" size:14];
    NSAttributedString *attributedText =[[NSAttributedString alloc] initWithString:text attributes:
                                         @{ NSFontAttributeName: font }] ;
    
    CGSize size = [attributedText boundingRectWithSize:CGSizeMake(212, CGFLOAT_MAX) options:(NSStringDrawingUsesLineFragmentOrigin) context:nil].size;
    
    size.height = (12+15+8*2) + size.height;//MAX(17*2+40, 15*2 + size.height);
    
    return size.height;
}



@end
