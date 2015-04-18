/*
 Copyright (c) 2011, Tony Million.
 All rights reserved.
 
 Redistribution and use in source and binary forms, with or without
 modification, are permitted provided that the following conditions are met:
 
 1. Redistributions of source code must retain the above copyright notice, this
 list of conditions and the following disclaimer.
 
 2. Redistributions in binary form must reproduce the above copyright notice,
 this list of conditions and the following disclaimer in the documentation
 and/or other materials provided with the distribution.
 
 THIS SOFTWARE IS PROVIDED BY THE COPYRIGHT HOLDERS AND CONTRIBUTORS "AS IS"
 AND ANY EXPRESS OR IMPLIED WARRANTIES, INCLUDING, BUT NOT LIMITED TO, THE
 IMPLIED WARRANTIES OF MERCHANTABILITY AND FITNESS FOR A PARTICULAR PURPOSE
 ARE DISCLAIMED. IN NO EVENT SHALL THE COPYRIGHT HOLDER OR CONTRIBUTORS BE
 LIABLE FOR ANY DIRECT, INDIRECT, INCIDENTAL, SPECIAL, EXEMPLARY, OR
 CONSEQUENTIAL DAMAGES (INCLUDING, BUT NOT LIMITED TO, PROCUREMENT OF
 SUBSTITUTE GOODS OR SERVICES; LOSS OF USE, DATA, OR PROFITS; OR BUSINESS
 INTERRUPTION) HOWEVER CAUSED AND ON ANY THEORY OF LIABILITY, WHETHER IN
 CONTRACT, STRICT LIABILITY, OR TORT (INCLUDING NEGLIGENCE OR OTHERWISE)
 ARISING IN ANY WAY OUT OF THE USE OF THIS SOFTWARE, EVEN IF ADVISED OF THE
 POSSIBILITY OF SUCH DAMAGE. 
 */

#import "TEALReachabilityManager.h"

NSString *const kTealiumReachabilityChangedNotification = @"kReachabilityChangedNotification";

@interface TEALReachabilityManager (private)

-(void)reachabilityChanged:(SCNetworkReachabilityFlags)flags;
-(BOOL)setReachabilityTarget:(NSString*)hostname;
-(BOOL)isReachableWithFlags:(SCNetworkReachabilityFlags)flags;

@end

//static NSString *reachabilityFlags(SCNetworkReachabilityFlags flags) 
//{
//    return [NSString stringWithFormat:@"%c%c %c%c%c%c%c%c%c",
//#if	TARGET_OS_IPHONE
//            (flags & kSCNetworkReachabilityFlagsIsWWAN)               ? 'W' : '-',
//#else
//            'X',
//#endif
//            (flags & kSCNetworkReachabilityFlagsReachable)            ? 'R' : '-',
//            (flags & kSCNetworkReachabilityFlagsConnectionRequired)   ? 'c' : '-',
//            (flags & kSCNetworkReachabilityFlagsTransientConnection)  ? 't' : '-',
//            (flags & kSCNetworkReachabilityFlagsInterventionRequired) ? 'i' : '-',
//            (flags & kSCNetworkReachabilityFlagsConnectionOnTraffic)  ? 'C' : '-',
//            (flags & kSCNetworkReachabilityFlagsConnectionOnDemand)   ? 'D' : '-',
//            (flags & kSCNetworkReachabilityFlagsIsLocalAddress)       ? 'l' : '-',
//            (flags & kSCNetworkReachabilityFlagsIsDirect)             ? 'd' : '-'];
//}

//Start listening for reachability notifications on the current run loop
static void TMReachabilityCallback(SCNetworkReachabilityRef target, SCNetworkReachabilityFlags flags, void* info) 
{
#pragma unused (target)
    
    TEALReachabilityManager *reachability = ((__bridge TEALReachabilityManager*)info);
    
    // we probably dont need an autoreleasepool here as GCD docs state each queue has its own autorelease pool
    // but what the heck eh?
    @autoreleasepool 
    {
        [reachability reachabilityChanged:flags];
    }
}


@implementation TEALReachabilityManager

@synthesize reachabilityRef;
@synthesize reachabilitySerialQueue;
@synthesize reachableOnWWAN;
@synthesize reachableBlock;
@synthesize unreachableBlock;
@synthesize reachabilityObject;

