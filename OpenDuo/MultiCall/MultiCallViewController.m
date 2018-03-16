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
    [self loadMediaEngine];
    
    self.videoSessions = [[NSMutableArray alloc] init];

    [self startLocalVideo];

    if (self.initiatorAccount) {
        self.callingLabel.text = [NSString stringWithFormat:@"%@ 接到通话请求 ...", self.initiatorAccount];
        [self playRing:@"ring"];
    }else{
        self.callingLabel.text = [NSString stringWithFormat:@"%@ 发起通话请求 ...", self.remoteUserIdArray];
        self.buttonStackView.axis = UILayoutConstraintAxisVertical;
        [self.acceptButton removeFromSuperview];
        
        //
        self.channel = [NSString stringWithFormat:@"c-%@",self.localAccount];
        // 查询用户在线状态，并发起 通话请求
        for (NSString *account in self.remoteUserIdArray) {
            [signalEngine queryUserStatus:account];
        }
        // 2秒后 或 全部得到结果弹出状态信息
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
    }
    else {
        // 取消所有 邀请
        [self cancelAllInvite];
    }
    
    if (self.callingLabel.hidden) {
        // already accepted
        [self leaveChannel];
    }
    else {
        // calling other
        [self stopRing];
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
    dispatch_async(dispatch_get_main_queue(), ^{
        BOOL allOffLine = YES;
        NSString *message;
        for (int i=0 ; i<self.remoteUserIdArray.count; i++) {
            NSString *account = self.remoteUserIdArray[i];
            if ([self.remoteUserStatus[account] intValue] > 0) {
                message = [NSString stringWithFormat:@"%@ %@ is online\n", message, account];
                allOffLine = NO;
            }else{
                message = [NSString stringWithFormat:@"%@ %@ is not online\n", message, account];
            }
        }
        
        [AlertUtil showAlert:message completion:^{
            if (allOffLine) {
                [self dismissViewControllerAnimated:NO completion:nil];
            }
        }];
    });
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
        if ([status intValue] == 0) {
            [weakSelf.remoteUserStatus setObject:@"0" forKey:@"name"];
        }
        else {
            // 发起视频请求
            [weakSelf.remoteUserStatus setObject:@"1" forKey:@"name"];
            NSDictionary *extraDic = @{@"_require_peer_online": @(1)};
            [signalEngine channelInviteUser2:weakSelf.channel account:name extra:[extraDic JSONString]];
        }
        if (weakSelf.remoteUserStatus.count == weakSelf.remoteUserIdArray.count) {
            [weakSelf alertUserStatus];
        }
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
        if (![channelID isEqualToString:weakSelf.channel]) {
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
//                    [weakSelf dismissViewControllerAnimated:NO completion:nil];
                }];
            }
            else {
//                [weakSelf dismissViewControllerAnimated:NO completion:nil];
            }
        });
    };
    
    // 对方已结束呼叫
    signalEngine.onInviteEndByPeer = ^(NSString* channelID, NSString *account, uint32_t uid, NSString *extra) {
        NSLog(@"onInviteEndByPeer, channel: %@, account: %@, uid: %u, extra: %@", channelID, account, uid, extra);
        if (![channelID isEqualToString:weakSelf.channel]) {
            return;
        }
        
//        dispatch_async(dispatch_get_main_queue(), ^() {
//            [weakSelf stopRing];
//            [weakSelf leaveChannel];
//            [weakSelf dismissViewControllerAnimated:NO completion:nil];
//        });
    };
}

//MARK: - AgoraRtcEngineDelegate
- (void)rtcEngine:(AgoraRtcEngineKit *)engine didOccurWarning:(AgoraWarningCode)warningCode {
    NSLog(@"rtcEngine:didOccurWarning: %ld", (long)warningCode);
}

- (void)rtcEngine:(AgoraRtcEngineKit *)engine didOccurError:(AgoraErrorCode)errorCode {
    NSLog(@"rtcEngine:didOccurError: %ld", (long)errorCode);
}

- (void)rtcEngine:(AgoraRtcEngineKit *)engine firstLocalVideoFrameWithSize:(CGSize)size elapsed:(NSInteger)elapsed {
    if (self.videoSessions.count) {
        [self updateInterface];
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
        [self updateInterface];
        
        if (deleteSession == self.fullSession) {
            self.fullSession = nil;
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
        [self updateInterface];
        return newSession;
    }
}

- (void)startLocalVideo {
    VideoSession *localSession = [[VideoSession alloc] initWithUid:self.localAccount.intValue];
    [self.videoSessions addObject:localSession];
    
    // add userView
    [self.localVideo addSubview:localSession.userView];
    localSession.userView.frame = self.localVideo.bounds;
    
    [mediaEngine startPreview];
}

#define kWidth                      [UIScreen mainScreen].bounds.size.width
#define kHeight                     [UIScreen mainScreen].bounds.size.height

- (void)updateInterface {
    int i = 0;
    for (VideoSession *session in self.videoSessions) {
//        [session.userView removeFromSuperview];
        int xCount = i%2;
        int yCount = i/2;
        int width = kWidth/2-20;
        session.userView.frame = CGRectMake(20+width*xCount, 64+120*yCount, width, 120);
        [self.view addSubview:session.userView];
        i+=1;
    }
    
    for (VideoSession *session in self.videoSessions) {
        if (session.uid == self.localAccount.intValue) {
            [mediaEngine setupLocalVideo:session.canvas];
        }else{
            [mediaEngine setRemoteVideoStream:session.uid type:AgoraVideoStreamTypeHigh];
        }
    }
    // 判断全屏
//    [self setStreamTypeForSessions:displaySessions fullSession:self.fullSession];
}
@end
