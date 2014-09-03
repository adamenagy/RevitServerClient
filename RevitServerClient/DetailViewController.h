//
//  DetailViewController.h
//  RevitServerClient
//
//  Created by Adam Nagy on 02/04/2012.
//  Copyright (c) 2012 Autodek. All rights reserved.
//

#import <UIKit/UIKit.h>

#import "ServerConnection.h"

@interface DetailViewController : UIViewController <UISplitViewControllerDelegate, ServerConnectionDataReadyDelegate>

@property (weak, nonatomic) IBOutlet UIWebView *wvDetails;
@property (strong, nonatomic) UIPopoverController * masterPopoverController;

- (void)updateUserInterface;

@end
