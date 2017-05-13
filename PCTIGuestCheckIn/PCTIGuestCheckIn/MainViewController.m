//
//  MainViewController.m
//  GuestCheckIn
//
//  Created by Dan on 6/6/16.
//  Copyright © 2016 Passaic County Technical Institute. All rights reserved.
//

#import "MainViewController.h"
#import "ArrivedGuestsViewController.h"
#import "DuplicateGuestsTableViewController.h"
#import "ModelKeys.h"
#import "CommonMacros.h"
#import "MTBBarcodeScanner.h"

static NSString * const ArrivedGuestsSegueIdentifier = @"ArrivedGuestsSegue";
static NSString * const DuplicateGuestsSegueIdentifier = @"DuplicateGuestsSegue";

@interface MainViewController ()

typedef enum VerificationMode : NSUInteger {
    IDNumber = 0,
    LastName
} VerificationMode;

@property (strong, nonatomic, readonly) UIPopoverController *arrivedPopover;
@property (strong, nonatomic, readonly) UIPopoverController *duplicatePopover;
@property (strong, nonatomic) NSString *lastScannerInput;
@property (strong, nonatomic) MTBBarcodeScanner *scanner;
@property (strong, nonatomic) NSLock *lock;
@property (nonatomic) bool isScanning;
@property (nonatomic) VerificationMode verificationMode;
@property (strong, nonatomic) NSMutableDictionary *overlayViews;

- (void)checkBarcodeNumber:(NSString *)string;
- (void)checkLastName:(NSString *)string;
- (NSString *)stringByTrimmingTrailingCharactersInSet:(NSCharacterSet *)characterSet fromString:(NSString *)string;
- (NSString *)stringByTrimmingLeadingCharactersInSet:(NSCharacterSet *)characterSet fromString:(NSString *)string;

@end

@implementation MainViewController
@synthesize managedObjectContext = _managedObjectContext;
@synthesize inputField = _inputField;
@synthesize ticketNumberField = _ticketNumberField;
@synthesize firstNameField = _firstNameField;
@synthesize lastNameField = _lastNameField;
@synthesize attendanceField = _attendanceField;
@synthesize status = _status;
@synthesize fetchedArrivedObjects;
@synthesize arrivedPopover = _arrivedPopover;
@synthesize duplicatePopover = _duplicatePopover;

- (id)initWithNibName:(NSString *)nibNameOrNil bundle:(NSBundle *)nibBundleOrNil {
    self = [super initWithNibName:nibNameOrNil bundle:nibBundleOrNil];
    if (self) {
        // Custom initialization
    }
    return self;
}

- (void)dealloc
{
    CFRelease(soundFileError);
    CFRelease(soundFileSuccess);
}

- (void)viewDidLoad {
    [super viewDidLoad];
    
    // Initialize scanner
    self.lock = [[NSLock alloc] init];
    self.lastScannerInput = [[NSString alloc] init];
    self.scanner = [[MTBBarcodeScanner alloc] initWithPreviewView:self.previewView];
    self.isScanning = false;
    
    // Set flashSegmentedControl visibility
    AVCaptureDevice *device = [AVCaptureDevice defaultDeviceWithMediaType:AVMediaTypeVideo];
    if ([device hasTorch])
        [self.flashSegmentedControl setHidden:false];
    else
        [self.flashSegmentedControl setHidden:true];
    
    // Set default verification mode
    self.verificationMode = IDNumber;
    self.verificationModeView.image = [UIImage imageNamed:@"id-number"];
    
    // Set sounds
    CFBundleRef mainBundle = CFBundleGetMainBundle();
    soundFileError = CFBundleCopyResourceURL(mainBundle, (CFStringRef) @"Error", CFSTR ("wav"), NULL);
    soundFileSuccess = CFBundleCopyResourceURL(mainBundle, (CFStringRef) @"Success", CFSTR ("wav"), NULL);
}

