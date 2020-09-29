//
//  JRLivePlayer.m
//  JRLive
//
//  Created by fan on 2020/9/28.
//

#import "JRLivePlayer.h"
#import "JRStreamPuller.h"
#import "JRFFmpegAudioDecoder.h"
#import "JRFFmpegVideoDecoder.h"
#import "JRHardwareVideoDecoder.h"
#import "JRHardwareAudioDecoder.h"
#import "JRPlayerView.h"
#import "JRAudioQueuePlayer.h"
#import "JRSortFrameHandler.h"


int kJRBufferSize = 4096;

@interface JRLivePlayer ()
<
JRStreamPullerDelegate,
JRFFmpegAudioDecoderDelegate,
JRFFmpegVideoDecoderDlegate,
JRHardwareVideoDecoderDelegate,
JRHardwareAudioDecoderDelegate
>

@property (nonatomic, strong) JRStreamPuller *puller;

@property (nonatomic, strong) JRFFmpegAudioDecoder *ffAudioDecoder;
@property (nonatomic, strong) JRFFmpegVideoDecoder *ffVideoDecoder;
@property (nonatomic, strong) JRHardwareAudioDecoder *hwAudioDecoder;
@property (nonatomic, strong) JRHardwareVideoDecoder *hwVideoDecoder;

@property (nonatomic, strong) JRPlayerView *playerView;
@property (nonatomic, strong) JRAudioQueuePlayer *audioPlayer;

///
@property (nonatomic, assign) BOOL isUseFFmpeg;

@property (nonatomic, assign) BOOL hasBFrame;
@property (nonatomic, strong) JRSortFrameHandler *sortHandler;

@property (nonatomic, assign) BOOL isFindIDR;

@property (nonatomic, assign) CGRect frame;

@end

@implementation JRLivePlayer

- (instancetype)initWithFrame:(CGRect)frame
{
    self = [super init];
    if (self) {
        self.frame = frame;
        self.isUseFFmpeg = YES;
    }
    return self;
}

#pragma mark - public

- (void)configWithURLString:(NSString *)urlString
{
    self.puller = [[JRStreamPuller alloc] initWithURLString:urlString];
    self.puller.delegate = self;
    if (self.isUseFFmpeg) {
        self.ffVideoDecoder = [[JRFFmpegVideoDecoder alloc] initWithFormatContext:[self.puller getFormatContext] videoStreamIndex:[self.puller getVideoStreamIndex]];
        self.ffVideoDecoder.delegate = self;
        self.ffAudioDecoder = [[JRFFmpegAudioDecoder alloc] initWithFormatContext:[self.puller getFormatContext] audioStreamIndex:[self.puller getAudioStreamIndex]];
        self.ffAudioDecoder.delegate = self;
    } else {
        
        // Origin file aac format
        AudioStreamBasicDescription audioFormat = {
            .mSampleRate         = 48000,
            .mFormatID           = kAudioFormatMPEG4AAC,
            .mChannelsPerFrame   = 2,
            .mFramesPerPacket    = 1024,
        };
        self.hwAudioDecoder = [[JRHardwareAudioDecoder alloc] initWithSourceFormat:audioFormat destFormatID:kAudioFormatLinearPCM sampleRate:48000];
        self.hwAudioDecoder.delegate = self;
        self.hwVideoDecoder = [[JRHardwareVideoDecoder alloc] init];
        self.hwVideoDecoder.delegate = self;
    }
    
    self.playerView = [[JRPlayerView alloc] initWithFrame:self.frame];
    
    [self configureAudioPlayer];
}

- (void)startPlayer
{
    [self.puller startWithDecodeType:self.isUseFFmpeg ? JRDecodeTypeFFmpeg : JRDecodeTypeHardware];
}

- (void)stopPlayer
{
    
}

- (UIView *)preview
{
    return self.playerView;
}

#pragma mark - config

- (void)configureAudioPlayer
{
    // Final Audio Player format : This is only for the FFmpeg to decode.
    AudioStreamBasicDescription ffmpegAudioFormat = {
        .mSampleRate         = 48000,
        .mFormatID           = kAudioFormatLinearPCM,
        .mChannelsPerFrame   = 2,
        .mFormatFlags        = kLinearPCMFormatFlagIsSignedInteger | kLinearPCMFormatFlagIsPacked,
        .mBitsPerChannel     = 16,
        .mBytesPerPacket     = 4,
        .mBytesPerFrame      = 4,
        .mFramesPerPacket    = 1,
    };
    
    // Final Audio Player format : This is only for audio converter format.
    AudioStreamBasicDescription systemAudioFormat = {
        .mSampleRate         = 48000,
        .mFormatID           = kAudioFormatLinearPCM,
        .mChannelsPerFrame   = 1,
        .mFormatFlags        = kLinearPCMFormatFlagIsSignedInteger | kLinearPCMFormatFlagIsPacked,
        .mBitsPerChannel     = 16,
        .mBytesPerPacket     = 2,
        .mBytesPerFrame      = 2,
        .mFramesPerPacket    = 1,
    };
    
    // Configure Audio Queue Player
    [[JRAudioQueuePlayer sharedObject] configureAudioPlayerWithAudioFormat:self.isUseFFmpeg ? &ffmpegAudioFormat : &systemAudioFormat bufferSize:kJRBufferSize];
    [[JRAudioQueuePlayer sharedObject] startAudioPlayer];
}

