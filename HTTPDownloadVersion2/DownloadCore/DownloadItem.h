//
//  DownloadItem.h
//  DownloadCore
//
//  Created by CPU11829 on 8/8/18.
//  Copyright © 2018 CPU11829. All rights reserved.
//

#import <Foundation/Foundation.h>

typedef enum {
    Waiting,
    Running,
    Suspended,
    Completed
} DownloadState;

@interface DownloadItem : NSObject

@property (weak, nonatomic) NSString* URLString;

@property (weak, nonatomic) NSURLSessionDownloadTask* downloadTask;

@property (nonatomic) DownloadState state;

@property (nonatomic) NSMutableArray* progressBlocks;

@property (nonatomic) NSMutableArray* errorBlocks;

@property (nonatomic) NSMutableArray* completionBlocks;

@property (nonatomic) dispatch_queue_t concurrentQueue;

- (instancetype)initWithDownloadTask:(NSURLSessionDownloadTask*)downloadTask URLString:(NSString*)URLString;

- (void)addProgressBlock:(void(^)(int64_t, int64_t))progressBlock;

- (void)addErrorBlocks:(void(^)(NSError*))errorBlock;

- (void)addCompletionBlock:(void(^)(NSURL*))completionBlock;

- (void)handleProgress;

- (void)handleError;

- (void)handleCompletion;

- (BOOL)suspend;

- (void)resume;

- (BOOL)cancle;

/*
// @property (nonatomic) NSString* filePath;

// @property (weak, nonatomic) NSString* URLString;

- (void)resume;

- (void)suspend;

- (void)cancle;

// - (void)cancleByProducingResumeData:(void(^)(NSData* resumeData))completion;

// - (instancetype)initWithTask:(NSURLSessionDownloadTask*)task andURLString:(NSString*)URLString;

// - (instancetype)initWithTask:(NSURLSessionDownloadTask*)task andFilePath:(NSString*)filePath;
*/


@end
