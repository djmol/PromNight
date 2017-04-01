//
//  MainViewController.h
//  GuestCheckIn
//
//  Created by Dan on 6/6/16.
//  Copyright © 2016 Passaic County Technical Institute. All rights reserved.
//

#import <UIKit/UIKit.h>
#import <AudioToolbox/AudioToolbox.h>
#import "DuplicateGuestsTableViewController.h"

@interface MainViewController : UIViewController <UITextFieldDelegate, DuplicateGuestsDelegate>
{
    
    CFURLRef soundFileSuccess;
    CFURLRef soundFileError;
    
}

@property (strong, nonatomic) NSManagedObjectContext *managedObjectContext;
@property (strong, nonatomic) NSMutableArray *duplicateGuests;
@property (weak, nonatomic) IBOutlet UITextView *inputField;
@property (weak, nonatomic) IBOutlet UILabel *ticketNumberField;
@property (weak, nonatomic) IBOutlet UILabel *firstNameField;
@property (weak, nonatomic) IBOutlet UILabel *lastNameField;
@property (weak, nonatomic) IBOutlet UILabel *attendanceField;
@property (weak, nonatomic) IBOutlet UILabel *status;
@property (weak, nonatomic) IBOutlet UIView *previewView;
@property (weak, nonatomic) IBOutlet UIImageView *hudView;
@property (weak, nonatomic) IBOutlet UIButton *cameraButton;
@property (weak, nonatomic) IBOutlet UISegmentedControl *flashSegmentedControl;
@property (weak, nonatomic) NSArray *fetchedArrivedObjects;

- (IBAction)barcodeNumberChanged:(UITextField *)sender;

@end
