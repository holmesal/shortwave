//
//  SWImageLoader.swift
//  Shortwave
//
//  Created by Ethan Sherr on 7/29/14.
//  Copyright (c) 2014 Ethan Sherr. All rights reserved.
//

import Foundation
import UIKit


private class DiscardableImage: NSDiscardableContent
{
    private var image:UIImage?
    private var contentHasBeenAccessed = false
    
    init(image:UIImage)
    {
        self.image = image
    }
    
    func getImage() -> UIImage?
    {
        contentHasBeenAccessed = true
        return image
    }
    
    func beginContentAccess() -> Bool
    {
        return contentHasBeenAccessed && (image != nil)
    }
    
    func endContentAccess()
    {
        //i don't get this fucking shit
    }
    
    func discardContentIfPossible()
    {
        image = nil
    }
    
    func isContentDiscarded() -> Bool
    {
        return (image == nil)
    }
    
}

enum DataLoadingParcelState
{
    case Unstarted
    case Downloading
    case Failed
//    case Paused
    case Complete
}

@objc class DataLoadingParcel: NSObject
{
    private class EventDispatcher
    {
        var completion:(() -> ())? = nil
        var progress:(() -> ())? = nil
        
        init(completion:(() -> ())?, progress:(() -> ())?)
        {
            self.completion = completion
            self.progress = progress
        }
    }
    
    let url:NSURL
    var percent:Float = 0.0
    var state:DataLoadingParcelState = .Unstarted
    private var dispatchers = [EventDispatcher]()
    

    init(url:NSURL)
    {
        self.url = url
        super.init()
        
        initializeRequest() //setups request fresh
        
    }
    
    func initializeRequest()
    {
        request = ASIHTTPRequest(URL: url)
        request.downloadProgressDelegate = self
        
        request.numberOfTimesToRetryOnTimeout = 2
        request.didFinishSelector = Selector("requestFinished:")
        request.didFailSelector = Selector("requestFailed:")
        
        request.delegate = self
    }
    
    var request:ASIHTTPRequest!
    var receivedData:NSData?
    
//    var error:NSError? //UNUSED FOR NOW!
    func addListeners(#completion:(() -> ())?, progress:(() -> ())?)
    {
        dispatchers.append(EventDispatcher(completion: completion, progress: progress))
    }
    
    func start()
    {
        switch state
        {
            case .Unstarted:
                
                state = .Downloading
                beginLoading()
            
            default:
                
                println("Download's state for \(state) is invalid to call load on. url: \(url)")
                break

        }
    }
    
    func beginLoading()
    {
        
        request.startAsynchronous()
        //by here state is .Downloading
    }
    
    func requestFinished(request:ASIHTTPRequest!)
    {
        state = .Complete
        receivedData = request.responseData()
        
        //completion reporting
        for event in dispatchers
        {
            if let completion = event.completion
            {
                completion()
            }
        }
        
        dispatchers = []

    }
    
    func requestFailed(request:ASIHTTPRequest!)
    {
        println("request failed, \(request)")
        
        state = .Unstarted
        //just auto repeat requests that fail for now.
        initializeRequest()
    }
 
    
    //work
    func setProgress(progress:Float)
    {
        self.percent = progress
        //progress reporting
        for event in dispatchers
        {
            if let progress = event.progress
            {
                progress()
            }
        }
    }
    
}


@objc class SWImageLoader
{
    let NUM_CONCURRENT = 5
    let cache:NSCache = NSCache()
    private var dataLoadingParcels:Dictionary<String, DataLoadingParcel> = [String: DataLoadingParcel]()
    private var dataLoadingParcelOrder:Array<DataLoadingParcel> = [DataLoadingParcel]()
    
    func loadImage(urlString:String, completionBlock:((image:UIImage, synchronous:Bool) -> ()), progressBlock:((progress:Float) -> ()) )
    {
        if let discardableImage = cache.objectForKey(urlString) as? DiscardableImage
        {
            completionBlock(image: discardableImage.image! , synchronous: true)
        } else
        {
            //does it already exist for this one?
            if let dataLoadingParcel = dataLoadingParcels[urlString]
            {
                dataLoadingParcel.addListeners(
                    completion: completionBlockForParcel(dataLoadingParcel, completionBlock:completionBlock),
                    progress: progressBlockForParcel(dataLoadingParcel, progressBlock:progressBlock))
            } else
            {
                let dataLoadingParcel = DataLoadingParcel(url: NSURL(string: urlString))
                dataLoadingParcel.addListeners(
                    completion: completionBlockForParcel(dataLoadingParcel, completionBlock:completionBlock),
                    progress: progressBlockForParcel(dataLoadingParcel, progressBlock:progressBlock))
                
                if dataLoadingParcelOrder.count <= NUM_CONCURRENT
                {
                    dataLoadingParcel.start()
                }
                
                dataLoadingParcels[urlString] = dataLoadingParcel
                dataLoadingParcelOrder.append(dataLoadingParcel)
                
            }
        }
    }
    
    private func completionBlockForParcel(parcel:DataLoadingParcel, completionBlock:((image:UIImage, synchronous:Bool) -> ())) -> (() -> ())
    {
        return {
            //parcel is nil? dont know what behavior is.
            
            
            if let data = parcel.receivedData
            {
                let image = UIImage(data: parcel.receivedData)
                //store DiscardableImage
                let discardableImage = DiscardableImage(image: image)
                let key = parcel.url.absoluteString
                
//                println("discardabieLimage = \(discardableImage) key \(key)")
                self.cache.setObject(discardableImage, forKey: key)
                
                if self.dataLoadingParcelOrder.count > self.NUM_CONCURRENT
                {
                    let dlp = self.dataLoadingParcelOrder[self.NUM_CONCURRENT]
                    dlp.start()
                }
                
                self.dataLoadingParcels[key] = nil
                //at this point, what the fuck? um, i mean.... removeObject? that function doesn't work in swift.  ssoooooo.  what the fuck.
                if let index = find(self.dataLoadingParcelOrder, parcel)
                {
                    self.dataLoadingParcelOrder.removeAtIndex(index)
                }
                
                completionBlock(image: image, synchronous: false)
            }
        }
    }
    
    private func progressBlockForParcel(parcel:DataLoadingParcel, progressBlock:((progress:Float) -> ())) -> (() -> ())
    {
        return {
            progressBlock(progress: parcel.percent)
        }
    }

    
    internal func hasImage(urlString:String) -> Bool
    {
        if let discardableContent = cache.objectForKey(urlString) as? DiscardableImage
        {
            if let img = discardableContent.getImage()
            {
                return true
            }
        }
        return false
    }
    
}

