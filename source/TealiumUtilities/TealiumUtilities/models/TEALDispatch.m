//
//  TEALDispatch.m
//  TealiumUtilities
//
//  Created by George Webster on 2/13/15.
//  Copyright (c) 2015 Tealium Inc. All rights reserved.
//

#import "TEALDispatch.h"

@implementation TEALDispatch

- (instancetype) initWithCoder:(NSCoder *)aDecoder {
    
    self = [self init];
    
    if (self) {
        _payload    = [aDecoder decodeObjectForKey:@"payload"];
        _timestamp  = [aDecoder decodeDoubleForKey:@"timestamp"];
        _queued     = [aDecoder decodeBoolForKey:@"queued"];
    }
    return self;
}

- (void) encodeWithCoder:(NSCoder *)aCoder {
    
    [aCoder encodeObject:self.payload forKey:@"payload"];
    [aCoder encodeDouble:self.timestamp forKey:@"timestamp"];
    [aCoder encodeBool:self.queued forKey:@"queued"];
}

@end
