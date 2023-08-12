//
//  NSWindow.m
//  BirchEditor
//
//  Created by Jesse Grosjean on 8/3/16.
//  Copyright © 2005–2018 Jesse Grosjean. All rights reserved.
//

#import "NSWindow-TitleLayout.h"
#import "JGMethodSwizzler.h"
#import <objc/runtime.h>



@implementation NSWindow (TitleLayout)

- (void)updateTitleLayout:(id <TitleLayoutLocator>)locator {
    NSString *selectorString = [[NSString alloc] initWithFormat:@"%@%@", @"_tileTitleb", @"arAndRedisplay:"];
    SEL titleTitlebarAndRedisplaySelector = NSSelectorFromString(selectorString);
    SEL didPatchTitleTitlebarAndRedisplaySelector = @selector(didPatchTitleTitlebarAndRedisplaySelector);
    SEL titleLayoutLocatorSelector = @selector(_titleLayoutLocator);
    
    NSView *titleLayoutView = self.contentView;
    while (titleLayoutView && ![titleLayoutView respondsToSelector:titleTitlebarAndRedisplaySelector]) {
        titleLayoutView = titleLayoutView.superview;
    }
    
    objc_setAssociatedObject(self, titleLayoutLocatorSelector, locator, OBJC_ASSOCIATION_ASSIGN);
    
    if (locator) {
        if (titleLayoutView) {
            if (!objc_getAssociatedObject(titleLayoutView, didPatchTitleTitlebarAndRedisplaySelector)) {
                objc_setAssociatedObject(titleLayoutView, didPatchTitleTitlebarAndRedisplaySelector, @YES, OBJC_ASSOCIATION_RETAIN);
                [titleLayoutView swizzleMethod:titleTitlebarAndRedisplaySelector withReplacement:JGMethodReplacementProviderBlock {
                    return JGMethodReplacement(void, NSView *, BOOL redisplay) {
                        JGOriginalImplementation(NSView *, redisplay);
                        [self.window _updateTitleLayout: objc_getAssociatedObject(self.window, titleLayoutLocatorSelector)];
                    };
                }];
            }
        }
    }
    
    [titleLayoutView performSelector:titleTitlebarAndRedisplaySelector withObject:@(YES)];
}

- (void)_updateTitleLayout:(id <TitleLayoutLocator>)locator {
    if (locator) {
        CGFloat center = [locator locateTitleCenter];
        if (center > 0) {
            NSMutableArray *titleViews = [NSMutableArray array];
            NSButton *iconButton = [self standardWindowButton:NSWindowDocumentIconButton];
            if (iconButton) {
                [titleViews addObject:iconButton];
            }
            
            for (NSView *each in [self standardWindowButton:NSWindowCloseButton].superview.subviews) {
                if ([each isKindOfClass:[NSTextField class]]) {
                    [titleViews addObject:each];
                }
            }
            
            NSButton *versionsButton = [self standardWindowButton:NSWindowDocumentVersionsButton];
            if (versionsButton) {
                [titleViews addObject:versionsButton];
            }
            
            if (titleViews.count > 0) {
                NSView *firstView = titleViews[0];
                NSView *lastView = titleViews[titleViews.count - 1];
                CGFloat start = NSMinX(firstView.frame);
                CGFloat end = NSMaxX(lastView.frame);
                CGFloat mid = start + ((end - start) / 2.0);
                CGFloat offset = roundf(center - mid);
                
                if (offset != 0) {
                    for (NSView *each in titleViews) {
                        NSPoint origin = each.frame.origin;
                        origin.x += offset;
                        [each setFrameOrigin:origin];
                    }
                }
            }
        }
    }
    
}

@end
