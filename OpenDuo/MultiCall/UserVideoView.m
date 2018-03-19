//
//  UserVideoView.m
//  OpenDuo
//
//  Created by 林英彬 on 2018/3/16.
//  Copyright © 2018年 Agora. All rights reserved.
//

#import "UserVideoView.h"

@interface UserVideoView()

@property (assign, nonatomic) NSUInteger uid;

@end

@implementation UserVideoView

/*
// Only override drawRect: if you perform custom drawing.
// An empty implementation adversely affects performance during animation.
- (void)drawRect:(CGRect)rect {
    // Drawing code
}
*/

-(instancetype)initWithUid:(NSUInteger)uid
{
    self = [super init];
    
    self.uid = uid;
    NSString *name = [NSString stringWithFormat:@"%ld",uid];
    self.nameLab = [[UILabel alloc] init];
    int random = arc4random()%3;
    NSArray *colors = @[[UIColor redColor],[UIColor orangeColor],[UIColor purpleColor]];
    self.nameLab.backgroundColor = colors[random];
    self.nameLab.text = name;
    [self addSubview:self.nameLab];
    
    self.hostingView = [[UIView alloc] init];
    [self addSubview:self.hostingView];
    
    UITapGestureRecognizer *tap = [[UITapGestureRecognizer alloc] initWithTarget:self action:@selector(viewTapped)];
    [self addGestureRecognizer:tap];
    return self;
}

-(void)layoutSubviews
{
    [super layoutSubviews];
    
    self.nameLab.frame = CGRectMake(0, self.frame.size.height/2 - 10, self.frame.size.width, 20);
    self.hostingView.frame = self.bounds;
}

-(void)viewTapped
{
    if (self.tapBlock) {
        self.tapBlock(self.uid);
    }
}

@end
