//
//  ChooseUserViewController.m
//  OpenDuo
//
//  Created by 林英彬 on 2018/3/15.
//  Copyright © 2018年 Agora. All rights reserved.
//

#import "ChooseUserViewController.h"
#import <AgoraSigKit/AgoraSigKit.h>
#import "KeyCenter.h"
#import "MultiCallViewController.h"

@interface ChooseUserViewController ()
{
    AgoraAPI *signalEngine;
}

@property (strong, nonatomic) IBOutletCollection(UIButton) NSArray *buttons;

@end

@implementation ChooseUserViewController

- (void)viewDidLoad {
    [super viewDidLoad];
    // Do any additional setup after loading the view.
    [self setupButtons];
    
    signalEngine = [AgoraAPI getInstanceWithoutMedia:[KeyCenter appId]];
}

-(void)viewWillAppear:(BOOL)animated
{
    [super viewWillAppear:animated];
    
    __weak typeof(self) weakSelf = self;

    signalEngine.onInviteReceived = ^(NSString* channelID, NSString *account, uint32_t uid, NSString *extra) {
        NSLog(@"onInviteReceived, channel: %@, account: %@, uid: %u, extra: %@", channelID, account, uid, extra);
        
        dispatch_async(dispatch_get_main_queue(), ^{
            [weakSelf showCallView:channelID remoteAccounts:@[account]];
        });
    };
}

- (void)didReceiveMemoryWarning {
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

-(void)setupButtons
{
    for (int i=0; i<self.buttons.count; i++) {
        UIButton *button = self.buttons[i];
        button.tag = 10000+i;
        [button setTitle:[NSString stringWithFormat:@"选择%d",10000+i] forState:UIControlStateNormal];
        [button setTitleColor:[UIColor grayColor] forState:UIControlStateNormal];
        [button setTitle:[NSString stringWithFormat:@"已选择%d",10000+i] forState:UIControlStateSelected];
//        [button setTitleColor:[UIColor redColor] forState:UIControlStateSelected];
        [button addTarget:self action:@selector(selectUser:) forControlEvents:UIControlEventTouchUpInside];
    }
}

- (void)selectUser:(UIButton *)sender
{
    [sender setSelected:!sender.selected];
}

- (IBAction)startMultiCall:(id)sender
{
    NSMutableArray *arr = [NSMutableArray new];
    for (UIButton *button in self.buttons) {
        if (button.isSelected) {
            NSString *account = [NSString stringWithFormat:@"%ld",(long)[button tag]];
            [arr addObject:account];
        }
    }
    [self showCallView:nil remoteAccounts:arr];

}

- (void)showCallView:(NSString* )channel remoteAccounts:(NSArray *)accounts {
    MultiCallViewController *callVC = [[MultiCallViewController alloc] initWithNibName:@"MultiCallViewController" bundle:nil];
    callVC.localAccount = self.localAccount;
    if (channel) { // 接到通话请求
        callVC.channel = channel;
        callVC.initiatorAccount = accounts.firstObject;
    }else{ // 发起者
        callVC.remoteUserIdArray = accounts;
    }
    [self presentViewController:callVC animated:NO completion:nil];
}

@end
