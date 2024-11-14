//
//  ISYandexAdapter.m
//  ISYandexAdapter
//
//  Copyright © 2024 ironSource Mobile Ltd. All rights reserved.
//

#import "ISYandexAdapter.h"
#import "ISYandexConstants.h"
#import "ISYandexRewardedVideoAdapter.h"
#import "ISYandexInterstitialAdapter.h"
#import "ISYandexBannerAdapter.h"
#import <YandexMobileAds/YandexMobileAds.h>

// Handle init callback for all adapter instances
static InitState initState = INIT_STATE_NONE;
static ISConcurrentMutableSet<ISNetworkInitCallbackProtocol> *initCallbackDelegates = nil;
static YMABidderTokenLoader *bidderTokenLoader = nil;

@interface ISYandexAdapter() <ISNetworkInitCallbackProtocol>

@end

@implementation ISYandexAdapter

#pragma mark - IronSource Protocol Methods

// Get adapter version
- (NSString *)version {
    return YandexAdapterVersion;
}

// Get network sdk version
- (NSString *)sdkVersion {
    return [YMAMobileAds sdkVersion];
}

#pragma mark - Initializations Methods And Callbacks

- (instancetype)initAdapter:(NSString *)name {
    self = [super initAdapter:name];
    
    if (self) {
        if (initCallbackDelegates == nil) {
            initCallbackDelegates = [ISConcurrentMutableSet<ISNetworkInitCallbackProtocol> set];
        }
        
        // The Yandex token loader object needs to be saved so that we can retrieve
        // the completion handler callback for async token handling.
        if (bidderTokenLoader == nil) {
            bidderTokenLoader = [[YMABidderTokenLoader alloc] initWithMediationNetworkName:kMediationName];
        }
        
        // Rewarded video
        ISYandexRewardedVideoAdapter *rewardedVideoAdapter = [[ISYandexRewardedVideoAdapter alloc] initWithYandexAdapter:self];
        [self setRewardedVideoAdapter:rewardedVideoAdapter];

        // Interstitial
        ISYandexInterstitialAdapter *interstitialAdapter = [[ISYandexInterstitialAdapter alloc] initWithYandexAdapter:self];
        [self setInterstitialAdapter:interstitialAdapter];
        
        // Banner
        ISYandexBannerAdapter *bannerAdapter = [[ISYandexBannerAdapter alloc] initWithYandexAdapter:self];
        [self setBannerAdapter:bannerAdapter];
        
        // The network's capability to load a Rewarded Video ad while another Rewarded Video ad of that network is showing
        LWSState = LOAD_WHILE_SHOW_BY_NETWORK;
    }
    
    return self;
}

- (void)initSDKWithAppId:(NSString *)appId {
    
    // Add self to the init delegates only in case the initialization has not finished yet
    if (initState == INIT_STATE_NONE || initState == INIT_STATE_IN_PROGRESS) {
        [initCallbackDelegates addObject:self];
    }
    
    static dispatch_once_t initSdkOnceToken;
    dispatch_once(&initSdkOnceToken, ^{
        initState = INIT_STATE_IN_PROGRESS;
        
        LogAdapterApi_Internal(@"appId = %@", appId);

        if ([ISConfigurations getConfigurations].adaptersDebug) {
            [YMAMobileAds enableLogging];
        }
        
        ISYandexAdapter * __weak weakSelf = self;
        [YMAMobileAds initializeSDKWithCompletionHandler:^{
            __typeof__(self) strongSelf = weakSelf;
            [strongSelf initializationSuccess];

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

#pragma mark - Legal Methods

- (void)setConsent:(BOOL)consent {
    LogAdapterApi_Internal(@"consent = %@", consent ? @"YES" : @"NO");
    [YMAMobileAds setUserConsent: consent];
}

#pragma mark - Helper Methods

- (void)collectBiddingDataWithRequestConfiguration:(YMABidderTokenRequestConfiguration *)requestConfiguration
                                          delegate:(id<ISBiddingDataDelegate>)delegate {
    
    if (initState != INIT_STATE_SUCCESS) {
        NSString *error = [NSString stringWithFormat:@"returning nil as token since init hasn't finished successfully"];
        LogAdapterApi_Internal(@"%@", error);
        [delegate failureWithError:error];
        return;
    }
    
    [bidderTokenLoader loadBidderTokenWithRequestConfiguration:requestConfiguration
                                             completionHandler:^(NSString *bidderToken) {
        if (bidderToken.length >= 0) {
            NSString *returnedToken = bidderToken ? bidderToken : @"";
            LogAdapterApi_Internal(@"token = %@", returnedToken);
            NSDictionary *biddingDataDictionary = [NSDictionary dictionaryWithObjectsAndKeys: returnedToken, @"token", nil];
            [delegate successWithBiddingData:biddingDataDictionary];
        } else {
            [delegate failureWithError:@"Failed to receive token - Yandex"];
        }
    }];
}

- (InitState)getInitState {
    return initState;
}

- (NSDictionary *)getConfigParams {
    NSDictionary *configParams = @{
        @"adapter_version": YandexAdapterVersion,
        @"adapter_network_name": kMediationName,
        @"adapter_network_sdk_version": [IronSource sdkVersion]
    };
    
    return configParams;
}

- (YMAMutableAdRequest *)createAdRequestWithBidResponse:(NSString *)bidResponse {
    NSDictionary *adRequestParameters = [self getConfigParams];
    YMAMutableAdRequest *adRequest = [[YMAMutableAdRequest alloc] init];
    adRequest.parameters = adRequestParameters;
    adRequest.biddingData = bidResponse;
    return adRequest;
}

- (YMAMutableAdRequestConfiguration *)createAdRequestWithBidResponse:(NSString *)bidResponse
                                                            adUnitId:(NSString *)adUnitId {
    NSDictionary *adRequestParameters = [self getConfigParams];
    YMAMutableAdRequestConfiguration *adRequest = [[YMAMutableAdRequestConfiguration alloc] initWithAdUnitID:adUnitId];
    adRequest.parameters = adRequestParameters;
    adRequest.biddingData = bidResponse;
    return adRequest;
}


@end

