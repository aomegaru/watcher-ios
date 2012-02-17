//
//  WatcherChecklistScreenController.m
//  ElectionsWatcher
//
//  Created by xfire on 22.01.12.
//  Copyright (c) 2012 __MyCompanyName__. All rights reserved.
//

#import "WatcherChecklistScreenController.h"
#import "WatcherChecklistScreenCell.h"
#import "AppDelegate.h"
#import "PollingPlace.h"

@implementation WatcherChecklistScreenController

@synthesize screenIndex;
@synthesize sectionIndex;
@synthesize screenInfo;
@synthesize isCancelling;

- (id)initWithStyle:(UITableViewStyle)style
{
    self = [super initWithStyle:style];
    
    if (self) {
        self.tableView.allowsSelection = NO;
    }
    
    return self;
}

- (void)didReceiveMemoryWarning
{
    // Releases the view if it doesn't have a superview.
    [super didReceiveMemoryWarning];
    
    // Release any cached data, images, etc that aren't in use.
}

-(void)dealloc {
    [screenInfo release];
    
    [super dealloc];
}

#pragma mark - View lifecycle

- (void)viewDidLoad
{
    [super viewDidLoad];

    // Uncomment the following line to preserve selection between presentations.
    // self.clearsSelectionOnViewWillAppear = NO;
 
    // Uncomment the following line to display an Edit button in the navigation bar for this view controller.
    // self.navigationItem.rightBarButtonItem = self.editButtonItem;
}

- (void)viewDidUnload
{
    [super viewDidUnload];
    // Release any retained subviews of the main view.
    // e.g. self.myOutlet = nil;
}

- (void)viewWillAppear:(BOOL)animated
{
    [super viewWillAppear:animated];
    
    self.title = [self.screenInfo objectForKey: @"title"];
    
    [self.tableView reloadData];
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
    // Return YES for supported orientations
    return (interfaceOrientation == UIInterfaceOrientationPortrait);
}

#pragma mark - Table view data source

- (NSInteger) numberOfSectionsInTableView: (UITableView *) tableView {
    return 1;
}

-(NSString *)tableView:(UITableView *)tableView titleForHeaderInSection:(NSInteger)section {
    return [self.screenInfo objectForKey: @"title"];
}

- (NSInteger) tableView: (UITableView *) tableView numberOfRowsInSection: (NSInteger) section
{
    return [[screenInfo objectForKey: @"items"] count];
}

- (CGFloat) tableView: (UITableView *) tableView heightForRowAtIndexPath: (NSIndexPath *) indexPath {
    NSDictionary *itemInfo = [[screenInfo objectForKey: @"items"] objectAtIndex: indexPath.row];
    NSString *itemTitle = [itemInfo objectForKey: @"title"];
    int controlType = [[itemInfo objectForKey: @"control"] intValue];
    
    CGSize labelSize;
    
    if ( [itemTitle length] )
        labelSize = [itemTitle sizeWithFont: [UIFont boldSystemFontOfSize: 13] 
                          constrainedToSize: CGSizeMake(280, 120) 
                              lineBreakMode: UILineBreakModeWordWrap];
    else
        labelSize = CGSizeZero;
    
    return controlType == INPUT_COMMENT ? labelSize.height + 140 : labelSize.height + 70;
}

/*
- (void) tableView: (UITableView *) tableView willDisplayCell: (UITableViewCell *) cell forRowAtIndexPath: (NSIndexPath *) indexPath {
    WatcherChecklistScreenCell *watcherCell = (WatcherChecklistScreenCell *) cell;
    watcherCell.itemInfo = [[screenInfo objectForKey: @"items"] objectAtIndex: indexPath.row];
    [watcherCell setNeedsLayout];
}
 */

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath {
    NSArray *items              = [screenInfo objectForKey: @"items"];
    NSDictionary *itemInfo      = [items objectAtIndex: indexPath.row];
    NSString *CellIdentifier    = [@"inputCell_" stringByAppendingString: [[itemInfo objectForKey: @"control"] stringValue]];
//    NSString *CellIdentifier    = [NSString stringWithFormat: @"cell_%d_%d", indexPath.section, indexPath.row];
    UITableViewCell *cell       = [tableView dequeueReusableCellWithIdentifier:CellIdentifier];
    
    if ( cell == nil ) {
        cell = [[[WatcherChecklistScreenCell alloc] initWithStyle: UITableViewCellStyleDefault 
                                                  reuseIdentifier: CellIdentifier 
                                                     withItemInfo: itemInfo] autorelease];
        
        WatcherChecklistScreenCell *watcherCell = (WatcherChecklistScreenCell *) cell;
        watcherCell.saveDelegate = self;
        watcherCell.sectionIndex = self.sectionIndex;
        watcherCell.screenIndex = self.screenIndex;
    }

    
    cell.textLabel.text = nil;
    cell.detailTextLabel.text = nil;
    
    AppDelegate *appDelegate = (AppDelegate *) [[UIApplication sharedApplication] delegate];
    NSArray *checklistItems = [[appDelegate.currentPollingPlace checklistItems] allObjects];
    NSPredicate *itemPredicate = [NSPredicate predicateWithFormat: @"SELF.sectionIndex == %d && SELF.screenIndex == %d && SELF.name LIKE %@", 
                                    self.sectionIndex, self.screenIndex, [itemInfo objectForKey: @"name"]];
    NSArray *existingItems = [checklistItems filteredArrayUsingPredicate: itemPredicate];
    
    if ( existingItems.count ) {
        [(WatcherChecklistScreenCell *) cell setChecklistItem: [existingItems lastObject]];
    } else {
        ChecklistItem *checklistItem = [NSEntityDescription insertNewObjectForEntityForName: @"ChecklistItem" 
                                                                     inManagedObjectContext: appDelegate.managedObjectContext];
        
        [(WatcherChecklistScreenCell *) cell setChecklistItem: checklistItem];
    }
    
    return cell;
}

#pragma mark - Save delegate

-(void)didSaveAttributeItem:(ChecklistItem *)item {
    AppDelegate *appDelegate = (AppDelegate *) [[UIApplication sharedApplication] delegate];
    if ( ! [appDelegate.currentPollingPlace.checklistItems containsObject: item] )
        [appDelegate.currentPollingPlace addChecklistItemsObject: item];
    
    NSError *error = nil;
    [appDelegate.managedObjectContext save: &error];
    
    if ( error )
        NSLog(@"error saving checklist item: %@", error.description);
}

@end
