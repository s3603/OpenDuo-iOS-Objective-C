//
//  TTDCallClient.m
//  TTDLive
//
//  Created by 林英彬 on 2018/3/14.
//  Copyright © 2018年 linyingbin. All rights reserved.
//

#import "TTDCallClient.h"
#import "RCCallCommonDefine.h"

@interface TTDCallClient ()

@property(nonatomic, strong) NSMutableArray *callWindows;

@end

@implementation TTDCallClient

+(instancetype)sharedTTDCallClient {
    static TTDCallClient *instance = nil;
    static dispatch_once_t predicate;
    dispatch_once(&predicate, ^{
        instance = [[[self class] alloc] init];
        
    });
    return instance;
}

-(TTDCallSession *)startCall:(int)conversationType targetId:(NSString *)targetId to:(NSArray *)userIdList mediaType:(RCCallMediaType)type sessionDelegate:(id<RCCallSessionDelegate>)delegate extra:(NSString *)extra
{
    TTDCallSession *session = [[TTDCallSession alloc] init];
    session.conversationType = conversationType;
    session.targetId = targetId;
    session.mediaType = type;
    session.extra = extra;
    [session startCall];
    
    self.currentCallSession = session;
    
    return self.currentCallSession;
}

-(TTDCallSession *)receiveCall:(int)conversationType targetId:(NSString *)targetId to:(NSArray *)userIdList mediaType:(RCCallMediaType)type {
    TTDCallSession *session = [[TTDCallSession alloc] init];
    session.conversationType = conversationType;
    session.targetId = targetId;
    session.mediaType = type;
    
    session.callStatus = RCCallIncoming;
    self.currentCallSession = session;
    return self.currentCallSession;
}

- (void)dismissCallViewController:(UIViewController *)viewController {
    
//    if ([viewController isKindOfClass:[RCCallBaseViewController class]]) {
//        UIViewController *rootVC = viewController;
//        while (rootVC.parentViewController) {
//            rootVC = rootVC.parentViewController;
//        }
//        viewController = rootVC;
//    }
    
    for (UIWindow *window in self.callWindows) {
        if (window.rootViewController == viewController) {
            [window resignKeyWindow];
            window.hidden = YES;
            [[UIApplication sharedApplication].delegate.window makeKeyWindow];
            [self.callWindows removeObject:window];
            break;
        }
    }
    [viewController dismissViewControllerAnimated:YES completion:nil];
}

#pragma mark - 音视频Call IM消息处理
//-(void)receiveCallMessage:(RCMessage *)message
//{
//
//    RCDTestMessage *msg = (RCDTestMessage *)message.content;
//    // 被叫人 收到视频邀请
//    if ([msg.content isEqualToString:@"发起"]) {
//        TTDCallSession *session = [[TTDCallClient sharedTTDCallClient] receiveCall:ConversationType_PRIVATE targetId:message.senderUserId to:nil mediaType:RCCallMediaVideo];
//
//        RCCallSingleCallViewController *singleCallViewController = [[RCCallSingleCallViewController alloc] initWithIncomingCall:session];
//        UIViewController *vc = [UIApplication sharedApplication].keyWindow.rootViewController;
//        if (vc) {
//            dispatch_sync_main_safe(^{
//                [vc presentViewController:singleCallViewController animated:YES completion:nil];
//            })
//        }
//        // 发出已经振铃消息
//        [self sendCallMessageWithKey:@"振铃" success:nil];
//    }
//
//    // 主叫人 收到被叫人已被振铃消息（在线）
//    if ([msg.content isEqualToString:@"振铃"]) {
//    }
//    // 被叫人 收到 主叫人取消
//    if ([msg.content isEqualToString:@"取消"]) {
//        [self.currentCallSession hangup];
//    }
//    // 主叫人 收到 被叫人接受
//    if ([msg.content isEqualToString:@"接受"]) {
//        if (self.currentCallSession.callStatus != RCCallActive) {
//            [self.currentCallSession accept:self.currentCallSession.mediaType];
//        }
//    }
//    // 主叫人 收到 被叫人拒绝
//    if ([msg.content isEqualToString:@"拒绝"]) {
//        [self.currentCallSession hangup];
//    }
//    // 双方 收到对方 挂断
//    if ([msg.content isEqualToString:@"挂断"]) {
//        [self.currentCallSession hangup];
//    }
//
//}

-(void)sendCallMessageWithKey:(NSString *)key success:(void (^)(long messageId))successBlock
{
//    RCDTestMessage *msg = [RCDTestMessage messageWithContent:key];
//    [[RCIMClient sharedRCIMClient] sendMessage:self.currentCallSession.conversationType targetId:self.currentCallSession.targetId content:msg pushContent:nil pushData:nil success:^(long messageId) {
//        if (successBlock) {
//            successBlock(messageId);
//        }
//    } error:^(RCErrorCode nErrorCode, long messageId) {
//        NSLog(@"发送失败。消息ID：%ld， 错误码：%ld", messageId, (long)nErrorCode);
//    }];
}
@end
