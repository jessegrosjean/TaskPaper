//
//  NSWindowTabbedBase.m
//  Birch
//
//  Created by Jesse Grosjean on 9/14/16.
//
//

#import "NSWindowTabbedBase.h"

@implementation NSWindowTabbedBase

- (instancetype)initWithContentRect:(NSRect)contentRect styleMask:(NSWindowStyleMask)style backing:(NSBackingStoreType)bufferingType defer:(BOOL)flag {
    self = [super initWithContentRect:contentRect styleMask:style backing:bufferingType defer:flag];
    if (self) {
    }
    return self;
}

@end
