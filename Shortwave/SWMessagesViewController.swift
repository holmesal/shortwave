//
//  SWMessagesViewController.swift
//  Shortwave
//
//  Created by Ethan Sherr on 7/30/14.
//  Copyright (c) 2014 Ethan Sherr. All rights reserved.
//

import Foundation
import UIKit

class SWMessagesViewController : UIViewController, PHFComposeBarViewDelegate, UIScrollViewDelegate, ChannelCellActionDelegate
{
    var channelModel:SWChannelModel!{
        didSet
        {
            channelModel.scrollViewDelegate = self
    }
    }
    
//    var longPressGesture:UILongPressGestureRecognizer!
    var temporaryEnlargedView:UIView?

    @IBOutlet weak var composeBarView: PHFComposeBarView!
    @IBOutlet weak var collectionView: UICollectionView!

    @IBOutlet weak var composeBarBottomConstraint: NSLayoutConstraint!
    override func viewDidLoad()
    {
        composeBarView.textView.font = UIFont(name: "Avenir-Medium", size: 14)
        composeBarView.textView.textColor = UIColor.blackColor()
        composeBarView.textView.tintColor = UIColor(hexString: kNiceColors["green"])
        composeBarView.button.tintColor = UIColor(hexString: kNiceColors["green"])
        
//        var rightButtonView = UIButton(frame: CGRectMake(0, 0, 50, 40))
//        rightButtonView.setImage(UIImage(named:"share"), forState: .Normal)
//        rightButtonView.addTarget(self, action: "shareChannelAction:", forControlEvents: UIControlEvents.TouchUpInside)
//        rightButtonView.contentEdgeInsets = UIEdgeInsets(top: 0, left: 30, bottom: 0, right: 0)
        var rightButton = UIBarButtonItem(title: "Invite", style: UIBarButtonItemStyle.Plain, target: self, action: "shareChannelAction:")
        self.navigationItem.rightBarButtonItem = rightButton
            
//        longPressGesture = UILongPressGestureRecognizer(target: self, action: "didLongPress:")
//        longPressGesture.cancelsTouchesInView = false
//        longPressGesture.minimumPressDuration = 0.075
//        self.view.addGestureRecognizer(longPressGesture)
        
        self.navigationItem.title = "#\(channelModel.name!)"

        
        
        setupComposeBarView()
        MessageCell.registerCollectionViewCellsForCollectionView(collectionView)//register relevant nib cells with this collectionview!
        
        channelModel.messageCollectionView = collectionView //dataSource and delegate linking has occured now!
        collectionView.transform = CGAffineTransformMakeRotation(CGFloat(M_PI))
        collectionView.showsVerticalScrollIndicator = false
        
        let notifCenter = NSNotificationCenter.defaultCenter()
        notifCenter.addObserver(self, selector: "keyboardWillToggle:", name: UIKeyboardWillShowNotification, object: nil)
        notifCenter.addObserver(self, selector: "keyboardWillToggle:", name: UIKeyboardWillHideNotification, object: nil)
        
//        notifCenter.addObserver(sel, selector: "helixFossil", name: "helixFossil", object: nil)
        
        collectionView.alwaysBounceVertical = true
        
        channelModel.cellActionDelegate = self
        
    }
    
    func shareChannelAction(sender:AnyObject?)
    {
        
        let UID = NSUserDefaults.standardUserDefaults().objectForKey(kNSUSERDEFAULTS_KEY_userId) as NSString
        
        let skimmedId = UID.stringByReplacingOccurrencesOfString("facebook:", withString: "")
            
        println("uid = \(UID)")
        
        let shareUrl = "http://getshortwave.com/" + self.channelModel.name! + "?ref=" + skimmedId
        println("shareUrl = \(shareUrl)")
        var activityView = UIActivityViewController(activityItems: [shareUrl], applicationActivities: nil)
        

        activityView.completionHandler = {(activityType:String!, done:Bool!) in
            
            println("activityType \(activityType)")
            println("done \(done)")
            
            var mixpanelProperties:[NSObject: AnyObject] = ["channel":self.channelModel!.name!, "done":done]

            
            if let type = activityType
            {
                mixpanelProperties["activityType"] = type
            }
            
            Mixpanel.sharedInstance().track("Invite", properties: mixpanelProperties)
        
        }
        
        self.presentViewController(activityView, animated: true, completion: nil)
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
        let heightChange = (frameEnd.origin.y - frameBegin.origin.y) * CGFloat(signCorrection);
        let newContentOffset = CGPointMake(0, collectionView.contentOffset.y - heightChange)
        
        
        UIView.animateWithDuration(0.3, delay: 0.0, options: UIViewAnimationOptions.BeginFromCurrentState | UIViewAnimationOptions.fromRaw(7 << 16)!, animations:
            {
                self.collectionView.contentInset = contentInset
                self.composeBarBottomConstraint.constant = constraintHeight
                self.composeBarView.layoutIfNeeded()
                self.collectionView.contentOffset = newContentOffset
                
            }, completion: nil)
    }
    
    
    func setupComposeBarView()
    {
//        composeBarView.maxCharCount = 160
        composeBarView.maxLinesCount = 5
        composeBarView.button.titleLabel.textColor = UIColor(hexString: "7E7E7E")
        composeBarView.delegate = self
    }
    
