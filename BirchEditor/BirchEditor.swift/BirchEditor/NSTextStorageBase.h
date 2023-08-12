//
//  OutlineEditorTextStorage.h
//  BirchEditor
//
//  Created by Jesse Grosjean on 7/14/16.
//  Copyright © 2005–2018 Jesse Grosjean. All rights reserved.
//

#import <Cocoa/Cocoa.h>

@interface NSTextStorageBase : NSTextStorage

@property (nonatomic) NSTextStorage *backingStorage;

@end
