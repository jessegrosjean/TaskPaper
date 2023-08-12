#import <Cocoa/Cocoa.h>

// Implement common NSString calls to avoid needing to call textStorage.string in Swift ... since that does a string conversion.

@interface NSTextStorage (Performance)

- (unichar)characterAtIndex:(NSUInteger)index;
- (NSString * _Nonnull)substringWithRange:(NSRange)range;
- (NSRange)paragraphRangeForRange:(NSRange)range;
- (void)enumerateParagraphRangesInRange:(NSRange)range usingBlock:(nonnull void (^)(NSRange enclosingRange,  BOOL * __nullable stop))block;
- (void)enumerateSubstringsInRange:(NSRange)range options:(NSStringEnumerationOptions)opts usingBlock:(nonnull void (^)(NSString * __nullable substring, NSRange substringRange, NSRange enclosingRange, BOOL * __nullable stop))block;

@end
