//
//  JBEObjectProxy.m
//  JabbaEnums
//
//  Created by Eduardo Mauricio da Costa on 12/11/14.
//  Copyright (c) 2014 Eduardo Mauricio da Costa. All rights reserved.
//

#import "JBEObjectProxy.h"

@import ObjectiveC.runtime;

@implementation JBEObjectProxy {
    id realObject;
    
    Class enumClass;
    NSString * enumString;
    id (*instanceForString)(id, SEL, NSString *);
}

+ (id)proxyForClassName:(NSString *)type andStringValue:(NSString *)str {
    Class rescls = NSClassFromString(type);
    if (!rescls) return nil;
    if (rescls == [NSString class]) return str;
    
    SEL sel = @selector(instanceForString:);
    Method m = class_getClassMethod(rescls, sel);
    if (!m) return nil;
    
    JBEObjectProxy * ep = [JBEObjectProxy alloc];
    ep->instanceForString = ((id(*)(id, SEL, NSString *))method_getImplementation(m));
    ep->enumClass = rescls;
    ep->enumString = str;
    return ep;
}

- (id)replacementObjectForCoder:(NSCoder *)aCoder {
    return [self realObject];
}

- (id)copyWithZone:(NSZone *)zone {
    return self;
}

- (void)loadRealObject {
    realObject = instanceForString(enumClass, @selector(instanceForString:), enumString);
    if (!realObject) {
        NSLog(@"%@ does not contains %@", enumClass, enumString);
        abort();
    }
    
    enumClass = nil;
    enumString = nil;
    instanceForString = nil;
}

- (id)realObject {
    if (!realObject) [self loadRealObject];
    return realObject;
}

- (void)forwardInvocation:(NSInvocation *)invocation {
    [invocation invokeWithTarget:[self realObject]];
}

- (NSMethodSignature *)methodSignatureForSelector:(SEL)sel {
    return [[self realObject] methodSignatureForSelector:sel];
}

@end
