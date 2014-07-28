//
//  SWMessagesLayout.swift
//  Shortwave
//
//  Created by Ethan Sherr on 7/27/14.
//  Copyright (c) 2014 Ethan Sherr. All rights reserved.
//

import UIKit

class SWMessagesLayout: UICollectionViewFlowLayout {

    
    override func layoutAttributesForItemAtIndexPath(indexPath: NSIndexPath!) -> UICollectionViewLayoutAttributes!
    {
        let attributes = super.layoutAttributesForItemAtIndexPath(indexPath)

//        attributes.frame.origin.y = collectionView.contentSize.height - attributes.frame.origin.y
        
        return attributes
    }
    
    override func collectionViewContentSize() -> CGSize
    {
        var size = super.collectionViewContentSize()
//        if size.height < collectionView.frame.size.height
//        {
//            size.height = collectionView.frame.size.height
//        }
        return size
        
    }
    
    
    
    override func layoutAttributesForElementsInRect(rect: CGRect) -> [AnyObject]!
    {
        let attributes:[AnyObject] = super.layoutAttributesForElementsInRect(rect)
        
        let size = self.collectionViewContentSize()
//        println("size \(size)")
        for attribute in attributes as [UICollectionViewLayoutAttributes]
        {
//            println("b4 = \(attribute.frame)")
//            attribute.frame.origin.y = size.height - attribute.frame.origin.y - attribute.frame.size.height
//            println("aftr = \(attribute.frame)")
            
        }

        return attributes;
        
      
        
    }

}
