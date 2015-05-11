//
//  TEALDataQueueTests.m
//  Tealium iOS Utilites
//
//  Created by George Webster on 1/20/15.
//
//

#import <UIKit/UIKit.h>
#import <XCTest/XCTest.h>

#import <TealiumUtilities/TEALDataQueue.h>


@interface TEALDataQueueTests : XCTestCase

@property (strong, nonatomic) TEALDataQueue *queueManager;
@property (nonatomic) NSUInteger capacity;

@end

@implementation TEALDataQueueTests

- (void) setUp {
    [super setUp];
    
    self.capacity = 10;
    self.queueManager = [TEALDataQueue queueWithCapacity:self.capacity];
}

- (void) tearDown {
    
    [super tearDown];
}

- (void) enqueueNumberOfItems:(NSUInteger)numberOfItems {
    
    for (NSUInteger xi = 0; xi < numberOfItems; xi++) {
        NSString *item = [NSString stringWithFormat:@"number_%lu", (unsigned long)xi];
        
        [self.queueManager enqueueObject:item];
    }
    
}

- (void) updateCapcity:(NSUInteger)capacity {
    self.capacity = capacity;
    [self.queueManager updateCapacity:capacity];
}

- (void) testCapacityLimit {
    
    [self enqueueNumberOfItems:13];
    
    XCTAssertEqual([self.queueManager count], self.capacity, @"queue should be limited to %lu items", self.capacity);
}

- (void) testCapacityUpdate {
    
    [self enqueueNumberOfItems:10];
    
    [self updateCapcity:5];
    
    XCTAssertEqual([self.queueManager count], self.capacity, @"queue should be limited to %lu items", self.capacity);
    
    [self updateCapcity:5];
    
    XCTAssertEqual([self.queueManager count], self.capacity, @"queue should still contain to %lu items", self.capacity);
    
    [self enqueueNumberOfItems:20];
    
    XCTAssertEqual([self.queueManager count], self.capacity, @"queue should be limited to %lu items", self.capacity);
}

- (void) testDequeueOrder {
    
    [self enqueueNumberOfItems:10];
    
    NSString *firstObj = [self.queueManager dequeueObject];
    
    XCTAssertTrue([firstObj isEqualToString:@"number_0"], @"first object should be number_0");
    
    // should be 1 - 9 left
    
    [self enqueueNumberOfItems:2];
    
    // + 2 limit of 10, 1 should have been popped off;
    
    firstObj = [self.queueManager dequeueObject];
    
    XCTAssertTrue([firstObj isEqualToString:@"number_2"], @"first object should now be number_2");
}

- (void) testQueuedObjectsOrderedWithLimit {
    
    [self updateCapcity:100];
    
    [self enqueueNumberOfItems:100];
    
    XCTAssertEqual([self.queueManager count], self.capacity, @"queue should contain %lu items", self.capacity);
    
    NSUInteger limit = 10;
    NSArray *first10Items = [self.queueManager queuedObjectsOrderedWithLimit:limit];
    
    XCTAssertEqual([first10Items count], limit, @"queue should have returned %lu items", limit);
    
    [first10Items enumerateObjectsUsingBlock:^(id obj, NSUInteger idx, BOOL *stop) {
        
        NSString *testValue = (NSString *)obj;
        NSString *targetValue = [NSString stringWithFormat:@"number_%ld", idx];
        
        XCTAssertTrue([testValue isEqualToString:testValue], @"item at index: %ld should equal: %@", idx, targetValue);
        
    }];
}



@end
