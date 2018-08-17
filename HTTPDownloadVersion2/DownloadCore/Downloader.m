//
//  Downloader.m
//  DownloadCore
//
//  Created by CPU11829 on 8/8/18.
//  Copyright © 2018 CPU11829. All rights reserved.
//

#import "Downloader.h"
#import "DownloadItem.h"

NSString* const defaultBackgroundIdentifier = @"backgroundIdentifier";

@implementation Downloader

- (instancetype)initWithBackgroundSessionIdentifier:(NSString *)identifier {
    self = [super init];
    if (self) {
        if (identifier && [identifier isKindOfClass:[NSString class]]) {
            _backgroundSession = [NSURLSession sessionWithConfiguration:[NSURLSessionConfiguration backgroundSessionConfigurationWithIdentifier:identifier] delegate:self delegateQueue:nil];
        }
        else {
            _backgroundSession = [NSURLSession sessionWithConfiguration:[NSURLSessionConfiguration backgroundSessionConfigurationWithIdentifier:defaultBackgroundIdentifier] delegate:self delegateQueue:nil];
        }
        _runningDownloads = [NSMutableDictionary new];
        _suspendedDownloads = [NSMutableDictionary new];
        _waitingDownloads = [PriorityQueue new];
        _serialQueue = dispatch_queue_create([self.description cStringUsingEncoding:NSUTF8StringEncoding], DISPATCH_QUEUE_SERIAL);
        _maxConcurrentDownload = 3;
    }
    return self;
}

+ (id)sharedDownloader {
    static Downloader* sharedDownloader = nil;
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        sharedDownloader = [[self alloc] initWithBackgroundSessionIdentifier:defaultBackgroundIdentifier];
    });
    return sharedDownloader;
}

- (void)createDownloadWithURLString:(NSString *)URLString
                           priority:(Priority)priority
                      progressBlock:(void (^)(int64_t, int64_t))progressBlock
                         errorBlock:(void (^)(NSError *))errorBlock
                    completionBlock:(void (^)(NSURL *))completionBlock {
    if (URLString && [URLString isKindOfClass:[NSString class]]) {
        __weak typeof(self) weakSelf = self;
        dispatch_async(_serialQueue, ^{
            DownloadItem* downloadItem = (DownloadItem*)[weakSelf.waitingDownloads objectForKey:URLString];
            if (!downloadItem) {
                downloadItem = [weakSelf.runningDownloads objectForKey:URLString];
            }
            if (!downloadItem) {
                downloadItem = [weakSelf.suspendedDownloads objectForKey:URLString];
            }
            if (downloadItem) {
                [downloadItem addErrorBlocks:errorBlock];
                [downloadItem addProgressBlock:progressBlock];
                [downloadItem addCompletionBlock:completionBlock];
                return;
            }
            else {
                downloadItem = [weakSelf.finishedDownloads objectForKey:URLString];
                if (downloadItem) {
                    completionBlock(nil);
                }
                else {
                    NSURL* url = [NSURL URLWithString:URLString];
                    NSURLSessionDownloadTask* downloadTask = [weakSelf.backgroundSession downloadTaskWithURL:url];
                    DownloadItem* downloadItem = [[DownloadItem alloc] initWithDownloadTask:downloadTask URLString:URLString];
                    [downloadItem addErrorBlocks:errorBlock];
                    [downloadItem addProgressBlock:progressBlock];
                    [downloadItem addCompletionBlock:completionBlock];
                    if (weakSelf.runningDownloads.count < weakSelf.maxConcurrentDownload && [weakSelf.waitingDownloads isEmpty]) {
                        [weakSelf.runningDownloads setObject:downloadItem forKey:URLString];
                        [downloadItem resume];
                    }
                    else {
                        [weakSelf.waitingDownloads addObject:downloadItem withPriority:priority];
                    }
                }
            }
        });
    }
}

