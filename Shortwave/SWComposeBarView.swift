//
//  SWComposeBarView.swift
//  Shortwave
//
//  Created by Ethan Sherr on 7/27/14.
//  Copyright (c) 2014 Ethan Sherr. All rights reserved.
//

import UIKit

class SWComposeBarView: UIView, UITextFieldDelegate
{
    
    var textField:UITextField
    var send:UIButton
    
    init(coder aDecoder: NSCoder!)
    {
        textField = UITextField(frame: CGRectMake(50, (48-40)*0.5, 320-50*2, 40))
        textField.backgroundColor = UIColor.blackColor()
        textField.textColor = UIColor.whiteColor()
        
        send = UIButton(frame: CGRectMake(320-50, 0, 50, 48))
        send.setTitle("Send", forState: .Normal)
        send.titleLabel.textColor = UIColor.blackColor()
        
        
        super.init(coder: aDecoder)
        
        
        textField.delegate = self
        addSubview(textField)
        addSubview(send)
        send.addTarget(self, action: "send:", forControlEvents: .TouchUpInside)
        
    }
    
    init()
    {
        textField = UITextField(frame: CGRectMake(50, (48-40)*0.5, 320-50*2, 40))
        textField.backgroundColor = UIColor.blackColor()
        textField.textColor = UIColor.whiteColor()
       
        
        
        send = UIButton(frame: CGRectMake(320-50, 0, 50, 48))
        send.setTitle("Send", forState: .Normal)
        send.titleLabel.textColor = UIColor.blackColor()
        
        
        super.init(frame: CGRectMake(0, 0, 320, 48))
    
        textField.delegate = self
        addSubview(textField)
        addSubview(send)
        send.addTarget(self, action: "send:", forControlEvents: .TouchUpInside)
    
    }
    
    func send(sender:AnyObject?)
    {
        println("send \(textField.text)!")
        textFieldShouldReturn(textField)
    }
    
    func textFieldShouldReturn(textField: UITextField!) -> Bool
    {
        textField.resignFirstResponder()
        
        return true
    }
    
    
//        var textFieldDelegate:UITextFieldDelegate?
//    {
//        get
//        {
//            println("cycle when setting textFieldDelegate??")
//            return self.textFieldDelegate
//    }
//        set
//        {
//            textField.delegate = newValue
//    }
//    }
    
    
    
}
