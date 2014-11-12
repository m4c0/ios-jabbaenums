//
//  JBEObjectProxy.h
//  JabbaEnums
//
//  Created by Eduardo Mauricio da Costa on 12/11/14.
//  Copyright (c) 2014 Eduardo Mauricio da Costa. All rights reserved.
//

#import <Foundation/Foundation.h>

@interface JBEObjectProxy : NSProxy<NSCopying>
+ (id)proxyForClassName:(NSString *)type andStringValue:(NSString *)str;
- (id)realObject;
@end

// Protocolo informal
@protocol JBEProxiable <NSObject>
- (instancetype)instanceForString:(NSString *)string;
@end