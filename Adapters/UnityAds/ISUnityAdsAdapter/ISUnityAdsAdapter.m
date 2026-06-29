//
//  ISUnityAdsAdapter.m
//  ISUnityAdsAdapter
//
//  Copyright © 2021-2025 Unity Technologies. All rights reserved.
//

#import <ISUnityAdsAdapter.h>
#import <ISUADSRewardedShowDelegate.h>
#import <ISUADSInterstitialShowDelegate.h>
#import <ISUADSBannerAdDelegate.h>
#import <UnityAds/UnityAds.h>
#import <objc/runtime.h>

// UnityAds Mediation MetaData
static NSString * const kMediationName          = @"ironSource";
static NSString * const kAdapterVersionKey      = @"adapter_version";
static NSString * const kUnityAdsInitBlobKey    = @"uads_init_blob";
static NSString * const kUnityAdsEpTraitsKey    = @"traits";

// Network keys
static NSString * const kAdapterVersion         = UnityAdsAdapterVersion;
static NSString * const kAdapterName            = UnityAdsAdapterName;
static NSString * const kGameId                 = @"sourceId";
static NSString * const kPlacementId            = @"zoneId";

// Meta data flags
static NSString * const kMetaDataCOPPAKey       = @"unityads_coppa";
static NSString * const kCCPAUnityAdsFlag       = @"privacy.consent";
static NSString * const kGDPRUnityAdsFlag       = @"gdpr.consent";
static NSString * const kCOPPAUnityAdsFlag      = @"user.nonBehavioral";

// Handle init callback for all adapter instances
static ISConcurrentMutableSet<ISNetworkInitCallbackProtocol> *initCallbackDelegates = nil;

// Event sender for missing callback detection
static ISUnityAdsEventSenderBlock eventSender = nil;

// Feature flag key to disable the network's capability to load a Rewarded Video ad while another Rewarded Video ad of that network is showing
static NSString * const kIsLWSSupported         = @"isSupportedLWS";

static int const kUnityAdsNoFillError           = 52100;

@interface ISUnityAdsAdapter () <UnityAdsInitializationDelegate,
                                ISNetworkInitCallbackProtocol>

// Rewarded video
@property (nonatomic, strong) ISConcurrentMutableDictionary *rewardedVideoPlacementIdToSmashDelegate;

// Interstitial
@property (nonatomic, strong) ISConcurrentMutableDictionary *interstitialPlacementIdToSmashDelegate;

// Banner
@property (nonatomic, strong) ISConcurrentMutableDictionary *bannerPlacementIdToSmashDelegate;

// synchronization lock
@property (nonatomic, strong) NSObject                      *unityAdsStorageLock;

// Rewarded
@property (nonatomic, strong) NSString *rewardedPlacementId;
@property (nonatomic, strong) UADSRewardedAd *rewardedAd;
@property (nonatomic, strong) ISUADSRewardedShowDelegate *rewardedShowDelegate;
// Interstitial
@property (nonatomic, strong) NSString *interstitialPlacementId;
@property (nonatomic, strong) UADSInterstitialAd *interstitialAd;
@property (nonatomic, strong) ISUADSInterstitialShowDelegate *interstitialShowDelegate;
//Banner
@property (nonatomic, strong) NSString *bannerPlacementId;
@property (nonatomic, strong) UADSBannerAd *bannerAd;
@property (nonatomic, strong) ISUADSBannerAdDelegate *bannerAdDelegate;


@end

@implementation ISUnityAdsAdapter

#pragma mark - IronSource Protocol Methods

// get adapter version
- (NSString *) version {
    return kAdapterVersion;
}

// get network sdk version
- (NSString *) sdkVersion {
    return [UnityAds getVersion];
}

#pragma mark - Initializations Methods And Callbacks

- (instancetype)initAdapter:(NSString *)name {
    self = [super initAdapter:name];

    if (self) {
        if (initCallbackDelegates == nil) {
            initCallbackDelegates = [ISConcurrentMutableSet<ISNetworkInitCallbackProtocol> set];
        }

        // Rewarded video
        _rewardedVideoPlacementIdToSmashDelegate = [ISConcurrentMutableDictionary dictionary];

        // Interstitial
        _interstitialPlacementIdToSmashDelegate = [ISConcurrentMutableDictionary dictionary];

        // Banner
        _bannerPlacementIdToSmashDelegate = [ISConcurrentMutableDictionary dictionary];

        _unityAdsStorageLock = [NSObject new];
    }

    return self;
}

