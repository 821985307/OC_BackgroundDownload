//
//  DownloaderManager.m
//  Downloader
//
//  Created by wenzhizheng on 2020/6/30.
//  Copyright © 2020 thread0. All rights reserved.
//

#import "DownloaderManager.h"
#import <UIKit/UIKit.h>




@interface DownloaderManager ()   <NSURLSessionDownloadDelegate>



@property (nonatomic, strong)  NSURLSession  *session;


@end

@implementation DownloaderManager


// 单例
+ (instancetype)shareInstance;
{
    static DownloaderManager *manager;
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        manager = [[DownloaderManager alloc] init];
    });
    
    return manager;
}


- (instancetype)init
{
    self = [super init];
    if (self) {
        
        // 创建后台下载session
        NSURLSessionConfiguration *config = [NSURLSessionConfiguration backgroundSessionConfigurationWithIdentifier:@"DownloaderManagerSession"];
        self.session = [NSURLSession sessionWithConfiguration:config delegate:self delegateQueue:[NSOperationQueue mainQueue]];
        
        
        // APP前后台切换 个别手机 个别系统会出现不回调进度的情况  暂停再开始可恢复
        [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(applicationDidBecomeActive) name:UIApplicationDidBecomeActiveNotification object:nil];
    }
    return self;
}



#pragma mark - 已下载的文件
- (NSArray *)downloadedFiles;
{
    NSString *dirPath = [[NSSearchPathForDirectoriesInDomains(NSDocumentDirectory, NSUserDomainMask, YES) lastObject] stringByAppendingPathComponent:@"Downloads"];
    if ([[NSFileManager defaultManager] fileExistsAtPath:dirPath]) {
        return  [[NSFileManager defaultManager] contentsOfDirectoryAtPath:dirPath error:nil];
    }
    return nil;
}

#pragma mark - 获取当前session下载列表
- (void)getTasksWithCompletionHandler:(void (^)(NSArray<NSURLSessionDownloadTask *> *downloadTasks))completionHandler;
{
    [self.session getTasksWithCompletionHandler:^(NSArray<NSURLSessionDataTask *> * _Nonnull dataTasks, NSArray<NSURLSessionUploadTask *> * _Nonnull uploadTasks, NSArray<NSURLSessionDownloadTask *> * _Nonnull downloadTasks) {
        if (completionHandler) {
            completionHandler(downloadTasks);
        }
    }];
}


#pragma mark - 新建一个新的下载
- (void)addDownloadTask:(NSURL *)url complete:(void(^)(BOOL result))complete;
{
    // 做一个判断 不重复下载同一个URL
    [self getTasksWithCompletionHandler:^(NSArray<NSURLSessionDownloadTask *> * _Nonnull downloadTasks) {

        BOOL isExit = false;
        for (NSURLSessionDownloadTask *task in downloadTasks) {
            if ([task.currentRequest.URL.absoluteString isEqualToString:url.absoluteString]) {
                isExit = YES;
                complete(NO);
                break;
            }
         }

        if (!isExit) {
            NSURLSessionDownloadTask *task = [self.session downloadTaskWithURL:url];
            [task resume];
            complete(YES);
        }

    }];
}


#pragma mark - 回到前台
- (void)applicationDidBecomeActive;
{
    [self getTasksWithCompletionHandler:^(NSArray<NSURLSessionDownloadTask *> * _Nonnull downloadTasks) {
        
        for (NSURLSessionDownloadTask *task in downloadTasks) {
            if (task.state == NSURLSessionTaskStateRunning) {
                [task suspend];
                [task resume];
            }
        }
    }];
}



#pragma mark - 下载代理
// 下载完成回调
- (void)URLSession:(nonnull NSURLSession *)session downloadTask:(nonnull NSURLSessionDownloadTask *)downloadTask didFinishDownloadingToURL:(nonnull NSURL *)location
{
    // 如果文件夹不存在文件移动会失败
    NSString *dirPath = [[NSSearchPathForDirectoriesInDomains(NSDocumentDirectory, NSUserDomainMask, YES) lastObject] stringByAppendingPathComponent:@"Downloads"];
    if (![[NSFileManager defaultManager] fileExistsAtPath:dirPath]) {
        [[NSFileManager defaultManager] createDirectoryAtPath:dirPath withIntermediateDirectories:YES attributes:nil error:nil];
    }
    
    
    NSURL *url = [NSURL fileURLWithPath:[dirPath stringByAppendingPathComponent:downloadTask.response.suggestedFilename]];
    
    NSError *error;
    [[NSFileManager defaultManager] moveItemAtURL:location toURL:url error:&error];
    if (error) {
        NSLog(@"%@",error);
    }
    
    
    if ([self.delegate respondsToSelector:@selector(didFinishDownloadingTask:)]) {
        [self.delegate didFinishDownloadingTask:downloadTask];
    }
}


// 进度回调
- (void)URLSession:(NSURLSession *)session downloadTask:(NSURLSessionDownloadTask *)downloadTask
                                           didWriteData:(int64_t)bytesWritten
                                      totalBytesWritten:(int64_t)totalBytesWritten
                              totalBytesExpectedToWrite:(int64_t)totalBytesExpectedToWrite;
{
    double progress = 1.0 * totalBytesWritten/totalBytesExpectedToWrite;
    if ([self.delegate respondsToSelector:@selector(didUpdateProgress:task:)]) {
        [self.delegate  didUpdateProgress:progress task:downloadTask];
    }
}

// 下载结束回调
- (void)URLSession:(NSURLSession *)session task:(NSURLSessionTask *)task didCompleteWithError:(NSError *)error
{
    
    if (error) {
        
        // 失败原因
        NSInteger reason = [[error.userInfo objectForKey:NSURLErrorBackgroundTaskCancelledReasonKey] integerValue];
        
        // 如果是退出APP导致的下载失败 使用resumeData重新下载
        if (reason == NSURLErrorCancelledReasonUserForceQuitApplication) {
            NSData *resumeData = [error.userInfo objectForKey:NSURLSessionDownloadTaskResumeData];
            if (resumeData) {
                NSURLSessionDownloadTask *task = [self.session downloadTaskWithResumeData:resumeData];
                [task resume];
            }
        }
    }

    if (self.delegate) {
        [self.delegate didCompleteWithError:error task:task];
    }
    
}

// 后台下载完成回调
- (void)URLSessionDidFinishEventsForBackgroundURLSession:(NSURLSession *)session
{
    
}





@end
