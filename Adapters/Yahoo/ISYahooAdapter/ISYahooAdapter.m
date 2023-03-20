//
//  ISYahooAdapter.m
//  ISYahooAdapter
//
//  Copyright © 2023 ironSource Mobile Ltd. All rights reserved.
//

#import <ISYahooAdapter.h>
#import <ISYahooRewardedVideoDelegate.h>
#import <ISYahooInterstitialDelegate.h>
#import <ISYahooBannerDelegate.h>
#import <YahooAds/YahooAds.h>

// Mediation info
static NSString * const kMediationName               = @"ironSource";

// Network keys
static NSString * const kAdapterVersion              = YahooAdapterVersion;
static NSString * const kAdapterName                 = @"Yahoo";
static NSString * const kSiteId                      = @"siteId";
static NSString * const kPlacementId                 = @"placementId";

// Meta data flags
static NSString * const kMetaDataCOPPAKey            = @"yahoo_coppa";
static NSString * const kMetaDataGDPRKey             = @"yahoo_gdprconsent";
static NSString * const kMetaDataCCPANoConsentValue  = @"1YYN";
static NSString * const kMetaDataCCPAConsentValue    = @"1YNN";

// Placement data
static NSString * const kPlacementDataServerDataKey  = @"adContent";
static NSString * const kPlacementDataWaterfallKey   = @"overrideWaterfallProvider";
static NSString * const kPlacementDataWaterfallValue = @"waterfallprovider/sideloading";

// Init state possible values
typedef NS_ENUM(NSInteger, InitState) {
    INIT_STATE_NONE,
    INIT_STATE_IN_PROGRESS,
    INIT_STATE_SUCCESS,
    INIT_STATE_FAILED
};

// Handle init callback for all adapter instances
static InitState _initState = INIT_STATE_NONE;
static ISConcurrentMutableSet<ISNetworkInitCallbackProtocol> *initCallbackDelegates = nil;

@interface ISYahooAdapter () <ISYahooRewardedVideoDelegateWrapper, ISYahooInterstitialDelegateWrapper, ISYahooBannerDelegateWrapper, ISNetworkInitCallbackProtocol>

// Rewarded video
@property (nonatomic, strong) ISConcurrentMutableDictionary *rewardedVideoPlacementIdToSmashDelegate;
@property (nonatomic, strong) ISConcurrentMutableDictionary *rewardedVideoPlacementIdToYahooAdDelegate;
@property (nonatomic, strong) ISConcurrentMutableDictionary *rewardedVideoPlacementIdToAd;
@property (nonatomic, strong) ISConcurrentMutableDictionary *rewardedVideoAdsAvailability;

// Interstitial
@property (nonatomic, strong) ISConcurrentMutableDictionary *interstitialPlacementIdToSmashDelegate;
@property (nonatomic, strong) ISConcurrentMutableDictionary *interstitialPlacementIdToYahooAdDelegate;
@property (nonatomic, strong) ISConcurrentMutableDictionary *interstitialPlacementIdToAd;
@property (nonatomic, strong) ISConcurrentMutableDictionary *interstitialAdsAvailability;

// Banner
@property (nonatomic, strong) ISConcurrentMutableDictionary *bannerPlacementIdToSmashDelegate;
@property (nonatomic, strong) ISConcurrentMutableDictionary *bannerPlacementIdToYahooAdDelegate;
@property (nonatomic, strong) ISConcurrentMutableDictionary *bannerPlacementIdToAd;
@property (nonatomic, strong) UIViewController              *bannerViewController;

@end

@implementation ISYahooAdapter

#pragma mark - IronSource Protocol Methods

// Get adapter version
- (NSString *)version {
    return kAdapterVersion;
}

// Get network sdk version
- (NSString *)sdkVersion {
    return YASAds.sdkInfo.version;
}

#pragma mark - Initializations Methods And Callbacks

- (instancetype)initAdapter:(NSString *)name {
    self = [super initAdapter:name];
    
    if (self) {
        if (initCallbackDelegates == nil) {
            initCallbackDelegates = [ISConcurrentMutableSet<ISNetworkInitCallbackProtocol> set];
        }
        
        // Rewrded video
        _rewardedVideoPlacementIdToSmashDelegate = [ISConcurrentMutableDictionary dictionary];
        _rewardedVideoPlacementIdToYahooAdDelegate = [ISConcurrentMutableDictionary dictionary];
        _rewardedVideoPlacementIdToAd = [ISConcurrentMutableDictionary dictionary];
        _rewardedVideoAdsAvailability = [ISConcurrentMutableDictionary dictionary];
        
        // Interstitial
        _interstitialPlacementIdToSmashDelegate = [ISConcurrentMutableDictionary dictionary];
        _interstitialPlacementIdToYahooAdDelegate = [ISConcurrentMutableDictionary dictionary];
        _interstitialPlacementIdToAd = [ISConcurrentMutableDictionary dictionary];
        _interstitialAdsAvailability = [ISConcurrentMutableDictionary dictionary];
        
        // Banner
        _bannerPlacementIdToSmashDelegate = [ISConcurrentMutableDictionary dictionary];
        _bannerPlacementIdToYahooAdDelegate = [ISConcurrentMutableDictionary dictionary];
        _bannerPlacementIdToAd = [ISConcurrentMutableDictionary dictionary];
        _bannerViewController = nil;
        
        // The network's capability to load a Rewarded Video ad while another Rewarded Video ad of that network is showing
        LWSState = LOAD_WHILE_SHOW_BY_INSTANCE;
    }
    
    return self;
}

