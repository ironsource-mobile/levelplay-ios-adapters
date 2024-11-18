#import "ISOguryRewardedVideoAdapter.h"
#import "ISOguryRewardedVideoDelegate.h"

@interface ISOguryRewardedVideoAdapter ()

@property (nonatomic, weak)   ISOguryAdapter *adapter;
@property (nonatomic, strong) OguryRewardedAd *ad;
@property (nonatomic, strong) ISOguryRewardedVideoDelegate *oguryAdDelegate;
@property (nonatomic, weak) id<ISRewardedVideoAdapterDelegate> smashDelegate;
@end

@implementation ISOguryRewardedVideoAdapter

- (instancetype)initWithOguryAdapter:(ISOguryAdapter *)adapter {
    self = [super init];
    if (self) {
        _adapter = adapter;
        _ad = nil;
        _smashDelegate = nil;
        _oguryAdDelegate = nil;
    }
    return self;
}

#pragma mark - Rewarded Video API

// Used for flows when the mediation needs to get a callback for init
- (void)initRewardedVideoForCallbacksWithUserId:(NSString *)userId
                                  adapterConfig:(ISAdapterConfig *)adapterConfig
                                       delegate:(id<ISRewardedVideoAdapterDelegate>)delegate {
    
    NSString *assetKey = [self getStringValueFromAdapterConfig:adapterConfig
                                                     forKey:kAppId];
    /* Configuration Validation */
    if (![self.adapter isConfigValueValid:assetKey]) {
        NSError *error = [self.adapter errorForMissingCredentialFieldWithName:kAppId];
        LogAdapterApi_Internal(@"error = %@", error);
        [delegate adapterRewardedVideoInitFailed:error];
        return;
    }

    NSString *adUnitId = [self getStringValueFromAdapterConfig:adapterConfig
                                                        forKey:kPlacementId];
    /* Configuration Validation */
    if (![self.adapter isConfigValueValid:adUnitId]) {
        NSError *error = [self.adapter errorForMissingCredentialFieldWithName:kPlacementId];
        LogAdapterApi_Internal(@"error = %@", error);
        [delegate adapterRewardedVideoInitFailed:error];
        return;
    }

    self.smashDelegate = delegate;

    LogAdapterApi_Internal(@"assetKey = %@, adUnitId = %@", assetKey, adUnitId);

    switch ([self.adapter getInitState]) {
        case INIT_STATE_NONE:
        case INIT_STATE_IN_PROGRESS:
            [self.adapter initSDKWithAssetKey:assetKey];
            break;
        case INIT_STATE_SUCCESS:
            [delegate adapterRewardedVideoInitSuccess];
            break;
        case INIT_STATE_FAILED:
            LogAdapterApi_Internal(@"init failed - adUnitId = %@", adUnitId);
            [delegate adapterRewardedVideoInitFailed:[ISError createError:ERROR_CODE_INIT_FAILED
                                                              withMessage:@"OgurySDK init failed"]];
            break;
    }
}

- (void)loadRewardedVideoForBiddingWithAdapterConfig:(ISAdapterConfig *)adapterConfig
                                              adData:(NSDictionary *)adData
                                          serverData:(NSString *)serverData
                                            delegate:(id<ISRewardedVideoAdapterDelegate>)delegate {
    
    NSString *adUnitId = [self getStringValueFromAdapterConfig:adapterConfig
                                                        forKey:kPlacementId];
    
    LogAdapterApi_Internal(@"adUnitId = %@", adUnitId);
    
    ISOguryRewardedVideoDelegate *adDelegate = [[ISOguryRewardedVideoDelegate alloc] initWithAdUnitId:adUnitId
                                                                                          andDelegate:delegate];
    
    self.oguryAdDelegate = adDelegate;    
    self.ad = [[OguryRewardedAd alloc] initWithAdUnitId:adUnitId
                                              mediation:[[OguryMediation alloc] initWithName: kMediationName version:[IronSource sdkVersion]]];
    self.ad.delegate = self.oguryAdDelegate;
    [self.ad loadWithAdMarkup: serverData];
}

- (void)showRewardedVideoWithViewController:(UIViewController *)viewController
                              adapterConfig:(ISAdapterConfig *)adapterConfig
                                   delegate:(id<ISRewardedVideoAdapterDelegate>)delegate {
    
    NSString *adUnitId = [self getStringValueFromAdapterConfig:adapterConfig
                                                        forKey:kPlacementId];

    LogAdapterDelegate_Internal(@"adUnitId = %@", adUnitId);

    if (![self.ad isLoaded]) {
        NSError *error = [ISError createError:ERROR_CODE_NO_ADS_TO_SHOW
                                  withMessage:[NSString stringWithFormat: @"%@ show failed", kAdapterName]];
        LogAdapterApi_Internal(@"error = %@", error);
        [delegate adapterRewardedVideoDidFailToShowWithError:error];
        return;
    }
    [self.ad showAdInViewController: viewController];
}


- (BOOL)hasRewardedVideoWithAdapterConfig:(ISAdapterConfig *)adapterConfig {
        return [self.ad isLoaded];
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
    NSString *adUnitId = [self getStringValueFromAdapterConfig:adapterConfig
                                                        forKey:kPlacementId];
    LogAdapterDelegate_Internal(@"adUnitId = %@", adUnitId);
    
    if (self.ad) {
        self.ad.delegate = nil;
        self.ad = nil;
    };
    self.smashDelegate = nil;
    self.oguryAdDelegate = nil;
}

@end
