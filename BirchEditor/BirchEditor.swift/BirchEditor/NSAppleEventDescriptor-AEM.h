//
//  NSAppleEventDescriptor-Extensions.h
//  BirchEditor
//
//  Created by Jesse Grosjean on 8/19/16.
//  Copyright © 2005–2018 Jesse Grosjean. All rights reserved.
//

#import <Foundation/Foundation.h>

@interface NSAppleEventDescriptor (AEM)

+ (nullable NSAppleEventDescriptor *)pack:(nonnull id)objects;

- (nullable id)unpack;

@end
