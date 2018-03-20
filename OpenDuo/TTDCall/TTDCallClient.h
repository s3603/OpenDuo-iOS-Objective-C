//
//  TTDCallClient.h
//  TTDLive
//
//  Created by 林英彬 on 2018/3/14.
//  Copyright © 2018年 linyingbin. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "TTDCallSession.h"

@interface TTDCallClient : NSObject

@property(nonatomic, strong) TTDCallSession *currentCallSession;
@property(nonatomic, assign) NSUInteger uid;

+ (instancetype)sharedTTDCallClient;

-(NSString *)localAccount;

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

- (void)sendCallMessageWithKey:(NSString *)key success:(void (^)(long messageId))successBlock;

- (void)loginWithAccount:(NSString *)account Success:(void(^)(uint32_t uid,int errorCode))success;
@end
