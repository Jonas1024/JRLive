//
//  ViewController.m
//  JRLive
//
//  Created by fan on 2020/9/25.
//

#import "ViewController.h"
#import "JRLivePreview.h"
#import "JRLivePlayer.h"

@interface ViewController ()

@property (nonatomic, strong) JRLivePlayer *livePlayer;

@end

@implementation ViewController

- (void)viewDidLoad
{
    [super viewDidLoad];
    
    self.view.backgroundColor = [UIColor lightGrayColor];
    
//    dispatch_async(dispatch_get_main_queue(), ^{
//        [self.view addSubview:[[JRLivePreview alloc] initWithFrame:self.view.bounds]];
//    });
    
    dispatch_after(dispatch_time(DISPATCH_TIME_NOW, (int64_t)(2 * NSEC_PER_SEC)), dispatch_get_main_queue(), ^{
        self.livePlayer = [[JRLivePlayer alloc] initWithFrame:self.view.bounds];
        [self.livePlayer configWithURLString:@"rtmp://live.dajiufan.com/live/live"];
        [self.view addSubview:self.livePlayer.preview];
        self.livePlayer.preview.frame = self.view.bounds;
        
        [self.livePlayer startPlayer];
    });
}


@end
