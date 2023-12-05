//
//  ISAdMobInterstitialAdapter.m
//  ISAdMobAdapter
//
//  Copyright © 2023 ironSource. All rights reserved.
//

#import "ISAdMobInterstitialAdapter.h"
#import "ISAdMobInterstitialDelegate.h"

@interface ISAdMobInterstitialAdapter ()

@property (nonatomic, weak) ISAdMobAdapter *adapter;

@property (nonatomic, strong) ISConcurrentMutableDictionary *adUnitIdToAds;
@property (nonatomic, strong) ISConcurrentMutableDictionary *adUnitIdToSmashDelegate;
@property (nonatomic, strong) ISConcurrentMutableDictionary *adUnitIdToAdsAvailability;
@property (nonatomic, strong) ISConcurrentMutableDictionary *adUnitIdToAdDelegate;

@end

@implementation ISAdMobInterstitialAdapter

- (instancetype)initWithAdMobAdapter:(ISAdMobAdapter *)adapter {
    self = [super init];
    if (self) {
        _adapter                                = adapter;
        _adUnitIdToAds                          = [ISConcurrentMutableDictionary dictionary];
        _adUnitIdToSmashDelegate                = [ISConcurrentMutableDictionary dictionary];
        _adUnitIdToAdsAvailability              = [ISConcurrentMutableDictionary dictionary];
        _adUnitIdToAdDelegate                   = [ISConcurrentMutableDictionary dictionary];
    }
    return self;
}

#pragma mark - Interstitial API

- (void)initInterstitialForBiddingWithUserId:(NSString *)userId
                               adapterConfig:(ISAdapterConfig *)adapterConfig
                                    delegate:(id<ISInterstitialAdapterDelegate>)delegate {
    [self initInterstitialWithUserId:userId
                       adapterConfig:adapterConfig
                            delegate:delegate];
}

- (void)initInterstitialWithUserId:(NSString *)userId
                     adapterConfig:(ISAdapterConfig *)adapterConfig
                          delegate:(id<ISInterstitialAdapterDelegate>)delegate {
    dispatch_async(dispatch_get_main_queue(), ^{
        
        NSString *adUnitId = adapterConfig.settings[kAdUnitId];
        
        
        /* Configuration Validation */
        if (![self.adapter isConfigValueValid:adUnitId]) {
            NSError *error = [self.adapter errorForMissingCredentialFieldWithName:kAdUnitId];
            LogAdapterApi_Internal(@"error = %@", error);
            [delegate adapterInterstitialInitFailedWithError:error];
            return;
        }
        
        LogAdapterApi_Internal(@"adUnitId = %@", adUnitId);
        
        [self.adUnitIdToSmashDelegate setObject:delegate
                                         forKey:adUnitId];
        
        switch ([self.adapter getInitState]) {
            case INIT_STATE_NONE:
            case INIT_STATE_IN_PROGRESS:
                [self.adapter initAdMobSDKWithAdapterConfig:adapterConfig];
                break;
            case INIT_STATE_FAILED: {
                LogAdapterApi_Internal(@"init failed - adUnitId = %@", adUnitId);
                [delegate adapterInterstitialInitFailedWithError:[ISError createError:ERROR_CODE_INIT_FAILED
                                                                          withMessage:@"AdMob SDK init failed"]];
                break;
            }
            case INIT_STATE_SUCCESS:
                [delegate adapterInterstitialInitSuccess];
                break;
        }
    });
}

- (void)loadInterstitialForBiddingWithAdapterConfig:(ISAdapterConfig *)adapterConfig
                                             adData:(NSDictionary *)adData
                                         serverData:(NSString *)serverData
                                           delegate:(id<ISInterstitialAdapterDelegate>)delegate {
    LogAdapterApi_Internal(@"");
    
    [self loadInterstitialInternal:adapterConfig
                            adData:adData
                        serverData:serverData
                          delegate:delegate];
}

- (void)loadInterstitialWithAdapterConfig:(ISAdapterConfig *)adapterConfig
                                   adData:(NSDictionary *)adData
                                 delegate:(id<ISInterstitialAdapterDelegate>)delegate {
    LogAdapterApi_Internal(@"");
    
    [self loadInterstitialInternal:adapterConfig
                            adData:adData
                        serverData:nil
                          delegate:delegate];
}

- (void)loadInterstitialInternal:(ISAdapterConfig *)adapterConfig
                          adData:(NSDictionary *)adData
                      serverData:(NSString *)serverData
                        delegate:(id<ISInterstitialAdapterDelegate>)delegate {
    dispatch_async(dispatch_get_main_queue(), ^{
        
        NSString *adUnitId = adapterConfig.settings[kAdUnitId];
        
        [self.adUnitIdToAdsAvailability setObject:@NO
                                           forKey:adUnitId];

        [self.adUnitIdToSmashDelegate setObject:delegate
                                         forKey:adUnitId];
        
        GADRequest *request = [self.adapter createGADRequestForLoadWithAdData:adData
                                                                   serverData:serverData];
        
        ISAdMobInterstitialDelegate *interstitialAdDelegate = [[ISAdMobInterstitialDelegate alloc] initWithAdapter:self
                                                                                                          adUnitId:adUnitId
                                                                                                       andDelegate:delegate];
        [self.adUnitIdToAdDelegate setObject:interstitialAdDelegate
                                      forKey:adUnitId];
        
        [GADInterstitialAd loadWithAdUnitID:adUnitId
                                    request:request
                          completionHandler:[interstitialAdDelegate completionBlock]];
    });
}

