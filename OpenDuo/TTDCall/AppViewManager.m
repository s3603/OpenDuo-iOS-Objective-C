//
//  AppViewManager.m
//  OpenDuo
//
//  Created by 林英彬 on 2018/3/20.
//  Copyright © 2018年 Agora. All rights reserved.
//

#import "AppViewManager.h"
#import "AppDelegate.h"
#import "RCCallCommonDefine.h"

@implementation AppViewManager

+ (id)sharedManager {
    static dispatch_once_t once;
    static id instance;
    dispatch_once(&once, ^{
        instance = [self new];
    });
    return instance;
}

- (void)presentVC:(UIViewController *)viewController
{
    UIViewController *vc = [UIApplication sharedApplication].keyWindow.rootViewController;
    if (vc) {
        dispatch_sync_main_safe(^{
            [vc presentViewController:viewController animated:YES completion:nil];
        })
    }
}

- (UINavigationController *)navigationViewController
{
    AppDelegate *delegate = [[UIApplication sharedApplication] delegate];
    if ([delegate.window.rootViewController isKindOfClass:[UINavigationController class]])
    {
        return (UINavigationController *)delegate.window.rootViewController;
    }
    else if ([delegate.window.rootViewController isKindOfClass:[UITabBarController class]])
    {
        UIViewController *selectVc = [((UITabBarController *)delegate.window.rootViewController) selectedViewController];
        if ([selectVc isKindOfClass:[UINavigationController class]])
        {
            return (UINavigationController *)selectVc;
        }
    }
    return nil;
}

@end
