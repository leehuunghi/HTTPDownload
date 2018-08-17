//
//  PriorityQueue.h
//  DownloadCore
//
//  Created by CPU11829 on 8/8/18.
//  Copyright © 2018 CPU11829. All rights reserved.
//

#import <Foundation/Foundation.h>

typedef enum {
    High,
    Medium,
    Low
} Priority;

@interface PriorityQueue : NSObject

@property (nonatomic) NSMutableArray *arrayHigh;

@property (nonatomic) NSMutableArray *arrayMedium;

@property (nonatomic) NSMutableArray *arrayLow;

- (void)addObject:(NSObject*)object withPriority:(Priority)priority;

- (NSObject*)getObjectFromQueue;

- (NSObject*)objectForKey:(NSString*)key;

- (void)removeObjectForKey:(NSString*)key;

- (NSArray*)getAllObjectFromQueue;

- (BOOL)isEmpty;

@end
