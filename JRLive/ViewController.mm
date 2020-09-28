//
//  ViewController.m
//  JRLive
//
//  Created by fan on 2020/9/25.
//

#import "ViewController.h"
#import "JRLivePreview.h"

// FFmpeg Header File
#ifdef __cplusplus
extern "C" {
#endif
    
#include "libavformat/avformat.h"
#include "libavcodec/avcodec.h"
#include "libavutil/avutil.h"
#include "libswscale/swscale.h"
#include "libswresample/swresample.h"
#include "libavutil/opt.h"
    
#ifdef __cplusplus
};
#endif

@interface ViewController ()

@end

@implementation ViewController

- (void)viewDidLoad
{
    [super viewDidLoad];
    
    av_register_all();
    
    dispatch_async(dispatch_get_main_queue(), ^{
        [self.view addSubview:[[JRLivePreview alloc] initWithFrame:self.view.bounds]];
    });
}


@end
