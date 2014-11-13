//
//  JBEEnum.m
//  JabbaEnums
//
//  Created by Eduardo Mauricio da Costa on 12/11/14.
//  Copyright (c) 2014 Eduardo Mauricio da Costa. All rights reserved.
//

#import "JBEEnum.h"

@import ObjectiveC.runtime;

static NSDictionary * JBEEnumTypes = nil;

const char JBEEnumClassArray;
const char JBEEnumClassDictionary;
const char JBEEnumClassMethodSuffix;

@implementation JBEEnum
@synthesize key = m_key;
@synthesize variant = m_variant;

+ (void)initialize {
    if (self != [JBEEnum self] && [self urlForBlockDictionary]) [self blockDictionary];
}

+ (void)preloadEveryEnumPossible {
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        NSMutableDictionary * types = [NSMutableDictionary new];
        
        unsigned int count;
        Class * list = objc_copyClassList(&count);
        for (int i = 0; i < count; i++) {
            if (class_respondsToSelector(list[i], @selector(someSeriouslyUglyWorkaroundToTestForJbeEnums))) {
                types[NSStringFromClass(list[i])] = list[i];
            }
        }
        
        JBEEnumTypes = [types copy];
    });
}
- (void)someSeriouslyUglyWorkaroundToTestForJbeEnums {}

+ (void)releaseCache {
    objc_setAssociatedObject(self, &JBEEnumClassArray, nil, OBJC_ASSOCIATION_RETAIN_NONATOMIC);
    objc_setAssociatedObject(self, &JBEEnumClassDictionary, nil, OBJC_ASSOCIATION_RETAIN_NONATOMIC);
}

+ (NSString *)methodSuffix {
    NSString * ms = objc_getAssociatedObject(self, &JBEEnumClassMethodSuffix);
    if (!ms) {
        NSString * className = NSStringFromClass([self class]);
        ms = [className substringFromIndex:3];
        objc_setAssociatedObject(self, &JBEEnumClassMethodSuffix, ms, OBJC_ASSOCIATION_RETAIN_NONATOMIC);
    }
    return ms;
}

+ (instancetype)allocForType:(NSString *)type {
    if (!type) return [self alloc];

    NSAssert(JBEEnumTypes[type], @"Invalid type: %@");
    
    return [JBEEnumTypes[type] alloc];
}

