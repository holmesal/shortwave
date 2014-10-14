//
//  SWMessagesLayout.m
//  hashtag
//
//  Created by Ethan Sherr on 10/10/14.
//  Copyright (c) 2014 Ethan Sherr. All rights reserved.
//

#import "SWMessagesLayout.h"

@implementation SWMessagesLayout

-(NSArray*)layoutAttributesForElementsInRect:(CGRect)rect
{
    NSMutableArray *attributesArray = [[super layoutAttributesForElementsInRect:rect] mutableCopy];
    
    NSMutableIndexSet *omittedSections = [NSMutableIndexSet indexSet];
    for (UICollectionViewLayoutAttributes *attributes in attributesArray) {
        if (attributes.representedElementCategory == UICollectionElementCategoryCell) {
            [omittedSections addIndex:attributes.indexPath.section];
            attributes.zIndex = 0;
        }
    }
    for (UICollectionViewLayoutAttributes *attributes in attributesArray) {
        if ([attributes.representedElementKind isEqualToString:UICollectionElementKindSectionFooter]) {
            [omittedSections removeIndex:attributes.indexPath.section];
        }
    }
    [omittedSections enumerateIndexesUsingBlock:^(NSUInteger idx, BOOL *stop) {
        NSIndexPath *indexPath = [NSIndexPath indexPathForItem:0 inSection:idx];
        UICollectionViewLayoutAttributes *attributes = [self layoutAttributesForSupplementaryViewOfKind:UICollectionElementKindSectionFooter
                                                                                            atIndexPath:indexPath];
        [attributesArray addObject:attributes];
    }];
    for (UICollectionViewLayoutAttributes *attributes in attributesArray) {
        if ([attributes.representedElementKind isEqualToString:UICollectionElementKindSectionFooter]) {
            
            // adjust any aspect of each header's attributes here, including frame or zIndex
            attributes.zIndex = 100;
            
        }
        else
        if (attributes.representedElementCategory == UICollectionElementCategoryCell)
        {
            attributes.zIndex = 0;
        }
    }
    
    return attributesArray;
}
- (BOOL) shouldInvalidateLayoutForBoundsChange:(CGRect)newBound {
    
    return YES;
    
}

//- (NSArray *)layoutAttributesForElementsInRect:(CGRect)rect
//{
//    NSMutableArray* attributesArray = [[super layoutAttributesForElementsInRect:rect] mutableCopy];
//    
//    BOOL headerVisible = NO;
//    
//    for (UICollectionViewLayoutAttributes *attributes in attributesArray) {
//        if ([attributes.representedElementKind isEqualToString:UICollectionElementKindSectionFooter]) {
//            headerVisible = YES;
////            attributes.frame = CGRectMake(self.collectionView.contentOffset.x, 0, self.headerReferenceSize.width, self.headerReferenceSize.height);
////            attributes.alpha = HEADER_ALPHA;
//            attributes.zIndex = 2;
////            NSLog(@"invalidateLayout caled!");
////            [self invalidateLayout];
//        }
//    }
//    
//    if (!headerVisible) {
//        UICollectionViewLayoutAttributes *attributes = [self layoutAttributesForSupplementaryViewOfKind:UICollectionElementKindSectionHeader
//                                                                                            atIndexPath:[NSIndexPath
//                                                                                                         indexPathForItem:0
//                                                                                                         inSection:0]];
//        [attributesArray addObject:attributes];
//    }
//    
//    return attributesArray;
//}



@end
