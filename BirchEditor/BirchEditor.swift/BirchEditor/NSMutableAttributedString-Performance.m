//
//  NSMutableAttributedString-Performance.m
//  BirchEditor
//
//  Created by Jesse Grosjean on 7/14/16.
//  Copyright © 2005–2018 Jesse Grosjean. All rights reserved.
//

#import "NSMutableAttributedString-Performance.h"

@implementation NSMutableAttributedString (Performance)

- (void)noConversionSetAttributes:(nullable id)attrs range:(NSRange)range {
    [self setAttributes:attrs range:range];
}

- (void)noConversionAddAttributes:(nonnull id)attrs range:(NSRange)range {
    [self addAttributes:attrs range:range];
}

@end
