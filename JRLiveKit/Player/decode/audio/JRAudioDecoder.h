//
//  JRAudioDecoder.h
//  JRLive
//
//  Created by fan on 2020/9/28.
//

#ifndef JRAudioDecoder_h
#define JRAudioDecoder_h

#import <AVFoundation/AVFoundation.h>

@protocol AudioDecoder;
@protocol AudioDecoderDelegate <NSObject>

- (void)audioDecodera:(id<AudioDecoder>)decoder didDecode:(CMSampleBufferRef)sampleBuffer;

@end

@protocol AudioDecoder <NSObject>

- (void)decodeData:(id)data;
- (void)stop;

@end

#endif /* JRAudioDecoder_h */