- (void)initSDKWithSiteId:(NSString *)siteId {
    
    if (_initState == INIT_STATE_NONE || _initState == INIT_STATE_IN_PROGRESS) {
        [initCallbackDelegates addObject:self];
    }
    
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        LogAdapterApi_Internal(@"siteId = %@", siteId);
        
        // Init needs to be called from main thread
        dispatch_async(dispatch_get_main_queue(), ^{
            _initState = INIT_STATE_IN_PROGRESS;
            
            [YASAds setLogLevel:[ISConfigurations getConfigurations].adaptersDebug ? YASLogLevelDebug : YASLogLevelInfo];
            
            if ([YASAds initializeWithSiteId:siteId]) {
                [self initializationSuccess];
            } else {
                [self initializationFailure:@"Yahoo SDK init failed"];
            }
        });
    });
}

- (void)initializationSuccess {
    LogAdapterDelegate_Internal(@"");
    
    _initState = INIT_STATE_SUCCESS;
    
    NSArray *initDelegatesList = initCallbackDelegates.allObjects;

    for (id<ISNetworkInitCallbackProtocol> delegate in initDelegatesList) {
        [delegate onNetworkInitCallbackSuccess];
    }
    
    [initCallbackDelegates removeAllObjects];
}

- (void)initializationFailure:(NSString *)errorMsg {
    LogAdapterDelegate_Internal(@"error = %@", errorMsg);
    
    _initState = INIT_STATE_FAILED;
    
    NSArray *initDelegatesList = initCallbackDelegates.allObjects;

    for (id<ISNetworkInitCallbackProtocol> delegate in initDelegatesList) {
        [delegate onNetworkInitCallbackFailed:errorMsg];
    }
    
    [initCallbackDelegates removeAllObjects];
}

- (void)onNetworkInitCallbackSuccess {
    // Rewarded video
    NSArray *rewardedVideoPlacementIDs = _rewardedVideoPlacementIdToSmashDelegate.allKeys;
    
    for (NSString *placementId in rewardedVideoPlacementIDs) {
        id<ISRewardedVideoAdapterDelegate> delegate = [_rewardedVideoPlacementIdToSmashDelegate objectForKey:placementId];
        [delegate adapterRewardedVideoInitSuccess];
    }
    
    // Interstitial
    NSArray *interstitialPlacementIDs = _interstitialPlacementIdToSmashDelegate.allKeys;
    
    for (NSString *placementId in interstitialPlacementIDs) {
        id<ISInterstitialAdapterDelegate> delegate = [_interstitialPlacementIdToSmashDelegate objectForKey:placementId];
        [delegate adapterInterstitialInitSuccess];
    }
    
    // Banner
    NSArray *bannerPlacementIDs = _bannerPlacementIdToSmashDelegate.allKeys;
    
    for (NSString *placementId in bannerPlacementIDs) {
        id<ISBannerAdapterDelegate> delegate = [_bannerPlacementIdToSmashDelegate objectForKey:placementId];
        [delegate adapterBannerInitSuccess];
    }
}

- (void)onNetworkInitCallbackFailed:(NSString *)errorMessage {
    
    NSError *error = [ISError createErrorWithDomain:kAdapterName
                                               code:ERROR_CODE_INIT_FAILED
                                            message:errorMessage];
    
    // Rewarded video
    NSArray *rewardedVideoPlacementIDs = _rewardedVideoPlacementIdToSmashDelegate.allKeys;
    
    for (NSString *placementId in rewardedVideoPlacementIDs) {
        id<ISRewardedVideoAdapterDelegate> delegate = [_rewardedVideoPlacementIdToSmashDelegate objectForKey:placementId];
        [delegate adapterRewardedVideoInitFailed:error];
    }
    
    // Interstitial
    NSArray *interstitialPlacementIDs = _interstitialPlacementIdToSmashDelegate.allKeys;
    
    for (NSString *placementId in interstitialPlacementIDs) {
        id<ISInterstitialAdapterDelegate> delegate = [_interstitialPlacementIdToSmashDelegate objectForKey:placementId];
        [delegate adapterInterstitialInitFailedWithError:error];
    }
    
    // Banner
    NSArray *bannerPlacementIDs = _bannerPlacementIdToSmashDelegate.allKeys;
    
    for (NSString *placementId in bannerPlacementIDs) {
        id<ISBannerAdapterDelegate> delegate = [_bannerPlacementIdToSmashDelegate objectForKey:placementId];
        [delegate adapterBannerInitFailedWithError:error];
    }
}

#pragma mark - Rewarded Video API

