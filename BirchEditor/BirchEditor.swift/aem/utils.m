//
//  utils.m
//  Appscript
//

#import "utils.h"

extern const char *GetMacOSStatusCommentString(OSStatus err) __attribute__((weak_import));

NSString *ASDescriptionForError(OSStatus err) {
	return [NSString stringWithFormat: @"Mac OS error %i", err];
}


NSAppleEventDescriptor *AEMNewRecordOfType(DescType descriptorType) {
	NSAppleEventDescriptor *recordDesc, *desc;
	recordDesc = [[NSAppleEventDescriptor alloc] initRecordDescriptor];
	desc = [recordDesc coerceToDescriptorType: descriptorType];
	[recordDesc release];
	return desc;
}

