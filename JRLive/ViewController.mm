//
//  ViewController.m
//  JRLive
//
//  Created by fan on 2020/9/25.
//

#import "ViewController.h"
#import "JRHardwareVideoEncoder.h"
#ifdef __cplusplus
extern "C" {
#endif
    
#include "libavformat/avformat.h"
    
#ifdef __cplusplus
};
#endif

@interface ViewController ()

@end

@implementation ViewController

- (void)viewDidLoad {
    [super viewDidLoad];
    av_register_all();
//    [[JRHardwareVideoEncoder alloc] init];
}


@end