// Used for flows when the mediation needs to get a callback for init
- (void)initRewardedVideoForCallbacksWithUserId:(NSString *)userId
                                  adapterConfig:(ISAdapterConfig *)adapterConfig
                                       delegate:(id<ISRewardedVideoAdapterDelegate>)delegate {
    NSString *siteId = adapterConfig.settings[kSiteId];
    NSString *placementId = adapterConfig.settings[kPlacementId];
    
    /* Configuration Validation */
    if (![self isConfigValueValid:placementId]) {
        NSError *error = [self errorForMissingCredentialFieldWithName:kPlacementId];
        LogAdapterApi_Internal(@"error = %@", error.description);
        [delegate adapterRewardedVideoInitFailed:error];
        return;
    }
    
    if (![self isConfigValueValid:siteId]) {
        NSError *error = [self errorForMissingCredentialFieldWithName:kSiteId];
        LogAdapterApi_Internal(@"error = %@", error.description);
        [delegate adapterRewardedVideoInitFailed:error];
        return;
    }
    
    LogAdapterApi_Internal(@"placementId = %@", placementId);
    
    // Add to rewarded video delegate map
    [self.rewardedVideoPlacementIdToSmashDelegate setObject:delegate
                                                     forKey:placementId];
    
    switch (_initState) {
        case INIT_STATE_IN_PROGRESS:
        case INIT_STATE_NONE:
            [self initSDKWithSiteId:siteId];
            break;
        case INIT_STATE_SUCCESS:
            [delegate adapterRewardedVideoInitSuccess];
            break;
        case INIT_STATE_FAILED:
            LogAdapterApi_Internal(@"init failed - placementId = %@", placementId);
            NSError *error = [NSError errorWithDomain:kAdapterName
                                                 code:ERROR_CODE_INIT_FAILED
                                             userInfo:@{NSLocalizedDescriptionKey:@"Yahoo SDK init failed"}];
            [delegate adapterRewardedVideoInitFailed:error];
            break;
    };
}

- (void)loadRewardedVideoForBiddingWithAdapterConfig:(ISAdapterConfig *)adapterConfig
                                              adData:(NSDictionary *)adData
                                          serverData:(NSString *)serverData
                                            delegate:(id<ISRewardedVideoAdapterDelegate>)delegate {
    NSString *placementId = adapterConfig.settings[kPlacementId];
    LogAdapterApi_Internal(@"placementId = %@", placementId);
    
    [self.rewardedVideoAdsAvailability setObject:@NO forKey:placementId];
    
    // Add to rewarded video delegate map
    [self.rewardedVideoPlacementIdToSmashDelegate setObject:delegate
                                                     forKey:placementId];
    
    YASInterstitialAd *rewardedVideoAd = [[YASInterstitialAd alloc] initWithPlacementId:placementId];
    ISYahooRewardedVideoDelegate *rewardedVideoAdDelegate = [[ISYahooRewardedVideoDelegate alloc] initWithPlacementId:placementId
                                                                                                          andDelegate:self];
    [self.rewardedVideoPlacementIdToYahooAdDelegate setObject:rewardedVideoAdDelegate
                                                       forKey:placementId];
    rewardedVideoAd.delegate = rewardedVideoAdDelegate;
    [self.rewardedVideoPlacementIdToAd setObject:rewardedVideoAd
                                          forKey:placementId];
    
    YASRequestMetadata *requestMetadata = [self getLoadRequestMetaDataWithServerData:serverData];
    YASInterstitialPlacementConfig *rewardedVideoConfig = [[YASInterstitialPlacementConfig alloc] initWithPlacementId:placementId
                                                                                                      requestMetadata:requestMetadata];
    
    // Load rewarded video
    [rewardedVideoAd loadWithPlacementConfig:rewardedVideoConfig];
}

- (void)showRewardedVideoWithViewController:(UIViewController *)viewController
                              adapterConfig:(ISAdapterConfig *)adapterConfig
                                   delegate:(id<ISRewardedVideoAdapterDelegate>)delegate {
    NSString *placementId = adapterConfig.settings[kPlacementId];
    LogAdapterApi_Internal(@"placementId = %@", placementId);
        
    if ([self hasRewardedVideoWithAdapterConfig:adapterConfig]) {
        [self.rewardedVideoAdsAvailability setObject:@NO
                                              forKey:placementId];
        
        dispatch_async(dispatch_get_main_queue(), ^{
            YASInterstitialAd *rewardedVideoAd = [self.rewardedVideoPlacementIdToAd objectForKey:placementId];
            [rewardedVideoAd showFromViewController:viewController];
        });
    } else {
        NSError *error = [NSError errorWithDomain:kAdapterName
                                             code:ERROR_CODE_NO_ADS_TO_SHOW
                                         userInfo:@{NSLocalizedDescriptionKey:@"No ads to show"}];
        LogAdapterApi_Internal(@"error = %@", error);
        [delegate adapterRewardedVideoDidFailToShowWithError:error];
    }
}

- (BOOL)hasRewardedVideoWithAdapterConfig:(ISAdapterConfig *)adapterConfig {
    NSString *placementId = adapterConfig.settings[kPlacementId];
    NSNumber *available = [self.rewardedVideoAdsAvailability objectForKey:placementId];
    return (available != nil) && [available boolValue];
}

