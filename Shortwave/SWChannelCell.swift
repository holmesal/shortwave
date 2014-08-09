//
//  SWChannelCell.swift
//  Shortwave
//
//  Created by Ethan Sherr on 7/25/14.
//  Copyright (c) 2014 Ethan Sherr. All rights reserved.
//

import Foundation
import UIKit
import CoreGraphics

class SWChannelCell: UICollectionViewCell, UIGestureRecognizerDelegate
{
    
    @IBOutlet weak var containerView: UIView!
    
    @IBOutlet weak var titleLabel: UILabel!
    @IBOutlet weak var descriptionLabel: UILabel!
    
    @IBOutlet weak var indicatorView: UIView!
    
    
    var channelModel:SWChannelModel? = nil {
    didSet {
        //do UI update here

        titleLabel.text = "#\(channelModel!.name!)"
        setIsSynchronized(channelModel!.isSynchronized)
        
    }
    }
    
    
    init(coder aDecoder: NSCoder!)
    {
        
        super.init(coder: aDecoder)
        
        
    }
    
    var animator:UIDynamicAnimator!
    var pushBehavior:UIPushBehavior!
    
    override func awakeFromNib()
    {
        
       
        
//        NSRunLoop.mainRunLoop().addTimer(NSTimer(timeInterval: 4, target: self, selector: "push", userInfo: nil, repeats: true), forMode: NSDefaultRunLoopMode)

        
    }
    
    var distance:CGFloat = 5;
    
    func push()
    {
        
        UIView.animateWithDuration(0.1, delay: 0.0, options: .CurveEaseIn, animations:
            {
                self.indicatorView.alpha = 1.0
                self.indicatorView.transform = CGAffineTransformMakeTranslation(0, self.distance)
            }, completion:
            {(b:Bool) in
                UIView.animateWithDuration(0.4, delay: 0.0, usingSpringWithDamping: 0.1, initialSpringVelocity: 2, options: .CurveLinear, animations:
                    {
                        self.indicatorView.transform = CGAffineTransformMakeTranslation(0, 0)
                    }, completion: {(b:Bool) in })
            })
        
    }
    
    func setIsSynchronized(synchronized:Bool)
    {
        if synchronized
        {
            indicatorView.alpha = 0.0
        } else
        {
            indicatorView.alpha = 1.0
        }
    }
    
    
    
    
    
    
    
    
}