//
//  SWChannelViewController.swift
//  Shortwave
//
//  Created by Ethan Sherr on 7/24/14.
//  Copyright (c) 2014 Ethan Sherr. All rights reserved.
//

import Foundation
import UIKit

enum AddChannelState
{
    case Ready
    case Typing
    case Seeking(String) //"the name"
    case Pending(isJoining:Bool, String)
}

class SWChannelsViewController: UIViewController, UICollectionViewDataSource, UICollectionViewDelegate, UICollectionViewDelegateFlowLayout, UIGestureRecognizerDelegate, UITextFieldDelegate, SWComposeBarViewDelegate
{
    var indexPathsToListenFor = Dictionary<NSIndexPath,Bool>()
    
    @IBOutlet var channelsCollectionView: UICollectionView!
    var channels:Array<SWChannelModel> = [SWChannelModel]()
    
    
    @IBOutlet weak var composeBar: SWComposeBarView!
    @IBOutlet weak var layout: SWChannelsLayout!
    @IBOutlet weak var bottomConstraintComposeBar: NSLayoutConstraint!
    
    var addChannelCell:SWAddChannelCell?
    var temporaryModel:SWChannelModel?
    
    //the current state of the addChannel button/cell
    var addChannelState:AddChannelState = .Ready

    var selectedChannel:SWChannelModel?
    
    override func viewDidLoad()
    {
        super.viewDidLoad()
        
        channelsCollectionView.delegate = self
        channelsCollectionView.dataSource = self
        channelsCollectionView.alwaysBounceVertical = true
        
        composeBar.delegate = self
        
        

        channelsCollectionView.viewForBaselineLayout().layer.speed = 1
        
        navigationItem.hidesBackButton = true
        bindToChannels()
        
        NSNotificationCenter.defaultCenter().addObserver(self, selector: "keyboardWillToggle:", name: UIKeyboardWillShowNotification, object: nil)
        NSNotificationCenter.defaultCenter().addObserver(self, selector: "keyboardWillToggle:", name: UIKeyboardWillHideNotification, object: nil)
        
    }
    
    func bindToChannels()
    {
        let url = "\(kROOT_FIREBASE)users/\(NSUserDefaults.standardUserDefaults().objectForKey(kNSUSERDEFAULTS_KEY_userId))/channels/"
        let f = Firebase(url: url)
        println("f = \(f)")
        f.observeEventType(FEventTypeChildAdded, andPreviousSiblingNameWithBlock:
            {
                (snap:FDataSnapshot?, str:String?) in
                
                if let dictionary = snap?.value as? NSDictionary
                {
                    let channelModel = SWChannelModel(dictionary: dictionary, url: "\(url)\(snap!.name)")
                    //check if this already exists!
                    let result = self.channels.filter { $0.name == channelModel.name }
                    
                    if (result.count != 0)
                    {
                        return
                    }
                    
                    
                    let index = self.channels.count;
                    
                    self.insertChannel(channelModel, atIndex:index)
                }
                
                
            } )
    }
    
    func insertChannel(channel: SWChannelModel, atIndex i:Int)
    {
        
        channelsCollectionView.performBatchUpdates(
            {
                self.channels.insert(channel, atIndex: i)
//                self.channelsCollectionView.insertItemsAtIndexPaths([NSIndexPath(forItem: 0, inSection: i)])
                
                self.channelsCollectionView.insertSections(NSIndexSet(index: i))
            
            }, completion:
            {(b:Bool) in
            
            })
        
    }
    
    
    //collectionView delegate and datasource methods
    func numberOfSectionsInCollectionView(collectionView: UICollectionView!) -> Int
    {
        return channels.count + 1
    }
    
    func collectionView(collectionView: UICollectionView!, numberOfItemsInSection section: Int) -> Int
    {
        if section == channels.count
        {
            return 1
        }
        let channelMode = channels[section]
        return 1 + (channelMode.isExpanded ? 1 : 0)
    }
    
