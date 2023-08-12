//
//  NSMutableAttributedString-Performance.h
//  BirchEditor
//
//  Created by Jesse Grosjean on 7/14/16.
//  Copyright © 2005–2018 Jesse Grosjean. All rights reserved.
//

#import <Foundation/Foundation.h>

@interface NSMutableAttributedString (Performance)

- (void)noConversionSetAttributes:(nullable id)attrs range:(NSRange)range;
- (void)noConversionAddAttributes:(nonnull id)attrs range:(NSRange)range;

@end
