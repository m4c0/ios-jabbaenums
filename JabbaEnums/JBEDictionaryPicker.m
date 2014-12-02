//
//  JBEDictionaryPicker.m
//  JabbaEnums
//
//  Created by Eduardo Mauricio da Costa on 02/12/14.
//  Copyright (c) 2014 Eduardo Mauricio da Costa. All rights reserved.
//

#import "JBEDictionaryPicker.h"

#import "JBEObjectProxy.h"

@implementation JBEDictionaryPicker {
    float sum;
}

- (instancetype)initWithItems:(NSDictionary *)i andEnumClass:(NSString *)ec {
    self = [super init];
    if (self) {
        sum = 0;
        
        NSMutableDictionary * items = [NSMutableDictionary new];
        [i enumerateKeysAndObjectsUsingBlock:^(id key, id obj, BOOL *stop) {
            if ([key isEqual:@""]) {
                items[[NSNull null]] = obj;
            } else if (!ec) {
                items[key] = obj;
            } else {
                JBEObjectProxy * proxy = [JBEObjectProxy proxyForClassName:ec andStringValue:key];
                items[proxy] = obj;
            }
            self->sum += [obj floatValue];
        }];
        _items = items;
    }
    return self;
}

- (id)randomObject {
    __block id res = nil;
    __block float acc = sum;
    float rnd = (float)arc4random_uniform(10000 * sum) / 10000.0;
    [self.items enumerateKeysAndObjectsUsingBlock:^(id key, id obj, BOOL *stop) {
        acc -= [obj floatValue];
        if (rnd > acc) {
            res = key;
            *stop = YES;
        }
    }];
    if ([res isKindOfClass:[JBEObjectProxy class]]) return [res realObject];
    if (res == [NSNull null]) return nil;
    return res;
}

@end
