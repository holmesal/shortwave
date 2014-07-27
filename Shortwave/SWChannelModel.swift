//
//  ChannelModel.swift
//  Shortwave
//
//  Created by Ethan Sherr on 7/24/14.
//  Copyright (c) 2014 Ethan Sherr. All rights reserved.
//

import Foundation

class SWChannelModel
{
    var isExpanded:Bool = false
    
    let name: String
    //store url because I may want to modify this entity later
    let url:String
    

    let channelRoot:Firebase; //reference to the messages
    
    let messagesRoot:Firebase;
    var messages:Array<SWMessageModel> = [SWMessageModel]() //this model becomes the wall source for the interior UICollectionView for messages

    init(dictionary:NSDictionary, url:String)
    {
        self.url = url;
        self.name = url.componentsSeparatedByString("/").last as String
        
        self.channelRoot = Firebase(url: "\(kROOT_FIREBASE)channels/\(name)")
        println("self.messagesRef = \(self.channelRoot)")
        
        self.messagesRoot = channelRoot.childByAppendingPath("messages/\(name)")
        bindToWall()
        println("self.messagesRoot = \(self.messagesRoot)")
    }
    
    func bindToWall()
    {
        messagesRoot.observeEventType(FEventTypeChildAdded, andPreviousSiblingNameWithBlock:
            {(snap:FDataSnapshot!, previous:String!) in
                println("snap.value = \(snap.value)")
            })
    }
    

    deinit
    {
        
    }
    
}

