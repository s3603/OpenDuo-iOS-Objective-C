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
#import "SelectedUserViewController.h"
#import "TTDCallClient.h"

@interface MultiCallViewController () <RCCallSessionDelegate>
{
    AVAudioPlayer *audioPlayer;
}

@property (nonatomic, copy) NSArray *remoteUserIdArray;

@property (weak, nonatomic) IBOutlet UIView *localVideo;
@property (weak, nonatomic) IBOutlet UILabel *callingLabel;
@property (weak, nonatomic) IBOutlet UIStackView *buttonStackView;
@property (weak, nonatomic) IBOutlet UIButton *hangupButton;
@property (weak, nonatomic) IBOutlet UIButton *acceptButton;
@property (weak, nonatomic) IBOutlet UIButton *micButton;

@end

@implementation MultiCallViewController

-(void)startCallTo:(NSArray *)userIdList
{
    self.remoteUserIdArray = userIdList;
    [[TTDCallClient sharedTTDCallClient] startCall:0 targetId:@"test" to:userIdList mediaType:RCCallMediaVideo sessionDelegate:self extra:nil];
}

-(void)showWithCall:(TTDCallSession *)callSession
{
    self.callSession = callSession;
    [self.callSession setDelegate:self];
    if (self.callSession.callStatus == RCCallIncoming || self.callSession.callStatus == RCCallRinging)
    {
        // 振铃
    }
}

