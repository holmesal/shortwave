//
//  SWNewChannel.swift
//  Shortwave
//
//  Created by Ethan Sherr on 7/30/14.
//  Copyright (c) 2014 Ethan Sherr. All rights reserved.
//

import Foundation
import UIKit

class SWNewChannel: UIViewController, UITextFieldDelegate
{
    
    @IBOutlet weak var navBarLabel: UILabel!
    @IBOutlet weak var fakeNavBar: UIView!
    
    weak var channelViewController: SWChannelsViewController!
    
    @IBOutlet weak var goButton: UIButton!
    
    @IBOutlet weak var channelNameTextField: UITextField!
    @IBOutlet weak var channelSearchResult: UILabel!
    
    @IBOutlet weak var scrollView: UIScrollView!
    
    var channelName = ""
    var channelNameExists:Bool?
    var isJoining:Bool = false
    
    var timer:NSTimer?
    
    //outlets for joining
    @IBOutlet weak var descriptionViewContainer: UIView!
    @IBOutlet weak var descriptionLabel: UILabel!
    
    
    override func viewDidLoad()
    {
        let hexString = kNiceColors["green"]
        fakeNavBar.backgroundColor = UIColor(hexString: hexString)
        
        descriptionViewContainer.alpha = 0.0
        

        navBarLabel.font = UIFont(name: "Avenir-Book", size: 15)
        navBarLabel.textColor = UIColor.whiteColor()
        
        scrollView.alwaysBounceVertical = true
        
        channelNameTextField.delegate = self
        channelNameTextField.becomeFirstResponder()
        
        updateUITimer() //hides the create button for "" result, and sets prompt
        
        
    }
    
    
    
    @IBAction func completeButtonAction(sender: AnyObject?)
    {
        println("complete action!")
        
        channelNameTextField.userInteractionEnabled = false
        goButton.userInteractionEnabled = false
        
        self.performFirebaseFetchForChannel(channelName, result:
            {(exists:Bool) in
                
                if exists
                {
                    self.joinChannel()
                } else
                {
                    self.createChannel()
                }
            })
        
    }
    
    @IBAction func cancelButtonAction(sender: AnyObject?) {
        println("go back yo")
        self.dismissViewControllerAnimated(true, completion:
        {
            if self.isJoining
            {
                self.channelViewController.openChannelForChannelName(self.channelName)
            }
        })
    }
    
    
    // MARK: textFieldDelegate method!
    func textFieldShouldReturn(textField: UITextField!) -> Bool
    {
        textField.resignFirstResponder()
        
        completeButtonAction(nil)
        
        // TODO: invalidate "" channel
        
//        addChannelState = .Seeking(textField.text)
//        self.addChannelCell!.curlDownAMessage("Please wait...", animated: true)
//        
//        self.performFirebaseFetchForChannel(textField.text)
//            {(exists:Bool) in
//                
//                // TODO: add filter to make sure that this is a valid name, break before this
//                
//                self.temporaryModel!.temporary = false
//                let url = kROOT_FIREBASE + "channels/" + textField.text
//                self.temporaryModel!.initialize(dictionary: NSDictionary(), andUrl: url)
//                self.temporaryModel!.bindToWall()
//                
//                if (exists)
//                {//join
//                    println("time to join \(textField.text)")
//                    self.addChannelState = .Pending(isJoining:true, textField.text)
//                    self.joinChannel(self.temporaryModel!)
//                    
//                } else
//                {//create
//                    println("time to create \(textField.text)")
//                    self.addChannelState = .Pending(isJoining:false, textField.text)
//                    self.createChannel(self.temporaryModel!)
//                }
//                
//                self.temporaryModel = nil
//                
//        }
        
        return true
    }
    
    func performFirebaseFetchForChannel(channel:String, result:((exists:Bool)->()) )
    {
        let channelExistenceFetch = Firebase(url: kROOT_FIREBASE + "channels/" + channel + "/public")
        channelExistenceFetch.observeSingleEventOfType(FEventTypeValue)
            {(snap:FDataSnapshot!) in
                
                if let isPublic = snap.value as? Bool
                {
                    // TODO: add support for isPublic == false
                    result(exists: true)
                } else
                {
                    result(exists: false)
                }
        }
    }
    
    //doesn't count for deletes
    func textField(textField: UITextField!, shouldChangeCharactersInRange range: NSRange, replacementString string: String!) -> Bool
    {
        
        
        
        var result = textField.text as NSString
        result = result.stringByReplacingCharactersInRange(range, withString: string)
        
        self.channelName = result
        self.channelNameExists = nil
        
        performFirebaseFetchForChannel(result,
            {(exists:Bool) in
                println("channel \(result) exists? \(exists)")
            
                //if the fetched result is the current result, save its result, wait for time to pass... update
                if (self.channelName == result)
                {
                    self.channelNameExists = exists
                    
                    if self.timer{
                        self.timer!.invalidate()
                    }
                    
                    self.updateUITimer()
                    
//                    self.timer = NSTimer(timeInterval: 0.2, target: self, selector: "updateUITimer", userInfo: nil, repeats: false )
//                    NSRunLoop.mainRunLoop().addTimer(self.timer, forMode: NSDefaultRunLoopMode)
                }
                
            })
        
        return true
    }
    
