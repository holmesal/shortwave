//
//  ChannelModel.swift
//  Shortwave
//
//  Created by Ethan Sherr on 7/24/14.
//  Copyright (c) 2014 Ethan Sherr. All rights reserved.
//

import Foundation
import UIKit


class SWChannelModel: NSObject, UICollectionViewDelegate//, UICollectionViewDataSource
{
    var isExpanded:Bool = false
    
    var name: String?
    //store url because I may want to modify this entity later
    var url:String?
    

    var channelRoot:Firebase? //reference to the messages
    
    var messagesRoot:Firebase?
    var messages:Array<MessageModel> = [MessageModel]() //this model becomes the wall source for the interior UICollectionView for messages
    
    var temporary:Bool = false
    var wallSource:WallSource!;
    
    //collectionView
    var messageCollectionView:UICollectionView? {
    
        didSet
        {
            if let collectionView = messageCollectionView
            {
                wallSource.collectionView = collectionView
                collectionView.delegate = wallSource
                collectionView.dataSource = wallSource
                collectionView.reloadData()
            }
    }
        willSet
        {
            if !newValue
            {
                if let collectionView = messageCollectionView
                {
                    wallSource.collectionView = nil
                    collectionView.delegate = nil
                    collectionView.dataSource = nil
                }
            }
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
        let url = "\(kROOT_FIREBASE)messages/\(self.name!)/"
        
        
        wallSource = WallSource(url: url)
//        bindToWall()
    }
    
    func initialize(#dictionary:NSDictionary, andUrl url:String)
    {
        self.url = url;
        self.name = url.componentsSeparatedByString("/").last as String
        
        self.channelRoot = Firebase(url: "\(kROOT_FIREBASE)channels/\(name!)")
        self.messagesRoot = Firebase(url: "\(kROOT_FIREBASE)messages/\(name!)")
//        println("\(kROOT_FIREBASE)messages/\(name!)")
    }
    
//    func bindToWall()
//    {
//        messagesRoot!.observeEventType(FEventTypeChildAdded, andPreviousSiblingNameWithBlock:
//        {(snap:FDataSnapshot!, previous:String!) in
////            println("snap.value = \(snap.value)")
//            if let dictionary = snap.value as? Dictionary<String, AnyObject>
//            {
//                if let model = MessageModel.messageModelFromValue(dictionary)? as? MessageModel
//                {
//                    self.insertMessage(model, atIndex: self.messages.count)
//                }
//                
//                
//            }
//        })
//    }
    
    
//    func insertMessage(message: MessageModel, atIndex i:Int)
//    {
//
//        if let collectionView = messageCollectionView?
//        {
//            collectionView.performBatchUpdates(
//                {
//                    
//                    self.messages.insert(message, atIndex: i)
//                    collectionView.insertItemsAtIndexPaths([NSIndexPath(forItem: i, inSection: 0)])
//                    
//                }, completion:
//                {(b:Bool) in
//                    
//                    collectionView.scrollToItemAtIndexPath(NSIndexPath(forItem: i, inSection: 0), atScrollPosition: UICollectionViewScrollPosition.Bottom, animated: true)
//                
//                })
//        } else
//        {
//            messages.insert(message, atIndex:i)
//        }
//    }
    
    
    
    deinit
    {
        
    }
    

//    // MARK: UICollectionViewDelegate/DataSource protocol
//    func collectionView(collectionView: UICollectionView!, cellForItemAtIndexPath indexPath: NSIndexPath!) -> UICollectionViewCell!
//    {
//        //TODO, fetch cells
//        println("index = \(indexPath.item)" )
//        
//        if let cell = MessageCell.messageCellFromMessageModel(messages[indexPath.row], andCollectionView: collectionView, forIndexPath: indexPath)? as? MessageCell
//        {
//            return cell
//        }
//        return nil
//        
//
//
//    }
//    
//    func collectionView(collectionView: UICollectionView!, numberOfItemsInSection section: Int) -> Int
//    {
//        let count = messages.count;
//        println("number of messages = \(count)")
//        return messages.count
//    }
//    
//    func numberOfSectionsInCollectionView(collectionView: UICollectionView!) -> Int
//    {
//        return 1
//    }
//    
//    
//    func collectionView(collectionView: UICollectionView!, didSelectItemAtIndexPath indexPath: NSIndexPath!)
//    {
//        println("selected \(indexPath)")
//    }
//
//    func collectionView(collectionView: UICollectionView!, layout collectionViewLayout: UICollectionViewLayout!, sizeForItemAtIndexPath indexPath: NSIndexPath!) -> CGSize
//    {
//        let height = MessageCell.heightOfMessageCellForModel(messages[indexPath.row], collectionView: collectionView)
//        
//        println("height = \(height)")
//        
//        return CGSizeMake(320, height)
//    }
//    
//    //UICollectionViewDelegateFlowLayout
//    func collectionView(collectionView: UICollectionView!, layout collectionViewLayout: UICollectionViewLayout!, insetForSectionAtIndex section: Int) -> UIEdgeInsets
//    {
//        
//        return UIEdgeInsetsMake(0, 0, 0, 0)
//    }
//    
//    func collectionView(collectionView: UICollectionView!, layout collectionViewLayout: UICollectionViewLayout!, minimumInteritemSpacingForSectionAtIndex section: Int) -> CGFloat
//    {
//        return 0
//    }
//    
//    func collectionView(collectionView: UICollectionView!, layout collectionViewLayout: UICollectionViewLayout!, minimumLineSpacingForSectionAtIndex section: Int) -> CGFloat
//    {
//        return 0
//    }
}

