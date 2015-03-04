//
//  TEALDatasource.m
//  TealiumUtilities
//
//  Created by George Webster on 1/28/15.
//  Copyright (c) 2015 tealium. All rights reserved.
//

#import "TEALDatasource.h"

@implementation TEALDatasource

+ (instancetype) datasourceWithName:(NSString *)name andValue:(NSString *)value {
    
    TEALDatasource *datasource = [[[self class] alloc] init];
    
    if (datasource) {
        datasource.name  = name;
        datasource.value = value;
    }
    return datasource;
}

- (instancetype) initWithCoder:(NSCoder *)aDecoder {

    self = [self init];
    
    if (self) {
        _name   = [[aDecoder decodeObjectForKey:@"name"] copy];
        _value  = [[aDecoder decodeObjectForKey:@"value"] copy];
    }
    return self;
}

- (void) encodeWithCoder:(NSCoder *)aCoder {
    
    [aCoder encodeObject:self.name forKey:@"name"];
    [aCoder encodeObject:self.value forKey:@"value"];
}

- (instancetype) copyWithZone:(NSZone *)zone {
    
    TEALDatasource *copy = [[[self class] allocWithZone:zone] init];
    
    if (copy) {
        copy.name  = [self.name copyWithZone:zone];
        copy.value = [self.value copyWithZone:zone];
    }
    return copy;
}

- (NSString *) description {
    
    NSString *displayClass = NSStringFromClass([self class]);
    
    return [NSString stringWithFormat:@"%@: { %@ => %@ }",
            displayClass,
            self.name,
            self.value];
}
     
     

@end
