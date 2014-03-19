//
//  FCLandingPageViewController.m
//  Firechat
//
//  Created by Ethan Sherr on 3/17/14.
//  Copyright (c) 2014 Buildco. All rights reserved.
//

#import "FCLandingPageViewController.h"
#import "FCLiveBlurButton.h"

typedef enum
{
    PanGestureDirectionNone,
    PanGestureDirectionUp,
    PanGestureDirectionDown,
    PanGestureDirectionLeft,
    PanGestureDirectionRight
}PanGestureDirection;

@interface FCLandingPageViewController () <UITableViewDataSource, UITableViewDelegate>

@property (nonatomic) UIImageView *extractedImageViewOnDone;

@property (nonatomic) PanGestureDirection panDirection;
@property (nonatomic) UIPanGestureRecognizer *panGesture;
@property (nonatomic) NSInteger colorIndex;

@property (nonatomic) CGPoint offsetOfTableViewAtStartOfVertical;

@property (weak, nonatomic) IBOutlet UIImageView *spinnerImageView;

@property (nonatomic) UITableView *iconTableView;
@property (weak, nonatomic) IBOutlet UIView *iconContainerView;
@property (nonatomic) NSInteger iconIndex;

@property (nonatomic) NSArray *iconNames;
@property (nonatomic) NSArray *colors;

@property (weak, nonatomic) IBOutlet FCLiveBlurButton *doneBlurButton;

@end



@implementation FCLandingPageViewController
@synthesize colorIndex;
@synthesize panDirection;

@synthesize iconIndex;

@synthesize iconNames;
@synthesize iconTableView;

@synthesize doneBlurButton;
@synthesize colors;



- (void)viewDidLoad
{
    [super viewDidLoad];
    
#pragma mark Alonso put colors here
    NSArray *colorsHex = @[@"FF0000", @"00FF00", @"0000FF"];
    NSMutableArray *colorsMutable = [[NSMutableArray alloc] init];
    for (NSString *hexColor in colorsHex)
    {
        [colorsMutable addObject:[UIColor colorWithHexString:hexColor]];
    }
    
    colors = [NSArray arrayWithArray:colorsMutable];

    
    
 
    self.iconNames = @[@"1", @"2", @"3", @"4"];
    [self setIconIndex:0];


    iconTableView = [[UITableView alloc] initWithFrame:self.iconContainerView.bounds style:UITableViewStylePlain];
    [iconTableView setBackgroundColor:[UIColor clearColor]];
    [iconTableView setSeparatorColor:[UIColor clearColor]];
    [iconTableView setShowsVerticalScrollIndicator:NO];
    [iconTableView setUserInteractionEnabled:NO];
    
    {
        CALayer *layer = [CALayer layer];
        [layer setFrame:self.iconContainerView.bounds];
        [layer setCornerRadius:self.iconContainerView.bounds.size.height/2];
        [layer setBackgroundColor:[UIColor whiteColor].CGColor];
        
        [self.iconContainerView.layer setMask:layer];
    }
    
    
    iconTableView.delegate = self;
    iconTableView.dataSource = self;
    
    [self.iconContainerView addSubview:iconTableView];

    
    [self.view setBackgroundColor:[colors objectAtIndex:colorIndex] ];
    
    //add gesture listener pan left right
    
    self.panGesture = [[UIPanGestureRecognizer alloc] initWithTarget:self action:@selector(handlePan:)];
    [self.view addGestureRecognizer:self.panGesture];
    
    // Start animating the image view
    [UIView animateWithDuration:40.0f
                          delay:0.0f
                        options:UIViewAnimationOptionRepeat | UIViewAnimationOptionCurveLinear
                     animations:^{
                         self.spinnerImageView.transform = CGAffineTransformMakeRotation(M_PI);
                     }
                     completion:nil
     ];
    [self.doneBlurButton addTarget:self action:@selector(doneBlurButtonAction:) forControlEvents:UIControlEventTouchUpInside];

}

