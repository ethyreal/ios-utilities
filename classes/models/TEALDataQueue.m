//
//  TEALDataQueue.m
//  TealiumUtilities
//
//  Created by George Webster on 1/19/15.
//  Copyright (c) 2015 Tealium. All rights reserved.
//

#import "TEALDataQueue.h"

@interface TEALDataQueue ()

@property (strong, nonatomic) NSMutableArray *dataQueue;

@property (nonatomic) NSUInteger capacity;

@end

@implementation TEALDataQueue

+ (instancetype) queueWithCapacity:(NSUInteger)capacity {

    return [[[self class] alloc] initWithCapacity:capacity];
}

- (instancetype) initWithCapacity:(NSUInteger)capacity {
    
    self = [super init];
    
    if (self) {
        _capacity = capacity;
    }
    
    return self;
}

- (NSMutableArray *) dataQueue {
    
    if (!_dataQueue) {
        _dataQueue = [NSMutableArray array];
    }
    return _dataQueue;
}

- (id) enqueueObject:(id)obj {
    
    if (!self.capacity) {
        return obj;
    }
    
    __block id dequeuedObject = nil;
    
    NSMutableArray *dataQueue = self.dataQueue;
    
    if (dataQueue.count == self.capacity) {

        [self dequeueNumberOfObjects:1 withBlock:^(id dObj) {
            
            dequeuedObject = dObj;
        }];
    }
    
    [dataQueue addObject:obj];
    
    return dequeuedObject;
}

- (id) enqueueObjectToFirstPosition:(id)obj {
    
    if (!self.capacity) {
        return obj;
    }

    __block id dequeuedObject = nil;
    
    NSMutableArray *dataQueue = self.dataQueue;
    
    if (dataQueue.count == self.capacity) {
        
        [self dequeueNumberOfObjects:1 withBlock:^(id dObj) {
            
            dequeuedObject = dequeuedObject;
        }];
    }
    
    [dataQueue insertObject:obj atIndex:0];
    
    return dequeuedObject;
}

- (id) dequeueObject {
    
    id firstObj = [self.dataQueue firstObject];
    
    if (firstObj) {
        [self.dataQueue removeObjectAtIndex:0];
    }
    
    return firstObj;
}

- (NSUInteger) count {
    return [self.dataQueue count];
}


- (NSArray *) allQueuedObjects {
    NSUInteger count = [self count];
    
    return [self queuedObjectsOrderedWithLimit:count];
}

- (NSArray *) queuedObjectsOrderedWithLimit:(NSUInteger)numberOfItems {
    
    if (numberOfItems == NSNotFound) {
        return nil;
    }
    
    if ([self.dataQueue count] <= numberOfItems) {
        return [NSArray arrayWithArray:self.dataQueue];
    } else {
        return [self.dataQueue subarrayWithRange:NSMakeRange(0, numberOfItems)];
    }
}

- (void) updateCapacity:(NSUInteger)capacity {
    
    if (self.capacity == capacity) {
        return;
    }
    
    NSUInteger capacityDiff = 0;
    
    if (capacity < self.dataQueue.count && capacity < self.capacity) {
        
        capacityDiff = self.capacity - capacity;
        
        [self dequeueNumberOfObjects:capacityDiff withBlock:nil];
    }
    
    self.capacity = capacity;
}

- (void) dequeueAllObjects {
    [self.dataQueue removeAllObjects];
}

- (void) dequeueNumberOfObjects:(NSUInteger)numberOfObjects withBlock:(void (^)(id dequeuedObject))block {
    
    if (numberOfObjects <= 0) {
        return;
    }
    
    for (NSUInteger xi = 0; xi < numberOfObjects; xi++) {
        
        id dequeuedObj = [self dequeueObject];
        
        if (block) {
            block( dequeuedObj );
        }
    }
    
}

- (void) dequeueObjects:(NSArray *)objects withBlock:(void (^)(id dequeuedObject))block {
    
    if (!objects) {
        return;
    }
    
    if (block) {
        for (id obj in objects) {
            
            if ([self.dataQueue containsObject:obj]) {
                block( obj );
            }
        }
    }

    [self.dataQueue removeObjectsInArray:objects];
}

- (void) enumerateQueuedObjectsUsingBlock:(void (^)(id obj,
                                                    NSUInteger idx,
                                                    BOOL *stop))block {
    
    [self.dataQueue enumerateObjectsUsingBlock:block];
}


@end
