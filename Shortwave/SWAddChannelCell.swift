//
//  SWAddChannelCell.swift
//  Shortwave
//
//  Created by Ethan Sherr on 7/27/14.
//  Copyright (c) 2014 Ethan Sherr. All rights reserved.
//

import UIKit

class SWAddChannelCell: UICollectionViewCell
{
    
    var label:UILabel?;
    
    
    required init(coder aDecoder: NSCoder!)
    {
        super.init(coder: aDecoder)
    
        label = self.getALabel("+ Channel")
        addSubview(label!)
    }
    
    func getALabel(text:String) -> UILabel
    {
        let aLabel = UILabel(frame: CGRectMake(0, 0, 320, 50))
        
        aLabel.textColor = UIColor.whiteColor()
        aLabel.textAlignment = .Center
        aLabel.text = text
        
        return aLabel
    }
    
    //animates this message down
    func curlDownAMessage(message:String, animated:Bool)
    {
        if !animated
        {
            label!.text = message
        } else
        {
            
            let newLabel = self.getALabel(message)
            newLabel.transform = self.transformForLabelWhichIsLeaving(false)
            newLabel.alpha = 0.0
            addSubview(newLabel)
            
            var tempLabel:UILabel?;
            
            UIView.animateWithDuration(0.2, delay: 0.0, usingSpringWithDamping: 0.1, initialSpringVelocity: 0, options: .CurveLinear, animations:
                {
                    
                    self.label!.alpha = 0.0
                    self.label!.transform = self.transformForLabelWhichIsLeaving( true)
                    newLabel.alpha = 1.0
                    newLabel.transform = CGAffineTransformIdentity
                    tempLabel = self.label
                    self.label = newLabel
                    
                }, completion: {(finished:Bool) in
                    tempLabel!.removeFromSuperview()
                })
        }
    }
    
    func transformForLabelWhichIsLeaving(isLeaving:Bool) -> CGAffineTransform
    {
        let h = self.frame.size.height
        
        let translation = CGAffineTransformMakeTranslation(0, (isLeaving ? 1 : -1 )*h*0.5)
        let scale = CGAffineTransformMakeScale(0.8, 0.8)
        
        return CGAffineTransformConcat(translation, scale)
    }
    
}
