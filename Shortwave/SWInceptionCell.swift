//
//  SWInceptionCell.swift
//  Shortwave
//
//  Created by Ethan Sherr on 7/25/14.
//  Copyright (c) 2014 Ethan Sherr. All rights reserved.
//

import Foundation
import UIKit

class SWInceptionCell:UICollectionViewCell
{
    
    @IBOutlet weak var messagesCollectionView: UICollectionView!

    @IBOutlet weak var containerView: UIView!
    @IBOutlet weak var heightConstraint: NSLayoutConstraint!
    
    
    var requiredGestureRecognizersToFail:Bool = false
    
    func requireToFail(gestureRecognizers:Array<UIGestureRecognizer>)
    {
        println("gestureRecognizers = \(gestureRecognizers)")
        

    }
    
    override func awakeFromNib()
    {
        super.awakeFromNib()
        self.contentView.clipsToBounds = true
        heightConstraint.constant = 0
        
        messagesCollectionView.alwaysBounceVertical = true
        messagesCollectionView.contentInset = UIEdgeInsetsMake(0, 0, 48, 0)

        
    }
    

    @IBAction func testActino(sender: AnyObject)
    {
        
        println("hie")
        
    }
    
    
    
    func animateInceptionCell(expanded isExpanded:Bool)
    {
    
        
        UIView .animateWithDuration(0.3, delay: 0.0, options: UIViewAnimationOptions.CurveEaseInOut, animations:
        {
            self.heightConstraint.constant = isExpanded ? self.frame.size.height : 0
            self.containerView.layoutIfNeeded()
        }, completion: nil)
    }
    
    
}