    func collectionView(collectionView: UICollectionView!, cellForItemAtIndexPath indexPath: NSIndexPath!) -> UICollectionViewCell!
    {
        if indexPath.row == 0 && indexPath.section == channels.count
        {
            // add-channel cell
            let cell = channelsCollectionView.dequeueReusableCellWithReuseIdentifier("SWAddChannelCell", forIndexPath: indexPath) as UICollectionViewCell
            if !addChannelCell
            {
                addChannelCell = cell as? SWAddChannelCell
            }
            
            return cell
            
        } else
        if indexPath.row == 0
        {
            let channelCell = collectionView.dequeueReusableCellWithReuseIdentifier("SWChannelCell", forIndexPath: indexPath) as SWChannelCell
            
            channelCell.channelModel = channels[indexPath.section]
            if channelCell.channelModel!.temporary
            {
                //this cell takes focus!
                channelCell.textField.delegate = self
                channelCell.textField.becomeFirstResponder()
            }
            
            return channelCell
        } else
        {
            let inceptionCell = collectionView.dequeueReusableCellWithReuseIdentifier("SWInceptionCell", forIndexPath: indexPath) as SWInceptionCell
            inceptionCell.messagesCollectionView.scrollEnabled = true
            inceptionCell.contentView.frame.size = CGSizeMake(320, self.view.frame.size.height - 52 - 20)//idk why!
            

            let channel = channels[indexPath.section]
            channel.messageCollectionView = inceptionCell.messagesCollectionView //setup delegate datasource and reloads
      
            let animateToFull = indexPathsToListenFor[indexPath]
            if animateToFull
            {
                inceptionCell.animateInceptionCell(expanded: true)
                indexPathsToListenFor = [:] //clear
            }
            return inceptionCell
        }
    }
    
    func collectionView(collectionView: UICollectionView!, didSelectItemAtIndexPath indexPath: NSIndexPath!)
    {
        if indexPath.row == 0 && indexPath.section != channels.count
        {

            let height = collectionView.cellForItemAtIndexPath(indexPath)!.frame.origin.y - 20

            
            UIView.animateWithDuration(0.3)
            {
                    self.channelsCollectionView.contentOffset = self.targetContentOffsetForProposedContentOffset(CGPoint(x: 0,y:height))
            }
            
            let channel = self.channels[indexPath.section];
            channel.isExpanded = !channel.isExpanded
            selectedChannel = (channel.isExpanded ? channel : nil)
            
            let myFloat = 0.0
            println(String(format:"myFloat: %.2f", myFloat))
            
            collectionView.performBatchUpdates(
                {
                    
                    
                    
                    
                    
                    let targetIndexPaths = [NSIndexPath(forItem: 1, inSection: indexPath.section)];
                    
                    
                        if channel.isExpanded
                        {
                            self.bottomConstraintComposeBar.constant = 0
                            self.indexPathsToListenFor[NSIndexPath(forItem: 1, inSection: indexPath.section)] = true
                            self.channelsCollectionView.scrollEnabled = false
                            collectionView.insertItemsAtIndexPaths(targetIndexPaths)
                        } else
                        {
                            self.bottomConstraintComposeBar.constant = -48
                            self.channelsCollectionView.scrollEnabled = true
                            let inceptionCell = self.channelsCollectionView.cellForItemAtIndexPath(NSIndexPath(forItem: 1, inSection: indexPath.section)) as SWInceptionCell
                            inceptionCell.animateInceptionCell(expanded:false)
                            collectionView.deleteItemsAtIndexPaths(targetIndexPaths)
                            if self.composeBar.textField.isFirstResponder()
                            {
                                self.composeBar.textField.resignFirstResponder()
                            }
                    }
                    
                    
                }, completion:
                {(b:Bool) in
                    
                })
        }
        else
        if indexPath.section == channels.count
        {
            switch addChannelState
            {
                case .Ready:
                    beginAddingAChannel()
                
                default:
                    break;
            }
        }
    }
    
    func beginAddingAChannel()
    {
        addChannelState = .Typing
        let tempChannelModel = SWChannelModel(temporary: true)
        channelsCollectionView.performBatchUpdates(
            {
                self.temporaryModel = tempChannelModel
                self.channels += tempChannelModel
                self.channelsCollectionView.insertSections(NSIndexSet(index: self.channels.count - 1))
            }, completion: {(b:Bool) in })
    }
    
