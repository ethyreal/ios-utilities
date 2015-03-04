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

@property (weak, nonatomic) id<TEALDispatchManagerDelegate> delegate;

@property BOOL traversingQueue;

@end

@implementation TEALDispatchManager

+ (instancetype) managerWithDelegate:(id<TEALDispatchManagerDelegate>)delegate {

    return [[[self class] alloc] initWithDelegate:delegate];
}

- (instancetype) initWithDelegate:(id<TEALDispatchManagerDelegate>)delegate {

    self = [super init];
    
    if (self) {
        
        _delegate = delegate;
        
        NSUInteger dispatchCapacity = [_delegate offlineDispatchQueueCapacity];

        _queuedDispatches = [TEALDataQueue queueWithCapacity:dispatchCapacity];

        _sentDispatches = [TEALDataQueue queueWithCapacity:12];
        
        _traversingQueue = NO;
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
        
        [self attemptDispatch:aDispatch
              completionBlock:^(TEALDispatchStatus status, TEALDispatch *dispatch, NSError *error) {

                  if (status != TEALDispatchStatusSent) {
                      [self enqueueDispatch:dispatch completionBlock:completionBlock];
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
    
    if (completionBlock){
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

//        NSUInteger count = [self queuedDispatchCount];
//        
//        BOOL shouldContinue = (count);
//
//        if (shouldContinue) {
//            
//            [self.delegate willRunDispatchQueueWithCount:count];
//        }
//        
//        while (shouldContinue) {
//            
//            TEALDispatch *dispatch = [self.queuedDispatches dequeueObject];
//            
//            if ([self attemptDispatch:dispatch completionBlock:nil]) {
//
//                shouldContinue = ( [self queuedDispatchCount] && [self.delegate shouldAttemptDispatch] );
//            } else {
//                [self requeueDispatch:dispatch];
//                shouldContinue = NO;
//            }
//        }
        
        [self beginQueueTraversal];
        
        [self recusivelyDispatchWithCompletion:^{
            
            [self endQueueTraversal];
        }];
    }
}

- (void) beginQueueTraversal {

    if (!self.traversingQueue) {

        NSUInteger count = [self queuedDispatchCount];
        [self.delegate willRunDispatchQueueWithCount:count];
        
        self.traversingQueue = YES;
    }
}

- (void) recusivelyDispatchWithCompletion:(TEALVoidBlock)completion {
    
    TEALDispatch *dispatch = [self.queuedDispatches dequeueObject];
    
    if (!dispatch || !self.traversingQueue) {
        if (completion) {
            completion();
        }
        return;
    }

    
    TEALDispatchBlock dispatchCompletion = ^(TEALDispatchStatus status, TEALDispatch *resultDispatch, NSError *error) {
        
        if (status == TEALDispatchStatusSent) {
            [self recusivelyDispatchWithCompletion:completion];
        } else {
            [self requeueDispatch:dispatch];
            if (completion) {
                completion();
            }
        }
    };
    
    [self attemptDispatch:dispatch
          completionBlock:dispatchCompletion];
}

- (void) endQueueTraversal {
    
    if (self.traversingQueue) {

        self.traversingQueue = NO;
    }
}

- (void) attemptDispatch:(TEALDispatch *)aDispatch completionBlock:(TEALDispatchBlock)completionBlock {
    
    if ([self.delegate shouldAttemptDispatch]) {

        [self.delegate dispatchManager:self
                      requestsDispatch:aDispatch
                       completionBlock:^(TEALDispatchStatus status, TEALDispatch *dispatch, NSError *error) {
                           
                           if (status == TEALDispatchStatusSent) {
                               [self enqueueSentDispatch:dispatch];
                           }
                           if (completionBlock) {
                               completionBlock(status, dispatch, error);
                           }
                       }];
    } else {
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