#pragma mark - Class constructor methods
+ (instancetype) reachabilityWithHostname:(NSString*)hostname {
    
    SCNetworkReachabilityRef ref = SCNetworkReachabilityCreateWithName(NULL, [hostname UTF8String]);
    if (ref) 
    {
        id reachability = [[self alloc] initWithReachabilityRef:ref];
        return reachability;
    }
    
    return nil;
}

+ (instancetype) reachabilityWithAddress:(const struct sockaddr_in *)hostAddress {
    SCNetworkReachabilityRef ref = SCNetworkReachabilityCreateWithAddress(kCFAllocatorDefault, (const struct sockaddr*)hostAddress);
    if (ref) 
    {
        id reachability = [[self alloc] initWithReachabilityRef:ref];
        return reachability;
    }
    
    return nil;
}

+ (instancetype) reachabilityForInternetConnection {
    
    struct sockaddr_in zeroAddress;
    bzero(&zeroAddress, sizeof(zeroAddress));
    zeroAddress.sin_len = sizeof(zeroAddress);
    zeroAddress.sin_family = AF_INET;
    
    return [self reachabilityWithAddress:&zeroAddress];
}

+ (instancetype) reachabilityForLocalWiFi {
    
    struct sockaddr_in localWifiAddress;
    bzero(&localWifiAddress, sizeof(localWifiAddress));
    localWifiAddress.sin_len            = sizeof(localWifiAddress);
    localWifiAddress.sin_family         = AF_INET;
    // IN_LINKLOCALNETNUM is defined in <netinet/in.h> as 169.254.0.0
    localWifiAddress.sin_addr.s_addr    = htonl(IN_LINKLOCALNETNUM);
    
    return [self reachabilityWithAddress:&localWifiAddress];
}


#pragma mark - INIT

- (instancetype) initWithReachabilityRef:(SCNetworkReachabilityRef)ref {
    
    self = [super init];
    if (self) {
        self.reachableOnWWAN = YES;
        self.reachabilityRef = ref;
    }
    
    return self;    
}

- (void) dealloc {
    
    [self stopNotifier];
    if(self.reachabilityRef) {
        
        CFRelease(self.reachabilityRef);
        self.reachabilityRef = nil;
    }
}

#pragma mark - Notifier methods

- (BOOL) startNotifier {
    
    SCNetworkReachabilityContext    context = { 0, NULL, NULL, NULL, NULL };
    
    // this should do a retain on ourself, so as long as we're in notifier mode we shouldn't disappear out from under ourselves
    // woah
    self.reachabilityObject = self;
    
    context.info = (__bridge void *)self;
    
    if (!SCNetworkReachabilitySetCallback(self.reachabilityRef, TMReachabilityCallback, &context)) {
        return NO;
    }
    
    //create a serial queue
    self.reachabilitySerialQueue = dispatch_queue_create("com.tonymillion.reachability", NULL);        
    
    // set it as our reachability queue which will retain the queue
    if(SCNetworkReachabilitySetDispatchQueue(self.reachabilityRef, self.reachabilitySerialQueue))
    {
        // refcount should be ++ from the above function so this -- will mean its still 1
        return YES;
    }
    
    self.reachabilitySerialQueue = nil;
    return NO;
}

- (void) stopNotifier {
    
    // first stop any callbacks!
    SCNetworkReachabilitySetCallback(self.reachabilityRef, NULL, NULL);
    
    // unregister target from the GCD serial dispatch queue
    // this will mean the dispatch queue gets dealloc'ed
    if(self.reachabilitySerialQueue) {
        SCNetworkReachabilitySetDispatchQueue(self.reachabilityRef, NULL);
        self.reachabilitySerialQueue = nil;
    }
    
    self.reachabilityObject = nil;
}

#pragma mark - Reachability tests

// this is for the case where you flick the airplane mode
// you end up getting something like this:
//Reachability: WR ct-----
//Reachability: -- -------
//Reachability: WR ct-----
//Reachability: -- -------
// we treat this as 4 UNREACHABLE triggers - really apple should do better than this

#define testcase (kSCNetworkReachabilityFlagsConnectionRequired | kSCNetworkReachabilityFlagsTransientConnection)

