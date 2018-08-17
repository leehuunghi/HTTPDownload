//
//  PriorityQueue.m
//  DownloadCore
//
//  Created by CPU11829 on 8/8/18.
//  Copyright © 2018 CPU11829. All rights reserved.
//

#import "PriorityQueue.h"
#import "DownloadItem.h"

@implementation PriorityQueue

- (instancetype)init {
    self = [super init];
    if (self) {
        _arrayLow = [NSMutableArray new];
        _arrayMedium = [NSMutableArray new];
        _arrayHigh = [NSMutableArray new];
    }
    return self;
}

- (void)addObject:(NSObject*)object withPriority:(Priority)priority {
    
    switch (priority) {
        case High:
            [_arrayHigh addObject:object];
            break;
            
        case Medium:
            [_arrayMedium addObject:object];
            break;
            
        case Low:
            [_arrayLow addObject:object];
            break;
            
        default:
            break;
    }
}

- (NSObject*)getObjectFromQueue {
    NSObject* object;
    if (_arrayHigh.count > 0) {
        object = [_arrayHigh firstObject];
        [_arrayHigh removeObjectAtIndex:0];
    }
    else if (_arrayMedium.count > 0) {
        object = [_arrayMedium firstObject];
        [_arrayMedium removeObjectAtIndex:0];
    }
    else if (_arrayLow.count > 0) {
        object = [_arrayLow firstObject];
        [_arrayLow removeObjectAtIndex:0];
    }
    return object;
}

- (NSObject*)objectForKey:(NSString*)key {
    for (DownloadItem* downloadItem in _arrayHigh) {
        if ([downloadItem.downloadTask.progress.fileURL.absoluteString isEqualToString:key]) {
            return downloadItem;
        }
    }
    for (DownloadItem* downloadItem in _arrayMedium) {
        if ([downloadItem.downloadTask.progress.fileURL.absoluteString isEqualToString:key]) {
            return downloadItem;
        }
    }
    for (DownloadItem* downloadItem in _arrayLow) {
        if ([downloadItem.downloadTask.progress.fileURL.absoluteString isEqualToString:key]) {
            return downloadItem;
        }
    }
    return nil;
}

- (void)removeObjectForKey:(NSString*)key {
    for (DownloadItem* downloadItem in _arrayHigh) {
        if ([downloadItem.downloadTask.progress.fileURL.absoluteString isEqualToString:key]) {
            [_arrayHigh removeObject:downloadItem];
            return;
        }
    }
    for (DownloadItem* downloadItem in _arrayMedium) {
        if ([downloadItem.downloadTask.progress.fileURL.absoluteString isEqualToString:key]) {
            [_arrayMedium removeObject:downloadItem];
            return;
        }
    }
    for (DownloadItem* downloadItem in _arrayLow) {
        if ([downloadItem.downloadTask.progress.fileURL.absoluteString isEqualToString:key]) {
            [_arrayLow removeObject:downloadItem];
            return;
        }
    }
}

- (NSArray *)getAllObjectFromQueue {
    return [[_arrayHigh arrayByAddingObjectsFromArray:_arrayMedium] arrayByAddingObjectsFromArray:_arrayLow];
}

- (BOOL)isEmpty {
    return _arrayHigh.count + _arrayMedium.count + _arrayLow.count == 0;
}

@end
