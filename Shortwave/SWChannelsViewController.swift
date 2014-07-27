//
//  SWChannelViewController.swift
//  Shortwave
//
//  Created by Ethan Sherr on 7/24/14.
//  Copyright (c) 2014 Ethan Sherr. All rights reserved.
//

import Foundation
import UIKit

class SWChannelsViewController: UIViewController, UICollectionViewDataSource, UICollectionViewDelegate, UICollectionViewDelegateFlowLayout
{
    var indexPathsToListenFor = Dictionary<NSIndexPath,Bool>()
    
    @IBOutlet var channelsCollectionView: UICollectionView!
    
    var channels:Array<SWChannelModel> = [SWChannelModel]()
    
    @IBOutlet weak var layout: SWChannelsLayout!
    
    
    override func viewDidLoad()
    {
        super.viewDidLoad()
        
        channelsCollectionView.delegate = self
        channelsCollectionView.dataSource = self
        channelsCollectionView.alwaysBounceVertical = true
        
        
//        let newActions = ["onOrderOut":NSNull(),
//                          "sublayers":NSNull(),
//                          "contents":NSNull(),
//                          "bounds":NSNull()]
//        channelsCollectionView.viewForBaselineLayout().layer.actions = newActions
        channelsCollectionView.viewForBaselineLayout().layer.speed = 0.1
        
        navigationItem.hidesBackButton = true
        bindToChannels()
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
//        println("numberOfSections \(channels.count)")
        return channels.count
    }
    
    func collectionView(collectionView: UICollectionView!, numberOfItemsInSection section: Int) -> Int
    {
        let channelMode = channels[section]
//        println("numberOfRows 1 in section \(section)")
        return 1 + (channelMode.isExpanded ? 1 : 0)
    }
    
    func collectionView(collectionView: UICollectionView!, cellForItemAtIndexPath indexPath: NSIndexPath!) -> UICollectionViewCell!
    {
        
//        println("cell4Row at \(indexPath.item), \(indexPath.section)" )
        if indexPath.row == 0
        {
            let channelCell = collectionView.dequeueReusableCellWithReuseIdentifier("SWChannelCell", forIndexPath: indexPath) as SWChannelCell
//            println("SWChannelCell cell!")
            channelCell.channelModel = channels[indexPath.section]
            return channelCell
        } else
        {
            let inceptionCell = collectionView.dequeueReusableCellWithReuseIdentifier("SWInceptionCell", forIndexPath: indexPath) as SWInceptionCell
      
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
        if indexPath.row == 0
        {

            
//            self.channelsCollectionView.scrollEnabled = false
            //scroll to someplace
            println("collectionView.cellForItemAtIndexPath(indexPath)?.frame \(collectionView.cellForItemAtIndexPath(indexPath)?.frame)")
            let height = collectionView.cellForItemAtIndexPath(indexPath)!.frame.origin.y - 20
            
            println("height = \(height)")
            
            UIView.animateWithDuration(0.3)
                {
                    self.channelsCollectionView.contentOffset = self.targetContentOffsetForProposedContentOffset(CGPoint(x: 0,y:height))
            }
            
            collectionView.performBatchUpdates(
                {
                    
                    
                    let channel = self.channels[indexPath.section];
                    channel.isExpanded = !channel.isExpanded
                    let targetIndexPaths = [NSIndexPath(forItem: 1, inSection: indexPath.section)];
                    
                    
                        if channel.isExpanded
                        {
                            self.indexPathsToListenFor[NSIndexPath(forItem: 1, inSection: indexPath.section)] = true
                            self.channelsCollectionView.scrollEnabled = false
                            collectionView.insertItemsAtIndexPaths(targetIndexPaths)
                        } else
                        {
                            self.channelsCollectionView.scrollEnabled = true
                            let inceptionCell = self.channelsCollectionView.cellForItemAtIndexPath(NSIndexPath(forItem: 1, inSection: indexPath.section)) as SWInceptionCell
                            inceptionCell.animateInceptionCell(expanded:false)
                            collectionView.deleteItemsAtIndexPaths(targetIndexPaths)
                        }
                    
                    
                }, completion:
                {(b:Bool) in
                    
                })
        }
        else
        {
            println("lol no expando")
        }
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
    
    
//    func scrollViewDidScroll(scrollView: UIScrollView!)
//    {
//        println("scrollView offset = \(scrollView.contentOffset.y)")
//    }
    
    
    
    
}