- (void)viewDidAppear:(BOOL)animated {
    [super viewDidAppear:animated];
    [[UIDevice currentDevice] setValue:[NSNumber numberWithInteger: UIInterfaceOrientationPortrait] forKey:@"orientation"];
}

- (void)viewDidUnload {
    [self setInputField:nil];
    [self setTicketNumberField:nil];
    [self setFirstNameField:nil];
    [self setLastNameField:nil];
    [self setAttendanceField:nil];
    [super viewDidUnload];
    // Release any retained subviews of the main view.
}

- (BOOL)shouldAutorotateToInterfaceOrientation:(UIInterfaceOrientation)interfaceOrientation {
    // The background doesn't handle rotation, so only present this in portrait.
    // Either right way up or upside down
    return UIInterfaceOrientationIsPortrait(interfaceOrientation);
}

- (UIStatusBarStyle)preferredStatusBarStyle {
    return UIStatusBarStyleLightContent;
}

#pragma mark - Segues

- (void)prepareForSegue:(UIStoryboardSegue *)segue sender:(id)sender {
    if ([segue.identifier isEqualToString:ArrivedGuestsSegueIdentifier]) {
        ArrivedGuestsViewController *arrivedGuestsVC = segue.destinationViewController;
        arrivedGuestsVC.moc = self.managedObjectContext;
    } else if ([segue.identifier isEqualToString:DuplicateGuestsSegueIdentifier]) {
        DuplicateGuestsTableViewController *duplicateGuestsVC = segue.destinationViewController;
        duplicateGuestsVC.duplicateGuests = self.duplicateGuests;
        duplicateGuestsVC.delegate = self;
    }
    return;
}

#pragma mark - Custom accessors

- (UIPopoverController *)arrivedPopover {
    if (!_arrivedPopover) {
        // Create the UITableViewController that will be presented in a popup
        ArrivedGuestsViewController *tableViewController = [[ArrivedGuestsViewController alloc] init];
        // Pass the managed object context to this controller
        tableViewController.moc = self.managedObjectContext;
        
        // Create a UIPopoverController to display the contents of this tableview controller.
        UIPopoverController *popover = [[UIPopoverController alloc] initWithContentViewController:tableViewController];
        _arrivedPopover = popover;
    }
    
    return _arrivedPopover;
}

- (UIPopoverController *)duplicatePopover {
    if (!_duplicatePopover) {
        // Create the UITableViewController that will be presented in a popup
        DuplicateGuestsTableViewController *tableViewController = [[DuplicateGuestsTableViewController alloc] init];
        
        // Create a UIPopoverController to display the contents of this tableview controller.
        UIPopoverController *popover = [[UIPopoverController alloc] initWithContentViewController:tableViewController];
        _duplicatePopover = popover;
    }
    
    return _duplicatePopover;
}

#pragma mark -  Action methods

- (IBAction)barcodeNumberChanged:(UITextField *)sender {
    /*NSInteger inputLength = [sender.text length];
     
     if (inputLength == 6) {
     [self checkBarcodeNumber:sender.text];
     sender.text = @"";
     }*/
}

- (IBAction)flashSegmentedControlChanged:(id)sender {
    if (self.flashSegmentedControl.selectedSegmentIndex == 0) {
        [self.scanner setTorchMode:MTBTorchModeOn];
    } else if (self.flashSegmentedControl.selectedSegmentIndex == 1) {
        [self.scanner setTorchMode:MTBTorchModeOff];
    } else if (self.flashSegmentedControl.selectedSegmentIndex == 2) {
        [self.scanner setTorchMode:MTBTorchModeAuto];
    }
}

- (IBAction)touchedVerificationModeButton:(id)sender {
    // This is a lame way of doing this, but it's a quick fix for a simple app.
    if (self.verificationMode == IDNumber) {
        // Switch from ID Number to Last Name
        self.verificationMode = LastName;
        self.verificationModeView.image = [UIImage imageNamed:@"last-name"];
    } else if (self.verificationMode == LastName) {
        // Switch from Last Name to ID Number
        self.verificationMode = IDNumber;
        self.verificationModeView.image = [UIImage imageNamed:@"id-number"];
    }
    
    // Reset scanner input
    self.lastScannerInput = nil;
}