- (void)showInterstitialWithViewController:(UIViewController *)viewController
                             adapterConfig:(ISAdapterConfig *)adapterConfig
                                  delegate:(id<ISInterstitialAdapterDelegate>)delegate {
    dispatch_async(dispatch_get_main_queue(), ^{
        NSString *adUnitId = adapterConfig.settings[kAdUnitId];
        LogAdapterApi_Internal(@"adUnitId = %@", adUnitId);
        
        GADInterstitialAd *interstitialAd = [self.adUnitIdToAds objectForKey:adUnitId];
        
        ISAdMobInterstitialDelegate *interstitialAdDelegate = [self.adUnitIdToAdDelegate objectForKey:adUnitId];
        
        interstitialAd.fullScreenContentDelegate = interstitialAdDelegate;
        
        // Show the ad if it's ready.
        if (interstitialAd != nil && [self hasInterstitialWithAdapterConfig:adapterConfig]) {
            [interstitialAd presentFromRootViewController:viewController];
        } else {
            NSError *error = [ISError createError:ERROR_CODE_NO_ADS_TO_SHOW
                                      withMessage:[NSString stringWithFormat: @"%@ show failed", kAdapterName]];
            LogAdapterApi_Internal(@"error = %@", error);
            [delegate adapterInterstitialDidFailToShowWithError:error];
            
        }
        
        //change interstitial availability to false
        [self.adUnitIdToAdsAvailability setObject:@NO
                                           forKey:adUnitId];
    });
}

- (BOOL)hasInterstitialWithAdapterConfig:(ISAdapterConfig *)adapterConfig {
    NSString *adUnitId = adapterConfig.settings[kAdUnitId];
    NSNumber *available = [self.adUnitIdToAdsAvailability objectForKey:adUnitId];
    return [available boolValue];
}

- (void)collectInterstitialBiddingDataWithAdapterConfig:(ISAdapterConfig *)adapterConfig
                                                 adData:(NSDictionary *)adData
                                               delegate:(id<ISBiddingDataDelegate>)delegate {
    dispatch_async(dispatch_get_main_queue(), ^{
        GADRequest *request = [GADRequest request];
        request.requestAgent = kRequestAgent;
        NSMutableDictionary *additionalParameters = [[NSMutableDictionary alloc] init];
        additionalParameters[kAdMobQueryInfoType] = kAdMobRequesterType;

        GADExtras *extras = [[GADExtras alloc] init];
        extras.additionalParameters = additionalParameters;
        [request registerAdNetworkExtras:extras];
        
        [self.adapter collectBiddingDataWithAdData:request
                                          adFormat:GADAdFormatInterstitial
                                          delegate:delegate];
    });
}

#pragma mark - Init Delegate

- (void)onNetworkInitCallbackSuccess {
    NSArray *interstitialAdUnitIds = self.adUnitIdToSmashDelegate.allKeys;

    for (NSString *adUnitId in interstitialAdUnitIds) {
        id<ISInterstitialAdapterDelegate> delegate = [self.adUnitIdToSmashDelegate objectForKey:adUnitId];
        [delegate adapterInterstitialInitSuccess];
    }
}

- (void)onNetworkInitCallbackFailed:(NSString *)errorMessage {
    NSError *error = [ISError createErrorWithDomain:kAdapterName
                                               code:ERROR_CODE_INIT_FAILED
                                            message:errorMessage];
    
    NSArray *interstitialAdUnitIds = self.adUnitIdToSmashDelegate.allKeys;

    for (NSString *adUnitId in interstitialAdUnitIds) {
        id<ISInterstitialAdapterDelegate> delegate = [self.adUnitIdToSmashDelegate objectForKey:adUnitId];
        [delegate adapterInterstitialInitFailedWithError:error];
    }
}

#pragma mark - Memory Handling

- (void)releaseMemoryWithAdapterConfig:(ISAdapterConfig *)adapterConfig {
    // there is no required implementation for AdMob release memory
}

#pragma mark - Availability

- (void)onAdUnitAvailabilityChangeWithAdUnitId:(NSString *)adUnitId
                                  availability:(BOOL)availability
                                interstitialAd:(GADInterstitialAd *)interstitialAd {
    if (availability) {
        [self.adUnitIdToAds setObject:interstitialAd
                               forKey:adUnitId];
    }

    [self.adUnitIdToAdsAvailability setObject:@(availability)
                                       forKey:adUnitId];
}

@end
