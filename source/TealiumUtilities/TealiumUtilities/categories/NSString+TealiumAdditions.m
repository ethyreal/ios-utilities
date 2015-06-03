//
//  NSString+TealiumAdditions.m
//  TealiumUtilities
//
//  Created by George Webster on 2/10/15.
//  Copyright (c) 2015 Tealium Inc. All rights reserved.
//

#import "NSString+TealiumAdditions.h"

@implementation NSString (TealiumAdditions)

+ (NSString *) teal_stringFromBool:(BOOL)value {

    return (value) ? @"YES" : @"NO";
}

@end
