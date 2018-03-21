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
#import "TTDCallClient.h"

@interface ChooseUserViewController ()
{
}

@property (strong, nonatomic) IBOutletCollection(UIButton) NSArray *buttons;

@end

@implementation ChooseUserViewController

- (void)viewDidLoad {
    [super viewDidLoad];
    // Do any additional setup after loading the view.
    [self setupButtons];
}

-(void)viewWillAppear:(BOOL)animated
{
    [super viewWillAppear:animated];
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
    [callVC startCallTo:accounts];
}

@end
