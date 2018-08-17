//
//  DownloadDelegate.h
//  DownloadCore
//
//  Created by CPU11829 on 8/8/18.
//  Copyright © 2018 CPU11829. All rights reserved.
//

#ifndef DownloadDelegate_h
#define DownloadDelegate_h

@protocol DownloadDelegate

- (void)downloadFrom:(NSString*)URLString didWriteTotalBytes:(int64_t)totalBytesWritten totalBytesExpected:(int64_t)totalBytesExpected;

- (void)downloadFrom:(NSString*)URLString didReceiveError:(NSError*)error;

- (void)downloadFrom:(NSString*)URLString didFinishDownloadingToURL:(NSURL*)path;

@end

#endif /* DownloadDelegate_h */
