//
//  AppDelegate.h
//  PCTIGuestCheckInLoader
//
//  Created by Dan on 6/9/16.
//  Copyright © 2016 Passaic County Technical Institute. All rights reserved.
//

#import <Cocoa/Cocoa.h>

@interface AppDelegate : NSObject <NSApplicationDelegate>

@property (assign) IBOutlet NSWindow *window;

@property (readonly, strong, nonatomic) NSPersistentStoreCoordinator *persistentStoreCoordinator;
@property (readonly, strong, nonatomic) NSManagedObjectModel *managedObjectModel;
@property (readonly, strong, nonatomic) NSManagedObjectContext *managedObjectContext;
@property (weak) IBOutlet NSTextField *recordsToProcessLabel;
@property (weak) IBOutlet NSTextField *recordsProcessedLabel;
@property (weak) IBOutlet NSTextField *storeLocationLabel;

- (IBAction)saveAction:(id)sender;

- (IBAction)loadData:(id)sender;

@end
