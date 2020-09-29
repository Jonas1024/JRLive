//
//  JRFFmpegAudioDecoder.h
//  JRLive
//
//  Created by fan on 2020/9/28.
//

#import <AVFoundation/AVFoundation.h>

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

@class JRFFmpegAudioDecoder;
@protocol JRFFmpegAudioDecoderDelegate <NSObject>

- (void)audioDecoder:(JRFFmpegAudioDecoder *)decoder data:(void *)data size:(int)size pts:(int64_t)pts isFirstFrame:(BOOL)isFirstFrame;

@end

@interface JRFFmpegAudioDecoder : NSObject

@property (weak, nonatomic) id<JRFFmpegAudioDecoderDelegate> delegate;

- (instancetype)initWithFormatContext:(AVFormatContext *)formatContext audioStreamIndex:(int)audioStreamIndex;
- (void)startDecodeAudioDataWithAVPacket:(AVPacket)packet;
- (void)stop;

@end

