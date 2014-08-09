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

class SWChannelsViewController: UIViewController, UICollectionViewDataSource, UICollectionViewDelegate, UICollectionViewDelegateFlowLayout, UIGestureRecognizerDelegate, ChannelActivityIndicatorDelegate
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

        
        self.navigationController.setNavigationBarHidden(false, animated: true)
        self.navigationController.navigationBar.translucent = false
        self.navigationController.navigationBar.barTintColor = UIColor(hexString: kNiceColors["green"])
        self.navigationController.navigationBar.tintColor = UIColor.whiteColor()

//        println("fonts! \(UIFont.familyNames())")
        let thing = UIFont.fontNamesForFamilyName("Avenir")
//        println("avenir \(thing)")
        
        let font = UIFont(name: "Avenir-Book", size: 15) //24 descriptors, 34 channel tittle
        let titleDict: NSDictionary = [NSForegroundColorAttributeName: UIColor.whiteColor(),
                                    NSFontAttributeName: font]
        self.navigationController.navigationBar.titleTextAttributes = titleDict
        self.navigationItem.title = "Shortwave Beta"
        
        
        var addButton = UIBarButtonItem(title: "Add", style: UIBarButtonItemStyle.Plain, target: self, action: "addBarButtonAction:")
        addButton.setTitleTextAttributes(titleDict, forState: UIControlState.Normal)
            
        self.navigationItem.rightBarButtonItem = addButton

        channelsCollectionView.viewForBaselineLayout().layer.speed = 1
        
        navigationItem.hidesBackButton = true
        bindToChannels()
        

        
    }
    
    func addBarButtonAction(sender:AnyObject?)
    {
        performSegueWithIdentifier("Add", sender: self)
    }
    
    func bindToChannels()
    {
        let url = "\(kROOT_FIREBASE)users/\(NSUserDefaults.standardUserDefaults().objectForKey(kNSUSERDEFAULTS_KEY_userId))/channels/"
        let f = Firebase(url: url)
        
        f.observeEventType(FEventTypeChildAdded, andPreviousSiblingNameWithBlock:
            {
                (snap:FDataSnapshot?, str:String?) in
                
                if let dictionary = snap?.value as? NSDictionary
                {
                    let channelModel = SWChannelModel(dictionary: dictionary, url: "\(url)\(snap!.name)")
                    channelModel.delegate = self //updating channel activity
                    
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
                
                self.channelsCollectionView.insertSections(NSIndexSet(index: i))
            
            }, completion:
            {(b:Bool) in
            
            })
        
    }
    
    
    //collectionView delegate and datasource methods
    func numberOfSectionsInCollectionView(collectionView: UICollectionView!) -> Int
    {
        return channels.count //+ 1
    }
    
    func collectionView(collectionView: UICollectionView!, numberOfItemsInSection section: Int) -> Int
    {
//        if section == channels.count
//        {
//            return 1
//        }
//        let channelMode = channels[section]
        return 1 //+ (channelMode.isExpanded ? 1 : 0)
    }
    
    func collectionView(collectionView: UICollectionView!, cellForItemAtIndexPath indexPath: NSIndexPath!) -> UICollectionViewCell!
    {
//        if indexPath.row == 0 && indexPath.section == channels.count
//        {
//            // add-channel cell
//            let cell = channelsCollectionView.dequeueReusableCellWithReuseIdentifier("SWAddChannelCell", forIndexPath: indexPath) as UICollectionViewCell
//            if !addChannelCell
//            {
//                addChannelCell = cell as? SWAddChannelCell
//            }
//            
//            return cell
//            
//        }

//        else
//        if indexPath.row == 0
//        {
            let channelCell = collectionView.dequeueReusableCellWithReuseIdentifier("SWChannelCell", forIndexPath: indexPath) as SWChannelCell
            
            channelCell.channelModel = channels[indexPath.section]
        
            
            return channelCell
//        } else
//        {
//            let inceptionCell = collectionView.dequeueReusableCellWithReuseIdentifier("SWInceptionCell", forIndexPath: indexPath) as SWInceptionCell
//            inceptionCell.messagesCollectionView.scrollEnabled = true
//            inceptionCell.contentView.frame.size = CGSizeMake(320, self.view.frame.size.height - 52 - 20)//idk why!
//            
//
//            let channel = channels[indexPath.section]
//            channel.messageCollectionView = inceptionCell.messagesCollectionView //setup delegate datasource and reloads
//      
//            let animateToFull = indexPathsToListenFor[indexPath]
//            if animateToFull
//            {
//                inceptionCell.animateInceptionCell(expanded: true)
//                indexPathsToListenFor = [:] //clear
//            }
//            return inceptionCell
//        }
    }
    
    func collectionView(collectionView: UICollectionView!, didSelectItemAtIndexPath indexPath: NSIndexPath!)
    {
        openChannel(channels[indexPath.section])
        
        
//        if indexPath.row == 0 && indexPath.section != channels.count
//        {
//
//            let height = collectionView.cellForItemAtIndexPath(indexPath)!.frame.origin.y - 20
//
//            
//            UIView.animateWithDuration(0.3)
//            {
//                    self.channelsCollectionView.contentOffset = self.targetContentOffsetForProposedContentOffset(CGPoint(x: 0,y:height))
//            }
//            
//            let channel = self.channels[indexPath.section];
//            channel.isExpanded = !channel.isExpanded
//            selectedChannel = (channel.isExpanded ? channel : nil)
//            
//            collectionView.performBatchUpdates(
//                {
//                    let targetIndexPaths = [NSIndexPath(forItem: 1, inSection: indexPath.section)];
//                    
//                    
//                        if channel.isExpanded
//                        {
//                            self.bottomConstraintComposeBar.constant = 0
//                            self.indexPathsToListenFor[NSIndexPath(forItem: 1, inSection: indexPath.section)] = true
//                            self.channelsCollectionView.scrollEnabled = false
//                            collectionView.insertItemsAtIndexPaths(targetIndexPaths)
//                        } else
//                        {
//                            self.bottomConstraintComposeBar.constant = -48
//                            self.channelsCollectionView.scrollEnabled = true
//                            let inceptionCell = self.channelsCollectionView.cellForItemAtIndexPath(NSIndexPath(forItem: 1, inSection: indexPath.section)) as SWInceptionCell
//                            inceptionCell.animateInceptionCell(expanded:false)
//                            collectionView.deleteItemsAtIndexPaths(targetIndexPaths)
//                            if self.composeBar.textField.isFirstResponder()
//                            {
//                                self.composeBar.textField.resignFirstResponder()
//                            }
//                    }
//                    
//                    
//                }, completion:
//                {(b:Bool) in
//                    
//                })
//        }
//        else
//        if indexPath.section == channels.count
//        {
//            switch addChannelState
//            {
//                case .Ready:
//                    beginAddingAChannel()
//                
//                default:
//                    break;
//            }
//        }
    }
    
//    func beginAddingAChannel()
//    {
//        addChannelState = .Typing
//        let tempChannelModel = SWChannelModel(temporary: true)
//        channelsCollectionView.performBatchUpdates(
//            {
//                self.temporaryModel = tempChannelModel
//                self.channels += tempChannelModel
//                self.channelsCollectionView.insertSections(NSIndexSet(index: self.channels.count - 1))
//            }, completion: {(b:Bool) in })
//    }
    
    func collectionView(collectionView: UICollectionView!, layout collectionViewLayout: UICollectionViewLayout!, sizeForItemAtIndexPath indexPath: NSIndexPath!) -> CGSize
    {
//        if (indexPath.item == 0)
//        {
            return CGSizeMake(320, 71)
//        }
//        
//        return CGSizeMake(320, self.view.frame.size.height - 52 - 20)
        
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
    
    
    
    
    
    
    
    
   
    
    
    deinit
    {
        NSNotificationCenter.defaultCenter().removeObserver(self)
    }

    

    
    /*
    // MARK: SWComposeBarViewDelegate
    func composeBarView(composeBarView: SWComposeBarView, sendMessage message: String)
    {
        let userID = NSUserDefaults.standardUserDefaults().objectForKey(kNSUSERDEFAULTS_KEY_userId) as String
        let message = SWMessageModel(userID: userID, text: message)
        
        message.sendMessageToChannel(selectedChannel!.name!)
        
    }
    */

    func openChannelForChannelName(channelName:String)
    {
        let filteredChannels = channels.filter {
            return ($0.name!  ==  channelName)
        }
        
        if filteredChannels.count  !=  0
        {
            openChannel(filteredChannels.last)
        }
    }
    
    func openChannel(channel:SWChannelModel)
    {
        selectedChannel = channel
        performSegueWithIdentifier("Messages", sender: self)
    }
    
    override func prepareForSegue(segue: UIStoryboardSegue!, sender: AnyObject!)
    {
        if let messagesViewController = segue.destinationViewController as? SWMessagesViewController //&& segue.identifier == "Messages"
        {
            messagesViewController.channelModel = selectedChannel
        } else
        if let addViewController = segue.destinationViewController as? SWNewChannel
        {
            addViewController.channelViewController = self
        }
    }
    

    //channel receives activity indicator
    func channel(channel: SWChannelModel, hasNewActivity: Bool)
    {
        var channelCell:SWChannelCell!
        
        if let index = find(channels, channel)
        {
            if let item = channelsCollectionView.cellForItemAtIndexPath(NSIndexPath(forItem: 0, inSection: index))
            {
                if let channelCell2 = item as? SWChannelCell
                {
                    channelCell = channelCell2 //channelCell.setIsSynchronized(true)
                }
            }
        } else
        {
            println("had to find channel \(channel) in channels \(channels)")
            assert(false)
        }
    
        
        //update the cell ui if it is visibru
        if let cell = channelCell
        {
            channelCell.setIsSynchronized(!hasNewActivity)
            
            if hasNewActivity
            {
                channelCell.push()
            }
        }
    }
    

    
}