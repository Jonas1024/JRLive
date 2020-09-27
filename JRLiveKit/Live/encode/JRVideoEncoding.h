//
//  JRVideoEncoding.h
//  JRLive
//
//  Created by fan on 2020/9/27.
//

#import <Foundation/Foundation.h>

#import "JRVideoFrame.h"
#import "JRLiveVideoConfiguration.h"

@protocol JRVideoEncoding;

/// 编码器编码后回调
@protocol JRVideoEncodingDelegate <NSObject>

@required
- (void)videoEncoder:(nullable id<JRVideoEncoding>)encoder videoFrame:(nullable JRVideoFrame *)frame;

@end

/// 编码器抽象的接口
@protocol JRVideoEncoding <NSObject>

@required
- (void)encodeVideoData:(nullable CVPixelBufferRef)pixelBuffer timeStamp:(uint64_t)timeStamp;

@optional
@property (nonatomic, assign) NSInteger videoBitRate;

- (nullable instancetype)initWithVideoStreamConfiguration:(nullable JRLiveVideoConfiguration *)configuration;

- (void)setDelegate:(nullable id<JRVideoEncodingDelegate>)delegate;

- (void)stopEncoder;
@end
