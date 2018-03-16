//
//  UserVideoView.h
//  OpenDuo
//
//  Created by 林英彬 on 2018/3/16.
//  Copyright © 2018年 Agora. All rights reserved.
//

#import <UIKit/UIKit.h>

@interface UserVideoView : UIView

@property (strong, nonatomic) UIView *hostingView;
@property (strong, nonatomic) UILabel *nameLab;

-(instancetype)initWithName:(NSString *)name;

@end
