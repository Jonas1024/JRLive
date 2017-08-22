//
//  JRLiveView.m
//  JRLive
//
//  Created by fanjianrong on 2017/8/22.
//  Copyright © 2017年 樊健荣. All rights reserved.
//

#import "JRLiveView.h"
#import <GPUImage.h>
#import "GPUImageBeautifyFilter.h"


@interface JRLiveView ()

@property (strong, nonatomic) GPUImageVideoCamera *videoCamera;
@property (strong, nonatomic) GPUImageView *filterView;



@end

@implementation JRLiveView

- (instancetype)initWithFrame:(CGRect)frame
{
    self = [super initWithFrame:frame];
    if (self) {
        [self setupViews];
        self.backgroundColor = [UIColor orangeColor];
    }
    return self;
}

- (void)layoutSubviews
{
    [super layoutSubviews];
    self.filterView.frame = self.bounds;
}

- (void)setupViews
{
    self.videoCamera = [[GPUImageVideoCamera alloc] initWithSessionPreset:AVCaptureSessionPreset640x480 cameraPosition:AVCaptureDevicePositionFront];
    self.videoCamera.outputImageOrientation = UIInterfaceOrientationLandscapeLeft;
    
    self.filterView = [[GPUImageView alloc] initWithFrame:self.bounds];
//    self.filterView.center = self.center;
    [self addSubview:self.filterView];
    self.filterView.backgroundColor = [UIColor blackColor];
    
    [self.videoCamera startCameraCapture];
    GPUImageBeautifyFilter *beautifyFilter = [[GPUImageBeautifyFilter alloc] init];
    [self.videoCamera addTarget:beautifyFilter];
    
    [beautifyFilter addTarget:self.filterView];
}


@end
