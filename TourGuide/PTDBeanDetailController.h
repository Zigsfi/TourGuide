//
//  PTDBeanDetailController.h
//  Bean Loader
//
//  Created by Matthew Chung on 4/24/14.
//  Copyright (c) 2014 Punch Through Design LLC. All rights reserved.
//

#import <PTDBeanManager.h>

@interface PTDBeanDetailController : UIViewController
@property (nonatomic, strong) PTDBean *bean;
@property (nonatomic, strong) PTDBeanManager *beanManager;
@end
