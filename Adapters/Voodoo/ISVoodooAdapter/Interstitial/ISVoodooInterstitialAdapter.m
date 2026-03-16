//
//  ISVoodooInterstitialAdapter.m
//  ISVoodooAdapter
//
//  Copyright © 2021-2025 Unity Technologies. All rights reserved.
//

#import "ISVoodooInterstitialAdapter.h"
#import "ISVoodooInterstitialDelegate.h"

@interface ISVoodooInterstitialAdapter ()

@property (nonatomic, weak)   ISVoodooAdapter                   *adapter;
@property (nonatomic, strong) ISVoodooInterstitialDelegate      *adDelegate;
@property (nonatomic, weak)   id<ISInterstitialAdapterDelegate> smashDelegate;
@property (nonatomic, strong) AdnFullscreenAdController         *ad;

@end

@implementation ISVoodooInterstitialAdapter

- (instancetype)initWithVoodooAdapter:(ISVoodooAdapter *)adapter {
    self = [super init];
    if (self) {
        _adapter = adapter;
        _adDelegate = nil;
        _smashDelegate = nil;
        _ad = nil;
    }
    return self;
}

#pragma mark - Interstitial API

- (void)initInterstitialForBiddingWithUserId:(NSString *)userId
                               adapterConfig:(ISAdapterConfig *)adapterConfig
                                    delegate:(id<ISInterstitialAdapterDelegate>)delegate {
    NSString *placementId = adapterConfig.settings[kPlacementId];

    // Configuration Validation
    if (![self.adapter isConfigValueValid:placementId]) {
        NSError *error = [self.adapter errorForMissingCredentialFieldWithName:kPlacementId];
        LogAdapterApi_Internal(@"error = %@", error.description);
        [delegate adapterInterstitialInitFailedWithError:error];
        return;
    }

    LogAdapterApi_Internal(@"placementId = %@", placementId);

    self.smashDelegate = delegate;

    switch ([self.adapter getInitState]) {
        case INIT_STATE_NONE:
        case INIT_STATE_IN_PROGRESS:
            [self.adapter initSDKWithConfig:adapterConfig];
            break;
        case INIT_STATE_SUCCESS:
            [delegate adapterInterstitialInitSuccess];
            break;
        case INIT_STATE_FAILED: {
            LogAdapterApi_Internal(@"init failed - placementId = %@", placementId);
            NSError *error = [ISError createError:ERROR_CODE_INIT_FAILED
                                      withMessage:@"Voodoo SDK init failed"];
            [delegate adapterInterstitialInitFailedWithError:error];
            break;
        }
    }
}

- (void)loadInterstitialForBiddingWithAdapterConfig:(ISAdapterConfig *)adapterConfig
                                             adData:(NSDictionary *)adData
                                         serverData:(NSString *)serverData
                                           delegate:(id<ISInterstitialAdapterDelegate>)delegate {
    NSString *placementId = adapterConfig.settings[kPlacementId];
    LogAdapterApi_Internal(@"placementId = %@", placementId);

    self.adDelegate = [[ISVoodooInterstitialDelegate alloc] initWithPlacementId:placementId
                                                                                             andDelegate:delegate];
    
    self.ad = [[AdnFullscreenAdController alloc] init];
    self.ad.fullscreenAdDelegate = self.adDelegate;
    AdnFullscreenAdOptions *options = [[AdnFullscreenAdOptions alloc] initWithPlacement:AdnPlacementTypeInterstitial
                                                                               adMarkup:serverData];
    
    [self.ad loadAdWithOptions:options
                           completion:^(NSError * _Nullable error) {
        [self.adDelegate handleOnLoad:error];
    }];
}

- (void)showInterstitialWithViewController:(UIViewController *)viewController
                             adapterConfig:(ISAdapterConfig *)adapterConfig
                                  delegate:(id<ISInterstitialAdapterDelegate>)delegate {
    NSString *placementId = adapterConfig.settings[kPlacementId];
    LogAdapterApi_Internal(@"placementId = %@", placementId);

    if (![self hasInterstitialWithAdapterConfig:adapterConfig]) {
        NSError *error = [ISError createError:ERROR_CODE_NO_ADS_TO_SHOW
                                  withMessage:[NSString stringWithFormat: @"%@ show failed", kAdapterName]];
        LogAdapterApi_Internal(@"error = %@", error);
        [delegate adapterInterstitialDidFailToShowWithError:error];
        return;
    }

    [self.ad presentAdFrom:viewController];
}

- (BOOL)hasInterstitialWithAdapterConfig:(ISAdapterConfig *)adapterConfig {
    return self.ad != nil && [self.ad canShow];
}

- (void)collectInterstitialBiddingDataWithAdapterConfig:(ISAdapterConfig *)adapterConfig
                                                 adData:(NSDictionary *)adData
                                               delegate:(id<ISBiddingDataDelegate>)delegate {
    [self.adapter collectBiddingDataWithDelegate:delegate
                                   placementType:AdnPlacementTypeInterstitial
                                   adapterConfig:adapterConfig];
}

#pragma mark - Init Delegate

- (void)onNetworkInitCallbackSuccess {
    [self.smashDelegate adapterInterstitialInitSuccess];
}

- (void)onNetworkInitCallbackFailed:(NSString *)errorMessage {
    NSError *error = [ISError createErrorWithDomain:kAdapterName
                                               code:ERROR_CODE_INIT_FAILED
                                            message:errorMessage];
    [self.smashDelegate adapterInterstitialInitFailedWithError:error];
}

#pragma mark - Memory Handling

- (void)destroyInterstitialAdWithAdapterConfig:(ISAdapterConfig *)adapterConfig {
    NSString *placementId = adapterConfig.settings[kPlacementId];
    LogAdapterApi_Internal(@"placementId = %@", placementId);
    [self.ad cleanUp];
    self.ad.fullscreenAdDelegate = nil;
    self.ad = nil;
    self.smashDelegate = nil;
    self.adDelegate = nil;
}

@end