- (void)initSDKWithGameId:(NSString *)gameId
            adapterConfig:(ISAdapterConfig *)adapterConfig  {

    // add self to the init delegates only in case the initialization is not successful
    if (!UnityAds.isInitialized) {
        [initCallbackDelegates addObject:self];
    }

    UADSInitializationConfigurationBuilder *builder = [[UADSInitializationConfigurationBuilder alloc] initWithGameId:gameId];
    builder = [builder withTestMode:NO];
    builder = [builder withLogLevel:[ISConfigurations getConfigurations].adaptersDebug ? UADSLogLevelDebug : UADSLogLevelInfo];
    builder = [builder withMediationInfo:[self adapterMediationInfo]];
    builder = [builder withExtras:[self initializationExtrasFrom:adapterConfig]];

    [UnityAds initialize:[builder build]
              completion:^(id<UnityAdsError> _Nullable error) {
        if (error == nil) {
            [self initializationComplete];
        } else {
            [self initializationFailedWithMessage:[NSString stringWithFormat:@"UnityAds SDK init failed with error code: %ld, error message: %@", error.code, error.message]];
        }
    }];
}

- (void)initializationComplete {
    LogAdapterDelegate_Internal(@"UnityAds init success");

    NSArray *initDelegatesList = initCallbackDelegates.allObjects;

    // call init callback delegate success
    for (id<ISNetworkInitCallbackProtocol> initDelegate in initDelegatesList) {
        [initDelegate onNetworkInitCallbackSuccess];
    }

    [initCallbackDelegates removeAllObjects];
}

- (void)initializationFailed:(UnityAdsInitializationError)error
                 withMessage:(NSString *)message {

    NSString *errorMsg = @"UnityAds SDK init failed";

    if (message) {
        errorMsg = [NSString stringWithFormat:@"UnityAds SDK init failed with error code: %@, error message: %@", [self unityAdsInitErrorToString:error], message];
    }

    [self initializationFailedWithMessage:errorMsg];
}

- (void)initializationFailedWithMessage:(NSString *)errorMsg {

    LogAdapterDelegate_Internal(@"error - %@", errorMsg);

    NSArray *initDelegatesList = initCallbackDelegates.allObjects;

    // call init callback delegate fail
    for (id<ISNetworkInitCallbackProtocol> initDelegate in initDelegatesList) {
        [initDelegate onNetworkInitCallbackFailed:errorMsg];
    }

    [initCallbackDelegates removeAllObjects];
}

- (void)onNetworkInitCallbackSuccess {
    // rewarded video
    NSArray *rewardedVideoPlacementIDs = _rewardedVideoPlacementIdToSmashDelegate.allKeys;

    for (NSString *placementId in rewardedVideoPlacementIDs) {
        id<ISRewardedVideoAdapterDelegate> delegate = [_rewardedVideoPlacementIdToSmashDelegate objectForKey:placementId];
        [delegate adapterRewardedVideoInitSuccess];
    }

    // interstitial
    NSArray *interstitialPlacementIDs = _interstitialPlacementIdToSmashDelegate.allKeys;

    for (NSString *placementId in interstitialPlacementIDs) {
        id<ISInterstitialAdapterDelegate> delegate = [_interstitialPlacementIdToSmashDelegate objectForKey:placementId];
        [delegate adapterInterstitialInitSuccess];
    }

    // banner
    NSArray *bannerPlacementIDs = _bannerPlacementIdToSmashDelegate.allKeys;

    for (NSString *placementId in bannerPlacementIDs) {
        id<ISBannerAdapterDelegate> delegate = [_bannerPlacementIdToSmashDelegate objectForKey:placementId];
        [delegate adapterBannerInitSuccess];
    }
}

- (void)onNetworkInitCallbackFailed:(nonnull NSString *)errorMessage {

    NSError *error = [ISError createErrorWithDomain:kAdapterName
                                               code:ERROR_CODE_INIT_FAILED
                                            message:errorMessage];

    // rewarded video
    NSArray *rewardedVideoPlacementIDs = _rewardedVideoPlacementIdToSmashDelegate.allKeys;

    for (NSString *placementId in rewardedVideoPlacementIDs) {
        id<ISRewardedVideoAdapterDelegate> delegate = [_rewardedVideoPlacementIdToSmashDelegate objectForKey:placementId];
        [delegate adapterRewardedVideoInitFailed:error];
    }

    // interstitial
    NSArray *interstitialPlacementIDs = _interstitialPlacementIdToSmashDelegate.allKeys;

    for (NSString *placementId in interstitialPlacementIDs) {
        id<ISInterstitialAdapterDelegate> delegate = [_interstitialPlacementIdToSmashDelegate objectForKey:placementId];
        [delegate adapterInterstitialInitFailedWithError:error];
    }

    // banner
    NSArray *bannerPlacementIDs = _bannerPlacementIdToSmashDelegate.allKeys;

    for (NSString *placementId in bannerPlacementIDs) {
        id<ISBannerAdapterDelegate> delegate = [_bannerPlacementIdToSmashDelegate objectForKey:placementId];
        [delegate adapterBannerInitFailedWithError:error];
    }
}

