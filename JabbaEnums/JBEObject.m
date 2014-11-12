//
//  JBEObject.m
//  JabbaEnums
//
//  Created by Eduardo Mauricio da Costa on 12/11/14.
//  Copyright (c) 2014 Eduardo Mauricio da Costa. All rights reserved.
//

#import "JBEObject.h"

#import "JBEObjectProxy.h"

@import CoreGraphics;
@import Foundation;
@import GLKit;
@import ObjectiveC.runtime;

#if TARGET_OS_IPHONE
@import UIKit;
#else
#define CGPointFromString NSPointFromString
#endif

@implementation JBEObject {
    NSMutableDictionary * rawValues;
}

+ (instancetype)allocForType:(NSString *)type {
    if (!type) return [self alloc];
    
    NSString * suffix = [NSStringFromClass([self class]) substringFromIndex:3];
    NSString * realClassName = [NSString stringWithFormat:@"IGE%@%@", type, suffix];
    return [NSClassFromString(realClassName) alloc];
}

+ (NSArray *)loadInstancesFromFile {
    NSURL * url = [[NSBundle bundleForClass:self] URLForResource:NSStringFromClass(self)
                                                   withExtension:@"plist"];
    return [self loadInstancesFromArray:[NSArray arrayWithContentsOfURL:url]];
}
+ (NSArray *)loadInstancesFromArray:(NSArray *)arr {
    NSAssert(self != [JBEObject class], @"Are you dumb or this is a smart usage for PlistObjs?");
    
    NSMutableArray * dst = [NSMutableArray new];
    for (NSDictionary * obj in arr) {
        NSString * type = obj[@"type"];
        [dst addObject:[[self allocForType:type] initWithDictionary:obj andDefaults:nil]];
    }
    return [dst copy];
}

- (instancetype)initWithDictionary:(NSDictionary *)obj andDefaults:(NSDictionary *)defs {
    self = [super init];
    if (self) {
        rawValues = [defs?:@{} mutableCopy];
        [rawValues addEntriesFromDictionary:obj];
        
        [self populateForClass:[self class] withDictionary:obj andDefaults:defs];
    }
    return self;
}
- (void)populateForClass:(Class)cls withDictionary:(NSDictionary *)obj andDefaults:(NSDictionary *)defs {
    unsigned int qty;
    Ivar * ivars = class_copyIvarList(cls, &qty);
    for (int i = 0; i < qty; i++) {
        const char * name = ivar_getName(ivars[i]);
        NSString * nameStr = [NSString stringWithCString:name + 1 encoding:NSUTF8StringEncoding];
        id val = self[nameStr];
        if (!val) continue;
        
        const char * enc = ivar_getTypeEncoding(ivars[i]);
        void * ptr = (uint8_t *)(__bridge void *)self + ivar_getOffset(ivars[i]);
        
        if (!strcmp(enc, "")) { // Swift
            continue;
        }
        
        if (!strcmp(enc, @encode(float))) {
            *(float *)ptr = [val floatValue];
        } else if (!strcmp(enc, @encode(double))) {
            *(double *)ptr = [val doubleValue];
        } else if (!strcmp(enc, @encode(int))) {
            *(int *)ptr = [val intValue];
        } else if (!strcmp(enc, @encode(unsigned int))) {
            *(unsigned int *)ptr = [val intValue];
        } else if (!strcmp(enc, @encode(BOOL))) {
            *(BOOL *)ptr = [val boolValue];
        } else if (!strncmp(enc, @encode(GLKVector2), 12)) {
            NSArray * sb = [val componentsSeparatedByString:@";"];
            NSAssert([sb count] == 2, @"Number of elements for: %s", name);
            *(GLKVector2 *)ptr = (GLKVector2){
                .x = [sb[0] floatValue],
                .y = [sb[1] floatValue],
            };
        } else if (!strncmp(enc, @encode(GLKVector3), 12)) {
            NSArray * sb = [val componentsSeparatedByString:@";"];
            NSAssert([sb count] == 3, @"Number of elements for: %s", name);
            *(GLKVector3 *)ptr = (GLKVector3){
                .r = [sb[0] floatValue],
                .g = [sb[1] floatValue],
                .b = [sb[2] floatValue],
            };
        } else if (!strncmp(enc, @encode(GLKVector4), 12)) {
            NSArray * sb = [val componentsSeparatedByString:@";"];
            NSAssert([sb count] == 4, @"Number of elements for: %s", name);
            *(GLKVector4 *)ptr = (GLKVector4){
                .r = [sb[0] floatValue],
                .g = [sb[1] floatValue],
                .b = [sb[2] floatValue],
                .a = [sb[3] floatValue],
            };
        } else if (!strncmp(enc, @encode(CGPoint), 9)) {
            *(CGPoint *)ptr = CGPointFromString(val);
        } else if ([val isKindOfClass:[NSDictionary class]]) {
            [self setValue:val forKey:nameStr];
        } else if ([val isKindOfClass:[NSArray class]]) {
            [self setValue:val forKey:nameStr];
        } else if ([val isKindOfClass:[NSString class]] && ![val length]) {
        } else {
            NSString * encStr = [NSString stringWithCString:enc + 2
                                                   encoding:NSUTF8StringEncoding];
            encStr = [encStr substringToIndex:strlen(enc) - 3];
            
            id res = [JBEObjectProxy proxyForClassName:encStr andStringValue:val];
            if (!res) {
                NSLog(@"%s => %s", name, enc);
                abort();
            }
            [self setValue:res forKey:nameStr];
        }
    }
    
    Class sup = class_getSuperclass(cls);
    if (sup != [JBEObject class]) [self populateForClass:sup withDictionary:obj andDefaults:defs];
}

#pragma mark - Extra stuff

- (id)objectForKeyedSubscript:(NSString *)key {
    return rawValues[key];
}

- (void)forwardInvocation:(NSInvocation *)anInvocation {
    id res = rawValues[NSStringFromSelector(anInvocation.selector)];
    [anInvocation setReturnValue:&res];
}
- (NSMethodSignature *)methodSignatureForSelector:(SEL)aSelector {
    NSMethodSignature * res = [super methodSignatureForSelector:aSelector];
    if (res) return res;
    
    NSString * key = NSStringFromSelector(aSelector);
    if (!rawValues[key]) return nil;
    
    IMP imp = imp_implementationWithBlock(^id(id wself){
        return ((JBEObject *)wself)->rawValues[key];
    });
    class_addMethod([self class], aSelector, imp, "@@:");
    
    return [NSMethodSignature signatureWithObjCTypes:"@@:"];
}

@end
