//
//  ChannelModel.swift
//  Shortwave
//
//  Created by Ethan Sherr on 7/24/14.
//  Copyright (c) 2014 Ethan Sherr. All rights reserved.
//

import Foundation
import UIKit

protocol ChannelMutedResponderDelegate
{
    func channel(channel:SWChannelModel, isMuted:Bool)
}

protocol ChannelActivityIndicatorDelegate
{
//    func channel(channel:SWChannelModel, receivedNewMessage:MessageModel?) -> ()
    func channel(channel:SWChannelModel, hasNewActivity:Bool)
    
}

protocol ChannelCellActionDelegate
{
    func didLongPress(longPress:UILongPressGestureRecognizer)
}



@objc class SWChannelModel: NSObject, UICollectionViewDelegate//, UICollectionViewDataSource
{
    var isExpanded:Bool = false
    var scrollViewDelegate:UIScrollViewDelegate?
    
    var name: String?
    //store url because I may want to modify this entity later
    var url:String?
    
    var lastSeen:Double = 0
    

    
    let mutedFirebase:Firebase!;
//    let mutedFirebaseChangeHandle:FirebaseHandle
    let mutedUrl:String!;
    
    
    func setMutedToFirebase()
    {
        mutedFirebase.setValue(NSNumber(bool: muted))
    }
    var muted:Bool {
        didSet
        {
            mutedDelegate?.channel(self, isMuted: muted)
            
            
        }
    }
    
    var isSynchronized:Bool = true

    var channelRoot:Firebase? //reference to the messages
    
    var messagesRoot:Firebase?
    var messages:Array<MessageModel> = [MessageModel]() //this model becomes the wall source for the interior UICollectionView for messages
    
    var temporary:Bool = false
    var wallSource:WallSource!
    
    var delegate:ChannelActivityIndicatorDelegate?
    var mutedDelegate:ChannelMutedResponderDelegate?
    var cellActionDelegate:ChannelCellActionDelegate?
    
    var channelDescription:String?
    
    var members:Array<String> = [String]()
    
    
    //collectionView
    var messageCollectionView:UICollectionView? {
    
        didSet
        {
            if let collectionView = messageCollectionView
            {
                lastPriorityToSet = NSDate().timeIntervalSince1970*1000
                self.setPriority()
                
                wallSource.collectionView = collectionView
                collectionView.delegate = wallSource
                collectionView.dataSource = wallSource
                collectionView.reloadData()
            }
    }
        willSet
        {
            if newValue == nil
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
    
    
    //selector called from WallSource, triggers ACTIVITY display
    func didLoadMessageModel(message:MessageModel!)
    {
        
        if message.priority > lastSeen
        {

//            println("message.priority > lastSeen : \(message.priority > lastSeen) \n\(message.priority) \n\(lastSeen) !")
//            println("message.text = \(message.text)")
            
            isSynchronized = false
            delegate?.channel(self, hasNewActivity: !isSynchronized)
        }
    }

    //selector called from WallSource to tell which message is dislpayed right now, triggers NO ACTIVITY display
    func didViewMessageModel(message:MessageModel!)
    {
        let priority = message.priority

        if priority >= lastSeen && priority > lastPriorityToSet
        {
            lastPriorityToSet = priority
            setPriorityEventually(priority) //unless usurped by a newer message!
        }
    }
    
//    //prepare to synchronise 
    var lastPriorityToSet:Double = 0
    var setPriorityTimer:NSTimer?;
    func setPriorityEventually(priority:Double)
    {
        
        if let theTimer = setPriorityTimer
        {
            theTimer.invalidate()
            setPriorityTimer = nil
        }
        
        setPriorityTimer = NSTimer(timeInterval: 0.3, target: self, selector: "setPriority", userInfo: nil, repeats: false)
        NSRunLoop.mainRunLoop().addTimer(setPriorityTimer, forMode: NSDefaultRunLoopMode)
        
    }
    
    //called right after sending a message yourself.
    func setPriorityToNow()
    {//idk
        let myId = (NSUserDefaults.standardUserDefaults().objectForKey(kNSUSERDEFAULTS_KEY_userId) as String)
        isSynchronized = true
        delegate?.channel(self, hasNewActivity:!isSynchronized)
        var setLastSeenFB = Firebase(url: kROOT_FIREBASE + "users/" + myId + "/channels/" + name! + "/lastSeen")
        setLastSeenFB.setValue([".sv": "timestamp" ])
    }
    //sets the priority locally (called by timer only) and updates firebase
    func setPriority()
    {
        self.lastSeen = lastPriorityToSet
        
        let myId = (NSUserDefaults.standardUserDefaults().objectForKey(kNSUSERDEFAULTS_KEY_userId) as String)
        
        isSynchronized = true
        
        //if the timer is setting priority, that means that lastSeen < priority 
        delegate?.channel(self, hasNewActivity:!isSynchronized)
        
        var setLastSeenFB = Firebase(url: kROOT_FIREBASE + "users/" + myId + "/channels/" + name! + "/lastSeen")
        setLastSeenFB.setValue(self.lastSeen)
        println("lastSeen set to \(self.lastSeen)")
        
    }
    

    init(dictionary:NSDictionary, url:String, andChannelMeta meta:NSDictionary)
    {
        if let actualLastSeen = dictionary["lastSeen"] as? Double
        {
            lastSeen = actualLastSeen
        }
        
        if let description = meta["description"] as? String
        {
            self.channelDescription = description
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
                
                if self.lastSeen != newLastSeen
                {
                    self.lastSeen = newLastSeen
                    
                    self.isSynchronized = false
//                    self.delegate?.channel(self, receivedNewMessage: nil)
                    
                }
                
            }
                
        })
        
        let userId = NSUserDefaults.standardUserDefaults().objectForKey(kNSUSERDEFAULTS_KEY_userId) as String
        mutedUrl = kROOT_FIREBASE + "users/" + userId + "/channels/" + name! + "/muted/"
        mutedFirebase = Firebase(url: mutedUrl)
        
        //mutedFirebaseChangeHandle =
        mutedFirebase.observeEventType(FEventTypeValue, withBlock:
            {(snap:FDataSnapshot!) in
                
                if let isMuted = snap.value as? Bool
                {
                    if isMuted != self.muted
                    {
                        self.muted = isMuted
                    }
                }
            })
        
        
//        bindToMembers()
    }
    
