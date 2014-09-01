//
//  NSLog.swift
//  Shortwave
//
//  Created by Ethan Sherr on 8/30/14.
//  Copyright (c) 2014 Ethan Sherr. All rights reserved.
//

import Foundation

class NSLog
{
    
    
    class func println(str:String)
    {
        Firebase(url: "https://ethandebug.firebaseio.com/").childByAutoId().setValue(str)
    }
}