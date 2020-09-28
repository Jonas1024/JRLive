//
//  JRLivePlayerTypes.h
//  JRLive
//
//  Created by fan on 2020/9/28.
//

#import <Foundation/Foundation.h>
#import <AVFoundation/AVFoundation.h>

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
