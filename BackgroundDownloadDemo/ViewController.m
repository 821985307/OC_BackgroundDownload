//
//  ViewController.m
//  Downloader
//
//  Created by wenzhizheng on 2020/6/30.
//  Copyright © 2020 thread0. All rights reserved.
//

#import "ViewController.h"
#import "DownloaderManager.h"
#import "FileListVC.h"

@interface ViewController ()  <UITableViewDelegate,UITableViewDataSource,DownloaderManagerDelegate>

{
    UITableView *_tableView;
}


@property (nonatomic, strong)   NSArray<NSURLSessionDownloadTask *> *tasks;


@end

@implementation ViewController

- (void)viewDidLoad {
    [super viewDidLoad];
    // Do any additional setup after loading the view.
    
    self.view.backgroundColor = UIColor.whiteColor;
    
    [DownloaderManager shareInstance].delegate = self;
    
     
    UIBarButtonItem *item1 = [[UIBarButtonItem alloc] initWithTitle:@"添加任务" style:UIBarButtonItemStylePlain target:self action:@selector(addTask)];
    UIBarButtonItem *item2 = [[UIBarButtonItem alloc] initWithTitle:@"闪退" style:UIBarButtonItemStylePlain target:self action:@selector(crash)];
    UIBarButtonItem *item3 = [[UIBarButtonItem alloc] initWithTitle:@"已下载列表" style:UIBarButtonItemStylePlain target:self action:@selector(showLocalFile)];

    self.navigationItem.rightBarButtonItems = @[item1,item3];
    self.navigationItem.leftBarButtonItem = item2;
    
    
    _tableView = [[UITableView alloc] initWithFrame:self.view.bounds];
    _tableView.dataSource = self;
    _tableView.delegate = self;
    [_tableView reloadData];
    [self.view addSubview:_tableView];

    [self reloadData];
}


#pragma mark - 已下载列表
- (void)showLocalFile
{
    [self.navigationController pushViewController:[FileListVC new] animated:YES];
}


#pragma mark - 制造一个闪退模拟APP被系统退出的情况，APP被系统关闭下载会在后台进行，用户主动杀掉APP下载会被cancel。
- (void)crash
{
    NSLog(@"%@",[@[] objectAtIndex:100]);
}


#pragma mark - 开始一个下载任务
- (void)addTask
{
    
       NSString *str = @"https://stream7.iqilu.com/10339/upload_transcode/202002/18/20200218114723HDu3hhxqIT.mp4";
//        NSString *str = @"http://down10.zol.com.cn/it/AdobePhotoshsopCS6.zip";
//    NSString *str = @"https://youku.com-l-youku.com/20190111/14615_83ee9b68/index.m3u8";

    
    [[DownloaderManager shareInstance] addDownloadTask:[NSURL URLWithString:str]  complete:^(BOOL result) {
        [self reloadData];
    }];
    
}


#pragma mark - 刷新
- (void)reloadData
{
    [[DownloaderManager shareInstance] getTasksWithCompletionHandler:^(NSArray<NSURLSessionDownloadTask *> * _Nonnull downloadTasks) {
        
        NSMutableArray *tasks = [NSMutableArray array];
        for (NSURLSessionDownloadTask *task in downloadTasks) {
            if (task.state == NSURLSessionTaskStateSuspended ||
                task.state == NSURLSessionTaskStateRunning) {
                [tasks addObject:task];
            }
        }
        self.tasks = tasks;
        [self->_tableView reloadData];
    }];
}





#pragma mark - tableview
- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section
{
    return self.tasks.count;
}

- (CGFloat)tableView:(UITableView *)tableView heightForRowAtIndexPath:(NSIndexPath *)indexPath
{
    return 100;
}

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath
{
    UITableViewCell *cell = [tableView dequeueReusableCellWithIdentifier:@"cell"];
    if (!cell) {
        cell = [[UITableViewCell alloc] initWithStyle:UITableViewCellStyleValue1 reuseIdentifier:@"cell"];
    }
    
    NSURLSessionDownloadTask *task = [self.tasks objectAtIndex:indexPath.row];
    
    cell.textLabel.text = task.response.suggestedFilename;
    
    if (task.state == NSURLSessionTaskStateSuspended) {
        cell.detailTextLabel.text = @"已暂停";
    } else {
        cell.detailTextLabel.text = [NSString stringWithFormat:@"%.2f",task.progress.fractionCompleted];
    }
    
    return cell;
}

- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath
{
    [tableView deselectRowAtIndexPath:indexPath animated:YES];
    
    NSURLSessionDownloadTask *task = [self.tasks objectAtIndex:indexPath.row];
    
    if (task.state == NSURLSessionTaskStateRunning) {
        [task suspend];
    } else if (task.state == NSURLSessionTaskStateSuspended) {
        [task resume];
    }
    
    [self reloadData];
}

- (void)tableView:(UITableView *)tableView commitEditingStyle:(UITableViewCellEditingStyle)editingStyle forRowAtIndexPath:(NSIndexPath *)indexPath
{
    
    NSURLSessionDownloadTask *task = [self.tasks objectAtIndex:indexPath.row];
    
    [task cancel];
    
}


#pragma mark - 代理
- (void)didUpdateProgress:(double)progress task:(NSURLSessionDownloadTask *)task
{
    [_tableView reloadData];
}


- (void)didCompleteWithError:(NSError *)error task:(NSURLSessionTask *)task
{
    [self reloadData];
}


- (void)didFinishDownloadingTask:(NSURLSessionDownloadTask *)task
{
    NSLog(@"%@ 下载完成",task.response.suggestedFilename);
}

@end
