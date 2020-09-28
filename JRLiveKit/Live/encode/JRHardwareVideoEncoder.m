//
//  JRHardwareVideoEncoder.m
//  JRLive
//
//  Created by fan on 2020/9/27.
//

#import "JRHardwareVideoEncoder.h"
#import <VideoToolbox/VideoToolbox.h>

@interface JRHardwareVideoEncoder ()
{
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

- (instancetype)initWithVideoStreamConfiguration:(JRLiveVideoConfiguration *)configuration
{
    if (self = [super init]) {

        _configuration = configuration;
        [self resetCompressionSession];
        [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(willEnterBackground:) name:UIApplicationWillResignActiveNotification object:nil];
        [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(willEnterForeground:) name:UIApplicationDidBecomeActiveNotification object:nil];
#ifdef DEBUG
        enabledWriteVideoFile = NO;
        [self initForFilePath];
#endif

    }
    return self;
}

- (void)resetCompressionSession
{
    if (compressionSession) {
        VTCompressionSessionCompleteFrames(compressionSession, kCMTimeInvalid);

        VTCompressionSessionInvalidate(compressionSession);
        CFRelease(compressionSession);
        compressionSession = NULL;
    }
    OSStatus status = VTCompressionSessionCreate(NULL, _configuration.videoSize.width, _configuration.videoSize.height, kCMVideoCodecType_H264, NULL, NULL, NULL, VideoCompressonOutputCallback, (__bridge void *)self, &compressionSession);
    if (status != noErr) {
        return;
    }
    _currentVideoBitRate = _configuration.videoBitRate;
    VTSessionSetProperty(compressionSession, kVTCompressionPropertyKey_MaxKeyFrameInterval, (__bridge CFTypeRef)@(_configuration.videoMaxKeyframeInterval));
    VTSessionSetProperty(compressionSession, kVTCompressionPropertyKey_MaxKeyFrameIntervalDuration, (__bridge CFTypeRef)@(_configuration.videoMaxKeyframeInterval/_configuration.videoFrameRate));
    VTSessionSetProperty(compressionSession, kVTCompressionPropertyKey_ExpectedFrameRate, (__bridge CFTypeRef)@(_configuration.videoFrameRate));
    VTSessionSetProperty(compressionSession, kVTCompressionPropertyKey_AverageBitRate, (__bridge CFTypeRef)@(_configuration.videoBitRate));
    NSArray *limit = @[@(_configuration.videoBitRate * 1.5/8), @(1)];
    VTSessionSetProperty(compressionSession, kVTCompressionPropertyKey_DataRateLimits, (__bridge CFArrayRef)limit);
    VTSessionSetProperty(compressionSession, kVTCompressionPropertyKey_RealTime, kCFBooleanTrue);
    VTSessionSetProperty(compressionSession, kVTCompressionPropertyKey_ProfileLevel, kVTProfileLevel_H264_Main_AutoLevel);
    VTSessionSetProperty(compressionSession, kVTCompressionPropertyKey_AllowFrameReordering, kCFBooleanTrue);
    VTSessionSetProperty(compressionSession, kVTCompressionPropertyKey_H264EntropyMode, kVTH264EntropyMode_CABAC);
    VTCompressionSessionPrepareToEncodeFrames(compressionSession);
}

- (void)setVideoBitRate:(NSInteger)videoBitRate {
    if(_isBackGround) return;
    VTSessionSetProperty(compressionSession, kVTCompressionPropertyKey_AverageBitRate, (__bridge CFTypeRef)@(videoBitRate));
    NSArray *limit = @[@(videoBitRate * 1.5/8), @(1)];
    VTSessionSetProperty(compressionSession, kVTCompressionPropertyKey_DataRateLimits, (__bridge CFArrayRef)limit);
    _currentVideoBitRate = videoBitRate;
}

- (NSInteger)videoBitRate {
    return _currentVideoBitRate;
}

- (void)dealloc {
    if (compressionSession != NULL) {
        VTCompressionSessionCompleteFrames(compressionSession, kCMTimeInvalid);

        VTCompressionSessionInvalidate(compressionSession);
        CFRelease(compressionSession);
        compressionSession = NULL;
    }
    [[NSNotificationCenter defaultCenter] removeObserver:self];
}

- (void)encodeVideoData:(CVPixelBufferRef)pixelBuffer timeStamp:(uint64_t)timeStamp
{
    if (_isBackGround) {
        return;
    }
    frameCount++;
    CMTime pts = CMTimeMake(frameCount, (int32_t)_configuration.videoFrameRate);
    VTEncodeInfoFlags flags;
    CMTime duration = CMTimeMake(1, (int32_t)_configuration.videoFrameRate);
    
    NSDictionary *properties = nil;
    if (frameCount % (int32_t)_configuration.videoMaxKeyframeInterval == 0) {
        properties = @{(__bridge NSString *)kVTEncodeFrameOptionKey_ForceKeyFrame: @(YES)};
    }
    NSNumber *timeNumber = @(timeStamp);
    
    OSStatus status = VTCompressionSessionEncodeFrame(compressionSession, pixelBuffer, pts, duration, (__bridge CFDictionaryRef)properties, (__bridge_retained void *)timeNumber, &flags);
    if (status != noErr) {
        [self resetCompressionSession];
    }
    
}

- (void)setDelegate:(id<JRVideoEncodingDelegate>)delegate
{
    _h264Delegate = delegate;
}

- (void)stopEncoder {
    VTCompressionSessionCompleteFrames(compressionSession, kCMTimeIndefinite);
}

static void VideoCompressonOutputCallback(void *VTref, void *VTFrameRef, OSStatus status, VTEncodeInfoFlags infoFlags, CMSampleBufferRef sampleBuffer)
{
    if (!sampleBuffer) {
        return;
    }
    CFArrayRef array = CMSampleBufferGetSampleAttachmentsArray(sampleBuffer, true);
    if (!array) {
        return;
    }
    CFDictionaryRef dic = (CFDictionaryRef)CFArrayGetValueAtIndex(array, 0);
    if (!dic) {
        return;
    }
    BOOL keyframe = !CFDictionaryContainsKey(dic, kCMSampleAttachmentKey_NotSync);
    uint64_t timestamp = [((__bridge_transfer NSNumber *)VTFrameRef) longLongValue];
    
    JRHardwareVideoEncoder *videoEncoder = (__bridge JRHardwareVideoEncoder *)VTref;
    if (status != noErr) {
        return;
    }
    if (keyframe && !videoEncoder->sps) {
        CMFormatDescriptionRef format = CMSampleBufferGetFormatDescription(sampleBuffer);
        size_t spsSize, spsCount;
        const uint8_t *sps;
        OSStatus statusCode = CMVideoFormatDescriptionGetH264ParameterSetAtIndex(format, 0, &sps, &spsSize, &spsCount, 0);
        if (statusCode == noErr) {
            size_t ppsSize, ppsCount;
            const uint8_t *pps;
            OSStatus statusCode = CMVideoFormatDescriptionGetH264ParameterSetAtIndex(format, 1, &pps, &ppsSize, &ppsCount, 0);
            if (statusCode == noErr) {
                videoEncoder->sps = [NSData dataWithBytes:sps length:spsSize];
                videoEncoder->pps = [NSData dataWithBytes:pps length:ppsSize];
                
                if (videoEncoder->enabledWriteVideoFile) {
                    NSMutableData *data = [[NSMutableData alloc] init];
                    uint8_t header[] = {0x00, 0x00, 0x00, 0x01};
                    [data appendBytes:header length:4];
                    [data appendData:videoEncoder->sps];
                    [data appendBytes:header length:4];
                    [data appendData:videoEncoder->pps];
                    fwrite(data.bytes, 1, data.length, videoEncoder->fp);
                }
            }
        }
    }
    
    CMBlockBufferRef dataBuffer = CMSampleBufferGetDataBuffer(sampleBuffer);
    size_t length, totalLength;
    char *dataPointer;
    OSStatus statusCodeRet = CMBlockBufferGetDataPointer(dataBuffer, 0, &length, &totalLength, &dataPointer);
    if (statusCodeRet == noErr) {
        size_t bufferoffset = 0;
        static const int AVCCHeaderLength = 4;
        if (bufferoffset < totalLength - AVCCHeaderLength) {
            uint32_t NALUnitLength = 0;
            memcpy(&NALUnitLength, dataPointer + bufferoffset, AVCCHeaderLength);
            
            NALUnitLength = CFSwapInt32BigToHost(NALUnitLength);
            
            JRVideoFrame *videoframe = [[JRVideoFrame alloc] init];
            videoframe.timestamp = timestamp;
            videoframe.data = [NSData dataWithBytes:dataPointer + bufferoffset + AVCCHeaderLength length:NALUnitLength];
            videoframe.isKeyFrame = keyframe;
            videoframe.sps = videoEncoder->sps;
            videoframe.pps = videoEncoder->pps;
            
            if (videoEncoder.h264Delegate && [videoEncoder.h264Delegate respondsToSelector:@selector(videoEncoder:videoFrame:)]) {
                [videoEncoder.h264Delegate videoEncoder:videoEncoder videoFrame:videoframe];
            }
            
            if (videoEncoder->enabledWriteVideoFile) {
                NSMutableData *data = [[NSMutableData alloc] init];
                if (keyframe) {
                    uint8_t header[] = {0x00, 0x00, 0x00, 0x01};
                    [data appendBytes:header length:4];
                } else {
                    uint8_t header[] = {0x00, 0x00, 0x01};
                    [data appendBytes:header length:3];
                }
                [data appendData:videoframe.data];

                fwrite(data.bytes, 1, data.length, videoEncoder->fp);
            }
            bufferoffset += AVCCHeaderLength + NALUnitLength;
        }
    }
}

#pragma mark -- Notification
- (void)willEnterBackground:(NSNotification*)notification{
    _isBackGround = YES;
}

- (void)willEnterForeground:(NSNotification*)notification{
    [self resetCompressionSession];
    _isBackGround = NO;
}

- (void)initForFilePath {
    NSString *path = [self GetFilePathByfileName:@"IOSCamDemo.h264"];
    NSLog(@"%@", path);
    self->fp = fopen([path cStringUsingEncoding:NSUTF8StringEncoding], "wb");
}

- (NSString *)GetFilePathByfileName:(NSString*)filename {
    NSArray *paths = NSSearchPathForDirectoriesInDomains(NSDocumentDirectory, NSUserDomainMask, YES);
    NSString *documentsDirectory = [paths objectAtIndex:0];
    NSString *writablePath = [documentsDirectory stringByAppendingPathComponent:filename];
    return writablePath;
}

@end
