//
//  JRFFmpegVideoDecoder.m
//  JRLive
//
//  Created by fan on 2020/9/28.
//

#import "JRFFmpegVideoDecoder.h"

@interface JRFFmpegVideoDecoder ()
{
    /*  FFmpeg  */
    AVFormatContext          *m_formatContext;
    AVCodecContext           *m_videoCodecContext;
    AVFrame                  *m_videoFrame;
    
    int     m_videoStreamIndex;
    BOOL    m_isFindIDR;
}

@property (nonatomic, assign) int64_t baseTime;
@property (nonatomic, assign) BOOL isFirstFrame;

@end

@implementation JRFFmpegVideoDecoder

#pragma mark - C Function

AVBufferRef *hw_device_ctx = NULL;
static int InitHardwareDecoder(AVCodecContext *ctx, const enum AVHWDeviceType type)
{
    int err = av_hwdevice_ctx_create(&hw_device_ctx, type, NULL, NULL, 0);
    if (err < 0) {
        NSLog(@"Failed to create specified HW device.");
        return err;
    }
    ctx->hw_device_ctx = av_buffer_ref(hw_device_ctx);
    return err;
}

static int DecodeGetAVStreamFPSTimeBase(AVStream *st) {
    CGFloat fps, timebase = 0.0;
    
    if (st->time_base.den && st->time_base.num)
        timebase = av_q2d(st->time_base);
    else if(st->codec->time_base.den && st->codec->time_base.num)
        timebase = av_q2d(st->codec->time_base);
    
    if (st->avg_frame_rate.den && st->avg_frame_rate.num)
        fps = av_q2d(st->avg_frame_rate);
    else if (st->r_frame_rate.den && st->r_frame_rate.num)
        fps = av_q2d(st->r_frame_rate);
    else
        fps = 1.0 / timebase;
    
    return fps;
}

#pragma mark -

- (instancetype)initWithFormatContext:(AVFormatContext *)formatContext
                     videoStreamIndex:(int)videoStreamIndex
{
    if (self = [super init]) {
        m_formatContext     = formatContext;
        m_videoStreamIndex  = videoStreamIndex;
        
        m_isFindIDR     = NO;
        _isFirstFrame   = NO;
        [self initDecoder];
    }
    return self;
}

- (void)initDecoder {
    AVStream *videoStream = m_formatContext->streams[m_videoStreamIndex];
    m_videoCodecContext = [self createVideoEncderWithFormatContext:m_formatContext
                                                            stream:videoStream
                                                  videoStreamIndex:m_videoStreamIndex];
    if (!m_videoCodecContext) {
        NSLog(@"create video codec failed");
        return;
    }
    
    // Get video frame
    m_videoFrame = av_frame_alloc();
    if (!m_videoFrame) {
        NSLog(@"alloc video frame failed");
        avcodec_close(m_videoCodecContext);
    }
}

#pragma mark -

- (void)startDecodeData:(AVPacket)packet
{
    AVStream *videoStream = m_formatContext->streams[m_videoStreamIndex];
    
    avcodec_send_packet(m_videoCodecContext, &packet);
    while (0 == avcodec_receive_frame(m_videoCodecContext, m_videoFrame))
    {
        CVPixelBufferRef pixelBuffer = (CVPixelBufferRef)m_videoFrame->data[3];
        CMTime presentationTimeStamp = kCMTimeInvalid;
        Float64 ptsSec = m_videoFrame->pts * av_q2d(videoStream->time_base);
        presentationTimeStamp = CMTimeMake(ptsSec*1000000, 1000000);
        CMSampleBufferRef sampleBufferRef = [self convertCVImageBufferRefToCMSampleBufferRef:(CVPixelBufferRef)pixelBuffer
                                                                   withPresentationTimeStamp:presentationTimeStamp];
        
        if (sampleBufferRef) {
            if ([self.delegate respondsToSelector:@selector(videoDecoder:didDecode:isFirstFrame:)]) {
                [self.delegate videoDecoder:self didDecode:sampleBufferRef isFirstFrame:NO];
            }
            CFRelease(sampleBufferRef);
        }
    }
}

