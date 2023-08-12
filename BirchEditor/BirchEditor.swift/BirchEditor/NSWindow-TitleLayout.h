//
//  NSWindow.h
//  BirchEditor
//
//  Created by Jesse Grosjean on 8/3/16.
//  Copyright © 2005–2018 Jesse Grosjean. All rights reserved.
//

#import <Cocoa/Cocoa.h>

@protocol TitleLayoutLocator
- (CGFloat)locateTitleCenter;
@end

@interface NSWindow (TitleLayout)

- (void)updateTitleLayout:(id <TitleLayoutLocator>)locator;

@end
