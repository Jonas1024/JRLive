//
//  JRStreamPuller.m
//  JRLive
//
//  Created by fan on 2020/9/28.
//

#import "JRStreamPuller.h"
#import <UIKit/UIKit.h>

static const int kSupportMaxFps     = 60;
static const int kFpsOffSet         = 5;
static const int kWidth1920         = 1920;
static const int kHeight1080        = 1080;
static const int kSupportMaxWidth   = 3840;
static const int kSupportMaxHeight  = 2160;

@interface JRStreamPuller ()
{
    /*  Flag  */
    BOOL m_isStopParse;
    
    /*  FFmpeg  */
    AVFormatContext          *m_formatContext;
    AVBitStreamFilterContext *m_bitFilterContext;
    
    int m_videoStreamIndex;
    int m_audioStreamIndex;
    
    /*  Video info  */
    int m_video_width, m_video_height, m_video_fps;
    
    dispatch_queue_t parseQueue;
}

@property (nonatomic, strong) NSString *urlString;
@property (nonatomic, assign) JRDecodeType type;

@end

@implementation JRStreamPuller

#pragma mark - C Function

static int GetAVStreamFPSTimeBase(AVStream *st) {
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

- (instancetype)initWithURLString:(NSString *)urlString
{
    self = [super init];
    if (self) {
        _urlString = urlString;
        parseQueue = dispatch_queue_create("com.dajiufan.pull.queue", DISPATCH_QUEUE_SERIAL);
        [self prepare];
    }
    return self;
}

#pragma mark - public

- (void)startWithDecodeType:(JRDecodeType)type
{
    self.type = type;
    if (type == JRDecodeTypeFFmpeg) {
        [self startFFmpeg];
    } else {
        [self startHardware];
    }
}

#pragma mark -

- (void)startHardware
{
    m_isStopParse = NO;
    dispatch_async(parseQueue, ^{
        AVPacket    packet;
        AVRational  input_base;
        input_base.num = 1;
        input_base.den = 1000;
        int fps = GetAVStreamFPSTimeBase(self->m_formatContext->streams[self->m_videoStreamIndex]);
        
        while (!self->m_isStopParse) {
            av_init_packet(&packet);
            
            //读取数据
            int size = av_read_frame(self->m_formatContext, &packet);
            if (size < 0 || packet.size < 0) {
                NSLog(@"pull finish");
                if ([self.delegate respondsToSelector:@selector(pullerDidFinish:)]) {
                    [self.delegate pullerDidFinish:self];
                }
                break;;
            }
            if (packet.stream_index == self->m_videoStreamIndex) {
                [self parseVideo:packet rational:input_base fps:fps];
            } else if (packet.stream_index == self->m_audioStreamIndex) {
                [self parseAudio:packet];
            }
            av_packet_unref(&packet);
        }
        [self freeAllResources];
    });
}

- (void)parseVideo:(AVPacket)packet rational:(AVRational)input_base fps:(int)fps
{
    JRVideoDataInfo videoInfo = {0};
    
    // get the rotation angle of video
    AVDictionaryEntry *tag = NULL;
    tag = av_dict_get(m_formatContext->streams[m_videoStreamIndex]->metadata, "rotate", tag, 0);
    if (tag != NULL) {
        int rotate = [[NSString stringWithFormat:@"%s",tag->value] intValue];
        switch (rotate) {
            case 90:
                videoInfo.videoRotate = 90;
                break;
            case 180:
                videoInfo.videoRotate = 180;
                break;
            case 270:
                videoInfo.videoRotate = 270;
                break;
            default:
                videoInfo.videoRotate = 0;
                break;
        }
    }
    
    if (videoInfo.videoRotate != 0 /* &&  <= iPhone 8*/) {
        NSLog(@"Not support the angle");
        return;
    }
    
    static char filter_name[32];
    if (m_formatContext->streams[m_videoStreamIndex]->codecpar->codec_id == AV_CODEC_ID_H264) {
        strncpy(filter_name, "h264_mp4toannexb", 32);
        videoInfo.videoFormat = JRVideoEncodeFormatH264;
    } else if (m_formatContext->streams[m_videoStreamIndex]->codecpar->codec_id == AV_CODEC_ID_HEVC) {
        strncpy(filter_name, "hevc_mp4toannexb", 32);
        videoInfo.videoFormat = JRVideoEncodeFormatH265;
    } else {
        return;
    }
    
    /* new API can't get correct sps, pps.
    if (!self->m_bsfContext) {
        const AVBitStreamFilter *filter = av_bsf_get_by_name(filter_name);
        av_bsf_alloc(filter, &self->m_bsfContext);
        av_bsf_init(self->m_bsfContext);
        avcodec_parameters_copy(self->m_bsfContext->par_in, formatContext->streams[videoStreamIndex]->codecpar);
    }
    */
    
    //有待了解
    // get sps,pps. If not call it, get sps , pps is incorrect. use new_packet to resolve memory leak.
    AVPacket new_packet = packet;
    if (self->m_bitFilterContext == NULL) {
        self->m_bitFilterContext = av_bitstream_filter_init(filter_name);
    }
    av_bitstream_filter_filter(self->m_bitFilterContext, m_formatContext->streams[m_videoStreamIndex]->codec, NULL, &new_packet.data, &new_packet.size, packet.data, packet.size, 0);
    
    CMSampleTimingInfo timingInfo;
    CMTime pts = kCMTimeInvalid;
    Float64 ptsSec = packet.pts * av_q2d(m_formatContext->streams[m_videoStreamIndex]->time_base);
    pts = CMTimeMake(ptsSec*1000000, 1000000);
    timingInfo.presentationTimeStamp = pts;
    Float64 dtsSec = av_rescale_q(packet.dts, m_formatContext->streams[m_videoStreamIndex]->time_base, input_base);
    timingInfo.decodeTimeStamp =  CMTimeMake(dtsSec*1000000, 1000000);
    
    int video_size = packet.size;
    uint8_t *video_data = (uint8_t *)malloc(video_size);
    memcpy(video_data, packet.data, video_size);
    
    videoInfo.data          = video_data;
    videoInfo.dataSize      = video_size;
    videoInfo.extraDataSize = m_formatContext->streams[m_videoStreamIndex]->codec->extradata_size;
    videoInfo.extraData     = (uint8_t *)malloc(videoInfo.extraDataSize);
    videoInfo.timingInfo    = timingInfo;
    videoInfo.pts           = packet.pts * av_q2d(m_formatContext->streams[m_videoStreamIndex]->time_base);
    videoInfo.fps           = fps;
    
    memcpy(videoInfo.extraData, m_formatContext->streams[m_videoStreamIndex]->codec->extradata, videoInfo.extraDataSize);
    av_free(new_packet.data);
    if ([self.delegate respondsToSelector:@selector(puller:videoDataInfo:)]) {
        [self.delegate puller:self videoDataInfo:&videoInfo];
    }
    free(videoInfo.extraData);
    free(videoInfo.data);
}

- (void)parseAudio:(AVPacket)packet
{
    JRAudioDataInfo audioInfo = {0};
    audioInfo.data = (uint8_t *)malloc(packet.size);
    memcpy(audioInfo.data, packet.data, packet.size);
    audioInfo.dataSize = packet.size;
    audioInfo.channel = m_formatContext->streams[m_audioStreamIndex]->codecpar->channels;
    audioInfo.sampleRate = m_formatContext->streams[m_audioStreamIndex]->codecpar->sample_rate;
    audioInfo.pts = packet.pts * av_q2d(m_formatContext->streams[m_audioStreamIndex]->time_base);
    
    if ([self.delegate respondsToSelector:@selector(puller:audioDataInfo:)]) {
        [self.delegate puller:self audioDataInfo:&audioInfo];
    }
    free(audioInfo.data);
}

#pragma mark -

- (void)startFFmpeg
{
    dispatch_async(parseQueue, ^{
        AVPacket    packet;
        while (!self->m_isStopParse) {
            av_init_packet(&packet);
            //读取数据
            int size = av_read_frame(self->m_formatContext, &packet);
            if (size < 0 || packet.size < 0) {
                NSLog(@"pull finish");
                if ([self.delegate respondsToSelector:@selector(pullerDidFinish:)]) {
                    [self.delegate pullerDidFinish:self];
                }
                break;
            }
            if (packet.stream_index == self->m_videoStreamIndex) {
                if ([self.delegate respondsToSelector:@selector(puller:videoPacket:)]) {
                    [self.delegate puller:self videoPacket:&packet];
                }
            } else {
                if ([self.delegate respondsToSelector:@selector(puller:audioPacket:)]) {
                    [self.delegate puller:self audioPacket:&packet];
                }
            }
            av_packet_unref(&packet);
        }
        [self freeAllResources];
    });
}

#pragma mark - private

- (void)prepare
{
    m_formatContext = [self createFormatContext];
    if (m_formatContext == NULL) {
        NSLog(@"create format context failed.");
        return;
    }
    m_videoStreamIndex = [self getAVStreamIndexWithIsVideoStream:YES];
    // Get video stream
    AVStream *videoStream = m_formatContext->streams[m_videoStreamIndex];
    m_video_width  = videoStream->codecpar->width;
    m_video_height = videoStream->codecpar->height;
    m_video_fps    = GetAVStreamFPSTimeBase(videoStream);
    
    NSLog(@"video index:%d, width:%d, height:%d, fps:%d",m_videoStreamIndex,m_video_width,m_video_height,m_video_fps);
    
    BOOL isSupport = [self isSupportVideoStream:videoStream];
    if (!isSupport) {
        NSLog(@"Not support the video stream");
        return;
    }
    
    m_audioStreamIndex = [self getAVStreamIndexWithIsVideoStream:NO];
    AVStream *audioStream = m_formatContext->streams[m_audioStreamIndex];
    
    isSupport = [self isSupportAudioStream:audioStream];
    if (!isSupport) {
        NSLog(@"Not support the audio stream");
        return;
    }
}

- (AVFormatContext *)createFormatContext
{
    AVFormatContext  *formatContext = NULL;
    AVDictionary     *opts          = NULL;
    
    av_dict_set(&opts, "timeout", "1000000", 0);//设置超时1秒
    
    formatContext = avformat_alloc_context();
    BOOL isSuccess = avformat_open_input(&formatContext, [self.urlString UTF8String], NULL, &opts) < 0 ? NO : YES;
    av_dict_free(&opts);
    
    if (!isSuccess) {
        if (formatContext) {
            avformat_free_context(formatContext);
        }
        return NULL;
    }
    
    if (avformat_find_stream_info(formatContext, NULL) < 0) {
        avformat_close_input(&formatContext);
        return NULL;
    }
    
    return formatContext;
}

- (int)getAVStreamIndexWithIsVideoStream:(BOOL)isVideoStream {
    int avStreamIndex = -1;
    for (int i = 0; i < m_formatContext->nb_streams; i++) {
        if ((isVideoStream ? AVMEDIA_TYPE_VIDEO : AVMEDIA_TYPE_AUDIO) == m_formatContext->streams[i]->codecpar->codec_type) {
            avStreamIndex = i;
        }
    }
    
    if (avStreamIndex == -1) {
        NSLog(@"Not find video stream");
        return NULL;
    }else {
        return avStreamIndex;
    }
}

- (BOOL)isSupportVideoStream:(AVStream *)stream
{
    if (stream->codecpar->codec_type == AVMEDIA_TYPE_VIDEO) {   // Video
        AVCodecID codecID = stream->codecpar->codec_id;
        NSLog(@"Current video codec format is %s", avcodec_find_decoder(codecID)->name);
        // 目前只支持H264、H265(HEVC iOS11)编码格式的视频文件
        if ((codecID != AV_CODEC_ID_H264 && codecID != AV_CODEC_ID_HEVC) || (codecID == AV_CODEC_ID_HEVC && [[UIDevice currentDevice].systemVersion floatValue] < 11.0)) {
            NSLog(@"Not suuport the codec");
            return NO;
        }
        
        // iPhone 8以上机型支持有旋转角度的视频
        AVDictionaryEntry *tag = NULL;
        tag = av_dict_get(m_formatContext->streams[m_videoStreamIndex]->metadata, "rotate", tag, 0);
        if (tag != NULL) {
            int rotate = [[NSString stringWithFormat:@"%s",tag->value] intValue];
            if (rotate != 0 /* && >= iPhone 8P*/) {
                NSLog(@"Not support rotate for device ");
            }
        }
        
        /*
         各机型支持的最高分辨率和FPS组合:
         
         iPhone 6S: 60fps -> 720P
         30fps -> 4K
         
         iPhone 7P: 60fps -> 1080p
         30fps -> 4K
         
         iPhone 8: 60fps -> 1080p
         30fps -> 4K
         
         iPhone 8P: 60fps -> 1080p
         30fps -> 4K
         
         iPhone X: 60fps -> 1080p
         30fps -> 4K
         
         iPhone XS: 60fps -> 1080p
         30fps -> 4K
         */
        
        // 目前最高支持到60FPS
        if (m_video_fps > kSupportMaxFps + kFpsOffSet) {
            NSLog(@"Not support the fps");
            return NO;
        }
        
        // 目前最高支持到3840*2160
        if (m_video_width > kSupportMaxWidth || m_video_height > kSupportMaxHeight) {
            NSLog(@"Not support the resolution");
            return NO;
        }
        
        // 60FPS -> 1080P
        if (m_video_fps > kSupportMaxFps - kFpsOffSet && (m_video_width > kWidth1920 || m_video_height > kHeight1080)) {
            NSLog(@"Not support the fps and resolution");
            return NO;
        }
        
        // 30FPS -> 4K
        if (m_video_fps > kSupportMaxFps / 2 + kFpsOffSet && (m_video_width >= kSupportMaxWidth || m_video_height >= kSupportMaxHeight)) {
            NSLog(@"Not support the fps and resolution");
            return NO;
        }
        return YES;
    }
    return NO;
}

- (BOOL)isSupportAudioStream:(AVStream *)stream
{
    if (stream->codecpar->codec_type == AVMEDIA_TYPE_AUDIO) {
        
        AVCodecID codecID = stream->codecpar->codec_id;
        NSLog(@"Current audio codec format is %s", avcodec_find_decoder(codecID)->name);
        // 本项目只支持AAC格式的音频
        if (codecID != AV_CODEC_ID_AAC) {
            NSLog(@"Only support AAC format for the demo.");
            return NO;
        }
        return YES;
    }else {
        return NO;
    }
}

#pragma mark -

- (void)freeAllResources
{
    if (m_formatContext) {
        avformat_close_input(&m_formatContext);
        m_formatContext = NULL;
    }
    
    if (m_bitFilterContext) {
        av_bitstream_filter_close(m_bitFilterContext);
        m_bitFilterContext = NULL;
    }
}

- (Float64)getCurrentTimestamp
{
    CMClockRef hostClockRef = CMClockGetHostTimeClock();
    CMTime hostTime = CMClockGetTime(hostClockRef);
    return CMTimeGetSeconds(hostTime);
}

@end
