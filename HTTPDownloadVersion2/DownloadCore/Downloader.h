//
//  Downloader.h
//  DownloadCore
//
//  Created by CPU11829 on 8/8/18.
//  Copyright © 2018 CPU11829. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "DownloadDelegate.h"
#import "PriorityQueue.h"

typedef enum {
    URLNil,
    URLNotSupportDownload
} NSURLErrorCode;

@interface Downloader : NSObject<NSURLSessionDownloadDelegate>

@property (nonatomic) NSURLSession* backgroundSession;

@property (nonatomic) int maxConcurrentDownload;

@property (nonatomic) dispatch_queue_t serialQueue;

@property (nonatomic) PriorityQueue* waitingDownloads;

@property (nonatomic) NSMutableDictionary* runningDownloads;

@property (nonatomic) NSMutableDictionary* suspendedDownloads;

@property (nonatomic) NSMutableDictionary* finishedDownloads;

- (instancetype)initWithBackgroundSessionIdentifier:(NSString*)identifier;

+ (id)sharedDownloader;

- (void)createDownloadWithURLString:(NSString*)URLString
                           priority:(Priority)priority
                      progressBlock:(void(^)(int64_t, int64_t))progressBlock
                         errorBlock:(void(^)(NSError*))errorBlock
                    completionBlock:(void(^)(NSURL*))completionBlock;

- (void)restoreDownloadWithURLString:(NSString*)URLString
                           priority:(Priority)priority
                      progressBlock:(void(^)(int64_t, int64_t))progressBlock
                         errorBlock:(void(^)(NSError*))errorBlock
                    completionBlock:(void(^)(NSURL*))completionBlock;

- (void)startOneDownloadFromQueue;

- (BOOL)suspendDownloadWithURLString:(NSString*)URLString;

- (void)resumeDownloadWithURLString:(NSString*)URLString;

- (BOOL)cancelDownloadWithURLString:(NSString*)URLString;

- (void)cancleAllDownloads;









/*

// @property (nonatomic) NSMutableDictionary* downloadDelegates;

- (instancetype)initWithBackgroundSessionIdentifier:(NSString*)identifier;

- (BOOL)createDownloadItemWithURLString:(NSString*)URLString
                               filePath:(NSString*)filePath
                               priority:(Priority)priority
                               delegate:(NSObject<DownloadDelegate>*)delegate;

- (void)loadResumeDownload;

- (BOOL)setDelegate:(NSObject<DownloadDelegate>*)delegate forDownloadFromURLString:(NSString*)URLString;

- (void)startOneDownload;

- (void)pauseDownloadWithURLString:(NSString*)URLString;

- (void)resumeDownloadWithURLString:(NSString*)URLString;

- (void)cancelDownloadWithURLString:(NSString*)URLString;

- (void)handleWhenAppTerminated;

+ (id)sharedDownloader;

 */
 
@end
