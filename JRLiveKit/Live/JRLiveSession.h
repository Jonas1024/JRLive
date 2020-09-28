//
//  JRLiveSession.h
//  JRLive
//
//  Created by fan on 2020/9/27.
//

#import <Foundation/Foundation.h>
#import <AVFoundation/AVFoundation.h>
#import "JRLiveStreamInfo.h"
#import "JRAudioFrame.h"
#import "JRVideoFrame.h"
#import "JRLiveAudioConfiguration.h"
#import "JRLiveVideoConfiguration.h"
#import "JRLiveDebug.h"


typedef NS_ENUM(NSInteger,JRLiveCaptureType) {
    JRLiveCaptureAudio,         //< capture only audio
    JRLiveCaptureVideo,         //< capture onlt video
    JRLiveInputAudio,           //< only audio (External input audio)
    JRLiveInputVideo,           //< only video (External input video)
};


///< 用来控制采集类型（可以内部采集也可以外部传入等各种组合，支持单音频与单视频,外部输入适用于录屏，无人机等外设介入）
typedef NS_ENUM(NSInteger,JRLiveCaptureTypeMask) {
    JRLiveCaptureMaskAudio = (1 << JRLiveCaptureAudio),                                 ///< only inner capture audio (no video)
    JRLiveCaptureMaskVideo = (1 << JRLiveCaptureVideo),                                 ///< only inner capture video (no audio)
    JRLiveInputMaskAudio = (1 << JRLiveInputAudio),                                     ///< only outer input audio (no video)
    JRLiveInputMaskVideo = (1 << JRLiveInputVideo),                                     ///< only outer input video (no audio)
    JRLiveCaptureMaskAll = (JRLiveCaptureMaskAudio | JRLiveCaptureMaskVideo),           ///< inner capture audio and video
    JRLiveInputMaskAll = (JRLiveInputMaskAudio | JRLiveInputMaskVideo),                 ///< outer input audio and video(method see pushVideo and pushAudio)
    JRLiveCaptureMaskAudioInputVideo = (JRLiveCaptureMaskAudio | JRLiveInputMaskVideo), ///< inner capture audio and outer input video(method pushVideo and setRunning)
    JRLiveCaptureMaskVideoInputAudio = (JRLiveCaptureMaskVideo | JRLiveInputMaskAudio), ///< inner capture video and outer input audio(method pushAudio and setRunning)
    JRLiveCaptureDefaultMask = JRLiveCaptureMaskAll                                     ///< default is inner capture audio and video
};

@class JRLiveSession;
@protocol JRLiveSessionDelegate <NSObject>

@optional
/** live status changed will callback */
- (void)liveSession:(nullable JRLiveSession *)session liveStateDidChange:(JRLiveState)state;
/** live debug info callback */
- (void)liveSession:(nullable JRLiveSession *)session debugInfo:(nullable JRLiveDebug *)debugInfo;
/** callback socket errorcode */
- (void)liveSession:(nullable JRLiveSession *)session errorCode:(JRLiveSocketErrorCode)errorCode;
@end

@class JRLiveStreamInfo;

@interface JRLiveSession : NSObject

#pragma mark - Attribute
///=============================================================================
/// @name Attribute
///=============================================================================
/** The delegate of the capture. captureData callback */
@property (nullable, nonatomic, weak) id<JRLiveSessionDelegate> delegate;

/** The running control start capture or stop capture*/
@property (nonatomic, assign) BOOL running;

/** The preView will show OpenGL ES view*/
@property (nonatomic, strong, null_resettable) UIView *preView;

/** The captureDevicePosition control camraPosition ,default front*/
@property (nonatomic, assign) AVCaptureDevicePosition captureDevicePosition;

/** The beautyFace control capture shader filter empty or beautiy */
@property (nonatomic, assign) BOOL beautyFace;

/** The beautyLevel control beautyFace Level. Default is 0.5, between 0.0 ~ 1.0 */
@property (nonatomic, assign) CGFloat beautyLevel;

/** The brightLevel control brightness Level, Default is 0.5, between 0.0 ~ 1.0 */
@property (nonatomic, assign) CGFloat brightLevel;

/** The torch control camera zoom scale default 1.0, between 1.0 ~ 3.0 */
@property (nonatomic, assign) CGFloat zoomScale;

/** The torch control capture flash is on or off */
@property (nonatomic, assign) BOOL torch;

/** The mirror control mirror of front camera is on or off */
@property (nonatomic, assign) BOOL mirror;

/** The muted control callbackAudioData,muted will memset 0.*/
@property (nonatomic, assign) BOOL muted;

/*  The adaptiveBitrate control auto adjust bitrate. Default is NO */
@property (nonatomic, assign) BOOL adaptiveBitrate;

/** The stream control upload and package*/
@property (nullable, nonatomic, strong, readonly) JRLiveStreamInfo *streamInfo;

/** The status of the stream .*/
@property (nonatomic, assign, readonly) JRLiveState state;

/** The captureType control inner or outer audio and video .*/
@property (nonatomic, assign, readonly) JRLiveCaptureTypeMask captureType;

/** The showDebugInfo control streamInfo and uploadInfo(1s) *.*/
@property (nonatomic, assign) BOOL showDebugInfo;

/** The reconnectInterval control reconnect timeInterval(重连间隔) *.*/
@property (nonatomic, assign) NSUInteger reconnectInterval;

/** The reconnectCount control reconnect count (重连次数) *.*/
@property (nonatomic, assign) NSUInteger reconnectCount;

/*** The warterMarkView control whether the watermark is displayed or not ,if set ni,will remove watermark,otherwise add.
 set alpha represent mix.Position relative to outVideoSize.
 *.*/
@property (nonatomic, strong, nullable) UIView *warterMarkView;

/* The currentImage is videoCapture shot */
@property (nonatomic, strong,readonly ,nullable) UIImage *currentImage;

/* The saveLocalVideo is save the local video */
@property (nonatomic, assign) BOOL saveLocalVideo;

/* The saveLocalVideoPath is save the local video  path */
@property (nonatomic, strong, nullable) NSURL *saveLocalVideoPath;

#pragma mark - Initializer
///=============================================================================
/// @name Initializer
///=============================================================================
- (nullable instancetype)init UNAVAILABLE_ATTRIBUTE;
+ (nullable instancetype)new UNAVAILABLE_ATTRIBUTE;

/**
   The designated initializer. Multiple instances with the same configuration will make the
   capture unstable.
 */
- (nullable instancetype)initWithAudioConfiguration:(nullable JRLiveAudioConfiguration *)audioConfiguration videoConfiguration:(nullable JRLiveVideoConfiguration *)videoConfiguration;

/**
 The designated initializer. Multiple instances with the same configuration will make the
 capture unstable.
 */
- (nullable instancetype)initWithAudioConfiguration:(nullable JRLiveAudioConfiguration *)audioConfiguration videoConfiguration:(nullable JRLiveVideoConfiguration *)videoConfiguration captureType:(JRLiveCaptureTypeMask)captureType NS_DESIGNATED_INITIALIZER;

/** The start stream .*/
- (void)startLive:(nonnull JRLiveStreamInfo *)streamInfo;

/** The stop stream .*/
- (void)stopLive;

/** support outer input yuv or rgb video(set JRLiveCaptureTypeMask) .*/
- (void)pushVideo:(nullable CVPixelBufferRef)pixelBuffer;

/** support outer input pcm audio(set JRLiveCaptureTypeMask) .*/
- (void)pushAudio:(nullable NSData*)audioData;

@end