    func collectionView(collectionView: UICollectionView!, layout collectionViewLayout: UICollectionViewLayout!, sizeForItemAtIndexPath indexPath: NSIndexPath!) -> CGSize
    {
        if (indexPath.item == 0)
        {
            return CGSizeMake(320, 52)
        }
        
        return CGSizeMake(320, self.view.frame.size.height - 52 - 20)
        
    }
    
    //UICollectionViewDelegateFlowLayout
    func collectionView(collectionView: UICollectionView!, layout collectionViewLayout: UICollectionViewLayout!, insetForSectionAtIndex section: Int) -> UIEdgeInsets
    {
     
        return UIEdgeInsetsMake(0, 0, 0, 0)
    }
    
    func collectionView(collectionView: UICollectionView!, layout collectionViewLayout: UICollectionViewLayout!, minimumInteritemSpacingForSectionAtIndex section: Int) -> CGFloat
    {
        return 0
    }
    
    func collectionView(collectionView: UICollectionView!, layout collectionViewLayout: UICollectionViewLayout!, minimumLineSpacingForSectionAtIndex section: Int) -> CGFloat
    {
        return 0
    }
    
    
    func targetContentOffsetForProposedContentOffset(contentOffset:CGPoint) -> CGPoint
    {
        let collectionViewContentSize = self.view.bounds.size;
        if collectionViewContentSize.height <= self.channelsCollectionView.bounds.size.height
        {
            return CGPointMake(0, contentOffset.y)
        }
        return contentOffset
    }
    
    // MARK: textFieldDelegate method!
    func textFieldShouldReturn(textField: UITextField!) -> Bool
    {
        textField.resignFirstResponder()
        
        // TODO: invalidate "" channel
        
        addChannelState = .Seeking(textField.text)
        self.addChannelCell!.curlDownAMessage("Please wait...", animated: true)
        
        self.performFirebaseFetchForChannel(textField.text)
        {(exists:Bool) in
            
            // TODO: add filter to make sure that this is a valid name, break before this
            
            self.temporaryModel!.temporary = false
            let url = kROOT_FIREBASE + "channels/" + textField.text
            self.temporaryModel!.initialize(dictionary: NSDictionary(), andUrl: url)
            self.temporaryModel!.bindToWall()
            
            if (exists)
            {//join
                println("time to join \(textField.text)")
                self.addChannelState = .Pending(isJoining:true, textField.text)
                self.joinChannel(self.temporaryModel!)
                
            } else
            {//create
                println("time to create \(textField.text)")
                self.addChannelState = .Pending(isJoining:false, textField.text)
                self.createChannel(self.temporaryModel!)
            }
            
            self.temporaryModel = nil
            
        }
        
        return true
    }
    
    func joinChannel(channel:SWChannelModel)
    {
        let userId = NSUserDefaults.standardUserDefaults().objectForKey(kNSUSERDEFAULTS_KEY_userId) as String
        
        //1 set myself as a moderator
        let membersFB = Firebase(url: "\(kROOT_FIREBASE)channels/\(channel.name!)/members/\(userId)")
//        println("moderatorsFB \(moderatorsFB)")
    
        membersFB.setValue(true, withCompletionBlock:
            {(error:NSError!, firebase:Firebase!) in
                if error
                {
                    println("error adding myself to a channel \(error)")
                } else
                {
                    //continue joining it by adding to my users/userID/channels
                    let myChannels = Firebase(url: "\(kROOT_FIREBASE)users/\(userId)/channels/\(channel.name!)")
                    myChannels.setValue(["lastSeen":0, "muted":false], andPriority: NSDate().timeIntervalSince1970*1000, withCompletionBlock:
                        {(error:NSError!, firebase:Firebase!) in
                            if error
                            {
                                println("error getting my user to join channel \(error)")
                            } else
                            {
                                self.addChannelState = .Ready
                                self.addChannelCell!.curlDownAMessage("+ Channel", animated: true)
                                //index of channel?
                                let section = find(self.channels, channel)!
                                
                                //expand this index
                                self.collectionView(self.channelsCollectionView, didSelectItemAtIndexPath: NSIndexPath(forItem: 0, inSection: section) )
                            }
                        })
                }
            })
    }
    
