//
//  JRVideoDecoder.h
//  JRLive
//
//  Created by fan on 2020/9/28.
//

#ifndef JRVideoDecoder_h
#define JRVideoDecoder_h

#import <AVFoundation/AVFoundation.h>

@protocol VideoDecoder;
@protocol VideoDecoderDelegate <NSObject>

- (void)videoDecoder:(id)decoder didDecode:(CMSampleBufferRef)sampleBuffer isFirstFrame:(BOOL)isFirstFrame;

@end

@protocol VideoDecoder <NSObject>

@property (nonatomic, weak) id<VideoDecoderDelegate> delegate;

- (void)startDecodeData:(id)data;
- (void)stop;

@end


#endif /* JRVideoDecoder_h */
