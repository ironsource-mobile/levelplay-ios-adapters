#import "ISBigoInterstitialAdapter.h"
#import "ISBigoInterstitialDelegate.h"
#import "ISBigoAdapter.h"

@interface ISBigoInterstitialAdapter ()

@property (nonatomic, weak)   ISBigoAdapter *adapter;
@property (nonatomic, strong) BigoInterstitialAd *ad;
@property (nonatomic, strong) BigoInterstitialAdLoader *adLoader;
@property (nonatomic, strong) ISBigoInterstitialDelegate *bigoAdDelegate;
@property (nonatomic, weak) id<ISInterstitialAdapterDelegate> smashDelegate;

@end

@implementation ISBigoInterstitialAdapter

- (instancetype)initWithBigoAdapter:(ISBigoAdapter *)adapter {
    self = [super init];
    if (self) {
        _adapter = adapter;
        _ad = nil;
        _smashDelegate = nil;
        _bigoAdDelegate = nil;
    }
    return self;
}

#pragma mark - Interstitial API

- (void)initInterstitialForBiddingWithUserId:(NSString *)userId
                               adapterConfig:(ISAdapterConfig *)adapterConfig
                                    delegate:(id<ISInterstitialAdapterDelegate>)delegate {
    NSString *appKey = [self getStringValueFromAdapterConfig:adapterConfig
                                                     forKey:kAppId];
    /* Configuration Validation */
    if (![self.adapter isConfigValueValid:appKey]) {
        NSError *error = [self.adapter errorForMissingCredentialFieldWithName:kAppId];
        LogAdapterApi_Internal(@"error = %@", error);
        [delegate adapterInterstitialInitFailedWithError:error];
        return;
    }

    NSString *slotId = [self getStringValueFromAdapterConfig:adapterConfig
                                                        forKey:kSlotId];
    /* Configuration Validation */
    if (![self.adapter isConfigValueValid:slotId]) {
        NSError *error = [self.adapter errorForMissingCredentialFieldWithName:kSlotId];
        LogAdapterApi_Internal(@"error = %@", error);
        [delegate adapterInterstitialInitFailedWithError:error];
        return;
    }

    self.smashDelegate = delegate;

    LogAdapterApi_Internal(@"appId = %@, slotId = %@", appKey, slotId);

    switch ([self.adapter getInitState]) {
        case INIT_STATE_NONE:
        case INIT_STATE_IN_PROGRESS:
            [self.adapter initSDKWithAppKey:appKey];
            break;
        case INIT_STATE_SUCCESS:
            [delegate adapterInterstitialInitSuccess];
            break;
        case INIT_STATE_FAILED:
            LogAdapterApi_Internal(@"init failed - slotId = %@", slotId);
            [delegate adapterInterstitialInitFailedWithError:[ISError createError:ERROR_CODE_INIT_FAILED
                                                                      withMessage:@"Bigo SDK init failed"]];
            break;
    }
}

- (void)loadInterstitialForBiddingWithAdapterConfig:(ISAdapterConfig *)adapterConfig
                                             adData:(NSDictionary *)adData
                                         serverData:(NSString *)serverData
                                           delegate:(id<ISInterstitialAdapterDelegate>)delegate {
    NSString *slotId = [self getStringValueFromAdapterConfig:adapterConfig
                                                        forKey:kSlotId];

    LogAdapterApi_Internal(@"slotId = %@", slotId);
    
    ISBigoInterstitialDelegate *adDelegate = [[ISBigoInterstitialDelegate alloc]
                                              initWithSlotId:slotId
                                        andInterstitialAdapter:self
                                                   andDelegate:delegate];
    self.bigoAdDelegate = adDelegate;
    
    BigoInterstitialAdRequest *request = [[BigoInterstitialAdRequest alloc] initWithSlotId:slotId];
    [request setServerBidPayload:serverData];
    
    ISBigoAdapter *bigoAdapter = [[ISBigoAdapter alloc] init];
    NSString *mediationInfo = [bigoAdapter getMediationInfo];
    
    self.adLoader = [[BigoInterstitialAdLoader alloc] initWithInterstitialAdLoaderDelegate:adDelegate];
    self.adLoader.ext = mediationInfo;
    [self.adLoader loadAd:request];
    
}

- (void)setInterstitialAd:(BigoInterstitialAd *)ad {
    self.ad = ad;
    [ad setAdInteractionDelegate:self.bigoAdDelegate];
}

- (void)showInterstitialWithViewController:(UIViewController *)viewController
                             adapterConfig:(ISAdapterConfig *)adapterConfig
                                  delegate:(id<ISInterstitialAdapterDelegate>)delegate {
    NSString *slotId = [self getStringValueFromAdapterConfig:adapterConfig
                                                        forKey:kSlotId];
    
    LogAdapterDelegate_Internal(@"slotId = %@", slotId);
    
    if (![self hasInterstitialWithAdapterConfig:adapterConfig]) {
        
        NSError *error = [ISError createError:ERROR_CODE_NO_ADS_TO_SHOW
                                  withMessage:[NSString stringWithFormat: @"%@ show failed", kAdapterName]];
        LogAdapterApi_Internal(@"error = %@", error);
        [delegate adapterInterstitialDidFailToShowWithError:error];
        return;
    }
    
    dispatch_async(dispatch_get_main_queue(), ^{
        [self.ad show:viewController];
    });
}

- (BOOL)hasInterstitialWithAdapterConfig:(ISAdapterConfig *)adapterConfig {
    return self.ad != nil && ![self.ad isExpired];
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
    NSString *slotId = [self getStringValueFromAdapterConfig:adapterConfig
                                                        forKey:kSlotId];
    LogAdapterDelegate_Internal(@"slotId = %@", slotId);

    dispatch_async(dispatch_get_main_queue(), ^{
        [self.ad destroy];
        self.ad = nil;
    });
    self.smashDelegate = nil;
    self.bigoAdDelegate = nil;
}

@end
