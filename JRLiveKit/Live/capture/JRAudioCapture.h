//
//  JRAudioCapture.h
//  JRLive
//
//  Created by fan on 2020/9/27.
//

#import <Foundation/Foundation.h>
#import <AVFoundation/AVFoundation.h>
#import "JRLiveAudioConfiguration.h"

#pragma mark -- AudioCaptureNotification
/** compoentFialed will post the notification */
extern NSString *_Nullable const JRAudioComponentFailedToCreateNotification;

@class JRAudioCapture;
/** JRAudioCapture callback audioData */
@protocol JRAudioCaptureDelegate <NSObject>
- (void)captureOutput:(nullable JRAudioCapture *)capture audioData:(nullable NSData*)audioData;
@end

NS_ASSUME_NONNULL_BEGIN

@interface JRAudioCapture : NSObject

#pragma mark - Attribute
///=============================================================================
/// @name Attribute
///=============================================================================

/** The delegate of the capture. captureData callback */
@property (nullable, nonatomic, weak) id<JRAudioCaptureDelegate> delegate;

/** The muted control callbackAudioData,muted will memset 0.*/
@property (nonatomic, assign) BOOL muted;

/** The running control start capture or stop capture*/
@property (nonatomic, assign) BOOL running;

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
- (nullable instancetype)initWithAudioConfiguration:(nullable JRLiveAudioConfiguration *)configuration NS_DESIGNATED_INITIALIZER;

@end

NS_ASSUME_NONNULL_END
