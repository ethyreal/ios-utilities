//
//  TEALStringifiedDataCollectionTests.m
//  ios-utilities-tests
//
//  Created by George Webster on 5/4/15.
//  Copyright (c) 2015 Tealium Inc. All rights reserved.
//

#import <UIKit/UIKit.h>
#import <XCTest/XCTest.h>

#import <TealiumUtilities/NSDictionary+TealiumAdditions.h>

@interface TEALStringifiedDataCollectionTests : XCTestCase

@end

@implementation TEALStringifiedDataCollectionTests

- (void)setUp {
    [super setUp];
    // Put setup code here. This method is called before the invocation of each test method in the class.
}

- (void)tearDown {
    // Put teardown code here. This method is called after the invocation of each test method in the class.
    [super tearDown];
}

- (void) testStringifiedDictionary {
    
    NSMutableDictionary *testDict = [NSMutableDictionary dictionary];
    
    testDict[@"date"] = [NSDate date];
    testDict[@"NuMber"] = [NSNumber numberWithInt:42];
    testDict[@"string"] = @"Oh captain my captain.";
    testDict[@"value"] = [NSValue valueWithCGRect:CGRectMake(0.0f, 0.0f, 300.f, 300.f)];
    testDict[@"nested array"] = @[@"stop", @"collaborate", @"and", @"listen", @"ice", @"is back"];
    testDict[@"nested junk array"] = @[@"wtf", [NSDate date], [NSNumber numberWithDouble:0.05]];
    testDict[[NSDate date]] = @"this key is a date";
    
    NSDictionary *cleanedDict = [testDict teal_stringifiedDictionary];
    
    [cleanedDict enumerateKeysAndObjectsUsingBlock:^(id key, id val, BOOL *stop) {
        
        XCTAssertTrue([key isKindOfClass:[NSString class]], @"all keys should be stirngs");
        
        XCTAssertTrue([val isKindOfClass:[NSString class]] || [val isKindOfClass:[NSArray class]], @"all values should be strings or arrays at this point.");
        if ([val isKindOfClass:[NSArray class]]) {
            
            [(NSArray *)val enumerateObjectsUsingBlock:^(id obj, NSUInteger arrayIdx, BOOL *arrayStop) {
                XCTAssertTrue([obj isKindOfClass:[NSString class]] || [obj isKindOfClass:[NSArray class]], @"all values should be strings or arrays at this point.");
                
            }];
        }
    }];
    
    NSArray *allKeys = [testDict allKeys];
    NSArray *allCleanedKeys = [cleanedDict allKeys];
    XCTAssertEqual([allKeys count], [allCleanedKeys count], @"should have same number of keys before and after");
    
}

@end
