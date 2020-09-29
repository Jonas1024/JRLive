//
//  JRFFmpegVideoDecoder.h
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

NS_ASSUME_NONNULL_BEGIN

@class JRFFmpegVideoDecoder;
@protocol JRFFmpegVideoDecoderDlegate <NSObject>

- (void)videoDecoder:(JRFFmpegVideoDecoder *)decoder didDecode:(CMSampleBufferRef)sampleBuffer;

@end

@interface JRFFmpegVideoDecoder : NSObject

@property (nonatomic, weak) id<JRFFmpegVideoDecoderDlegate> delegate;

- (instancetype)initWithFormatContext:(AVFormatContext *)formatContext videoStreamIndex:(int)videoStreamIndex;

- (void)startDecodeData:(AVPacket)packet;
- (void)stop;

@end

NS_ASSUME_NONNULL_END