    func createChannel(channel:SWChannelModel)
    {
        
        let userId = NSUserDefaults.standardUserDefaults().objectForKey(kNSUSERDEFAULTS_KEY_userId) as String
        
        let value =
        [
            "moderators": [userId: true],
            "members": [userId: true],
            "public": true
        ]
        
        channel.channelRoot!.setValue(value, withCompletionBlock:
            {(error:NSError!, firebase:Firebase!) in
                println("error \(error) and firebase \(firebase)")
                if error
                {
                    //failure!
                } else
                {
                    let priority = NSDate().timeIntervalSince1970*1000
                    let yourChannels = Firebase(url: "\(kROOT_FIREBASE)users/\(userId)/channels/\(channel.name!)")
                    yourChannels.setValue([
                            "lastSeen":0,
                            "muted":false
                        ], andPriority:priority, withCompletionBlock:
                        {(error:NSError!, firebase:Firebase!) in
                            if error
                            {
                                
                            } else
                            {
                                self.addChannelState = .Ready
                                self.addChannelCell!.curlDownAMessage("+ Channel", animated: true)
                                //index of channel?
                                let section = find(self.channels, channel)!
                                
                                //expand this index
                                self.collectionView(self.channelsCollectionView, didSelectItemAtIndexPath: NSIndexPath(forItem: 0, inSection: section) )
                                
                            }
                        })
                    
                }
            })
    }
    
    
    func performFirebaseFetchForChannel(channel:String, result:((exists:Bool)->()) )
    {
        let channelExistenceFetch = Firebase(url: kROOT_FIREBASE + "channels/" + channel + "/public")
        channelExistenceFetch.observeSingleEventOfType(FEventTypeValue)
            {(snap:FDataSnapshot!) in
                
                if let isPublic = snap.value as? Bool
                {
                    // TODO: add support for isPublic == false
                    result(exists: true)
                } else
                {
                    result(exists: false)
                }
        }
    }
    
    func textField(textField: UITextField!, shouldChangeCharactersInRange range: NSRange, replacementString string: String!) -> Bool
    {

        
        
        var result = textField.text as NSString
        result = result.stringByReplacingCharactersInRange(range, withString: string)
        
        performFirebaseFetchForChannel(result,
            {(exists:Bool) in
                println("channel \(result) exists? \(exists)")
                if exists
                {
                    self.addChannelCell!.curlDownAMessage("Join '\(result)'?", animated:true)
                } else
                {
                    self.addChannelCell!.curlDownAMessage("Create '\(result)'?", animated:true)
                }
            })
        
        return true
    }
    
    
    deinit
    {
        NSNotificationCenter.defaultCenter().removeObserver(self)
    }

    
    /// MARK: keyboardWillToggle for willShow and willHide
    func keyboardWillToggle(notification:NSNotification)
    {
        if !composeBar.textField.isFirstResponder()
        {
            return
        }
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

        println("durationV = \(durationV) and curveV = \(curveV)")
//        println("duration = \(duration) and curve = \(animationCurve)")
        
        let dy = frameBegin.origin.y - frameEnd.origin.y
        let constraintHeight = (dy < 0 ? 0 : dy )
        UIView.animateWithDuration(0.3, delay: 0.0, options: UIViewAnimationOptions.BeginFromCurrentState | UIViewAnimationOptions.fromRaw(7 << 16)!, animations:
            {
                self.bottomConstraintComposeBar.constant = constraintHeight
                self.composeBar.layoutIfNeeded()
            }, completion: nil)
    }
    
    // MARK: SWComposeBarViewDelegate
    func composeBarView(composeBarView: SWComposeBarView, sendMessage message: String)
    {
        let userID = NSUserDefaults.standardUserDefaults().objectForKey(kNSUSERDEFAULTS_KEY_userId) as String
        let message = SWMessageModel(userID: userID, text: message)
        
        message.sendMessageToChannel(selectedChannel!.name!)
        
    }
    
    
    
    
    
    
    
    
    
}