//
//  JRHardwareVideoEncoder.m
//  JRLive
//
//  Created by fan on 2020/9/27.
//

#import "JRHardwareVideoEncoder.h"
#import <VideoToolbox/VideoToolbox.h>

@interface JRHardwareVideoEncoder (){
    VTCompressionSessionRef compressionSession;
    NSInteger frameCount;
    NSData *sps;
    NSData *pps;
    FILE *fp;
    BOOL enabledWriteVideoFile;
}

@property (nonatomic, strong) JRLiveVideoConfiguration *configuration;
@property (nonatomic, weak) id<JRVideoEncodingDelegate> h264Delegate;
@property (nonatomic) NSInteger currentVideoBitRate;
@property (nonatomic) BOOL isBackGround;

@end

@implementation JRHardwareVideoEncoder



@end