    func composeBarViewDidPressButton(composeBarView: PHFComposeBarView!)
    {
        //send the message
        let text = self.composeBarView.text
        
        //does text contain helix or fossil?
//        var textNSString = text as NSString
        let lowercase = text.lowercaseString
        if lowercase.rangeOfString("helix") != nil || lowercase.rangeOfString("fossil") != nil
        {
            helixFossil()
            composeBarView.resignFirstResponder()
            Mixpanel.sharedInstance().track("Helix Fossil", properties:["message":text])
            return
        }
        
        //does text contain a url?
        let ownerId = NSUserDefaults.standardUserDefaults().objectForKey(kNSUSERDEFAULTS_KEY_userId) as String
        MessageModel(ownerID: ownerId, andText: text).sendMessageToChannel(channelModel.name!)
        
        self.channelModel.setPriorityToNow()
        
        composeBarView.setText("", animated: true)
        composeBarView.resignFirstResponder()
    }
    
    deinit
    {
        NSNotificationCenter.defaultCenter().removeObserver(self)
    }
    
    override func viewDidDisappear(animated: Bool)
    {
        super.viewDidDisappear(animated)
        

        
        if channelModel.messageCollectionView == self.collectionView
        {
            channelModel.scrollViewDelegate = nil
            channelModel.cellActionDelegate = nil
            channelModel.messageCollectionView = nil; //no more collectinoView associated with channelModel dataSource, delegate
        }

    }
    
    func didLongPress(theLongPress:UILongPressGestureRecognizer)
    {
        let location:CGPoint = theLongPress.locationInView(collectionView)
        
        if let indexPath = collectionView.indexPathForItemAtPoint(location)
        {
            let messageModel = channelModel.wallSource.wallObjectAtIndex(indexPath.item)
            
            if let cell = collectionView.cellForItemAtIndexPath(indexPath)
            {
                let selectedCell = cell as UICollectionViewCell
            
                handleLongPress(theLongPress, withMessageModel:messageModel, andCollectionViewCell:selectedCell)
                return
            }
        }
        
        handleLongPress(theLongPress, withMessageModel:nil, andCollectionViewCell:nil)
        

    }
    
