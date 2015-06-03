//
//  NSDictionary+TealiumAdditions.m
//  TealiumUtilities
//
//  Created by George Webster on 2/12/15.
//  Copyright (c) 2015 Tealium Inc. All rights reserved.
//

#import "NSDictionary+TealiumAdditions.h"
#import "NSArray+TealiumAdditions.h"
#import "NSObject+TealiumAdditions.h"

@implementation NSDictionary (TealiumAdditions)

- (NSDictionary *) teal_stringifiedDictionary {
    
    NSMutableDictionary *cleanedDict = [NSMutableDictionary dictionary];
    
    @autoreleasepool {
        NSArray *allKeys = [self allKeys];
        for (unsigned int i = 0; i < [allKeys count]; i++){
            id key = allKeys[i];
            id obj = self[key];
            
            NSString *newKey = [key teal_stringValue];
            
            if ([obj isKindOfClass:[NSArray class]]) {
                NSArray *ar = (NSArray *)obj;
                cleanedDict[newKey] = [ar teal_stringifiedArray];
            } else {
                
                cleanedDict[newKey] = [obj teal_stringValue];
            }
        }
    }

    return [NSDictionary dictionaryWithDictionary:cleanedDict];

}

- (NSArray *) teal_arrayForDebugDisplay {

    NSMutableArray *sortedArray = [NSMutableArray array];
    
    @autoreleasepool {
        NSArray *keys = [self allKeys];
        NSArray *sortedKeys = [keys sortedArrayUsingSelector:@selector(localizedCaseInsensitiveCompare:)];
        
        for (NSString *key in sortedKeys) {
            id object = self[key];
            NSString *string = [NSString stringWithFormat:@"%@ = %@", key, object];
            [sortedArray addObject:string];
        }
    }
    
    return [NSArray arrayWithArray:sortedArray];
}

@end