#pragma mark - Rewarded Video API


// used for flows when the mediation needs to get a callback for init
- (void)initRewardedVideoForCallbacksWithUserId:(NSString *)userId
                                  adapterConfig:(ISAdapterConfig *)adapterConfig
                                       delegate:(id<ISRewardedVideoAdapterDelegate>)delegate {
    NSString *gameId = adapterConfig.settings[kGameId];
    NSString *placementId = adapterConfig.settings[kPlacementId];

    // Configuration Validation
    if (![self isConfigValueValid:gameId]) {
        NSError *error = [self errorForMissingCredentialFieldWithName:kGameId];
        LogAdapterApi_Internal(@"error = %@", error);
        [delegate adapterRewardedVideoInitFailed:error];
        return;
    }

    if (![self isConfigValueValid:placementId]) {
        NSError *error = [self errorForMissingCredentialFieldWithName:kPlacementId];
        LogAdapterApi_Internal(@"error = %@", error);
        [delegate adapterRewardedVideoInitFailed:error];
        return;
    }

    LogAdapterApi_Internal(@"placementId = %@", placementId);

    // Register Delegate for placement
    [_rewardedVideoPlacementIdToSmashDelegate setObject:delegate
                                                 forKey:placementId];

    [self extractEventSender:adapterConfig];

    if (!UnityAds.isInitialized) {
        [self initSDKWithGameId:gameId
                  adapterConfig:adapterConfig];
    }

    [delegate adapterRewardedVideoInitSuccess];
}

- (void)loadRewardedVideoForBiddingWithAdapterConfig:(ISAdapterConfig *)adapterConfig
                                              adData:(NSDictionary *)adData
                                          serverData:(NSString *)serverData
                                            delegate:(id<ISRewardedVideoAdapterDelegate>)delegate {
    NSString *placementId = adapterConfig.settings[kPlacementId];
    LogAdapterApi_Internal(@"placementId = %@", placementId);

    // Register Rewarded Video delegate for placement in order to support OPW flow- the delegate passes as a param through adapter's API
    [_rewardedVideoPlacementIdToSmashDelegate setObject:delegate
                                                 forKey:placementId];

    UADSLoadConfigurationBuilder *builder = [[UADSLoadConfigurationBuilder alloc] initWithPlacementId:placementId];
    if (serverData != nil) {
        builder = [builder withAdMarkup:serverData];
    }
    builder = [builder withMediationInfo:[self adapterMediationInfo]];
    builder = [builder withMediationAdUnitId:[self mediationAdUnitIdFor:UADSAdFormatRewarded adapterConfig:adapterConfig]];

    [UADSRewardedAd load:[builder build]
              completion:^(UADSRewardedAd* _Nullable rewardedAd, id<UnityAdsError> _Nullable error) {
        if (rewardedAd != nil) {
            LogAdapterDelegate_Internal(@"placementId = %@", placementId);
            if (delegate == nil && eventSender != nil) {
                eventSender(LEVEL_PLAY_REWARDED, TROUBLESHOOTING_UADS_MISSING_CALLBACK, @"rewarded_newApi_onAdLoaded");
            }
            self.rewardedAd = rewardedAd;
            self.rewardedPlacementId = placementId;
            [delegate adapterRewardedVideoHasChangedAvailability:YES];
        } else {
            LogAdapterDelegate_Internal(@"placementId = %@ reason - %ld %@", placementId, error.code, error.message);
            if (delegate == nil && eventSender != nil) {
                eventSender(LEVEL_PLAY_REWARDED, TROUBLESHOOTING_UADS_MISSING_CALLBACK, @"rewarded_newApi_onAdFailedToLoad");
            }
            NSInteger errorCode = (error.code == kUnityAdsNoFillError) ? ERROR_RV_LOAD_NO_FILL : error.code;
            NSError *smashError = [NSError errorWithDomain:kAdapterName
                                                      code:errorCode
                                                  userInfo:@{NSLocalizedDescriptionKey:error.message}];
            [delegate adapterRewardedVideoHasChangedAvailability:NO];
            [delegate adapterRewardedVideoDidFailToLoadWithError:smashError];
        }

    }];
}

