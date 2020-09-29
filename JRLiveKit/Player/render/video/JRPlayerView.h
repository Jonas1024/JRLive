//
//  JRPlayerView.h
//  JRLive
//
//  Created by fan on 2020/9/29.
//

#import <UIKit/UIKit.h>

@interface JRPlayerView : UIView

/**
 Whether full the screen
 */
@property (nonatomic, assign, getter=isFullScreen) BOOL fullScreen;

/**
 display
 */
- (void)displayPixelBuffer:(CVPixelBufferRef)pixelBuffer;

@end

