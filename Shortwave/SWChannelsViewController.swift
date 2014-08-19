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
    
    func back()
    {
        self.navigationController.popViewControllerAnimated(true)
    }
    
    override func viewDidLoad()
    {
        super.viewDidLoad()
        NSNotificationCenter.defaultCenter().addObserver(self, selector: "joinChannelRemoteNotification:", name: kRemoteNotification_JoinChannel, object: nil)
        
//        self.navigationItem.backBarButtonItem = [[UIBarButtonItem alloc] initWithTitle:@"" style:UIBarButtonItemStylePlain target:nil action:nil];
        let backButton = UIBarButtonItem(title: "", style: UIBarButtonItemStyle.Plain, target: self, action: "back")
        self.navigationItem.backBarButtonItem = backButton
        
        channelsCollectionView.delegate = self
        channelsCollectionView.dataSource = self
        channelsCollectionView.alwaysBounceVertical = true

        self.navigationController.setNavigationBarHidden(false, animated: true)
        self.navigationController.navigationBar.translucent = false
        self.navigationController.navigationBar.barTintColor = UIColor(hexString: kNiceColors["bar"])
        self.navigationController.navigationBar.tintColor = UIColor.whiteColor()

//        let thing = UIFont.fontNamesForFamilyName("Avenir")
//        println("avenir \(thing)")
        
        let font = UIFont(name: "Avenir-Black", size: 17) //24 descriptors, 34 channel tittle
        let titleDict: NSDictionary = [NSForegroundColorAttributeName: UIColor.whiteColor(),
                                    NSFontAttributeName: font]
        
        var addButtonButton = UIButton(frame: CGRect(x: 12, y:0, width:70-7, height:48))
        addButtonButton.addTarget(self, action: "addBarButtonAction:", forControlEvents: UIControlEvents.TouchUpInside)
        addButtonButton.titleLabel.font = font;
        addButtonButton.setTitleColor(UIColor.whiteColor(), forState: .Normal)
        addButtonButton.setTitle("Add", forState: .Normal)
        
        var addButtonView = UIView(frame: CGRect(x: 0, y: 0 , width:70, height:48))
        addButtonView.backgroundColor = UIColor.clearColor()
        addButtonView.addSubview(addButtonButton)
        
        var whiteLine = UIView(frame: CGRect(x: 0, y: 0, width: 0.5, height:48))
        whiteLine.backgroundColor = UIColor.whiteColor()
        addButtonView.addSubview(whiteLine)
        
        
        var addButton = UIBarButtonItem(customView: addButtonView)
        //UIBarButtonItem(title: "Add", style: UIBarButtonItemStyle.Plain, target: self, action: "addBarButtonAction:")
        
        addButton.setTitleTextAttributes(titleDict, forState: UIControlState.Normal)
            
        self.navigationItem.rightBarButtonItem = addButton

        
        navigationItem.hidesBackButton = true
        
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
                    
                    let f2 = Firebase(url: kROOT_FIREBASE + "/channels/" + snap!.name + "/meta" )
                    f2.observeEventType(FEventTypeValue)
                    {
                        (f2Snapshot:FDataSnapshot!) in
                        
                        if let meta = f2Snapshot.value as? NSDictionary
                        {
                            let channelModel = SWChannelModel(dictionary: dictionary, url: "\(url)\(snap!.name)", andChannelMeta:meta)
                            channelModel.delegate = self //updating channel activity
                            
                            //check if this already exists!
                            let result = self.channels.filter { $0.name == channelModel.name }
                            
                            if (result.count != 0)
                            {
                                return
                            }
                            
                            
                            let index = self.channels.count;
                            
                            //is this the channel that triggered a remote notification which the user opened the app with?
                            println("watch for \((UIApplication.sharedApplication().delegate as AppDelegate).channelFromRemoteNotification) this is \(channelModel.name!)")
                            
                            if let channelFromRemoteNotification = (UIApplication.sharedApplication().delegate as AppDelegate).channelFromRemoteNotification
                            {
                                if channelFromRemoteNotification == channelModel.name!
                                {
                                    self.openChannel(channelModel)
                                    (UIApplication.sharedApplication().delegate as AppDelegate).channelFromRemoteNotification = nil
                                }
                            }
                            self.insertChannel(channelModel, atIndex:index)
                        }
                    }
                    
                }
                
                
            } )
        
        f.observeEventType(FEventTypeChildRemoved, withBlock: {(snapshot:FDataSnapshot!) in
            
            let name = snapshot.name
            
            let names = self.channels.filter {$0.name == name}
            
            if names.count > 0
            {
                let channelModel = names[0]

                if let index = find(self.channels, channelModel)
                {
                    
                    self.channelsCollectionView.performBatchUpdates(
                        {
                            self.channels.removeAtIndex(index)
                            self.channelsCollectionView.deleteSections(NSIndexSet(index: index))
                        }, completion: {(finished:Bool) in })
                    
                    
                }
                
            }
            

        })

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
        
            channelCell.contentView.frame = channelCell.bounds
            channelCell.contentView.clipsToBounds = true
