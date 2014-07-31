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
    
    @IBOutlet weak var titleLabel: UILabel!
    @IBOutlet weak var descriptionLabel: UILabel!
    
    var channelModel:SWChannelModel? = nil {
    didSet {
        //do UI update here

        titleLabel.text = "#\(channelModel!.name!)"
        
    }
    }
    
    
    init(coder aDecoder: NSCoder!)
    {
        
        super.init(coder: aDecoder)
        
        
    }
    
    override func awakeFromNib()
    {

    }
    
    
    
    
    
    
    
    
}