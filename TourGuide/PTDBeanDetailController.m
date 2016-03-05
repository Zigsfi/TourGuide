//
//  PTDBeanDetailController.m
//  Bean Loader
//
//  Created by Matthew Chung on 4/24/14.
//  Copyright (c) 2014 Punch Through Design LLC. All rights reserved.
//

#import "PTDBeanDetailController.h"
#import "PTDBeanHeaderCell.h"
#import "PTDBeanRadioConfig.h"

typedef enum {
    ActionCellSendSerialString,
    ActionCellReadAccel,
    ActionCellWriteBlue,
    ActionCellReadLed,
    ActionCellReadTemp,
    ActionCellReadConfig,
    ActionCellWriteConfig,
    ActionCellSetScratchNumber,
    ActionCellGetScratchNumber,
    ActionCellCount
} ActionCell;

@interface PTDBeanDetailController () <PTDBeanManagerDelegate, PTDBeanDelegate, UITableViewDataSource, UITableViewDelegate>
@property (weak, nonatomic) IBOutlet UIBarButtonItem *connectButton;
@property (weak, nonatomic) IBOutlet UITableView *tableView;
@property (nonatomic, strong) NSArray *pendingBeanConfigParams;
@property (nonatomic, assign) BOOL beanConfigUpdatePending;

@end

@implementation PTDBeanDetailController

- (void)viewDidLoad {
    [super viewDidLoad];
}

- (void)viewWillAppear:(BOOL)animated {
    [super viewWillAppear:animated];
    [self update];
}

- (void)update {
    if (self.bean.state == BeanState_Discovered) {
        self.connectButton.title = @"Connect";
        self.connectButton.enabled = YES;
    }
    else if (self.bean.state == BeanState_ConnectedAndValidated) {
        self.connectButton.title = @"Disconnect";
        self.connectButton.enabled = YES;
    }
    [self.tableView reloadData];
}

#pragma mark - BeanManagerDelegate Callbacks

- (void)beanManagerDidUpdateState:(PTDBeanManager *)manager{
}

- (void)BeanManager:(PTDBeanManager*)beanManager didDiscoverBean:(PTDBean*)bean error:(NSError*)error{
}

- (void)BeanManager:(PTDBeanManager*)beanManager didConnectToBean:(PTDBean*)bean error:(NSError*)error{
    if (error) {
        NSLog(@"%@", [error localizedDescription]);
        return;
    }
    
    [self.beanManager stopScanningForBeans_error:&error];
    if (error) {
        NSLog(@"%@", [error localizedDescription]);
        return;
    }
    [self update];
}

- (void)BeanManager:(PTDBeanManager*)beanManager didDisconnectBean:(PTDBean*)bean error:(NSError*)error{
    if (bean == self.bean) {
        [self update];
    }
}

#pragma mark BeanDelegate