- (BOOL) isReachableWithFlags:(SCNetworkReachabilityFlags)flags {
    BOOL connectionUP = YES;
    
    if(!(flags & kSCNetworkReachabilityFlagsReachable))
        connectionUP = NO;
    
    if( (flags & testcase) == testcase )
        connectionUP = NO;
    
#if	TARGET_OS_IPHONE
    if(flags & kSCNetworkReachabilityFlagsIsWWAN) {
        // we're on 3G
        if(!self.reachableOnWWAN) {
            // we dont want to connect when on 3G
            connectionUP = NO;
        }
    }
#endif
    
    return connectionUP;
}

- (BOOL) isReachable {
    
    SCNetworkReachabilityFlags flags;  
    
    if(!SCNetworkReachabilityGetFlags(self.reachabilityRef, &flags))
        return NO;
    
    return [self isReachableWithFlags:flags];
}

- (BOOL) isReachableViaWWAN {
    
#if	TARGET_OS_IPHONE

    SCNetworkReachabilityFlags flags = 0;
    
    if(SCNetworkReachabilityGetFlags(reachabilityRef, &flags)) 
    {
        // check we're REACHABLE
        if(flags & kSCNetworkReachabilityFlagsReachable) {
            
            // now, check we're on WWAN
            if(flags & kSCNetworkReachabilityFlagsIsWWAN) {
                
                return YES;
            }
        }
    }
#endif
    
    return NO;
}

- (BOOL) isReachableViaWiFi {
    
    SCNetworkReachabilityFlags flags = 0;
    
    if(SCNetworkReachabilityGetFlags(reachabilityRef, &flags)) {
        
        // check we're reachable
        if((flags & kSCNetworkReachabilityFlagsReachable)) {
            
#if	TARGET_OS_IPHONE
            // check we're NOT on WWAN
            if((flags & kSCNetworkReachabilityFlagsIsWWAN)) {
                
                return NO;
            }
#endif
            return YES;
        }
    }

    return NO;
}


// WWAN may be available, but not active until a connection has been established.
// WiFi may require a connection for VPN on Demand.
-(BOOL)isConnectionRequired
{
    return [self connectionRequired];
}

-(BOOL)connectionRequired
{
    SCNetworkReachabilityFlags flags;
	
	if(SCNetworkReachabilityGetFlags(reachabilityRef, &flags)) 
    {
		return (flags & kSCNetworkReachabilityFlagsConnectionRequired);
	}
    
    return NO;
}

// Dynamic, on demand connection?
-(BOOL)isConnectionOnDemand
{
	SCNetworkReachabilityFlags flags;
	
	if (SCNetworkReachabilityGetFlags(reachabilityRef, &flags)) 
    {
		return ((flags & kSCNetworkReachabilityFlagsConnectionRequired) &&
				(flags & (kSCNetworkReachabilityFlagsConnectionOnTraffic | kSCNetworkReachabilityFlagsConnectionOnDemand)));
	}
	
	return NO;
}

// Is user intervention required?
-(BOOL)isInterventionRequired
{
    SCNetworkReachabilityFlags flags;
	
	if (SCNetworkReachabilityGetFlags(reachabilityRef, &flags)) 
    {
		return ((flags & kSCNetworkReachabilityFlagsConnectionRequired) &&
				(flags & kSCNetworkReachabilityFlagsInterventionRequired));
	}
	
	return NO;
}


#pragma mark - Reachability status stuff


-(SCNetworkReachabilityFlags)reachabilityFlags
{
    SCNetworkReachabilityFlags flags = 0;
    
    if(SCNetworkReachabilityGetFlags(reachabilityRef, &flags)) 
    {
        return flags;
    }
    
    return 0;
}

//-(NSString *)currentReachabilityFlags {
//    
//    return reachabilityFlags([self reachabilityFlags]);
//}

#pragma mark - Callback function calls this method

- (void) reachabilityChanged:(SCNetworkReachabilityFlags)flags {
    
    if ([self isReachableWithFlags:flags]) {
        
        if (self.reachableBlock) {
            
            //NSLog(@"Reachability: blocks are not called on the main thread.\n Use dispatch_async(dispatch_get_main_queue(), ^{}); to update your UI!");
            self.reachableBlock(self);
        }
    } else {
        if (self.unreachableBlock) {
            
            //NSLog(@"Reachability: blocks are not called on the main thread.\n Use dispatch_async(dispatch_get_main_queue(), ^{}); to update your UI!");
            self.unreachableBlock(self);
        }
    }
    
    [[NSNotificationCenter defaultCenter] postNotificationName:kTealiumReachabilityChangedNotification
                                                        object:self];
}

@end