#pragma mark - delegate

- (void)puller:(JRStreamPuller *)puller audioDataInfo:(JRAudioDataInfo *)info
{
    [self.hwAudioDecoder decodeAudioWithSourceBuffer:info->data sourceBufferSize:info->dataSize pts:info->pts];
}

- (void)puller:(JRStreamPuller *)puller audioPacket:(AVPacket *)packet
{
    [self.ffAudioDecoder startDecodeAudioDataWithAVPacket:*packet];
}

- (void)puller:(JRStreamPuller *)puller videoDataInfo:(JRVideoDataInfo *)info
{
    [self.hwVideoDecoder startDecodeData:info];
}

- (void)puller:(JRStreamPuller *)puller videoPacket:(AVPacket *)packet
{
    if ((*packet).flags == 1 && self.isFindIDR == NO) {
        self.isFindIDR = YES;
    }
    
    if (!self.isFindIDR) {
        return;
    }
    [self.ffVideoDecoder startDecodeData:*packet];
}

- (void)pullerDidFinish:(JRStreamPuller *)puller
{
    [self.ffVideoDecoder stop];
    [self.hwVideoDecoder stop];
    [self.ffAudioDecoder stop];
    [self.hwAudioDecoder stop];
}

- (void)audioDecoder:(JRFFmpegAudioDecoder *)decoder
                data:(void *)data
                size:(int)size
                 pts:(int64_t)pts
        isFirstFrame:(BOOL)isFirstFrame
{
    [self addBufferToWorkQueueWithAudioData:data size:size pts:pts];
    
    // control rate
    usleep(14.5*1000);
}

- (void)videoDecoder:(nonnull JRFFmpegVideoDecoder *)decoder didDecode:(nonnull CMSampleBufferRef)sampleBuffer
{
    CVPixelBufferRef pixelBuffer = CMSampleBufferGetImageBuffer(sampleBuffer);
    [self.playerView displayPixelBuffer:pixelBuffer];
}

- (void)videoDecoder:(JRHardwareVideoDecoder *)decoder didDecode:(CMSampleBufferRef)sampleBuffer isFirstFrame:(BOOL)isFirstFrame
{
    //TODO b frame
    if (self.hasBFrame) {
        // Note : the first frame not need to sort.
//        if (isFirstFrame) {
//            CVPixelBufferRef pixelBuffer = CMSampleBufferGetImageBuffer(sampleBuffer);
//            [self.playerView displayPixelBuffer:pixelBuffer];
//            return;
//        }
//
//        [self.sortHandler addDataToLinkList:sampleBuffer];
    }else {
        CVPixelBufferRef pixelBuffer = CMSampleBufferGetImageBuffer(sampleBuffer);
        [self.playerView displayPixelBuffer:pixelBuffer];
    }
}

- (void)audioDecoder:(nonnull JRHardwareAudioDecoder *)decoder destBufferList:(nonnull AudioBufferList *)destBufferList outputPackets:(UInt32)outputPackets outputPacketDescriptions:(nonnull AudioStreamPacketDescription *)outputPacketDescriptions pts:(int64_t)pts
{
    // Put audio data from audio file into audio data queue
    [self addBufferToWorkQueueWithAudioData:destBufferList->mBuffers->mData size:destBufferList->mBuffers->mDataByteSize pts:pts];

    // control rate
    usleep(16.8*1000);
}

- (void)addBufferToWorkQueueWithAudioData:(void *)data size:(int)size pts:(int64_t)pts
{
    JRCustomQueueProcess *audioBufferQueue =  [JRAudioQueuePlayer sharedObject]->_audioBufferQueue;
    
    JRCustomQueueNode *node = audioBufferQueue->DeQueue(audioBufferQueue->m_free_queue);
    if (node == NULL) {
        return;
    }
    
    node->pts  = pts;
    node->size = size;
    memcpy(node->data, data, size);
    audioBufferQueue->EnQueue(audioBufferQueue->m_work_queue, node);
    
    NSLog(@"Test Data in ,  work size = %d, free size = %d !",audioBufferQueue->m_work_queue->size, audioBufferQueue->m_free_queue->size);
}


@end
