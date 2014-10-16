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
    
//    NSMutableIndexSet *omittedSections = [NSMutableIndexSet indexSet];
//    NSLog(@"*attributesArya*");
    for (UICollectionViewLayoutAttributes *attributes in attributesArray)
    {
        //0 cell, 1 supplement, 2 decoration
//        NSLog(@"attributes.representedelementCatagory = %d [%d, %d]", attributes.representedElementCategory, attributes.indexPath.section, attributes.indexPath.row);

        if (attributes.representedElementCategory == UICollectionElementCategoryCell)
        {
//            [omittedSections addIndex:attributes.indexPath.section];
            attributes.zIndex = -1;
//            attributes.alpha = 0.1f;
        } else
        {
            attributes.zIndex = 1;
//            attributes.alpha = 0.1;
        }
    }
//    for (UICollectionViewLayoutAttributes *attributes in attributesArray) {
//        if ([attributes.representedElementKind isEqualToString:UICollectionElementKindSectionFooter]) {
//            [omittedSections removeIndex:attributes.indexPath.section];
//        }
//    }
//    [omittedSections enumerateIndexesUsingBlock:^(NSUInteger idx, BOOL *stop) {
//        NSIndexPath *indexPath = [NSIndexPath indexPathForItem:0 inSection:idx];
//        UICollectionViewLayoutAttributes *attributes = [self layoutAttributesForSupplementaryViewOfKind:UICollectionElementKindSectionFooter
//                                                                                            atIndexPath:indexPath];
//        [attributesArray addObject:attributes];
//    }];
//    for (UICollectionViewLayoutAttributes *attributes in attributesArray) {
//        if ([attributes.representedElementKind isEqualToString:UICollectionElementKindSectionFooter]) {
//            
//            // adjust any aspect of each header's attributes here, including frame or zIndex
//            attributes.zIndex = 100;
//            
//        }
//        
//    }
    
    return attributesArray;
}

//-(UICollectionViewLayoutAttributes*)layoutAttributesForDecorationViewOfKind:(NSString *)elementKind atIndexPath:(NSIndexPath *)indexPath
//{
//    UICollectionViewLayoutAttributes *attributes = [super layoutAttributesForDecorationViewOfKind:elementKind atIndexPath:indexPath];
//    attributes.zIndex = 100;
//    return attributes;
//}
//-(UICollectionViewLayoutAttributes*)layoutAttributesForSupplementaryViewOfKind:(NSString *)elementKind atIndexPath:(NSIndexPath *)indexPath
//{
//    UICollectionViewLayoutAttributes *attributes = [super layoutAttributesForSupplementaryViewOfKind:elementKind atIndexPath:indexPath];
//    attributes.zIndex = 100000;
//    return attributes;
//}
//-(UICollectionViewLayoutAttributes*)layoutAttributesForItemAtIndexPath:(NSIndexPath *)indexPath
//{
//    UICollectionViewLayoutAttributes *att = [super layoutAttributesForItemAtIndexPath:indexPath];
//    att.zIndex = 0;
//    return att;
//}

- (BOOL) shouldInvalidateLayoutForBoundsChange:(CGRect)newBound {
    
    return YES;
    
}







@end