- (void)showRewardedVideoWithViewController:(UIViewController *)viewController
                              adapterConfig:(ISAdapterConfig *)adapterConfig
                                   delegate:(id<ISRewardedVideoAdapterDelegate>)delegate {
    NSString *placementId = adapterConfig.settings[kPlacementId];
    LogAdapterApi_Internal(@"placementId = %@", placementId);

    if (_rewardedAd == nil) {
        NSError *error = [ISError createError:ERROR_CODE_NO_ADS_TO_SHOW
                                  withMessage:[NSString stringWithFormat: @"%@ show failed", kAdapterName]];
        LogAdapterApi_Internal(@"error = %@", error);
        [delegate adapterRewardedVideoDidFailToShowWithError:error];
        return;
    }

    UADSShowConfigurationBuilder *builder = [[UADSShowConfigurationBuilder alloc] init];
    if ([self dynamicUserId]) {
        builder = [builder withCustomRewardString:[self dynamicUserId]];
    }
    UIViewController *vc = viewController == nil ? [self topMostController] : viewController;
    builder = [builder withViewController:vc];

    _rewardedShowDelegate = [[ISUADSRewardedShowDelegate alloc] initWithPlacementId:placementId delegate:delegate eventSender:eventSender];
    [_rewardedAd show:[builder build] delegate:_rewardedShowDelegate];
}

- (BOOL)hasRewardedVideoWithAdapterConfig:(ISAdapterConfig *)adapterConfig {
    NSString *placementId = adapterConfig.settings[kPlacementId];
    return [self.rewardedPlacementId isEqualToString:placementId] && self.rewardedAd != nil;
}

- (void)collectRewardedVideoBiddingDataWithAdapterConfig:(ISAdapterConfig *)adapterConfig
                                                  adData:(NSDictionary *)adData
                                                delegate:(id<ISBiddingDataDelegate>)delegate {
    [self getBiddingDataFor:UADSAdFormatRewarded
             adapterConfig:adapterConfig
                    adData:adData
                  delegate:delegate];
}

- (void)destroyRewardedVideoAdWithAdapterConfig:(ISAdapterConfig *)adapterConfig {
    NSString *placementId = adapterConfig.settings[kPlacementId];

    if ([placementId isEqualToString:self.rewardedPlacementId]) {
        _rewardedAd = nil;
        _rewardedPlacementId = nil;
        _rewardedShowDelegate = nil;
    }
}

#pragma mark - Interstitial API

- (void)initInterstitialForBiddingWithUserId:(NSString *)userId
                               adapterConfig:(ISAdapterConfig *)adapterConfig
                                    delegate:(id<ISInterstitialAdapterDelegate>)delegate {
    NSString *gameId = adapterConfig.settings[kGameId];
    NSString *placementId = adapterConfig.settings[kPlacementId];

    // Configuration Validation
    if (![self isConfigValueValid:gameId]) {
        NSError *error = [self errorForMissingCredentialFieldWithName:kGameId];
        LogAdapterApi_Internal(@"error = %@", error);
        [delegate adapterInterstitialInitFailedWithError:error];
        return;
    }

    if (![self isConfigValueValid:placementId]) {
        NSError *error = [self errorForMissingCredentialFieldWithName:kPlacementId];
        LogAdapterApi_Internal(@"error = %@", error);
        [delegate adapterInterstitialInitFailedWithError:error];
        return;
    }

    LogAdapterApi_Internal(@"placementId = %@", placementId);

    // Register Delegate for placement
    [_interstitialPlacementIdToSmashDelegate setObject:delegate
                                                forKey:placementId];

    [self extractEventSender:adapterConfig];

    if (!UnityAds.isInitialized) {
        [self initSDKWithGameId:gameId
                  adapterConfig:adapterConfig];
    }

    [delegate adapterInterstitialInitSuccess];
}

