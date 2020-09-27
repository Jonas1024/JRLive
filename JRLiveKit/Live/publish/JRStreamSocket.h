//
//  JRStreamSocket.h
//  JRLive
//
//  Created by fan on 2020/9/27.
//

#import <Foundation/Foundation.h>
#import "JRLiveStreamInfo.h"
#import "JRStreamingBuffer.h"
#import "JRLiveDebug.h"



@protocol JRStreamSocket;
@protocol JRStreamSocketDelegate <NSObject>

/** callback buffer current status (回调当前缓冲区情况，可实现相关切换帧率 码率等策略)*/
- (void)socketBufferStatus:(nullable id <JRStreamSocket>)socket status:(JRLiveBuffferState)status;
/** callback socket current status (回调当前网络情况) */
- (void)socketStatus:(nullable id <JRStreamSocket>)socket status:(JRLiveState)status;
/** callback socket errorcode */
- (void)socketDidError:(nullable id <JRStreamSocket>)socket errorCode:(JRLiveSocketErrorCode)errorCode;

@optional
/** callback debugInfo */
- (void)socketDebug:(nullable id <JRStreamSocket>)socket debugInfo:(nullable JRLiveDebug *)debugInfo;

@end

@protocol JRStreamSocket <NSObject>

- (void)start;
- (void)stop;
- (void)sendFrame:(nullable JRFrame *)frame;
- (void)setDelegate:(nullable id <JRStreamSocketDelegate>)delegate;

@optional
- (nullable instancetype)initWithStream:(nullable JRLiveStreamInfo *)stream;
- (nullable instancetype)initWithStream:(nullable JRLiveStreamInfo *)stream reconnectInterval:(NSInteger)reconnectInterval reconnectCount:(NSInteger)reconnectCount;
@end