- (NSDictionary *)getRewardedVideoBiddingDataWithAdapterConfig:(ISAdapterConfig *)adapterConfig
                                                        adData:(NSDictionary *)adData {
    return [self getBiddingData];
}

#pragma mark - Rewarded Video Delegate

- (void)onRewardedVideoDidLoad:(nonnull NSString *)placementId
           withRewardedVideoAd:(nonnull YASInterstitialAd *)rewardedVideoAd {
    LogAdapterDelegate_Internal(@"placementId = %@", placementId);
    [self.rewardedVideoAdsAvailability setObject:@YES
                                          forKey:placementId];
    
    id<ISRewardedVideoAdapterDelegate> delegate = [self.rewardedVideoPlacementIdToSmashDelegate objectForKey:placementId];
    [delegate adapterRewardedVideoHasChangedAvailability:YES];
}

- (void)onRewardedVideoDidFailToLoad:(nonnull NSString *)placementId
                           withError:(nonnull YASErrorInfo *)errorInfo {
    LogAdapterDelegate_Internal(@"placementId = %@, error = %@", placementId, errorInfo.description);
    id<ISRewardedVideoAdapterDelegate> delegate = [self.rewardedVideoPlacementIdToSmashDelegate objectForKey:placementId];
    [self.rewardedVideoAdsAvailability setObject:@NO
                                          forKey:placementId];
    [delegate adapterRewardedVideoHasChangedAvailability:NO];
    NSInteger errorCode = (errorInfo.code == YASCoreErrorAdNotAvailable) ? ERROR_RV_LOAD_NO_FILL : errorInfo.code;
    NSError *error = [NSError errorWithDomain:kAdapterName
                                         code:errorCode
                                     userInfo:@{NSLocalizedDescriptionKey:errorInfo.description}];
    [delegate adapterRewardedVideoDidFailToLoadWithError:error];
}

- (void)onRewardedVideoDidOpen:(nonnull NSString *)placementId {
    LogAdapterDelegate_Internal(@"placementId = %@", placementId);
    id<ISRewardedVideoAdapterDelegate> delegate = [self.rewardedVideoPlacementIdToSmashDelegate objectForKey:placementId];
    [delegate adapterRewardedVideoDidOpen];
    [delegate adapterRewardedVideoDidStart];
}

- (void)onRewardedVideoShowFail:(nonnull NSString *)placementId
                      withError:(nonnull YASErrorInfo *)errorInfo {
    LogAdapterDelegate_Internal(@"placementId = %@, error = %@", placementId, errorInfo.description);
    id<ISRewardedVideoAdapterDelegate> delegate = [self.rewardedVideoPlacementIdToSmashDelegate objectForKey:placementId];
    [delegate adapterRewardedVideoDidFailToShowWithError:errorInfo];
}

- (void)onRewardedVideoDidClick:(nonnull NSString *)placementId {
    LogAdapterDelegate_Internal(@"placementId = %@", placementId);
    id<ISRewardedVideoAdapterDelegate> delegate = [self.rewardedVideoPlacementIdToSmashDelegate objectForKey:placementId];
    [delegate adapterRewardedVideoDidClick];
}

- (void)onRewardedVideoDidReceiveReward:(nonnull NSString *)placementId {
    LogAdapterDelegate_Internal(@"placementId = %@", placementId);
    id<ISRewardedVideoAdapterDelegate> delegate = [self.rewardedVideoPlacementIdToSmashDelegate objectForKey:placementId];
    [delegate adapterRewardedVideoDidReceiveReward];
}

- (void)onRewardedVideoDidClose:(nonnull NSString *)placementId {
    LogAdapterDelegate_Internal(@"placementId = %@", placementId);
    id<ISRewardedVideoAdapterDelegate> delegate = [self.rewardedVideoPlacementIdToSmashDelegate objectForKey:placementId];
    [delegate adapterRewardedVideoDidEnd];
    [delegate adapterRewardedVideoDidClose];
}

#pragma mark - Interstitial API

- (void)initInterstitialForBiddingWithUserId:(NSString *)userId
                               adapterConfig:(ISAdapterConfig *)adapterConfig
                                    delegate:(id<ISInterstitialAdapterDelegate>)delegate {
    NSString *siteId = adapterConfig.settings[kSiteId];
    NSString *placementId = adapterConfig.settings[kPlacementId];
    
    /* Configuration Validation */
    if (![self isConfigValueValid:placementId]) {
        NSError *error = [self errorForMissingCredentialFieldWithName:kPlacementId];
        LogAdapterApi_Internal(@"error = %@", error.description);
        [delegate adapterInterstitialInitFailedWithError:error];
        return;
    }
    
    if (![self isConfigValueValid:siteId]) {
        NSError *error = [self errorForMissingCredentialFieldWithName:kSiteId];
        LogAdapterApi_Internal(@"error = %@", error.description);
        [delegate adapterInterstitialInitFailedWithError:error];
        return;
    }
    
    LogAdapterApi_Internal(@"placementId = %@", placementId);
    
    // Add to interstitial delegate map
    [self.interstitialPlacementIdToSmashDelegate setObject:delegate
                                                    forKey:placementId];
    
    switch (_initState) {
        case INIT_STATE_IN_PROGRESS:
        case INIT_STATE_NONE:
            [self initSDKWithSiteId:siteId];
            break;
        case INIT_STATE_SUCCESS:
            [delegate adapterInterstitialInitSuccess];
            break;
        case INIT_STATE_FAILED:
            LogAdapterApi_Internal(@"init failed - placementId = %@", placementId);
            NSError *error = [NSError errorWithDomain:kAdapterName
                                                 code:ERROR_CODE_INIT_FAILED
                                             userInfo:@{NSLocalizedDescriptionKey:@"Yahoo SDK init failed"}];
            [delegate adapterInterstitialInitFailedWithError:error];
            break;
    };
}