    func updateUITimer()
    {
        timer?.invalidate()
        timer = nil
        
        println("updateUITimer channel \(self.channelName) exists? \(self.channelNameExists)")
        
        if channelName == "" //invalid
        {
            channelSearchResult.text = "We'll check if it exists."
            goButton.alpha = 0.0
        } else
        if !(self.channelNameExists!)
        {
            channelSearchResult.text = "You are creating this channel."
            
            if self.descriptionViewContainer.alpha != 0.0
            {
                UIView.animateWithDuration(0.4, animations:
                    {
                        self.descriptionViewContainer.alpha = 0.0
                        self.descriptionViewContainer.transform = CGAffineTransformMakeTranslation(0, -5)
                    }, completion: {(b:Bool) in })
            }
            goButton.setTitle("Create", forState: .Normal)
            goButton.alpha = 1
        } else
        {
            channelSearchResult.text = "This channel exists."
            
            self.descriptionViewContainer.transform = CGAffineTransformMakeTranslation(0, -5)
            UIView.animateWithDuration(0.4, animations:
                {
                    self.descriptionViewContainer.alpha = 1.0
                    self.descriptionViewContainer.transform = CGAffineTransformIdentity
                }, completion: {(b:Bool) in })
            
            
            goButton.setTitle("Join", forState: .Normal)
            goButton.alpha = 1
        }
        
    }

    
    func joinChannel()
    {
        let userId = NSUserDefaults.standardUserDefaults().objectForKey(kNSUSERDEFAULTS_KEY_userId) as String
        
        //1 set myself as a moderator
        let membersFB = Firebase(url: "\(kROOT_FIREBASE)channels/\(self.channelName)/members/\(userId)")
        //        println("moderatorsFB \(moderatorsFB)")
        
        membersFB.setValue(true, withCompletionBlock:
            {(error:NSError!, firebase:Firebase!) in
                if error
                {
                    println("error adding myself to a channel \(error)")
                } else
                {
                    //continue joining it by adding to my users/userID/channels
                    let myChannels = Firebase(url: "\(kROOT_FIREBASE)users/\(userId)/channels/\(self.channelName)")
                    myChannels.setValue(["lastSeen":0, "muted":false], andPriority: NSDate().timeIntervalSince1970*1000, withCompletionBlock:
                        {(error:NSError!, firebase:Firebase!) in
                            if error
                            {
                                println("error getting my user to join channel \(error)")
                            } else
                            {
                                self.isJoining = true
                                self.cancelButtonAction(nil)
//                                self.addChannelState = .Ready
//                                self.addChannelCell!.curlDownAMessage("+ Channel", animated: true)
//                                //index of channel?
//                                let section = find(self.channels, channel)!
//                                
//                                //expand this index
//                                self.collectionView(self.channelsCollectionView, didSelectItemAtIndexPath: NSIndexPath(forItem: 0, inSection: section) )
                            }
                        })
                }
            })
    }
    
    func createChannel()
    {
        
        let userId = NSUserDefaults.standardUserDefaults().objectForKey(kNSUSERDEFAULTS_KEY_userId) as String
        
        let value =
        [
            "moderators": [userId: true],
            "members": [userId: true],
            "public": true
        ]
        let channelRoot = Firebase(url: "\(kROOT_FIREBASE)channels/\(self.channelName)")
        channelRoot.setValue(value, withCompletionBlock:
            {(error:NSError!, firebase:Firebase!) in
                println("error \(error) and firebase \(firebase)")
                if error
                {
                    //failure!
                } else
                {
                    let priority = Int(NSDate().timeIntervalSince1970*1000)
                    let yourChannels = Firebase(url: "\(kROOT_FIREBASE)users/\(userId)/channels/\(self.channelName)")
                    yourChannels.setValue([
                        "lastSeen":0,
                        "muted":false
                        ], andPriority:priority, withCompletionBlock:
                        {(error:NSError!, firebase:Firebase!) in
                            if error
                            {
                                
                            } else
                            {
                                self.isJoining = true
                                self.cancelButtonAction(nil)
//                                self.addChannelState = .Ready
//                                self.addChannelCell!.curlDownAMessage("+ Channel", animated: true)
//                                //index of channel?
//                                let section = find(self.channels, channel)!
//                                
//                                //expand this index
//                                self.collectionView(self.channelsCollectionView, didSelectItemAtIndexPath: NSIndexPath(forItem: 0, inSection: section) )
                                
                            }
                        })
                    
                }
            })
    }
}