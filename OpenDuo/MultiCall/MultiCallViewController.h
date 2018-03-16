//
//  MultiCallViewController.h
//  OpenDuo
//
//  Created by 林英彬 on 2018/3/15.
//  Copyright © 2018年 Agora. All rights reserved.
//

#import <UIKit/UIKit.h>

@interface MultiCallViewController : UIViewController

@property (copy, nonatomic) NSString *localAccount;
@property (copy, nonatomic) NSString *channel;
@property (nonatomic, copy) NSArray *remoteUserIdArray;

@end