- (void)loadInterstitialForBiddingWithAdapterConfig:(ISAdapterConfig *)adapterConfig
                                             adData:(NSDictionary *)adData
                                         serverData:(NSString *)serverData
                                           delegate:(id<ISInterstitialAdapterDelegate>)delegate {
    
    NSString *placementId = adapterConfig.settings[kPlacementId];
    LogAdapterApi_Internal(@"placementId = %@", placementId);
    
    [self.interstitialAdsAvailability setObject:@NO forKey:placementId];
    
    // Add to interstitial delegate map
    [self.interstitialPlacementIdToSmashDelegate setObject:delegate
                                                    forKey:placementId];
    
    YASInterstitialAd *interstitialAd = [[YASInterstitialAd alloc] initWithPlacementId:placementId];
    ISYahooInterstitialDelegate *interstitialAdDelegate = [[ISYahooInterstitialDelegate alloc] initWithPlacementId:placementId
                                                                                                       andDelegate:self];
    [self.interstitialPlacementIdToYahooAdDelegate setObject:interstitialAdDelegate
                                                      forKey:placementId];
    interstitialAd.delegate = interstitialAdDelegate;
    [self.interstitialPlacementIdToAd setObject:interstitialAd
                                         forKey:placementId];
    
    YASRequestMetadata *requestMetadata = [self getLoadRequestMetaDataWithServerData:serverData];
    YASInterstitialPlacementConfig *interstitialConfig = [[YASInterstitialPlacementConfig alloc] initWithPlacementId:placementId
                                                                                                     requestMetadata:requestMetadata];
    
    // Load interstitial
    [interstitialAd loadWithPlacementConfig:interstitialConfig];
}

-(void)showInterstitialWithViewController:(UIViewController *)viewController
                            adapterConfig:(ISAdapterConfig *)adapterConfig
                                 delegate:(id<ISInterstitialAdapterDelegate>)delegate {
    NSString *placementId = adapterConfig.settings[kPlacementId];
    LogAdapterApi_Internal(@"placementId = %@", placementId);
    
    if ([self hasInterstitialWithAdapterConfig:adapterConfig]) {
        [self.interstitialAdsAvailability setObject:@NO
                                             forKey:placementId];
        
        dispatch_async(dispatch_get_main_queue(), ^{
            YASInterstitialAd *interstitialAd = [self.interstitialPlacementIdToAd objectForKey:placementId];
            [interstitialAd showFromViewController:viewController];
        });
    } else {
        NSError *error = [NSError errorWithDomain:kAdapterName
                                             code:ERROR_CODE_NO_ADS_TO_SHOW
                                         userInfo:@{NSLocalizedDescriptionKey:@"No ads to show"}];
        LogAdapterApi_Internal(@"error = %@", error);
        [delegate adapterInterstitialDidFailToShowWithError:error];
    }
}

- (BOOL)hasInterstitialWithAdapterConfig:(ISAdapterConfig *)adapterConfig {
    NSString *placementId = adapterConfig.settings[kPlacementId];
    NSNumber *available = [self.interstitialAdsAvailability objectForKey:placementId];
    return (placementId != nil) && [available boolValue];
}

- (NSDictionary *)getInterstitialBiddingDataWithAdapterConfig:(ISAdapterConfig *)adapterConfig
                                                       adData:(NSDictionary *)adData {
    return [self getBiddingData];
}

#pragma mark - Interstitial Delegate

- (void)onInterstitialDidLoad:(nonnull NSString *)placementId
           withInterstitialAd:(nonnull YASInterstitialAd *)interstitialAd {
    LogAdapterDelegate_Internal(@"placementId = %@", placementId);
    [self.interstitialAdsAvailability setObject:@YES
                                         forKey:placementId];
    
    id<ISInterstitialAdapterDelegate> delegate = [self.interstitialPlacementIdToSmashDelegate objectForKey:placementId];
    [delegate adapterInterstitialDidLoad];
}

- (void)onInterstitialDidFailToLoad:(nonnull NSString *)placementId
                          withError:(nonnull YASErrorInfo *)errorInfo {
    LogAdapterDelegate_Internal(@"placementId = %@, error = %@", placementId, errorInfo.description);
    [self.interstitialAdsAvailability setObject:@NO forKey:placementId];
    id<ISInterstitialAdapterDelegate> delegate = [self.interstitialPlacementIdToSmashDelegate objectForKey:placementId];
    NSInteger errorCode = (errorInfo.code == YASCoreErrorAdNotAvailable) ? ERROR_IS_LOAD_NO_FILL : errorInfo.code;
    NSError *error = [NSError errorWithDomain:kAdapterName
                                         code:errorCode
                                     userInfo:@{NSLocalizedDescriptionKey:errorInfo.description}];
    [delegate adapterInterstitialDidFailToLoadWithError:error];
}

