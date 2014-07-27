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
                    return SWMessageModel()
                
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
}