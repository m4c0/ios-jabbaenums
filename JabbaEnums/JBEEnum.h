//
//  JBEEnum.h
//  JabbaEnums
//
//  Created by Eduardo Mauricio da Costa on 12/11/14.
//  Copyright (c) 2014 Eduardo Mauricio da Costa. All rights reserved.
//

#import "JBEObject.h"

@interface JBEEnum : JBEObject<NSCoding,NSCopying>
@property (nonatomic, readonly) NSString * key;
@property (nonatomic, readonly) NSString * variant;

+ (void)preloadEveryEnumPossible;

+ (instancetype)instanceWithKey:(NSString *)key;
+ (instancetype)instanceWithKey:(NSString *)key andVariant:(NSString *)variant;
+ (NSArray *)instancesWithKey:(NSString *)key;

+ (instancetype)instanceForString:(NSString *)str;

+ (NSArray *)instancesForPredicateWithFormat:(NSString *)predicate, ...;
+ (NSArray *)instancesForPredicateWithFormat:(NSString *)predicate arguments:(va_list)args;

+ (NSArray *)allInstances;
+ (void)releaseCache;

+ (NSDictionary *)convertAndRegisterDictionary:(NSDictionary *)dict;

- (instancetype)initForKey:(NSString *)key withDictionary:(NSDictionary *)dict andDefaults:(NSDictionary *)defs;
- (void)enumDidLoad;
- (NSString *)stringValue;
@end
