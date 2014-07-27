//
//  SWChannelsLayout.swift
//  Shortwave
//
//  Created by Ethan Sherr on 7/25/14.
//  Copyright (c) 2014 Ethan Sherr. All rights reserved.
//

import Foundation
import UIKit

class SWChannelsLayout: UICollectionViewFlowLayout
{
//    override func collectionViewContentSize() -> CGSize
//    {
//        let numberOfItems = self.collectionView.numberOfItemsInSection(0)
//        return CGSizeMake( 320, numberOfItems*20)
//    }
//    override func layoutAttributesForItemAtIndexPath(indexPath: NSIndexPath!) -> UICollectionViewLayoutAttributes!
//    {
//        let c = super.layoutAttributesForItemAtIndexPath(indexPath)
//        
//        c.frame.size.height = 1
//        c.alpha = 1.0
//        
//        return c
//    }
    
    override func initialLayoutAttributesForAppearingItemAtIndexPath(itemIndexPath: NSIndexPath!) -> UICollectionViewLayoutAttributes!
    {
        
        let c = super.initialLayoutAttributesForAppearingItemAtIndexPath(itemIndexPath)

        if (itemIndexPath.row != 0)
        {
            c.alpha = 1.0
            
        }
        
        return c
        
    }
    
    override func finalLayoutAttributesForDisappearingItemAtIndexPath(itemIndexPath: NSIndexPath!) -> UICollectionViewLayoutAttributes!
    {
        let c = super.finalLayoutAttributesForDisappearingItemAtIndexPath(itemIndexPath)
        
        if (itemIndexPath.row != 0)
        {
            c.alpha = 1.0
//            let t1 = CGAffineTransformMakeScale(1, 0.001)
//            let t2 = CGAffineTransformMakeTranslation(0, -c.frame.size.height/2)
//            c.transform = CGAffineTransformConcat(t1, t2)
        }
        return c
    }

//    override func layoutAttributesForElementsInRect(rect: CGRect) -> [AnyObject]!
//    {
////        var attributes = [UICollectionViewLayoutAttributes]()
////        let firstIndex = floor(CGRectGetMinY(rect) / 52)
////        let lastIndex = ceil(CGRectGetMaxY(rect) / 52)
////        
////        for var index = firstIndex; index <= lastIndex; index++
////        {
////            NSIndexPath(
////        }
//    }
    
}
