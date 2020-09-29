//
//  JRAudioQueuePlayer.h
//  JRLive
//
//  Created by fan on 2020/9/29.
//

#import <Foundation/Foundation.h>
#import "JRQueueProcess.h"
#import <AVFoundation/AVFoundation.h>

@interface JRAudioQueuePlayer : NSObject
{
    @public
    JRCustomQueueProcess   *_audioBufferQueue;
}

@property (nonatomic, assign, readonly) BOOL isRunning;

/**
 configure player

 @param audioFormat audio format by ASBD
 @param bufferSize  audio queue buffer size
 */
- (void)configureAudioPlayerWithAudioFormat:(AudioStreamBasicDescription *)audioFormat
                                 bufferSize:(int)bufferSize;


/**
 * Control player
 */
- (void)startAudioPlayer;
- (void)pauseAudioPlayer;
- (void)resumeAudioPlayer;
- (void)stopAudioPlayer;
- (void)freeAudioPlayer;


/**
 * get audio queue buffer size
 */
+ (int)audioBufferSize;

+ (instancetype)sharedObject;

@end

