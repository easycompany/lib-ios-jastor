#import "Jastor.h"
#import "JastorRuntimeHelper.h"
#import "DateTimeUtils.h"
#import "CustomNSDateComponents.h"
#include "java/lang/Enum.h"
#include "IOSClass.h"
#import "DbRecord.h"
#import "DbDocument.h"

@implementation Jastor

@synthesize id;
static NSString *idPropertyName = @"id";
static NSString *idPropertyNameOnObject = @"id";

Class nsDictionaryClass;
Class nsArrayClass;

- (id)initWithDictionary:(NSDictionary *)dictionary {
	if (!nsDictionaryClass) nsDictionaryClass = [NSDictionary class];
	if (!nsArrayClass) nsArrayClass = [NSArray class];
	
	if ((self = [super init])) {
		for (NSString *key in [JastorRuntimeHelper propertyNames:[self class]]) {
			id value = [dictionary valueForKey:key];
			
			if (value == [NSNull null] || value == nil) continue;
            Class klass = [JastorRuntimeHelper propertyClassForPropertyName:key ofClass:[self class]];

            if ([key isEqualToString:@"payload"]) {
                if ([dictionary objectForKey:@"commandType"] != nil) {
                    NSString *commandType = [dictionary objectForKey:@"commandType"];
                    klass = NSClassFromString(commandType);
                    value = [[klass alloc] initWithDictionary:value];
                }
                else if ([dictionary objectForKey:@"eventType"] != nil) {
                    NSString *eventType = [dictionary objectForKey:@"eventType"];
                    klass = NSClassFromString(eventType);
                    value = [[klass alloc] initWithDictionary:value];
                } else if ([[dictionary objectForKey:@"headers"] objectForKey:@"PAYLOAD_TYPE"] != nil) {
                    NSString *payloadType = [[dictionary objectForKey:@"headers"] objectForKey:@"PAYLOAD_TYPE"];
                    klass = NSClassFromString(payloadType);
                    value = [[klass alloc] initWithDictionary:value];
                }
            }
			// handle dictionary
			else if ([value isKindOfClass:nsDictionaryClass]) {
                if (klass == [NSObject class]) {
                    value = [[NSDictionary alloc] initWithDictionary:value];
                } else if (klass == [NSDictionary class]) {
                    Class dictionaryItemType = [[self class] performSelector:NSSelectorFromString([NSString stringWithFormat:@"%@_class", key])];
                    
                    NSMutableDictionary *childObjects = [NSMutableDictionary dictionaryWithCapacity:[[value allKeys] count]];
                    
                    for (NSString *key in [value allKeys]) {
                        id child = [value objectForKey:key];
                        Jastor *childDTO = [[dictionaryItemType alloc] initWithDictionary:child];
                        [childObjects setObject:childDTO forKey:key];
                    }
                    value = childObjects;
                } else {

                    value = [[klass alloc] initWithDictionary:value];
                }
			}
			// handle array
			else if ([value isKindOfClass:nsArrayClass]) {
				Class arrayItemType = [[self class] performSelector:NSSelectorFromString([NSString stringWithFormat:@"%@_class", key])];
				
				NSMutableArray *childObjects = [NSMutableArray arrayWithCapacity:[value count]];
				
				for (id child in value) {
					if ([[child class] isSubclassOfClass:nsDictionaryClass]) {
						Jastor *childDTO = [[arrayItemType alloc] initWithDictionary:child];
						[childObjects addObject:childDTO];
					} else {
						[childObjects addObject:child];
					}
				}
				
				value = childObjects;
			}
            else if ([klass isSubclassOfClass:[NSDate class]]) {
                value = [DateTimeUtils getDateFromIsoFormat:value];
            }
            else if ([klass isSubclassOfClass:[CustomNSDateComponents class]]) {
                value = [DateTimeUtils deSerializeDateComponents:value];
            }
            else if ([[[klass alloc] init] respondsToSelector:@selector(initWithString:)]) {
                value = [[klass alloc]initWithString:(NSString*)value];
            }
            else if ([klass isSubclassOfClass:[JavaLangEnum class]]) {
                value = [JavaLangEnum valueOfWithIOSClass:[IOSClass classWithClass:klass] withNSString:value];
            }
            
            NSString *iosKey = [NSString stringWithFormat:@"%@_",key];
            if ([self isKindOfClass:[DbDocument class]] || [self isKindOfClass:[DbRecord class]]) {
                iosKey = key;
            }
            // set the value for the iosKey
            [self setValue:value forKey:iosKey];

		}
		
		id objectIdValue;
		if ((objectIdValue = [dictionary objectForKey:idPropertyName]) && objectIdValue != [NSNull null]) {
			if (![objectIdValue isKindOfClass:[NSString class]]) {
				objectIdValue = [NSString stringWithFormat:@"%@", objectIdValue];
			}
			[self setValue:objectIdValue forKey:idPropertyNameOnObject];
		}
	}
	return self;	
}



- (void)encodeWithCoder:(NSCoder*)encoder {
	[encoder encodeObject:self.id forKey:idPropertyNameOnObject];
	for (NSString *key in [JastorRuntimeHelper propertyNames:[self class]]) {
		[encoder encodeObject:[self valueForKey:key] forKey:key];
	}
}

- (id)initWithCoder:(NSCoder *)decoder {
	if ((self = [super init])) {
		[self setValue:[decoder decodeObjectForKey:idPropertyNameOnObject] forKey:idPropertyNameOnObject];
		
		for (NSString *key in [JastorRuntimeHelper propertyNames:[self class]]) {
			id value = [decoder decodeObjectForKey:key];
			if (value != [NSNull null] && value != nil) {
				[self setValue:value forKey:key];
			}
		}
	}
	return self;
}

- (NSString *)description {
	NSMutableDictionary *dic = [NSMutableDictionary dictionary];
	
	if (self.id) [dic setObject:self.id forKey:idPropertyNameOnObject];
	
	for (NSString *key in [JastorRuntimeHelper propertyNames:[self class]]) {
		id value = [self valueForKey:key];
		if (value != nil) [dic setObject:value forKey:key];
	}
	
	return [NSString stringWithFormat:@"#<%@: id = %@ %@>", [self class], self.id, [dic description]];
}

- (BOOL)isEqual:(id)object {
	if (object == nil || ![object isKindOfClass:[Jastor class]]) return NO;
	
	Jastor *model = (Jastor *)object;
	
	return [self.id isEqualToString:model.id];
}

@end
