//
//  SWNewChannel.swift
//  Shortwave
//
//  Created by Ethan Sherr on 7/30/14.
//  Copyright (c) 2014 Ethan Sherr. All rights reserved.
//

import Foundation
import UIKit
import QuartzCore

class SWNewChannel: UIViewController, UITextFieldDelegate, UITextViewDelegate
{
    

    @IBOutlet weak var createButtonBottomConstraint: NSLayoutConstraint!
    @IBOutlet weak var navBarLabel: UILabel!
    @IBOutlet weak var fakeNavBar: UIView!
    
    weak var channelViewController: SWChannelsViewController!
    
    @IBOutlet weak var goButton: UIButton!
    
    @IBOutlet weak var channelNameCharacterCountLabel: UILabel!
    @IBOutlet weak var hashTagLabel: UILabel!
    @IBOutlet weak var channelNameTextField: UITextField!
//    @IBOutlet weak var channelSearchResult: UILabel!
    
    @IBOutlet weak var scrollView: UIScrollView!
    
    var channelName = ""
    var channelNameExists:Bool?
    var isJoining:Bool = false
    
    var timer:NSTimer?
    
    //outlets for joining
    @IBOutlet strong var descriptionViewContainer: UIView!
    @IBOutlet weak var descriptionLabel: UILabel!
    @IBOutlet weak var descriptionLabelHeightConstraint: NSLayoutConstraint!
    
    @IBOutlet weak var createDescriptionContainer: UIView!
    @IBOutlet weak var createDescriptionTextView: UITextView!
    
    override func viewDidLoad()
    {
        
        channelNameTextField.becomeFirstResponder()
        
        NSNotificationCenter.defaultCenter().addObserver(self, selector: "keyboardWillToggle:", name: UIKeyboardWillShowNotification, object: nil)
        NSNotificationCenter.defaultCenter().addObserver(self, selector: "keyboardWillToggle:", name: UIKeyboardWillHideNotification, object: nil)
        
        let hexString = kNiceColors["bar"]
        fakeNavBar.backgroundColor = UIColor(hexString: hexString)
        
        descriptionViewContainer.alpha = 0.0
        

        navBarLabel.font = UIFont(name: "Avenir-Book", size: 15)
        navBarLabel.textColor = UIColor.whiteColor()
        
        scrollView.alwaysBounceVertical = true
        
        channelNameTextField.delegate = self
        
        
        createDescriptionTextView.delegate = self
        createDescriptionTextView.backgroundColor = UIColor.clearColor()
        
        //CALayer behind textView
        createInputLayer()
        
        updateUITimer() //hides the create button for "" result, and sets prompt
        
        

        
    }
    
    func createInputLayer()
    {
        let insetVertical:CGFloat = 5.0
        let insetHorizontal:CGFloat = 5.0
    
        let textViewSize = createDescriptionTextView.frame.size
        
        var layer = CALayer()
        
//        let frame = CGRect(x: -insertHorizontal, y: -insetVertical,
//            width: textViewSize.width + 2*insertHorizontal,
//            height: textViewSize.height + 2*insetVertical)
        //CGRect(x: -insetHorizontal, y: -insetVertical, width:(textViewSize.width + 2 * insetHorizontal), height:(textViewSize.height + 2 * insetVertical))
        var frame = createDescriptionTextView.frame
        
        frame.origin.y = -(insetVertical)
        frame.origin.x = -(insetHorizontal)
        frame.size.width = 2*insetHorizontal + frame.size.width
        frame.size.height = 2*insetVertical + frame.size.height
        
        
        layer.frame = frame
        
        layer.cornerRadius = 3.0
        layer.borderColor = UIColor.redColor().CGColor //UIColor(red: 151/255.0, green: 151/255.0, blue: 151/255.0, alpha: 1.0).CGColor
        layer.borderWidth = 0.5
        layer.backgroundColor = UIColor(red: 255/255.0, green: 255/255.0, blue: 255/255.0, alpha: 1.0).CGColor
        
        createDescriptionTextView.layer.insertSublayer(layer, atIndex:0)
        
        
    }
    
    
    