- (void)loadInterstitialForBiddingWithAdapterConfig:(ISAdapterConfig *)adapterConfig
                                             adData:(NSDictionary *)adData
                                         serverData:(NSString *)serverData
                                           delegate:(id<ISInterstitialAdapterDelegate>)delegate {
    NSString *placementId = adapterConfig.settings[kPlacementId];
    LogAdapterApi_Internal(@"placementId = %@", placementId);

    // Register delegate for placement
    [_interstitialPlacementIdToSmashDelegate setObject:delegate
                                                forKey:placementId];

    UADSLoadConfigurationBuilder *builder = [[UADSLoadConfigurationBuilder alloc] initWithPlacementId:placementId];
    if (serverData != nil) {
        builder = [builder withAdMarkup:serverData];
    }
    builder = [builder withMediationInfo:[self adapterMediationInfo]];
    builder = [builder withMediationAdUnitId:[self mediationAdUnitIdFor:UADSAdFormatInterstitial adapterConfig:adapterConfig]];

    [UADSInterstitialAd load:[builder build]
                  completion:^(UADSInterstitialAd* _Nullable interstitialAd, id<UnityAdsError> _Nullable error) {
        if (interstitialAd != nil) {
            LogAdapterDelegate_Internal(@"placementId = %@", placementId);
            if (delegate == nil && eventSender != nil) {
                eventSender(LEVEL_PLAY_INTERSTITIAL, TROUBLESHOOTING_UADS_MISSING_CALLBACK, @"interstitial_newApi_onAdLoaded");
            }
            self.interstitialAd = interstitialAd;
            self.interstitialPlacementId = placementId;
            [delegate adapterInterstitialDidLoad];
        } else {
            LogAdapterDelegate_Internal(@"placementId = %@ reason - %ld %@", placementId, error.code, error.message);
            if (delegate == nil && eventSender != nil) {
                eventSender(LEVEL_PLAY_INTERSTITIAL, TROUBLESHOOTING_UADS_MISSING_CALLBACK, @"interstitial_newApi_onAdFailedToLoad");
            }
            NSInteger errorCode = (error.code == kUnityAdsNoFillError) ? ERROR_IS_LOAD_NO_FILL : error.code;
            NSError *smashError = [NSError errorWithDomain:kAdapterName
                                                      code:errorCode
                                                  userInfo:@{NSLocalizedDescriptionKey:error.message}];
            [delegate adapterInterstitialDidFailToLoadWithError:smashError];
        }
    }];
}

- (void)showInterstitialWithViewController:(UIViewController *)viewController
                             adapterConfig:(ISAdapterConfig *)adapterConfig
                                  delegate:(id<ISInterstitialAdapterDelegate>)delegate {
    NSString *placementId = adapterConfig.settings[kPlacementId];
    LogAdapterApi_Internal(@"placementId = %@", placementId);

    if (_interstitialAd == nil) {
        NSError *error = [ISError createError:ERROR_CODE_NO_ADS_TO_SHOW
                                  withMessage:[NSString stringWithFormat: @"%@ show failed", kAdapterName]];
        LogAdapterApi_Internal(@"error = %@", error);
        [delegate adapterInterstitialDidFailToShowWithError:error];
        return;
    }

    UADSShowConfigurationBuilder *builder = [[UADSShowConfigurationBuilder alloc] init];
    if ([self dynamicUserId]) {
        builder = [builder withCustomRewardString:[self dynamicUserId]];
    }
    UIViewController *vc = viewController == nil ? [self topMostController] : viewController;
    builder = [builder withViewController:vc];

    _interstitialShowDelegate = [[ISUADSInterstitialShowDelegate alloc] initWithPlacementId:placementId delegate:delegate eventSender:eventSender];
    [_interstitialAd show:[builder build] delegate:_interstitialShowDelegate];
}

- (BOOL)hasInterstitialWithAdapterConfig:(ISAdapterConfig *)adapterConfig {
    NSString *placementId = adapterConfig.settings[kPlacementId];
    return [self.interstitialPlacementId isEqualToString:placementId] && self.interstitialAd != nil;
}

- (void)collectInterstitialBiddingDataWithAdapterConfig:(ISAdapterConfig *)adapterConfig
                                                 adData:(NSDictionary *)adData
                                               delegate:(id<ISBiddingDataDelegate>)delegate {
    [self getBiddingDataFor:UADSAdFormatInterstitial
             adapterConfig:adapterConfig
                    adData:adData
                  delegate:delegate];
}

- (void)destroyInterstitialAdWithAdapterConfig:(ISAdapterConfig *)adapterConfig {
    NSString *placementId = adapterConfig.settings[kPlacementId];

    if ([placementId isEqualToString:self.interstitialPlacementId]) {
        _interstitialAd = nil;
        _interstitialPlacementId = nil;
        _interstitialShowDelegate = nil;
    }
}

#pragma mark - Banner API

