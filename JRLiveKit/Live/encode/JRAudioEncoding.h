//
//  JRAudioEncoding.h
//  JRLive
//
//  Created by fan on 2020/9/27.
//

#import <Foundation/Foundation.h>
#import <AVFoundation/AVFoundation.h>
#import "JRAudioFrame.h"
#import "JRLiveAudioConfiguration.h"

@protocol JRAudioEncoding;
/// 编码器编码后回调
@protocol JRAudioEncodingDelegate <NSObject>

@required
- (void)audioEncoder:(nullable id<JRAudioEncoding>)encoder audioFrame:(nullable JRAudioFrame *)frame;

@end

/// 编码器抽象的接口
@protocol JRAudioEncoding <NSObject>

@required
- (void)encodeAudioData:(nullable NSData*)audioData timeStamp:(uint64_t)timeStamp;

- (void)stopEncoder;

@optional
- (nullable instancetype)initWithAudioStreamConfiguration:(nullable JRLiveAudioConfiguration *)configuration;

- (void)setDelegate:(nullable id<JRAudioEncodingDelegate>)delegate;

- (nullable NSData *)adtsData:(NSInteger)channel rawDataLength:(NSInteger)rawDataLength;

@end