    @IBAction func completeButtonAction(sender: AnyObject?)
    {
        println("complete action!")
        
        channelNameTextField.userInteractionEnabled = false
        goButton.userInteractionEnabled = false
        
        self.performFirebaseFetchForChannel(channelName, result:
            {(exists:Bool, description:String?) in
                
                if exists
                {
                    self.joinChannel()
                } else
                {
                    self.createChannel()
                }
            })
        
    }
    
    @IBAction func cancelButtonAction(sender: AnyObject?) {
        println("go back yo")
        self.dismissViewControllerAnimated(true, completion:
        {
            if self.isJoining
            {
                self.channelViewController.openChannelForChannelName(self.channelName)
            }
        })
    }
    
    
    // MARK: textFieldDelegate method!
    func textFieldShouldReturn(textField: UITextField!) -> Bool
    {
        textField.resignFirstResponder()
        
        completeButtonAction(nil)
        
        // TODO: invalidate "" channel
        
//        addChannelState = .Seeking(textField.text)
//        self.addChannelCell!.curlDownAMessage("Please wait...", animated: true)
//        
//        self.performFirebaseFetchForChannel(textField.text)
//            {(exists:Bool) in
//                
//                // TODO: add filter to make sure that this is a valid name, break before this
//                
//                self.temporaryModel!.temporary = false
//                let url = kROOT_FIREBASE + "channels/" + textField.text
//                self.temporaryModel!.initialize(dictionary: NSDictionary(), andUrl: url)
//                self.temporaryModel!.bindToWall()
//                
//                if (exists)
//                {//join
//                    println("time to join \(textField.text)")
//                    self.addChannelState = .Pending(isJoining:true, textField.text)
//                    self.joinChannel(self.temporaryModel!)
//                    
//                } else
//                {//create
//                    println("time to create \(textField.text)")
//                    self.addChannelState = .Pending(isJoining:false, textField.text)
//                    self.createChannel(self.temporaryModel!)
//                }
//                
//                self.temporaryModel = nil
//                
//        }
        
        return true
    }
    
    func performFirebaseFetchForChannel(channel:String, result:((exists:Bool, description:String?)->()) )
    {
        let channelExistenceFetch = Firebase(url: kROOT_FIREBASE + "channels/" + channel + "/meta")
        
        println("channelExistenceFetch = \(channelExistenceFetch)")

        channelExistenceFetch.observeSingleEventOfType(FEventTypeValue, withBlock: {(snap:FDataSnapshot!) in
            
            if let meta = snap.value as? NSDictionary
            {
                let description = meta["description"] as? String
                result(exists: true, description: description)
            } else
            {
                result(exists:false, description:nil)
            }
            }, withCancelBlock: {(error:NSError!) in
                println("error = \(error)")
            })
        
    }
    
    //doesn't count for deletes
    var joiningDescriptionString:String?
    func textField(textField: UITextField!, shouldChangeCharactersInRange range: NSRange, replacementString string: String!) -> Bool
    {
        
        
        
        var result = textField.text as NSString
        

        result = result.stringByReplacingCharactersInRange(range, withString: string)
        hashTagLabel.highlighted = result.length != 0
        channelNameCharacterCountLabel.text = "\(result.length) / \(20)"
        
        
        self.channelName = result
        self.channelNameExists = nil
        
        performFirebaseFetchForChannel(result,
            {(exists:Bool, description:String?) in
                println("channel \(result) exists? \(exists)")
            
                //if the fetched result is the current result, save its result, wait for time to pass... update
                self.joiningDescriptionString = description
                if (self.channelName == result)
                {
                    self.channelNameExists = exists
                    
                    
                    if self.timer{
                        self.timer!.invalidate()
                    }
                    
                    self.updateUITimer()
                    
                }
                
            })
        
        return true
    }
    
