//
//  NSAppleEventDescriptor-Extensions.m
//  BirchEditor
//
//  Created by Jesse Grosjean on 8/19/16.
//  Copyright © 2005–2018 Jesse Grosjean. All rights reserved.
//

#import "NSAppleEventDescriptor-AEM.h"
#import "codecs.h"

@implementation NSAppleEventDescriptor (AEM)

+ (nullable NSAppleEventDescriptor *)pack:(nonnull id)objects {
    return [[AEMCodecs defaultCodecs] pack:objects];
}

- (nullable id)unpack {
    return [[AEMCodecs defaultCodecs] unpack:self];
}

@end
