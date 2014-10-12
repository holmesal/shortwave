//
//  SWWebSiteCell.m
//  Shortwave
//
//  Created by Ethan Sherr on 8/11/14.
//  Copyright (c) 2014 Ethan Sherr. All rights reserved.
//

#import "SWWebSiteCell.h"
#import "MessageWebSite.h"
#import "UIColor+HexString.h"

@interface SWWebSiteCell ()

@property (weak, nonatomic) IBOutlet UIView *containerView;
@property (weak, nonatomic) IBOutlet UILabel *titleLabel;
@property (weak, nonatomic) IBOutlet NSLayoutConstraint *titleLableTopSpaceToContainer;
@property (weak, nonatomic) IBOutlet NSLayoutConstraint *titleLabelHeightConstraint;

@property (weak, nonatomic) IBOutlet UIView *bodyContainerView;
@property (weak, nonatomic) IBOutlet NSLayoutConstraint *bodyContainerViewHeightConstraint;
@property (weak, nonatomic) IBOutlet NSLayoutConstraint *bodyContainerViewVerticalSpaceBetweenTitle;
@property (weak, nonatomic) IBOutlet UIImageView *bigImageView;
@property (weak, nonatomic) IBOutlet UILabel *descriptionLabel;
@property (weak, nonatomic) IBOutlet NSLayoutConstraint *descriptionLabelHeight;

@property (weak, nonatomic) IBOutlet UIImageView *smalImageView;
@property (weak, nonatomic) IBOutlet UILabel *smallUrlLabel;
@property (weak, nonatomic) IBOutlet NSLayoutConstraint *smallUrlLabelLeftConstraint;

@property (weak, nonatomic) IBOutlet NSLayoutConstraint *trailingViewHeightConstraint;


@property (strong, nonatomic) UIButton *bgButton;



@property (strong, nonatomic) UIColor *titleColorBeforeSelect;
@property (strong, nonatomic) UIColor *descriptionColorBeforeSelect;
@property (strong, nonatomic) UIColor *siteNameColorBeforeSelect;

@end


@implementation SWWebSiteCell
@synthesize containerView;
@synthesize bgButton;


-(void)awakeFromNib
{
    containerView.transform = CGAffineTransformMakeRotation(M_PI);
    
    bgButton = [[UIButton alloc] initWithFrame:CGRectMake(0, 0, 0, 0)];
    [bgButton setBackgroundColor:[UIColor clearColor]];
    [containerView insertSubview:bgButton atIndex:0];
    [bgButton addTarget:self action:@selector(touchDown:) forControlEvents:UIControlEventTouchDown];
    [bgButton addTarget:self action:@selector(touchUpInside:) forControlEvents:UIControlEventTouchUpInside];
    [bgButton addTarget:self action:@selector(touchUpOutOrCancel:) forControlEvents:UIControlEventTouchUpOutside];
    [bgButton addTarget:self action:@selector(touchUpOutOrCancel:) forControlEvents:UIControlEventTouchCancel];
}

#pragma mark bgButton touch gesture responders (and helpera animators) START
-(void)touchDown:(id)sender
{
    [bgButton setBackgroundColor:[UIColor colorWithHexString:@"FFFFFF"]];
    
    _titleColorBeforeSelect = self.titleLabel.textColor;
    _descriptionColorBeforeSelect = self.descriptionLabel.textColor;
    _siteNameColorBeforeSelect = self.smallUrlLabel.textColor;
    
//    self.titleLabel.textColor = [UIColor whiteColor];
//    self.descriptionLabel.textColor = [UIColor whiteColor];
//    self.smallUrlLabel.textColor = [UIColor whiteColor];
    
}

-(void)touchUpInside:(id)sender
{
    
    MessageWebSite *mws = (MessageWebSite*)self.model;
    [[UIApplication sharedApplication] openURL:[NSURL URLWithString:mws.url]];
    
    [self performSelector:@selector(deselectAnimated) withObject:nil afterDelay:1.5];
}

-(void)touchUpOutOrCancel:(id)sender
{
    [self deselectAnimated];
}

-(void)deselectAnimated
{
    [UIView animateWithDuration:0.3 delay:0.0 usingSpringWithDamping:1.0 initialSpringVelocity:1.0 options:UIViewAnimationOptionCurveLinear animations:^
    {
        bgButton.backgroundColor = [UIColor clearColor];
        
        self.titleLabel.textColor = _titleColorBeforeSelect;
        self.descriptionLabel.textColor = _descriptionColorBeforeSelect;
        self.smallUrlLabel.textColor = _siteNameColorBeforeSelect;
        
    } completion:^(BOOL finished)
    {
    
    }];
}

#pragma mark bgButton touch gesture responders END



