//
//  NSMutableArray+Add.m
//  JRLive
//
//  Created by fan on 2020/9/27.
//

#import "NSMutableArray+Add.h"

@implementation NSMutableArray (Add)

- (void)jrRemoveFirstObject {
    if (self.count) {
        [self removeObjectAtIndex:0];
    }
}

- (id)jrPopFirstObject {
    id obj = nil;
    if (self.count) {
        obj = self.firstObject;
        [self jrRemoveFirstObject];
    }
    return obj;
}

@end
