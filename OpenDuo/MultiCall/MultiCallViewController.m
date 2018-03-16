//
//  MultiCallViewController.m
//  OpenDuo
//
//  Created by 林英彬 on 2018/3/15.
//  Copyright © 2018年 Agora. All rights reserved.
//

#import "MultiCallViewController.h"
#import "VideoSession.h"
#import <AgoraRtcEngineKit/AgoraRtcEngineKit.h>
#import <AgoraSigKit/AgoraSigKit.h>
#import "KeyCenter.h"
#import "AlertUtil.h"
#import "NSObject+JSONString.h"

@interface MultiCallViewController () <AgoraRtcEngineDelegate>
{
    AVAudioPlayer *audioPlayer;
    AgoraAPI *signalEngine;
    AgoraRtcEngineKit *mediaEngine;
}

@property (strong, nonatomic) NSMutableArray<VideoSession *> *videoSessions;
@property (strong, nonatomic) VideoSession *fullSession;

@property (weak, nonatomic) IBOutlet UIView *remoteVideo;
@property (weak, nonatomic) IBOutlet UIView *localVideo;
@property (weak, nonatomic) IBOutlet UILabel *callingLabel;
@property (weak, nonatomic) IBOutlet UIStackView *buttonStackView;
@property (weak, nonatomic) IBOutlet UIButton *hangupButton;
@property (weak, nonatomic) IBOutlet UIButton *acceptButton;

@property (strong, nonatomic) NSMutableDictionary *remoteUserStatus;

@end

@implementation MultiCallViewController

- (void)viewDidLoad {
    [super viewDidLoad];
    // Do any additional setup after loading the view from its nib.
    [self loadSignalEngine];
    
    if (self.initiatorAccount) {
        self.callingLabel.text = [NSString stringWithFormat:@"%@ 接到通话请求 ...", self.initiatorAccount];
        [self loadMediaEngine];
        [self startLocalVideo];
        [self playRing:@"ring"];
    }else{
        self.callingLabel.text = [NSString stringWithFormat:@"%@ 发起通话请求 ...", self.remoteUserIdArray];
        self.buttonStackView.axis = UILayoutConstraintAxisVertical;
        [self.acceptButton removeFromSuperview];
        // 查询用户在线状态，并发起 通话请求
        for (NSString *account in self.remoteUserIdArray) {
            [signalEngine queryUserStatus:account];
        }
        // 2秒后 或 全部得到结果弹出状态信息
        
        // 准备视频
        [self loadMediaEngine];
        [self startLocalVideo];
    }
    [[NSNotificationCenter defaultCenter] addObserver:self
                                             selector:@selector(applicationWillTerminate:)
                                                 name:UIApplicationWillTerminateNotification
                                               object:nil];

}

