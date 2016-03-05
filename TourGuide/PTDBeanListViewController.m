//
//  PTDViewController.m
//  iOS
//
//  Created by Matthew Chung on 4/23/14.
//  Copyright (c) 2014 Punch Through Design LLC. All rights reserved.
//

#import <PTDBeanManager.h>
#import "PTDBeanListViewController.h"
#import "PTDBeanHeaderCell.h"
#import "PTDBeanDetailController.h"

@interface PTDBeanListViewController () <PTDBeanManagerDelegate, PTDBeanDelegate, UITableViewDataSource, UITableViewDelegate>
// all the beans returned from a scan
@property (nonatomic, strong) NSMutableDictionary *beans;
// how we access the beans
@property (nonatomic, strong) PTDBeanManager *beanManager;
@end

@implementation PTDBeanListViewController

- (void)viewDidLoad {
    [super viewDidLoad];
    
    self.beans = [NSMutableDictionary dictionary];
    // instantiating the bean starts a scan. make sure you have you delegates implemented
    // to receive bean info
    self.beanManager = [[PTDBeanManager alloc] initWithDelegate:self];
}

- (void)viewWillAppear:(BOOL)animated {
    [super viewWillAppear:animated];
    // the next vc grabs the delegate to receive callbacks
    // when the view appears , we want to grab them back.
    self.beanManager.delegate = self;
    [self.tableView reloadData];
}

#pragma mark - Private functions

-(PTDBean*)beanForRow:(NSInteger)row{
    return [self.beans.allValues objectAtIndex:row];
}

#pragma mark - BeanManagerDelegate Callbacks

- (void)beanManagerDidUpdateState:(PTDBeanManager *)manager{
    if(self.beanManager.state == BeanManagerState_PoweredOn){
        [self.beanManager startScanningForBeans_error:nil];
    }
    else if (self.beanManager.state == BeanManagerState_PoweredOff) {
        UIAlertView *alert = [[UIAlertView alloc] initWithTitle:@"Error" message:@"Turn on bluetooth to continue" delegate:nil cancelButtonTitle:nil otherButtonTitles:@"Ok", nil];
        [alert show];
        return;
    }
}
- (void)BeanManager:(PTDBeanManager*)beanManager didDiscoverBean:(PTDBean*)bean error:(NSError*)error{
    NSUUID * key = bean.identifier;
    if (![self.beans objectForKey:key]) {
        // New bean
        NSLog(@"BeanManager:didDiscoverBean:error %@", bean);
        [self.beans setObject:bean forKey:key];
    }
    [self.tableView reloadData];
}
- (void)BeanManager:(PTDBeanManager*)beanManager didConnectToBean:(PTDBean*)bean error:(NSError*)error{
    if (error) {
        UIAlertView *alert = [[UIAlertView alloc] initWithTitle:@"Error" message:[error localizedDescription] delegate:nil cancelButtonTitle:nil otherButtonTitles:@"Ok", nil];
        [alert show];
        return;
    }

    [self.beanManager stopScanningForBeans_error:&error];
    if (error) {
        UIAlertView *alert = [[UIAlertView alloc] initWithTitle:@"Error" message:[error localizedDescription] delegate:nil cancelButtonTitle:nil otherButtonTitles:@"Ok", nil];
        [alert show];
        return;
    }
    [self.tableView reloadData];
}

- (void)BeanManager:(PTDBeanManager*)beanManager didDisconnectBean:(PTDBean*)bean error:(NSError*)error{
    [self.tableView reloadData];
}

#pragma mark UITableViewDataSource

static NSString *CellIdentifier = @"BeanListCell";

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath {
    PTDBean * bean = [self.beans.allValues objectAtIndex:indexPath.row];
    
    PTDBeanHeaderCell *cell = [tableView dequeueReusableCellWithIdentifier:CellIdentifier];
    cell.bean = bean;
    return cell;
}

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section {
    return self.beans.count;
}

- (NSString *)tableView:(UITableView *)tableView titleForHeaderInSection:(NSInteger)section {
    return @"Beans";
}

- (void)prepareForSegue:(UIStoryboardSegue *)segue sender:(id)sender {
    NSIndexPath *indexPath = [self.tableView indexPathForCell:sender];
    PTDBean * bean = [self.beans.allValues objectAtIndex:indexPath.row];
    PTDBeanDetailController *destController = segue.destinationViewController;
    destController.bean = bean;
    destController.beanManager = self.beanManager;
}

#pragma mark Actions

- (IBAction)handleRefresh:(id)sender {
    if(self.beanManager.state == BeanManagerState_PoweredOn){
        NSError *error;
        [self.beanManager startScanningForBeans_error:&error];
        if (error) {
            UIAlertView *alert = [[UIAlertView alloc] initWithTitle:@"Error" message:[error localizedDescription] delegate:nil cancelButtonTitle:nil otherButtonTitles:@"Ok", nil];
            [alert show];
        }
    }
    [(UIRefreshControl *)sender endRefreshing];
}

- (void)didReceiveMemoryWarning
{
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

@end
