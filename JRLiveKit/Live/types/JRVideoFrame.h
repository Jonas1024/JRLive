//
//  JRVideoFrame.h
//  JRLive
//
//  Created by fan on 2020/9/27.
//

#import "JRFrame.h"

NS_ASSUME_NONNULL_BEGIN

@interface JRVideoFrame : JRFrame

@property (nonatomic, assign) BOOL isKeyFrame;
@property (nonatomic, strong) NSData *sps;
@property (nonatomic, strong) NSData *pps;

@end

NS_ASSUME_NONNULL_END
