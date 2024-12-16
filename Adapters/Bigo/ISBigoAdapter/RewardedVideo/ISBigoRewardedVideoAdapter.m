#import "ISBigoRewardedVideoAdapter.h"
#import "ISBigoRewardedVideoDelegate.h"
#import "ISBigoAdapter.h"

@interface ISBigoRewardedVideoAdapter ()

@property (nonatomic, weak)   ISBigoAdapter *adapter;
@property (nonatomic, strong) BigoRewardVideoAd *ad;
@property (nonatomic, strong) BigoRewardVideoAdLoader *adLoader;
@property (nonatomic, strong) ISBigoRewardedVideoDelegate *bigoAdDelegate;
@property (nonatomic, weak) id<ISRewardedVideoAdapterDelegate> smashDelegate;

@end

@implementation ISBigoRewardedVideoAdapter

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

#pragma mark - Rewarded Video API

// Used for flows when the mediation needs to get a callback for init
- (void)initRewardedVideoForCallbacksWithUserId:(NSString *)userId
                                  adapterConfig:(ISAdapterConfig *)adapterConfig
                                       delegate:(id<ISRewardedVideoAdapterDelegate>)delegate {
    NSString *appKey = [self getStringValueFromAdapterConfig:adapterConfig
                                                     forKey:kAppId];
    /* Configuration Validation */
    if (![self.adapter isConfigValueValid:appKey]) {
        NSError *error = [self.adapter errorForMissingCredentialFieldWithName:kAppId];
        LogAdapterApi_Internal(@"error = %@", error);
        [delegate adapterRewardedVideoInitFailed:error];
        return;
    }

    NSString *slotId = [self getStringValueFromAdapterConfig:adapterConfig
                                                        forKey:kSlotId];
    /* Configuration Validation */
    if (![self.adapter isConfigValueValid:slotId]) {
        NSError *error = [self.adapter errorForMissingCredentialFieldWithName:kSlotId];
        LogAdapterApi_Internal(@"error = %@", error);
        [delegate adapterRewardedVideoInitFailed:error];
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
            [delegate adapterRewardedVideoInitSuccess];
            break;
        case INIT_STATE_FAILED:
            LogAdapterApi_Internal(@"init failed - slotId = %@", slotId);
            [delegate adapterRewardedVideoInitFailed:[ISError createError:ERROR_CODE_INIT_FAILED
                                                              withMessage:@"Bigo SDK init failed"]];
            break;
    }
}

- (void)loadRewardedVideoForBiddingWithAdapterConfig:(ISAdapterConfig *)adapterConfig
                                              adData:(NSDictionary *)adData
                                          serverData:(NSString *)serverData
                                            delegate:(id<ISRewardedVideoAdapterDelegate>)delegate {
    
    NSString *slotId = [self getStringValueFromAdapterConfig:adapterConfig
                                                        forKey:kSlotId];
    
    LogAdapterApi_Internal(@"slotId = %@", slotId);
    ISBigoRewardedVideoDelegate *adDelegate = [[ISBigoRewardedVideoDelegate alloc]
                                    initWithSlotId:slotId
                                andRewardedAdapter:self
                                    andDelegate:delegate];
    
    self.bigoAdDelegate = adDelegate;
    
    BigoRewardVideoAdRequest *request = [[BigoRewardVideoAdRequest alloc] initWithSlotId:slotId];
    [request setServerBidPayload:serverData];
    
    ISBigoAdapter *bigoAdapter = [[ISBigoAdapter alloc] init];
    NSString *mediationInfo = [bigoAdapter getMediationInfo];
    
    self.adLoader = [[BigoRewardVideoAdLoader alloc] initWithRewardVideoAdLoaderDelegate:adDelegate];
    self.adLoader.ext = mediationInfo;
    [self.adLoader loadAd:request];
    
}

- (void)setRewardedAd:(BigoRewardVideoAd *)ad {
    self.ad = ad;
    [ad setRewardVideoAdInteractionDelegate:self.bigoAdDelegate];
}

- (void)showRewardedVideoWithViewController:(UIViewController *)viewController
                              adapterConfig:(ISAdapterConfig *)adapterConfig
                                   delegate:(id<ISRewardedVideoAdapterDelegate>)delegate {
        
    NSString *slotId = [self getStringValueFromAdapterConfig:adapterConfig
                                                        forKey:kSlotId];
    LogAdapterDelegate_Internal(@"slotId = %@", slotId);
    
    if (![self hasRewardedVideoWithAdapterConfig:adapterConfig]) {
    
        NSError *error = [ISError createError:ERROR_CODE_NO_ADS_TO_SHOW
                                  withMessage:[NSString stringWithFormat: @"%@ show failed", kAdapterName]];
        
        LogAdapterApi_Internal(@"error = %@", error);
        [delegate adapterRewardedVideoDidFailToShowWithError:error];
        return;
    }
    
    dispatch_async(dispatch_get_main_queue(), ^{
        [self.ad show:viewController];
    });
    
}


- (BOOL)hasRewardedVideoWithAdapterConfig:(ISAdapterConfig *)adapterConfig {
    return self.ad != nil && ![self.ad isExpired];
}

- (void)collectRewardedVideoBiddingDataWithAdapterConfig:(ISAdapterConfig *)adapterConfig
                                                  adData:(NSDictionary *)adData
                                                delegate:(id<ISBiddingDataDelegate>)delegate {
    
    [self.adapter collectBiddingDataWithDelegate:delegate];
}

#pragma mark - Init Delegate

- (void)onNetworkInitCallbackSuccess {
    [self.smashDelegate adapterRewardedVideoInitSuccess];
}


- (void)onNetworkInitCallbackFailed:(NSString *)errorMessage {
    NSError *error = [ISError createErrorWithDomain:kAdapterName
                                               code:ERROR_CODE_INIT_FAILED
                                            message:errorMessage];
    [self.smashDelegate adapterRewardedVideoInitFailed:error];
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