- (void)onInterstitialDidOpen:(nonnull NSString *)placementId {
    LogAdapterDelegate_Internal(@"placementId = %@", placementId);
    id<ISInterstitialAdapterDelegate> delegate = [self.interstitialPlacementIdToSmashDelegate objectForKey:placementId];
    [delegate adapterInterstitialDidOpen];
    [delegate adapterInterstitialDidShow];
}

- (void)onInterstitialShowFail:(nonnull NSString *)placementId
                     withError:(nonnull YASErrorInfo *)errorInfo {
    LogAdapterDelegate_Internal(@"placementId = %@, error = %@", placementId, errorInfo.description);
    id<ISInterstitialAdapterDelegate> delegate = [self.interstitialPlacementIdToSmashDelegate objectForKey:placementId];
    [delegate adapterInterstitialDidFailToShowWithError:errorInfo];
}

- (void)onInterstitialDidClick:(nonnull NSString *)placementId {
    LogAdapterDelegate_Internal(@"placementId = %@", placementId);
    id<ISInterstitialAdapterDelegate> delegate = [self.interstitialPlacementIdToSmashDelegate objectForKey:placementId];
    [delegate adapterInterstitialDidClick];
}

- (void)onInterstitialDidClose:(nonnull NSString *)placementId {
    LogAdapterDelegate_Internal(@"placementId = %@", placementId);
    id<ISInterstitialAdapterDelegate> delegate = [self.interstitialPlacementIdToSmashDelegate objectForKey:placementId];
    [delegate adapterInterstitialDidClose];
}

#pragma mark - Banner API

- (void)initBannerForBiddingWithUserId:(NSString *)userId
                         adapterConfig:(ISAdapterConfig *)adapterConfig
                              delegate:(id<ISBannerAdapterDelegate>)delegate {
    NSString *siteId = adapterConfig.settings[kSiteId];
    NSString *placementId = adapterConfig.settings[kPlacementId];
    
    /* Configuration Validation */
    if (![self isConfigValueValid:placementId]) {
        NSError *error = [self errorForMissingCredentialFieldWithName:kPlacementId];
        LogAdapterApi_Internal(@"error = %@", error.description);
        [delegate adapterBannerInitFailedWithError:error];
        return;
    }
    
    if (![self isConfigValueValid:siteId]) {
        NSError *error = [self errorForMissingCredentialFieldWithName:kSiteId];
        LogAdapterApi_Internal(@"error = %@", error.description);
        [delegate adapterBannerInitFailedWithError:error];
        return;
    }
    
    LogAdapterApi_Internal(@"placementId = %@", placementId);
    
    // Add to banner delegate map
    [self.bannerPlacementIdToSmashDelegate setObject:delegate
                                              forKey:placementId];
    
    switch (_initState) {
        case INIT_STATE_IN_PROGRESS:
        case INIT_STATE_NONE:
            [self initSDKWithSiteId:siteId];
            break;
        case INIT_STATE_SUCCESS:
            [delegate adapterBannerInitSuccess];
            break;
        case INIT_STATE_FAILED:
            LogAdapterApi_Internal(@"init failed - placementId = %@", placementId);
            NSError *error = [NSError errorWithDomain:kAdapterName
                                                 code:ERROR_CODE_INIT_FAILED
                                             userInfo:@{NSLocalizedDescriptionKey:@"Yahoo SDK init failed"}];
            [delegate adapterBannerInitFailedWithError:error];
            break;
    };
}

- (void)loadBannerForBiddingWithAdapterConfig:(ISAdapterConfig *)adapterConfig
                                       adData:(NSDictionary *)adData
                                   serverData:(NSString *)serverData
                               viewController:(UIViewController *)viewController
                                         size:(ISBannerSize *)size
                                     delegate:(id <ISBannerAdapterDelegate>)delegate {
    NSString *placementId = adapterConfig.settings[kPlacementId];
    LogAdapterApi_Internal(@"placementId = %@", placementId);
    
    // Add to banner delegate map
    [self.bannerPlacementIdToSmashDelegate setObject:delegate
                                              forKey:placementId];

    
    // Hold view controller in a property to return it in Yahoo׳s callback
    _bannerViewController = (viewController != nil) ? viewController : [self topMostController];
    
    dispatch_async(dispatch_get_main_queue(), ^{
        @try {
            YASInlineAdView *bannerAd = [[YASInlineAdView alloc] initWithPlacementId:placementId];
            ISYahooBannerDelegate *bannerAdDelegate = [[ISYahooBannerDelegate alloc] initWithPlacementId:placementId
                                                                                             andDelegate:self];
            [self.bannerPlacementIdToYahooAdDelegate setObject:bannerAdDelegate
                                                        forKey:placementId];
            bannerAd.delegate = bannerAdDelegate;
            [self.bannerPlacementIdToAd setObject:bannerAd
                                           forKey:placementId];
        
            YASRequestMetadata *requestMetadata = [self getLoadRequestMetaDataWithServerData:serverData];
            NSArray<YASInlineAdSize*> *adSizes = [self getBannerSize:size];
            YASInlinePlacementConfig *bannerConfig = [[YASInlinePlacementConfig alloc] initWithPlacementId:placementId
                                                                                           requestMetadata:requestMetadata
                                                                                                   adSizes:adSizes];
            
            // Load banner
            [bannerAd loadWithPlacementConfig:bannerConfig];
        } @catch (NSException *exception) {
            LogAdapterApi_Internal(@"exception = %@", exception);
            NSError *error = [NSError errorWithDomain:kAdapterName
                                                 code:ERROR_CODE_GENERIC
                                             userInfo:@{NSLocalizedDescriptionKey:exception.description}];
            [delegate adapterBannerDidFailToLoadWithError:error];
        }
    });
}