- (void)initBannerForBiddingWithUserId:(NSString *)userId
                         adapterConfig:(ISAdapterConfig *)adapterConfig
                              delegate:(id<ISBannerAdapterDelegate>)delegate {
    NSString *gameId = adapterConfig.settings[kGameId];
    NSString *placementId = adapterConfig.settings[kPlacementId];

    // Configuration validation
    if (![self isConfigValueValid:gameId]) {
        NSError *error = [self errorForMissingCredentialFieldWithName:kGameId];
        LogAdapterApi_Internal(@"error = %@", error);
        [delegate adapterBannerInitFailedWithError:error];
        return;
    }

    if (![self isConfigValueValid:placementId]) {
        NSError *error = [self errorForMissingCredentialFieldWithName:kPlacementId];
        LogAdapterApi_Internal(@"error = %@", error);
        [delegate adapterBannerInitFailedWithError:error];
        return;
    }

    LogAdapterApi_Internal(@"placementId = %@", placementId);

    // add to banner delegate dictionary
    [_bannerPlacementIdToSmashDelegate setObject:delegate
                                          forKey:placementId];

    [self extractEventSender:adapterConfig];

    if (!UnityAds.isInitialized) {
        [self initSDKWithGameId:gameId adapterConfig:adapterConfig];
    }

    [delegate adapterBannerInitSuccess];
}

- (void)loadBannerForBiddingWithAdapterConfig:(ISAdapterConfig *)adapterConfig
                                       adData:(NSDictionary *)adData
                                   serverData:(NSString *)serverData
                               viewController:(UIViewController *)viewController
                                         size:(ISBannerSize *)size
                                     delegate:(id <ISBannerAdapterDelegate>)delegate {
    NSString *placementId = adapterConfig.settings[kPlacementId];

    // Verify size
    if (![self isBannerSizeSupported:size]) {
        NSError *error = [ISError createError:ERROR_BN_UNSUPPORTED_SIZE withMessage:[NSString stringWithFormat:@"UnityAds unsupported banner size - %@", size.sizeDescription]];
        LogAdapterApi_Internal(@"error = %@", error);
        [delegate adapterBannerDidFailToLoadWithError:error];
        return;
    }

    LogAdapterApi_Internal(@"placementId = %@", placementId);

    // add to banner delegate dictionary
    [_bannerPlacementIdToSmashDelegate setObject:delegate
                                          forKey:placementId];

    _bannerAdDelegate = [[ISUADSBannerAdDelegate alloc] initWithPlacementId:placementId delegate:delegate eventSender:eventSender];
    UADSBannerLoadConfigurationBuilder *builder = [[UADSBannerLoadConfigurationBuilder alloc]
                                                   initWithPlacementId:placementId
                                                   bannerSize:[self getBannerSize:size]
                                                   delegate:_bannerAdDelegate];
    if (serverData != nil) {
        builder = [builder withAdMarkup:serverData];
    }
    builder = [builder withMediationInfo:[self adapterMediationInfo]];
    builder = [builder withMediationAdUnitId:[self mediationAdUnitIdFor:UADSAdFormatBanner adapterConfig:adapterConfig]];

    [UADSBannerAd load:[builder build]
            completion:^(UADSBannerAd * _Nullable bannerAd, id<UnityAdsError> _Nullable error) {
        if (bannerAd != nil) {
            LogAdapterDelegate_Internal(@"placementId = %@", placementId);
            if (delegate == nil && eventSender != nil) {
                eventSender(LEVEL_PLAY_BANNER, TROUBLESHOOTING_UADS_MISSING_CALLBACK, @"banner_newApi_onAdLoaded");
            }
            self.bannerAd = bannerAd;
            self.bannerPlacementId = placementId;
            [delegate adapterBannerDidLoad:bannerAd.view];
        } else {
            LogAdapterDelegate_Internal(@"placementId = %@ reason - %ld %@", placementId, error.code, error.message);
            if (delegate == nil && eventSender != nil) {
                eventSender(LEVEL_PLAY_BANNER, TROUBLESHOOTING_UADS_MISSING_CALLBACK, @"banner_newApi_onAdFailedToLoad");
            }
            NSInteger errorCode = (error.code == kUnityAdsNoFillError)? ERROR_BN_LOAD_NO_FILL : error.code;
            NSError *smashError = [NSError errorWithDomain:kAdapterName
                                                      code:errorCode
                                                  userInfo:@{NSLocalizedDescriptionKey:error.message}];
            [delegate adapterBannerDidFailToLoadWithError:smashError];
        }
    }];
}

- (void)destroyBannerWithAdapterConfig:(ISAdapterConfig *)adapterConfig {
    NSString *placementId = adapterConfig.settings[kPlacementId];

    if ([placementId isEqualToString:self.bannerPlacementId]) {
        _bannerAd = nil;
        _bannerPlacementId = nil;
        _bannerAdDelegate = nil;
    }
}