- (void)stop
{
    [self freeAllResources];
}

- (void)freeAllResources {
    if (m_videoCodecContext) {
        avcodec_send_packet(m_videoCodecContext, NULL);
        avcodec_flush_buffers(m_videoCodecContext);
        
        if (m_videoCodecContext->hw_device_ctx) {
            av_buffer_unref(&m_videoCodecContext->hw_device_ctx);
            m_videoCodecContext->hw_device_ctx = NULL;
        }
        avcodec_close(m_videoCodecContext);
        m_videoCodecContext = NULL;
    }
    
    if (m_videoFrame) {
        av_free(m_videoFrame);
        m_videoFrame = NULL;
    }
}


#pragma mark - Private

#pragma mark - Other
- (CMSampleBufferRef)convertCVImageBufferRefToCMSampleBufferRef:(CVImageBufferRef)pixelBuffer
                                      withPresentationTimeStamp:(CMTime)presentationTimeStamp
{
    CVPixelBufferLockBaseAddress(pixelBuffer, 0);
    CMSampleBufferRef newSampleBuffer = NULL;
    OSStatus res = 0;
    
    CMSampleTimingInfo timingInfo;
    timingInfo.duration              = kCMTimeInvalid;
    timingInfo.decodeTimeStamp       = presentationTimeStamp;
    timingInfo.presentationTimeStamp = presentationTimeStamp;
    
    CMVideoFormatDescriptionRef videoInfo = NULL;
    res = CMVideoFormatDescriptionCreateForImageBuffer(NULL, pixelBuffer, &videoInfo);
    if (res != 0) {
        NSLog(@"Create video format description failed!");
        CVPixelBufferUnlockBaseAddress(pixelBuffer, 0);
        return NULL;
    }
    
    res = CMSampleBufferCreateForImageBuffer(kCFAllocatorDefault,
                                             pixelBuffer,
                                             true,
                                             NULL,
                                             NULL,
                                             videoInfo,
                                             &timingInfo, &newSampleBuffer);
    
    CFRelease(videoInfo);
    if (res != 0) {
        NSLog(@"Create sample buffer failed!");
        CVPixelBufferUnlockBaseAddress(pixelBuffer, 0);
        return NULL;
        
    }
    
    CVPixelBufferUnlockBaseAddress(pixelBuffer, 0);
    return newSampleBuffer;
}

- (AVCodecContext *)createVideoEncderWithFormatContext:(AVFormatContext *)formatContext
                                                stream:(AVStream *)stream
                                      videoStreamIndex:(int)videoStreamIndex
{
    AVCodecContext *codecContext = NULL;
    AVCodec *codec = NULL;
    
    const char *codecName = av_hwdevice_get_type_name(AV_HWDEVICE_TYPE_VIDEOTOOLBOX);
    enum AVHWDeviceType type = av_hwdevice_find_type_by_name(codecName);
    if (type != AV_HWDEVICE_TYPE_VIDEOTOOLBOX) {
        NSLog(@"Not find hardware codec.");
        return NULL;
    }
    
    int ret = av_find_best_stream(formatContext, AVMEDIA_TYPE_VIDEO, -1, -1, &codec, 0);
    if (ret < 0) {
        NSLog(@"av_find_best_stream faliture");
        return NULL;
    }
    
    codecContext = avcodec_alloc_context3(codec);
    if (!codecContext){
        NSLog(@"avcodec_alloc_context3 faliture");
        return NULL;
    }
    
    ret = avcodec_parameters_to_context(codecContext, formatContext->streams[videoStreamIndex]->codecpar);
    if (ret < 0){
        NSLog(@"avcodec_parameters_to_context faliture");
        return NULL;
    }
    
    ret = InitHardwareDecoder(codecContext, type);
    if (ret < 0){
        NSLog(@"hw_decoder_init faliture");
        return NULL;
    }
    
    ret = avcodec_open2(codecContext, codec, NULL);
    if (ret < 0) {
        NSLog(@"avcodec_open2 faliture");
        return NULL;
    }
    
    return codecContext;
}

@end
