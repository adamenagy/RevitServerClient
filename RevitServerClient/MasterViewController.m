//
//  MasterViewController.m
//  RevitServerClient
//
//  Created by Adam Nagy on 02/04/2012.
//  Copyright (c) 2012 Autodek. All rights reserved.
//

#import "MasterViewController.h"

#import "DetailViewController.h"

#import "ProgressViewController.h"

#import "ServerConnection.h"

@implementation MasterViewController

@synthesize detailViewController = _detailViewController;
@synthesize listOfFiles = _listOfFiles;
@synthesize listOfFolders = _listOfFolders;

static ServerConnection * _conn = nil;

- (void)awakeFromNib
{
    if ([[UIDevice currentDevice] userInterfaceIdiom] == UIUserInterfaceIdiomPad) {
        self.clearsSelectionOnViewWillAppear = NO;
        self.contentSizeForViewInPopover = CGSizeMake(320.0, 600.0);
    }
    [super awakeFromNib];
}

- (void)didReceiveMemoryWarning
{
    [super didReceiveMemoryWarning];
    // Release any cached data, images, etc that aren't in use.
}

#pragma mark - View lifecycle

- (void)viewDidLoad
{
    [super viewDidLoad];
    
    // Add editing capability
    [[self navigationItem] setRightBarButtonItem:[self editButtonItem]];
    
	// Do any additional setup after loading the view, typically from a nib.
    self.detailViewController = (DetailViewController *)[[self.splitViewController.viewControllers lastObject] topViewController];
    
    NSLog(@"MasterViewController.viewDidLoad, \n  self = %@\n  self.detailViewController = %@", [self description], self.detailViewController);
    
    self.listOfFolders = [[NSMutableArray alloc] init];
    self.listOfFiles = [[NSMutableArray alloc] init];     
    
    [self updateUserInterface];
    
    [self.detailViewController updateUserInterface];

    NSLog(@"MasterViewController.viewDidLoad - return");
}

- (void)updateUserInterface
{
    // Data representation update has 3 parts:
    // 1) Here below we ask for the content to be retrieved
    // 2) When it arrives in dataReady() then we update the ServerConnection 
    // data and trigger a view update >> [tableView reloadData];
    // 3) The table will ask for the latest data to show in the user interface
    
    NSString * fullPath = [NSString stringWithFormat:@"%@%@", [ServerConnection getPath], @"/contents"];
    
    [self.listOfFiles removeAllObjects];
    [self.listOfFolders removeAllObjects];
    
    _conn = [ServerConnection getData:self ofRequestType:@"GET" withRequest:fullPath withRequestId:0];
    
    NSLog(@"updateUserInterface");
}

