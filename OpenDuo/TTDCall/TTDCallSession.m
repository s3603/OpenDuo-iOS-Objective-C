//
//  TTDCallSession.m
//  TTDLive
//
//  Created by 林英彬 on 2018/3/14.
//  Copyright © 2018年 linyingbin. All rights reserved.
//

#import "TTDCallSession.h"
#import "KeyCenter.h"
#import "TTDCallClient.h"
#import "VideoSession.h"
#import <AgoraRtcEngineKit/AgoraRtcEngineKit.h>
#import <AgoraSigKit/AgoraSigKit.h>

@interface TTDCallSession () <AgoraRtcEngineDelegate>
{
    AgoraRtcEngineKit *mediaEngine;
}

@property (weak, nonatomic) id<RCCallSessionDelegate> sessionDelegate;
@property (strong, nonatomic) NSMutableArray<VideoSession *> *videoSessions;
@property (strong, nonatomic) VideoSession *fullSession;

@end

@implementation TTDCallSession

-(instancetype)init
{
    self = [super init];
    [self initAgoraSDK];
    
    return self;
}
-(void)initAgoraSDK
{
    mediaEngine = [AgoraRtcEngineKit sharedEngineWithAppId:[KeyCenter appId] delegate:self];
}

-(void)setDelegate:(id<RCCallSessionDelegate>)delegate
{
    self.sessionDelegate = delegate;
}

-(void)startCall
{
    [mediaEngine setChannelProfile:AgoraChannelProfileLiveBroadcasting];
    [mediaEngine enableVideo];
    [mediaEngine setClientRole:AgoraClientRoleBroadcaster];
    [mediaEngine setVideoProfile:AgoraVideoProfilePortrait240P swapWidthAndHeight:NO];

    int userId = 111;
    int code = 0; //[mediaEngine joinChannelByKey:nil channelName:@"10006" info:nil uid:userId joinSuccess:nil];
    if (code != 0) {
        dispatch_async(dispatch_get_main_queue(), ^{
            NSLog(@"%@",[NSString stringWithFormat:@"Join channel failed: %d", code]);
        });
    }else{
        NSLog(@"%@",[NSString stringWithFormat:@"Join channel %@", self.targetId]);
        self.callStatus = RCCallDialing;
    }
}

-(void)accept:(RCCallMediaType)type
{
    [mediaEngine setChannelProfile:AgoraChannelProfileLiveBroadcasting];
    if (type == RCCallMediaVideo) {
        [mediaEngine enableVideo];
    }
    [mediaEngine setClientRole:AgoraClientRoleBroadcaster];
    [mediaEngine setVideoProfile:AgoraVideoProfilePortrait240P swapWidthAndHeight:NO];
    
    [[TTDCallClient sharedTTDCallClient] sendCallMessageWithKey:@"接受" success:^(long messageId) {
        [self joinCall];
    }];

}
-(void)joinCall
{
//    int userId = [[TTDIMDataSource shareInstance].loginUserTest intValue];
//    int code = [mediaEngine joinChannelByKey:nil channelName:@"10006" info:nil uid:userId joinSuccess:nil];
//    if (code != 0) {
//        dispatch_async(dispatch_get_main_queue(), ^{
//            NSLog(@"%@",[NSString stringWithFormat:@"Join channel failed: %d", code]);
//        });
//    }else{
//        NSLog(@"%@",[NSString stringWithFormat:@"Join channel %@", self.targetId]);
//        self.callStatus = RCCallActive;
//        [_sessionDelegate callDidConnect];
//    }
}

-(void)hangup
{
    void(^successBlock)(long messageId) = ^void(long messageId) {
        [self hangupMessageSendSuccess];
    };
    
    if (self.callStatus == RCCallDialing) {
        // 取消
        [[TTDCallClient sharedTTDCallClient] sendCallMessageWithKey:@"取消" success:successBlock];
    }
    if (self.callStatus == RCCallIncoming || self.callStatus == RCCallRinging) {
        // 拒绝
        [[TTDCallClient sharedTTDCallClient] sendCallMessageWithKey:@"拒绝" success:successBlock];
    }
    if (self.callStatus == RCCallActive) {
        // 挂断
        [[TTDCallClient sharedTTDCallClient] sendCallMessageWithKey:@"挂断" success:successBlock];
    }
    if (self.callStatus == RCCallHangup) {
        
    }
}