- (IBAction)touchedCameraButton:(id)sender {
  
    //CGRect rect = self.hudView.frame;
    //NSLog(@"%f %f %f %f",rect.origin.x, rect.origin.y, rect.size.width, rect.size.height);
    //self.scanner.scanRect = rect;
    
    if ([self.scanner isScanning]) {
        [self stopScanning];
    } else {
        [MTBBarcodeScanner requestCameraPermissionWithSuccess:^(BOOL success) {
            if (success) {
                [self startScanning];
            } else {
                NSLog(@"Access denied!");
                // The user denied access to the camera
                //[self displayPermissionMissingAlert];
            }
        }];
    }
    
}

#pragma mark - Scanner

- (void)startScanning {
    if (self.previewView.hidden == true) {
        // Show scanner view
        [self.previewView setHidden:false];
        [self.scanner unfreezeCapture];
        self.isScanning = true;
        
        // Reset scanner input
        self.lastScannerInput = @"";
        
        NSError *error = nil;
        
        // Scan for QR codes
        [self.scanner startScanningWithResultBlock:^(NSArray *codes) {
            
            // Draw overlays
            [self drawOverlaysOnCodes:codes];
            
            AVMetadataMachineReadableCodeObject *code = [codes firstObject];
            if (code.stringValue == (id)[NSNull null] || code.stringValue.length == 0 || [code.stringValue isEqualToString:self.lastScannerInput]) {
                // Do nothing. Not even worth trying to scan.
            } else {
                if ([self.lock tryLock])
                {
                    @synchronized (self.lock) {
                        // Freeze the capture
                        [self.scanner freezeCapture];
                        
                        // Check the scanner input data against the database
                        [self checkEntry:code.stringValue];
                        self.lastScannerInput = code.stringValue;
                        [NSThread sleepForTimeInterval:.5];
                        
                        // Unfreeze the capture
                        [self.lock unlock];
                        [self.scanner unfreezeCapture];
                    }
                } else {
                    // Do nothing. Locked!
                }
            }
            //[self.scanner stopScanning];
        } error:&error];
    }
    else {
        // Close scanner view
        [self.scanner stopScanning];
        [self.previewView setHidden:true];
    }
}

- (void)stopScanning {
    // Stop scanner and hide preview view
    [self.scanner stopScanning];
    [self.previewView setHidden:true];
    self.isScanning = false;
    
    // Remove overlays
    for (NSString *code in self.overlayViews.allKeys) {
        [self.overlayViews[code] removeFromSuperview];
    }
}

#pragma mark - Scanner overlays

- (void)drawOverlaysOnCodes:(NSArray *)codes {
    // Overlay methods lifted from MTBBarcodeScannerExample
    // Get all of the captured code strings
    NSMutableArray *codeStrings = [[NSMutableArray alloc] init];
    for (AVMetadataMachineReadableCodeObject *code in codes) {
        if (code.stringValue) {
            [codeStrings addObject:code.stringValue];
        }
    }
    
    // Remove any code overlays no longer on the screen
    for (NSString *code in self.overlayViews.allKeys) {
        if ([codeStrings indexOfObject:code] == NSNotFound) {
            // A code that was on the screen is no longer
            // in the list of captured codes, remove its overlay
            [self.overlayViews[code] removeFromSuperview];
            [self.overlayViews removeObjectForKey:code];
        }
    }
    
    for (AVMetadataMachineReadableCodeObject *code in codes) {
        UIView *view = nil;
        NSString *codeString = code.stringValue;
        
        if (codeString) {
            if (self.overlayViews[codeString]) {
                // The overlay is already on the screen
                view = self.overlayViews[codeString];
                
                // Move it to the new location
                view.frame = code.bounds;
                
            } else {
                // Create an overlay
                UIView *overlayView = [self overlayForCodeString:codeString
                                                          bounds:code.bounds];
                self.overlayViews[codeString] = overlayView;
                
                // Add the overlay to the preview view
                [self.previewView addSubview:overlayView];
                
            }
        }
    }
}

