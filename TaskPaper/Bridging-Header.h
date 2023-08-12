//
//  Bridging-Header.h
//  Birch
//
//  Created by Jesse Grosjean on 8/21/16.
//
//

#import "Checkers.h"
#import "JGMethodSwizzler.h"
#import "NSTextStorageBase.h"
#import "NSTextStorage-Performance.h"
#import "NSWindowTabbedBase.h"
#import "NSMutableAttributedString-Performance.h"
#import "NSTextView-RangeForUserCompletionAdditions.h"
#import "NSTextView-AccessibilityPerformanceHacks.h"
#import "NSAppleEventDescriptor-AEM.h"
#import "getFileDescriptorPath.h"

#if SETAPP
#import "Setapp.h"
#endif
