//
//  JRStreamPuller.h
//  JRLive
//
//  Created by fan on 2020/9/28.
//

#import "JRLivePlayerTypes.h"

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

