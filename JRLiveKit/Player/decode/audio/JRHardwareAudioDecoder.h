//
//  JRHardwareAudioDecoder.h
//  JRLive
//
//  Created by fan on 2020/9/28.
//

#import <Foundation/Foundation.h>
#import <AudioToolbox/AudioToolbox.h>

NS_ASSUME_NONNULL_BEGIN

@class JRHardwareAudioDecoder;
@protocol JRHardwareAudioDecoderDelegate <NSObject>

- (void)decoder:(JRHardwareAudioDecoder *)decoder destBufferList:(AudioBufferList *)destBufferList outputPackets:(UInt32)outputPackets outputPacketDescriptions:(AudioStreamPacketDescription *)outputPacketDescriptions;

@end

@interface JRHardwareAudioDecoder : NSObject
{
    @public
    AudioConverterRef           mAudioConverter;
    AudioStreamBasicDescription mDestinationFormat;
    AudioStreamBasicDescription mSourceFormat;
}

@property (nonatomic, weak) id<JRHardwareAudioDecoderDelegate> delegate;

/**
 Init Audio Encoder
 @param sourceFormat source audio data format
 @param destFormatID destination audio data format
 @return object.
 */
- (instancetype)initWithSourceFormat:(AudioStreamBasicDescription)sourceFormat
                        destFormatID:(AudioFormatID)destFormatID
                          sampleRate:(float)sampleRate;

/**
 Encode Audio Data
 @param sourceBuffer source audio data
 @param sourceBufferSize source audio data size
 */
- (void)decodeAudioWithSourceBuffer:(void *)sourceBuffer
                   sourceBufferSize:(UInt32)sourceBufferSize;


- (void)freeDecoder;

@end

NS_ASSUME_NONNULL_END
