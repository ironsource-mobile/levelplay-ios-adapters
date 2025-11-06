//
//  ISYSOAdapter.m
//  ISYSOAdapter
//
//  Copyright © 2021-2025 Unity Technologies. All rights reserved.
//

#import "ISYSOAdapter.h"
#import "ISYSOConstants.h"
#import "ISYSORewardedVideoAdapter.h"
#import "ISYSOInterstitialAdapter.h"
#import <YsoNetwork/YsoNetwork.h>
#import <YsoNetwork/YsoNetwork-Swift.h>

// Handle init callback for all adapter instances
static InitState initState = INIT_STATE_NONE;
static ISConcurrentMutableSet<ISNetworkInitCallbackProtocol> *initCallbackDelegates = nil;

@interface ISYSOAdapter() <ISNetworkInitCallbackProtocol>

@end

@implementation ISYSOAdapter

#pragma mark - IronSource Protocol Methods

// Get adapter version
- (NSString *)version {
    return YSOAdapterVersion;
}

// Get network sdk version
- (NSString *)sdkVersion {
    return [YsoNetwork getSdkVersion];
}

#pragma mark - Initializations Methods And Callbacks

- (instancetype)initAdapter:(NSString *)name {
    self = [super initAdapter:name];
    
    if (self) {
        if (initCallbackDelegates == nil) {
            initCallbackDelegates = [ISConcurrentMutableSet<ISNetworkInitCallbackProtocol> set];
        }
        
        // Rewarded video
        ISYSORewardedVideoAdapter *rewardedVideoAdapter = [[ISYSORewardedVideoAdapter alloc] initWithYSOAdapter:self];
        [self setRewardedVideoAdapter:rewardedVideoAdapter];

        // Interstitial
        ISYSOInterstitialAdapter *interstitialAdapter = [[ISYSOInterstitialAdapter alloc] initWithYSOAdapter:self];
        [self setInterstitialAdapter:interstitialAdapter];
    }
    
    return self;
}

- (void)initSDKWithPlacementKey:(NSString *)placementKey{
    
    // Add self to the init delegates only in case the initialization has not finished yet
    if (initState == INIT_STATE_NONE || initState == INIT_STATE_IN_PROGRESS) {
        [initCallbackDelegates addObject:self];
    }
    
    static dispatch_once_t initSdkOnceToken;
    dispatch_once(&initSdkOnceToken, ^{
        initState = INIT_STATE_IN_PROGRESS;
        
        LogAdapterApi_Internal(@"placementKey = %@", placementKey);
        
        dispatch_async(dispatch_get_main_queue(), ^{
            @try{
                [YsoNetwork initializeWithViewController: self.topMostController];
                
                if ([YsoNetwork isInitialized])
                {
                    [self initializationSuccess];
                }
                else
                {
                    [self initializationFailure];
                }
            }
            @catch (NSException *exception) {
                LogAdapterApi_Internal(@"YSO initialization exception: %@", exception.reason);
                [self initializationFailure];
            }
        });
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

- (void)initializationFailure {
    LogAdapterDelegate_Internal(@"");
    
    initState = INIT_STATE_FAILED;
    
    NSArray* initDelegatesList = initCallbackDelegates.allObjects;
    
    for(id<ISNetworkInitCallbackProtocol> initDelegate in initDelegatesList){
        [initDelegate onNetworkInitCallbackFailed:@"YSO SDK init failed"];
    }
    [initCallbackDelegates removeAllObjects];
}

#pragma mark - Helper Methods

- (InitState)getInitState {
    return initState;
}

- (void)collectBiddingDataWithDelegate:(id<ISBiddingDataDelegate>)delegate {
    
    if (initState != INIT_STATE_SUCCESS) {
        NSString *error = [NSString stringWithFormat:@"returning nil as token since init hasn't finished successfully"];
        LogAdapterApi_Internal(@"%@", error);
        [delegate failureWithError:error];
        return;
    }
    
    NSString *token = [YsoNetwork getSignal];
    if (!token.length) {
        [delegate failureWithError:@"Failed to receive token - YSO"];
        return;
    }
    NSString *sdkVersion = [self sdkVersion];
    NSString *returnedToken = token ? token : @"";
    LogAdapterApi_Internal(@"token = %@, sdkVersion = %@", returnedToken, sdkVersion);
    NSDictionary *biddingDataDictionary = [NSDictionary dictionaryWithObjectsAndKeys: returnedToken, @"token", sdkVersion, @"sdkVersion", nil];
    [delegate successWithBiddingData:biddingDataDictionary];
}

- (NSString *)ysoLoadErrorToString:(e_ActionError)error {
    NSString *result = nil;
    switch (error) {
        case e_ActionErrorSdkNotInitialized:
            result = @"sdk not initialized";
        case e_ActionErrorInvalidRequest:
            result = @"bad request data sent to SDK";
        case e_ActionErrorInvalidConfig:
            result = @" invalid ad configuration";
        case e_ActionErrorLoad:
            result = @"ad load error";
        case e_ActionErrorTimeout:
            result = @"timeout loading the ad";
        case e_ActionErrorServer:
            result = @"error in the server response";
        case e_ActionErrorInternal:
            result = @"other error";
        default:
            result = @"unknown error";
    }
    return result;
}

@end
