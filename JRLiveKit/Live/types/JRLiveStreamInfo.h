//
//  JRLiveStreamInfo.h
//  JRLive
//
//  Created by fan on 2020/9/27.
//

#import <Foundation/Foundation.h>
#import "JRLiveAudioConfiguration.h"
#import "JRLiveVideoConfiguration.h"

/// 流状态
typedef NS_ENUM (NSUInteger, JRLiveState){
    /// 准备
    JRLiveReady = 0,
    /// 连接中
    JRLivePending = 1,
    /// 已连接
    JRLiveStart = 2,
    /// 已断开
    JRLiveStop = 3,
    /// 连接出错
    JRLiveError = 4,
    ///  正在刷新
    JRLiveRefresh = 5
};

typedef NS_ENUM (NSUInteger, JRLiveSocketErrorCode) {
    JRLiveSocketError_PreView = 201,              ///< 预览失败
    JRLiveSocketError_GetStreamInfo = 202,        ///< 获取流媒体信息失败
    JRLiveSocketError_ConnectSocket = 203,        ///< 连接socket失败
    JRLiveSocketError_Verification = 204,         ///< 验证服务器失败
    JRLiveSocketError_ReConnectTimeOut = 205      ///< 重新连接服务器超时
};

NS_ASSUME_NONNULL_BEGIN

@interface JRLiveStreamInfo : NSObject

@property (nonatomic, copy) NSString *streamId;

#pragma mark -- FLV
@property (nonatomic, copy) NSString *host;
@property (nonatomic, assign) NSInteger port;
#pragma mark -- RTMP
@property (nonatomic, copy) NSString *url;          ///< 上传地址 (RTMP用就好了)
///音频配置
@property (nonatomic, strong) JRLiveAudioConfiguration *audioConfiguration;
///视频配置
@property (nonatomic, strong) JRLiveVideoConfiguration *videoConfiguration;


@end

NS_ASSUME_NONNULL_END
