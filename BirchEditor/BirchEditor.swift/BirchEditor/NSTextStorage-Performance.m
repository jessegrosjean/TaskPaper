//
//  OutlineEditorTextStorage-Performance.m
//  BirchEditor
//
//  Created by Jesse Grosjean on 7/14/16.
//  Copyright © 2005–2018 Jesse Grosjean. All rights reserved.
//

#import "NSTextStorage-Performance.h"

@implementation NSTextStorage (Performance)

- (unichar)characterAtIndex:(NSUInteger)index {
    return [self.string characterAtIndex:index];
}

- (NSString *)substringWithRange:(NSRange)range {
    return [self.string substringWithRange:range];
}

- (NSRange)paragraphRangeForRange:(NSRange)range {
    return [self.string paragraphRangeForRange:range];
}

- (void)enumerateParagraphRangesInRange:(NSRange)range usingBlock:(nonnull void (^)(NSRange enclosingRange,  BOOL * __nullable stop))block {
    [self enumerateSubstringsInRange:[self paragraphRangeForRange: range] options:NSStringEnumerationByParagraphs | NSStringEnumerationSubstringNotRequired usingBlock:^(NSString * _Nullable substring, NSRange substringRange, NSRange enclosingRange, BOOL * _Nullable stop) {
        block(enclosingRange, stop);
    }];
}

- (void)enumerateParagraphsInRange:(NSRange)range usingBlock:(nonnull void (^)(NSString * __nullable substring, NSRange substringRange, NSRange enclosingRange,  BOOL * __nullable stop))block {
    [self enumerateSubstringsInRange:[self paragraphRangeForRange: range] options:NSStringEnumerationByParagraphs | NSStringEnumerationSubstringNotRequired usingBlock:block];
}

- (void)enumerateSubstringsInRange:(NSRange)range options:(NSStringEnumerationOptions)opts usingBlock:(nonnull void (^)(NSString * __nullable substring, NSRange substringRange, NSRange enclosingRange, BOOL * __nullable stop))block {
    [self.string enumerateSubstringsInRange:range options:opts usingBlock:block];
}

@end
