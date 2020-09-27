//
//  JRStreamingBuffer.h
//  JRLive
//
//  Created by fan on 2020/9/27.
//

#import <Foundation/Foundation.h>
#import "JRAudioFrame.h"
#import "JRVideoFrame.h"

/** current buffer status */
typedef NS_ENUM (NSUInteger, JRLiveBuffferState) {
    JRLiveBuffferUnknown = 0,      // 未知
    JRLiveBuffferIncrease = 1,    // 缓冲区状态差应该降低码率
    JRLiveBuffferDecline = 2      // 缓冲区状态好应该提升码率
};

@class JRStreamingBuffer;
/** this two method will control videoBitRate */
@protocol JRStreamingBufferDelegate <NSObject>

@optional
/** 当前buffer变动（增加or减少） 根据buffer中的updateInterval时间回调*/
- (void)streamingBuffer:(nullable JRStreamingBuffer *)buffer bufferState:(JRLiveBuffferState)state;
@end


@interface JRStreamingBuffer : NSObject

/** The delegate of the buffer. buffer callback */
@property (nullable, nonatomic, weak) id <JRStreamingBufferDelegate> delegate;

/** current frame buffer */
@property (nonatomic, strong, readonly) NSMutableArray <JRFrame *> *_Nonnull list;

/** buffer count max size default 1000 */
@property (nonatomic, assign) NSUInteger maxCount;

/** count of drop frames in last time */
@property (nonatomic, assign) NSInteger lastDropFrames;

/** add frame to buffer */
- (void)appendObject:(nullable JRFrame *)frame;

/** pop the first frome buffer */
- (nullable JRFrame *)popFirstObject;

/** remove all objects from Buffer */
- (void)removeAllObject;

@end

