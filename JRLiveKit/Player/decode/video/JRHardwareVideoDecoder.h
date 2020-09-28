//
//  JRHardwareVideoDecoder.h
//  JRLive
//
//  Created by fan on 2020/9/28.
//

#import <Foundation/Foundation.h>
#import "JRVideoDecoder.h"
#import "JRLivePlayerTypes.h"

@interface JRHardwareVideoDecoder : NSObject

@property (nonatomic, weak) id<VideoDecoderDelegate> delegate;

- (void)startDecodeData:(struct JRVideoDataInfo *)info;
- (void)stop;

@end