- (UIView *)overlayForCodeString:(NSString *)codeString bounds:(CGRect)bounds {
    UIColor *viewColor = [UIColor colorWithRed:0.42 green:0.753 blue:0.278 alpha:1.0]; //#6BC047
    UIView *view = [[UIView alloc] initWithFrame:bounds];
    UILabel *label = [[UILabel alloc] initWithFrame:view.bounds];
    
    // Configure the view
    view.layer.borderWidth = 5.0;
    view.backgroundColor = [viewColor colorWithAlphaComponent:0.75];
    view.layer.borderColor = viewColor.CGColor;
    
    // Configure the label
    label.font = [UIFont boldSystemFontOfSize:12];
    label.text = codeString;
    label.textColor = [UIColor blackColor];
    label.textAlignment = NSTextAlignmentCenter;
    label.numberOfLines = 0;
    
    // Add the label to the view
    [view addSubview:label];
    
    return view;
}

#pragma mark - UITextFieldDelegate methods

- (BOOL)textFieldShouldReturn:(UITextField *)textField {
    if (!isEmpty(textField.text)) {
        [self checkEntry:textField.text];
        textField.text = @"";
        return YES;
    } else {
        return NO;
    }
}

#pragma mark - Verification

- (void)checkEntry:(NSString *)entry{
    if (self.verificationMode == IDNumber) {
        [self checkBarcodeNumber:entry];
    } else if (self.verificationMode == LastName) {
        [self checkLastName:entry];
    }
}

- (NSString *)pruneWhitespace:(NSString *)stringToPrune {
    // Prune whitespace from both ends of string
    NSMutableString *prunedString = [[NSMutableString alloc] init];
    NSString *endPruned;
    endPruned = [self stringByTrimmingTrailingCharactersInSet:[NSCharacterSet whitespaceAndNewlineCharacterSet] fromString:stringToPrune];
    [prunedString appendString:[self stringByTrimmingLeadingCharactersInSet:[NSCharacterSet whitespaceAndNewlineCharacterSet] fromString:endPruned]];
    
    return prunedString;
}