//            channelCell.contentView.backgroundColor = UIColor(red: 0.5, green: 0, blue: 0, alpha: 0.5)
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
    override func viewDidAppear(animated: Bool) {
        super.viewDidAppear(animated)
        
        bindToChannels()
        
    }
    override func viewDidDisappear(animated: Bool)
    {
        super.viewDidDisappear(animated)
        
        let selectedPaths = channelsCollectionView.indexPathsForSelectedItems()
        for thing in selectedPaths
        {
            if let indexPath = thing as? NSIndexPath
            {
                channelsCollectionView.deselectItemAtIndexPath(indexPath, animated: false)
            }
        }
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
            let channel = channels[indexPath.section]
            return CGSizeMake(320, SWChannelCell.cellHeightGivenChannel(channel) )

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
//            println("had to find channel \(channel) in channels \(channels)")
//            assert(false)
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
    
    func scrollViewDidScroll(scrollView: UIScrollView!)
    {
        for channelCell in channelsCollectionView.visibleCells() as [SWChannelCell]
        {
            channelCell.hideLeaveChannelConfirmUI()
        }
    }
    
    
    func joinChannelRemoteNotification(notificaiton:NSNotification)
    {
        println("joinChannelremoteNotification to be handled by SWChannelsViewController")
        
        let appDelegate = UIApplication.sharedApplication().delegate as AppDelegate
        if let channelName = appDelegate.channelFromRemoteNotification
        {
            //of all channels, is channelName one of them?
            let channelsWithSameName = channels.filter {$0.name! == channelName}
            if channelsWithSameName.count > 0
            {
                //let's open this channel!
                openChannel(channelsWithSameName.last)
                appDelegate.channelFromRemoteNotification = nil //action complete
            }
        }
    }
    


//    func collectionView(collectionView: UICollectionView!, didHighlightItemAtIndexPath indexPath: NSIndexPath!)
//    {
//        let cell = collectionView.cellForItemAtIndexPath(indexPath)
//        cell.backgroundColor = UIColor(hexString: kNiceColors["green"] )
//    }
//    
//    func collectionView(collectionView: UICollectionView!, didUnhighlightItemAtIndexPath indexPath: NSIndexPath!)
//    {
//    
//        let cell = collectionView.cellForItemAtIndexPath(indexPath)
//        cell.backgroundColor = UIColor.clearColor()
//        
//    }
    
//    - (void)collectionView:(UICollectionView *)colView didHighlightItemAtIndexPath:(NSIndexPath *)indexPath {
//    UICollectionViewCell* cell = [colView cellForItemAtIndexPath:indexPath];
//    cell.contentView.backgroundColor = [UIColor colorWithRed:0 green:0 blue:1 alpha:0.5];
//    }
//    
//    - (void)collectionView:(UICollectionView *)colView didUnhighlightItemAtIndexPath:(NSIndexPath *)indexPath {
//    UICollectionViewCell* cell = [colView cellForItemAtIndexPath:indexPath];
//    cell.contentView.backgroundColor = nil;
//    }

    
}