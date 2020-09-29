//
//  JRHardwareVideoDecoder.h
//  JRLive
//
//  Created by fan on 2020/9/28.
//

#import <Foundation/Foundation.h>
#import "JRLivePlayerTypes.h"

@class JRHardwareVideoDecoder;
@protocol JRHardwareVideoDecoderDelegate <NSObject>

- (void)videoDecoder:(JRHardwareVideoDecoder *)decoder didDecode:(CMSampleBufferRef)sampleBuffer isFirstFrame:(BOOL)isFirstFrame;

@end

@interface JRHardwareVideoDecoder : NSObject

@property (nonatomic, weak) id<JRHardwareVideoDecoderDelegate> delegate;

- (void)startDecodeData:(struct JRVideoDataInfo *)info;
- (void)stop;

@end