// TODO: Combine this and checkBarcodeNumber. They should've been together to begin with, but surname checking was implemented as a quick-fix.
- (void)checkLastName:(NSString *)string {
    // Sometimes we check guests against last names in our database.
    static NSDateFormatter *dateFormatter = nil;
    
    if (!dateFormatter) {
        dateFormatter = [[NSDateFormatter alloc] init];
        [dateFormatter setDateStyle:NSDateFormatterNoStyle];
        [dateFormatter setTimeStyle:NSDateFormatterShortStyle];
    }
    
    // Set up our fetch request and check if our barcode number is in the database
    NSFetchRequest *fetchRequest = [[NSFetchRequest alloc] init];
    NSEntityDescription *entity = [NSEntityDescription entityForName:@"Attendee" inManagedObjectContext:self.managedObjectContext];
    [fetchRequest setEntity:entity];
    
    // Prune whitespace
    NSString *lastNameString = [self pruneWhitespace:string];
    
    NSPredicate *predicate = [NSPredicate predicateWithFormat:@"lastName ==[c] %@", lastNameString];
    [fetchRequest setPredicate:predicate];
    
    NSError *error = nil;
    NSArray *fetchedObjects = [self.managedObjectContext executeFetchRequest:fetchRequest error:&error];
    
    if (!fetchedObjects) {
        DLog(@"Unable to retrieve any values because: %@", error);
    }
    
    if (!fetchedObjects.count) {
        // Invalid guest
        UIAlertView *alert = [[UIAlertView alloc] initWithTitle:@"Not Found!"
                                                        message:[NSString stringWithFormat:@"Last name not found."]
                                                       delegate:nil
                                              cancelButtonTitle:@"OK"
                                              otherButtonTitles:nil];
        [alert show];
        self.ticketNumberField.text = @"";
        self.firstNameField.text = @"";
        self.lastNameField.text = @"";
        self.status.text = [NSString stringWithFormat:@"Last name not found."];
        [self playSound:soundFileError];
        
    } else {
        // Valid guest
        NSManagedObject *attendee;
        
        // If there's more than one guest with the same last name, throw up a popover for the user to resolve it
        if (fetchedObjects.count > 1) {
            self.duplicateGuests = [[NSMutableArray alloc] init];
            for (NSManagedObject *attendee in fetchedObjects) {
                [self.duplicateGuests addObject:attendee];
            }
            [self performSegueWithIdentifier:DuplicateGuestsSegueIdentifier sender:self];
        } else {
            attendee = [fetchedObjects lastObject];
            
            NSString *ticketNumber = [[attendee valueForKey:kModelTicketNumber] stringValue];
            NSString *firstName = [attendee valueForKey:kModelFirstName];
            NSString *lastName = [attendee valueForKey:kModelLastName];
            NSString *attendance = [[attendee valueForKey:kModelAttendance] stringValue];
            
            self.ticketNumberField.text = ticketNumber;
            self.firstNameField.text = firstName;
            self.lastNameField.text = lastName;
            self.attendanceField.text = attendance;
            
            NSInteger isHere = [[attendee valueForKey:kModelArrived] boolValue];
            
            if ([[attendee valueForKey:kModelAttendance] intValue] > 0) {
                if (!isHere) {
                    // Checking in for the first time
                    [attendee setValue:[NSNumber numberWithBool:YES] forKey:kModelArrived];
                    [attendee setValue:[NSDate date] forKey:kModelArrivalTime];
                    self.status.text = [NSString stringWithFormat: @"%@ %@ is now checked in.", firstName, lastName];
                    [self playSound:soundFileSuccess];
                    if (!self.isScanning) {
                        [_inputField becomeFirstResponder];
                    }
                    
                } else {
                    // Guest had already checked in previously
                    NSString *arrivedAt = [dateFormatter stringFromDate:[attendee valueForKey:kModelArrivalTime]];
                    [self presentAlreadyArrivedErrorForFirstName:firstName lastName:lastName arrivedAtTime:arrivedAt];
                    self.status.text = [NSString stringWithFormat:@"%@ %@ was previously scanned into the system at %@!", firstName, lastName, arrivedAt];
                }
            } else {
                // Guest has invalid ticket (i.e. ticket exists, but the person didn't buy admission, so it's a useless ticket)
                [attendee setValue:[NSNumber numberWithBool:YES] forKey:kModelArrived];
                [attendee setValue:[NSDate date] forKey:kModelArrivalTime];
                [self presentInvalidTicketErrorForFirstName:firstName lastName:lastName];
                self.status.text = [NSString stringWithFormat: @"%@ %@'s ticket is not valid!", firstName, lastName];
            }
        }
    }
    
}

