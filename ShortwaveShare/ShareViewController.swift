//
//  ShareViewController.swift
//  ShortwaveShare
//
//  Created by Alonso Holmes on 7/11/14.
//  Copyright (c) 2014 Buildco. All rights reserved.
//

import UIKit
import Social
import ShortwaveiOSFramework


class ShareViewController : UIViewController {
    
    @IBOutlet var imgView : UIImageView
    
    @IBOutlet var fake : UIImageView
    override func viewDidLoad(){
        NSLog("view loaded!")
        NSLog("%@",extensionContext.inputItems)
//        let items: NSArray = extensionContext.inputItems
//        NSLog("%@", items)
//        NSLog("%@", items.objectAtIndex(0).description)
//        let items: AnyObject[] = extensionContext.inputItems
//        for item : AnyObject in items{
//            NSLog("%@", item.description)
//        }
        println("does this work?")
        let fakeToolbar = UIToolbar(frame: view.bounds)
        fakeToolbar.autoresizingMask = view.autoresizingMask
        view.insertSubview(fakeToolbar, atIndex: 0)
    }
    
    override func viewWillAppear(animated: Bool) {
        view.alpha = 0
        fake.alpha = 0
    }
    
    override func viewDidAppear(animated: Bool) {
//        UIView.animateWithDuration(0.3, animations: {
//            self.view.alpha = 1
//        })
        UIView.animateWithDuration(0.5,
            delay: 0,
            usingSpringWithDamping: 0.8,
            initialSpringVelocity: 0,
            options: nil,
            animations: {
                self.view.alpha = 1
            },
            completion: nil)
        
        UIView.animateWithDuration(0.3,
            delay: 0.3,
            usingSpringWithDamping: 1.0,
            initialSpringVelocity: 0,
            options: nil,
            animations: {
                self.fake.alpha = 1
            },
            completion: nil)
    }
    
//    override func viewDidAppear(animated: Bool) {
//
////        let cont: CGContextRef = UIGraphicsGetCurrentContext()
//        UIGraphicsBeginImageContextWithOptions(UIScreen.mainScreen().bounds.size, false, UIScreen.mainScreen().scale)
//        self.view.drawViewHierarchyInRect(self.imgView.bounds, afterScreenUpdates: false)
//        let img: UIImage = UIGraphicsGetImageFromCurrentImageContext()
//        imgView.image = img
//        
//        imgView.backgroundColor = UIColor.redColor()
//        imgView.alpha = 0.8
//        
//        UIGraphicsEndImageContext()
//    }
    
}


//class ShareViewController: SLComposeServiceViewController {
//    
//    override func presentationAnimationDidFinish() {
//        println("hi there!")
//    }
//
//    override func isContentValid() -> Bool {
//        // Do validation of contentText and/or NSExtensionContext attachments here
//        return true
//    }
//
//    override func didSelectPost() {
//        // This is called after the user selects Post. Do the upload of contentText and/or NSExtensionContext attachments.
//    
//        // Inform the host that we're done, so it un-blocks its UI. Note: Alternatively you could call super's -didSelectPost, which will similarly complete the extension context.
//        var trans = Transponder()
//        println("ok done")
////        println(trans.description)
//        
//        
////        self.extensionContext.completeRequestReturningItems(nil, completionHandler: nil)
//    }
//
//    override func configurationItems() -> AnyObject[]! {
//        // To add configuration options via table cells at the bottom of the sheet, return an array of SLComposeSheetConfigurationItem here.
//        return NSArray()
//    }
//
//}