- (void)destroyBannerWithAdapterConfig:(ISAdapterConfig *)adapterConfig {
    NSString *placementId = adapterConfig.settings[kPlacementId];
    LogAdapterApi_Internal(@"placementId = %@", placementId);
    
    YASInlineAdView *bannerAd = [self.bannerPlacementIdToAd objectForKey:placementId];
    
    if (bannerAd) {
        LogAdapterApi_Internal(@"destroy banner ad");
        // Destroy banner
        [bannerAd destroy];
        
        // Remove from dictionaries
        [self.bannerPlacementIdToAd removeObjectForKey:placementId];
        [self.bannerPlacementIdToSmashDelegate removeObjectForKey:placementId];
        [self.bannerPlacementIdToYahooAdDelegate removeObjectForKey:placementId];
    }
}

- (NSDictionary *)getBannerBiddingDataWithAdapterConfig:(ISAdapterConfig *)adapterConfig
                                                 adData:(NSDictionary *)adData {
    return [self getBiddingData];
}

#pragma mark - Banner Delegate

- (void)onBannerDidLoad:(nonnull NSString *)placementId
           withBannerAd:(nonnull YASInlineAdView *)bannerAd {
    LogAdapterDelegate_Internal(@"placementId = %@", placementId);
    id<ISBannerAdapterDelegate> delegate = [self.bannerPlacementIdToSmashDelegate objectForKey:placementId];
    
    dispatch_async(dispatch_get_main_queue(), ^{
        bannerAd.frame = CGRectMake(0, 0, bannerAd.adSize.width, bannerAd.adSize.height);
        [delegate adapterBannerDidLoad:bannerAd];
    });
}

- (void)onBannerDidFailToLoad:(nonnull NSString *)placementId
                    withError:(nonnull YASErrorInfo *)errorInfo {
    LogAdapterDelegate_Internal(@"placementId = %@, error = %@", placementId, errorInfo.description);
    id<ISBannerAdapterDelegate> delegate = [self.bannerPlacementIdToSmashDelegate objectForKey:placementId];
    NSInteger errorCode = (errorInfo.code == YASCoreErrorAdNotAvailable) ? ERROR_BN_LOAD_NO_FILL : errorInfo.code;
    NSError *error = [NSError errorWithDomain:kAdapterName
                                         code:errorCode
                                     userInfo:@{NSLocalizedDescriptionKey:errorInfo.description}];
    [delegate adapterBannerDidFailToLoadWithError:error];
}

- (void)onBannerDidShow:(nonnull NSString *)placementId {
    LogAdapterDelegate_Internal(@"placementId = %@", placementId);
    id<ISBannerAdapterDelegate> delegate = [self.bannerPlacementIdToSmashDelegate objectForKey:placementId];
    [delegate adapterBannerDidShow];
}

- (void)onBannerDidClick:(nonnull NSString *)placementId {
    LogAdapterDelegate_Internal(@"placementId = %@", placementId);
    id<ISBannerAdapterDelegate> delegate = [self.bannerPlacementIdToSmashDelegate objectForKey:placementId];
    [delegate adapterBannerDidClick];
}

- (void)onBannerBannerDidLeaveApplication:(nonnull NSString *)placementId {
    LogAdapterDelegate_Internal(@"placementId = %@", placementId);
    id<ISBannerAdapterDelegate> delegate = [self.bannerPlacementIdToSmashDelegate objectForKey:placementId];
    [delegate adapterBannerWillLeaveApplication];
}

- (void)onBannerDidPresentScreen:(nonnull NSString *)placementId {
    LogAdapterDelegate_Internal(@"placementId = %@", placementId);
    id<ISBannerAdapterDelegate> delegate = [self.bannerPlacementIdToSmashDelegate objectForKey:placementId];
    [delegate adapterBannerWillPresentScreen];
}

- (void)onBannerDidDismissScreen:(nonnull NSString *)placementId {
    LogAdapterDelegate_Internal(@"placementId = %@", placementId);
    id<ISBannerAdapterDelegate> delegate = [self.bannerPlacementIdToSmashDelegate objectForKey:placementId];
    [delegate adapterBannerDidDismissScreen];
}

