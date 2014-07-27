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
    
    let name: String
    //store url because I may want to modify this entity later
    let url:String
    

    let channelRoot:Firebase; //reference to the messages
    
    let messagesRoot:Firebase;
    var messages:Array<SWMessageModel> = [SWMessageModel]() //this model becomes the wall source for the interior UICollectionView for messages
    
    
    //collectionView
    var messageCollectionView:UICollectionView {
        get
        {
            return self.messageCollectionView
    }
        set
        {
            newValue.delegate = self
            newValue.dataSource = self
            newValue.reloadData()
            
                println("hey!!!")
            
//            self.messageCollectionView = newValue
    }
    }

    init(dictionary:NSDictionary, url:String)
    {
        self.url = url;
        self.name = url.componentsSeparatedByString("/").last as String
        
        self.channelRoot = Firebase(url: "\(kROOT_FIREBASE)channels/\(name)")
        self.messagesRoot = Firebase(url: "\(kROOT_FIREBASE)messages/\(name)")
        
        super.init()
        
        bindToWall()
        
    }
    
    func bindToWall()
    {
        messagesRoot.observeEventType(FEventTypeChildAdded, andPreviousSiblingNameWithBlock:
        {(snap:FDataSnapshot!, previous:String!) in
            println("snap.value = \(snap.value)")
            if let dictionary = snap.value as? Dictionary<String, AnyObject>
            {
                if let model = SWMessageModel.messageModelForDictionary(dictionary)
                {
                    self.messages += model
                }
            }
        })
    }
    
    
    
    deinit
    {
        
    }
    

    // MARK: UICollectionViewDelegate/DataSource protocol
    func collectionView(collectionView: UICollectionView!, cellForItemAtIndexPath indexPath: NSIndexPath!) -> UICollectionViewCell!
    {
        //TODO, fetch cells
        var cell = collectionView.dequeueReusableCellWithReuseIdentifier("Cellulare", forIndexPath: indexPath) as UICollectionViewCell
        cell.backgroundColor = UIColor(red: 1, green: 0, blue: 0, alpha: 0.6)
        return cell
    }
    
    func collectionView(collectionView: UICollectionView!, numberOfItemsInSection section: Int) -> Int
    {
        return messages.count
    }
    
    func numberOfSectionsInCollectionView(collectionView: UICollectionView!) -> Int
    {
        return 1
    }
    
    

    
}

