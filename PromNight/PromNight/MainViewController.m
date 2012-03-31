//
//  MainViewController.m
//  PromNight
//
//  Created by Abizer Nasir on 31/03/2012.
//  Copyright (c) 2012 Jungle Candy Software. All rights reserved.
//

#import "MainViewController.h"

@interface MainViewController ()

- (void)checkTicketNumber:(NSString *)string;

@end

@implementation MainViewController
@synthesize managedObjectContext = _managedObjectContext;
@synthesize inputField = _inputField;
@synthesize firstNameField = _firstNameField;
@synthesize lastNameField = _lastNameField;
@synthesize arrivedSwitch = _arrivedSwitch;

- (id)initWithNibName:(NSString *)nibNameOrNil bundle:(NSBundle *)nibBundleOrNil {
    self = [super initWithNibName:nibNameOrNil bundle:nibBundleOrNil];
    if (self) {
        // Custom initialization
    }
    return self;
}

- (void)viewDidLoad {
    [super viewDidLoad];
	// Do any additional setup after loading the view.
}

- (void)viewDidUnload {
    [self setInputField:nil];
    [self setFirstNameField:nil];
    [self setLastNameField:nil];
    [self setArrivedSwitch:nil];
    [super viewDidUnload];
    // Release any retained subviews of the main view.
}

- (BOOL)shouldAutorotateToInterfaceOrientation:(UIInterfaceOrientation)interfaceOrientation {
	return YES;
}

#pragma mark - UITextFieldDelegate methods

- (BOOL)textFieldShouldReturn:(UITextField *)textField {
    [self checkTicketNumber:textField.text];
    textField.text = @"";
    return YES;
}

#pragma mark - Private methods;

- (void)checkTicketNumber:(NSString *)string {
    NSFetchRequest *fetchRequest = [[NSFetchRequest alloc] init];
    NSEntityDescription *entity = [NSEntityDescription entityForName:@"Attendee" inManagedObjectContext:self.managedObjectContext];
    [fetchRequest setEntity:entity];
    
    NSPredicate *predicate = [NSPredicate predicateWithFormat:@"ticketNumber == %u", [string integerValue]];
    [fetchRequest setPredicate:predicate];
    
    NSError *error = nil;
    NSArray *fetchedObjects = [self.managedObjectContext executeFetchRequest:fetchRequest error:&error];
    
    if (!fetchedObjects) {
        DLog(@"Unable to retrieve any values because: %@", error);
    }
    
    NSManagedObject *attendee = [fetchedObjects lastObject];
    
    self.firstNameField.text = [attendee valueForKey:@"firstName"];
    self.lastNameField.text = [attendee valueForKey:@"lastName"];
    
    [attendee setValue:[NSNumber numberWithBool:YES] forKey:@"arrived"];
    
    [self.arrivedSwitch setOn:[[attendee valueForKey:@"arrived"] boolValue] animated:YES];
    
    
}

@end