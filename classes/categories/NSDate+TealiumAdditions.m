//
//  NSDate+TealiumAdditions.m
//  TealiumUtilities
//
//  Created by George Webster on 2/11/15.
//  Copyright (c) 2015 Tealium Inc. All rights reserved.
//

#import "NSDate+TealiumAdditions.h"

@implementation NSDate (TealiumAdditions)

- (NSString *) teal_timestampISOStringValue {

    NSDateFormatter *formatter = [NSDateFormatter new];

    formatter.timeZone      = [NSTimeZone timeZoneWithName:@"UTC"];
    formatter.timeStyle     = NSDateFormatterFullStyle;
    formatter.dateFormat    = @"yyyy-MM-dd'T'HH:mm:ss'Z'";
    
    return [formatter stringFromDate:self];
}

@end
