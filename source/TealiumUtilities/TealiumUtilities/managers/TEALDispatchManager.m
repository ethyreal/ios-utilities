//
//  TEALDispatchManager.m
//  TealiumUtilities
//
//  Created by George Webster on 1/19/15.
//  Copyright (c) 2015 Tealium. All rights reserved.
//

#import "TEALDispatchManager.h"

#import "TEALDispatch.h"
#import "TEALBlocks.h"

@interface TEALDispatchManager ()

@property (strong, nonatomic) TEALDataQueue *sentDispatches;
@property (strong, nonatomic) TEALDataQueue *queuedDispatches;
@property (strong, nonatomic) TEALDataQueue *processingQueue;

@property (weak, nonatomic) id<TEALDispatchManagerDelegate> delegate;

@end

@implementation TEALDispatchManager

+ (instancetype) managerWithDelegate:(id<TEALDispatchManagerDelegate>)delegate {

    return [[TEALDispatchManager alloc] initWithDelegate:delegate];
}

- (instancetype) initWithDelegate:(id<TEALDispatchManagerDelegate>)delegate {

    self = [super init];
    
    if (self) {
        
        _delegate = delegate;
        
        NSUInteger dispatchCapacity = [_delegate offlineDispatchQueueCapacity];

        _queuedDispatches = [TEALDataQueue queueWithCapacity:dispatchCapacity];

        _sentDispatches = [TEALDataQueue queueWithCapacity:12];
        
        _processingQueue = nil;
    }
    return self;
}

- (void) updateQueuedCapacity:(NSUInteger)capacity {

    [self runDispatchQueue];
    [self.queuedDispatches updateCapacity:capacity];
}

- (void) disableDispatchQueue {
    
    [self.queuedDispatches dequeueAllObjects];
}

- (void) dequeueAllData {

    [self.queuedDispatches dequeueAllObjects];
    [self.sentDispatches dequeueAllObjects];
    
}

#pragma mark - enqueue / dequeue dispatches

- (void) addDispatch:(TEALDispatch *)aDispatch completionBlock:(TEALDispatchBlock)completionBlock {

    [self purgeStaleDispatches];
    
    NSUInteger batchSize    = [self.delegate dispatchBatchSize];
    NSUInteger queueCount   = [self.queuedDispatches count];
    
    BOOL shouldBatch = batchSize > 1;
    
    if (!shouldBatch && queueCount == 0) {
        
        __weak TEALDispatchManager *weakSelf = self;
        
        [self attemptDispatch:aDispatch
              completionBlock:^(TEALDispatchStatus status, TEALDispatch *dispatch, NSError *error) {

                  if (status != TEALDispatchStatusSent) {
                      [weakSelf enqueueDispatch:dispatch completionBlock:completionBlock];
                  } else if (completionBlock) {
                      completionBlock(status, dispatch, error);
                  }
              }];
    } else {
        
        [self enqueueDispatch:aDispatch completionBlock:completionBlock];
    }

    if ([self.queuedDispatches count] >= batchSize) {
        [self runDispatchQueue];
    }
    
    [self.delegate didUpdateDispatchQueues];
}

- (void) enqueueDispatch:(TEALDispatch *)dispatch completionBlock:(TEALDispatchBlock)completionBlock {
    
    [self.delegate willEnqueueDispatch:dispatch];
    
    dispatch.queued = YES;
    
    TEALDispatch *dequeued = [self.queuedDispatches enqueueObject:dispatch];
    
    if (dequeued) {
        [self attemptDispatch:dequeued
              completionBlock:nil];
    }
    
    [self.delegate didEnqueueDispatch:dispatch];
    
    if (completionBlock) {
        completionBlock(TEALDispatchStatusQueued, dispatch, nil);
    }
}

- (void) requeueDispatch:(TEALDispatch *)dispatch {
    
    [self.queuedDispatches enqueueObjectToFirstPosition:dispatch];
}

- (void) enqueueSentDispatch:(TEALDispatch *)sentDispatch {
    
    [self.sentDispatches enqueueObject:sentDispatch];
    
    [self.delegate didUpdateDispatchQueues];
}