- (void)collectBannerBiddingDataWithAdapterConfig:(ISAdapterConfig *)adapterConfig
                                           adData:(NSDictionary *)adData
                                         delegate:(id<ISBiddingDataDelegate>)delegate {
    [self getBiddingDataFor:UADSAdFormatBanner
             adapterConfig:adapterConfig
                    adData:adData
                  delegate:delegate];
}

#pragma mark - Legal Methods

- (void)setMetaDataWithKey:(NSString *)key
                 andValues:(NSMutableArray *)values {
    if (values.count == 0) {
        return;
    }

    // this is a list of 1 value
    NSString *value = values[0];
    LogAdapterApi_Internal(@"setMetaData: key=%@, value=%@", key, value);

    if ([ISMetaDataUtils isValidCCPAMetaDataWithKey:key
                                           andValue:value]) {
        [self setCCPAValue:[ISMetaDataUtils getMetaDataBooleanValue:value]];
    } else {
        NSString *formattedValue = [ISMetaDataUtils formatValue:value
                                                        forType:(META_DATA_VALUE_BOOL)];

        if ([ISMetaDataUtils isValidMetaDataWithKey:key
                                               flag:kMetaDataCOPPAKey
                                           andValue:formattedValue]) {
            [self setCOPPAValue:[ISMetaDataUtils getMetaDataBooleanValue:formattedValue]];
        }
    }
}

- (void)setCCPAValue:(BOOL)value {
    // The UnityAds CCPA API expects an indication if the user opts in to targeted advertising.
    // Given that this is opposite to the ironSource Mediation CCPA flag of do_not_sell
    // we will use the opposite value of what is passed to this method
    BOOL optIn = !value;

    [self setUnityAdsMetaDataWithKey:kCCPAUnityAdsFlag
                               value:optIn];

    [UnityAds setUserOptOut:value];
}

- (void)setConsent:(BOOL)consent {
    [self setUnityAdsMetaDataWithKey:kGDPRUnityAdsFlag
                               value:consent];

    [UnityAds setUserConsent:consent];
}

- (void)setCOPPAValue:(BOOL)value {
    [self setUnityAdsMetaDataWithKey:kCOPPAUnityAdsFlag
                               value:value];

    [UnityAds setNonBehavioral:value];
}

- (void)setUnityAdsMetaDataWithKey:(NSString *)key
                             value:(BOOL)value {
    LogAdapterApi_Internal(@"key = %@, value = %@", key, value? @"YES" : @"NO");

    @synchronized (_unityAdsStorageLock) {
        UADSMetaData *unityAdsMetaData = [[UADSMetaData alloc] init];
        [unityAdsMetaData set:key value:value ? @YES : @NO];
        [unityAdsMetaData commit];
    }
}

#pragma mark - Private Methods

- (void)extractEventSender:(ISAdapterConfig *)adapterConfig {
    if (eventSender != nil) {
        return;
    }

    ISUnityAdsEventSenderBlock sender = objc_getAssociatedObject(adapterConfig, @selector(eventSenderBlock));

    if (!sender) {
        return;
    }

    eventSender = sender;
}

- (void)getBiddingDataFor:(UADSAdFormat)format
            adapterConfig:(ISAdapterConfig *)adapterConfig
                   adData:(NSDictionary *)adData
                 delegate:(id<ISBiddingDataDelegate>)delegate {
    UADSTokenConfigurationBuilder *builder = [[UADSTokenConfigurationBuilder alloc] initWithAdFormat:format];
    builder = [builder withMediationInfo:[self adapterMediationInfo]];
    id bannerSizeValue = adData[@"bannerSize"];
    if ([bannerSizeValue isKindOfClass:[ISBannerSize class]]) {
        ISBannerSize *bannerSize = (ISBannerSize *)bannerSizeValue;
        builder = [builder withBannerSize:CGSizeMake(bannerSize.width, bannerSize.height)];
    }

    NSString *placementId = adapterConfig.settings[kPlacementId];
    if(placementId != nil) {
        builder = [builder withPlacementId: placementId];
    }

    NSString *mediationAdUnitId = [self mediationAdUnitIdFor:format
                                               adapterConfig:adapterConfig];
    if (mediationAdUnitId != nil) {
        builder = [builder withMediationAdUnitId: mediationAdUnitId];
    }

    [UnityAds getToken:[builder build] completion:^(NSString * _Nullable token) {
        if (token != nil && ![token isEqualToString:@""]) {
            LogAdapterApi_Internal(@"token = %@", token);
            [delegate successWithBiddingData:@{ @"token": token }];
        } else {
            LogAdapterApi_Internal(@"returning nil as token");
            [delegate failureWithError:@"empty token"];
        }
    }];
}

