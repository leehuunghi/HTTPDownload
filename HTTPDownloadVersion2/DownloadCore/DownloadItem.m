//
//  DownloadItem.m
//  DownloadCore
//
//  Created by CPU11829 on 8/8/18.
//  Copyright © 2018 CPU11829. All rights reserved.
//

#import "DownloadItem.h"

@implementation DownloadItem

/*
- (void)resume {
    if (_state == Suspended) {
        _state = Running;
        [_downloadTask resume];
    }
}

- (void)suspend {
    if (_state == Running) {
        _state = Suspended;
        [_downloadTask suspend];
    }
}

- (void)cancle {
    [_downloadTask cancel];
}

/*
- (instancetype)initWithTask:(NSURLSessionDownloadTask*)task andFilePath:(NSString*)filePath {
    self = [super init];
    if (self) {
        _downloadTask = [task copy];
        // _filePath = [filePath copy];
        _state = Suspended;
    }
    return self;
}
 */


@end
