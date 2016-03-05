//
//  PTDBeanListCell.m
//  Bean Loader
//
//  Created by Matthew Chung on 4/24/14.
//  Copyright (c) 2014 Punch Through Design LLC. All rights reserved.
//

#import "PTDBeanHeaderCell.h"

@interface PTDBeanHeaderCell()
@property (weak, nonatomic) IBOutlet UILabel *nameLabel;
@property (weak, nonatomic) IBOutlet UILabel *rssiLabel;
@property (weak, nonatomic) IBOutlet UILabel *statusLabel;
@end

@implementation PTDBeanHeaderCell

- (id)initWithStyle:(UITableViewCellStyle)style reuseIdentifier:(NSString *)reuseIdentifier
{
    self = [super initWithStyle:style reuseIdentifier:reuseIdentifier];
    if (self) {
        // Initialization code
    }
    return self;
}

- (void)layoutSubviews {
    [super layoutSubviews];
    
    self.nameLabel.text = self.bean.name;
    self.rssiLabel.text = [self.bean.RSSI stringValue];
    NSString* state;
    switch (self.bean.state) {
        case BeanState_Unknown:
            state = @"Unknown";
            break;
        case BeanState_Discovered:
            state = @"Disconnected";
            break;
        case BeanState_AttemptingConnection:
            state = @"Connecting...";
            break;
        case BeanState_AttemptingValidation:
            state = @"Connecting...";
            break;
        case BeanState_ConnectedAndValidated:
            state = @"Connected";
            break;
        case BeanState_AttemptingDisconnection:
            state = @"Disconnecting...";
            break;
        default:
            state = @"Invalid";
            break;
    }
    self.statusLabel.text = state;

}

@end
