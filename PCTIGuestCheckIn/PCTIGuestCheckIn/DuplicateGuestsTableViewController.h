//
//  DuplicateGuestsTableViewController.h
//  GuestCheckIn
//
//  Created by Dan on 6/6/16.
//  Copyright © 2016 Passaic County Technical Institute. All rights reserved.
//

#import <UIKit/UIKit.h>
#import "Attendee.h"

@protocol DuplicateGuestsDelegate <NSObject>

- (void)selectedDuplicateGuest:(Attendee *)attendee;

@end

@interface DuplicateGuestsTableViewController : UITableViewController

@property (strong, nonatomic) NSMutableArray *duplicateGuests;
@property (weak, nonatomic) id <DuplicateGuestsDelegate> delegate;

@end
