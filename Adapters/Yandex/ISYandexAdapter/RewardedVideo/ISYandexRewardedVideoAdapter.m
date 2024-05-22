//
//  ISYandexRewardedVideoAdapter.m
//  IronSourceYandexAdapter
//
//  Copyright © 2024 ironSource Mobile Ltd. All rights reserved.
//

#import "ISYandexRewardedVideoAdapter.h"
#import "ISYandexRewardedVideoAdDelegate.h"

@interface ISYandexRewardedVideoAdapter ()

@property (nonatomic, weak)   ISYandexAdapter *adapter;
@property (nonatomic, strong) YMARewardedAd *ad;
@property (nonatomic, strong) YMARewardedAdLoader *adLoader;
@property (nonatomic, strong) ISYandexRewardedVideoAdDelegate *yandexAdDelegate;
@property (nonatomic, weak)   id<ISRewardedVideoAdapterDelegate> smashDelegate;

@property (nonatomic, assign) BOOL adAvailability;

@end

@implementation ISYandexRewardedVideoAdapter

- (instancetype)initWithYandexAdapter:(ISYandexAdapter *)adapter {
    self = [super init];
    if (self) {
        _adapter = adapter;
        _ad = nil;
        _adLoader = nil;
        _smashDelegate = nil;
        _yandexAdDelegate = nil;
    }
    return self;
}

#pragma mark - Rewarded Video API's

- (void)initRewardedVideoForCallbacksWithUserId:(NSString *)userId 
                                  adapterConfig:(ISAdapterConfig *)adapterConfig
                                       delegate:(id<ISRewardedVideoAdapterDelegate>)delegate {
    NSString *appId = [self getStringValueFromAdapterConfig:adapterConfig
                                                     forKey:kAppId];
    /* Configuration Validation */
    if (![self.adapter isConfigValueValid:appId]) {
        NSError *error = [self.adapter errorForMissingCredentialFieldWithName:kAppId];
        LogAdapterApi_Internal(@"error = %@", error);
        [delegate adapterRewardedVideoInitFailed:error];
        return;
    }
    
    NSString *adUnitId = [self getStringValueFromAdapterConfig:adapterConfig
                                                        forKey:kAdUnitId];
    /* Configuration Validation */
    if (![self.adapter isConfigValueValid:adUnitId]) {
        NSError *error = [self.adapter errorForMissingCredentialFieldWithName:kAdUnitId];
        LogAdapterApi_Internal(@"error = %@", error);
        [delegate adapterRewardedVideoInitFailed:error];
        return;
    }
    
    self.smashDelegate = delegate;
    
    LogAdapterApi_Internal(@"appId = %@, adUnitId = %@", appId, adUnitId);
    
    switch ([self.adapter getInitState]) {
        case INIT_STATE_NONE:
        case INIT_STATE_IN_PROGRESS:
            [self.adapter initSDKWithAppId:appId];
            break;
        case INIT_STATE_SUCCESS:
            [delegate adapterRewardedVideoInitSuccess];
            break;
    }
}

- (void)loadRewardedVideoForBiddingWithAdapterConfig:(ISAdapterConfig *)adapterConfig 
                                              adData:(NSDictionary *)adData
                                          serverData:(NSString *)serverData
                                            delegate:(id<ISRewardedVideoAdapterDelegate>)delegate {
    NSString *adUnitId = [self getStringValueFromAdapterConfig:adapterConfig
                                                        forKey:kAdUnitId];

    LogAdapterApi_Internal(@"adUnitId = %@", adUnitId);

    self.adAvailability = NO;
    
    // create banner ad delegate
    ISYandexRewardedVideoAdDelegate *adDelegate = [[ISYandexRewardedVideoAdDelegate alloc] initWithAdapter:self
                                                                                                  adUnitId:adUnitId
                                                                                               andDelegate:delegate];
    self.yandexAdDelegate = adDelegate;
    
    // create adLoader
    YMARewardedAdLoader *adLoader = [[YMARewardedAdLoader alloc] init];
    adLoader.delegate = adDelegate;
    
    // save interstitial ad to local variable
    self.adLoader = adLoader;

    // get ad request parameters
    YMAAdRequestConfiguration *adRequest = [self.adapter createAdRequestWithBidResponse:serverData
                                                                               adUnitId:adUnitId];
    
    dispatch_async(dispatch_get_main_queue(), ^{
        // load ad
        [self.adLoader loadAdWithRequestConfiguration:adRequest];
    });

}

- (void)showRewardedVideoWithViewController:(UIViewController *)viewController 
                              adapterConfig:(ISAdapterConfig *)adapterConfig
                                   delegate:(id<ISRewardedVideoAdapterDelegate>)delegate {
    NSString *adUnitId = [self getStringValueFromAdapterConfig:adapterConfig
                                                        forKey:kAdUnitId];

    LogAdapterDelegate_Internal(@"adUnitId = %@", adUnitId);

    if (![self hasRewardedVideoWithAdapterConfig:adapterConfig]) {
        self.adAvailability = NO;

        NSError *error = [ISError createError:ERROR_CODE_NO_ADS_TO_SHOW
                                  withMessage:[NSString stringWithFormat: @"%@ show failed", kAdapterName]];
        LogAdapterApi_Internal(@"error = %@", error);
        [delegate adapterRewardedVideoDidFailToShowWithError:error];
        return;
    }
    
    dispatch_async(dispatch_get_main_queue(), ^{
        // load ad
        [self.ad showFromViewController:viewController];
    });
}

- (BOOL)hasRewardedVideoWithAdapterConfig:(ISAdapterConfig *)adapterConfig {
    return self.ad != nil && self.adAvailability;
}

- (void)collectRewardedVideoBiddingDataWithAdapterConfig:(ISAdapterConfig *)adapterConfig 
                                                  adData:(NSDictionary *)adData
                                                delegate:(id<ISBiddingDataDelegate>)delegate {
    YMABidderTokenRequestConfiguration *requestConfiguration = [[YMABidderTokenRequestConfiguration alloc] initWithAdType:YMAAdTypeRewarded];

    requestConfiguration.parameters = [self.adapter getConfigParams];
    
    [self.adapter collectBiddingDataWithRequestConfiguration:requestConfiguration
                                                    delegate:delegate];
}

#pragma mark - Init Delegate

- (void)onNetworkInitCallbackSuccess {
    [self.smashDelegate adapterRewardedVideoInitSuccess];
}

#pragma mark - Memory Handling

- (void)releaseMemoryWithAdapterConfig:(ISAdapterConfig *)adapterConfig {
    NSString *adUnitId = [self getStringValueFromAdapterConfig:adapterConfig
                                                        forKey:kAdUnitId];
    LogAdapterDelegate_Internal(@"adUnitId = %@", adUnitId);
    
    self.ad.delegate = nil;
    dispatch_async(dispatch_get_main_queue(), ^{
        self.ad = nil;
    });
    self.adLoader.delegate = nil;
    self.adLoader = nil;
    self.smashDelegate = nil;
    self.yandexAdDelegate = nil;
}

#pragma mark - Helper Methods

- (void)onAdUnitAvailabilityChangeWithAdUnitId:(NSString *)adUnitId
                                  availability:(BOOL)availability
                               rewardedVideoAd:(YMARewardedAd *)rewardedVideoAd {
    self.ad = rewardedVideoAd;
    self.ad.delegate = self.yandexAdDelegate;
    self.adAvailability = availability;
}

@end
