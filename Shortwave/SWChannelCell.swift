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
    
    //CONSTRAINT
    @IBOutlet weak var topInsetConstraint: NSLayoutConstraint!
    
    @IBOutlet weak var titleLabel: UILabel!
    //CONSTRAINT
    @IBOutlet weak var titleLabelHeightConstraint: NSLayoutConstraint!
    
    @IBOutlet weak var descriptionLabel: UILabel!
    //CONSTRAINT
    @IBOutlet weak var descriptionLabelHeightConstraint: NSLayoutConstraint!
    
    //CONSTRAINT
    @IBOutlet weak var verticalSpaceBetweenTitleAndDescriptionConstraint: NSLayoutConstraint!
    
    @IBOutlet weak var indicatorView: UIView!
    
    
    var channelModel:SWChannelModel? = nil {
    didSet {
        //do UI update here

        titleLabel.text = (channelModel!.name!)
        setIsSynchronized(channelModel!.isSynchronized)
        
        if channelModel!.channelDescription
        {
            descriptionLabel.text = (channelModel!.channelDescription!)
//            descriptionLabel.backgroundColor = UIColor.purpleColor()
        } else
        {
            descriptionLabel.text = ""
        }
        let attributes = [NSFontAttributeName : descriptionLabel.font]
        
//        println("maxW says \(descriptionLabel.frame.size.width)")
        let constraintSize = CGSize(width: descriptionLabel.frame.size.width, height: 300)
        let string:NSString = descriptionLabel.text
//        (NSStringDrawingUsesLineFragmentOrigin|NSStringDrawingUsesFontLeading)
//        NSStringDrawingOptions.usesFontLeading


        let actualSize = descriptionLabel.sizeThatFits(CGSize(width: descriptionLabel.frame.size.width, height: 80) )
        
//        println("actualSize = \(actualSize)")
        
        descriptionLabelHeightConstraint.constant = actualSize.height
            
        
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
    
    //DOUBLE CHECK WHEN UI CHANGE
    class func cellHeightGivenChannel(channel:SWChannelModel) -> CGFloat
    {
        println("channel = \(channel.name!)")
        //2 * topInsetConstraint                          //height label and height and description label height
        
        let descriptionFont = UIFont(name: "Avenir-Light", size: 14)
        let descriptionMaxWidth = 222;
        let fakeDescriptionLabel = UILabel(frame: CGRect(x:0, y:0, width:descriptionMaxWidth, height:80) )
        fakeDescriptionLabel.font = descriptionFont
        fakeDescriptionLabel.numberOfLines = 0
        fakeDescriptionLabel.text = channel.channelDescription!
        let descriptionSize = fakeDescriptionLabel.sizeThatFits(fakeDescriptionLabel.frame.size)
        
        let titleFont = UIFont(name: "Avenir-Light", size: 16)
        let titleMaxWidth = 222;
        let fakeTitleLabel = UILabel(frame: CGRect(x: 0, y: 0, width: titleMaxWidth, height: 80))
        fakeTitleLabel.numberOfLines = 0
        fakeTitleLabel.font = titleFont
        fakeTitleLabel.text = channel.name!
        let titleSize = fakeTitleLabel.sizeThatFits(fakeTitleLabel.frame.size)
        
        
        let result = 2 * 21 +                  2 +               titleSize.height + descriptionSize.height;
        return result
    }
    
    override var highlighted:Bool {
        didSet
        {
            if highlighted
            {
                self.backgroundColor = UIColor(hexString: kNiceColors["green"])
            } else
            {
                self.backgroundColor = UIColor.clearColor()
            }
        }
    }
    
    
    
    
    
    
    
    
    
}