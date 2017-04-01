//
//  DuplicateGuestsCell.m
//  GuestCheckIn
//
//  Created by Dan on 6/6/16.
//  Copyright © 2016 Passaic County Technical Institute. All rights reserved.
//

#import "DuplicateGuestsCell.h"

@implementation DuplicateGuestsCell

- (void)awakeFromNib {
    [super awakeFromNib];
    
    // Initialization code
    // Set selected color
    UIView *selectedView = [[UIView alloc] initWithFrame:self.frame];
    selectedView.backgroundColor = [UIColor colorWithRed:0.00 green:0.36 blue:0.73 alpha:1.0];
    self.selectedBackgroundView = selectedView;
}

- (void)setSelected:(BOOL)selected animated:(BOOL)animated {
    [super setSelected:selected animated:animated];
    // Configure the view for the selected state
}

@end
