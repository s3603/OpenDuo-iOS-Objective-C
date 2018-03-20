//
//  TTDCallClient.h
//  TTDLive
//
//  Created by 林英彬 on 2018/3/14.
//  Copyright © 2018年 linyingbin. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "TTDCallSession.h"

@protocol RCCallReceiveDelegate <NSObject>

/*!
 接收到通话呼入的回调
 
 @param callSession 呼入的通话实体
 */
- (void)didReceiveCall:(TTDCallSession *)callSession;

/*!
 接收到通话呼入的远程通知的回调
 
 @param callId        呼入通话的唯一值
 @param inviterUserId 通话邀请者的UserId
 @param mediaType     通话的媒体类型
 @param userIdList    被邀请者的UserId列表
 @param userDict      远程推送包含的其他扩展信息
 */
- (void)didReceiveCallRemoteNotification:(NSString *)callId
                           inviterUserId:(NSString *)inviterUserId
                               mediaType:(RCCallMediaType)mediaType
                              userIdList:(NSArray *)userIdList
                                userDict:(NSDictionary *)userDict;

/*!
 接收到取消通话的远程通知的回调
 
 @param callId        呼入通话的唯一值
 @param inviterUserId 通话邀请者的UserId
 @param mediaType     通话的媒体类型
 @param userIdList    被邀请者的UserId列表
 */
- (void)didCancelCallRemoteNotification:(NSString *)callId
                          inviterUserId:(NSString *)inviterUserId
                              mediaType:(RCCallMediaType)mediaType
                             userIdList:(NSArray *)userIdList;

@end

@interface TTDCallClient : NSObject

@property(nonatomic, strong) TTDCallSession *currentCallSession;

+ (instancetype)sharedTTDCallClient;

/*!
 发起一个通话
 
 @param conversationType 会话类型
 @param targetId         目标会话ID
 @param userIdList       邀请的用户ID列表
 @param type             发起的通话媒体类型
 @param delegate         通话监听
 @param extra            附件信息
 
 @return 呼出的通话实体
 */
- (TTDCallSession *)startCall:(int)conversationType
                    targetId:(NSString *)targetId
                          to:(NSArray *)userIdList
                   mediaType:(RCCallMediaType)type
             sessionDelegate:(id<RCCallSessionDelegate>)delegate
                       extra:(NSString *)extra;

-(TTDCallSession *)receiveCall:(int)conversationType targetId:(NSString *)targetId to:(NSArray *)userIdList mediaType:(RCCallMediaType)type ;

- (void)dismissCallViewController:(UIViewController *)viewController;

- (void)sendCallMessageWithKey:(NSString *)key success:(void (^)(long messageId))successBlock;
@end