-(void)bean:(PTDBean*)device error:(NSError*)error {
    UIAlertView *alert = [[UIAlertView alloc] initWithTitle:@"Error" message:[error localizedDescription] delegate:nil cancelButtonTitle:nil otherButtonTitles:@"Ok", nil];
    [alert show];
}
-(void)bean:(PTDBean*)device receivedMessage:(NSData*)data {

}
-(void)bean:(PTDBean*)device serialDataReceived:(NSData *)data {
    NSString *str = [[NSString alloc] initWithData:data encoding:NSUTF8StringEncoding];
    float i = [str floatValue];
    if (i < 2000) {
        float dist = i * 340.0 / 2 / 1e6;
        UIAlertController *alertController = [UIAlertController alertControllerWithTitle:@"Be Careful" message:[NSString stringWithFormat:@"Obstacle within %f meters.", dist] preferredStyle:UIAlertControllerStyleAlert];
        
        UIAlertAction* ok = [UIAlertAction actionWithTitle:@"OK" style:UIAlertActionStyleDefault handler:nil];
        [alertController addAction:ok];
        
        [self presentViewController:alertController animated:YES completion:nil];
    }
    NSLog(@"%f", i);
    
}
-(void)bean:(PTDBean*)bean didUpdateAccelerationAxes:(PTDAcceleration)acceleration {
    NSString *msg = [NSString stringWithFormat:@"x:%f y:%f z:%f", acceleration.x,acceleration.y,acceleration.z];
    UIAlertView *alert = [[UIAlertView alloc] initWithTitle:@"Result" message:msg delegate:nil cancelButtonTitle:nil otherButtonTitles:@"Ok", nil];
    [alert show];
}
-(void)bean:(PTDBean *)bean didUpdateLoopbackPayload:(NSData *)payload {
    NSString *msg = [NSString stringWithFormat:@"received loopback payload:%@", [payload description]];
    UIAlertView *alert = [[UIAlertView alloc] initWithTitle:@"Result" message:msg delegate:nil cancelButtonTitle:nil otherButtonTitles:@"Ok", nil];
    [alert show];
}
-(void)bean:(PTDBean *)bean didUpdateLedColor:(UIColor *)color {
    CGFloat red;
    CGFloat green;
    CGFloat blue;
    CGFloat alpha;
    [color getRed:&red green:&green blue:&blue alpha:&alpha];
    NSString *msg = [NSString stringWithFormat:@"received did led r:%f g:%f b:%f", red,green,blue];
    UIAlertView *alert = [[UIAlertView alloc] initWithTitle:@"Result" message:msg delegate:nil cancelButtonTitle:nil otherButtonTitles:@"Ok", nil];
    [alert show];
}
-(void)bean:(PTDBean *)bean didUpdatePairingPin:(UInt16)pinCode {
    NSString *msg = [NSString stringWithFormat:@"received did update pairing pin payload:%d", pinCode];
    UIAlertView *alert = [[UIAlertView alloc] initWithTitle:@"Result" message:msg delegate:nil cancelButtonTitle:nil otherButtonTitles:@"Ok", nil];
    [alert show];
}
-(void)bean:(PTDBean *)bean didUpdateTemperature:(NSNumber *)degrees_celsius {
    NSString *msg = [NSString stringWithFormat:@"received did update temp reading:%@", degrees_celsius];
    UIAlertView *alert = [[UIAlertView alloc] initWithTitle:@"Result" message:msg delegate:nil cancelButtonTitle:nil otherButtonTitles:@"Ok", nil];
    [alert show];
}
-(void)bean:(PTDBean*)bean didUpdateRadioConfig:(PTDBeanRadioConfig*)config {
    if ( self.beanConfigUpdatePending && self.pendingBeanConfigParams ) {
        [self updateBeanForConfig:config];
        return;
    }
    NSString *msg = [NSString stringWithFormat:@"received advertising interval:%f connection interval:%f name:%@ power:%d", config.advertisingInterval, config.connectionInterval, config.name, (int)config.power];
    UIAlertView *alert = [[UIAlertView alloc] initWithTitle:@"Result" message:msg delegate:nil cancelButtonTitle:nil otherButtonTitles:@"Ok", nil];
    [alert show];
}
-(void)bean:(PTDBean *)bean didUpdateScratchNumber:(NSNumber *)number withValue:(NSData *)data {
    NSString* str = [NSString stringWithUTF8String:[data bytes]];
    NSString *msg = [NSString stringWithFormat:@"received scratch number:%@ scratch:%@", number, str];
    UIAlertView *alert = [[UIAlertView alloc] initWithTitle:@"Result" message:msg delegate:nil cancelButtonTitle:nil otherButtonTitles:@"Ok", nil];
    [alert show];
}

#pragma mark IBActions

- (IBAction)connectButtonPressed:(id)sender {
    if (self.bean.state == BeanState_Discovered) {
        self.bean.delegate = self;
        [self.beanManager connectToBean:self.bean error:nil];
        self.beanManager.delegate = self;
        self.connectButton.enabled = NO;
    }
    else {
        self.bean.delegate = self;
        [self.beanManager disconnectBean:self.bean error:nil];
    }
    [self.tableView reloadData];
}

#pragma mark UITableViewDataSource