- (void)checkBarcodeNumber:(NSString *)string {
    // Sometimes we check guests against an barcode number in our database.
    static NSDateFormatter *dateFormatter = nil;

    if (!dateFormatter) {
        dateFormatter = [[NSDateFormatter alloc] init];
        [dateFormatter setDateStyle:NSDateFormatterNoStyle];
        [dateFormatter setTimeStyle:NSDateFormatterShortStyle];
    }

    // Set up our fetch request and check if our barcode number is in the database
    NSFetchRequest *fetchRequest = [[NSFetchRequest alloc] init];
    NSEntityDescription *entity = [NSEntityDescription entityForName:@"Attendee" inManagedObjectContext:self.managedObjectContext];
    [fetchRequest setEntity:entity];
    
    NSString *barcodeString = [self pruneWhitespace:string];
    
    NSPredicate *predicate = [NSPredicate predicateWithFormat:@"barcodeNumber == %u", [barcodeString integerValue]];
    [fetchRequest setPredicate:predicate];

    NSError *error = nil;
    NSArray *fetchedObjects = [self.managedObjectContext executeFetchRequest:fetchRequest error:&error];

    if (!fetchedObjects) {
        DLog(@"Unable to retrieve any values because: %@", error);
    }

    if (!fetchedObjects.count) {
        // Invalid guest
        UIAlertView *alert = [[UIAlertView alloc] initWithTitle:@"Doesn't Exist!"
        message:[NSString stringWithFormat:@"Ticket number doesn't exist."]
        delegate:nil
        cancelButtonTitle:@"OK"
        otherButtonTitles:nil];
        [alert show];
        self.ticketNumberField.text = @"";
        self.firstNameField.text = @"";
        self.lastNameField.text = @"";
        self.status.text = [NSString stringWithFormat:@"Ticket number doesn't exist."];
        [self playSound:soundFileError];

        } else {
        // Valid guest
        // Set info on views accordingly
        NSManagedObject *attendee = [fetchedObjects lastObject];

        NSString *ticketNumber = [[attendee valueForKey:kModelTicketNumber] stringValue];
        NSString *firstName = [attendee valueForKey:kModelFirstName];
        NSString *lastName = [attendee valueForKey:kModelLastName];
        NSString *attendance = [[attendee valueForKey:kModelAttendance] stringValue];
            
        self.ticketNumberField.text = ticketNumber;
        self.firstNameField.text = firstName;
        self.lastNameField.text = lastName;
        self.attendanceField.text = attendance;

        NSInteger isHere = [[attendee valueForKey:kModelArrived] boolValue];

        if ([[attendee valueForKey:kModelAttendance] intValue] > 0) {
            if (!isHere) {
                // Guest is being checked in for the first time
                [attendee setValue:[NSNumber numberWithBool:YES] forKey:kModelArrived];
                [attendee setValue:[NSDate date] forKey:kModelArrivalTime];
                self.status.text = [NSString stringWithFormat: @"%@ %@ has arrived.", firstName, lastName];
                [self playSound:soundFileSuccess];
                if (!self.isScanning) {
                    [_inputField becomeFirstResponder];
                }

            } else {
                // Guest has already been scanned into the system
                NSString *arrivedAt = [dateFormatter stringFromDate:[attendee valueForKey:kModelArrivalTime]];
                [self presentAlreadyArrivedErrorForFirstName:firstName lastName:lastName arrivedAtTime:arrivedAt];
                self.status.text = [NSString stringWithFormat:@"%@ %@ was previously scanned into the system at %@!", firstName, lastName, arrivedAt];
            }
        } else {
            // Guest has invalid ticket (i.e. ticket exists, but the person didn't buy admission, so it's a useless ticket)
            [attendee setValue:[NSNumber numberWithBool:YES] forKey:kModelArrived];
            [attendee setValue:[NSDate date] forKey:kModelArrivalTime];
            [self presentInvalidTicketErrorForFirstName:firstName lastName:lastName];
            self.status.text = [NSString stringWithFormat: @"%@ %@'s ticket is not valid!", firstName, lastName];
        }
    }
 }

- (void)presentInvalidTicketErrorForFirstName:(NSString *)firstName lastName:(NSString *)lastName {
    UIAlertView *alert = [[UIAlertView alloc] initWithTitle:@"Invalid ticket!"
                                                    message:[NSString stringWithFormat:@"%@ %@'s ticket is NOT valid.", firstName, lastName]
                                                   delegate:nil
                                          cancelButtonTitle:@"OK"
                                          otherButtonTitles:nil];
    [alert show];
    [self playSound:soundFileError];
}