-(void)doneBlurButtonAction:(UIButton*)button
{
    NSLog(@"doneBlurButtonAction");
    int currentIndex = (iconTableView.contentOffset.y/self.cellHeight);
    
    UITableViewCell * cell = [iconTableView cellForRowAtIndexPath:[NSIndexPath indexPathForRow:currentIndex inSection:0] ];
//    cell.reuseIdentifier = @"lolaok";
    
    UIImageView* imageView = (UIImageView*)[cell viewWithTag:5];
    [imageView setHidden:YES];
    self.extractedImageViewOnDone = [[UIImageView alloc] initWithFrame:imageView.frame];
    [self.extractedImageViewOnDone setContentMode:UIViewContentModeScaleAspectFit];
    [self.extractedImageViewOnDone setImage:imageView.image];
    

    
    CGRect tempFrame = self.extractedImageViewOnDone.frame;
    tempFrame.origin = CGPointMake((self.view.frame.size.width-tempFrame.size.width)*0.5f, (self.view.frame.size.height -tempFrame.size.height)*0.5f);
    self.extractedImageViewOnDone.frame = tempFrame;
    [self.view addSubview:self.extractedImageViewOnDone];
    
    [UIView animateWithDuration:1.2f delay:0.0 usingSpringWithDamping:1.2 initialSpringVelocity:0.0f options:UIViewAnimationOptionCurveLinear animations:^
    {
        for (UIView *subview in self.view.subviews)
        {
            if (subview != self.extractedImageViewOnDone)
            {
                subview.alpha = 0.0f;
            }
        }

    } completion:^(BOOL finished)
    {
        [self transitionToFCWallViewControllerWithImage:self.extractedImageViewOnDone.image andColor:self.view.backgroundColor];
    }];
    
//OK now it is done!

}

-(void)transitionToFCWallViewControllerWithImage:(UIImage*)image andColor:(UIColor*)backgroundColor
{
    UIStoryboard *storyboard = [UIStoryboard storyboardWithName:@"main" bundle:nil];
    UIViewController *nextViewController = [storyboard instantiateViewControllerWithIdentifier:@"FCWallViewController"];

    [nextViewController performSelector:@selector(beginTransitionWithIcon:andColor:) withObject:image withObject:backgroundColor];
    
    NSMutableArray *viewControllers = [NSMutableArray arrayWithArray:self.navigationController.viewControllers];
    [viewControllers addObject:nextViewController];
    self.navigationController.viewControllers = viewControllers;
}


-(void)viewDidAppear:(BOOL)animated
{
    [super viewDidAppear:animated];
    [doneBlurButton invalidatePressedLayer];
}