-(void)setModel:(MessageWebSite *)model
{
    if (super.model != model)
    {
        self.bigImageView.image = nil;
        self.smalImageView.image = nil;
        
        self.bigImageView.alpha = 0.0f;
        self.smalImageView.alpha = 0.0f;
        
        self.descriptionLabel.text = @"";
        self.titleLabel.text = @"";
    }
    
    CGFloat titleLabelHeight = 0;
    if (model.title)
    {

        _titleLabel.text = model.title;
        titleLabelHeight = [_titleLabel sizeThatFits:CGSizeMake(_titleLabel.frame.size.width, 300)].height;
        _bodyContainerViewVerticalSpaceBetweenTitle.constant = 19;
        
    } else
    {
        _bodyContainerViewVerticalSpaceBetweenTitle.constant = 0;
    }
    _titleLabelHeightConstraint.constant = titleLabelHeight;
    
    
    CGFloat bodyHeight = 0;
    if (model.image)
    {
        bodyHeight = 170;
        _descriptionLabelHeight.constant = bodyHeight;
        _descriptionLabel.text = model.image;
        _bigImageView.alpha = 1.0;
    } else
    if (model.description)
    {
        _bigImageView.alpha = 0.0;
        _descriptionLabel.text = model.description;
        bodyHeight = [_descriptionLabel sizeThatFits:CGSizeMake(_descriptionLabel.frame.size.width, 500)].height;
        _descriptionLabelHeight.constant = bodyHeight;
        bodyHeight += 2 * 2; //top and bottom spacing between body container & label inside
    }
    
    _bodyContainerViewHeightConstraint.constant = bodyHeight;
    
    CGFloat trailingViewHeight = 0;
    if (model.siteName || model.favicon)
    {
        trailingViewHeight = 66.0f;
    }
    _trailingViewHeightConstraint.constant = trailingViewHeight;
    
    
    if (model.siteName)
    {
        _smallUrlLabel.text = model.siteName;
        
    } else
    {
        _smallUrlLabel.text = @"";
    }
    
    CGFloat leftSpaceToSmallUrlLabel = 0;
    if (model.favicon)
    {
        leftSpaceToSmallUrlLabel = 54;
    } else
    {
        leftSpaceToSmallUrlLabel = 19;
    }
    _smallUrlLabelLeftConstraint.constant = leftSpaceToSmallUrlLabel;
    
    
    bgButton.frame = self.bounds;
    
    
    
    super.model = model;
}

+(CGFloat)heightWithMessageModel:(MessageWebSite *)model
{
    CGFloat height = 27;//CONST space from top to first element
    if (model.title)
    {
        UILabel *title = [[UILabel alloc] initWithFrame:CGRectMake(19, 27, 282, 300)];
        title.numberOfLines = 2;
        title.font = [UIFont fontWithName:@"Avenir-Medium" size:23];
        title.text = model.title;
        CGSize titleSize = [title sizeThatFits:title.frame.size];
        height += titleSize.height; //height of the TITLE content
        height += 19; //CONST between body content and title label bottom
    }
    
    if (model.image)        //body size determination!
    {
        height += 170;
    } else
    if (model.description)  //body is text!
    {
        UILabel *descriptionLabel = [[UILabel alloc] initWithFrame:CGRectMake(19, 27, 282, 500)];
        descriptionLabel.numberOfLines = 6;
        descriptionLabel.font = [UIFont fontWithName:@"Avenir-Light" size:14];
        descriptionLabel.text = model.description;
        CGSize titleSize = [descriptionLabel sizeThatFits:descriptionLabel.frame.size];
        height += titleSize.height; //height of the DESCRIPTION label
        height += 2 * 2; //space between top (and bottom) of descriptionLabel and its container bodyContainerView
    }
    
    if (model.siteName || model.favicon)
    {
        height += 66;
    }
    
    return height;
}

//image setting selectors
-(void)setFavIconImg:(UIImage*)img animated:(BOOL)animated
{
    [self setImageView:_smalImageView withImage:img animated:animated];
}
-(void)setImg:(UIImage*)img animated:(BOOL)animated
{
    //Q: does img fit into bigImageView.frame.size without enlargement?
    if (img.size.height <= _bigImageView.frame.size.height)
    {
        _bigImageView.contentMode = UIViewContentModeScaleAspectFit;
    } else
    {
        _bigImageView.contentMode = UIViewContentModeScaleAspectFill;
    }
    
    [self setImageView:_bigImageView withImage:img animated:animated];
}

//helper
-(void)setImageView:(UIImageView*)imageView withImage:(UIImage*)image animated:(BOOL)animated
{
    imageView.image = image;
    
    if (animated)
    {
        [UIView animateWithDuration:0.3f delay:0.0f options:UIViewAnimationOptionCurveEaseInOut animations:^
        {
            imageView.alpha = 1.0f;
        } completion:^(BOOL finished){}];
    } else
    {
        imageView.alpha = 1.0;
    }
    
    
}

@end