- (void) purgeStaleDispatches {
    
    if (![self.queuedDispatches count]) {
        return;
    }
    
    NSMutableArray *purgeData = [NSMutableArray array];
    
    [self.queuedDispatches enumerateQueuedObjectsUsingBlock:^(id obj, NSUInteger idx, BOOL *stop) {
        
        if ([obj isKindOfClass:[TEALDispatch class]]) {
            
            TEALDispatch *dispatch = (TEALDispatch *)obj;
            
            if ([self.delegate hasDispatchExpired:dispatch]) {
                [purgeData addObject:dispatch];
            }
        }
        
    }];
    
    if ([purgeData count]) {
        [self.queuedDispatches dequeueObjects:purgeData withBlock:nil];
    }
}

- (void) runDispatchQueue {
    
    if ([self.delegate shouldAttemptDispatch]) {

        if ([self beginQueueTraversal]) {
            [self recursivelyDispatchWithCompletion:^{
                
                [self endQueueTraversal];
            }];
        }
    }
}

- (BOOL) beginQueueTraversal {

    NSUInteger queueCount = [self queuedDispatchCount];
    if (!self.processingQueue && queueCount) {

        self.processingQueue = [TEALDataQueue queueWithCapacity:queueCount];

        __weak TEALDispatchManager *weakSelf = self;
        
        [self.queuedDispatches dequeueNumberOfObjects:queueCount
                                            withBlock:^(id dequeuedObject) {
                                                
                                                [weakSelf.processingQueue enqueueObject:dequeuedObject];
                                            }];
        
        NSUInteger processingCount = [self.processingQueue count];

        [self.delegate willRunDispatchQueueWithCount:processingCount];
            
        return YES;
    }
    return NO;
}

- (void) recursivelyDispatchWithCompletion:(TEALVoidBlock)completion {

    if (!self.processingQueue) {
        if (completion) {
            completion();
        }
        return;
    }
    
    TEALDispatch *dispatch = [self.processingQueue dequeueObject];
    
    if (!dispatch) {
        if (completion) {
            completion();
        }
        return;
    }

    __weak TEALDispatchManager *weakSelf = self;
    
    TEALDispatchBlock dispatchCompletion = ^(TEALDispatchStatus status, TEALDispatch *resultDispatch, NSError *error) {
        
        if (status == TEALDispatchStatusSent) {
            [weakSelf recursivelyDispatchWithCompletion:completion];
        } else {
            
            if (weakSelf.processingQueue) {
                [weakSelf.processingQueue enqueueObjectToFirstPosition:dispatch];
            }
            if (completion) {
                completion();
            }
        }
    };
    
    [self attemptDispatch:dispatch
          completionBlock:dispatchCompletion];
}

- (void) endQueueTraversal {

    if (self.processingQueue) {
        NSUInteger count = [self.processingQueue count];
        
        if (count) {

            __weak TEALDispatchManager *weakSelf = self;
            
            [self.processingQueue dequeueNumberOfObjects:count
                                               withBlock:^(id dequeuedObject) {
                                                   
                                                   [weakSelf.queuedDispatches enqueueObjectToFirstPosition:dequeuedObject];
                                               }];
        }

        NSUInteger remainingCount = [self.queuedDispatches count];
        [self.delegate didRunDispatchQueueWithCount:remainingCount];
    }
    self.processingQueue = nil;
}

- (void) attemptDispatch:(TEALDispatch *)aDispatch completionBlock:(TEALDispatchBlock)completionBlock {
    
    if ([self.delegate shouldAttemptDispatch]) {

        __weak TEALDispatchManager *weakSelf = self;
        
        [self.delegate dispatchManager:self
                      requestsDispatch:aDispatch
                       completionBlock:^(TEALDispatchStatus status, TEALDispatch *dispatch, NSError *error) {
                           
                           if (status == TEALDispatchStatusSent) {
                               [weakSelf enqueueSentDispatch:dispatch];
                           }
                           if (completionBlock) {
                               completionBlock(status, dispatch, error);
                           }
                       }];
    } else if (completionBlock) {
        completionBlock(TEALDispatchStatusFailed, aDispatch, nil);
    }
}

- (NSUInteger) queuedDispatchCount {
    
    return [self.queuedDispatches count];
}

- (NSUInteger) sentDispatchCount {
    
    return [self.sentDispatches count];
}

@end