- (void)presentAlreadyArrivedErrorForFirstName:(NSString *)firstName lastName:(NSString *)lastName arrivedAtTime:(NSString *)time {
    UIAlertView *alert = [[UIAlertView alloc] initWithTitle:@"Already here!"
                                                    message:[NSString stringWithFormat:@"%@ %@ was previously scanned into the system at %@!", firstName, lastName, time]
                                                   delegate:nil
                                          cancelButtonTitle:@"OK"
                                          otherButtonTitles:nil];
    [alert show];
    [self playSound:soundFileError];
}

#pragma mark - DuplicateGuestsDelegate

- (void)selectedDuplicateGuest:(Attendee *)attendee {
    
    static NSDateFormatter *dateFormatter = nil;
    
    if (!dateFormatter) {
        dateFormatter = [[NSDateFormatter alloc] init];
        [dateFormatter setDateStyle:NSDateFormatterNoStyle];
        [dateFormatter setTimeStyle:NSDateFormatterShortStyle];
    }
    
    NSString *ticketNumber = [[attendee valueForKey:kModelBarcodeNumber] stringValue];
    NSString *firstName = [attendee valueForKey:kModelFirstName];
    NSString *lastName = [attendee valueForKey:kModelLastName];
    NSString *attendance = [[attendee valueForKey:kModelAttendance] stringValue];
    
    self.ticketNumberField.text = ticketNumber;
    self.firstNameField.text = firstName;
    self.lastNameField.text = lastName;
    self.attendanceField.text = attendance;
    
    NSInteger isHere = [[attendee valueForKey:kModelArrived] boolValue];
    
    if (!isHere) {
        
        [attendee setValue:[NSNumber numberWithBool:YES] forKey:kModelArrived];
        [attendee setValue:[NSDate date] forKey:kModelArrivalTime];
        self.status.text = [NSString stringWithFormat: @"%@ %@ is now checked in.", firstName, lastName];
        [self playSound:soundFileSuccess];
        if (!self.isScanning) {
            [_inputField becomeFirstResponder];
        }
        
    } else {
        NSString *arrivedAt = [dateFormatter stringFromDate:[attendee valueForKey:kModelArrivalTime]];
        [self presentAlreadyArrivedErrorForFirstName:firstName lastName:lastName arrivedAtTime:arrivedAt];
        self.status.text = [NSString stringWithFormat:@"%@ %@ was previously scanned into the system at %@!", firstName, lastName, arrivedAt];
    }
}

-(void)playSound:(CFURLRef)soundFile {
    UInt32 soundID;
    AudioServicesCreateSystemSoundID(soundFile, &soundID);
    AudioServicesPlaySystemSound(soundID);
}

#pragma mark - String parsing

- (NSString *)stringByTrimmingTrailingCharactersInSet:(NSCharacterSet *)characterSet fromString:(NSString *)string {
    NSUInteger location = 0;
    NSUInteger length = [string length];
    unichar charBuffer[length];
    [string getCharacters:charBuffer];
    
    for (length; length > 0; length--) {
        if (![characterSet characterIsMember:charBuffer[length - 1]]) {
            break;
        }
    }
    
    return [string substringWithRange:NSMakeRange(location, length - location)];
}

- (NSString *)stringByTrimmingLeadingCharactersInSet:(NSCharacterSet *)characterSet fromString:(NSString *)string {
    NSUInteger location = 0;
    NSUInteger length = [string length];
    unichar charBuffer[length];
    [string getCharacters:charBuffer];
    
    for (location; location < length; location++) {
        if (![characterSet characterIsMember:charBuffer[location]]) {
            break;
        }
    }
    
    return [string substringWithRange:NSMakeRange(location, length - location)];
}

#pragma mark - Overlay Views

- (NSMutableDictionary *)overlayViews {
    if (!_overlayViews) {
        _overlayViews = [[NSMutableDictionary alloc] init];
    }
    return _overlayViews;
}

@end
