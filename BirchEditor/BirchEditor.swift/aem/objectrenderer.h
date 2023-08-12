//
//  formatter.m
//  appscript
//

#import <Cocoa/Cocoa.h>

@interface AEMObjectRenderer : NSObject

+(NSString *)formatOSType:(OSType)code;

+(void)formatObject:(id)obj indent:(NSString *)indent result:(NSMutableString *)result;

+(NSString *)formatObject:(id)obj;

@end

