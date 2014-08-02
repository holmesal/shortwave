//
//  SWMessagesViewController.swift
//  Shortwave
//
//  Created by Ethan Sherr on 7/30/14.
//  Copyright (c) 2014 Ethan Sherr. All rights reserved.
//

import Foundation
import UIKit

class SWMessagesViewController : UIViewController, PHFComposeBarViewDelegate
{

    var channelModel:SWChannelModel!
    

    @IBOutlet weak var composeBarView: PHFComposeBarView!
    @IBOutlet weak var collectionView: UICollectionView!

    @IBOutlet weak var composeBarBottomConstraint: NSLayoutConstraint!
    override func viewDidLoad()
    {
        self.navigationItem.title = "#\(channelModel.name!)"
        
        
        setupComposeBarView()
        MessageCell.registerCollectionViewCellsForCollectionView(collectionView)//register relevant nib cells with this collectionview!
        
        channelModel.messageCollectionView = collectionView //dataSource and delegate linking has occured now!
        collectionView.transform = CGAffineTransformMakeRotation(CGFloat(M_PI))
        collectionView.showsVerticalScrollIndicator = false
        
        NSNotificationCenter.defaultCenter().addObserver(self, selector: "keyboardWillToggle:", name: UIKeyboardWillShowNotification, object: nil)
        NSNotificationCenter.defaultCenter().addObserver(self, selector: "keyboardWillToggle:", name: UIKeyboardWillHideNotification, object: nil)
        
        collectionView.alwaysBounceVertical = true
    }
    
    
    /// MARK: keyboardWillToggle for willShow and willHide
    func keyboardWillToggle(notification:NSNotification)
    {
//        if !composeBarView.textField.isFirstResponder()
//        {
//            return
//        }
        let userInfo = notification.userInfo
        
        let durationV = userInfo[UIKeyboardAnimationDurationUserInfoKey]
        let curveV = userInfo[UIKeyboardAnimationCurveUserInfoKey]
        let frameBeginV = userInfo[UIKeyboardFrameBeginUserInfoKey] as? NSValue
        let frameEndV = userInfo[UIKeyboardFrameEndUserInfoKey] as? NSValue
        
        let duration = durationV!.doubleValue as NSTimeInterval
        let frameBegin = frameBeginV!.CGRectValue()
        let frameEnd = frameEndV!.CGRectValue()
        
        let curve:UInt = 7//curveV!.unsignedIntegerValue
        let animationCurve = UIViewAnimationOptions.fromRaw(curve)
        
//        println("durationV = \(durationV) and curveV = \(curveV)")
        
        let dy = frameBegin.origin.y - frameEnd.origin.y
        let constraintHeight = (dy < 0 ? 0 : dy )
        
        //if constraintHeight = 0, then edgeInsetBottom = 0, else
        
        var contentInset = self.collectionView.contentInset
        contentInset.top = constraintHeight
        
        //what is the index of the very last cell?
        let lastIndex = channelModel.messages.count-1
        

        var signCorrection = -1
        if (frameBegin.origin.y < 0 || frameBegin.origin.x < 0 || frameEnd.origin.y < 0 || frameEnd.origin.x < 0)
        {
            signCorrection = 1;
        }
//            CGFloat widthChange  = (endFrame.origin.x - startFrame.origin.x) * signCorrection;
        let heightChange = (frameEnd.origin.y - frameBegin.origin.y) * signCorrection;
        
        let newContentOffset = CGPointMake(0, collectionView.contentOffset.y + heightChange)
        
        
        
        UIView.animateWithDuration(0.3, delay: 0.0, options: UIViewAnimationOptions.BeginFromCurrentState | UIViewAnimationOptions.fromRaw(7 << 16)!, animations:
            {
                self.collectionView.contentInset = contentInset
                self.composeBarBottomConstraint.constant = constraintHeight
                self.composeBarView.layoutIfNeeded()
                
                
//                self.collectionView.contentOffset = newContentOffset
                
                
                
            }, completion: nil)
    }
    
    
    func setupComposeBarView()
    {
        /*
        [self.composeBarView setMaxCharCount:160];
        [self.composeBarView setMaxLinesCount:5];
        
        [self.composeBarView.button.titleLabel setTextColor:[UIColor colorWithHexString:@"7E7E7E"]];
        
        [self.composeBarView setUtilityButtonImage:[UIImage imageNamed:@"paperclip"]];
        [self.composeBarView setDelegate:self];
        */
        composeBarView.maxCharCount = 160
        composeBarView.maxLinesCount = 5
        composeBarView.button.titleLabel.textColor = UIColor(hexString: "7E7E7E")
        composeBarView.delegate = self
    }
    
    func composeBarViewDidPressButton(composeBarView: PHFComposeBarView!)
    {
        //send the message
        let text = self.composeBarView.text
        
        let ownerId = NSUserDefaults.standardUserDefaults().objectForKey(kNSUSERDEFAULTS_KEY_userId) as String
        MessageModel(ownerID: ownerId, andText: text).sendMessageToChannel(channelModel.name!)
        
        composeBarView.setText("", animated: true)
        composeBarView.resignFirstResponder()
    }
    
    deinit
    {
        NSNotificationCenter.defaultCenter().removeObserver(self)
    }
}