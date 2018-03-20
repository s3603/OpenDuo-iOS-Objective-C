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
#import "AlertUtil.h"

@interface TTDCallSession () <AgoraRtcEngineDelegate>
{
    AgoraRtcEngineKit *mediaEngine;
    AgoraAPI *signalEngine;
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
    signalEngine = [AgoraAPI getInstanceWithoutMedia:[KeyCenter appId]];

    NSDateFormatter *dateFormatter = [[NSDateFormatter alloc] init];
    [dateFormatter setDateFormat:@"yyyy-MM-dd ah-mm-ss"];
    NSString *logFilePath = [NSString stringWithFormat:@"%@/AgoraRtcEngine %@.log",
                             NSSearchPathForDirectoriesInDomains(NSDocumentDirectory,NSUserDomainMask, YES).firstObject,
                             [dateFormatter stringFromDate:[NSDate date]]];
    [mediaEngine setLogFile:logFilePath];
    //[mediaEngine setParameters:@"{\"rtc.log_filter\":65535}"];
    
    [mediaEngine enableVideo];
    [mediaEngine setVideoProfile:AgoraVideoProfileLandscape240P swapWidthAndHeight:NO];
    [mediaEngine enableAudioVolumeIndication:500 smooth:3];
}

-(void)setDelegate:(id<RCCallSessionDelegate>)delegate
{
    self.sessionDelegate = delegate;
}

-(void)accept:(RCCallMediaType)type
{
    [self joinCall];
//    [[TTDCallClient sharedTTDCallClient] sendCallMessageWithKey:@"接受" success:^(long messageId) {
//    }];
}

