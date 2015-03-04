//
//  NSDictionary+TealiumAdditions.h
//  TealiumUtilities
//
//  Created by George Webster on 2/12/15.
//  Copyright (c) 2015 f. All rights reserved.
//

#import <Foundation/Foundation.h>

@interface NSDictionary (TealiumAdditions)

- (NSDictionary *) teal_stringifiedDictionary;

- (NSArray *) teal_arrayForDebugDisplay;

@end
