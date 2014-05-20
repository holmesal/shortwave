//
//  SWOwnerTextCell.m
//  Shortwave
//
//  Created by Ethan Sherr on 5/19/14.
//  Copyright (c) 2014 Buildco. All rights reserved.
//

#import "SWOwnerTextCell.h"

@interface SWOwnerTextCell ()

@property (weak, nonatomic) IBOutlet UIImageView *iconImageView;
@property (weak, nonatomic) IBOutlet UITextView *messageText;
@property (weak, nonatomic) IBOutlet UIView *iconImageViewContainer;

@property (nonatomic, strong) CALayer *coloredCircleLayer;

//@property (nonatomic) UILongPressGestureRecognizer *longPress;
//@property (nonatomic) UITapGestureRecognizer *doubleTap;
//@property (nonatomic) UITapGestureRecognizer *debugTap;
@end

@implementation SWOwnerTextCell
@synthesize coloredCircleLayer;
@synthesize ownerID;
@synthesize messageText;
@synthesize iconImageViewContainer;
@synthesize iconImageView;

-(void)awakeFromNib
{
    [super awakeFromNib];
}
-(CALayer*)coloredCircleLayer
{
    if (!coloredCircleLayer)
    {
        CGFloat radius = 15;
        coloredCircleLayer = [CALayer layer];
        [coloredCircleLayer setBackgroundColor:[UIColor blackColor].CGColor];
        [coloredCircleLayer setBorderColor:[UIColor clearColor].CGColor];
        [coloredCircleLayer setCornerRadius:radius];
        
        
        CGRect frame = CGRectMake(-0.5f, -0.0f, radius*2+1, radius*2+1);
        frame.origin.x += (iconImageViewContainer.frame.size.width-frame.size.width)*0.5f;
        frame.origin.y += (iconImageViewContainer.frame.size.height-frame.size.height)*0.5f;
        [coloredCircleLayer setFrame:frame];
        
        [iconImageViewContainer.layer insertSublayer:coloredCircleLayer atIndex:0];
    }
    return coloredCircleLayer;
}

- (void)setMessage:(FCMessage *)message
{
    ownerID = message.ownerID;
    messageText.text = message.text;
    
    [iconImageView setContentMode:UIViewContentModeScaleAspectFit];
    [self.coloredCircleLayer setBackgroundColor:[UIColor colorWithHexString:message.color].CGColor];
    UIImage *img = [UIImage imageNamed:[NSString stringWithFormat:@"%@.png",message.icon]];
    iconImageView.image = img;
    
}

-(void)setFaded:(BOOL)faded animated:(BOOL)animated
{
    CGFloat targetAlpha = (faded? 0.2f : 1.0f);
    
    if (animated)
    {
        [UIView animateWithDuration:0.6f delay:0.0f usingSpringWithDamping:1.2f initialSpringVelocity:0.0f options:UIViewAnimationOptionCurveEaseInOut animations:^
         {
             self.coloredCircleLayer.opacity = targetAlpha;
             iconImageView.alpha = targetAlpha;
             self.messageText.alpha = targetAlpha;
         } completion:^(BOOL finishd){}];
    } else
    {
        self.coloredCircleLayer.opacity = targetAlpha;
        iconImageView.alpha = targetAlpha;
        self.messageText.alpha  = targetAlpha;
    }
}




//debug methods & | custom touches
//-(void)addTapDebugGestureIfNecessary
//{
//    if (!self.debugTap)
//    {
//        self.debugTap = [[UITapGestureRecognizer alloc] initWithTarget:self action:@selector(debugTapGesture:)];
//        if (self.doubleTap)
//            [self.debugTap requireGestureRecognizerToFail:self.doubleTap];
//        [self addGestureRecognizer:self.debugTap];
//    }
//}

//-(void)initializeLongPress
//{
//    if (self.longPress) return;
//    self.longPress = [[UILongPressGestureRecognizer alloc] initWithTarget:self action:@selector(longPressSelector)];
//    [self addGestureRecognizer:self.longPress];
//}
//-(void)initializeDoubleTap
//{
//    if (self.doubleTap) return;
//    self.doubleTap = [[UITapGestureRecognizer alloc] initWithTarget:self action:@selector(doubleTapSelector)];
//    [self.doubleTap setNumberOfTapsRequired:2];
//    [self addGestureRecognizer:self.doubleTap];
//}

#pragma GCC diagnostic ignored "-Wundeclared-selector"
//-(void)longPressSelector
//{
//    UITableView *tableView = (UITableView*)(self.superview.superview);
//    if ([tableView.delegate respondsToSelector:@selector(tableView:didLongPressCellAtIndexPath:)])
//    {
//
//        NSIndexPath *indexPath = [tableView indexPathForCell:self];
//        [tableView.delegate performSelector:@selector(tableView:didLongPressCellAtIndexPath:) withObject:tableView withObject:indexPath];
//    }
//}
//-(void)doubleTapSelector
//{
//    UITableView *tableView = (UITableView*)(self.superview.superview);
//    if ([tableView.delegate respondsToSelector:@selector(tableView:didDoubleTapCellAtIndexPath:)])
//    {
//        NSIndexPath *indexPath = [tableView indexPathForCell:self];
//        [tableView.delegate performSelector:@selector(tableView:didDoubleTapCellAtIndexPath:) withObject:tableView withObject:indexPath];
//
//    }
//}

//-(void)debugTapGesture:(UITapGestureRecognizer*)tap
//{
//    UIAlertView *alertView = [[UIAlertView alloc] initWithTitle:@"Debug" message:self.ownerID delegate:nil cancelButtonTitle:@"ok" otherButtonTitles:nil];
//    [alertView show];
//}

@end
