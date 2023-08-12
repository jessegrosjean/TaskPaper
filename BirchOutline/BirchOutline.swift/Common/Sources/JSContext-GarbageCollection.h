//
//  JSContext-GarbageCollection.h
//  BirchOutline
//
//  Created by Jesse Grosjean on 8/22/16.
//  Copyright © 2005–2018 Jesse Grosjean. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <JavaScriptCore/JavaScriptCore.h>

@interface JSContext (GarbageCollection)

- (void)garbageCollect;

@end