static NSString *CellIdentifier = @"BeanListCell";

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath {
    if (indexPath.section == 0) {
        PTDBeanHeaderCell *cell = [tableView dequeueReusableCellWithIdentifier:CellIdentifier];
        cell.bean = self.bean;
        cell.selectionStyle = UITableViewCellSelectionStyleNone;
        return cell;
    }
    else {
        switch (indexPath.row) {
            case ActionCellSendSerialString: {
                UITableViewCell *cell = [[UITableViewCell alloc] initWithStyle:UITableViewCellStyleDefault reuseIdentifier:nil];
                cell.textLabel.text = @"Send Serial String";
                return cell;
            }
            case ActionCellWriteBlue: {
                UITableViewCell *cell = [[UITableViewCell alloc] initWithStyle:UITableViewCellStyleDefault reuseIdentifier:nil];
                cell.textLabel.text = @"Send LED Write Blue";
                return cell;
            }
            case ActionCellReadLed: {
                UITableViewCell *cell = [[UITableViewCell alloc] initWithStyle:UITableViewCellStyleDefault reuseIdentifier:nil];
                cell.textLabel.text = @"Send Read LED";
                return cell;
            }
            case ActionCellReadAccel: {
                UITableViewCell *cell = [[UITableViewCell alloc] initWithStyle:UITableViewCellStyleDefault reuseIdentifier:nil];
                cell.textLabel.text = @"Send Read Accelerometer";
                return cell;
            }
            case ActionCellReadConfig: {
                UITableViewCell *cell = [[UITableViewCell alloc] initWithStyle:UITableViewCellStyleDefault reuseIdentifier:nil];
                cell.textLabel.text = @"Read Config";
                return cell;
            }
            case ActionCellWriteConfig: {
                UITableViewCell *cell = [[UITableViewCell alloc] initWithStyle:UITableViewCellStyleDefault reuseIdentifier:nil];
                cell.textLabel.text = @"Write Config";
                return cell;
            }
            case ActionCellReadTemp: {
                UITableViewCell *cell = [[UITableViewCell alloc] initWithStyle:UITableViewCellStyleDefault reuseIdentifier:nil];
                cell.textLabel.text = @"Read Temp";
                return cell;
            }
            case ActionCellSetScratchNumber: {
                UITableViewCell *cell = [[UITableViewCell alloc] initWithStyle:UITableViewCellStyleDefault reuseIdentifier:nil];
                cell.textLabel.text = @"Set Scratch Number";
                return cell;
            }
            case ActionCellGetScratchNumber: {
                UITableViewCell *cell = [[UITableViewCell alloc] initWithStyle:UITableViewCellStyleDefault reuseIdentifier:nil];
                cell.textLabel.text = @"Get Scratch Number";
                return cell;
            }
            default:
                break;
        }
    }
    return nil;
}
- (NSInteger)numberOfSectionsInTableView:(UITableView *)tableView {
    if (self.bean.state == BeanState_Discovered) {
        return 1;
    }
    else {
        return 2;
    }
}
- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section {
    if (section == 0) {
        return 1;
    }
    else {
        if (self.bean.state == BeanState_Discovered) {
            return 0;
        }
        else if (self.bean.state == BeanState_ConnectedAndValidated) {
            return ActionCellCount;
        }
        else {
            return 0;
        }
    }
}
- (NSString *)tableView:(UITableView *)tableView titleForHeaderInSection:(NSInteger)section {
    if (section == 0) {
        return @"Bean";
    }
    else {
        return @"Actions";
    }
}

