//
//  AppDelegate.m
//  JRLive
//
//  Created by fanjianrong on 2017/8/21.
//  Copyright © 2017年 樊健荣. All rights reserved.
//

#import "JRAppDelegate.h"
#import "JRAppDelegate+Category.h"
#import "JRBaseTabBarController.h"

@interface JRAppDelegate ()

@end

@implementation JRAppDelegate


- (BOOL)application:(UIApplication *)application didFinishLaunchingWithOptions:(NSDictionary *)launchOptions {
    
    JRBaseTabBarController *baseTarBarVC = [JRBaseTabBarController baseTabBarController];
    
    self.window.rootViewController = baseTarBarVC;
    
    return YES;
}

- (UIWindow *)window
{
    if (!_window) {
        _window = [[UIWindow alloc] initWithFrame:[UIScreen mainScreen].bounds];
        [_window makeKeyAndVisible];
    }
    return _window;
}



@end
