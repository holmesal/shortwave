//
//  AutoCompleteChannelCell.h
//  hashtag
//
//  Created by Ethan Sherr on 10/6/14.
//  Copyright (c) 2014 Ethan Sherr. All rights reserved.
//

#import <UIKit/UIKit.h>
#import "SWChannelModel.h"

@interface AutoCompleteChannelCell : UICollectionViewCell

-(void)setData:(QueryResult*)setData;

-(QueryResult*)data;

@end
