//
//  ArrivedGuestsViewController.h
//  GuestCheckIn
//
//  Created by Hanley Hansen on 03/30/2012.
//  Copyright (c) 2012 Hansen Info Tech. All rights reserved.
//

#import <UIKit/UIKit.h>
#import <CoreData/CoreData.h>

@interface ArrivedGuestsViewController : UITableViewController <NSFetchedResultsControllerDelegate>

@property (strong, nonatomic) NSManagedObjectContext *moc;
@property (weak, nonatomic) IBOutlet UIButton *clearButton;
@property (weak, nonatomic) IBOutlet UIBarButtonItem *clearAllButton;

@end
