//
//  FCAnonOverlayViewController.m
//  Firechat
//
//  Created by Alonso Holmes on 2/5/14.
//  Copyright (c) 2014 Buildco. All rights reserved.
//

#import "FCAnonOverlayViewController.h"
#import <MobileCoreServices/MobileCoreServices.h>
#import "FCUser.h"

@interface FCAnonOverlayViewController ()
@property (weak, nonatomic) IBOutlet UIButton *profileImageButton;
@property (weak, nonatomic) IBOutlet UITextField *usernameTextField;
@property (weak, nonatomic) IBOutlet UIButton *signupButton;
@property UIImage *image;
@end

@implementation FCAnonOverlayViewController

- (id)initWithNibName:(NSString *)nibNameOrNil bundle:(NSBundle *)nibBundleOrNil
{
    self = [super initWithNibName:nibNameOrNil bundle:nibBundleOrNil];
    if (self) {
        // Custom initialization
    }
    return self;
}

- (void)viewDidLoad
{
    [super viewDidLoad];
    // Image should be rounded
    self.profileImageButton.layer.cornerRadius = self.profileImageButton.bounds.size.width / 2.0;
    self.profileImageButton.layer.masksToBounds = YES;
    
    // Close text field on tap outside
    UITapGestureRecognizer *tap = [[UITapGestureRecognizer alloc]
                                   initWithTarget:self
                                   action:@selector(dismissKeyboard)];
    
    [self.view addGestureRecognizer:tap];
    
    // Add a bottom border to the text input
    CALayer *bottomBorder = [CALayer layer];
    bottomBorder.frame = CGRectMake(0.0f, 43.0f, self.view.bounds.size.width, 1.0f);
    bottomBorder.backgroundColor = [UIColor colorWithWhite:0.8f
                                                     alpha:1.0f].CGColor;
    [self.usernameTextField.layer addSublayer:bottomBorder];
    
    // Button should be square with a white border
    self.signupButton.layer.borderWidth = 0.6f;
    self.signupButton.layer.borderColor = [UIColor whiteColor].CGColor;
}

- (void)didReceiveMemoryWarning
{
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

- (void)showWithAnimation
{
    NSLog(@"AWESOME SLIDE-UP ANIMATION HERE!!!");
}

# pragma mark - keyboard dismiss

-(void)dismissKeyboard
{
    [self.usernameTextField resignFirstResponder];
}

# pragma mark - image picker protocol

- (IBAction)showImagePicker:(id)sender {
    UIImagePickerController *imagePicker = [[UIImagePickerController alloc] init];
    imagePicker.delegate = self;
    imagePicker.sourceType = UIImagePickerControllerSourceTypePhotoLibrary;
    imagePicker.mediaTypes =
    @[(NSString *) kUTTypeImage];
    imagePicker.allowsEditing = NO;
    [self presentViewController:imagePicker animated:YES completion:nil];
}

-(void)imagePickerController:(UIImagePickerController *)picker didFinishPickingMediaWithInfo:(NSDictionary *)info
{
    // Dismiss the view controller
    [self dismissViewControllerAnimated:YES completion:nil];
    // store and set the image
    UIImage *chosenImage = info[UIImagePickerControllerOriginalImage];
    self.image = [self squareImageWithImage:chosenImage scaledToSize:self.profileImageButton.bounds.size];
    [self.profileImageButton setBackgroundImage:self.image forState:UIControlStateNormal];
    
}

-(void)imagePickerControllerDidCancel:(UIImagePickerController *)picker
{
    [self dismissViewControllerAnimated:YES completion:nil];
    NSLog(@"User did cancel!");
}

- (UIImage *)squareImageWithImage:(UIImage *)image scaledToSize:(CGSize)newSize {
    double ratio;
    double delta;
    CGPoint offset;
    
    //make a new square size, that is the resized imaged width
    CGSize sz = CGSizeMake(newSize.width, newSize.width);
    
    //figure out if the picture is landscape or portrait, then
    //calculate scale factor and offset
    if (image.size.width > image.size.height) {
        ratio = newSize.width / image.size.width;
        delta = (ratio*image.size.width - ratio*image.size.height);
        offset = CGPointMake(delta/2, 0);
    } else {
        ratio = newSize.width / image.size.height;
        delta = (ratio*image.size.height - ratio*image.size.width);
        offset = CGPointMake(0, delta/2);
    }
    
    //make the final clipping rect based on the calculated values
    CGRect clipRect = CGRectMake(-offset.x, -offset.y,
                                 (ratio * image.size.width) + delta,
                                 (ratio * image.size.height) + delta);
    
    
    //start a new context, with scale factor 0.0 so retina displays get
    //high quality image
    if ([[UIScreen mainScreen] respondsToSelector:@selector(scale)]) {
        UIGraphicsBeginImageContextWithOptions(sz, YES, 0.0);
    } else {
        UIGraphicsBeginImageContext(sz);
    }
    UIRectClip(clipRect);
    [image drawInRect:clipRect];
    UIImage *newImage = UIGraphicsGetImageFromCurrentImageContext();
    UIGraphicsEndImageContext();
    
    return newImage;
}
- (IBAction)signupButtonClicked:(id)sender {
    // Create a new user
        [[FCUser alloc] signupWithUsername:self.usernameTextField.text andImage:self.image];
    //    // Disable the button
        [sender setEnabled:NO];
        [sender setTitle:@"Please wait." forState:UIControlStateNormal];
    // Wait for the success notification
}



@end
