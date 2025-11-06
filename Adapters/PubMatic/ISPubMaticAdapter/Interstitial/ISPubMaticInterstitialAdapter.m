//
//  ISPubMaticInterstitialAdapter.m
//  ISPubMaticAdapter
//
//  Copyright © 2021-2025 Unity Technologies. All rights reserved.
//

#import "ISPubMaticInterstitialAdapter.h"
#import "ISPubMaticInterstitialDelegate.h"

@interface ISPubMaticInterstitialAdapter ()

@property (nonatomic, weak)   ISPubMaticAdapter                 *adapter;
@property (nonatomic, strong) POBInterstitial                   *ad;
@property (nonatomic, strong) ISPubMaticInterstitialDelegate    *adDelegate;
@property (nonatomic, weak)   id<ISInterstitialAdapterDelegate> smashDelegate;

@end

@implementation ISPubMaticInterstitialAdapter

- (instancetype)initWithPubMaticAdapter:(ISPubMaticAdapter *)adapter {
    self = [super init];
    if (self) {
        _adapter = adapter;
        _ad = nil;
        _smashDelegate = nil;
        _adDelegate = nil;
    }
    return self;
}

#pragma mark - Interstitial API

- (void)initInterstitialForBiddingWithUserId:(NSString *)userId
                               adapterConfig:(ISAdapterConfig *)adapterConfig
                                    delegate:(id<ISInterstitialAdapterDelegate>)delegate {
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

    LogAdapterApi_Internal(@"adUnitId = %@", adUnitId);

    switch ([self.adapter getInitState]) {
        case INIT_STATE_NONE:
        case INIT_STATE_IN_PROGRESS:
            [self.adapter initSDKWithConfig:adapterConfig];
            break;
        case INIT_STATE_SUCCESS:
            [delegate adapterInterstitialInitSuccess];
            break;
        case INIT_STATE_FAILED:
            LogAdapterApi_Internal(@"init failed - adUnitId = %@", adUnitId);
            [delegate adapterInterstitialInitFailedWithError:[ISError createError:ERROR_CODE_INIT_FAILED
                                                                      withMessage:@"PubMatic SDK init failed"]];
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
    
    // create interstitial ad delegate
    ISPubMaticInterstitialDelegate *adDelegate = [[ISPubMaticInterstitialDelegate alloc] initWithAdUnitId:adUnitId
                                                                                                   andDelegate:delegate];
    self.adDelegate = adDelegate;
    self.ad = [[POBInterstitial alloc] init];
    self.ad.delegate = self.adDelegate;

    // load ad
    [self.ad loadAdWithResponse:serverData forBiddingHost:POBSDKBiddingHostUnityLevelPlay];
}

- (void)showInterstitialWithViewController:(UIViewController *)viewController
                             adapterConfig:(ISAdapterConfig *)adapterConfig
                                  delegate:(id<ISInterstitialAdapterDelegate>)delegate {
    NSString *adUnitId = [self getStringValueFromAdapterConfig:adapterConfig
                                                        forKey:kAdUnitId];
    
    LogAdapterApi_Internal(@"adUnitId = %@", adUnitId);
    
    if (![self hasInterstitialWithAdapterConfig:adapterConfig]) {
        NSError *error = [ISError createError:ERROR_CODE_NO_ADS_TO_SHOW
                                  withMessage:[NSString stringWithFormat: @"%@ show failed", kAdapterName]];
        LogAdapterApi_Internal(@"error = %@", error);
        [delegate adapterInterstitialDidFailToShowWithError:error];
        return;
    }
    // show ad
    [self.ad showFromViewController:viewController];
}

- (BOOL)hasInterstitialWithAdapterConfig:(ISAdapterConfig *)adapterConfig {
    return [self.ad isReady];
}

- (void)collectInterstitialBiddingDataWithAdapterConfig:(ISAdapterConfig *)adapterConfig
                                                 adData:(NSDictionary *)adData
                                               delegate:(id<ISBiddingDataDelegate>)delegate {
    dispatch_async(dispatch_get_main_queue(), ^{
        [self.adapter collectBiddingDataWithDelegate:delegate
                                            adFormat:POBAdFormatInterstitial
                                       adapterConfig:adapterConfig];
    });
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
    NSString *adUnitId = [self getStringValueFromAdapterConfig:adapterConfig
                                                        forKey:kAdUnitId];
    LogAdapterApi_Internal(@"adUnitId = %@", adUnitId);
    self.ad.delegate = nil;
    self.ad = nil;
    self.smashDelegate = nil;
    self.adDelegate = nil;
}

@end
