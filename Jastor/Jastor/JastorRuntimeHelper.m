#import <objc/runtime.h>
#import "JastorRuntimeHelper.h"
#import "Jastor.h"
#include "java/lang/reflect/Field.h"
#include "java/lang/reflect/Modifier.h"
#define K_Excluded_Properties @[@"hash", @"superclass", @"description", @"debugDescription"]

static const char *property_getTypeName(objc_property_t property) {
    const char *attributes = property_getAttributes(property);
    char buffer[1 + strlen(attributes)];
    strcpy(buffer, attributes);
    char *state = buffer, *attribute;
    while ((attribute = strsep(&state, ",")) != NULL) {
        if (attribute[0] == 'T') {
            size_t len = strlen(attribute);
            attribute[len - 1] = '\0';
            const char *type = (const char *)[[NSData dataWithBytes:(attribute + 3) length:len - 2] bytes];
            return type;

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
	
    // try to get the object properties using the old code
	NSMutableArray *propertyNames = [[NSMutableArray alloc] init];
	unsigned int propertyCount = 0;
    Class tempClass = klass;
    while (tempClass != [NSObject class] && tempClass != [Jastor class]) {
        objc_property_t *properties = class_copyPropertyList(tempClass, &propertyCount);
        
        for (unsigned int i = 0; i < propertyCount; ++i) {
            objc_property_t property = properties[i];
            const char * name = property_getName(property);
            
            NSString *propertyName = [NSString stringWithUTF8String:name];
            if (![K_Excluded_Properties containsObject:propertyName]) {
                
                NSString *key = [NSString stringWithFormat:@"%@:%@", NSStringFromClass(klass), propertyName];
                NSString *className;
                if ([propertyName isEqualToString:@"enumValue"]) {
                    className = @"NSString";
                } else {
                    const char *type = property_getTypeName(property);
                    if (type == nil) {
                        className = nil;
                    } else {
                        className = [NSString stringWithUTF8String:type];
                    }
                }
                
                if (className != nil) {
                    [propertyNames addObject:propertyName];
                    [propertyClassByClassAndPropertyName setObject:className forKey:key];
                }
            }

        }
        free(properties);
        
        tempClass = [tempClass superclass];
    }
    
    // get the properties of the translated object using reflection
    if ([propertyNames count]==0) {
        NSDictionary *userInfo = @{@"className": className};
        [[[NSException alloc] initWithName:@"serializationError" reason:@"Could not serialize J2Objc translated class" userInfo:userInfo] raise];
//        IOSObjectArray *classFields = [[IOSClass classWithClass:klass] getFields];
//        IOSObjectArray *a__ = classFields;
//        JavaLangReflectField * const *b__ = ((IOSObjectArray *) nil_chk(a__))->buffer_;
//        JavaLangReflectField * const *e__ = b__ + a__->size_;
//        
//        while (b__ < e__) {
//            
//            JavaLangReflectField *field = (*b__++);
//            
//            if ([JavaLangReflectModifier isPublicWithInt:[((JavaLangReflectField *) nil_chk(field)) getModifiers]] && ![JavaLangReflectModifier isTransientWithInt:[field getModifiers]] && ![JavaLangReflectModifier isStaticWithInt:[field getModifiers]]) {
//                
//                NSString *fieldName = [field getName];
//                if (![fieldName isEqualToString:@"isa"]) {
//                    NSString *key = [NSString stringWithFormat:@"%@:%@", NSStringFromClass(klass), fieldName];
//                    NSString *fieldType = [[field getType] getName];
//                    
//                    [propertyNames addObject:fieldName];
//                    [propertyClassByClassAndPropertyName setObject:fieldType forKey:key];
//                    NSLog(@"%@: %@", [field getName], [[field getType] getName]);
//                }
//            }
//            
//        }
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
