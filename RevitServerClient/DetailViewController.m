//
//  DetailViewController.m
//  RevitServerClient
//
//  Created by Adam Nagy on 02/04/2012.
//  Copyright (c) 2012 Autodek. All rights reserved.
//

#import "DetailViewController.h"

#import "ServerConnection.h"

@implementation DetailViewController

@synthesize wvDetails = _wvDetails;
@synthesize masterPopoverController = _masterPopoverController;

static ServerConnection * _conn = nil;

#pragma mark - Managing the detail item

- (void)didReceiveMemoryWarning
{
    [super didReceiveMemoryWarning];
    // Release any cached data, images, etc that aren't in use.
}

#pragma mark - View lifecycle

- (void)viewDidLoad
{
    [super viewDidLoad];
    
    [self updateUserInterface];
}

- (void)updateUserInterface
{
    // Clear the user interface
    [[self wvDetails] loadHTMLString:@"" baseURL:nil];
    
    // If there is nothing to show in the Detail View then
    // we can exit the function
    if ([[ServerConnection getDetailRequest] length] == 0)
        return;

    // Data representation update has 2 parts:
    // 1) Here below we ask for the content to be retrieved
    // 2) When it arrives in dataReady() then we update the user interface
    
    _conn = [ServerConnection getData:self ofRequestType:@"GET" withRequest:[ServerConnection getDetailRequest] withRequestId:0];   
}

- (void)viewDidUnload
{
    [self setWvDetails:nil];
    [super viewDidUnload];
    
    // Release any retained subviews of the main view.
    // e.g. self.myOutlet = nil;
    
    [_conn cancelData];
}

- (void)viewWillAppear:(BOOL)animated
{
    [super viewWillAppear:animated];
}

- (void)viewDidAppear:(BOOL)animated
{
    [super viewDidAppear:animated];
}

- (void)viewWillDisappear:(BOOL)animated
{
	[super viewWillDisappear:animated];
}

- (void)viewDidDisappear:(BOOL)animated
{
	[super viewDidDisappear:animated];
}

- (BOOL)shouldAutorotateToInterfaceOrientation:(UIInterfaceOrientation)interfaceOrientation
{
    return YES;
}

#pragma mark - Split view

- (void)splitViewController:(UISplitViewController *)splitController willHideViewController:(UIViewController *)viewController withBarButtonItem:(UIBarButtonItem *)barButtonItem forPopoverController:(UIPopoverController *)popoverController
{
    barButtonItem.title = NSLocalizedString(@"Server", @"Server");
    [self.navigationItem setLeftBarButtonItem:barButtonItem animated:YES];
    self.masterPopoverController = popoverController;
}

- (void)splitViewController:(UISplitViewController *)splitController willShowViewController:(UIViewController *)viewController invalidatingBarButtonItem:(UIBarButtonItem *)barButtonItem
{
    // Called when the view is shown again in the split view, invalidating the button and popover controller.
    [self.navigationItem setLeftBarButtonItem:nil animated:YES];
    self.masterPopoverController = nil;
}

#pragma mark - ServerConnectionDataReadyDelegate

-(void)responseReady:(NSURLResponse *)response withRequestId:(int)requestId
{
    
}

-(void)dataReady:(NSDictionary *)data withRequestId:(int)requestId
{
    // Nothing to do if there is no data to show
    if (data == nil)
        return;
    
    // Html View
    NSString * text = 
        [ServerConnection getDataAsHtmlString:data withIndent:0];    
    
    [[self wvDetails] loadHTMLString:text baseURL:nil];
}

@end