- (BOOL)isBannerSizeSupported:(ISBannerSize *)size {
    if ([size.sizeDescription isEqualToString:@"BANNER"] ||
        [size.sizeDescription isEqualToString:@"LARGE"] ||
        [size.sizeDescription isEqualToString:@"RECTANGLE"] ||
        [size.sizeDescription isEqualToString:@"SMART"]) {
        return YES;
    }

    return NO;
}

- (CGSize)getBannerSize:(ISBannerSize *)size {
    if ([size.sizeDescription isEqualToString:@"BANNER"] ||
        [size.sizeDescription isEqualToString:@"LARGE"]) {
        return CGSizeMake(320, 50);
    } else if ([size.sizeDescription isEqualToString:@"RECTANGLE"]) {
        return CGSizeMake(300, 250);
    } else if ([size.sizeDescription isEqualToString:@"SMART"]) {
        if (UI_USER_INTERFACE_IDIOM() == UIUserInterfaceIdiomPad) {
            return CGSizeMake(728, 90);
        } else {
            return CGSizeMake(320, 50);
        }
    }

    return CGSizeZero;
}

- (NSString *)unityAdsInitErrorToString:(UnityAdsInitializationError)error {
    NSString *result = nil;

    switch (error) {
        case kUnityInitializationErrorInternalError:
            result = @"INTERNAL_ERROR";
            break;
        case kUnityInitializationErrorInvalidArgument:
            result = @"INVALID_ARGUMENT";
            break;
        case kUnityInitializationErrorAdBlockerDetected:
            result = @"AD_BLOCKER_DETECTED";
            break;
        default:
            result = @"UNKNOWN_ERROR";
    }

    return result;
}

// The network's capability to load a Rewarded Video ad while another Rewarded Video ad of that network is showing
- (ISLoadWhileShowSupportState)getLWSSupportState:(ISAdapterConfig *)adapterConfig {
    ISLoadWhileShowSupportState state = LOAD_WHILE_SHOW_BY_INSTANCE;

    if (adapterConfig != nil && [adapterConfig.settings objectForKey:kIsLWSSupported] != nil) {
        BOOL isLWSSupported = [[adapterConfig.settings objectForKey:kIsLWSSupported] boolValue];

        if (!isLWSSupported) {
            state = LOAD_WHILE_SHOW_NONE;
        }
    }

    return state;
}

- (UADSMediationInfo*)adapterMediationInfo {
    return [[UADSMediationInfo alloc] initWithName:kMediationName
                                           version:[LevelPlay sdkVersion]
                                    adapterVersion:kAdapterVersion];
}

- (NSString *)mediationAdUnitIdFor:(UADSAdFormat)format
                     adapterConfig:(ISAdapterConfig *)adapterConfig {
    switch (format) {
        case UADSAdFormatBanner:
            return adapterConfig.bannerSettings[kPlacementId];

        case UADSAdFormatRewarded:
            return adapterConfig.rewardedVideoSettings[kPlacementId];

        case UADSAdFormatInterstitial:
            return adapterConfig.interstitialSettings[kPlacementId];

        default:
            return nil;
    }
}

- (NSDictionary *)initializationExtrasFrom:(ISAdapterConfig *)adapterConfig {
    NSMutableDictionary<NSString *, NSString *> *extras = [NSMutableDictionary dictionary];
    NSString *blob = adapterConfig.settings[kUnityAdsInitBlobKey];
    if ([blob isKindOfClass:NSString.class]) {
        extras[kUnityAdsInitBlobKey] = blob;
    }
    id traitsObject = adapterConfig.settings[kUnityAdsEpTraitsKey];
    if ([traitsObject isKindOfClass:NSDictionary.class]) {
        NSDictionary *traits = (NSDictionary *)traitsObject;
        for (id key in traits) {
            if (![key isKindOfClass:NSString.class]) {
                continue;
            }
            id value = traits[key];
            if ([value isKindOfClass:NSString.class]) {
                extras[key] = value;
            } else if ([value isKindOfClass:NSNumber.class]) {
                extras[key] = [((NSNumber *)value) stringValue];
            }
        }
    }
    return extras;
}

@end

#if DEBUG
@implementation ISUnityAdsAdapter (Testing)

+ (ISUnityAdsEventSenderBlock)eventSender {
    return eventSender;
}

+ (void)resetEventSender {
    eventSender = nil;
}

@end
#endif
