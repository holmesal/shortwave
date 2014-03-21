//
//  ESCoreDataController.h
//  Firechat
//
//  Created by Ethan Sherr on 3/20/14.
//  Copyright (c) 2014 Buildco. All rights reserved.
//


#import <Foundation/Foundation.h>
#import <CoreData/CoreData.h>

@interface ESCoreDataController : NSObject




+ (id)sharedInstance;

- (NSURL *)applicationDocumentsDirectory;

- (NSManagedObjectContext *)masterManagedObjectContext;
- (NSManagedObjectContext *)backgroundManagedObjectContext;
- (void)saveMasterContext;
- (void)saveBackgroundContext;
- (NSManagedObjectModel *)managedObjectModel;
- (NSPersistentStoreCoordinator *)persistentStoreCoordinator;

-(NSManagedObjectContext*)managedObjectContextOnBackgroundThread;

-(void)deleteEverything;


@end