-(void)handlePan:(UIPanGestureRecognizer*)panGesture
{
//    NSLog(@"panGesture = %@", panGesture);

    CGPoint velocity = [panGesture velocityInView:self.view];
    CGPoint location = [panGesture locationInView:self.view];
    CGPoint translation = [panGesture translationInView:self.view];

    
    static CGFloat swipeWidth = 320;
    CGFloat swipeHeight = self.view.frame.size.height;
    
    switch((int)panGesture.state)
    {
            //determine what kind of swipe, up down left or right
        case UIGestureRecognizerStateBegan:
        {
            
//            NSLog(@"velocity = %@", NSStringFromCGPoint(velocity));
//            NSLog(@"location = %@", NSStringFromCGPoint(location));
//            NSLog(@"translation = %@", NSStringFromCGPoint(translation));
            if (fabsf(velocity.x) > fabsf(velocity.y))
            {
                if (velocity.x < 0)
                {
                    NSLog(@"Left");
                    panDirection = PanGestureDirectionLeft;
                } else
                {
                    NSLog(@"Right");
                    panDirection = PanGestureDirectionRight;
                }
            } else
            {
                if (velocity.y < 0)
                {
                    NSLog(@"Up");
                    panDirection = PanGestureDirectionUp;
                } else
                {
                    NSLog(@"Down");
                    panDirection = PanGestureDirectionDown;
                }
                
                self.offsetOfTableViewAtStartOfVertical = self.iconTableView.contentOffset;
            }
        }
        break;
        case UIGestureRecognizerStateChanged:
        {
            
            CGFloat percent = 0;
            
            switch (panDirection)
            {

                case PanGestureDirectionLeft:
                {
                    percent = translation.x/swipeWidth;
                }
                break;
                case PanGestureDirectionRight:
                {
                    percent = translation.x/swipeWidth;
                }
                break;
                case PanGestureDirectionUp:
                {
                    percent = translation.y/swipeHeight;
                }
                break;
                case PanGestureDirectionDown:
                {
                    percent = translation.y/swipeHeight;
                }
                break;
                case PanGestureDirectionNone:
                {
                    NSLog(@"PanGestureDirectionNone on state changed! WARNING!");
                }
                break;
            }

            if (PanGestureDirectionLeft == panDirection || PanGestureDirectionRight == panDirection )
            {//Left Right color change CHANGE
                int direction = fabsf(percent)/percent;
                while (fabsf(percent >= 1))
                {
                    NSLog(@"direction = %d", direction);
                    
                    percent += -direction;
                    [self setColorIndex:colorIndex+direction];
                }
                
                int start = self.colorIndex;
                int end = self.colorIndex+direction;
                if (end < 0)
                {
                    end = colors.count-1;
                } else
                if (end >= colors.count)
                {
                    end = 0;
                }
                
                if (direction < 0)
                {//switch start and end colors
                    int tempStart = start;
                    start = end;
                    end = tempStart;
                    percent += 1.0f;
                }
                //percent always positive here
                [self.view setBackgroundColor:[self colorLerpFrom:[colors objectAtIndex:start] to:[colors objectAtIndex:end] withDuration:percent]];
                
                
            } else
            if (PanGestureDirectionUp == panDirection || PanGestureDirectionDown == panDirection)
            {
                //up is negative, down is positive
                int direction = fabsf(percent)/percent;
                
                CGFloat y = self.offsetOfTableViewAtStartOfVertical.y - percent*self.cellHeight;
                
                //following if else clause will appear to loop the tableview, aka: no top nor bottom.
                if (y < 0)
                {
                    //reshuffle bottom to top
                    id lastObject = [self.iconNames lastObject];
                    
                    NSMutableArray *iconNamesMutable = [NSMutableArray arrayWithArray:self.iconNames];
                    [iconNamesMutable removeLastObject];
                    [iconNamesMutable insertObject:lastObject atIndex:0];
                    self.iconNames = [NSArray arrayWithArray:iconNamesMutable];
                    [self.iconTableView reloadData];
                
                    //move tableView
                    CGPoint offset = {0, self.cellHeight};
                    
                    self.offsetOfTableViewAtStartOfVertical = offset; //{0, self.offsetOfTableViewAtStartOfVertical.y + self.cellHeight};
                    
                    y = self.offsetOfTableViewAtStartOfVertical.y - percent*self.cellHeight;
                    
                } else
                if (y > self.cellHeight*(self.iconNames.count-1))
                {
                    //reshuffle top to bottom
                    id firstObject = [self.iconNames objectAtIndex:0];
                    
                    NSMutableArray *iconNamesMutable = [NSMutableArray arrayWithArray:self.iconNames];
                    [iconNamesMutable removeObject:firstObject];
                    [iconNamesMutable addObject:firstObject];
                    self.iconNames = [NSArray arrayWithArray:iconNamesMutable];
                    [self.iconTableView reloadData];
                    
                    //move tableView
                    CGPoint offset = {0, self.cellHeight*(self.iconNames.count-1)-self.cellHeight};
                    
                    self.offsetOfTableViewAtStartOfVertical = offset; //{0, self.offsetOfTableViewAtStartOfVertical.y + self.cellHeight};
                    
                    y = self.offsetOfTableViewAtStartOfVertical.y - percent*self.cellHeight;

                    
                }
                
                [self.iconTableView setContentOffset:CGPointMake(0, y)];
                
            }
//            NSLog(@"percent = %f", percent);
        }
        break;
        case UIGestureRecognizerStateEnded:
        {
            CGFloat percent = 0;
            switch (panDirection)
            {
                    
                case PanGestureDirectionLeft:
                {
                    percent = translation.x/swipeWidth;
                }
                    break;
                case PanGestureDirectionRight:
                {
                    percent = translation.x/swipeWidth;
                }
                    break;
                case PanGestureDirectionUp:
                {
                    percent = translation.y/swipeHeight;
                }
                    break;
                case PanGestureDirectionDown:
                {
                    percent = translation.y/swipeHeight;
                }
                    break;
                case PanGestureDirectionNone:
                {
                    NSLog(@"PanGestureDirectionNone on state ENDED! WARNING!");
                }
                break;
            }
            int direction = fabsf(percent)/percent;
            
            if (PanGestureDirectionLeft == panDirection || PanGestureDirectionRight == panDirection )
            {//Left Right color change END
                
                int start = self.colorIndex;
                int end = self.colorIndex+direction;
                if (end < 0)
                {
                    end = colors.count-1;
                } else
                if (end >= colors.count)
                {
                    end = 0;
                }
                
//switch back if not going fast enough for a certain percent traveled
                if (fabsf(velocity.x) < 40 && fabsf(percent) < 0.7f)
                {
                    end = start;
                }
                
                [UIView animateWithDuration:0.25f delay:0.0f usingSpringWithDamping:1.25f initialSpringVelocity:0 options:UIViewAnimationOptionCurveLinear animations:^
                {
                    self.view.backgroundColor = [colors objectAtIndex:end];
                    self.colorIndex = end;
                } completion:^(BOOL finished)
                {
                    [doneBlurButton invalidatePressedLayer];
                }];
                
            } else
            if (PanGestureDirectionUp == panDirection || PanGestureDirectionDown == panDirection)
            {
                int direction = fabsf(percent)/percent;
                
                int numberOfWraps = abs((int)percent);
                numberOfWraps = MAX(1, numberOfWraps);
                
                
                CGFloat y = self.offsetOfTableViewAtStartOfVertical.y - numberOfWraps*direction*self.cellHeight;
                
                [UIView animateWithDuration:0.25f delay:0.0f usingSpringWithDamping:1.25f initialSpringVelocity:0 options:UIViewAnimationOptionCurveLinear animations:^
                {
                    
                    [self.iconTableView setContentOffset:CGPointMake(0, y)];
                    self.iconIndex = iconIndex - numberOfWraps;
                    
                } completion:^(BOOL finished)
                {
                    
                }];
                
            }
        }
        break;
            
            
            
    }
    
}