- (void)viewDidLoad {
    [super viewDidLoad];
    // Do any additional setup after loading the view from its nib.
//    [self loadMediaEngine];
//    [self startLocalVideo];

    if (self.remoteUserIdArray.count == 0) {
        self.callingLabel.text = [NSString stringWithFormat:@" 接到%@的通话请求", self.callSession];
        [self playRing:@"ring"];
    }else{
        
        self.callingLabel.text = [NSString stringWithFormat:@"对 %@ 发起通话请求", [self.remoteUserIdArray componentsJoinedByString:@","]];
        self.buttonStackView.axis = UILayoutConstraintAxisVertical;
        [self.acceptButton removeFromSuperview];
        
        //
//        self.channel = [NSString stringWithFormat:@"c-%@",self.callSession.channel];
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

-(void)viewWillAppear:(BOOL)animated
{
    [super viewWillAppear:animated];    
}

- (void)viewWillDisappear:(BOOL)animated {
    [super viewWillDisappear:animated];
    
//    [AgoraRtcEngineKit sharedEngineWithAppId:[KeyCenter appId] delegate:nil];
//
//    signalEngine.onError = nil;
//    signalEngine.onQueryUserStatusResult = nil;
//    signalEngine.onInviteReceivedByPeer = nil;
//    signalEngine.onInviteFailed = nil;
//    signalEngine.onInviteAcceptedByPeer = nil;
//    signalEngine.onInviteRefusedByPeer = nil;
//    signalEngine.onInviteEndByPeer = nil;
}

- (void)applicationWillTerminate:(NSNotification *)noti
{
    [self cancelAllInvite];
}

-(void)cancelAllInvite
{
    [self.callSession hangup];
    // 我是 发起人
//    for (NSString *account in self.remoteUserIdArray) {
//        [signalEngine channelInviteEnd:self.channel account:account uid:0];
//    }
}

- (IBAction)muteButtonClicked:(UIButton *)sender {
    [sender setSelected:!sender.isSelected];
    [self.callSession setMuted:sender.isSelected];
}

- (IBAction)switchCameraButtonClicked:(UIButton *)sender {
    [sender setSelected:!sender.isSelected];
    [self.callSession switchCameraMode];
}

- (IBAction)hangupButtonClicked:(UIButton *)sender {
//    if (self.initiatorAccount) {
//        // called by other
//        NSDictionary *extraDic = @{@"status": @(0)};
//        [signalEngine channelInviteRefuse:self.channel account:self.initiatorAccount uid:0 extra:[extraDic JSONString]];
//    }
//    else {
//        // 取消所有 邀请
//        [self cancelAllInvite];
//    }
//
//    if (self.callingLabel.hidden) {
//        // already accepted
//        [self leaveChannel];
//    }
//    else {
//        // calling other
//        [self stopRing];
//    }
    [self.callSession hangup];
    
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
    [self.callSession accept:0];
    
    self.callingLabel.hidden = YES;
    self.buttonStackView.axis = UILayoutConstraintAxisVertical;
    [self.acceptButton removeFromSuperview];
    
//    [self stopRing];
//    [self joinChannel];
}

- (void)leaveChannel {
//    if (mediaEngine) {
//        [[UIApplication sharedApplication] setIdleTimerDisabled:NO];
//        [mediaEngine stopPreview];
//        [mediaEngine setupLocalVideo:nil];
//        [mediaEngine leaveChannel:nil];
//        mediaEngine = nil;
//    }
}

- (IBAction)addUserButtonClicked:(id)sender
{
    SelectedUserViewController *selectUserVC = [[SelectedUserViewController alloc] initWithNibName:@"SelectedUserViewController" bundle:nil];
    selectUserVC.channelId = self.callSession.channel;
    [self presentViewController:selectUserVC animated:YES completion:nil ];
}

#define kWidth                      [UIScreen mainScreen].bounds.size.width
#define kHeight                     [UIScreen mainScreen].bounds.size.height

- (void)updateInterface:(NSArray *)videoSessions {
    int i = 0;
    for (VideoSession *session in videoSessions) {
//        [session.userView removeFromSuperview];
        int xCount = i%2;
        int yCount = i/2;
        int width = kWidth/2-20;
        session.userView.frame = CGRectMake(20+width*xCount, 120+120*yCount, width, 120);
        [self.view addSubview:session.userView];
        [session.userView setTapBlock:^(NSUInteger uid) {
            [self showActionSheet:uid];
        }];
        [self.callSession setVideoView:session.userView.hostingView userId:session.uid];
        i+=1;
    }
//     判断全屏
//    [self setStreamTypeForSessions:displaySessions fullSession:self.fullSession];
}

-(void)showActionSheet:(NSUInteger)uid
{
    UIAlertController *sheet = [UIAlertController alertControllerWithTitle:nil message:nil preferredStyle:UIAlertControllerStyleActionSheet];
    UIAlertAction *kick = [UIAlertAction actionWithTitle:@"踢出聊天室" style:UIAlertActionStyleDefault handler:^(UIAlertAction * _Nonnull action) {
        [self sendMessage:@"kick" To:uid];
    }];
    UIAlertAction *closeMic = [UIAlertAction actionWithTitle:@"关闭麦克风" style:UIAlertActionStyleDefault handler:^(UIAlertAction * _Nonnull action) {
        [self sendMessage:@"closeMic" To:uid];
    }];
    UIAlertAction *closeVideo = [UIAlertAction actionWithTitle:@"关闭视频" style:UIAlertActionStyleDefault handler:^(UIAlertAction * _Nonnull action) {
        [self sendMessage:@"closeVideo" To:uid];
    }];
    UIAlertAction *openVideo = [UIAlertAction actionWithTitle:@"打开摄像头" style:UIAlertActionStyleDefault handler:^(UIAlertAction * _Nonnull action) {
        [self sendMessage:@"openVideo" To:uid];
    }];
    UIAlertAction *openMic = [UIAlertAction actionWithTitle:@"打开麦克风" style:UIAlertActionStyleDefault handler:^(UIAlertAction * _Nonnull action) {
        [self sendMessage:@"openMic" To:uid];
    }];
    
    UIAlertAction *cancel = [UIAlertAction actionWithTitle:@"Cancel" style:UIAlertActionStyleCancel handler:nil];
    [sheet addAction:kick];
    [sheet addAction:closeMic];
    [sheet addAction:closeVideo];
    [sheet addAction:openVideo];
    [sheet addAction:openMic];
    [sheet addAction:cancel];
//    [sheet popoverPresentationController].sourceView = self.popoverSourceView;
    [sheet popoverPresentationController].permittedArrowDirections = UIPopoverArrowDirectionUp;
    [self presentViewController:sheet animated:YES completion:nil];
}

-(void)sendMessage:(NSString *)key To:(NSUInteger)uid
{
    NSString *name = [NSString stringWithFormat:@"%ld",uid];
//    [signalEngine messageInstantSend:name uid:uid msg:key msgID:nil];
}

//MARK: - RCCallSessionDelegate
/*!
 通话已接通
 */
- (void)callDidConnect;
{
    
}

/*!
 通话已结束
 */
- (void)callDidDisconnect;
{
    
}

/*!
 对端用户正在振铃
 
 @param userId 用户ID
 */
- (void)remoteUserDidRing:(NSString *)userId;
{
    
}

/*!
 有用户被邀请加入通话
 
 @param userId    被邀请的用户ID
 @param mediaType 希望被邀请者使用的媒体类型
 */
- (void)remoteUserDidInvite:(NSString *)userId mediaType:(RCCallMediaType)mediaType;
{
    
}

/*!
 对端用户加入了通话
 
 @param userId    用户ID
 @param mediaType 用户的媒体类型
 */
- (void)remoteUserDidJoin:(NSString *)userId mediaType:(RCCallMediaType)mediaType;
{
    
}

/*!
 对端用户切换了媒体类型
 
 @param userId    用户ID
 @param mediaType 切换至的媒体类型
 */
- (void)remoteUserDidChangeMediaType:(NSString *)userId mediaType:(RCCallMediaType)mediaType;
{
    
}

/*!
 对端用户开启或关闭了摄像头的状态
 
 @param disabled  是否关闭摄像头
 @param userId    用户ID
 */
- (void)remoteUserDidDisableCamera:(BOOL)disabled byUser:(NSString *)userId;
{
    
}

/*!
 对端用户挂断
 
 @param userId 用户ID
 @param reason 挂断的原因
 */
- (void)remoteUserDidLeft:(NSString *)userId reason:(RCCallDisconnectReason)reason;
{
    
}

/*!
 彩铃
 */
- (void)shouldAlertForWaitingRemoteResponse;
{
    
}

/*!
 来电铃声
 */
- (void)shouldRingForIncomingCall;
{
    
}

/*!
 停止播放铃声(通话接通或挂断)
 */
- (void)shouldStopAlertAndRing;
{
    
}

/*!
 通话过程中的错误回调
 
 @param error 错误码
 
 @warning
 这个接口回调的错误码主要是为了提供必要的log以及提示用户，如果是不可恢复的错误，SDK会挂断电话并回调callDidDisconnect，App可以在callDidDisconnect中统一处理通话结束的逻辑。
 */
- (void)errorDidOccur:(RCCallErrorCode)error;
{
    
}

/*!
 当前通话网络状态的回调，该回调方法每两秒触发一次
 
 @param txQuality   上行网络质量
 @param rxQuality   下行网络质量
 */
- (void)networkTxQuality:(RCCallQuality)txQuality rxQuality:(RCCallQuality)rxQuality;
{
    
}


@end