- (void)didReceiveMemoryWarning {
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

- (void)viewWillDisappear:(BOOL)animated {
    [super viewWillDisappear:animated];
    
    [AgoraRtcEngineKit sharedEngineWithAppId:[KeyCenter appId] delegate:nil];
    
    signalEngine.onError = nil;
    signalEngine.onQueryUserStatusResult = nil;
    signalEngine.onInviteReceivedByPeer = nil;
    signalEngine.onInviteFailed = nil;
    signalEngine.onInviteAcceptedByPeer = nil;
    signalEngine.onInviteRefusedByPeer = nil;
    signalEngine.onInviteEndByPeer = nil;
}

- (void)applicationWillTerminate:(NSNotification *)noti
{
    [self cancelAllInvite];
}

-(void)cancelAllInvite
{
    // 我是 发起人
    if (!self.initiatorAccount) {
        for (NSString *account in self.remoteUserIdArray) {
            [signalEngine channelInviteEnd:self.channel account:account uid:0];
        }
    }
}

- (IBAction)muteButtonClicked:(UIButton *)sender {
    if (mediaEngine) {
        [sender setSelected:!sender.isSelected];
        [mediaEngine muteLocalAudioStream:sender.isSelected];
    }
}

- (IBAction)switchCameraButtonClicked:(UIButton *)sender {
    if (mediaEngine) {
        [sender setSelected:!sender.isSelected];
        [mediaEngine switchCamera];
    }
}

- (IBAction)hangupButtonClicked:(UIButton *)sender {
    if (self.initiatorAccount) {
        // called by other
        NSDictionary *extraDic = @{@"status": @(0)};
        [signalEngine channelInviteRefuse:self.channel account:self.initiatorAccount uid:0 extra:[extraDic JSONString]];
        
        [self stopRing];
    }
    else {
        // 取消所有 邀请
        [self cancelAllInvite];
        
        if (self.callingLabel.hidden) {
            // already accepted
            [self leaveChannel];
        }
        else {
            // calling other
            [self stopRing];
        }
    }
    
    [self dismissViewControllerAnimated:NO completion:nil];
}

- (void)playRing:(NSString *)name {
    AVAudioSession *audioSession = [AVAudioSession sharedInstance];
    [audioSession setCategory:AVAudioSessionCategoryPlayback error:nil];
    [audioSession setActive:YES error:nil];
    
    NSURL *path = [[NSBundle mainBundle] URLForResource:name withExtension:@"mp3"];
    audioPlayer = [[AVAudioPlayer alloc] initWithContentsOfURL:path error:nil];
    audioPlayer.numberOfLoops = 1;
    [audioPlayer play];
}

- (void)stopRing {
    if (audioPlayer) {
        [audioPlayer stop];
        audioPlayer = nil;
    }
}

- (IBAction)acceptButtonClicked:(UIButton *)sender {
    [signalEngine channelInviteAccept:self.channel account:self.initiatorAccount uid:0];
    
    self.callingLabel.hidden = YES;
    self.buttonStackView.axis = UILayoutConstraintAxisVertical;
    [self.acceptButton removeFromSuperview];
    
    [self stopRing];
    [self joinChannel];
}

- (void)loadMediaEngine {
    mediaEngine = [AgoraRtcEngineKit sharedEngineWithAppId:[KeyCenter appId] delegate:self];
    
    NSDateFormatter *dateFormatter = [[NSDateFormatter alloc] init];
    [dateFormatter setDateFormat:@"yyyy-MM-dd ah-mm-ss"];
    NSString *logFilePath = [NSString stringWithFormat:@"%@/AgoraRtcEngine %@.log",
                             NSSearchPathForDirectoriesInDomains(NSDocumentDirectory,NSUserDomainMask, YES).firstObject,
                             [dateFormatter stringFromDate:[NSDate date]]];
    [mediaEngine setLogFile:logFilePath];
    //[mediaEngine setParameters:@"{\"rtc.log_filter\":65535}"];
    
    [mediaEngine enableVideo];
    [mediaEngine setVideoProfile:AgoraVideoProfileLandscape240P swapWidthAndHeight:NO];
}

- (void)startLocalVideo {
    AgoraRtcVideoCanvas *videoCanvas = [[AgoraRtcVideoCanvas alloc] init];
    videoCanvas.uid = 0;
    videoCanvas.view = self.localVideo;
    videoCanvas.renderMode = AgoraVideoRenderModeHidden;
    [mediaEngine setupLocalVideo:videoCanvas];
    [mediaEngine startPreview];
}

- (void)joinChannel {
    NSString *key = [KeyCenter generateMediaKey:self.channel uid:self.localAccount.intValue expiredTime:0];
    int result = [mediaEngine joinChannelByToken:key channelId:self.channel info:nil uid:self.localAccount.intValue joinSuccess:nil];
    if (result != AgoraEcode_SUCCESS) {
        NSLog(@"Join channel failed: %d", result);
        
        [signalEngine channelInviteEnd:self.channel account:self.initiatorAccount uid:0];
        
        __weak typeof(self) weakSelf = self;
        [AlertUtil showAlert:[NSString stringWithFormat:@"Join channel failed"] completion:^{
            [weakSelf dismissViewControllerAnimated:NO completion:nil];
        }];
    }
}

- (void)leaveChannel {
    if (mediaEngine) {
        [[UIApplication sharedApplication] setIdleTimerDisabled:NO];
        [mediaEngine stopPreview];
        [mediaEngine setupLocalVideo:nil];
        [mediaEngine leaveChannel:nil];
        mediaEngine = nil;
    }
}

-(void)alertUserStatus
{
    
}

//MARK: - AgoraAPI 监听
- (void)loadSignalEngine {
    signalEngine = [AgoraAPI getInstanceWithoutMedia:[KeyCenter appId]];
    
    __weak typeof(self) weakSelf = self;
    
    signalEngine.onError = ^(NSString* name, AgoraEcode ecode, NSString* desc) {
        NSLog(@"onError, name: %@, code:%lu, desc: %@", name, (unsigned long)ecode, desc);
        if ([name isEqualToString:@"query_user_status"]) {
            dispatch_async(dispatch_get_main_queue(), ^{
                [AlertUtil showAlert:desc completion:^{
                    [weakSelf dismissViewControllerAnimated:NO completion:nil];
                }];
            });
        }
    };
    
    // 查询用户是否在线
    signalEngine.onQueryUserStatusResult = ^(NSString *name, NSString *status) {
        NSLog(@"onQueryUserStatusResult, name: %@, status: %@", name, status);
        dispatch_async(dispatch_get_main_queue(), ^{
            if ([status intValue] == 0) {
//                NSString *message = [NSString stringWithFormat:@"%@ is not online", name];
//                [AlertUtil showAlert:message completion:^{
//                    [weakSelf dismissViewControllerAnimated:NO completion:nil];
//                }];
                [weakSelf.remoteUserStatus setObject:@"0" forKey:@"name"];
            }
            else {
                // 发起视频请求
                [weakSelf.remoteUserStatus setObject:@"1" forKey:@"name"];
                NSDictionary *extraDic = @{@"_require_peer_online": @(1)};
                [signalEngine channelInviteUser2:weakSelf.channel account:name extra:[extraDic JSONString]];
            }
        });
    };
    
    // 远端 收到呼叫
    signalEngine.onInviteReceivedByPeer = ^(NSString* channelID, NSString *account, uint32_t uid) {
        NSLog(@"onInviteReceivedByPeer, channel: %@, account: %@, uid: %u", channelID, account, uid);
        if (![channelID isEqualToString:weakSelf.channel] || ![account isEqualToString:weakSelf.initiatorAccount]) {
            // 不是当前房间的 邀请
            return;
        }
        
        dispatch_async(dispatch_get_main_queue(), ^{
            [weakSelf playRing:@"tones"];
        });
    };
    
    // 呼叫失败
    signalEngine.onInviteFailed = ^(NSString* channelID, NSString* account, uint32_t uid, AgoraEcode ecode, NSString *extra) {
        NSLog(@"Call %@ failed, ecode: %lu", account, (unsigned long)ecode);
        if (![channelID isEqualToString:weakSelf.channel]) {
            return;
        }
        
//        dispatch_async(dispatch_get_main_queue(), ^{
//            [weakSelf leaveChannel];
//
//            [AlertUtil showAlert:@"Call failed" completion:^{
//                [weakSelf dismissViewControllerAnimated:NO completion:nil];
//            }];
//        });
    };
    
    // 远端接受呼叫
    signalEngine.onInviteAcceptedByPeer = ^(NSString* channelID, NSString *account, uint32_t uid, NSString *extra) {
        NSLog(@"onInviteAcceptedByPeer, channel: %@, account: %@, uid: %u, extra: %@", channelID, account, uid, extra);
        if (![channelID isEqualToString:weakSelf.channel] || ![account isEqualToString:weakSelf.initiatorAccount]) {
            return;
        }
        
        dispatch_async(dispatch_get_main_queue(), ^() {
            weakSelf.callingLabel.hidden = YES;
            [weakSelf stopRing];
            [weakSelf joinChannel];
        });
    };
    
    // 对方已拒绝呼叫
    signalEngine.onInviteRefusedByPeer = ^(NSString* channelID, NSString *account, uint32_t uid, NSString *extra) {
        NSLog(@"onInviteRefusedByPeer, channel: %@, account: %@, uid: %u, extra: %@", channelID, account, uid, extra);
        if (![channelID isEqualToString:weakSelf.channel] || ![account isEqualToString:weakSelf.initiatorAccount]) {
            return;
        }
        
        dispatch_async(dispatch_get_main_queue(), ^{
            [weakSelf stopRing];
            [weakSelf leaveChannel];
            
            NSData *data = [extra dataUsingEncoding:NSUTF8StringEncoding];
            NSDictionary *dic = [NSJSONSerialization JSONObjectWithData:data options:0 error:nil];
            if ([dic[@"status"] intValue] == 1) {
                NSString *message = [NSString stringWithFormat:@"%@ is busy", account];
                [AlertUtil showAlert:message completion:^{
                    [weakSelf dismissViewControllerAnimated:NO completion:nil];
                }];
            }
            else {
                [weakSelf dismissViewControllerAnimated:NO completion:nil];
            }
        });
    };
    
    // 对方已结束呼叫
    signalEngine.onInviteEndByPeer = ^(NSString* channelID, NSString *account, uint32_t uid, NSString *extra) {
        NSLog(@"onInviteEndByPeer, channel: %@, account: %@, uid: %u, extra: %@", channelID, account, uid, extra);
        if (![channelID isEqualToString:weakSelf.channel]) {
            return;
        }
        
        dispatch_async(dispatch_get_main_queue(), ^() {
            [weakSelf stopRing];
            [weakSelf leaveChannel];
            [weakSelf dismissViewControllerAnimated:NO completion:nil];
        });
    };
}

//MARK: - AgoraRtcEngineDelegate
- (void)rtcEngine:(AgoraRtcEngineKit *)engine didOccurWarning:(AgoraWarningCode)warningCode {
    NSLog(@"rtcEngine:didOccurWarning: %ld", (long)warningCode);
}

- (void)rtcEngine:(AgoraRtcEngineKit *)engine didOccurError:(AgoraErrorCode)errorCode {
    NSLog(@"rtcEngine:didOccurError: %ld", (long)errorCode);
}

- (void)rtcEngine:(AgoraRtcEngineKit *)engine didJoinChannel:(NSString*)channel withUid:(NSUInteger)uid elapsed:(NSInteger) elapsed {
    NSLog(@"rtcEngine:didJoinChannel: %@", channel);
    [[UIApplication sharedApplication] setIdleTimerDisabled:YES];
}

- (void)rtcEngine:(AgoraRtcEngineKit *)engine didJoinedOfUid:(NSUInteger)uid elapsed:(NSInteger)elapsed {
    NSLog(@"rtcEngine:didJoinedOfUid: %ld", (long)uid);
    AgoraRtcVideoCanvas *videoCanvas = [[AgoraRtcVideoCanvas alloc] init];
    videoCanvas.uid = uid;
    videoCanvas.view = self.remoteVideo;
    videoCanvas.renderMode = AgoraVideoRenderModeHidden;
    [mediaEngine setupRemoteVideo:videoCanvas];
}

- (void)rtcEngine:(AgoraRtcEngineKit *)engine didOfflineOfUid:(NSUInteger)uid reason:(AgoraUserOfflineReason)reason {
    NSLog(@"rtcEngine:didOfflineOfUid: %ld", (long)uid);
    // only receive this callback if remote user logout unexpected
    [self leaveChannel];
    [self dismissViewControllerAnimated:NO completion:nil];
}

@end
