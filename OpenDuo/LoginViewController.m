//
//  ViewController.m
//  OpenDuo
//
//  Created by suleyu on 2017/10/31.
//  Copyright © 2017 Agora. All rights reserved.
//

#import "LoginViewController.h"
#import "DialViewController.h"
#import "AlertUtil.h"
#import "KeyCenter.h"
#import <AgoraSigKit/AgoraSigKit.h>
#import "ChooseUserViewController.h"

@interface LoginViewController ()
{
    AgoraAPI *signalEngine;
    NSString *multiLocalAccount;
}

@property (weak, nonatomic) IBOutlet UITextField *accountTextField;

@property (strong, nonatomic) IBOutletCollection(UIButton) NSArray *buttons;

@end

@implementation LoginViewController

- (void)viewDidLoad {
    [super viewDidLoad];
    
    signalEngine = [AgoraAPI getInstanceWithoutMedia:[KeyCenter appId]];
    
    [self setupButtons];
}

- (void)didReceiveMemoryWarning {
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

- (void)viewDidAppear:(BOOL)animated {
    [super viewDidAppear:animated];
    
    __weak typeof(self) weakSelf = self;
    
    signalEngine.onLoginSuccess = ^(uint32_t uid, int fd) {
        NSLog(@"Login successfully, uid: %u", uid);
        dispatch_async(dispatch_get_main_queue(), ^{
            if (multiLocalAccount) {
                [weakSelf pushMultiCall];
            }else{
                [weakSelf performSegueWithIdentifier:@"ShowDialView" sender:@(uid)];
            }
        });
    };
    
    signalEngine.onLoginFailed = ^(AgoraEcode ecode) {
        NSLog(@"Login failed, error: %lu", (unsigned long)ecode);
        dispatch_async(dispatch_get_main_queue(), ^{
            [AlertUtil showAlert:@"Login failed"];
        });
    };
}

- (void)viewWillDisappear:(BOOL)animated {
    [super viewWillDisappear:animated];
    signalEngine.onLoginSuccess = nil;
    signalEngine.onLoginFailed = nil;
}

- (void)prepareForSegue:(UIStoryboardSegue *)segue sender:(id)sender {
    if ([segue.identifier isEqualToString:@"ShowDialView"]) {
        DialViewController *dialVC = segue.destinationViewController;
        dialVC.localUID = [sender unsignedIntValue];
        dialVC.localAccount = self.accountTextField.text;
    }
}

- (IBAction)loginButtonClicked:(id)sender {
    NSString *account = self.accountTextField.text;
    if (account.length > 0) {
        [self.accountTextField resignFirstResponder];
        [signalEngine login:[KeyCenter appId]
                       account:account
                         token:[KeyCenter generateSignalToken:account expiredTime:3600]
                           uid:0
                      deviceID:nil];
    }
}

-(void)setupButtons
{
    for (int i=0; i<self.buttons.count; i++) {
        UIButton *button = self.buttons[i];
        button.tag = 10000+i;
        [button setTitle:[NSString stringWithFormat:@"登录%d",10000+i] forState:UIControlStateNormal];
        [button addTarget:self action:@selector(loginWithMulti:) forControlEvents:UIControlEventTouchUpInside];
    }
}

-(void)loginWithMulti:(id)sender
{
    NSString *account = [NSString stringWithFormat:@"%ld",(long)[sender tag]];
    multiLocalAccount = account;
    [signalEngine login:[KeyCenter appId]
                account:account
                  token:[KeyCenter generateSignalToken:account expiredTime:3600]
                    uid:0
               deviceID:nil];
}

-(void)pushMultiCall
{
    ChooseUserViewController *chooseUserVC = [self.storyboard instantiateViewControllerWithIdentifier:@"ChooseUserVC"];
    chooseUserVC.localAccount = multiLocalAccount;
    [self.navigationController presentViewController:chooseUserVC animated:YES completion:nil];
}

@end
