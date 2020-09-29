//
//  JRSortFrameHandler.m
//  JRLive
//
//  Created by fan on 2020/9/29.
//

#import "JRSortFrameHandler.h"

const static int g_maxSize = 4;

struct JRSortLinkList {
    CMSampleBufferRef dataArray[g_maxSize];
    int index;
};

typedef struct JRSortLinkList JRSortLinkList;

@interface JRSortFrameHandler ()
{
    JRSortLinkList _sortLinkList;
}

@end

@implementation JRSortFrameHandler

#pragma mark - Lifecycle
- (instancetype)init
{
    if (self = [super init]) {
        JRSortLinkList linkList = {
            .index = 0,
            .dataArray = {0},
        };
        
        _sortLinkList = linkList;
    }
    return self;
}

#pragma mark - Public

- (void)addDataToLinkList:(CMSampleBufferRef)sampleBufferRef
{
    CFRetain(sampleBufferRef);
    _sortLinkList.dataArray[_sortLinkList.index] = sampleBufferRef;
    _sortLinkList.index++;
    
    if (_sortLinkList.index == g_maxSize) {
        _sortLinkList.index = 0;
        
        // sort
        [self selectSortWithLinkList:&_sortLinkList];
        
        for (int i = 0; i < g_maxSize; i++) {
            if ([self.delegate respondsToSelector:@selector(getSortedVideoNode:)]) {
                [self.delegate getSortedVideoNode:_sortLinkList.dataArray[i]];
                CFRelease(_sortLinkList.dataArray[i]);
            }
        }
    }
}

#pragma mark - Private
- (void)selectSortWithLinkList:(JRSortLinkList *)sortLinkList
{
    for (int i = 0; i < g_maxSize; i++) {
        int64_t minPTS = i;
        for (int j = i + 1; j < g_maxSize; j++) {
            if ([self getPTS:sortLinkList->dataArray[j]] < [self getPTS:sortLinkList->dataArray[minPTS]]) {
                minPTS = j;
            }
        }
        
        if (i != minPTS) {
            CMSampleBufferRef *tmp = (CMSampleBufferRef *)sortLinkList->dataArray[i];
            sortLinkList->dataArray[i] = sortLinkList->dataArray[minPTS];
            sortLinkList->dataArray[minPTS] = *tmp;
        }
    }
}

- (int64_t)getPTS:(CMSampleBufferRef)sampleBufferRef
{
    int64_t pts = (int64_t)(CMTimeGetSeconds(CMSampleBufferGetPresentationTimeStamp(sampleBufferRef)) * 1000);
    return pts;
}


@end
