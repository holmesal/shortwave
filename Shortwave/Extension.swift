//
//  Extension.swift
//  Shortwave
//
//  Created by Ethan Sherr on 7/25/14.
//  Copyright (c) 2014 Ethan Sherr. All rights reserved.
//

import Foundation

extension Array
    {
        var last: T {
        return self[self.endIndex - 1]
    }
    
    
    
    
//    func giveDictionary(jsonResult:NSDictionary) -> String?
//    {
//    
//        if let x = (jsonResult["key_1"]? as? NSDictionary)
//        {
//            if let y = (x["key_2"]? as? NSString)
//            {
//                return y
//            }
//        }
//        return nil
//    }
    
    
    }
//    private func getData(url: NSURL) {
//        let config: NSURLSessionConfiguration = NSURLSessionConfiguration.defaultSessionConfiguration()
//        let session: NSURLSession = NSURLSession(configuration: config)
//        
//        let dataTask: NSURLSessionDataTask = NSURLSession.sharedSession().dataTaskWithURL(url, completionHandler: {(data: NSData!, urlResponse: NSURLResponse!, error: NSError!) -> Void in
//            
//            if let httpUrlResponse = urlResponse as? NSHTTPURLResponse
//            {
//                if error {
//                    println("Error Occurred: \(error.localizedDescription)")
//                } else {
//                    println("\(httpUrlResponse.allHeaderFields)") // Error
//                }
//            }
//            })
//        
//        dataTask.resume()
//    }

//    func contains<T: Equatable>(obj:T) -> Bool
//    {
//        if let foundResult = find(self, obj) as Int
//        {
//            return true
//        }
//        return false
//    }
 