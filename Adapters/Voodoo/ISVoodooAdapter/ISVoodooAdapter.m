//
//  ISVoodooAdapter.m
//  ISVoodooAdapter
//
//  Copyright © 2021-2025 Unity Technologies. All rights reserved.
//

#import "ISVoodooAdapter.h"
#import "ISVoodooConstants.h"
#import "ISVoodooRewardedVideoAdapter.h"
#import "ISVoodooInterstitialAdapter.h"
#import <VoodooAdn/VoodooAdn.h>

// Handle init callback for all adapter instances
static InitState initState = INIT_STATE_NONE;
static ISConcurrentMutableSet<ISNetworkInitCallbackProtocol> *initCallbackDelegates = nil;

@interface ISVoodooAdapter () <ISNetworkInitCallbackProtocol>

@end

@implementation ISVoodooAdapter

#pragma mark - IronSource Protocol Methods

// Get adapter version
- (NSString *)version {
    return VoodooAdapterVersion;
}

// Get network sdk version
- (NSString *)sdkVersion {
    return [AdnSdkBridge sdkVersion];
}

#pragma mark - Initializations Methods And Callbacks
- (instancetype)initAdapter:(NSString *)name {
    self = [super initAdapter:name];
    
    if (self) {
        if (initCallbackDelegates == nil) {
            initCallbackDelegates = [ISConcurrentMutableSet<ISNetworkInitCallbackProtocol> set];
        }
        
        // Rewarded video
        ISVoodooRewardedVideoAdapter *rewardedVideoAdapter = [[ISVoodooRewardedVideoAdapter alloc] initWithVoodooAdapter:self];
        [self setRewardedVideoAdapter:rewardedVideoAdapter];

        // Interstitial
        ISVoodooInterstitialAdapter *interstitialAdapter = [[ISVoodooInterstitialAdapter alloc] initWithVoodooAdapter:self];
        [self setInterstitialAdapter:interstitialAdapter];
    }
    
    return self;
}

- (void)initSDKWithConfig:(ISAdapterConfig *)adapterConfig {

    // Add self to the init delegates only in case the initialization has not finished yet
    if (initState == INIT_STATE_NONE || initState == INIT_STATE_IN_PROGRESS) {
        [initCallbackDelegates addObject:self];
    }
    
    NSString *placementId = adapterConfig.settings[kPlacementId];

    static dispatch_once_t initSdkOnceToken;
    dispatch_once(&initSdkOnceToken, ^{
        LogAdapterApi_Internal(@"placementId = %@", placementId);
        initState = INIT_STATE_IN_PROGRESS;

        ISVoodooAdapter * __weak weakSelf = self;

        [AdnSdkBridge initializeWith:kMediationName
                          completion:^ (bool success) {
            __typeof__(self) strongSelf = weakSelf;
            if (success) {
                [strongSelf initializationSuccess];
            } else {
                [strongSelf initializationFailure:@"Voodoo SDK init failed"];
            }
        }];
    });
}

- (void)initializationSuccess {
    LogAdapterDelegate_Internal(@"");
    
    initState = INIT_STATE_SUCCESS;
    
    NSArray *initDelegatesList = initCallbackDelegates.allObjects;
    
    for (id<ISNetworkInitCallbackProtocol> initDelegate in initDelegatesList) {
        [initDelegate onNetworkInitCallbackSuccess];
    }
    
    [initCallbackDelegates removeAllObjects];
}

- (void)initializationFailure:(NSString *)error {
    LogAdapterDelegate_Internal(@"error = %@", error.description);
    
    initState = INIT_STATE_FAILED;
    
    NSArray *initDelegatesList = initCallbackDelegates.allObjects;
    
    for (id<ISNetworkInitCallbackProtocol> delegate in initDelegatesList) {
        [delegate onNetworkInitCallbackFailed:error];
    }
    
    [initCallbackDelegates removeAllObjects];
}

#pragma mark - Helper Methods

- (InitState)getInitState {
    return initState;
}

- (void)collectBiddingDataWithDelegate:(id<ISBiddingDataDelegate>)delegate
                         placementType:(AdnPlacementType)placementType
                         adapterConfig:(ISAdapterConfig *)adapterConfig {
    if (initState == INIT_STATE_NONE) {
        NSString *error = [NSString stringWithFormat:@"returning nil as token since init hasn't started"];
        LogAdapterApi_Internal(@"%@", error);
        [delegate failureWithError:error];
        return;
    }
    
    [AdnSdkBridge getBidTokenWithPlacement:placementType
                                completion:^(NSString *token) {
        if (token.length == 0) {
            LogAdapterApi_Internal(@"Failed to receive token - Voodoo");
            [delegate failureWithError:@"Failed to receive token - Voodoo"];
            return;
        }
        
        NSString *sdkVersion = [self sdkVersion];

        LogAdapterApi_Internal(@"%@ = %@, sdkVersion = %@", kMediationTokenKey, token, sdkVersion);
        NSDictionary *biddingDataDictionary = @{kMediationTokenKey: token, @"sdkVersion": sdkVersion};
        [delegate successWithBiddingData:biddingDataDictionary];
    }];
}

@end
