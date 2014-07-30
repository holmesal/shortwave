//
//  SWChannelCell.swift
//  Shortwave
//
//  Created by Ethan Sherr on 7/25/14.
//  Copyright (c) 2014 Ethan Sherr. All rights reserved.
//

import Foundation
import UIKit

class SWChannelCell: UICollectionViewCell, UIGestureRecognizerDelegate
{
    
    @IBOutlet weak var containerView: UIView!
    @IBOutlet weak var textField: UITextField!
    
    let leftScreenEdgeGestureRecognizer:UIScreenEdgePanGestureRecognizer?
    var panAttachmentBehavior:UIAttachmentBehavior?
    
    var animator:UIDynamicAnimator?
    var gravity:UIGravityBehavior?
    var pushBehavior:UIPushBehavior?
    
    var channelModel:SWChannelModel? = nil {
    didSet {
        //do UI update here

        textField.text = channelModel!.name
        
    }
    }
    
    
    init(coder aDecoder: NSCoder!)
    {
        
        super.init(coder: aDecoder)
        
        leftScreenEdgeGestureRecognizer = UIScreenEdgePanGestureRecognizer(target: self, action: "handleScreenEdgePan:")
        leftScreenEdgeGestureRecognizer!.edges = UIRectEdge.Left
        leftScreenEdgeGestureRecognizer!.delegate = self
        self.addGestureRecognizer(leftScreenEdgeGestureRecognizer)
        
    }
    
    override func awakeFromNib()
    {
        setupAnimatorBehavior()
    }
    
    func setupAnimatorBehavior()
    {
        animator = UIDynamicAnimator(referenceView: self)
        
        let collisionBehavior:UICollisionBehavior = UICollisionBehavior(items: [self.containerView]);
        collisionBehavior.setTranslatesReferenceBoundsIntoBoundaryWithInsets(UIEdgeInsetsMake(0, 0, 0, -280))
        animator!.addBehavior(collisionBehavior)
        
        
        gravity = UIGravityBehavior(items: [self.containerView])
        gravity!.gravityDirection = CGVectorMake(-1, 0)
        animator!.addBehavior(gravity)
        
        
        pushBehavior = UIPushBehavior(items: [self.containerView], mode: UIPushBehaviorMode.Instantaneous)
        pushBehavior!.magnitude = 0.0
        pushBehavior!.angle = 0.0
        animator!.addBehavior(pushBehavior)
        
        let itemBehavior: UIDynamicItemBehavior = UIDynamicItemBehavior(items: [self.containerView])
        itemBehavior.elasticity = 0.45
        animator!.addBehavior(itemBehavior)
        
    }
    
    
    func handleScreenEdgePan(gestureRecognizer:UIScreenEdgePanGestureRecognizer)
    {
        var location = gestureRecognizer.locationInView(self)
        location.y = CGRectGetMidY(self.containerView.bounds)
        
        if (gestureRecognizer.state == .Began)
        {
            animator!.removeBehavior(gravity)
            panAttachmentBehavior = UIAttachmentBehavior(item: containerView, attachedToAnchor: location)
            animator!.addBehavior(panAttachmentBehavior)
        } else
        if gestureRecognizer.state == UIGestureRecognizerState.Changed
        {
            panAttachmentBehavior!.anchorPoint = location
        } else
        if gestureRecognizer.state == .Ended
        {
            animator!.removeBehavior(panAttachmentBehavior)
            panAttachmentBehavior = nil;
            
            var velocity = gestureRecognizer.velocityInView(self)
            
            if velocity.x > 0
            {
                //open menu
                gravity!.gravityDirection = CGVectorMake(1, 0)
            } else
            {
                gravity!.gravityDirection = CGVectorMake(-1, 0)
            }
            
            animator!.addBehavior(gravity)
            
            pushBehavior!.pushDirection = CGVector(velocity.x/10.0, 0)
            pushBehavior!.active = true
        }
        
    }
    
    
    
    
}