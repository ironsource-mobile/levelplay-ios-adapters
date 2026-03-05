//
//  ISYandexAdapter.m
//  ISYandexAdapter
//
//  Copyright © 2021-2025 Unity Technologies. All rights reserved.
//

#import "ISYandexAdapter.h"
#import "ISYandexConstants.h"
#import "ISYandexRewardedAdapter.h"
#import "ISYandexInterstitialAdapter.h"
#import "ISYandexBannerAdapter.h"
#import <YandexMobileAds/YandexMobileAds.h>

// Handle init callback for all adapter instances
static InitState initState = INIT_STATE_NONE;
static ISConcurrentMutableSet<ISNetworkInitializationDelegate> *initCallbackDelegates = nil;
static YMABidderTokenLoader *bidderTokenLoader = nil;

@interface ISYandexAdapter()

@end

@implementation ISYandexAdapter

#pragma mark - LevelPlay Protocol Methods

- (NSString *)adapterVersion {
    return YandexAdapterVersion;
}

- (NSString *)networkSDKVersion {
    return [YMAMobileAds sdkVersion];
}

#pragma mark - Initialization Methods And Callbacks

- (instancetype)init {
    self = [super init];

    if (self) {
        if (initCallbackDelegates == nil) {
            initCallbackDelegates = [ISConcurrentMutableSet<ISNetworkInitializationDelegate> set];
        }

        // The Yandex token loader object needs to be saved so that we can retrieve
        // the completion handler callback for async token handling.
        if (bidderTokenLoader == nil) {
            bidderTokenLoader = [[YMABidderTokenLoader alloc] initWithMediationNetworkName:mediationName];
        }
    }

    return self;
}

- (void)init:(ISAdData *)adData delegate:(id<ISNetworkInitializationDelegate>)delegate {

    if(initState == INIT_STATE_SUCCESS && delegate) {
        [delegate onInitDidSucceed];
        return;
    }

    // Add delegate to the init delegates only in case the initialization has not finished yet
    if ((initState == INIT_STATE_NONE || initState == INIT_STATE_IN_PROGRESS) && delegate) {
        [initCallbackDelegates addObject:delegate];
    }

    static dispatch_once_t initSdkOnceToken;
    dispatch_once(&initSdkOnceToken, ^{
        initState = INIT_STATE_IN_PROGRESS;

        NSString *appId = [adData getString:appIdKey];
        LogAdapterApi_Internal(logAppId, appId);

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
    LogAdapterDelegate_Internal(logCallbackEmpty);

    initState = INIT_STATE_SUCCESS;

    NSArray *initDelegatesList = initCallbackDelegates.allObjects;

    for (id<ISNetworkInitializationDelegate> initDelegate in initDelegatesList) {
        [initDelegate onInitDidSucceed];
    }

    [initCallbackDelegates removeAllObjects];
}

#pragma mark - Legal Methods

- (void)setConsent:(BOOL)consent {
    LogAdapterApi_Internal(logConsent, consent ? @"YES" : @"NO");
    [YMAMobileAds setUserConsent:consent];
}

#pragma mark - Helper Methods

- (void)collectBiddingDataWithRequestConfiguration:(YMABidderTokenRequestConfiguration *)requestConfiguration
                                          delegate:(id<ISBiddingDataDelegate>)delegate {

    if (initState != INIT_STATE_SUCCESS) {
        LogAdapterApi_Internal(logTokenError);
        [delegate failureWithError:logTokenError];
        return;
    }

    [bidderTokenLoader loadBidderTokenWithRequestConfiguration:requestConfiguration
                                             completionHandler:^(NSString *bidderToken) {
        NSString *returnedToken = bidderToken ? bidderToken : @"";
        LogAdapterApi_Internal(logToken, returnedToken);
        NSDictionary *biddingDataDictionary = @{tokenKey: returnedToken};
        [delegate successWithBiddingData:biddingDataDictionary];
    }];
}

- (NSDictionary *)getConfigParams {
    NSDictionary *configParams = @{
        adapterVersionKey: YandexAdapterVersion,
        adapterNetworkNameKey: mediationName,
        adapterNetworkSDKVersionKey: [LevelPlay sdkVersion]
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

+ (NSString *)buildCreativeIdStringFromCreatives:(NSArray<YMACreative *> *)creatives {
    if (!creatives) {
        return @"";
    }

    NSMutableArray<NSString *> *creativeIds = [NSMutableArray array];

    for (YMACreative *creative in creatives) {
        NSString *creativeId = creative.creativeID;
        if (creativeId.length > 0) {
            [creativeIds addObject:creativeId];
        }
    }

    return [creativeIds componentsJoinedByString:@","];
}

@end
