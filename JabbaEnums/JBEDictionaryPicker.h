//
//  JBEDictionaryPicker.h
//  JabbaEnums
//
//  Created by Eduardo Mauricio da Costa on 02/12/14.
//  Copyright (c) 2014 Eduardo Mauricio da Costa. All rights reserved.
//

#import <Foundation/Foundation.h>

@interface JBEDictionaryPicker : NSObject
@property (nonatomic, readonly) NSDictionary * items;

- (instancetype)initWithItems:(NSDictionary *)i andEnumClass:(NSString *)ec;
- (id)randomObject;
@end