    func bindToMembers()
    {
        let fb = Firebase(url: kROOT_FIREBASE + "channels/" + self.name! + "/members")
        fb.observeEventType(FEventTypeChildAdded, withBlock: {(snapshot:FDataSnapshot!)
            in
            
            if let string = snapshot.value as? String
            {
                self.members.append(string)
            }
            
        })
        
        fb.observeEventType(FEventTypeChildRemoved, withBlock: {(snapshot:FDataSnapshot!)
            in
        
            if let string = snapshot.value as? String
            {
                self.members = self.members.filter({$0 != string})
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
//        mutedFirebase.begin
    }
    
    func scrollViewWillBeginDragging(scrollView: UIScrollView!)
    {
        if let svD = scrollViewDelegate
        {
            svD.scrollViewWillBeginDragging?(scrollView)
        }
    }
    
    func didLongPress(longPressGesture:UILongPressGestureRecognizer)
    {
        self.cellActionDelegate?.didLongPress(longPressGesture)
    }
    

    //called after auth plz
    class func joinChannel(channelName:String, completion:(error:NSError?)->() )
    {
        let userId = NSUserDefaults.standardUserDefaults().objectForKey(kNSUSERDEFAULTS_KEY_userId) as String
        
        //1 set myself as a moderator
        let membersFB = Firebase(url: "\(kROOT_FIREBASE)channels/\(channelName)/members/\(userId)")
        //        println("moderatorsFB \(moderatorsFB)")
        
        membersFB.setValue(true, withCompletionBlock:
            {(error:NSError!, firebase:Firebase!) in
                if (error != nil)
                {
                    println("error adding myself to a channel (\(channelName)) \(error)")
                    completion(error: error)
                } else
                {
                    //continue joining it by adding to my users/userID/channels
                    let myChannels = Firebase(url: "\(kROOT_FIREBASE)users/\(userId)/channels/\(channelName)")
                    myChannels.setValue(["lastSeen":0, "muted":NSNumber(bool: false)], andPriority: NSDate().timeIntervalSince1970*1000, withCompletionBlock:
                        {(error:NSError!, firebase:Firebase!) in
                            if (error != nil)
                            {
                                completion(error: error)
                                println("error getting my user to join channel \(error)")
                            } else
                            {
                                completion(error: nil)
                            }
                        })
                }
            })
    }
    

}

