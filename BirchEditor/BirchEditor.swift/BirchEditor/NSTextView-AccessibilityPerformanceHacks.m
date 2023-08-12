//
//  NSTextView-AccessibilityPerformanceHacks.m
//  Birch
//
//  Created by Jesse Grosjean on 11/14/18.
//

#import "NSTextView-AccessibilityPerformanceHacks.h"

// Accessibility API calls these methods and then iterates over all attributes in NSTextView
// to find all links and attachments. This means all items need to be loaded into text view
// when they are suposed to be loaded lazily... to expensive. Lots of beachballs.

@implementation NSTextView (AccessibilityPerformanceHacks)

- (id)accessibilityTextLinks {
    return nil;
}

- (id)accessibilityAttachments {
    return nil;
}

@end
