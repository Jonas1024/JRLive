//
//  JRStreamPuller.h
//  JRLive
//
//  Created by fan on 2020/9/28.
//

#import <AVFoundation/AVFoundation.h>

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


typedef NS_ENUM(NSUInteger, JRVideoEncodeFormat) {
    JRVideoEncodeFormatH264,
    JRVideoEncodeFormatH265,
};

typedef NS_ENUM(NSUInteger, JRDecodeType) {
    JRDecodeTypeFFmpeg,
    JRDecodeTypeHardware,
};

struct JRVideoDataInfo {
    uint8_t                 *data;
    int                     dataSize;
    uint8_t                 *extraData;
    int                     extraDataSize;
    Float64                 pts;
    Float64                 time_base;
    int                     videoRotate;
    int                     fps;
    CMSampleTimingInfo      timingInfo;
    JRVideoEncodeFormat     videoFormat;
};

struct JRAudioDataInfo {
    uint8_t     *data;
    int         dataSize;
    int         channel;
    int         sampleRate;
    Float64     pts;
};

@class JRStreamPuller;

@protocol JRStreamPullerDelegate <NSObject>

- (void)puller:(JRStreamPuller *)puller videoDataInfo:(JRVideoDataInfo *)info;
- (void)puller:(JRStreamPuller *)puller audioDataInfo:(JRAudioDataInfo *)info;

- (void)puller:(JRStreamPuller *)puller videoPacket:(AVPacket *)packet;
- (void)puller:(JRStreamPuller *)puller audioPacket:(AVPacket *)packet;

- (void)pullerDidFinish:(JRStreamPuller *)puller;

@end

@interface JRStreamPuller : NSObject

@property (nonatomic, weak) id<JRStreamPullerDelegate> delegate;

- (instancetype)initWithURLString:(NSString *)urlString;

- (void)startWithDecodeType:(JRDecodeType)type;

///
- (AVFormatContext *)getFormatContext;
- (int)getVideoStreamIndex;
- (int)getAudioStreamIndex;

@end