- (void)restoreDownloadWithURLString:(NSString *)URLString priority:(Priority)priority progressBlock:(void (^)(int64_t, int64_t))progressBlock errorBlock:(void (^)(NSError *))errorBlock completionBlock:(void (^)(NSURL *))completionBlock {
    if (URLString && [URLString isKindOfClass:[NSString class]]) {
        __weak typeof(self) weakSelf = self;
        dispatch_async(_serialQueue, ^{
            if ([weakSelf.finishedDownloads objectForKey:URLString]) {
                [weakSelf.finishedDownloads removeObjectForKey:URLString];
                [weakSelf createDownloadWithURLString:URLString priority:priority progressBlock:progressBlock errorBlock:errorBlock completionBlock:completionBlock];
            }
        });
    }
}

- (void)startOneDownloadFromQueue {
    __weak typeof(self) weakSelf = self;
    dispatch_async(_serialQueue, ^{
        DownloadItem* downloadItem = (DownloadItem*)[weakSelf.waitingDownloads getObjectFromQueue];
        if (downloadItem) {
            [weakSelf.runningDownloads setObject:downloadItem forKey:downloadItem.URLString];
            [(DownloadItem*)downloadItem resume];
        }
    });
}


/*
+ (id)sharedDownloader {
    static Downloader* sharedDownloader = nil;
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        sharedDownloader = [[self alloc] init];
    });
    return sharedDownloader;
}

- (instancetype)init {
    self = [super init];
    if (self) {
        _backgroundSession = [NSURLSession sessionWithConfiguration:[NSURLSessionConfiguration backgroundSessionConfigurationWithIdentifier:backgroundIdentifier] delegate:self delegateQueue:nil];
        _runningDownloads = [NSMutableDictionary new];
        _suspendedDownloads = [NSMutableDictionary new];
        _waitingDownloads = [PriorityQueue new];
        // _downloadDelegates = [NSMutableDictionary new];
        _sessionQueue = dispatch_queue_create([self.description cStringUsingEncoding:NSUTF8StringEncoding], DISPATCH_QUEUE_SERIAL);
        _maxConcurrentDownload = 3;
    }
    return self;
}

- (instancetype)initWithBackgroundSessionIdentifier:(NSString*)identifier {
    self = [super init];
    if (self) {
        _backgroundSession = [NSURLSession sessionWithConfiguration:[NSURLSessionConfiguration backgroundSessionConfigurationWithIdentifier:identifier] delegate:self delegateQueue:nil];
        _runningDownloads = [NSMutableDictionary new];
        _suspendedDownloads = [NSMutableDictionary new];
        _waitingDownloads = [PriorityQueue new];
        // _downloadDelegates = [NSMutableDictionary new];
        _sessionQueue = dispatch_queue_create([self.description cStringUsingEncoding:NSUTF8StringEncoding], DISPATCH_QUEUE_SERIAL);
        _maxConcurrentDownload = 3;
    }
    return self;
}

- (void)loadResumeDownload {
    __weak typeof(self) weakSelf = self;
    [_backgroundSession getTasksWithCompletionHandler:^(NSArray<NSURLSessionDataTask *> * _Nonnull dataTasks, NSArray<NSURLSessionUploadTask *> * _Nonnull uploadTasks, NSArray<NSURLSessionDownloadTask *> * _Nonnull downloadTasks) {
        for (NSURLSessionDownloadTask* downloadTask in downloadTasks) {
            [downloadTask suspend];
            NSDictionary* downloadProperties = [NSUserDefaults.standardUserDefaults objectForKey:downloadTask.originalRequest.URL.absoluteString];
            if (downloadProperties) {
                NSObject* filePath = [downloadProperties objectForKey:@"filepath"];
                if (filePath) {
                    if ([filePath isKindOfClass:[NSString class]]) {
                        DownloadItem* download = [[DownloadItem alloc] initWithTask:downloadTask andFilePath:(NSString*)filePath];
                        NSObject* state = [downloadProperties objectForKey:@"state"];
                        if (state) {
                            if ([state isKindOfClass:[NSNumber class]]) {
                                switch ([(NSNumber*)state intValue]) {
                                    case Running:
                                        if (download.downloadTask.state == NSURLSessionTaskStateSuspended) {
                                            [weakSelf.runningDownloads setObject:download forKey:downloadTask.originalRequest.URL.absoluteString];
                                            [download resume];
                                        }
                                        break;
                                    case Suspended:
                                        [weakSelf.suspendedDownloads setObject:download forKey:downloadTask.originalRequest.URL.absoluteString];
                                        break;
                                    case Waiting:
                                        [weakSelf.waitingDownloads addObject:download withPriority:High];
                                        break;
                                    default:
                                        break;
                                }
                            }
                        }
                    }
                }
            }
        }
    }];
}

- (BOOL)setDelegate:(NSObject<DownloadDelegate>*)delegate forDownloadFromURLString:(NSString*)URLString {
    NSObject* downloadItem = [_runningDownloads objectForKey:URLString];
    if (downloadItem) {
        if ([downloadItem isKindOfClass:[DownloadItem class]]) {
            // [_downloadDelegates setObject:delegate forKey:((DownloadItem*)downloadItem).downloadTask];
            return true;
        }
    }
    
    downloadItem = [_suspendedDownloads objectForKey:URLString];
    if (downloadItem) {
        if ([downloadItem isKindOfClass:[DownloadItem class]]) {
            // [_downloadDelegates setObject:delegate forKey:((DownloadItem*)downloadItem).downloadTask];
            return true;
        }
    }
    
    downloadItem = [_waitingDownloads objectForKey:URLString];
    if (downloadItem) {
        if ([downloadItem isKindOfClass:[DownloadItem class]]) {
            // [_downloadDelegates setObject:delegate forKey:((DownloadItem*)downloadItem).downloadTask];
            return true;
        }
    }
    
    return false;
}

- (BOOL)createDownloadItemWithURLString:(NSString *)URLString
                               filePath:(NSString*)filePath
                               priority:(Priority)priority
                               delegate:(NSObject<DownloadDelegate> *)delegate {
    if (URLString) {
        __block BOOL isDownloaded = false;
        __weak typeof(self) weakSelf = self;
        
        dispatch_sync(_sessionQueue, ^{
            NSObject* downloadItem = [weakSelf.runningDownloads objectForKey:URLString];
            if (downloadItem) {
                if ([downloadItem isKindOfClass:[DownloadItem class]]) {
                    isDownloaded = true;
                    return;
                }
            }
            
            downloadItem = [weakSelf.suspendedDownloads objectForKey:URLString];
            if (downloadItem) {
                if ([downloadItem isKindOfClass:[DownloadItem class]]) {
                    isDownloaded = true;
                    return;
                }
            }
            
            downloadItem = [weakSelf.waitingDownloads objectForKey:URLString];
            if (downloadItem) {
                if ([downloadItem isKindOfClass:[DownloadItem class]]) {
                    isDownloaded = true;
                    return;
                }
            }
        });
        
        if (!isDownloaded) {
            NSURL* url = [NSURL URLWithString:URLString];
            NSURLSessionDownloadTask* downloadTask;
            NSObject* resumeData = [NSUserDefaults.standardUserDefaults objectForKey:URLString];
            if (resumeData) {
                if ([resumeData isKindOfClass:[NSData class]]) {
                    [NSUserDefaults.standardUserDefaults removeObjectForKey:URLString];
                    downloadTask = [_backgroundSession downloadTaskWithResumeData:(NSData*)resumeData];
                }
            }
            if (!downloadTask) {
                downloadTask = [_backgroundSession downloadTaskWithURL:url];
            }
            DownloadItem* downloadItem = [[DownloadItem alloc] initWithTask:downloadTask andFilePath:filePath];
            dispatch_async(_sessionQueue, ^{
                // [weakSelf.downloadDelegates setObject:delegate forKey:downloadTask];
                if (downloadItem) {
                    if (weakSelf.runningDownloads.count < weakSelf.maxConcurrentDownload && [weakSelf.waitingDownloads isEmpty]) {
                        [weakSelf.runningDownloads setObject:downloadItem forKey:URLString];
                        [downloadItem resume];
                    }
                    else {
                        [weakSelf.waitingDownloads addObject:downloadItem withPriority:priority];
                    }
                }
            });
            return true;
        }
    }
    return false;
}

- (void)startOneDownload {
    __weak typeof(self) weakSelf = self;
    dispatch_async(_sessionQueue, ^{
        NSObject* downloadItem = [weakSelf.waitingDownloads getObjectFromQueue];
        if (downloadItem) {
            if ([downloadItem isKindOfClass:[DownloadItem class]]) {
                [weakSelf.runningDownloads setObject:downloadItem forKey:((DownloadItem*)downloadItem).downloadTask.originalRequest.URL.absoluteString];
                [(DownloadItem*)downloadItem resume];
            }
        }
    });
}

- (void)pauseDownloadWithURLString:(NSString *)URLString {
    if (URLString) {
        __weak typeof(self) weakSelf = self;
        dispatch_async(_sessionQueue, ^{
            NSObject* downloadItem = [weakSelf.runningDownloads objectForKey:URLString];
            if (downloadItem) {
                if ([downloadItem isKindOfClass:[DownloadItem class]]) {
                    [(DownloadItem*)downloadItem suspend];
                    [weakSelf.runningDownloads removeObjectForKey:URLString];
                    [weakSelf.suspendedDownloads setObject:downloadItem forKey:URLString];
                    [weakSelf startOneDownload];
                }
            }
        });
    }
}

- (void)resumeDownloadWithURLString:(NSString *)URLString {
    if (URLString) {
        __weak typeof(self) weakSelf = self;
        dispatch_async(_sessionQueue, ^{
            NSObject* downloadItem = [weakSelf.suspendedDownloads objectForKey:URLString];
            if (downloadItem) {
                [weakSelf.suspendedDownloads removeObjectForKey:URLString];
                if ([downloadItem isKindOfClass:[DownloadItem class]]) {
                    if (weakSelf.runningDownloads.count < weakSelf.maxConcurrentDownload && [weakSelf.waitingDownloads isEmpty]) {
                        [weakSelf.runningDownloads setObject:downloadItem forKey:URLString];
                        [(DownloadItem*)downloadItem resume];
                    }
                    else {
                        [weakSelf.waitingDownloads addObject:downloadItem withPriority:High];
                    }
                }
            }
        });
    }
}

- (void)cancelDownloadWithURLString:(NSString *)URLString {
    if (URLString) {
        __weak typeof(self) weakSelf = self;
        dispatch_async(_sessionQueue, ^{
            NSObject* downloadItem = [weakSelf.runningDownloads objectForKey:URLString];
            if (downloadItem) {
                if ([downloadItem isKindOfClass:[DownloadItem class]]) {
                    [(DownloadItem*)downloadItem cancle];
                    [weakSelf.runningDownloads removeObjectForKey:URLString];
                    return;
                }
            }
            
            downloadItem = [weakSelf.suspendedDownloads objectForKey:URLString];
            if (downloadItem) {
                if ([downloadItem isKindOfClass:[DownloadItem class]]) {
                    [(DownloadItem*)downloadItem cancle];
                    [weakSelf.suspendedDownloads removeObjectForKey:URLString];
                    return;
                }
            }
            
            downloadItem = [weakSelf.waitingDownloads objectForKey:URLString];
            if (downloadItem) {
                if ([downloadItem isKindOfClass:[DownloadItem class]]) {
                    [(DownloadItem*)downloadItem cancle];
                    [weakSelf.waitingDownloads removeObjectForKey:URLString];
                    return;
                }
            }
        });
    }
}

- (void)URLSession:(nonnull NSURLSession *)session downloadTask:(nonnull NSURLSessionDownloadTask *)downloadTask didFinishDownloadingToURL:(nonnull NSURL *)location {
    NSObject* downloadDelegate;// = [_downloadDelegates objectForKey:downloadTask];
    if (downloadDelegate) {
        if ([downloadDelegate respondsToSelector:@selector(downloadFrom:didFinishDownloadingToURL:)]) {
            [(NSObject<DownloadDelegate>*)downloadDelegate downloadFrom:downloadTask.originalRequest.URL.absoluteString didFinishDownloadingToURL:location];
        }
    }
}

- (void)URLSession:(NSURLSession *)session downloadTask:(NSURLSessionDownloadTask *)downloadTask didWriteData:(int64_t)bytesWritten totalBytesWritten:(int64_t)totalBytesWritten totalBytesExpectedToWrite:(int64_t)totalBytesExpectedToWrite {
    NSObject* downloadDelegate;// = [_downloadDelegates objectForKey:downloadTask];
    if (downloadDelegate) {
        if ([downloadDelegate respondsToSelector:@selector(downloadFrom:didWriteTotalBytes:totalBytesExpected:)]) {
            [(NSObject<DownloadDelegate>*)downloadDelegate downloadFrom:downloadTask.originalRequest.URL.absoluteString didWriteTotalBytes:totalBytesWritten totalBytesExpected:totalBytesExpectedToWrite];
        }
    }
}

- (void)URLSession:(NSURLSession *)session task:(NSURLSessionTask *)task didCompleteWithError:(NSError *)error {
    NSObject* downloadDelegate;// = [_downloadDelegates objectForKey:task];
    if (downloadDelegate) {
        if ([downloadDelegate respondsToSelector:@selector(downloadFrom:didReceiveError:)]) {
            if (error) {
                [(NSObject<DownloadDelegate>*)downloadDelegate downloadFrom:task.originalRequest.URL.absoluteString didReceiveError:error];
            }
            else {
                NSObject* response = task.response;
                NSInteger statusCode = [(NSHTTPURLResponse*)response statusCode];
                if (statusCode < 200 || statusCode > 299) {
                    [(NSObject<DownloadDelegate>*)downloadDelegate downloadFrom:task.originalRequest.URL.absoluteString didReceiveError:[NSError errorWithDomain:@"URLError"
                                                                                                                   code:URLNotSupportDownload
                                                                                                               userInfo:@{@"url": task.currentRequest.URL,
                                                                                                                          @"statuscode": [NSNumber numberWithInteger: [(NSHTTPURLResponse*)(task.response) statusCode]]
                                                                                                                          }]];
                }
            }
        }
        // [_downloadDelegates removeObjectForKey:task];
    }
    __weak typeof(self) weakSelf = self;
    dispatch_async(_sessionQueue, ^{
        for (DownloadItem* download in self.runningDownloads.allValues) {
            if ([download.downloadTask isEqual:task]) {
                [weakSelf.runningDownloads removeObjectForKey:download.downloadTask.originalRequest.URL.absoluteString];
            }
        }
        [weakSelf startOneDownload];
    });
}

- (void)handleWhenAppTerminated {
    for (DownloadItem* download in _runningDownloads.allValues) {
        if (download.filePath && download.downloadTask.originalRequest.URL.absoluteString) {
            [NSUserDefaults.standardUserDefaults setObject:[NSDictionary dictionaryWithObjects:@[[NSNumber numberWithInt:download.state], download.filePath] forKeys:@[@"state", @"filepath"]]
                                                    forKey:download.downloadTask.originalRequest.URL.absoluteString];
        }
    }
    for (DownloadItem* download in _suspendedDownloads.allValues) {
        if (download.filePath && download.downloadTask.originalRequest.URL.absoluteString) {
            [NSUserDefaults.standardUserDefaults setObject:[NSDictionary dictionaryWithObjects:@[[NSNumber numberWithInt:download.state], download.filePath] forKeys:@[@"state", @"filepath"]]
                                                    forKey:download.downloadTask.originalRequest.URL.absoluteString];
        }
    }
    for (DownloadItem* download in _waitingDownloads.getAllObjectFromQueue) {
        if (download.filePath && download.downloadTask.originalRequest.URL.absoluteString) {
            [NSUserDefaults.standardUserDefaults setObject:[NSDictionary dictionaryWithObjects:@[[NSNumber numberWithInt:download.state], download.filePath] forKeys:@[@"state", @"filepath"]]
                                                    forKey:download.downloadTask.originalRequest.URL.absoluteString];
        }
    }
}

 */
 
@end
