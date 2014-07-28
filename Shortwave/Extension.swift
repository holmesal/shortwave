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
    

//    func contains<T: Equatable>(obj:T) -> Bool
//    {
//        if let foundResult = find(self, obj) as Int
//        {
//            return true
//        }
//        return false
//    }
    
}