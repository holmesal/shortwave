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
        let attribute = super.layoutAttributesForItemAtIndexPath(indexPath)

//        let size = self.collectionViewContentSize()
//        attribute.frame.origin.y = size.height - attribute.frame.origin.y - attribute.frame.size.height
        
        return attribute
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
    
    
    
//    override func layoutAttributesForElementsInRect(rect: CGRect) -> [AnyObject]!
//    {
//        //shift the rectangle down!
//        let size = self.collectionViewContentSize()
//        
//        let rect = CGRectMake(rect.origin.x, size.height - rect.size.height, rect.size.width, rect.size.height);
//        
//        println("rect = \(rect)")
//        let attributes:[AnyObject] = super.layoutAttributesForElementsInRect(rect)
//        
//        
////        println("size \(size)")
//        for attribute in attributes as [UICollectionViewLayoutAttributes]
//        {
////            println("size = \(size)")
////            println("attribute.y = \(attribute.frame.origin.y)")
//            attribute.frame.origin.y = size.height - attribute.frame.origin.y //- attribute.frame.size.height
//            println("aftr.y = \(attribute.frame.origin.y)")
//            
//            
//        }
//
//        return attributes;
//        
//      
//        
//    }

}