+ (NSURL *)urlForBlockDictionary {
    return [[NSBundle bundleForClass:self] URLForResource:NSStringFromClass(self)
                                            withExtension:@"plist"];
}
+ (NSDictionary *)blockDictionary {
    NSDictionary * instance = objc_getAssociatedObject(self, &JBEEnumClassDictionary);
    if (!instance) {
        NSURL * url = [self urlForBlockDictionary];
        NSDictionary * res = url ? [self loadDictionaryFromURL:url] : [self filterDictionaryFromSuper];
        instance = [res copy];
        objc_setAssociatedObject(self, &JBEEnumClassDictionary, instance, OBJC_ASSOCIATION_RETAIN_NONATOMIC);
    }
    return instance;
}
+ (NSDictionary *)loadDictionaryFromURL:(NSURL *)url {
    Class meta = object_getClass(self);
    
    NSDictionary * dict = [NSDictionary dictionaryWithContentsOfURL:url];
    NSMutableDictionary * res = [NSMutableDictionary new];
    [dict enumerateKeysAndObjectsUsingBlock:^(id key, id raw, BOOL *stop) {
        NSString * novars = [key stringByAppendingString:[self methodSuffix]];
        NSString * withvars = [novars stringByAppendingString:@"WithVariant:"];
        
        if ([[key substringToIndex:1] isEqualToString:@"$"]) return;
        
        NSString * dollarParent = raw[@"$parent"];
        NSArray * parents = dollarParent ? @[ dollarParent ] : @[];
        
        id vars;
        NSArray * keyParts = [key componentsSeparatedByString:@"-"];
        NSAssert([keyParts count] <= 2, @"Invalid keyname: '%@'", key);
        if (([keyParts count] == 2) && dict[keyParts[0]]) {
            NSAssert(!raw[@"variants"], @"Variant with variants for: %@", key);
            key = keyParts[0];
            vars = @[ keyParts[1] ];
            parents = [parents arrayByAddingObject:key];
        }
        
        NSMutableDictionary * obj = [NSMutableDictionary new];
        for (NSString * parent in parents) {
            NSAssert(dict[parent], @"Unknown parent enum: '%@'", parent);
            [obj addEntriesFromDictionary:dict[parent]];
        }
        [obj addEntriesFromDictionary:raw];
        
        NSString * type = obj[@"type"];
        if (!vars) vars = obj[@"variants"];
        
        if (!vars) {
            id x = res[key] = [[self allocForType:type] initForKey:key withDictionary:obj andDefaults:nil];
            class_addMethod(meta, NSSelectorFromString(novars), imp_implementationWithBlock(^id(id _s){
                return x;
            }), "@@:");
        } else if ([vars isKindOfClass:[NSNumber class]]) {
            NSMutableDictionary * value = res[key] = [NSMutableDictionary new];
            
            NSMutableDictionary * newobj = [obj mutableCopy];
            [newobj removeObjectForKey:@"variants"];
            for (int i = 0; i < [vars intValue]; i++) {
                newobj[@"variant"] = [@(i) stringValue];
                value[[@(i) stringValue]] = [[self allocForType:type] initForKey:key
                                                                  withDictionary:[self applyTransforms:newobj]
                                                                     andDefaults:nil];
            }
            
            class_addMethod(meta, NSSelectorFromString(novars), imp_implementationWithBlock(^id(id _s){
                NSArray * vals = [value allValues];
                return [vals objectAtIndex:arc4random_uniform((int)[vals count])];
            }), "@@:");
            class_addMethod(meta, NSSelectorFromString(withvars), imp_implementationWithBlock(^id(id _s, id k){
                return value[[k description]];
            }), "@@:@");
        } else if ([vars isKindOfClass:[NSArray class]]) {
            NSMutableDictionary * value = res[key];
            if (!value) {
                value = res[key] = [NSMutableDictionary new];
            }
            
            NSMutableDictionary * newobj = [obj mutableCopy];
            [newobj removeObjectForKey:@"variants"];
            for (id varobj in vars) {
                NSString * var = [varobj description];
                newobj[@"variant"] = var;
                value[var] = [[self allocForType:type] initForKey:key
                                                   withDictionary:[self applyTransforms:newobj]
                                                      andDefaults:nil];
            }
            
            class_addMethod(meta, NSSelectorFromString(novars), imp_implementationWithBlock(^id(id _s){
                NSArray * vals = [value allValues];
                return [vals objectAtIndex:arc4random_uniform((int)[vals count])];
            }), "@@:");
            class_addMethod(meta, NSSelectorFromString(withvars), imp_implementationWithBlock(^id(id _s, id k){
                return value[[k description]];
            }), "@@:@");
        } else {
            NSLog(@"Unknown kind of variant");
            abort();
        }
    }];
    return res;
}
+ (NSDictionary *)filterDictionaryFromSuper {
    NSDictionary * sup = [[self superclass] blockDictionary];
    if (!sup) abort();
    
    NSMutableDictionary * res = [NSMutableDictionary new];
    [sup enumerateKeysAndObjectsUsingBlock:^(id key, id obj, BOOL *stop) {
        if ([obj isKindOfClass:self]) {
            res[key] = obj;
        } else if ([obj isKindOfClass:[NSDictionary class]]) {
            NSMutableDictionary * boo = [NSMutableDictionary new];
            [obj enumerateKeysAndObjectsUsingBlock:^(id key1, id obj1, BOOL *stop1) {
                if ([obj1 isKindOfClass:self]) {
                    boo[key1] = obj1;
                }
            }];
            if ([boo count]) res[key] = [boo copy];
        }
    }];
    return res;
}

