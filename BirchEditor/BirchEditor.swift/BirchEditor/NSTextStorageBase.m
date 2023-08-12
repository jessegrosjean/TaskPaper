//
//  OutlineEditorTextStorage.m
//  BirchEditor
//
//  Created by Jesse Grosjean on 7/14/16.
//  Copyright © 2005–2018 Jesse Grosjean. All rights reserved.
//

#import "NSTextStorageBase.h"
#import "JGMethodSwizzler.h"

@implementation NSTextStorageBase

- (instancetype)init {
    self = [super init];
    if (self) {
        _backingStorage = [[NSTextStorage alloc] init];
    }
    return self;
}

- (NSString *)string {
    return [_backingStorage string];
}

- (NSUInteger)length {
    return [_backingStorage length];
}

- (NSDictionary *)attributesAtIndex:(NSUInteger)index effectiveRange:(NSRangePointer)aRange {
    NSRange effectiveRange;
    NSDictionary *attributes = [_backingStorage attributesAtIndex:index effectiveRange:&effectiveRange];
    NSString *storageItemID = attributes[@"StorageItemID"];
    
    if (storageItemID) {
        if (aRange) {
            aRange->location = effectiveRange.location;
            aRange->length = effectiveRange.length;
        }
        return attributes;
    } else {
        [self fillBackingStoreAttributesInRange:effectiveRange];
        return [_backingStorage attributesAtIndex:index effectiveRange:aRange];
    }
}

- (void)fillBackingStoreAttributesInRange:(NSRange)range {
}

@end
