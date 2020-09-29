//
//  JRLivePlayer.h
//  JRLive
//
//  Created by fan on 2020/9/28.
//

#import <UIKit/UIKit.h>

@interface JRLivePlayer : NSObject

@property (nonatomic, strong, readonly) UIView *preview;

- (instancetype)initWithFrame:(CGRect)frame;

- (void)configWithURLString:(NSString *)urlString;

- (void)startPlayer;

- (void)stopPlayer;

@end