+ (NSDictionary *)applyTransforms:(NSDictionary *)old {
    NSString * var = old[@"variant"];
    if (!var) return old;
    
    NSString * capsVar = [var capitalizedString];
    
    NSDictionary * t = @{ @"$variant" : var, @"$Variant" : capsVar };
    return [self applyTransforms:t toValue:old];
}
+ (id)applyTransforms:(NSDictionary *)t toValue:(id)obj {
    if ([obj isKindOfClass:[NSString class]]) {
        __block NSString * res = obj;
        [t enumerateKeysAndObjectsUsingBlock:^(id key, id obj1, BOOL *stop) {
            res = [res stringByReplacingOccurrencesOfString:key withString:obj1];
        }];
        return res;
    } else if ([obj isKindOfClass:[NSArray class]]) {
        NSMutableArray * res = [NSMutableArray new];
        for (id a in obj) {
            [res addObject:[self applyTransforms:t toValue:a]];
        }
        return [res copy];
    } else if ([obj isKindOfClass:[NSDictionary class]]) {
        NSMutableDictionary * res = [NSMutableDictionary new];
        [obj enumerateKeysAndObjectsUsingBlock:^(id key, id obj1, BOOL *stop) {
            NSString * nkey = [self applyTransforms:t toValue:key];
            res[nkey] = [self applyTransforms:t toValue:obj1];
        }];
        return res;
    } else {
        return obj;
    }
}

+ (instancetype)instanceWithKey:(NSString *)key {
    return [self blockDictionary][key];
}
+ (NSArray *)instancesWithKey:(NSString *)key {
    id res = [self blockDictionary][key];
    if (![res isKindOfClass:[NSDictionary class]]) return @[res];
    
    return [res allValues];
}
+ (instancetype)instanceWithKey:(NSString *)key andVariant:(NSString *)variant {
    if (!variant) return [self instanceWithKey:key];
    return [self blockDictionary][key][variant];
}

+ (instancetype)instanceForString:(NSString *)str {
    NSUInteger pos = [str rangeOfString:@"-"].location;
    if (pos == NSNotFound) {
        return [self instanceWithKey:str];
    } else {
        NSString * key = [str substringToIndex:pos];
        NSString * var = [str substringFromIndex:pos + 1];
        return [self instanceWithKey:key andVariant:var];
    }
}

+ (NSArray *)allInstances {
    NSArray * instances = objc_getAssociatedObject(self, &JBEEnumClassArray);
    if (!instances) {
        NSMutableArray * vals = [NSMutableArray new];
        
        for (id val in [[self blockDictionary] allValues]) {
            if ([val isKindOfClass:[NSDictionary class]]) {
                [vals addObjectsFromArray:[val allValues]];
            } else if ([val isKindOfClass:[NSArray class]]) {
                [vals addObjectsFromArray:val];
            } else {
                [vals addObject:val];
            }
        }
        
        instances = [vals sortedArrayUsingDescriptors:@[ [NSSortDescriptor sortDescriptorWithKey:@"key" ascending:YES]]];
        objc_setAssociatedObject(self, &JBEEnumClassArray, instances, OBJC_ASSOCIATION_RETAIN_NONATOMIC);
    }
    return instances;
}

- (instancetype)initForKey:(NSString *)key withDictionary:(NSDictionary *)obj andDefaults:(NSDictionary *)defs {
    self = [super initWithDictionary:obj andDefaults:defs];
    if (self) {
        m_key = key;
        m_variant = [obj[@"variant"]?:defs[@"variant"] description];
    }
    return self;
}

- (id)initWithCoder:(NSCoder *)aDecoder {
    return [[self class] instanceWithKey:[aDecoder decodeObjectForKey:@"key"]
                              andVariant:[aDecoder decodeObjectForKey:@"variant"]];
}
- (void)encodeWithCoder:(NSCoder *)aCoder {
    [aCoder encodeObject:self.key forKey:@"key"];
    [aCoder encodeObject:self.variant forKey:@"variant"];
}

- (id)copyWithZone:(NSZone *)zone {
    return self;
}

- (NSString *)description {
    return [NSString stringWithFormat:@"<%@: %@>", NSStringFromClass([self class]), [self stringValue]];
}

- (NSString *)stringValue {
    return self.variant ? [NSString stringWithFormat:@"%@-%@", self.key, self.variant] : self.key;
}

@end
