//
//  JRLiveViewController.m
//  JRLive
//
//  Created by fanjianrong on 2017/8/22.
//  Copyright © 2017年 樊健荣. All rights reserved.
//

#import "JRLiveViewController.h"
#import "JRLiveView.h"

@interface JRLiveViewController ()

@property (strong, nonatomic) JRLiveView *liveView;

@end

@implementation JRLiveViewController

- (void)viewDidLoad {
    [super viewDidLoad];
    
    self.view.backgroundColor = [UIColor whiteColor];
    
    [self.view addSubview:self.liveView];
    self.liveView.frame = self.view.bounds;
    
    
}

- (void)viewWillAppear:(BOOL)animated
{
    [super viewWillAppear:animated];
    
}

- (void)viewDidLayoutSubviews
{
    [super viewDidLayoutSubviews];
    
}


#pragma mark - setter && getter

- (JRLiveView *)liveView
{
    if (!_liveView) {
        _liveView = [[JRLiveView alloc] init];
    }
    return _liveView;
}


@end
