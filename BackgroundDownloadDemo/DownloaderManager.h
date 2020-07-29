//
//  DownloaderManager.h
//  Downloader
//
//  Created by wenzhizheng on 2020/6/30.
//  Copyright © 2020 thread0. All rights reserved.
//

#import <Foundation/Foundation.h>


NS_ASSUME_NONNULL_BEGIN




@protocol DownloaderManagerDelegate <NSObject>

// 下载完成
- (void)didFinishDownloadingTask:(NSURLSessionDownloadTask *)task;


// 下载进度有变化
- (void)didUpdateProgress:(double)progress task:(NSURLSessionDownloadTask *)task;



// 下载结束
- (void)didCompleteWithError:(NSError *)error task:(NSURLSessionTask *)task;


@end


@interface DownloaderManager : NSObject


// 单例
+ (instancetype)shareInstance;


// 代理
@property (nonatomic, weak)   id<DownloaderManagerDelegate> delegate;


// 获取当前下载列表
- (void)getTasksWithCompletionHandler:(void (^)(NSArray<NSURLSessionDownloadTask *> *downloadTasks))completionHandler;


// 新建一个新的下载
- (void)addDownloadTask:(NSURL *)url complete:(void(^)(BOOL result))complete;


// 已下载的文件
- (NSArray *)downloadedFiles;


@end

NS_ASSUME_NONNULL_END