- (UIViewController *)bannerPresentingViewController {
    return _bannerViewController;
}

#pragma mark - Legal Methods

- (void)setMetaDataWithKey:(NSString *)key
                 andValues:(NSMutableArray *)values {
    if (values.count == 0) {
        return;
    }
    
    // This is an array of 1 value
    NSString *value = values[0];
    LogAdapterApi_Internal(@"key = %@, value = %@", key, value);
    
    if ([ISMetaDataUtils isValidCCPAMetaDataWithKey:key
                                           andValue:value]) {
        [self setCCPAValue:[ISMetaDataUtils getMetaDataBooleanValue:value]];
        
    } else if ([ISMetaDataUtils isValidMetaDataWithKey:key
                                                  flag:kMetaDataGDPRKey
                                              andValue:value]) {
        [self setGDPRConsentString:value];
        
    } else {
        NSString *formattedValue = [ISMetaDataUtils formatValue:value
                                                        forType:(META_DATA_VALUE_BOOL)];
            
        if ([ISMetaDataUtils isValidMetaDataWithKey:key
                                               flag:kMetaDataCOPPAKey
                                           andValue:value]) {
            [self setCOPPAValue:[ISMetaDataUtils getMetaDataBooleanValue:formattedValue]];
        }
    }
}

- (void)setCCPAValue:(BOOL)value {
    NSString *ccpaConsentString = (value) ? kMetaDataCCPANoConsentValue : kMetaDataCCPAConsentValue;
    LogAdapterApi_Internal(@"value = %@", ccpaConsentString);
    
    [YASAds.sharedInstance applyCcpa];
    YASCcpaConsent *ccpaConsent = [[YASCcpaConsent alloc] initWithConsentString:ccpaConsentString];
    [YASAds.sharedInstance addConsent:ccpaConsent];
}

- (void)setGDPRConsentString:(NSString *)consentString {
    LogAdapterApi_Internal(@"consentString = %@", consentString);
    [YASAds.sharedInstance applyGdpr];
    YASGdprConsent *gdprConsent = [[YASGdprConsent alloc] initWithConsentString:consentString];
    [YASAds.sharedInstance addConsent:gdprConsent];
}

- (void)setCOPPAValue:(BOOL)value {
    LogAdapterApi_Internal(@"value = %@", value ? @"YES" : @"NO");
    
    if (value) {
        [YASAds.sharedInstance applyCoppa];
    }
}

#pragma mark - Helper Methods

- (NSDictionary *)getBiddingData {
    if (_initState != INIT_STATE_SUCCESS) {
        LogAdapterApi_Internal(@"returning nil as token since init isn't successful");
        return nil;
    }
    
    NSString *bidderToken = [[YASAds sharedInstance] biddingTokenTrimmedToSize:0];
    NSString *returnedToken = bidderToken? bidderToken : @"";
    LogAdapterApi_Internal(@"token = %@", returnedToken);
    return @{@"token": returnedToken};
}

- (NSArray<YASInlineAdSize*> *)getBannerSize:(ISBannerSize *)size {
    YASInlineAdSize *bannerSize = [YASInlineAdSize alloc];
    NSArray<YASInlineAdSize*> *arrayBannerSize;
    
    if ([size.sizeDescription isEqualToString:@"BANNER"]) {
        bannerSize = [bannerSize initWithWidth:320
                                        height:50];
    } else if ([size.sizeDescription isEqualToString:@"LARGE"]) {
        bannerSize = [bannerSize initWithWidth:320
                                        height:90];
    } else if ([size.sizeDescription isEqualToString:@"RECTANGLE"]) {
        bannerSize = [bannerSize initWithWidth:300
                                        height:250];
    } else if ([size.sizeDescription isEqualToString:@"SMART"]) {
        if (UI_USER_INTERFACE_IDIOM() == UIUserInterfaceIdiomPad) {
            bannerSize = [bannerSize initWithWidth:728
                                            height:90];
        } else {
            bannerSize = [bannerSize initWithWidth:320
                                            height:50];
        }
    } else if ([size.sizeDescription isEqualToString:@"CUSTOM"]) {
        bannerSize = [bannerSize initWithWidth:size.width
                                        height:size.height];
    }
    
    arrayBannerSize = [[NSArray alloc] initWithObjects:bannerSize, nil];
    return arrayBannerSize;
}

- (YASRequestMetadata *)getLoadRequestMetaDataWithServerData:(NSString *)serverData {
    YASRequestMetadataBuilder *metadataBuilder = [[YASRequestMetadataBuilder alloc] initWithRequestMetadata:[YASAds sharedInstance].requestMetadata];
    
    // Add ironSource identifier and SDK version to bid requests
    [metadataBuilder setMediator:[NSString stringWithFormat:@"%@ %@", kMediationName, kAdapterVersion]];
    
    NSMutableDictionary<NSString *, id> *placementData = [NSMutableDictionary dictionaryWithDictionary: @{kPlacementDataServerDataKey : serverData, kPlacementDataWaterfallKey: kPlacementDataWaterfallValue}];
    [metadataBuilder setPlacementData:placementData];
    
    return metadataBuilder.build;
}

@end

