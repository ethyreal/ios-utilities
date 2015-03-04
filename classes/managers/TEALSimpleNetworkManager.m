//
//  TEALSimpleNetworkManager.m
//  TealiumUtilities
//
//  Created by George Webster on 2/26/15.
//
//

#import "TEALSimpleNetworkManager.h"

@interface TEALSimpleNetworkManager ()

@end

@implementation TEALSimpleNetworkManager


- (void) sendAsynchronousRequest:(NSURLRequest *)request
               completionHandler:(TEALURLResponseBlock)completionHandler {

    if (NSFoundationVersionNumber >= NSFoundationVersionNumber_iOS_7_0) {

        NSURLSession *session = [NSURLSession sharedSession];
        
        TEALURLTaskResponseBlock taskCompletion = ^(NSData *data, NSURLResponse *response, NSError *error) {
            
            if (completionHandler) {
                completionHandler(response, data, error);
            }
            
        };
        
        NSURLSessionTask *task = [session dataTaskWithRequest:request
                                            completionHandler:taskCompletion];
        [task resume];
        
    } else {
        
        NSOperationQueue *targetQueue = self.responseQueue;
        
        if (!targetQueue) {
            targetQueue = [NSOperationQueue mainQueue];
        }
        
        [NSURLConnection sendAsynchronousRequest:request
                                           queue:targetQueue
                               completionHandler:^(NSURLResponse *response, NSData *data, NSError *error) {
                                   
                                   if (completionHandler) {
                                       completionHandler(response, data, error);
                                   }
                               }];
    }
}

@end
