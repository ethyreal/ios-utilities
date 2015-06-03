//
//  TEALSwizzler.m
//  TealiumUtilities
//
//  Created by George Webster on 2/27/15.
//  Copyright (c) 2015 Tealium Inc. All rights reserved.
//

#import "TEALSwizzler.h"

@implementation TEALSwizzler

+ (void) swizzleClass:(Class)class
             selector:(SEL)originalSelector
          newSelector:(SEL)newSelector {
    
    
    Method originalMethod   = class_getInstanceMethod(class, originalSelector);
    Method newMethod        = class_getInstanceMethod(class, newSelector);


    BOOL methodWasAdded = class_addMethod(class,
                                          originalSelector,
                                          method_getImplementation(newMethod),
                                          method_getTypeEncoding(newMethod));
    
    if (methodWasAdded) {
        class_addMethod(class,
                        newSelector,
                        method_getImplementation(originalMethod),
                        method_getTypeEncoding(originalMethod));
    } else {
        method_exchangeImplementations(originalMethod, newMethod);
    }
}

@end
