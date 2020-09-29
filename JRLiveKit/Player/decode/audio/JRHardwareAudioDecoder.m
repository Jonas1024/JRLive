//
//  JRHardwareAudioDecoder.m
//  JRLive
//
//  Created by fan on 2020/9/28.
//

#import "JRHardwareAudioDecoder.h"

#define kAudioPCMFramesPerPacket 1
#define KAudioBitsPerChannel     16
#define kIOOutputDataPackets     1024

struct ConverterInfo {
    UInt32   sourceChannelsPerFrame;
    UInt32   sourceDataSize;
    void     *sourceBuffer;
    AudioStreamPacketDescription packetDesc;
};

@implementation JRHardwareAudioDecoder

#pragma mark - Decode Callback
OSStatus DecodeConverterComplexInputDataProc(AudioConverterRef              inAudioConverter,
                                             UInt32                         *ioNumberDataPackets,
                                             AudioBufferList                *ioData,
                                             AudioStreamPacketDescription   **outDataPacketDescription,
                                             void                           *inUserData) {
    struct ConverterInfo *info = (struct ConverterInfo *)inUserData;
    
    if (info->sourceDataSize <= 0) {
        ioNumberDataPackets = 0;
        return -1;
    }
    
    *outDataPacketDescription = &info->packetDesc;
    (*outDataPacketDescription)[0].mStartOffset             = 0;
    (*outDataPacketDescription)[0].mDataByteSize            = info->sourceDataSize;
    (*outDataPacketDescription)[0].mVariableFramesInPacket  = 0;
    
    ioData->mNumberBuffers              = 1;
    ioData->mBuffers[0].mData           = info->sourceBuffer;
    ioData->mBuffers[0].mNumberChannels = info->sourceChannelsPerFrame;
    ioData->mBuffers[0].mDataByteSize   = info->sourceDataSize;
    
    return noErr;
}

- (instancetype)initWithSourceFormat:(AudioStreamBasicDescription)sourceFormat
                        destFormatID:(AudioFormatID)destFormatID
                          sampleRate:(float)sampleRate
{
    if (self = [super init]) {
        mSourceFormat   = sourceFormat;
        mAudioConverter = [self configureDecoderBySourceFormat:sourceFormat
                                                    destFormat:&mDestinationFormat
                                                  destFormatID:destFormatID
                                                    sampleRate:sampleRate];
    }
    return self;
}

- (void)decodeAudioWithSourceBuffer:(void *)sourceBuffer sourceBufferSize:(UInt32)sourceBufferSize
{
    [self decodeFormatByConverter:mAudioConverter
                     sourceBuffer:sourceBuffer
                 sourceBufferSize:sourceBufferSize
                     sourceFormat:mSourceFormat
                             dest:mDestinationFormat];
}

- (void)freeDecoder
{
    if (mAudioConverter) {
        AudioConverterDispose(mAudioConverter);
        mAudioConverter = NULL;
    }
}

- (void)decodeFormatByConverter:(AudioConverterRef)audioConverter sourceBuffer:(void *)sourceBuffer sourceBufferSize:(UInt32)sourceBufferSize sourceFormat:(AudioStreamBasicDescription)sourceFormat dest:(AudioStreamBasicDescription)destFormat
{
    // Note: audio convert must set 1024.
    UInt32 ioOutputDataPackets = kIOOutputDataPackets;
    UInt32 outputBufferSize = (UInt32)(ioOutputDataPackets * destFormat.mChannelsPerFrame * destFormat.mBytesPerFrame);
    // Set up output buffer list.
    AudioBufferList fillBufferList = {0};
    fillBufferList.mNumberBuffers = 1;
    fillBufferList.mBuffers[0].mNumberChannels  = destFormat.mChannelsPerFrame;
    fillBufferList.mBuffers[0].mDataByteSize    = outputBufferSize;
    fillBufferList.mBuffers[0].mData            = malloc(outputBufferSize * sizeof(char));
    
    struct ConverterInfo userInfo        = {0};
    userInfo.sourceBuffer                = sourceBuffer;
    userInfo.sourceDataSize              = sourceBufferSize;
    userInfo.sourceChannelsPerFrame      = sourceFormat.mChannelsPerFrame;
    userInfo.packetDesc.mDataByteSize    = (UInt32)sourceBufferSize;
    userInfo.packetDesc.mStartOffset     = 0;
    userInfo.packetDesc.mVariableFramesInPacket = 0;
    
    AudioStreamPacketDescription outputPacketDesc = {0};
    OSStatus status = AudioConverterFillComplexBuffer(audioConverter,
                                                      DecodeConverterComplexInputDataProc,
                                                      &userInfo,
                                                      &ioOutputDataPackets,
                                                      &fillBufferList,
                                                      &outputPacketDesc);
    
    // if interrupted in the process of the conversion call, we must handle the error appropriately
    if (status != noErr) {
        if (status == kAudioConverterErr_HardwareInUse) {
            printf("Audio Converter returned kAudioConverterErr_HardwareInUse!\n");
        } else {
            if (![self checkError:status withErrorString:@"AudioConverterFillComplexBuffer error!"]) {
                return;
            }
        }
    } else {
        if (ioOutputDataPackets == 0) {
            // This is the EOF condition.
            status = noErr;
        }
        
        if ([self.delegate respondsToSelector:@selector(decoder:destBufferList:outputPackets:outputPacketDescriptions:)]) {
            [self.delegate decoder:self destBufferList:&fillBufferList outputPackets:ioOutputDataPackets outputPacketDescriptions:&outputPacketDesc];
        }
    }
}

