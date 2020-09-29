//
//  JRSortFrameHandler.h
//  JRLive
//
//  Created by fan on 2020/9/29.
//

#import <AVFoundation/AVFoundation.h>

@protocol JRSortFrameHandlerDelegate <NSObject>

@optional
- (void)getSortedVideoNode:(CMSampleBufferRef)videoDataRef;

@end

@interface JRSortFrameHandler : NSObject

@property (weak, nonatomic) id<JRSortFrameHandlerDelegate> delegate;

- (void)addDataToLinkList:(CMSampleBufferRef)videoDataRef;

@end

