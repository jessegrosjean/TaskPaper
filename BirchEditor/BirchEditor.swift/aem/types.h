//
//  types.h
//  aem
//

#import <Cocoa/Cocoa.h>
#import "utils.h"
#import "objectrenderer.h"

/**********************************************************************/
// not defined in __LP64__

#ifdef __LP64__
enum { typeFSS = 'fss ' };
#endif


/**********************************************************************/
// convenience macros

#define ASTrue [ASBoolean True]
#define ASFalse [ASBoolean False]


/**********************************************************************/
// Boolean class represents AEDescs of typeTrue and typeFalse


@interface ASBoolean : NSObject <AEMSelfPackingProtocol> {
	BOOL boolValue;
	NSAppleEventDescriptor *cachedDesc;
}

+ (id)True;

+ (id)False;

// client's shouldn't call -initWithBool: directly; use +True/+False (or ASTrue/ASFalse macros) instead
- (id)initWithBool:(BOOL)boolValue_;

- (BOOL)boolValue;

- (NSAppleEventDescriptor *)descriptor;

@end


/**********************************************************************/
// file object classes represent AEDescs of typeAlias, typeFSRef, typeFSSpec

//abstract base class


/***********************************/
// concrete classes

/**********************************************************************/

// abstract base class for AEMType, AEMEnum, AEMProperty, AEMKeyword
@interface AEMTypeBase : NSObject <AEMSelfPackingProtocol> {
	DescType type;
	OSType code;
	NSAppleEventDescriptor *cachedDesc;
}

// clients shouldn't call this next method directly; use subclasses' class/instance initialisers instead
- (id)initWithDescriptorType:(DescType)type_
						code:(OSType)code_
						desc:(NSAppleEventDescriptor *)desc;

- (id)initWithDescriptor:(NSAppleEventDescriptor *)desc; // normally called by AEMCodecs -unpack:, though clients could also use it to wrap any loose NSAppleEventDescriptor instances they might have. Note: doesn't verify descriptor's type before use; clients are responsible for providing an appropriate value.

- (id)initWithCode:(OSType)code_; // stub method; subclasses will override this to provide concrete implementations 

- (OSType)fourCharCode;

- (NSAppleEventDescriptor *)descriptor;

@end


/***********************************/
// concrete classes representing AEDescs of typeType, typeEnumerator, typeProperty, typeKeyword
// note: unlike NSAppleEventDescriptor instances, instances of these classes are fully hashable
// and comparable, so suitable for use as NSDictionary keys.

@interface AEMType : AEMTypeBase

+ (id)typeWithCode:(OSType)code_;

@end


@interface AEMEnum : AEMTypeBase

+ (id)enumWithCode:(OSType)code_;

@end


@interface AEMProperty : AEMTypeBase

+ (id)propertyWithCode:(OSType)code_;

@end


@interface AEMKeyword : AEMTypeBase

+ (id)keywordWithCode:(OSType)code_;

@end


/**********************************************************************/
// Unit types

@interface ASUnits : NSObject {
	NSNumber *value;
	NSString *units;
}

+ (id)unitsWithNumber:(NSNumber *)value_ type:(NSString *)units_;

+ (id)unitsWithInt:(int)value_ type:(NSString *)units_;

+ (id)unitsWithDouble:(double)value_ type:(NSString *)units_;

- (id)initWithNumber:(NSNumber *)value_ type:(NSString *)units_;

- (NSNumber *)numberValue;

- (int)intValue;

- (double)doubleValue;

- (NSString *)units;

@end