- (UIColor *)colorLerpFrom:(UIColor *)start to:(UIColor *)end withDuration:(float)t
{
    if(t < 0.0f) t = 0.0f;
    if(t > 1.0f) t = 1.0f;
    
    const CGFloat *startComponent = CGColorGetComponents(start.CGColor);
    const CGFloat *endComponent = CGColorGetComponents(end.CGColor);
    
    float startAlpha = CGColorGetAlpha(start.CGColor);
    float endAlpha = CGColorGetAlpha(end.CGColor);
    
    float r = startComponent[0] + (endComponent[0] - startComponent[0]) * t;
    float g = startComponent[1] + (endComponent[1] - startComponent[1]) * t;
    float b = startComponent[2] + (endComponent[2] - startComponent[2]) * t;
    float a = startAlpha + (endAlpha - startAlpha) * t;
    
    return [UIColor colorWithRed:r green:g blue:b alpha:a];
}

- (void)didReceiveMemoryWarning
{
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

-(void)setIconIndex:(NSInteger)newIconIndex
{
    while (newIconIndex < 0)
    {
        newIconIndex += iconNames.count;
    }
    
    iconIndex = newIconIndex%iconNames.count;
}

-(void)setColorIndex:(NSInteger)newColorIndex
{
    while (newColorIndex < 0)
    {
        newColorIndex += colors.count;
    }
    
    colorIndex = newColorIndex%colors.count;
}

#pragma mark iconTableView delegate callback
-(NSInteger) numberOfSectionsInTableView:(UITableView *)tableView
{
    return 1;
}
-(NSInteger) tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section
{
    return iconNames.count;
}
-(UITableViewCell*)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath
{
    UITableViewCell *iconCell = [tableView dequeueReusableCellWithIdentifier:@"IconCell"];
    if (!iconCell)
    {
        iconCell = [[UITableViewCell alloc] initWithStyle:UITableViewCellStyleDefault reuseIdentifier:@"IconCell"];
        [iconCell setBackgroundColor:[UIColor clearColor]];
        UIImageView *imageView = [[UIImageView alloc] initWithFrame:CGRectMake((self.iconContainerView.bounds.size.width-50)*0.5, (self.iconContainerView.bounds.size.height-50)*0.5, 50, 50)];
        [imageView setContentMode:UIViewContentModeScaleAspectFit];
        imageView.tag = 5;
        [imageView setBackgroundColor:[UIColor clearColor]];
        
        [iconCell.contentView addSubview:imageView];
    }
    
    UIImageView *imageView = (UIImageView*)[iconCell viewWithTag:5];
    [imageView setImage:[UIImage imageNamed:[iconNames objectAtIndex:indexPath.row] ] ];
    
    return iconCell;
}

-(CGFloat)tableView:(UITableView *)tableView heightForRowAtIndexPath:(NSIndexPath *)indexPath
{
    return self.cellHeight;
}

-(CGFloat)cellHeight
{
    return self.iconContainerView.bounds.size.height;
}


#pragma mark iconTableView datasource callback


@end
