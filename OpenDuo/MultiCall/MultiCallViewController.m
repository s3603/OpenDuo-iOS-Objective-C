//
//  MultiCallViewController.m
//  OpenDuo
//
//  Created by 林英彬 on 2018/3/15.
//  Copyright © 2018年 Agora. All rights reserved.
//

#import "MultiCallViewController.h"
#import "VideoSession.h"

@interface MultiCallViewController ()

@property (strong, nonatomic) NSMutableArray<VideoSession *> *videoSessions;
@property (strong, nonatomic) VideoSession *fullSession;

@property (weak, nonatomic) IBOutlet UIView *remoteVideo;
@property (weak, nonatomic) IBOutlet UIView *localVideo;
@property (weak, nonatomic) IBOutlet UILabel *callingLabel;
@property (weak, nonatomic) IBOutlet UIStackView *buttonStackView;
@property (weak, nonatomic) IBOutlet UIButton *hangupButton;
@property (weak, nonatomic) IBOutlet UIButton *acceptButton;

@end

@implementation MultiCallViewController

- (void)viewDidLoad {
    [super viewDidLoad];
    // Do any additional setup after loading the view from its nib.
}

- (void)didReceiveMemoryWarning {
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

/*
#pragma mark - Navigation

// In a storyboard-based application, you will often want to do a little preparation before navigation
- (void)prepareForSegue:(UIStoryboardSegue *)segue sender:(id)sender {
    // Get the new view controller using [segue destinationViewController].
    // Pass the selected object to the new view controller.
}
*/

@end
