#import "Jastor.h"
#import "JastorRuntimeHelper.h"
#import "DateTimeUtils.h"
#import "CustomNSDateComponents.h"

@implementation Jastor

@synthesize objectId;
static NSString *idPropertyName = @"id";
static NSString *idPropertyNameOnObject = @"objectId";

Class nsDictionaryClass;
Class nsArrayClass;

- (id)initWithDictionary:(NSDictionary *)dictionary {
	if (!nsDictionaryClass) nsDictionaryClass = [NSDictionary class];
	if (!nsArrayClass) nsArrayClass = [NSArray class];
	
	if ((self = [super init])) {
		for (NSString *key in [JastorRuntimeHelper propertyNames:[self class]]) {
			id value = [dictionary valueForKey:key];
			
			if (value == [NSNull null] || value == nil) continue;
			
			// handle dictionary
			if ([value isKindOfClass:nsDictionaryClass]) {
                NSString *type = [value objectForKey:@"@type"];
				Class klass = NSClassFromString(type);//[JastorRuntimeHelper propertyClassForPropertyName:key ofClass:[self class]];
                if (klass == [NSObject class]) {
                    value = [[NSDictionary alloc] initWithDictionary:value];
                }else if (klass == [NSDictionary class]) {
                    Class dictionaryItemType = [[self class] performSelector:NSSelectorFromString([NSString stringWithFormat:@"%@_class", key])];
                    
                    NSMutableDictionary *childObjects = [NSMutableDictionary dictionaryWithCapacity:[[value allKeys] count]];
                    
                    for (NSString *key in [value allKeys]) {
                        id child = [value objectForKey:key];
                        Jastor *childDTO = [[dictionaryItemType alloc] initWithDictionary:child];
                        [childObjects setObject:childDTO forKey:key];
                    }
                    
                    
                    value = childObjects;
                    
                    
                }else {
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
			// handle all others
            Class klass = [JastorRuntimeHelper propertyClassForPropertyName:key ofClass:[self class]];
            if ([klass isSubclassOfClass:[NSDate class]]) {
                [self setValue:[DateTimeUtils getDateFromIsoFormat:value] forKey:key];
            } else if ([klass isSubclassOfClass:[CustomNSDateComponents class]]) {
                [self setValue:[DateTimeUtils deSerializeDateComponents:value] forKey:key];
            } else if (klass == nil && [JastorRuntimeHelper isClassTypeForPropertyName:key ofClass:[self class]]) {
                [self setValue:[JastorRuntimeHelper NSClassFromString:value] forKey:key];
            } else {
                [self setValue:value forKey:key];
            }
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
	[encoder encodeObject:self.objectId forKey:idPropertyNameOnObject];
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
	
	if (self.objectId) [dic setObject:self.objectId forKey:idPropertyNameOnObject];
	
	for (NSString *key in [JastorRuntimeHelper propertyNames:[self class]]) {
		id value = [self valueForKey:key];
		if (value != nil) [dic setObject:value forKey:key];
	}
	
	return [NSString stringWithFormat:@"#<%@: id = %@ %@>", [self class], self.objectId, [dic description]];
}

- (BOOL)isEqual:(id)object {
	if (object == nil || ![object isKindOfClass:[Jastor class]]) return NO;
	
	Jastor *model = (Jastor *)object;
	
	return [self.objectId isEqualToString:model.objectId];
}

@end
