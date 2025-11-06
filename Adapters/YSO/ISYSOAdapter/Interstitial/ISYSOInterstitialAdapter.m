//
//  ISYSOInterstitialAdapter.m
//  ISYSOAdapter
//
//  Copyright © 2021-2025 Unity Technologies. All rights reserved.
//

#import "ISYSOInterstitialAdapter.h"
#import "ISYSOInterstitialAdDelegate.h"

@interface ISYSOInterstitialAdapter ()

@property (nonatomic, weak)   ISYSOAdapter *adapter;
@property (nonatomic, strong) ISYSOInterstitialAdDelegate *adDelegate;
@property (nonatomic, weak)   id<ISInterstitialAdapterDelegate> smashDelegate;

@end

@implementation ISYSOInterstitialAdapter

- (instancetype)initWithYSOAdapter:(ISYSOAdapter *)adapter {
    self = [super init];
    if (self) {
        _adapter = adapter;
        _adDelegate = nil;
        _smashDelegate = nil;
    }
    return self;
}

#pragma mark - Interstitial API

- (void)initInterstitialForBiddingWithUserId:(NSString *)userId
                               adapterConfig:(ISAdapterConfig *)adapterConfig
                                    delegate:(id<ISInterstitialAdapterDelegate>)delegate {
    
    NSString *placementKey = [self getStringValueFromAdapterConfig:adapterConfig
                                                     forKey:kPlacementKey];

    /* Configuration Validation */
    if (![self.adapter isConfigValueValid:placementKey]) {
        NSError *error = [self.adapter errorForMissingCredentialFieldWithName:kPlacementKey];
        LogAdapterApi_Internal(@"error = %@", error);
        [delegate adapterInterstitialInitFailedWithError:error];
        return;
    }
    
    LogAdapterApi_Internal(@"placementKey = %@", placementKey);
    
    self.smashDelegate = delegate;
    
    switch ([self.adapter getInitState]) {
        case INIT_STATE_NONE:
        case INIT_STATE_IN_PROGRESS:
            [self.adapter initSDKWithPlacementKey:placementKey];
            break;
        case INIT_STATE_SUCCESS:
            [delegate adapterInterstitialInitSuccess];
            break;
        case INIT_STATE_FAILED:
            LogAdapterApi_Internal(@"init failed - placementKey = %@", placementKey);
            [delegate adapterInterstitialInitFailedWithError:[ISError createError:ERROR_CODE_INIT_FAILED
                                                              withMessage:@"YSO SDK init failed"]];
            break;
    }
}

- (void)loadInterstitialForBiddingWithAdapterConfig:(ISAdapterConfig *)adapterConfig 
                                             adData:(NSDictionary *)adData
                                         serverData:(NSString *)serverData
                                           delegate:(id<ISInterstitialAdapterDelegate>)delegate {
    NSString *placementKey = [self getStringValueFromAdapterConfig:adapterConfig
                                                           forKey:kPlacementKey];

    LogAdapterApi_Internal(@"placementKey = %@", placementKey);
    
    // create interstitial ad delegate
    ISYSOInterstitialAdDelegate *adDelegate = [[ISYSOInterstitialAdDelegate alloc] initWithPlacementKey:placementKey
                                                                                               adapter:self.adapter
                                                                                           andDelegate:delegate];
    self.adDelegate = adDelegate;
    
    // load ad
    [YsoNetwork interstitialLoadWithKey:placementKey
                                   json:serverData
                                 onLoad:^(e_ActionError error) {
        [self.adDelegate handleOnLoad:error];
    }];
}

- (void)showInterstitialWithViewController:(UIViewController *)viewController
                             adapterConfig:(ISAdapterConfig *)adapterConfig
                                  delegate:(id<ISInterstitialAdapterDelegate>)delegate {
    NSString *placementKey = [self getStringValueFromAdapterConfig:adapterConfig
                                                     forKey:kPlacementKey];

    LogAdapterApi_Internal(@"placementKey = %@", placementKey);

    if (![self hasInterstitialWithAdapterConfig:adapterConfig]) {
        NSError *error = [ISError createError:ERROR_CODE_NO_ADS_TO_SHOW
                                  withMessage:[NSString stringWithFormat: @"%@ show failed", kAdapterName]];
        LogAdapterApi_Internal(@"error = %@", error);
        [delegate adapterInterstitialDidFailToShowWithError:error];
        return;
    }
    
    dispatch_async(dispatch_get_main_queue(), ^{
        [YsoNetwork interstitialShowWithKey:placementKey
                             viewController:viewController
                                  onDisplay:^(YNWebView * _Nullable view) {
            [self.adDelegate handleOnDisplay:view];
        }
                                    onClick:^{
            [self.adDelegate handleOnClick];
        }
                                    onClose:^(BOOL display, BOOL complete) {
            [self.adDelegate handleOnClose:display complete:complete];
        }];
    });
}

- (BOOL)hasInterstitialWithAdapterConfig:(ISAdapterConfig *)adapterConfig {
    NSString *placementKey = [self getStringValueFromAdapterConfig:adapterConfig
                                                     forKey:kPlacementKey];
    return [YsoNetwork interstitialIsReadyWithKey:placementKey];
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

- (void)destroyInterstitialAdWithAdapterConfig:(ISAdapterConfig *)adapterConfig {
    NSString *placementKey = [self getStringValueFromAdapterConfig:adapterConfig
                                                            forKey:kPlacementKey];
    LogAdapterApi_Internal(@"placementKey = %@", placementKey);
    self.adDelegate = nil;
    self.smashDelegate = nil;
}

@end
