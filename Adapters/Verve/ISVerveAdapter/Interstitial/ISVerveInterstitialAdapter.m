//
//  ISVerveInterstitialAdapter.m
//  ISVerveAdapter
//
//  Copyright © 2024 ironSource. All rights reserved.
//

#import "ISVerveInterstitialAdapter.h"
#import "ISVerveInterstitialDelegate.h"

@interface ISVerveInterstitialAdapter ()

@property (nonatomic, weak)   ISVerveAdapter *adapter;
@property (nonatomic, strong) HyBidInterstitialAd *ad;
@property (nonatomic, strong) ISVerveInterstitialDelegate *verveAdDelegate;
@property (nonatomic, weak) id<ISInterstitialAdapterDelegate> smashDelegate;

@end

@implementation ISVerveInterstitialAdapter

- (instancetype)initWithVerveAdapter:(ISVerveAdapter *)adapter {
    self = [super init];
    if (self) {
        _adapter = adapter;
        _ad = nil;
        _smashDelegate = nil;
        _verveAdDelegate = nil;
    }
    return self;
}

#pragma mark - Interstitial API

- (void)initInterstitialForBiddingWithUserId:(NSString *)userId
                               adapterConfig:(ISAdapterConfig *)adapterConfig
                                    delegate:(id<ISInterstitialAdapterDelegate>)delegate {
    NSString *appToken = [self getStringValueFromAdapterConfig:adapterConfig
                                                     forKey:kAppToken];
    
    /* Configuration Validation */
    if (![self.adapter isConfigValueValid:appToken]) {
        NSError *error = [self.adapter errorForMissingCredentialFieldWithName:kAppToken];
        LogAdapterApi_Internal(@"error = %@", error);
        [delegate adapterInterstitialInitFailedWithError:error];
        return;
    }

    NSString *zoneId = [self getStringValueFromAdapterConfig:adapterConfig
                                                        forKey:kZoneId];
    /* Configuration Validation */
    if (![self.adapter isConfigValueValid:zoneId]) {
        NSError *error = [self.adapter errorForMissingCredentialFieldWithName:kZoneId];
        LogAdapterApi_Internal(@"error = %@", error);
        [delegate adapterInterstitialInitFailedWithError:error];
        return;
    }

    self.smashDelegate = delegate;

    LogAdapterApi_Internal(@"appToken = %@, zoneId = %@", appToken, zoneId);

    switch ([self.adapter getInitState]) {
        case INIT_STATE_NONE:
        case INIT_STATE_IN_PROGRESS:
            [self.adapter initSDKWithAppToken:appToken];
            break;
        case INIT_STATE_SUCCESS:
            [delegate adapterInterstitialInitSuccess];
            break;
        case INIT_STATE_FAILED:
            LogAdapterApi_Internal(@"init failed - adUnitId = %@", zoneId);
            [delegate adapterInterstitialInitFailedWithError:[ISError createError:ERROR_CODE_INIT_FAILED
                                                                      withMessage:@"Verve SDK init failed"]];
            break;
    }
}

- (NSString *)getZoneId:(ISAdapterConfig *)adapterConfig {
    return [self getStringValueFromAdapterConfig:adapterConfig
                                          forKey:kZoneId];
}

- (void)loadInterstitialForBiddingWithAdapterConfig:(ISAdapterConfig *)adapterConfig
                                             adData:(NSDictionary *)adData
                                         serverData:(NSString *)serverData
                                           delegate:(id<ISInterstitialAdapterDelegate>)delegate {
    NSString *zoneId = [self getZoneId:adapterConfig];

    LogAdapterApi_Internal(@"zoneId = %@", zoneId);
    
    // create interstitial ad delegate
    ISVerveInterstitialDelegate *adDelegate = [[ISVerveInterstitialDelegate alloc] initWithZoneId:zoneId
                                                                andDelegate:delegate];
    self.verveAdDelegate = adDelegate;
    self.ad = [[HyBidInterstitialAd alloc] initWithDelegate:adDelegate];
    [self.ad prepareAdWithContent:serverData];
}

- (void)showInterstitialWithViewController:(UIViewController *)viewController
                             adapterConfig:(ISAdapterConfig *)adapterConfig
                                  delegate:(id<ISInterstitialAdapterDelegate>)delegate {
    NSString *zoneId = [self getZoneId:adapterConfig];
    
    LogAdapterDelegate_Internal(@"zoneId = %@", zoneId);
    
    if (![self hasInterstitialWithAdapterConfig:adapterConfig]) {
        
        NSError *error = [ISError createError:ERROR_CODE_NO_ADS_TO_SHOW
                                  withMessage:[NSString stringWithFormat: @"%@ show failed", kAdapterName]];
        LogAdapterApi_Internal(@"error = %@", error);
        [delegate adapterInterstitialDidFailToShowWithError:error];
        return;
    }
    
    dispatch_async(dispatch_get_main_queue(), ^{
        [self.ad showFromViewController: viewController];
    });
    
}

- (BOOL)hasInterstitialWithAdapterConfig:(ISAdapterConfig *)adapterConfig {
    return self.ad != nil && self.ad.isReady;
}


- (void)collectInterstitialBiddingDataWithAdapterConfig:(ISAdapterConfig *)adapterConfig
                                                 adData:(NSDictionary *)adData
                                               delegate:(id<ISBiddingDataDelegate>)delegate {
    [self.adapter collectBiddingDataWithDelegate:delegate];
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

- (void)releaseMemoryWithAdapterConfig:(ISAdapterConfig *)adapterConfig {
    NSString *zoneId = [self getStringValueFromAdapterConfig:adapterConfig
                                                        forKey:kZoneId];
    LogAdapterDelegate_Internal(@"zoneId = %@", zoneId);
    
    self.ad = nil;
    self.smashDelegate = nil;
    self.verveAdDelegate = nil;
}

@end
