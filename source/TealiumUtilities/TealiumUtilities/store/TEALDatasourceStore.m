//
//  TEALDatasourceStore.m
//  TealiumUtilities
//
//  Created by George Webster on 4/8/15.
//  Copyright (c) 2015 Tealium Inc. All rights reserved.
//

#import "TEALDatasourceStore.h"

const char * kTEALDatasoruceStoreQueueName = "com.tealium.datasource-store-queue";

@interface TEALDatasourceStore ()

@property (nonatomic, strong) dispatch_queue_t queue;

@property (nonatomic, strong) NSMutableDictionary *datasources;

@end

@implementation TEALDatasourceStore

+ (instancetype) sharedStore {
    
    static dispatch_once_t onceToken = 0;
    __strong static TEALDatasourceStore *_sharedStore = nil;
    
    dispatch_once(&onceToken, ^{
        _sharedStore = [[TEALDatasourceStore alloc] initPrivate];
    });
    
    return _sharedStore;
}

- (instancetype) init {
    [NSException raise:@"should not be initialized directly"
                format:@"please use [TEALDatasourceStore sharedStore] method"];
    return nil;
}

- (instancetype) initPrivate {
    
    self = [super init];
    
    if (self) {
        _queue = dispatch_queue_create(kTEALDatasoruceStoreQueueName, DISPATCH_QUEUE_CONCURRENT);
        _datasources = [NSMutableDictionary new];
    }
    return self;
}

- (id) objectForKey:(id<NSCopying, NSSecureCoding>)key {
    
    __block id obj = nil;
    
    dispatch_sync(self.queue, ^{
        obj = self.datasources[key];
    });
    
    return obj;
}

- (id) objectForKeyedSubscript:(id <NSCopying, NSSecureCoding>)key {
    return [self objectForKey:key];
}


- (void) setObject:(id<NSCopying, NSSecureCoding>)object
            forKey:(id<NSCopying, NSSecureCoding>)aKey {
    
    dispatch_barrier_async(self.queue, ^{
        
        self.datasources[aKey] = object;
    });
}

- (void) setObject:(id)obj forKeyedSubscript:(id <NSCopying, NSSecureCoding>)key {
    [self setObject:obj
             forKey:key];
}

#pragma mark - I/O

- (BOOL) unarchiveWithStorageKey:(NSString *)key {
    
    __block BOOL unarchived = NO;
    
    id obj = [[NSUserDefaults standardUserDefaults] objectForKey:key];
    
    if (obj && [obj isKindOfClass:[NSDictionary class]]) {
        dispatch_barrier_sync(self.queue, ^{
            [self.datasources addEntriesFromDictionary:obj];
            unarchived = YES;
        });
    }
    return unarchived;
}

- (void) archiveWithStorageKey:(NSString *)key {
    
    __block NSDictionary *dataCopy = nil;
    
    dispatch_barrier_sync(self.queue, ^{
        dataCopy = [self.datasources copy];
    });
    
    if (dataCopy) {
        [[NSUserDefaults standardUserDefaults] setObject:dataCopy
                                                  forKey:key];
        [[NSUserDefaults standardUserDefaults] synchronize];
    }
}


@end