    func updateUITimer()
    {
        timer?.invalidate()
        timer = nil
        
        println("updateUITimer channel \(self.channelName) exists? \(self.channelNameExists)")
        
        if channelName == "" //invalid
        {
//            channelSearchResult.text = "We'll check if it exists."
//            goButton.alpha = 0.0
        } else
        if !(self.channelNameExists!)
        {
//            channelSearchResult.text = "You are creating this channel."
            
            animateDescriptionContainer(descriptionViewContainer, visible:false)
            animateDescriptionContainer(createDescriptionContainer , visible:true)
            
            /*
                NSDictionary *attributes = @{NSFontAttributeName: [UIFont fontWithName:@"HelveticaNeue" size:14]};
                // NSString class method: boundingRectWithSize:options:attributes:context is
                // available only on ios7.0 sdk.
                CGRect rect = [textToMeasure boundingRectWithSize:CGSizeMake(width, CGFLOAT_MAX)
                options:NSStringDrawingUsesLineFragmentOrigin
                attributes:attributes
                context:nil];
            */
            
            
            goButton.setTitle("Create", forState: .Normal)
            goButton.alpha = 1
        } else
        {
//            channelSearchResult.text = "This channel exists."
            
            animateDescriptionContainer(createDescriptionContainer , visible:false)
            
            if let description = joiningDescriptionString
            {
                descriptionLabel.text = description
                let attributes = [
                    NSFontAttributeName : descriptionLabel.font,
                                 ]
                let descriptionNSString:NSString = description
                let actualSize = descriptionNSString.boundingRectWithSize(CGSize(width: descriptionLabel.frame.size.width, height: 300), options: NSStringDrawingOptions.UsesLineFragmentOrigin, attributes: attributes, context: nil)
                descriptionLabelHeightConstraint.constant = actualSize.height
                
                animateDescriptionContainer(descriptionViewContainer, visible:true)
                
            } else
            {
                animateDescriptionContainer(descriptionViewContainer, visible: false)
            }
            
            goButton.setTitle("Join", forState: .Normal)
            goButton.alpha = 1

            
        }
        
    }
    
    func animateDescriptionContainer(descContainer:UIView, visible:Bool)
    {
        if visible && descContainer.alpha == 1.0
        {
            return
        }
        
        if !visible && descContainer.alpha == 0.0
        {
            return
        }
        
        
        descContainer.alpha = visible ? 0.0 : 1.0
//        descContainer.transform = visible ? CGAffineTransformMakeTranslation(0.0, -5.0) : CGAffineTransformIdentity
        UIView.animateWithDuration(0.4, animations:
            {
                descContainer.alpha = visible ? 1.0 : 0.0
//                descContainer.transform = !visible ? CGAffineTransformMakeTranslation(0.0, -5.0) : CGAffineTransformIdentity
            }, completion: {(b:Bool) in

            
            })
    }

    
    func joinChannel()
    {
        let userId = NSUserDefaults.standardUserDefaults().objectForKey(kNSUSERDEFAULTS_KEY_userId) as String
        
        //1 set myself as a moderator
        let membersFB = Firebase(url: "\(kROOT_FIREBASE)channels/\(self.channelName)/members/\(userId)")
        //        println("moderatorsFB \(moderatorsFB)")
        
        membersFB.setValue(true, withCompletionBlock:
            {(error:NSError!, firebase:Firebase!) in
                if error
                {
                    println("error adding myself to a channel \(error)")
                } else
                {
                    //continue joining it by adding to my users/userID/channels
                    let myChannels = Firebase(url: "\(kROOT_FIREBASE)users/\(userId)/channels/\(self.channelName)")
                    myChannels.setValue(["lastSeen":0, "muted":NSNumber(bool: false)], andPriority: NSDate().timeIntervalSince1970*1000, withCompletionBlock:
                        {(error:NSError!, firebase:Firebase!) in
                            if error
                            {
                                println("error getting my user to join channel \(error)")
                            } else
                            {
                                self.isJoining = true
                                self.cancelButtonAction(nil)
//                                self.addChannelState = .Ready
//                                self.addChannelCell!.curlDownAMessage("+ Channel", animated: true)
//                                //index of channel?
//                                let section = find(self.channels, channel)!
//                                
//                                //expand this index
//                                self.collectionView(self.channelsCollectionView, didSelectItemAtIndexPath: NSIndexPath(forItem: 0, inSection: section) )
                            }
                        })
                }
            })
    }
    
