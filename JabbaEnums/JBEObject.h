//
//  JBEObject.h
//  JabbaEnums
//
//  Created by Eduardo Mauricio da Costa on 12/11/14.
//  Copyright (c) 2014 Eduardo Mauricio da Costa. All rights reserved.
//

#import <Foundation/Foundation.h>

@interface JBEObject : NSObject

+ (NSArray *)loadInstancesFromArray:(NSArray *)arr;
+ (NSArray *)loadInstancesFromFile;

- (instancetype)initWithDictionary:(NSDictionary *)dict andDefaults:(NSDictionary *)defs;

- (id)objectForKeyedSubscript:(NSString *)key;

@end