#pragma mark - Private

- (AudioConverterRef)configureDecoderBySourceFormat:(AudioStreamBasicDescription)sourceFormat
                                         destFormat:(AudioStreamBasicDescription *)destFormat
                                       destFormatID:(AudioFormatID)destFormatID
                                         sampleRate:(float)sampleRate
{
    AudioStreamBasicDescription destinationFormat = {0};
    destinationFormat.mSampleRate = sampleRate;
    if (destFormatID != kAudioFormatLinearPCM) {
        NSLog(@"Not get compression format after decoding !");
        return NULL;
    } else {
        destinationFormat.mFormatID = destFormatID;
        destinationFormat.mChannelsPerFrame  = 1;
        destinationFormat.mFormatID          = kAudioFormatLinearPCM;
        destinationFormat.mFormatFlags       = (kAudioFormatFlagIsSignedInteger | kAudioFormatFlagIsPacked);
        destinationFormat.mFramesPerPacket   = kAudioPCMFramesPerPacket;
        destinationFormat.mBitsPerChannel    = KAudioBitsPerChannel;
        destinationFormat.mBytesPerFrame     = destinationFormat.mBitsPerChannel / 8 *destinationFormat.mChannelsPerFrame;
        destinationFormat.mBytesPerPacket    = destinationFormat.mBytesPerFrame * destinationFormat.mFramesPerPacket;
        destinationFormat.mReserved          =  0;
    }
    memcpy(destFormat, &destinationFormat, sizeof(AudioStreamBasicDescription));
    
    printf("Source File format:\n");
    [JRHardwareAudioDecoder printAudioStreamBasicDescription:sourceFormat];
    printf("Destination File format:\n");
    [JRHardwareAudioDecoder printAudioStreamBasicDescription:destinationFormat];
    
    //获取解码器的描述信息
    AudioClassDescription *audioClassDesc = [self getAudioCalssDescriptionWithType:destFormatID fromManufacture:kAppleHardwareAudioCodecManufacturer];
    
    // Create the AudioConverterRef.
    AudioConverterRef converter = NULL;
    if (![self checkError:AudioConverterNewSpecific(&sourceFormat, &destinationFormat, destinationFormat.mChannelsPerFrame, audioClassDesc, &converter) withErrorString:@"Audio Converter New failed"]) {
        return NULL;
    }else {
        printf("Audio converter create successful \n");
    }
    
    return converter;
}

- (AudioClassDescription *)getAudioCalssDescriptionWithType:(AudioFormatID)type
                                            fromManufacture:(uint32_t)manufacture
{
    static AudioClassDescription desc;
    UInt32 decoderSpecific = type;
    UInt32 size;
    OSStatus status = AudioFormatGetPropertyInfo(kAudioFormatProperty_Decoders,
                                                 sizeof(decoderSpecific),
                                                 &decoderSpecific,
                                                 &size);
    
    if (status != noErr) {
        NSLog(@"Error！：硬解码AAC get info 失败, status= %d", (int)status);
        return nil;
    }
    
    //计算aac解码器的个数
    unsigned int count = size / sizeof(AudioClassDescription);
    //创建一个包含count个解码器的数组
    AudioClassDescription description[count];
    //将满足aac解码的解码器的信息写入数组
    status = AudioFormatGetProperty(kAudioFormatProperty_Encoders,
                                    sizeof(decoderSpecific),
                                    &decoderSpecific,
                                    &size,
                                    &description);
    
    if (status != noErr) {
        NSLog(@"Error！：硬解码AAC get propery 失败, status= %d", (int)status);
        return nil;
    }
    
    for (unsigned int i = 0; i < count; i++) {
        if (type == description[i].mSubType && manufacture == description[i].mManufacturer) {
            desc = description[i];
            return &desc;
        }
    }
    return nil;
}

- (BOOL)checkError:(OSStatus)error withErrorString:(NSString *)string {
    if (error == noErr) {
        return YES;
    }
    
    NSError *err = [NSError errorWithDomain:@"AudioFileConvertOperationErrorDomain" code:error userInfo:@{NSLocalizedDescriptionKey : string}];
    NSLog(@"%@", err);
    return NO;
}

+ (void)printAudioStreamBasicDescription:(AudioStreamBasicDescription)asbd {
    char formatID[5];
    UInt32 mFormatID = CFSwapInt32HostToBig(asbd.mFormatID);
    bcopy (&mFormatID, formatID, 4);
    formatID[4] = '\0';
    printf("Sample Rate:         %10.0f\n",  asbd.mSampleRate);
    printf("Format ID:           %10s\n",    formatID);
    printf("Format Flags:        %10X\n",    (unsigned int)asbd.mFormatFlags);
    printf("Bytes per Packet:    %10d\n",    (unsigned int)asbd.mBytesPerPacket);
    printf("Frames per Packet:   %10d\n",    (unsigned int)asbd.mFramesPerPacket);
    printf("Bytes per Frame:     %10d\n",    (unsigned int)asbd.mBytesPerFrame);
    printf("Channels per Frame:  %10d\n",    (unsigned int)asbd.mChannelsPerFrame);
    printf("Bits per Channel:    %10d\n",    (unsigned int)asbd.mBitsPerChannel);
    printf("\n");
}


@end