-(void)hangupMessageSendSuccess
{
    [mediaEngine setupLocalVideo:nil];
    [mediaEngine stopPreview];
    if (self.callStatus == RCCallActive || self.callStatus == RCCallDialing) {
        [mediaEngine leaveChannel:nil];
        // 挂断
    }
    self.callStatus = RCCallHangup;

    [_sessionDelegate callDidDisconnect];
}

-(BOOL)changeMediaType:(RCCallMediaType)type
{
    if (type == RCCallMediaAudio) {
        [mediaEngine enableVideo];
    }else{
        [mediaEngine disableVideo];
    }
    return YES;
}

-(void)setVideoView:(UIView *)view userId:(NSString *)userId
{
    int loginUserId = 111;
    
    if (view) {
        if (loginUserId == [userId intValue]) {
            VideoSession *localSession = [VideoSession localSession];
            localSession.canvas.view = view;
            [mediaEngine setupLocalVideo:localSession.canvas];
        }else{
            VideoSession *userSession = [self videoSessionOfUid:[userId intValue]];
            userSession.canvas.view = view;
            [mediaEngine setupRemoteVideo:userSession.canvas];
        }
    }else{
        if (loginUserId == [userId intValue]) {
            [mediaEngine setupLocalVideo:nil];
        }else{
            [mediaEngine setupRemoteVideo:nil];
        }
    }
}

-(BOOL)switchCameraMode
{
    return [mediaEngine switchCamera];
}

-(BOOL)setMuted:(BOOL)muted
{
    [mediaEngine muteLocalAudioStream:muted];
    [mediaEngine muteLocalVideoStream:muted];
    return YES;
}

-(BOOL)setCameraEnabled:(BOOL)cameraEnabled
{
    return [mediaEngine muteLocalVideoStream:cameraEnabled];
}

-(BOOL)setSpeakerEnabled:(BOOL)speakerEnabled
{
    return [mediaEngine setEnableSpeakerphone:speakerEnabled];
}


#pragma mark - AgoraRtcEngineDelegate
- (void)rtcEngine:(AgoraRtcEngineKit * _Nonnull)engine didOccurWarning:(AgoraWarningCode)warningCode {
    NSLog(@"rtcEngine:didOccurWarning: %ld", (long)warningCode);
}

- (void)rtcEngine:(AgoraRtcEngineKit * _Nonnull)engine didOccurError:(AgoraErrorCode)errorCode {
    NSLog(@"rtcEngine:didOccurError: %ld", (long)errorCode);
}

- (void)rtcEngine:(AgoraRtcEngineKit *)engine didJoinChannel:(NSString*)channel withUid:(NSUInteger)uid elapsed:(NSInteger) elapsed {
    NSLog(@"rtcEngine:didJoinChannel: %@", channel);
    [[UIApplication sharedApplication] setIdleTimerDisabled:YES];
}

- (void)rtcEngine:(AgoraRtcEngineKit *)engine didJoinedOfUid:(NSUInteger)uid elapsed:(NSInteger)elapsed {
    NSLog(@"rtcEngine:didJoinedOfUid: %ld", (long)uid);
    [_sessionDelegate remoteUserDidJoin:[NSString stringWithFormat:@"%d",uid] mediaType:RCCallMediaVideo];
}

- (void)rtcEngine:(AgoraRtcEngineKit *)engine didOfflineOfUid:(NSUInteger)uid reason:(AgoraUserOfflineReason)reason {
    NSLog(@"rtcEngine:didOfflineOfUid: %ld", (long)uid);
    // only receive this callback if remote user logout unexpected
//    [self leaveChannel];
//    [self dismissViewControllerAnimated:NO completion:nil];
}

//MARK: - VideoSession

- (void)addLocalSession {
    VideoSession *localSession = [VideoSession localSession];
    [self.videoSessions addObject:localSession];
    [mediaEngine setupLocalVideo:localSession.canvas];
}

- (VideoSession *)fetchSessionOfUid:(NSUInteger)uid {
    for (VideoSession *session in self.videoSessions) {
        if (session.uid == uid) {
            return session;
        }
    }
    return nil;
}

- (VideoSession *)videoSessionOfUid:(NSUInteger)uid {
    VideoSession *fetchedSession = [self fetchSessionOfUid:uid];
    if (fetchedSession) {
        return fetchedSession;
    } else {
        VideoSession *newSession = [[VideoSession alloc] initWithUid:uid];
        [self.videoSessions addObject:newSession];
        return newSession;
    }
}

@end
