//
//  NSObject+TealiumAdditions.m
//  TealiumUtilities
//
//  Created by George Webster on 2/12/15.
//  Copyright (c) 2015 Tealium Inc. All rights reserved.
//

#import "NSObject+TealiumAdditions.h"

@implementation NSObject (TealiumAdditions)

- (NSString *) teal_stringValue {

    if (![self isKindOfClass:[NSString class]]) {
        return [NSString stringWithFormat:@"%@", self];
    }
    return [(NSString *)self copy];

}

@end
