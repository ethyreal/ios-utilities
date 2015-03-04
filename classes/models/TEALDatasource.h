//
//  TEALDatasource.h
//  TealiumUtilities
//
//  Created by George Webster on 1/28/15.
//  Copyright (c) 2015 tealium. All rights reserved.
//

#import <Foundation/Foundation.h>

@interface TEALDatasource : NSObject <NSCopying, NSCoding>

@property (copy, nonatomic) NSString *name;
@property (copy, nonatomic) NSString *value;

+ (instancetype) datasourceWithName:(NSString *)name andValue:(NSString *)value;

@end