#pragma mark UITableViewDelegate
- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath {
    if (indexPath.section == 1) {
        switch (indexPath.row) {
            case ActionCellSendSerialString: {
                UIAlertView *alertView = [[UIAlertView alloc] initWithTitle:@"Enter String" message:@"" delegate:self cancelButtonTitle:@"Cancel" otherButtonTitles:@"Ok", nil] ;
                alertView.tag = ActionCellSendSerialString;
                alertView.alertViewStyle = UIAlertViewStylePlainTextInput;
                [alertView show];
                break;
            }
            case ActionCellWriteBlue: {
                [self.bean setLedColor:[UIColor blueColor]];
                break;
            }
            case ActionCellReadLed: {
                [self.bean readLedColor];
                break;
            }
            case ActionCellReadAccel: {
                [self.bean readAccelerationAxes];
                break;
            }
            case ActionCellReadConfig: {
                [self.bean readRadioConfig];
                break;
            }
            case ActionCellWriteConfig: {
                UIAlertView *alertView = [[UIAlertView alloc] initWithTitle:@"adv interval(sec),conn interval(sec),power(0,1,2,3),name\nexample:[0.1,0.15,2,mybeanname]" message:@"" delegate:self cancelButtonTitle:@"Cancel" otherButtonTitles:@"Ok", nil] ;
                alertView.tag = ActionCellWriteConfig;
                alertView.alertViewStyle = UIAlertViewStylePlainTextInput;
                [alertView show];
                break;
            }
            case ActionCellReadTemp: {
                [self.bean readTemperature];
                break;
            }
            case ActionCellSetScratchNumber: {
                UIAlertView *alertView = [[UIAlertView alloc] initWithTitle:@"Enter Scratch [scratch number[1-5],scratch data[up to 20 chars]]" message:@"" delegate:self cancelButtonTitle:@"Cancel" otherButtonTitles:@"Ok", nil] ;
                alertView.tag = ActionCellSetScratchNumber;
                alertView.alertViewStyle = UIAlertViewStylePlainTextInput;
                [alertView show];
                break;
            }
            case ActionCellGetScratchNumber: {
                UIAlertView *alertView = [[UIAlertView alloc] initWithTitle:@"Enter Scratch Number [scratch number[1-5]]" message:@"" delegate:self cancelButtonTitle:@"Cancel" otherButtonTitles:@"Ok", nil] ;
                alertView.tag = ActionCellGetScratchNumber;
                alertView.alertViewStyle = UIAlertViewStylePlainTextInput;
                [alertView show];
                break;
            }
            default:
                break;
        }
    }
    [tableView deselectRowAtIndexPath:indexPath animated:YES];
}

#pragma mark UIAlertViewDelegate

- (void)alertView:(UIAlertView *)alertView clickedButtonAtIndex:(NSInteger)buttonIndex{
    if (buttonIndex == 0) {
        return;
    }
    if (alertView.tag == ActionCellSendSerialString) {
        UITextField * alertTextField = [alertView textFieldAtIndex:0];
        [self.bean sendSerialString:alertTextField.text];
    }
    else if (alertView.tag == ActionCellWriteConfig) {
        UITextField * alertTextField = [alertView textFieldAtIndex:0];
        NSArray *arr = [alertTextField.text componentsSeparatedByString:@","];
        if (arr.count != 4) {
            UIAlertView *alert = [[UIAlertView alloc] initWithTitle:@"Error" message:@"Invalid parameters entered" delegate:nil cancelButtonTitle:nil otherButtonTitles:@"Ok", nil];
            [alert show];
            return;
        }
        self.beanConfigUpdatePending = YES;
        self.pendingBeanConfigParams = arr;
        [self.bean readRadioConfig];
    }
    else if (alertView.tag == ActionCellSetScratchNumber) {
        UITextField * alertTextField = [alertView textFieldAtIndex:0];
        NSArray *arr = [alertTextField.text componentsSeparatedByString:@","];
        NSInteger scratchNumber = (NSInteger)[arr[0] integerValue];
        NSString *str = (NSString*)arr[1];
        [self.bean setScratchBank:scratchNumber data:[str dataUsingEncoding:NSUTF8StringEncoding]];
    }
    else if (alertView.tag == ActionCellGetScratchNumber) {
        UITextField * alertTextField = [alertView textFieldAtIndex:0];
        UInt8 scratchNumber = (UInt8)[alertTextField.text integerValue];
        [self.bean readScratchBank:scratchNumber];
    }
}

- (void)updateBeanForConfig:(PTDBeanRadioConfig *)config
{
    config.advertisingInterval = (NSTimeInterval)[self.pendingBeanConfigParams[0] doubleValue] *1000;
    config.connectionInterval = (NSTimeInterval)[self.pendingBeanConfigParams[1] doubleValue] *1000;
    config.power = (PTDTxPower_dB)[self.pendingBeanConfigParams[2] integerValue];
    config.name = self.pendingBeanConfigParams[3];
    if ( [config validate:nil] ) {
        [self.bean setRadioConfig:config];
        self.pendingBeanConfigParams = nil;
        self.beanConfigUpdatePending = NO;
        [self.bean readRadioConfig];
    } else {
        [[[UIAlertView alloc] initWithTitle:@"Error" message:@"Invalid parameters entered" delegate:nil cancelButtonTitle:nil otherButtonTitles:@"Ok", nil] show];
    }
    
}

- (void)dealloc {
    self.bean.delegate = nil;
}

@end
