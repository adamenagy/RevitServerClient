//
//  ServerViewController.h
//  RevitServerClient
//
//  Created by Adam Nagy on 02/04/2012.
//  Copyright (c) 2012 Autodek. All rights reserved.
//

#import <UIKit/UIKit.h>

@interface ServerViewController : UIViewController

- (IBAction)ClickConnect:(id)sender;

@property (weak, nonatomic) IBOutlet UITextField *txtServerIP;

@end
