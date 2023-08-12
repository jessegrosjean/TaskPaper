//
//  NSTextView-RangeForUserCompletionAdditions.m
//  BirchEditor
//
//  Created by Jesse Grosjean on 8/3/16.
//  Copyright © 2005–2018 Jesse Grosjean. All rights reserved.
//

#import "NSTextView-RangeForUserCompletionAdditions.h"
#import "JGMethodSwizzler.h"
#import <objc/runtime.h>


/*
@implementation NSView (DEbugit)

+ (void)load {
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        [[self class] swizzleInstanceMethod:@selector(layout) withReplacement:JGMethodReplacementProviderBlock {
            return JGMethodReplacement(void, NSView *) {
                NSLog(@"%@", self);
                NSLog(@"%@", self.constraints);
                JGOriginalImplementation(void);
            };
        }];
    });
}

@end
 */

@implementation NSTextView (RangeForUserCompletionAdditions)

+ (void)load {
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        [[self class] swizzleInstanceMethod:@selector(rangeForUserCompletion) withReplacement:JGMethodReplacementProviderBlock {
            return JGMethodReplacement(NSRange, NSTextView *) {
                NSCharacterSet *wordRangeLeadExtensionCharacters = self.wordRangeLeadExtensionCharacters;
                NSRange range = JGOriginalImplementation(NSRange);
                NSString *string = self.textStorage.string;

                if (wordRangeLeadExtensionCharacters != nil && range.location > 0) {
                    
                    if ([wordRangeLeadExtensionCharacters characterIsMember:[string characterAtIndex:range.location - 1]]) {
                        if (range.location > 1) {
                            if ([[NSCharacterSet whitespaceAndNewlineCharacterSet] characterIsMember: [string characterAtIndex:range.location - 2]]) {
                                range.location--;
                                range.length++;
                            }
                        } else {
                            range.location--;
                            range.length++;
                        }
                    }
                }
                
                NSUInteger end = NSMaxRange(range);
                
                if (end < string.length) {
                    if (![[NSCharacterSet whitespaceAndNewlineCharacterSet] characterIsMember: [string characterAtIndex:end]]) {
                        range.length = 0;
                    }
                }
                
                return range;
            };
        }];
    });
}

- (NSCharacterSet *)wordRangeLeadExtensionCharacters {
    return objc_getAssociatedObject(self, @selector(wordRangeLeadExtensionCharacters));
}

- (void)setWordRangeLeadExtensionCharacters:(NSCharacterSet *)wordRangeLeadExtensionCharacters {
    objc_setAssociatedObject(self, @selector(wordRangeLeadExtensionCharacters), wordRangeLeadExtensionCharacters, OBJC_ASSOCIATION_RETAIN);
}

@end
