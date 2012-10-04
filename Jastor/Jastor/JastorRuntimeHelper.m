#import <objc/runtime.h>
#import "JastorRuntimeHelper.h"
#import "Jastor.h"

static const char *property_getTypeName(objc_property_t property) {
	const char *attributes = property_getAttributes(property);
	char buffer[1 + strlen(attributes)];
	strcpy(buffer, attributes);
	char *state = buffer, *attribute;
	while ((attribute = strsep(&state, ",")) != NULL) {
		if (attribute[0] == 'T') {
			return (const char *)[[NSData dataWithBytes:(attribute + 3) length:strlen(attribute) - 4] bytes];
		}
	}
	return "@";
}

@implementation JastorRuntimeHelper

static NSMutableDictionary *propertyListByClass;
static NSMutableDictionary *propertyClassByClassAndPropertyName;

+ (NSArray *)propertyNames:(Class)klass {
	if (!propertyListByClass) propertyListByClass = [[NSMutableDictionary alloc] init];
    if (!propertyClassByClassAndPropertyName) propertyClassByClassAndPropertyName = [[NSMutableDictionary alloc] init];

	NSString *className = NSStringFromClass(klass);
	NSArray *value = [propertyListByClass objectForKey:className];
	
	if (value) {
		return value; 
	}
	
	NSMutableArray *propertyNames = [[NSMutableArray alloc] init];
	unsigned int propertyCount = 0;
    Class tempClass = klass;
    while (tempClass != [NSObject class] && tempClass != [Jastor class]) {
        objc_property_t *properties = class_copyPropertyList(tempClass, &propertyCount);
        
        for (unsigned int i = 0; i < propertyCount; ++i) {
            objc_property_t property = properties[i];
            const char * name = property_getName(property);
            
            NSString *propertyName = [NSString stringWithUTF8String:name];
            [propertyNames addObject:propertyName];
            
            NSString *key = [NSString stringWithFormat:@"%@:%@", NSStringFromClass(klass), propertyName];
            NSString *className;
            if ([propertyName isEqualToString:@"enumValue"]) {
                className = @"NSString";
            } else {
                className = [NSString stringWithUTF8String:property_getTypeName(property)];
            }
                    
            if (className != nil) {
                [propertyClassByClassAndPropertyName setObject:className forKey:key];
            }
        }
        free(properties);
        
        tempClass = [tempClass superclass];
    }
    
	
	[propertyListByClass setObject:propertyNames forKey:className];
	
	return propertyNames;
}

+ (Class)propertyClassForPropertyName:(NSString *)propertyName ofClass:(Class)klass {
	if (!propertyClassByClassAndPropertyName) propertyClassByClassAndPropertyName = [[NSMutableDictionary alloc] init];
	
	NSString *key = [NSString stringWithFormat:@"%@:%@", NSStringFromClass(klass), propertyName];
	NSString *value = [propertyClassByClassAndPropertyName objectForKey:key];
	
	if (value) {
		return NSClassFromString(value);
	}
	
	unsigned int propertyCount = 0;
	objc_property_t *properties = class_copyPropertyList(klass, &propertyCount);
	
	const char * cPropertyName = [propertyName UTF8String];
	
	for (unsigned int i = 0; i < propertyCount; ++i) {
		objc_property_t property = properties[i];
		const char * name = property_getName(property);
		if (strcmp(cPropertyName, name) == 0) {
			free(properties);
			NSString *className = [NSString stringWithUTF8String:property_getTypeName(property)];
            if (className != nil) {
                [propertyClassByClassAndPropertyName setObject:className forKey:key];
            }
			return NSClassFromString(className);
		}
	}
	free(properties);
	return nil;
}

@end
