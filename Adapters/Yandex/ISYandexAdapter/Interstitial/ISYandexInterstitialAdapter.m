//
//  ISYandexInterstitialAdapter.m
//  IronSourceYandexAdapter
//
//  Copyright © 2024 ironSource Mobile Ltd. All rights reserved.
//

#import "ISYandexInterstitialAdapter.h"
#import "ISYandexInterstitialAdDelegate.h"

@interface ISYandexInterstitialAdapter ()

@property (nonatomic, weak)   ISYandexAdapter *adapter;
@property (nonatomic, strong) YMAInterstitialAd *ad;
@property (nonatomic, strong) YMAInterstitialAdLoader *adLoader;
@property (nonatomic, strong) ISYandexInterstitialAdDelegate *yandexAdDelegate;
@property (nonatomic, weak)   id<ISInterstitialAdapterDelegate> smashDelegate;

@property (nonatomic, assign) BOOL adAvailability;

@end

@implementation ISYandexInterstitialAdapter

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

#pragma mark - Interstitial API's

- (void)initInterstitialForBiddingWithUserId:(NSString *)userId
                               adapterConfig:(ISAdapterConfig *)adapterConfig
                                    delegate:(id<ISInterstitialAdapterDelegate>)delegate {
    NSString *appId = [self getStringValueFromAdapterConfig:adapterConfig
                                                     forKey:kAppId];
    /* Configuration Validation */
    if (![self.adapter isConfigValueValid:appId]) {
        NSError *error = [self.adapter errorForMissingCredentialFieldWithName:kAppId];
        LogAdapterApi_Internal(@"error = %@", error);
        [delegate adapterInterstitialInitFailedWithError:error];
        return;
    }
    
    NSString *adUnitId = [self getStringValueFromAdapterConfig:adapterConfig
                                                        forKey:kAdUnitId];
    /* Configuration Validation */
    if (![self.adapter isConfigValueValid:adUnitId]) {
        NSError *error = [self.adapter errorForMissingCredentialFieldWithName:kAdUnitId];
        LogAdapterApi_Internal(@"error = %@", error);
        [delegate adapterInterstitialInitFailedWithError:error];
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
            [delegate adapterInterstitialInitSuccess];
            break;
    }
}

- (void)loadInterstitialForBiddingWithAdapterConfig:(ISAdapterConfig *)adapterConfig 
                                             adData:(NSDictionary *)adData
                                         serverData:(NSString *)serverData
                                           delegate:(id<ISInterstitialAdapterDelegate>)delegate {
    NSString *adUnitId = [self getStringValueFromAdapterConfig:adapterConfig
                                                        forKey:kAdUnitId];

    LogAdapterApi_Internal(@"adUnitId = %@", adUnitId);

    self.adAvailability = NO;
    
    // create banner ad delegate
    ISYandexInterstitialAdDelegate *adDelegate = [[ISYandexInterstitialAdDelegate alloc] initWithAdapter:self
                                                                                                adUnitId:adUnitId
                                                                                             andDelegate:delegate];
    self.yandexAdDelegate = adDelegate;
    
    // create adLoader
    YMAInterstitialAdLoader *adLoader = [[YMAInterstitialAdLoader alloc] init];
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

- (void)showInterstitialWithViewController:(UIViewController *)viewController 
                             adapterConfig:(ISAdapterConfig *)adapterConfig
                                  delegate:(id<ISInterstitialAdapterDelegate>)delegate {
    NSString *adUnitId = [self getStringValueFromAdapterConfig:adapterConfig
                                                        forKey:kAdUnitId];
    
    LogAdapterDelegate_Internal(@"adUnitId = %@", adUnitId);

    if (![self hasInterstitialWithAdapterConfig:adapterConfig]) {
        self.adAvailability = NO;

        NSError *error = [ISError createError:ERROR_CODE_NO_ADS_TO_SHOW
                                  withMessage:[NSString stringWithFormat: @"%@ show failed", kAdapterName]];
        LogAdapterApi_Internal(@"error = %@", error);
        [delegate adapterInterstitialDidFailToShowWithError:error];
        return;
    }
    
    
    dispatch_async(dispatch_get_main_queue(), ^{
        // load ad
        [self.ad showFromViewController:viewController];
    });
}

- (BOOL)hasInterstitialWithAdapterConfig:(ISAdapterConfig *)adapterConfig {
    return self.ad != nil && self.adAvailability;
}

- (void)collectInterstitialBiddingDataWithAdapterConfig:(ISAdapterConfig *)adapterConfig 
                                                 adData:(NSDictionary *)adData
                                               delegate:(id<ISBiddingDataDelegate>)delegate {
    YMABidderTokenRequestConfiguration *requestConfiguration = [[YMABidderTokenRequestConfiguration alloc] initWithAdType:YMAAdTypeInterstitial];

    requestConfiguration.parameters = [self.adapter getConfigParams];

    [self.adapter collectBiddingDataWithRequestConfiguration:requestConfiguration
                                                    delegate:delegate];
}

#pragma mark - Init Delegate

- (void)onNetworkInitCallbackSuccess {
    [self.smashDelegate adapterInterstitialInitSuccess];
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
                                interstitialAd:(YMAInterstitialAd *)interstitialAd {
    self.ad = interstitialAd;
    self.ad.delegate = self.yandexAdDelegate;
    self.adAvailability = availability;
}

@end
