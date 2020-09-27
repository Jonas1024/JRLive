//
//  JRAudioFrame.h
//  JRLive
//
//  Created by fan on 2020/9/27.
//

#import "JRFrame.h"

NS_ASSUME_NONNULL_BEGIN

@interface JRAudioFrame : JRFrame

/// flv打包中aac的header
@property (nonatomic, strong) NSData *audioInfo;

@end

NS_ASSUME_NONNULL_END
