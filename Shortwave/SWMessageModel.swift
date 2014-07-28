//
//  SWMessageModel.swift
//  Shortwave
//
//  Created by Ethan Sherr on 7/25/14.
//  Copyright (c) 2014 Ethan Sherr. All rights reserved.
//

import Foundation

class SWMessageModel
{
    class func messageModelForDictionary(msg:[String: AnyObject] ) -> SWMessageModel?
    {
        if let type = msg["type"]! as? String
        {
            switch type
            {
                case "text":
                    println("messageModelFor \(msg) is 'text'")
                    return SWMessageModel(dict:msg)
                
                case "image":
                    break;
                
                case "gif":
                    break;
                
                
                
            default:
                println("messageModelFor \(msg) is nil")
               return nil
            }
        
        }
        return nil
    }
    
    
    let userID:String?
    let text:String?
    let type = "text"
    
    var isValid:Bool
    
    init(dict:[String: AnyObject])
    {
        
        userID = dict["owner"] as? NSString
        
        let contentObj: AnyObject? = dict["content"]
        if contentObj?
        {
            if let content = contentObj as Dictionary<String, AnyObject>?
            {
                text = content["text"] as? NSString
            }
        }
        
        isValid = userID? && text?
    }
    
    init(userID:String, text:String)
    {
        self.userID = userID
        self.text = text
        isValid = true
    }

    func sendMessageToChannel(channel:String)
    {
        let priority:Double = NSDate().timeIntervalSince1970 * 1000
        
        let val =
        [
            "type": type,
            "content": self.getContentDictionary(),
            "owner":userID!,
            "raw":text!,
            "parsed":false
        ]
        
        println("sending val = \(val)")

        let messagesChannel = Firebase(url: "\(kROOT_FIREBASE)messages/\(channel)").childByAutoId()
        println("messagesChannel \(messagesChannel)")
        
        messagesChannel.setValue(val, andPriority: priority, withCompletionBlock:
                {(error:NSError!, firebase:Firebase!) in
                    println("omgomgomg error \(error) firebase \(firebase)")
                })
        

    }
    
    func getContentDictionary() -> NSDictionary
    {
        return ["text": text!]
    }
    
}