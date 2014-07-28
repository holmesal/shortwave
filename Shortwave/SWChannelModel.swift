//
//  ChannelModel.swift
//  Shortwave
//
//  Created by Ethan Sherr on 7/24/14.
//  Copyright (c) 2014 Ethan Sherr. All rights reserved.
//

import Foundation
import UIKit


class SWChannelModel: NSObject, UICollectionViewDelegate, UICollectionViewDataSource
{
    var isExpanded:Bool = false
    
    var name: String?
    //store url because I may want to modify this entity later
    var url:String?
    

    var channelRoot:Firebase? //reference to the messages
    
    var messagesRoot:Firebase?
    var messages:Array<SWMessageModel> = [SWMessageModel]() //this model becomes the wall source for the interior UICollectionView for messages
    
    var temporary:Bool = false
    //collectionView
    var messageCollectionView:UICollectionView? {
    
        didSet
        {
            messageCollectionView!.delegate = self
            messageCollectionView!.dataSource = self
            messageCollectionView!.reloadData()
        }
    }
    
    init(temporary:Bool)
    {
        self.temporary = temporary
        super.init()
    }

    init(dictionary:NSDictionary, url:String)
    {
        super.init()
     
        initialize(dictionary: dictionary, andUrl: url)
        bindToWall()
    }
    
    func initialize(#dictionary:NSDictionary, andUrl url:String)
    {
        self.url = url;
        self.name = url.componentsSeparatedByString("/").last as String
        
        self.channelRoot = Firebase(url: "\(kROOT_FIREBASE)channels/\(name!)")
        self.messagesRoot = Firebase(url: "\(kROOT_FIREBASE)messages/\(name!)")
        println("\(kROOT_FIREBASE)messages/\(name!)")
    }
    
    func bindToWall()
    {
        messagesRoot!.observeEventType(FEventTypeChildAdded, andPreviousSiblingNameWithBlock:
        {(snap:FDataSnapshot!, previous:String!) in
//            println("snap.value = \(snap.value)")
            if let dictionary = snap.value as? Dictionary<String, AnyObject>
            {
                if let model = SWMessageModel.messageModelForDictionary(dictionary)
                {
                    self.insertChannel(model, atIndex: self.messages.count)
                }
            }
        })
    }
    
    
    func insertChannel(channel: SWMessageModel, atIndex i:Int)
    {

        if let collectionView = messageCollectionView?
        {
            collectionView.performBatchUpdates(
                {
                    
                    self.messages.insert(channel, atIndex: i)
                    collectionView.insertItemsAtIndexPaths([NSIndexPath(forItem: i, inSection: 0)])
                    
                }, completion:
                {(b:Bool) in
                    
                })
        } else
        {
            messages.insert(channel, atIndex:i)
        }
    }
    
    
    
    deinit
    {
        
    }
    

    // MARK: UICollectionViewDelegate/DataSource protocol
    func collectionView(collectionView: UICollectionView!, cellForItemAtIndexPath indexPath: NSIndexPath!) -> UICollectionViewCell!
    {
        //TODO, fetch cells
        println("index = \(indexPath.item)" )
        var cell = collectionView.dequeueReusableCellWithReuseIdentifier("Cellulare", forIndexPath: indexPath) as UICollectionViewCell
        cell.backgroundColor = indexPath.item%2 == 0 ? UIColor(red: 1, green: 0, blue: 0, alpha: 0.6) : UIColor(red: 1, green: 0, blue: 0, alpha: 1.0)
        
        
        let messageModel = messages[indexPath.row]
        var label = cell.viewWithTag(5) as? UILabel
        label!.text = messageModel.text!
        
        
        return cell
    }
    
    func collectionView(collectionView: UICollectionView!, numberOfItemsInSection section: Int) -> Int
    {
        let count = messages.count;
        println("number of messages = \(count)")
        return messages.count
    }
    
    func numberOfSectionsInCollectionView(collectionView: UICollectionView!) -> Int
    {
        return 1
    }
    
    
    func collectionView(collectionView: UICollectionView!, didSelectItemAtIndexPath indexPath: NSIndexPath!)
    {
        println("selected \(indexPath)")
    }

    func collectionView(collectionView: UICollectionView!, layout collectionViewLayout: UICollectionViewLayout!, sizeForItemAtIndexPath indexPath: NSIndexPath!) -> CGSize
    {
        return CGSizeMake(320, 52)
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
}

