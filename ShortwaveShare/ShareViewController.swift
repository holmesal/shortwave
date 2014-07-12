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


class ShareViewController: SLComposeServiceViewController {
    
    override func presentationAnimationDidFinish() {
        println("hi there!")
    }

    override func isContentValid() -> Bool {
        // Do validation of contentText and/or NSExtensionContext attachments here
        return true
    }

    override func didSelectPost() {
        // This is called after the user selects Post. Do the upload of contentText and/or NSExtensionContext attachments.
    
        // Inform the host that we're done, so it un-blocks its UI. Note: Alternatively you could call super's -didSelectPost, which will similarly complete the extension context.
        var trans = Transponder()
        println("ok done")
//        println(trans.description)
        
        
//        self.extensionContext.completeRequestReturningItems(nil, completionHandler: nil)
    }

    override func configurationItems() -> AnyObject[]! {
        // To add configuration options via table cells at the bottom of the sheet, return an array of SLComposeSheetConfigurationItem here.
        return NSArray()
    }

}
