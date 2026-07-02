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
@import YandexMobileAds;

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
    return [YMAYandexAds sdkVersion].stringValue;
}

+ (NSString *)networkAdapterVersion {
    return YandexAdapterVersion;
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
            bidderTokenLoader = [[YMABidderTokenLoader alloc] init];
        }
    }

    return self;
}

- (void)init:(ISAdData *)adData delegate:(id<ISNetworkInitializationDelegate>)delegate {

    NSString *appId = [adData getString:appIdKey];
    NSString *adUnitId = [adData getString:adUnitIdKey];

    // Configuration Validation
    if (!appId || appId.length == 0) {
        NSString *errorMessage = [NSString stringWithFormat:logMissingParam, appIdKey];
        LogAdapterApi_Internal(logError, errorMessage);
        [delegate onInitDidFailWithErrorCode:ERROR_CODE_INIT_FAILED errorMessage:errorMessage];
        return;
    }

    if (!adUnitId || adUnitId.length == 0) {
        NSString *errorMessage = [NSString stringWithFormat:logMissingParam, adUnitIdKey];
        LogAdapterApi_Internal(logError, errorMessage);
        [delegate onInitDidFailWithErrorCode:ERROR_CODE_INIT_FAILED errorMessage:errorMessage];
        return;
    }

    if(initState == INIT_STATE_SUCCESS) {
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

        LogAdapterApi_Internal(logAppIdAndAdUnitId, appId, adUnitId);

        if ([ISConfigurations getConfigurations].adaptersDebug) {
            [YMAYandexAds enableLogging];
        }

        // Set adapter identity before initializing SDK
        YMAAdapterIdentity *adapterIdentity = [[YMAAdapterIdentity alloc] initWithAdapterNetworkName:mediationName
                                                                                      adapterVersion:[self adapterVersion]
                                                                               adapterNetworkVersion:[LevelPlay sdkVersion]];
        [YMAYandexAds setAdapterIdentity:adapterIdentity];

        ISYandexAdapter * __weak weakSelf = self;
        [YMAYandexAds initializeSDKWithCompletionHandler:^{
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
    [YMAYandexAds setUserConsent:consent];
}

#pragma mark - Helper Methods

- (void)collectBiddingDataWithRequestConfiguration:(YMABidderTokenRequest *)requestConfiguration
                                          delegate:(id<ISBiddingDataDelegate>)delegate {

    if (initState != INIT_STATE_SUCCESS) {
        LogAdapterApi_Internal(logTokenError);
        [delegate failureWithError:logTokenError];
        return;
    }

    [bidderTokenLoader loadBidderTokenWithRequest:requestConfiguration
                                 completionHandler:^(NSString *bidderToken) {
        NSString *returnedToken = bidderToken ? bidderToken : @"";
        LogAdapterApi_Internal(logToken, returnedToken);
        NSDictionary *biddingDataDictionary = @{tokenKey: returnedToken};
        [delegate successWithBiddingData:biddingDataDictionary];
    }];
}

- (NSDictionary *)getConfigParams {
    NSDictionary *configParams = @{
        adapterVersionKey: [self adapterVersion],
        adapterNetworkNameKey: mediationName,
        adapterNetworkSDKVersionKey: [LevelPlay sdkVersion]
    };

    return configParams;
}

- (YMAAdRequest *)createAdRequestWithBidResponse:(NSString *)bidResponse
                                        adUnitId:(NSString *)adUnitId {
    NSDictionary *adRequestParameters = [self getConfigParams];
    YMAAdRequest *adRequest = [[YMAAdRequest alloc] initWithAdUnitID:adUnitId
                                                            targeting:nil
                                                              adTheme:YMAAdThemeUnspecified
                                                          biddingData:bidResponse
                                                    headerBiddingData:nil
                                                           parameters:adRequestParameters];
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