    func createChannel()
    {
        
        let userId = NSUserDefaults.standardUserDefaults().objectForKey(kNSUSERDEFAULTS_KEY_userId) as String
        
        let value =
        [
            "moderators": [userId: true],
            "members": [userId: true],
            "meta" : ["public": true, "description": createDescriptionTextView.text]
        ]
        let channelRoot = Firebase(url: "\(kROOT_FIREBASE)channels/\(self.channelName)")
        channelRoot.setValue(value, withCompletionBlock:
            {(error:NSError!, firebase:Firebase!) in
                println("error \(error) and firebase \(firebase)")
                if error
                {
                    //failure!
                } else
                {
                    let t:Float = Float(NSDate().timeIntervalSince1970*1000)
//                    println("t = \(t)")
//                    let tInt:UInt = UInt(t)
                    
                    println("t = \(t)")
                    
                    println("[\(Int.min), \(Int.max)]")
                    
                    
                    let priority = t//tInt
                    let yourChannels = Firebase(url: "\(kROOT_FIREBASE)users/\(userId)/channels/\(self.channelName)")
                    yourChannels.setValue([
                        "lastSeen":0,
                        "muted":false
                        ], andPriority:priority, withCompletionBlock:
                        {(error:NSError!, firebase:Firebase!) in
                            if error
                            {
                                
                            } else
                            {
                                self.isJoining = true
                                self.cancelButtonAction(nil)
//                                self.addChannelState = .Ready
//                                self.addChannelCell!.curlDownAMessage("+ Channel", animated: true)
//                                //index of channel?
//                                let section = find(self.channels, channel)!
//                                
//                                //expand this index
//                                self.collectionView(self.channelsCollectionView, didSelectItemAtIndexPath: NSIndexPath(forItem: 0, inSection: section) )
                                
                            }
                        })
                    
                }
            })
    }
    
    // Mark: UITextViewDelegate methods
    func textView(textView: UITextView!, shouldChangeTextInRange range: NSRange, replacementText text: String!) -> Bool
    {
        if textView == createDescriptionTextView
        {
            if text == "\n"
            {
                self.completeButtonAction(nil)
                textView.resignFirstResponder()
                return false
            }
        }
        
        return true
    }
    
    deinit
    {
        NSNotificationCenter.defaultCenter().removeObserver(self)
    }
    
    func keyboardWillToggle(notification:NSNotification)
    {

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
        var constraintHeight = ( dy < 0 ? 0 : dy )
        
        

        //if constraintHeight = 0, then edgeInsetBottom = 0, else
        

        
        var signCorrection = -1
        if (frameBegin.origin.y < 0 || frameBegin.origin.x < 0 || frameEnd.origin.y < 0 || frameEnd.origin.x < 0)
        {
            signCorrection = 1;
        }
        //            CGFloat widthChange  = (endFrame.origin.x - startFrame.origin.x) * signCorrection;
        let heightChange = (frameEnd.origin.y - frameBegin.origin.y) * signCorrection;
        
        
        
        if constraintHeight > 300
        {
            constraintHeight = 216
            self.createButtonBottomConstraint.constant = constraintHeight
        } else
        {
            UIView.animateWithDuration(0.3, delay: 0.0, options: UIViewAnimationOptions.BeginFromCurrentState | UIViewAnimationOptions.fromRaw(7 << 16)!, animations:
                {
                    self.createButtonBottomConstraint.constant = constraintHeight
                    self.goButton.superview.layoutIfNeeded()
                    
                }, completion: nil)
        }
    }

}