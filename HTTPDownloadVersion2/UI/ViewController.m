//
//  ViewController.m
//  HTTPDownload
//
//  Created by CPU11367 on 7/30/18.
//  Copyright © 2018 CPU11367. All rights reserved.
//

#import "ViewController.h"
#import "DownloadCellObject.h"

@interface ViewController ()

@property (nonatomic) NSArray* staticArr;
@property (nonatomic) int count;

@end

@implementation ViewController

- (void)viewDidLoad {
    [super viewDidLoad];
    self.navigationItem.title = @"Download";
    
    [self loadData];
}

- (void)didReceiveMemoryWarning {
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

- (void)loadData {
    NSMutableArray *historyDownload = [NSMutableArray new];
    _downloadTableView.cellObjects = historyDownload;
    self.staticArr = @[
                       @"https://audio-ssl.itunes.apple.com/apple-assets-us-std-000001/AudioPreview128/v4/35/e6/81/35e68178-723f-9f06-6c92-04f81e2acfb9/mzaf_4847328976572813745.plus.aac.p.m4a",
                       @"https://audio-ssl.itunes.apple.com/apple-assets-us-std-000001/AudioPreview128/v4/48/14/99/481499f2-523f-929c-60ae-e98323751e6f/mzaf_5727211119371474437.plus.aac.p.m4a",
                       @"https://audio-ssl.itunes.apple.com/apple-assets-us-std-000001/Music3/v4/11/cf/71/11cf71d7-5a2b-660c-eef2-a8dacd9694cb/mzaf_9148830979689986253.plus.aac.p.m4a",
                       @"https://audio-ssl.itunes.apple.com/apple-assets-us-std-000001/Music/c0/77/58/mzm.mwxzkcck.aac.p.m4a"
                       ];
    for (NSString* downloadURLString in self.staticArr) {
        DownloadCellObject* cellObject = [DownloadCellObject new];
        cellObject.title = [ViewController getNameInURL:downloadURLString];
        cellObject.url = downloadURLString;
        cellObject.state = DownloadStatePause;
        if (![Downloader.sharedDownloader setDelegate:cellObject forDownloadFromURLString:downloadURLString]) {
            [Downloader.sharedDownloader createDownloadItemWithURLString:downloadURLString filePath:nil priority:High delegate:cellObject];
        }
        [_downloadTableView addCell:cellObject];
    }
    _count = 0;
}

+ (NSString *)getNameInURL:(NSString *)url {
    int startPoint = 0;
    for (int i = 1; i < [url length]; ++i) {
        if ([url characterAtIndex:i] == '/') {
            startPoint = i + 1;
        }
    }
    return [url substringFromIndex:startPoint];
}

- (IBAction)exitButtonClicked:(id)sender {
    [Downloader.sharedDownloader handleWhenAppTerminated];
    exit(0);
}

@end