    func handleLongPress(longPressGesture:UILongPressGestureRecognizer, withMessageModel messageModel:MessageModel?, andCollectionViewCell cell:UICollectionViewCell?)
    {
        

        
        switch longPressGesture.state
        {
        case .Began:
            if temporaryEnlargedView == nil
            {
                
                let createTemporaryEnlargedView:()->() = {
                    self.temporaryEnlargedView = UIView(frame: self.view.bounds)
                    self.temporaryEnlargedView!.backgroundColor = UIColor(white: 0, alpha: 0.8)
                    self.temporaryEnlargedView!.alpha = 0
                    self.view.addSubview(self.temporaryEnlargedView!)

                    UIView.animateWithDuration(0.3, delay: 0.0, usingSpringWithDamping: 1.0, initialSpringVelocity: 0.0, options: .CurveEaseInOut, animations:
                        {
                            if let tempEnlargedView = self.temporaryEnlargedView
                            {
                                tempEnlargedView.alpha = 1.0
                            }
                        }, completion: {(b:Bool) in })
                }
                

                
                if let imageMessage = messageModel as? MessageImage
                {
                    createTemporaryEnlargedView()
                    println("long press began on IMAGE")
                    let imageCell = (cell as SWImageCell)
                    let imageView = UIImageView(frame: self.view.bounds)
                    imageView.contentMode = UIViewContentMode.ScaleAspectFit
                    imageView.image = imageCell.getImage()
                    
                    temporaryEnlargedView!.addSubview(imageView)
                    
                } else
                if let gifMessage = messageModel as? MessageGif
                {
                    createTemporaryEnlargedView()
                    
                    let player = gifMessage.player
                    var playerLayer = AVPlayerLayer(player: player)
                    playerLayer.bounds = self.view.bounds
                    playerLayer.position = CGPoint(x: playerLayer.bounds.size.width*0.5, y: playerLayer.bounds.size.height*0.5)
                    playerLayer.backgroundColor = UIColor(red: 1, green: 0, blue: 1, alpha: 0.2).CGColor
                    
                    
                    temporaryEnlargedView!.layer.addSublayer(playerLayer)
                    
                    
                }
                
                
            }
            
        case .Ended, .Cancelled:

            if let tempEnlargedView = temporaryEnlargedView
            {
                UIView.animateWithDuration(0.3, delay: 0.0, usingSpringWithDamping: 1.0, initialSpringVelocity: 0.0, options: .CurveEaseInOut, animations:
                    {
                        tempEnlargedView.alpha = 0.0
                    }, completion: {(b:Bool) in
                        tempEnlargedView.removeFromSuperview()
                        self.temporaryEnlargedView = nil
                    })
            }
            
            
        default:
            break
        }
    }
    
    
    func scrollViewWillBeginDragging(scrollView: UIScrollView!)
    {
        composeBarView.textView.resignFirstResponder()
    }
    
    var animator:UIDynamicAnimator!
    var gravity:UIGravityBehavior!
    var collision:UICollisionBehavior!
//    var collision:UICollisionBehavior!
    
    func createAnimatorStuffIfNotAlready()
    {
        if animator == nil
        {
            animator = UIDynamicAnimator(referenceView: self.view)
            gravity = UIGravityBehavior()
            collision = UICollisionBehavior()
            collision!.translatesReferenceBoundsIntoBoundary = true
            animator!.addBehavior(gravity)
            animator!.addBehavior(collision)
        }
    }
    
    func fossilTap(helixButton:UIButton)
    {
        helixButton.removeFromSuperview()
        gravity.removeItem(helixButton)
        collision.removeItem(helixButton)
        
        
        let alert = UIAlertView(title: nil, message: "Now is not the time to consult the helix fossil.", delegate: nil, cancelButtonTitle: nil)
        alert.show()
        
        let dealyInSeconds:UInt64 = 2
        let popTime:dispatch_time_t = dispatch_time(DISPATCH_TIME_NOW, Int64(dealyInSeconds * NSEC_PER_SEC))
        dispatch_after(popTime, dispatch_get_main_queue(),
        {
            alert.dismissWithClickedButtonIndex(0, animated: true)
        })
    }
    
    func helixFossil()
    {
        var square = UIButton(frame: CGRectMake((320-56)*0.5, 100, 56, 60))
        square.setBackgroundImage(UIImage(named: "fossil"), forState: .Normal)
        square.contentMode = UIViewContentMode.ScaleToFill
        self.view.addSubview(square)
        
        square.alpha = 0.2
        square.transform = CGAffineTransformMakeScale(1.6, 1.6)
        
        UIView.animateWithDuration(0.7, delay: 0.0, usingSpringWithDamping: 1, initialSpringVelocity: 1, options: .CurveLinear, animations:
            {
                square.transform = CGAffineTransformIdentity
                square.alpha = 1.0
            }, completion: {(b:Bool) in })
        
        square.addTarget(self, action: "fossilTap:", forControlEvents: UIControlEvents.TouchDown)

        createAnimatorStuffIfNotAlready()
        
        gravity.addItem(square)
        collision.addItem(square)
        
        //push behavior
        var pushBehavior = UIPushBehavior(items: [square], mode: UIPushBehaviorMode.Instantaneous)
        pushBehavior.magnitude = 1
        let double:Double = Double(Int(rand())%2)
        pushBehavior.angle = CGFloat(  double * M_PI)
        animator.addBehavior(pushBehavior)
        
        animator.addBehavior(collision)
    }
    override func viewDidAppear(animated: Bool) {
        super.viewDidAppear(animated)
        
    }
    
}