-(void)joinCall
{
    [signalEngine channelInviteAccept:self.channel account:self.inviter uid:0];

    int uid = [TTDCallClient sharedTTDCallClient].uid;
    NSString *key = [KeyCenter generateMediaKey:self.channel uid:uid expiredTime:0];
    int result = [mediaEngine joinChannelByToken:key channelId:self.channel info:nil uid:uid joinSuccess:nil];
    if (result != AgoraEcode_SUCCESS) {
        NSLog(@"Join channel failed: %d", result);
        [signalEngine channelInviteEnd:self.channel account:self.inviter uid:0];
        
        __weak typeof(self) weakSelf = self;
        [AlertUtil showAlert:[NSString stringWithFormat:@"Join channel failed"] completion:^{
//            [weakSelf dismissViewControllerAnimated:NO completion:nil];
        }];
    }else{
        [_sessionDelegate callDidConnect];
    }
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

-(void)setVideoView:(UIView *)view userId:(int)userId
{
    int loginUserId = [TTDCallClient sharedTTDCallClient].uid;
    
    if (view) {
        if (loginUserId == userId) {
            VideoSession *localSession = [VideoSession localSession];
            localSession.canvas.view = view;
            [mediaEngine setupLocalVideo:localSession.canvas];
        }else{
            VideoSession *userSession = [self videoSessionOfUid:userId];
            userSession.canvas.view = view;
            [mediaEngine setupRemoteVideo:userSession.canvas];
        }
    }else{
        if (loginUserId == userId) {
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

//MARK: - AgoraRtcEngineDelegate
- (void)rtcEngine:(AgoraRtcEngineKit *)engine didOccurWarning:(AgoraWarningCode)warningCode {
    NSLog(@"rtcEngine:didOccurWarning: %ld", (long)warningCode);
    static int count = 0;
    if (warningCode == 104) {
        count ++;
    }
    if (count == 10) {
//        [self leaveChannel];
    }
}

- (void)rtcEngine:(AgoraRtcEngineKit *)engine didOccurError:(AgoraErrorCode)errorCode {
    NSLog(@"rtcEngine:didOccurError: %ld", (long)errorCode);
}

-(void)rtcEngine:(AgoraRtcEngineKit *)engine didLeaveChannelWithStats:(AgoraChannelStats *)stats
{
    NSLog(@"rtcEngine:didLeaveChannelWithStats: %ld", (long)stats);
}

- (void)rtcEngine:(AgoraRtcEngineKit *)engine firstLocalVideoFrameWithSize:(CGSize)size elapsed:(NSInteger)elapsed {
    if (self.videoSessions.count) {
        [self.sessionDelegate updateInterface:self.videoSessions];
    }
}

- (void)rtcEngine:(AgoraRtcEngineKit *)engine didJoinChannel:(NSString*)channel withUid:(NSUInteger)uid elapsed:(NSInteger) elapsed {
    NSLog(@"rtcEngine:didJoinChannel: %@", channel);
    [[UIApplication sharedApplication] setIdleTimerDisabled:YES];
}

- (void)rtcEngine:(AgoraRtcEngineKit *)engine didJoinedOfUid:(NSUInteger)uid elapsed:(NSInteger)elapsed {
    NSLog(@"rtcEngine:didJoinedOfUid: %ld", (long)uid);
    VideoSession *userSession = [self videoSessionOfUid:uid];
    [mediaEngine setupRemoteVideo:userSession.canvas];
//    [_sessionDelegate remoteUserDidJoin:[NSString stringWithFormat:@"%d",uid] mediaType:RCCallMediaVideo];
}

- (void)rtcEngine:(AgoraRtcEngineKit *)engine didOfflineOfUid:(NSUInteger)uid reason:(AgoraUserOfflineReason)reason {
    NSLog(@"rtcEngine:didOfflineOfUid: %ld", (long)uid);
    // only receive this callback if remote user logout unexpected
    //    [self leaveChannel];
    //    [self dismissViewControllerAnimated:NO completion:nil];
    VideoSession *deleteSession;
    for (VideoSession *session in self.videoSessions) {
        if (session.uid == uid) {
            deleteSession = session;
        }
    }
    
    if (deleteSession) {
        [self.videoSessions removeObject:deleteSession];
        [deleteSession.userView removeFromSuperview];
        [self.sessionDelegate updateInterface:self.videoSessions];

        if (deleteSession == self.fullSession) {
            self.fullSession = nil;
        }
    }
}

- (void)rtcEngine:(AgoraRtcEngineKit *)engine
    didAudioMuted:(BOOL)muted byUid:(NSUInteger)uid
{
    VideoSession *fetchedSession = [self fetchSessionOfUid:uid];
    [fetchedSession.userView changeMicMuteState:muted];
}

- (void)rtcEngine:(AgoraRtcEngineKit *)engine
  didVideoEnabled:(BOOL)enabled byUid:(NSUInteger)uid
{
    
}

- (void)rtcEngine:(AgoraRtcEngineKit *)engine reportAudioVolumeIndicationOfSpeakers:
(NSArray*)speakers totalVolume:(NSInteger)totalVolume
{
    for (AgoraRtcAudioVolumeInfo *info in speakers) {
//        NSLog(@"reportAudioVolumeIndicationOfSpeakers： \n uid: %ld 音量: %ld",info.uid,info.volume);
    }
    
    for (VideoSession *session in self.videoSessions) {
        BOOL speaking = NO;
        for (AgoraRtcAudioVolumeInfo *info in speakers) {
            if (info.uid == session.uid) {
                if (info.volume > 15) {
                    speaking = YES;
                    // 正在发言
                    [session.userView changeSpeakState:YES];
                }
            }
        }
        if(!speaking) {
            // 未发言
            [session.userView changeSpeakState:NO];
        }
    }
}

//MARK: - VideoSession
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
        [self.sessionDelegate updateInterface:self.videoSessions];
        return newSession;
    }
}

- (void)startLocalVideo {
//    VideoSession *localSession = [[VideoSession alloc] initWithUid:self.localAccount.intValue];
//    [self.videoSessions addObject:localSession];
    
    // add userView
//    [self.localVideo addSubview:localSession.userView];
//    localSession.userView.frame = self.localVideo.bounds;
//    [localSession.userView setTapBlock:^(NSUInteger uid) {
//        [self showActionSheet:uid];
//    }];
    
    [mediaEngine startPreview];
}

@end