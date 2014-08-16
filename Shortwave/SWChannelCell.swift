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

class SWChannelCell: UICollectionViewCell, UIGestureRecognizerDelegate, ChannelMutedResponderDelegate
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
    
    @IBOutlet weak var muteButton: UIButton!
    
    @IBOutlet weak var muteButtonImageSelected: UIImageView!
    @IBOutlet weak var muteButtonImageUnselected: UIImageView!
    
    @IBOutlet weak var sideView: UIView!
    
    
    @IBOutlet weak var leaveButton: UIButton!
//    @IBOutlet weak var confirmDeleteButton: UIButton!
    var confirmDeleteView: UIView!
//    @IBOutlet weak var confirmDeleteLeadingSpaceToContainer: NSLayoutConstraint!
    //CONSTRAINT
    @IBOutlet weak var verticalSpaceBetweenTitleAndDescriptionConstraint: NSLayoutConstraint!
    
    @IBOutlet weak var indicatorView: UIView!
    
    
    var channelModel:SWChannelModel? = nil {
    willSet {
        if let currentChannelModel = channelModel
        {
            //wouldn't want to respond to another channel's muted event, properly unset!
            channelModel!.mutedDelegate = nil
        }
    }
    
    
    didSet {
        //do UI update here

        titleLabel.text = (channelModel!.name!)
        setIsSynchronized(channelModel!.isSynchronized)
        
//        confirmDeleteLeadingSpaceToContainer.constant = 320
//        confirmDeleteView.alpha = 0.5
        
        if channelModel!.channelDescription
        {
            descriptionLabel.text = (channelModel!.channelDescription!)
        } else
        {
            descriptionLabel.text = ""
        }
        let attributes = [NSFontAttributeName : descriptionLabel.font]
        
        let constraintSize = CGSize(width: descriptionLabel.frame.size.width, height: 300)
        let string:NSString = descriptionLabel.text


        let actualSize = descriptionLabel.sizeThatFits(CGSize(width: descriptionLabel.frame.size.width, height: 80) )
        
        channelModel!.mutedDelegate = self
        updateMutedState(channelModel!.muted)
        
        descriptionLabelHeightConstraint.constant = actualSize.height
        
        
        confirmDeleteView.transform = CGAffineTransformMakeTranslation(0, 0)
        let yForConfirmDelete = self.frame.size.height - 40
        var frame = confirmDeleteView.frame
        frame.origin.y = yForConfirmDelete
        confirmDeleteView.frame = frame
        confirmDeleteView.transform = CGAffineTransformMakeTranslation(320, 0)
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

        confirmDeleteView = UIView(frame: CGRect(x:0, y:0, width:320, height:40))
        
        confirmDeleteView.backgroundColor = UIColor(hexString: kNiceColors["pinkRed"])
        self.addSubview(confirmDeleteView)
        
        var deleteButton = UIButton(frame: confirmDeleteView.bounds)
        deleteButton.setTitle("Leave Channel", forState: .Normal)
        deleteButton.setTitleColor(UIColor.whiteColor(), forState: .Normal)
        confirmDeleteView .addSubview(deleteButton)
        deleteButton.titleLabel.font = UIFont(name: "Avenir-Black", size: 17)
        deleteButton.addTarget(self, action: "confirmDeleteAction:", forControlEvents: UIControlEvents.TouchUpInside)
        
        
    }
    @IBAction func muteAction(sender: AnyObject)
    {
     
        channelModel!.muted = !channelModel!.muted
        channelModel!.setMutedToFirebase()
        
    }
    
    func channel(channel: SWChannelModel, isMuted: Bool)
    {
        updateMutedState(isMuted)
    }
    
    func updateMutedState(isMuted:Bool)
    {
        muteButtonImageSelected.alpha = isMuted ? 1.0 : 0.0
        muteButtonImageUnselected.alpha = !isMuted ? 1.0 : 0.0
    }
    
    
    
    var distance:CGFloat = 5;
    
    func push()
    {
        
        UIView.animateWithDuration(0.1, delay: 0.0, options: .CurveEaseIn, animations:
            {
                self.sideView.alpha = 1.0
//                self.indicatorView.alpha = 1.0
                self.sideView.transform = CGAffineTransformMakeTranslation(-self.distance, 0)
//                self.indicatorView.transform = CGAffineTransformMakeTranslation(0, self.distance)
            }, completion:
            {(b:Bool) in
                UIView.animateWithDuration(0.4, delay: 0.0, usingSpringWithDamping: 0.1, initialSpringVelocity: 2, options: .CurveLinear, animations:
                    {
                        self.sideView.transform = CGAffineTransformMakeTranslation(0, 0)
                    }, completion: {(b:Bool) in })
            })
        
    }
    
    func setIsSynchronized(synchronized:Bool)
    {
        if synchronized
        {
            self.sideView.alpha = 0.0
        } else
        {
            self.sideView.alpha = 1.0
        }
    }
    
    @IBAction func confirmDeleteAction(sender: AnyObject)
    {
        let userID = NSUserDefaults.standardUserDefaults().objectForKey(kNSUSERDEFAULTS_KEY_userId) as String
        let userChannelFB = Firebase(url: kROOT_FIREBASE + "users/" + userID + "/channels/" + self.channelModel!.name!)
        userChannelFB.setValue(nil)
        
        let userInChannelMemberFB = Firebase(url: kROOT_FIREBASE + "channels/" + self.channelModel!.name! + "/members/" + userID)
        userInChannelMemberFB.setValue(nil)
    }
    @IBAction func leaveAction(sender: AnyObject)
    {
        println("leaveAction:")
        UIView.animateWithDuration(0.4, delay: 0.0, usingSpringWithDamping: 2.0, initialSpringVelocity: 2.0, options: UIViewAnimationOptions.CurveLinear, animations: {
//            self.confirmDeleteLeadingSpaceToContainer.constant = 0
//            self.confirmDeleteView.superview.layoutIfNeeded()
            self.confirmDeleteView.transform = CGAffineTransformMakeTranslation(0, 0)
            
            }, completion: {(b:Bool) in })
    }
    
    //DOUBLE CHECK WHEN UI CHANGE
    class func cellHeightGivenChannel(channel:SWChannelModel) -> CGFloat
    {
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
        
        
        let result = 1 * 21 +                  2 +               titleSize.height + descriptionSize.height + 57;
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
    
    func hideLeaveChannelConfirmUI()
    {
//        if self.confirmDeleteLeadingSpaceToContainer.constant != 320
//        {
            UIView.animateWithDuration(0.2, delay: 0.0, usingSpringWithDamping: 2.0, initialSpringVelocity: 2.0, options: UIViewAnimationOptions.CurveLinear, animations: {
                
                self.confirmDeleteView.transform = CGAffineTransformMakeTranslation(320, 0)
//                self.confirmDeleteLeadingSpaceToContainer.constant = 320
//                self.confirmDeleteView.superview.layoutIfNeeded()
                
                }, completion: {(b:Bool) in })
//        }
    }
    
    
    
    
    
    
    
    
    
}