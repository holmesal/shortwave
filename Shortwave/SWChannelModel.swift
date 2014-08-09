//
//  ChannelModel.swift
//  Shortwave
//
//  Created by Ethan Sherr on 7/24/14.
//  Copyright (c) 2014 Ethan Sherr. All rights reserved.
//

import Foundation
import UIKit


protocol ChannelActivityIndicatorDelegate
{
    func channel(channel:SWChannelModel, receivedNewMessage:MessageModel?) -> ()
    func channelIsRead(channel:SWChannelModel)
}

@objc class SWChannelModel: NSObject, UICollectionViewDelegate//, UICollectionViewDataSource
{
    var isExpanded:Bool = false
    
    var name: String?
    //store url because I may want to modify this entity later
    var url:String?
    
    var lastSeen:Double = 0
    var muted:Bool = false
    
    var isSynchronized:Bool = true

    var channelRoot:Firebase? //reference to the messages
    
    var messagesRoot:Firebase?
    var messages:Array<MessageModel> = [MessageModel]() //this model becomes the wall source for the interior UICollectionView for messages
    
    var temporary:Bool = false
    var wallSource:WallSource!
    
    var delegate:ChannelActivityIndicatorDelegate?
    
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
    
    
//    func wallIsLoadedMessageWithLargestPriority(message:MessageModel!)
//    {
//        if largestLoadedPriority >= lastSeen
//        {
//            //hidden state
//            isSynchronized = true
//            delegate?.channelIsRead(self)
//        } else
//        {
//            isSynchronized = false
//            delegate?.channel(self, receivedNewMessage: message)
//        }
//    }
    
    
    func didLoadMessageModel(message:MessageModel!)
    {
        if message.priority > lastSeen
        {
            isSynchronized = false
            delegate?.channel(self, receivedNewMessage: message)
            
        } else
        {
//            if (isSynchronized != true)
//            {
//                isSynchronized = true
//                delegate?.channelIsRead(self)
//            }
        }
    }

    //selector called from WallSource to tell which message is dislpayed right now
    func messageViewed(message:MessageModel!)
    {
        let priority = message.priority
        
        println("priority = \(priority) > lastSeen = \(lastSeen) ? \(priority > lastSeen)")
        
        if priority > lastSeen
        {
            setPriorityEventually(priority)
        }
    }
    
    //prepare to synchronise 
    var lastPriorityToSet:Double!
    var setPriorityTimer:NSTimer?;
    func setPriorityEventually(priority:Double)
    {
        if let lastPriorityKnownToSet = lastPriorityToSet
        {
            if priority > lastPriorityKnownToSet
            {
                lastPriorityToSet = priority
            }
        } else
        {
            lastPriorityToSet = priority
        }
        
        if let theTimer = setPriorityTimer
        {
            theTimer.invalidate()
            setPriorityTimer = nil
        }
        
        setPriorityTimer = NSTimer(timeInterval: 0.3, target: self, selector: "setPriority", userInfo: nil, repeats: false)
        NSRunLoop.mainRunLoop().addTimer(setPriorityTimer, forMode: NSDefaultRunLoopMode)
        
    }
    
    
    //sets the priority locally (called by timer) and updates firebase
    func setPriority()
    {
        self.lastSeen = lastPriorityToSet
        
        lastPriorityToSet = nil;
        setPriorityTimer!.invalidate()
        setPriorityTimer = nil;
        
        lastPriorityToSet = nil
        let myId = (NSUserDefaults.standardUserDefaults().objectForKey(kNSUSERDEFAULTS_KEY_userId) as String)
        
        isSynchronized = true
        delegate?.channelIsRead(self)
        
        var setLastSeenFB = Firebase(url: kROOT_FIREBASE + "users/" + myId + "/channels/" + name! + "/lastSeen")
        setLastSeenFB.setValue(self.lastSeen)
        println("setLastSeenFB = \(setLastSeenFB)")
    }
    

    init(dictionary:NSDictionary, url:String)
    {
        if let actualLastSeen = dictionary["lastSeen"] as? Double
        {
            lastSeen = actualLastSeen
        }
        
        muted = dictionary["muted"] as Bool
        
        super.init()
        
        initialize(dictionary: dictionary, andUrl: url)
        let url = "\(kROOT_FIREBASE)messages/\(self.name!)/"
        
        wallSource = WallSource(url: url)
        wallSource.target = self
        
        let myId = (NSUserDefaults.standardUserDefaults().objectForKey(kNSUSERDEFAULTS_KEY_userId) as String)
        var setLastSeenFB:Firebase = Firebase(url: kROOT_FIREBASE + "users/" + myId + "/channels/" + name! + "/lastSeen")
        
        setLastSeenFB.observeEventType(FEventTypeValue, withBlock:
            {(snap:FDataSnapshot!) in
                
            if let newLastSeen = snap.value as? Double
            {
                println("newLastSeen = \(newLastSeen) and current lastSeen = \(self.lastSeen)")
                
                if self.lastSeen != newLastSeen
                {
                    println("update lastSeen, possibly update activity indicator!")
                    self.lastSeen = newLastSeen
                    
                    self.isSynchronized = false
                    self.delegate?.channel(self, receivedNewMessage: nil)
                    
                }
                
            }
                
        })
        
    }
    

    
    func initialize(#dictionary:NSDictionary, andUrl url:String)
    {
        self.url = url;
        self.name = url.componentsSeparatedByString("/").last as String
        
        self.channelRoot = Firebase(url: "\(kROOT_FIREBASE)channels/\(name!)")
        self.messagesRoot = Firebase(url: "\(kROOT_FIREBASE)messages/\(name!)")
        
    }
    

    
    
    
    deinit
    {
        
    }
    


}

