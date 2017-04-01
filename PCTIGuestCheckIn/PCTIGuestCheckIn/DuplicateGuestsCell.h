//
//  DuplicateGuestsCell.h
//  GuestCheckIn
//
//  Created by Dan on 6/6/16.
//  Copyright © 2016 Passaic County Technical Institute. All rights reserved.
//

#import <UIKit/UIKit.h>
@class Attendee;

@interface DuplicateGuestsCell : UITableViewCell

@property (strong, nonatomic) Attendee *guest;

@property (weak, nonatomic) IBOutlet UILabel *nameLabel;

@end
