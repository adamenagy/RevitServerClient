//
//  MasterViewController.h
//  RevitServerClient
//
//  Created by Adam Nagy on 02/04/2012.
//  Copyright (c) 2012 Autodek. All rights reserved.
//

#import <UIKit/UIKit.h>

#import "ServerConnection.h"

@class DetailViewController;

@interface MasterViewController : UITableViewController <ServerConnectionDataReadyDelegate, UIAlertViewDelegate>

@property (strong, nonatomic) DetailViewController * detailViewController;
@property (strong, nonatomic) NSMutableArray * listOfFolders;
@property (strong, nonatomic) NSMutableArray * listOfFiles;

- (void)updateUserInterface;

- (void) setPath:(NSString *)text inSection:(int)section;

- (void) setDetailsRequest:(NSString *)text inSection:(int)section;

+ (NSString *)getNameFromPath:(NSString *)path withDefault:(Boolean)useDefault;

@end
