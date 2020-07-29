//
//  AppDelegate.m
//  Downloader
//
//  Created by wenzhizheng on 2020/6/30.
//  Copyright © 2020 thread0. All rights reserved.
//

#import "AppDelegate.h"
#import "DownloaderManager.h"

#import <UserNotifications/UserNotifications.h>

@interface AppDelegate ()

@end

@implementation AppDelegate


- (BOOL)application:(UIApplication *)application didFinishLaunchingWithOptions:(NSDictionary *)launchOptions {
    // Override point for customization after application launch.
    
   // 请求通知权限
    [self notiAuthor];

    return YES;
}


#pragma mark - 通知
- (void)notiAuthor
{
    UNAuthorizationOptions options = UNAuthorizationOptionSound | UNAuthorizationOptionAlert | UNAuthorizationOptionBadge;
    [UNUserNotificationCenter.currentNotificationCenter requestAuthorizationWithOptions:options completionHandler:^(BOOL granted, NSError * _Nullable error) {
        if (granted) {
            // 允许授权
        } else {
            // 不允许授权
        }
    }];
    
}


- (void)addNotification {
    // 创建一个通知内容
    UNMutableNotificationContent *content = [[UNMutableNotificationContent alloc] init];
    content.badge = @1;
    content.title = @"下载任务已全部完成";
    content.sound = [UNNotificationSound defaultSound];
    
    
    // 通知触发器
    UNTimeIntervalNotificationTrigger *trigger = [UNTimeIntervalNotificationTrigger triggerWithTimeInterval:1 repeats:false];
    // 通知请求
    UNNotificationRequest *request = [UNNotificationRequest requestWithIdentifier:@"noti" content:content trigger:trigger];
    //添加通知
    [UNUserNotificationCenter.currentNotificationCenter addNotificationRequest:request withCompletionHandler:^(NSError * _Nullable error) {
        
        NSLog(@"error:%@",error);
    }];
    
    
    // 添加通知的一些操作
//    UNNotificationAction *openAction = [UNNotificationAction actionWithIdentifier:@"open" title:@"打开" options:UNNotificationActionOptionForeground];
//    UNNotificationAction *closeAction = [UNNotificationAction actionWithIdentifier:@"close" title:@"关闭" options:UNNotificationActionOptionDestructive];
//    UNNotificationCategory *category = [UNNotificationCategory categoryWithIdentifier:@"category" actions:@[openAction, closeAction] intentIdentifiers:@[] options:UNNotificationCategoryOptionCustomDismissAction];
//
//    NSSet *sets = [NSSet setWithObject:category];
//    [UNUserNotificationCenter.currentNotificationCenter setNotificationCategories:sets];
}



#pragma mark - app进入前台/后台
- (void)applicationDidBecomeActive:(UIApplication *)application;
{
    [[UIApplication sharedApplication] setApplicationIconBadgeNumber:0];
}

- (void)applicationDidEnterBackground:(UIApplication *)application
{
    
}



#pragma mark - 后台下载完成时 回调 （当某个session里面的所有任务都完成时候才会执行回调）
- (void)application:(UIApplication *)application handleEventsForBackgroundURLSession:(NSString *)identifier completionHandler:(void (^)(void))completionHandler;
{
    
    [self addNotification];
    
    completionHandler();
}



@end
