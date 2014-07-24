//
//  SWAuthViewController.swift
//  Shortwave
//
//  Created by Ethan Sherr on 7/24/14.
//  Copyright (c) 2014 Ethan Sherr. All rights reserved.
//

import Foundation
import UIKit

class SWAuthViewController: UIViewController
{
    @IBOutlet var authButton: UIButton
    
    override func viewDidLoad()
    {
        super.viewDidLoad()
        
        //if i'm already logged in just push ahead
        if NSUserDefaults.standardUserDefaults().boolForKey("UserIsAuthed")
        {
            var viewControllers:Array<UIViewController> = self.navigationController.viewControllers as Array<UIViewController>
            var channelViewController:UIViewController = self.storyboard.instantiateViewControllerWithIdentifier("SWChannelViewController") as UIViewController
            viewControllers += channelViewController;
        }
    }
    
    
    @IBAction func authButtonPress(sender: AnyObject)
    {
        //begin auth with facebook!
        println("authButtonPressed yo!")
    }
}