- (void)viewDidUnload
{
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

- (void) setPath:(NSString *)text inSection:(int)section
{
    NSString * path = [ServerConnection getPath];
    NSString * folder = [MasterViewController getNameFromPath:path withDefault:false];
    Boolean isRoot = folder == nil; 
    
    switch (section)
    {
        case 0:
        {
            // In case of clicking on "Server" we have nothing to do
            // as we cannot get higher than that
            if (isRoot)
                return;
            
            NSString * newPath = [path substringToIndex:([path length] - [folder length] - 1)];
            
            [ServerConnection setPath:newPath];           
            
            break;
        }
            
        case 1:
        {
            NSString * newPath = [NSString stringWithFormat:@"%@|%@", [ServerConnection getPath], text];
            
            [ServerConnection setPath:newPath];
            
            break;
        }  
            
        // In case of clicking on a file we have nothing to do    
        case 2:
            return;
    }
    
    // Upadate Master View to show the content 
    // of the subdirectory
    [self updateUserInterface];    
}

- (void) setDetailsRequest:(NSString *)text inSection:(int)section
{
    NSString * path = [ServerConnection getPath];
    NSString * folder = [MasterViewController getNameFromPath:path withDefault:false];
    Boolean isRoot = folder == nil; 
    
    switch (section)
    {
        case 0:
        {
            if (isRoot)
            {                
                // Since we are in the root folder let's get the server details
                [ServerConnection setDetailRequest:@"serverProperties"]; 
            }
            else
            {
                // Get the properties of the current folder
                NSString * request = [NSString stringWithFormat:@"%@/DirectoryInfo", path]; 
                [ServerConnection setDetailRequest:request]; 
            }
            
            break;
        }
            
        case 1:
        {
            NSString * request = 
                [NSString stringWithFormat:@"%@|%@/DirectoryInfo", [ServerConnection getPath], text];
            
            [ServerConnection setDetailRequest:request]; 
            
            break;
        }  
            
        case 2:
        {
            NSString * request = 
            [NSString stringWithFormat:@"%@|%@/history", [ServerConnection getPath], text];
            
            [ServerConnection setDetailRequest:request]; 
            
            break;
        }
    }
    
    // Update the Detail View to show the 
    // information about the selected item
    // Either implicitly by switching to the Detail View on iPhone
    // or explicitly using updateUserInterface on iPad
    if ([[UIDevice currentDevice] userInterfaceIdiom] == UIUserInterfaceIdiomPhone) 
        [self performSegueWithIdentifier:@"segueToDetails" sender:self];  
    else
    {
        [self.detailViewController updateUserInterface]; 

        UIPopoverController * popoverController = [[self detailViewController] masterPopoverController];
        if (popoverController != nil)
        {
            // In Portrait we have a pop-up that we should probably dismiss
            [popoverController dismissPopoverAnimated:YES];
        }
    }
}

- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath
{
    NSLog(@"tableView.didSelectRowAtIndexPath");
    
    UITableViewCell * cell = [tableView cellForRowAtIndexPath:indexPath];
    
    NSString * text = [[cell textLabel] text];    
    
    [self setPath:text inSection:indexPath.section];
}


- (void)                        tableView:(UITableView *)tableView 
 accessoryButtonTappedForRowWithIndexPath:(NSIndexPath *)indexPath
{
    UITableViewCell * cell = [tableView cellForRowAtIndexPath:indexPath];
    NSString * text = [[cell textLabel] text];    
    
    [self setDetailsRequest:text inSection:indexPath.section];
}

#pragma mark - UITableViewDataSource

- (NSInteger)tableView:(UITableView *)tableView 
 numberOfRowsInSection:(NSInteger)section
{
    switch (section)
    {
        case 0:
        {
            NSLog(@"numberOfRowsInSection / 1");
            return 1;
        }   
            
        case 1: 
        {
            NSInteger i = [self.listOfFolders count];
            NSLog(@"numberOfRowsInSection / listOfFolders / %d", i);
            return i;
        }
            
        case 2:
        {
            NSInteger i = [self.listOfFiles count];
            NSLog(@"numberOfRowsInSection / listOfFiles / %d", i);
            return i;
        }
            
        default:
        {
            NSLog(@"numberOfRowsInSection / 0");
            return 0;
        }   
    }
}

- (NSInteger)numberOfSectionsInTableView:(UITableView *)tableView
{
    NSLog(@"numberOfSectionsInTableView / 3");
    return 3;
}

- (NSString *)tableView:(UITableView *)tableView 
titleForHeaderInSection:(NSInteger)section
{
    switch (section)
    {
        case 0:
            return @"Parent Folder";
            
        case 1: 
            return @"Folders";
            
        case 2:
            return @"Files";
    }  
    
    return @"";    
}

+ (NSString *)getNameFromPath:(NSString *)path withDefault:(Boolean)useDefault
{
    NSArray * split = [path componentsSeparatedByString:@"|"];
    
    if ([split count] <= 2)
    {
        if (useDefault)
            return @"Server";
        else
            return nil;
    }
    else
        return [split lastObject];
}

// Row display. Implementers should *always* try to reuse cells by setting each cell's reuseIdentifier and querying for available reusable cells with dequeueReusableCellWithIdentifier:
// Cell gets various attributes set automatically based on table (separators) and data source (accessory views, editing controls)

- (UITableViewCell *)tableView:(UITableView *)tableView 
         cellForRowAtIndexPath:(NSIndexPath *)indexPath
{
    NSLog(@"cellForRowAtIndexPath / begin / section = %d / row = %d", indexPath.section, indexPath.row);
    
    UITableViewCell * cell = [tableView dequeueReusableCellWithIdentifier:@"tvcTemplate"];
    
    if (cell == nil) 
    {
        cell = [[UITableViewCell alloc] 
                initWithStyle:UITableViewCellStyleDefault 
              reuseIdentifier:@"tvcTemplate"];
    } 
    
    switch (indexPath.section)
    {
        case 0:
        {
            NSString * name = 
                [MasterViewController getNameFromPath:[ServerConnection getPath] withDefault:false];
            
            if (name == nil)
            {
                [[cell textLabel] setText:@"Server"];
                [cell setSelectionStyle:UITableViewCellSelectionStyleNone];
            }
            else
            {
                [[cell textLabel] setText:name];                
            }
            
            break;
        }
            
        case 1: 
            [[cell textLabel] setText:
                [self.listOfFolders objectAtIndex:indexPath.row]];
            break;
            
        case 2:
            [[cell textLabel] setText:
                [self.listOfFiles objectAtIndex:indexPath.row]];
            
            [cell setSelectionStyle:UITableViewCellSelectionStyleNone];
            
            break;
    } 
    
    cell.accessoryType = UITableViewCellAccessoryDetailDisclosureButton;
    
    NSLog(@"cellForRowAtIndexPath / end");
    return cell;
}

- (BOOL)tableView:(UITableView *)tableView canEditRowAtIndexPath:(NSIndexPath *)indexPath
{
    // Only folders can be edited, but let the system 
    // put all the items into editing mode, so that the buttons
    // get inactivated
    return true;
}

- (UITableViewCellEditingStyle)tableView:(UITableView *)tableView editingStyleForRowAtIndexPath:(NSIndexPath *)indexPath
{
    // Only folders can be edited (it can be copied)
    if (indexPath.section == 1)    
        return UITableViewCellEditingStyleInsert;
    else
        return UITableViewCellEditingStyleNone;
}

- (void)tableView:(UITableView *)tableView commitEditingStyle:(UITableViewCellEditingStyle)editingStyle forRowAtIndexPath:(NSIndexPath *)indexPath 
{    
    if (editingStyle == UITableViewCellEditingStyleInsert) 
    {
        /*
        UIAlertView * alert = [[UIAlertView alloc] initWithTitle:@"Copy Folder" message:@"Talking to server ..." delegate:self cancelButtonTitle:@"Cancel" otherButtonTitles:nil, nil ];
        
        [alert show];  
            */    
        
        UITableViewCell * cell = [tableView cellForRowAtIndexPath:indexPath];
        
        // e.g. /Folder_B/descendent?sourceObjectPath=Folder_A|Model_01.rvt&pasteAction=Move&duplicateOption=CopyIncrement

        NSString * fullRequest = 
        [NSString stringWithFormat:@"%@/descendent?sourceObjectPath=%@|%@&pasteAction=Copy&duplicateOption=CopyIncrement",
         [ServerConnection getPath],
         [ServerConnection getPath],
         [[cell textLabel] text]];
        
        // Start getting copying
        _conn = [ServerConnection 
                 getData:self 
                 ofRequestType:@"POST" 
                 withRequest:fullRequest 
                 withRequestId:1];
    }   
}
 
- (void)alertViewCancel:(UIAlertView *)alertView
{
    [_conn cancelData];   
}

- (void)alertView:(UIAlertView *)alertView clickedButtonAtIndex:(NSInteger)buttonIndex
{
    [_conn cancelData];   
}

#pragma mark - ServerConnectionDataReadyDelegate

-(void)responseReady:(NSURLResponse *)response withRequestId:(int)requestId
{
    if (requestId != 1)
        return;
    
    // Data from the folder creation
    // Should get message saying "Created" + "Location"
    
    NSHTTPURLResponse * httpResponse = (NSHTTPURLResponse *)response;
    
    NSDictionary * dict = httpResponse.allHeaderFields;
    
    for (NSString * key in dict)
    {
        NSLog(@"Key [%@] with value [%@]", key, [dict valueForKey:key]);
    }

    //NSObject * obj1 = [response valueForKey:@"Created"];
}

-(void)dataReady:(NSDictionary *)data withRequestId:(int)requestId
{    
    if (requestId != 0)
        return;
    
    self.listOfFiles =
        [ServerConnection getDataAsList:data forItem:@"Models" andSubItem:@"Name"];
        
    self.listOfFolders = 
        [ServerConnection getDataAsList:data forItem:@"Folders" andSubItem:@"Name"];
        
    UITableView * tableView = (UITableView *)self.view;
    [tableView reloadData];
}

@end
