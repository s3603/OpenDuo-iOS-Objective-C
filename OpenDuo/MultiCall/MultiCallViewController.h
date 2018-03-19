//
//  MultiCallViewController.h
//  OpenDuo
//
//  Created by 林英彬 on 2018/3/15.
//  Copyright © 2018年 Agora. All rights reserved.
//

#import <UIKit/UIKit.h>

typedef NS_ENUM(NSUInteger, TTDCMDMessageType) {
   
    MESSAGE_KICK = 0,
    
    MESSAGE_CLOSE_MIC = 1,
    
    MESSAGE_CLOSE_VIDEO = 2,
    
    MESSAGE_OPEN_VIDEO = 3,
};

#define CMDKeys @[@"kick",@"closeMic",@"closeVideo",@"openVideo"]

@interface MultiCallViewController : UIViewController

@property (copy, nonatomic) NSString *localAccount;
@property (copy, nonatomic) NSString *channel;
@property (copy, nonatomic) NSString *initiatorAccount;
@property (nonatomic, copy) NSArray *remoteUserIdArray;

@end
