//
//  JRFFmpegAudioDecoder.m
//  JRLive
//
//  Created by fan on 2020/9/28.
//

#import "JRFFmpegAudioDecoder.h"

@interface JRFFmpegAudioDecoder ()
{
    /*  FFmpeg  */
    AVFormatContext          *m_formatContext;
    AVCodecContext           *m_audioCodecContext;
    AVFrame                  *m_audioFrame;
    
    int     m_audioStreamIndex;
    BOOL    m_isFindIDR;
    int64_t m_base_time;
    BOOL    m_isFirstFrame;
}

@property (nonatomic, assign) int64_t baseTime;

@end

@implementation JRFFmpegAudioDecoder

#pragma mark - C Function
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

- (instancetype)initWithFormatContext:(AVFormatContext *)formatContext audioStreamIndex:(int)audioStreamIndex
{
    if (self = [super init]) {
        m_formatContext     = formatContext;
        m_audioStreamIndex  = audioStreamIndex;
        
        m_isFindIDR      = NO;
        m_base_time      = 0;
        m_isFirstFrame   = YES;
        [self initDecoder];
    }
    return self;
}

- (void)initDecoder
{
    AVStream *audioStream = m_formatContext->streams[m_audioStreamIndex];
    m_audioCodecContext = [self createAudioEncderWithFormatContext:m_formatContext
                                                            stream:audioStream
                                                  audioStreamIndex:m_audioStreamIndex];
    if (!m_audioCodecContext) {
        NSLog(@"create audio codec failed");
        return;
    }
    
    // Get audio frame
    m_audioFrame = av_frame_alloc();
    if (!m_audioFrame) {
        NSLog(@"alloc audio frame failed");
        avcodec_close(m_audioCodecContext);
    }
}

#pragma mark - Public
- (void)startDecodeAudioDataWithAVPacket:(AVPacket)packet
{
    [self startDecodeAudioDataWithAVPacket:packet
                         audioCodecContext:m_audioCodecContext
                                audioFrame:m_audioFrame
                                  baseTime:self.baseTime
                          audioStreamIndex:m_audioStreamIndex];
}

- (void)stopDecoder
{
    m_isFirstFrame   = YES;
    [self freeAllResources];
}

#pragma mark - Private

- (AVCodecContext *)createAudioEncderWithFormatContext:(AVFormatContext *)formatContext
                                                stream:(AVStream *)stream
                                      audioStreamIndex:(int)audioStreamIndex
{
    AVCodecContext *codecContext = formatContext->streams[audioStreamIndex]->codec;
    AVCodec *codec = avcodec_find_decoder(codecContext->codec_id);
    if (!codec) {
        NSLog(@"Not find audio codec");
        return NULL;
    }

    if (avcodec_open2(codecContext, codec, NULL) < 0) {
        NSLog(@"Can't open audio codec");
        return NULL;
    }

    return codecContext;
}

- (void)startDecodeAudioDataWithAVPacket:(AVPacket)packet
                       audioCodecContext:(AVCodecContext *)audioCodecContext
                              audioFrame:(AVFrame *)audioFrame
                                baseTime:(int64_t)baseTime
                        audioStreamIndex:(int)audioStreamIndex
{
    int result = avcodec_send_packet(audioCodecContext, &packet);
    if (result < 0) {
        NSLog(@"Send audio data to decoder failed.");
    } else {
        while (0 == avcodec_receive_frame(audioCodecContext, audioFrame)) {
            Float64 ptsSec = audioFrame->pts* av_q2d(m_formatContext->streams[audioStreamIndex]->time_base);
            struct SwrContext *au_convert_ctx = swr_alloc();
            au_convert_ctx = swr_alloc_set_opts(au_convert_ctx,
                                                AV_CH_LAYOUT_STEREO,
                                                AV_SAMPLE_FMT_S16,
                                                48000,
                                                audioCodecContext->channel_layout,
                                                audioCodecContext->sample_fmt,
                                                audioCodecContext->sample_rate,
                                                0,
                                                NULL);
            swr_init(au_convert_ctx);
            int out_linesize;
            int out_buffer_size = av_samples_get_buffer_size(&out_linesize,
                                                             audioCodecContext->channels,
                                                             audioCodecContext->frame_size,
                                                             audioCodecContext->sample_fmt,
                                                             1);
            
            uint8_t *out_buffer = (uint8_t *)av_malloc(out_buffer_size);
            // 解码
            swr_convert(au_convert_ctx, &out_buffer, out_linesize, (const uint8_t **)audioFrame->data , audioFrame->nb_samples);
            swr_free(&au_convert_ctx);
            au_convert_ctx = NULL;
            if ([self.delegate respondsToSelector:@selector(decoder:data:size:pts:isFirstFrame:)]) {
                [self.delegate decoder:self data:out_buffer size:out_buffer_size pts:ptsSec isFirstFrame:m_isFirstFrame];
                m_isFirstFrame=NO;
            }
            
            av_free(out_buffer);
        }
        
        if (result != 0) {
            NSLog(@"Decode finish.");
        }
    }
}


- (void)freeAllResources
{
    if (m_audioCodecContext) {
        avcodec_send_packet(m_audioCodecContext, NULL);
        avcodec_flush_buffers(m_audioCodecContext);
        
        if (m_audioCodecContext->hw_device_ctx) {
            av_buffer_unref(&m_audioCodecContext->hw_device_ctx);
            m_audioCodecContext->hw_device_ctx = NULL;
        }
        avcodec_close(m_audioCodecContext);
        m_audioCodecContext = NULL;
    }
    
    if (m_audioFrame) {
        av_free(m_audioFrame);
        m_audioFrame = NULL;
    }
}


@end
