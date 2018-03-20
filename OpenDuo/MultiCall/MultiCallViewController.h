//
//  MultiCallViewController.h
//  OpenDuo
//
//  Created by 林英彬 on 2018/3/15.
//  Copyright © 2018年 Agora. All rights reserved.
//

#import <UIKit/UIKit.h>
#import "TTDCallSession.h"

typedef NS_ENUM(NSUInteger, TTDCMDMessageType) {
   
    MESSAGE_KICK = 0,
    
    MESSAGE_CLOSE_MIC = 1,
    
    MESSAGE_CLOSE_VIDEO = 2,
    
    MESSAGE_OPEN_VIDEO = 3,
    
    MESSAGE_OPEN_MIC = 4,
};

#define CMDKeys @[@"kick",@"closeMic",@"closeVideo",@"openVideo",@"openMic",@"audience",@"player"]

@interface MultiCallViewController : UIViewController

/*!
 通话实体
 */
@property(nonatomic, strong) TTDCallSession *callSession;

- (void)startCallTo:(NSArray *)userIdList;
- (void)showWithCall:(TTDCallSession *)callSession;

@end
