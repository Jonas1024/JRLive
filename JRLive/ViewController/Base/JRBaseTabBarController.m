//
//  JRBaseTabBarController.m
//  JRLive
//
//  Created by fanjianrong on 2017/8/22.
//  Copyright © 2017年 樊健荣. All rights reserved.
//

#import "JRBaseTabBarController.h"
#import "JRBaseNavigationController.h"
#import "JRHomeViewController.h"
#import "JRLiveViewController.h"

@interface JRBaseTabBarController ()

@end

@implementation JRBaseTabBarController


+ (instancetype)baseTabBarController
{
    return [[JRBaseTabBarController alloc] init];
}

- (instancetype)init
{
    self = [super init];
    if (self) {
        [self initSubControllers];
    }
    return self;
}

- (void)initSubControllers
{
    JRHomeViewController *home = [[JRHomeViewController alloc] init];
    JRLiveViewController *live = [[JRLiveViewController alloc] init];
    
    JRBaseNavigationController *homeNavi = [[JRBaseNavigationController alloc] initWithRootViewController:home];
    JRBaseNavigationController *liveNavi = [[JRBaseNavigationController alloc] initWithRootViewController:live];
    
    home.title = @"首页";
    live.title = @"直播";
    
    self.viewControllers = @[homeNavi, liveNavi];
}


@end
