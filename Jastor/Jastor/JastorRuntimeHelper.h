@interface JastorRuntimeHelper : NSObject {
	
}

+ (NSArray *)propertyNames:(Class)klass;
+ (Class)propertyClassForPropertyName:(NSString *)propertyName ofClass:(Class)klass;
+ (BOOL)isClassTypeForPropertyName:(NSString *)propertyName ofClass:(Class)klass;
+ (Class)NSClassFromString:(NSString*)string;

@end
