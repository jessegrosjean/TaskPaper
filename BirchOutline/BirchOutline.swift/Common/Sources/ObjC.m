//
//  ObjC.m
//  TaskPaper
//
//  Created by Jesse Grosjean on 7/6/16.
//  Copyright © 2005–2018 Jesse Grosjean. All rights reserved.
//

#import "ObjC.h"

@implementation ObjC

+ (BOOL)catchException:(void(^)(void))tryBlock error:(__autoreleasing NSError **)error {
    @try {
        tryBlock();
        return YES;
    }
    @catch (NSException *exception) {
        *error = [[NSError alloc] initWithDomain:exception.name code:0 userInfo:exception.userInfo];
    }
}

@end
