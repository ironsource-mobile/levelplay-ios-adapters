//
// Copyright © 2022 ironSource Mobile Ltd. All rights reserved.
//

#import "ISChartboostAdapter.h"
#import "ISChartboostInterstitialDelegate.h"
#import "ISChartboostRewardedVideoDelegate.h"
#import "ISChartboostBannerDelegate.h"
#import <ChartboostSDK/ChartboostSDK.h>

// Mediation info
static NSString * const kMediationName              = @"ironSource";
static CHBMediation *_mediationInfo = nil;

// Network keys
static NSString * const kAdapterVersion             = ChartboostAdapterVersion;
static NSString * const kAdapterName                = @"Chartboost";
static NSString * const kAppSignature               = @"appSignature";
static NSString * const kLocationId                 = @"adLocation";
static NSString * const kAppID                      = @"appID";


// init state possible values
typedef NS_ENUM(NSInteger, InitState) {
    INIT_STATE_NONE,
    INIT_STATE_IN_PROGRESS,
    INIT_STATE_SUCCESS,
    INIT_STATE_FAILED
};

// Handle init callback for all adapter instances
static InitState _initState = INIT_STATE_NONE;
static ConcurrentMutableSet<ISNetworkInitCallbackProtocol> *initCallbackDelegates = nil;

@interface ISChartboostAdapter () <ISChartboostInterstitialDelegateWrapper, ISChartboostRewardedVideoDelegateWrapper, ISChartboostBannerDelegateWrapper, ISNetworkInitCallbackProtocol>

// rewarded video
@property (nonatomic, strong) ConcurrentMutableDictionary *rewardedVideoLocationIdToSmashDelegate;
@property (nonatomic, strong) ConcurrentMutableDictionary *rewardedVideoLocationIdToChartboostAdDelegate;
@property (nonatomic, strong) ConcurrentMutableDictionary *rewardedVideoLocationIdToAd;
@property (nonatomic, strong) ConcurrentMutableSet        *rewardedVideoLocationIdsForInitCallbacks;

// interstitial
@property (nonatomic, strong) ConcurrentMutableDictionary *interstitialLocationIdToSmashDelegate;
@property (nonatomic, strong) ConcurrentMutableDictionary *interstitialLocationIdToChartboostAdDelegate;
@property (nonatomic, strong) ConcurrentMutableDictionary *interstitialLocationIdToAd;

// banner
@property (nonatomic, strong) ConcurrentMutableDictionary *bannerLocationIdToSmashDelegate;
@property (nonatomic, strong) ConcurrentMutableDictionary *bannerLocationIdToChartboostAdDelegate;
@property (nonatomic, strong) ConcurrentMutableDictionary *bannerLocationIdToAd;
@property (nonatomic, strong) ConcurrentMutableDictionary *bannerLocationIdToViewController;
@property (nonatomic, strong) ConcurrentMutableDictionary *bannerLocationIdToSize;

@end

@implementation ISChartboostAdapter

#pragma mark - IronSource Protocol Methods

// get adapter version
- (NSString *)version {
    return kAdapterVersion;
}

//get network sdk version
- (NSString *)sdkVersion {
    return [Chartboost getSDKVersion];
}

- (NSArray *)systemFrameworks {
    return @[@"AdSupport", @"AVFoundation", @"CoreGraphics", @"CoreMedia", @"Foundation", @"StoreKit", @"UIKit", @"WebKit"];
}

- (NSString *)sdkName {
    return @"Chartboost";
}

#pragma mark - Initializations Methods And Callbacks

- (instancetype)initAdapter:(NSString *)name {
    self = [super initAdapter:name];
    
    if (self) {
        if (initCallbackDelegates == nil) {
            initCallbackDelegates = [ConcurrentMutableSet<ISNetworkInitCallbackProtocol> set];
        }
        
        // rewarded video
        _rewardedVideoLocationIdToSmashDelegate = [ConcurrentMutableDictionary dictionary];
        _rewardedVideoLocationIdToChartboostAdDelegate = [ConcurrentMutableDictionary dictionary];
        _rewardedVideoLocationIdToAd = [ConcurrentMutableDictionary dictionary];
        _rewardedVideoLocationIdsForInitCallbacks = [ConcurrentMutableSet set];
        
        // interstitial
        _interstitialLocationIdToSmashDelegate = [ConcurrentMutableDictionary dictionary];
        _interstitialLocationIdToChartboostAdDelegate = [ConcurrentMutableDictionary dictionary];
        _interstitialLocationIdToAd = [ConcurrentMutableDictionary dictionary];

        // banner
        _bannerLocationIdToSmashDelegate = [ConcurrentMutableDictionary dictionary];
        _bannerLocationIdToChartboostAdDelegate = [ConcurrentMutableDictionary dictionary];
        _bannerLocationIdToAd = [ConcurrentMutableDictionary dictionary];
        _bannerLocationIdToViewController = [ConcurrentMutableDictionary dictionary];
        _bannerLocationIdToSize = [ConcurrentMutableDictionary dictionary];
        
        // The network's capability to load a Rewarded Video ad while another Rewarded Video ad of that network is showing
        LWSState = LOAD_WHILE_SHOW_BY_NETWORK;
    }
    
    return self;
}

- (void)initSDKWithAppId:(NSString *)appId
            appSignature:(NSString *)appSignature {

    // add self to the init delegates only in case the initialization has not finished yet
    if ((_initState == INIT_STATE_NONE) || (_initState == INIT_STATE_IN_PROGRESS)) {
        [initCallbackDelegates addObject:self];
    }
    
    static dispatch_once_t initToken;
    dispatch_once(&initToken, ^{
        _initState = INIT_STATE_IN_PROGRESS;
            
        LogAdapterApi_Internal(@"appId = %@ - appSignature = %@", appId, appSignature);

        CBLoggingLevel logLevel = ([ISConfigurations getConfigurations].adaptersDebug) ? CBLoggingLevelVerbose : CBLoggingLevelError;
        [Chartboost setLoggingLevel:logLevel];

        [Chartboost startWithAppID:appId
                      appSignature:appSignature
                        completion:^(CHBStartError * _Nullable error) {
            if (!error) {
                [self initSuccess];
            } else {
                [self initFailedWithError:error];
            }
        }];
    });
}

- (void)initSuccess {
    LogAdapterDelegate_Internal(@"");
    _initState = INIT_STATE_SUCCESS;
    
    NSArray *initDelegatesList = initCallbackDelegates.allObjects;

    for (id<ISNetworkInitCallbackProtocol> delegate in initDelegatesList) {
        [delegate onNetworkInitCallbackSuccess];
    }
    
    [initCallbackDelegates removeAllObjects];
}

- (void)initFailedWithError:(NSError *)error {
    LogAdapterDelegate_Internal(@"error = %@", error.description);

    _initState = INIT_STATE_FAILED;
    
    NSArray *initDelegatesList = initCallbackDelegates.allObjects;

    for (id<ISNetworkInitCallbackProtocol> delegate in initDelegatesList) {
        NSString *errorReason = [NSString stringWithFormat:@"Chartboost SDK init failed - %@", (error ? error.localizedDescription : @"")];
        [delegate onNetworkInitCallbackFailed:errorReason];
    }
    
    [initCallbackDelegates removeAllObjects];
}

- (void)onNetworkInitCallbackSuccess {
    
    // rewarded video
    NSArray *rewardedVideoLocationIDs = _rewardedVideoLocationIdToSmashDelegate.allKeys;

    for (NSString *locationId in rewardedVideoLocationIDs) {
        id<ISRewardedVideoAdapterDelegate> delegate = [_rewardedVideoLocationIdToSmashDelegate objectForKey:locationId];
        if ([_rewardedVideoLocationIdsForInitCallbacks hasObject:locationId]) {
            [delegate adapterRewardedVideoInitSuccess];
        } else {
            [self loadRewardedVideoInternal:locationId
                                   delegate:delegate];
        }
    }
    
    // interstitial
    NSArray *interstitialLocationIDs = _interstitialLocationIdToSmashDelegate.allKeys;

    for (NSString *locationId in interstitialLocationIDs) {
        id<ISInterstitialAdapterDelegate> delegate = [_interstitialLocationIdToSmashDelegate objectForKey:locationId];
        [delegate adapterInterstitialInitSuccess];
    }
    
    // banners
    NSArray *bannerLocationIDs = _bannerLocationIdToSmashDelegate.allKeys;

    for (NSString *locationId in bannerLocationIDs) {
        id<ISBannerAdapterDelegate> delegate = [_bannerLocationIdToSmashDelegate objectForKey:locationId];
        [delegate adapterBannerInitSuccess];
    }
}

- (void)onNetworkInitCallbackFailed:(nonnull NSString *)errorMessage {
    NSError *error = [NSError errorWithDomain:kAdapterName
                                         code:ERROR_CODE_INIT_FAILED
                                     userInfo:@{NSLocalizedDescriptionKey:errorMessage}];
    
    // rewarded video
    NSArray *rewardedVideoLocationIDs = _rewardedVideoLocationIdToSmashDelegate.allKeys;

    for (NSString *locationId in rewardedVideoLocationIDs) {
        id<ISRewardedVideoAdapterDelegate> delegate = [_rewardedVideoLocationIdToSmashDelegate objectForKey:locationId];
        if ([_rewardedVideoLocationIdsForInitCallbacks hasObject:locationId]) {
            [delegate adapterRewardedVideoInitFailed:error];
        } else {
            [delegate adapterRewardedVideoHasChangedAvailability:NO];
        }
    }
    
    // interstitial
    NSArray *interstitialLocationIDs = _interstitialLocationIdToSmashDelegate.allKeys;

    for (NSString *locationId in interstitialLocationIDs) {
        id<ISInterstitialAdapterDelegate> delegate = [_interstitialLocationIdToSmashDelegate objectForKey:locationId];
        [delegate adapterInterstitialInitFailedWithError:error];
    }
    
    // banners
    NSArray *bannerLocationIDs = _bannerLocationIdToSmashDelegate.allKeys;

    for (NSString *locationId in bannerLocationIDs) {
        id<ISBannerAdapterDelegate> delegate = [_bannerLocationIdToSmashDelegate objectForKey:locationId];
        [delegate adapterBannerInitFailedWithError:error];
    }
}

#pragma mark - Rewarded Video API

// used for flows when the mediation needs to get a callback for init
- (void)initRewardedVideoForCallbacksWithUserId:(NSString *)userId
                                  adapterConfig:(ISAdapterConfig *)adapterConfig
                                       delegate:(id<ISRewardedVideoAdapterDelegate>)delegate {
    
    NSString *appId = adapterConfig.settings[kAppID];
    NSString *appSignature = adapterConfig.settings[kAppSignature];
    NSString *locationId = adapterConfig.settings[kLocationId];

    /* Configuration Validation */
    if (![self isConfigValueValid:appId]) {
        NSError *error = [self errorForMissingCredentialFieldWithName:kAppID];
        LogAdapterApi_Internal(@"error = %@", error.description);
        [delegate adapterRewardedVideoInitFailed:error];
        return;
    }
    
    
    if (![self isConfigValueValid:appSignature]) {
        NSError *error = [self errorForMissingCredentialFieldWithName:kAppSignature];
        LogAdapterApi_Internal(@"error = %@", error.description);
        [delegate adapterRewardedVideoInitFailed:error];
        return;
    }
    
    if (![self isConfigValueValid:locationId]) {
        NSError *error = [self errorForMissingCredentialFieldWithName:kLocationId];
        LogAdapterApi_Internal(@"error = %@", error.description);
        [delegate adapterRewardedVideoInitFailed:error];
        return;
    }
    
    LogAdapterApi_Internal(@"locationId = %@", locationId);
    
    ISChartboostRewardedVideoDelegate *rewardedVideoDelegate = [[ISChartboostRewardedVideoDelegate alloc] initWithLocationId:locationId
                                                                                                                 andDelegate:self];

    //add to rewarded video delegate map
    [_rewardedVideoLocationIdToChartboostAdDelegate setObject:rewardedVideoDelegate
                                                       forKey:locationId];
    
    [_rewardedVideoLocationIdToSmashDelegate setObject:delegate
                                                forKey:locationId];
    
    [_rewardedVideoLocationIdsForInitCallbacks addObject:locationId];
    
    switch (_initState) {
        case INIT_STATE_NONE:
        case INIT_STATE_IN_PROGRESS:
            [self initSDKWithAppId:appId
                      appSignature:appSignature];
            break;
        case INIT_STATE_SUCCESS: {
            [delegate adapterRewardedVideoInitSuccess];
            break;
        }
        case INIT_STATE_FAILED: {
            LogAdapterApi_Internal(@"init failed - locationId = %@", locationId);
            NSError *error = [NSError errorWithDomain:kAdapterName
                                                 code:ERROR_CODE_INIT_FAILED
                                             userInfo:@{NSLocalizedDescriptionKey:@"Chartboost SDK init failed"}];
            [delegate adapterRewardedVideoInitFailed:error];
            break;
        }
    }
}

// used for flows when the mediation doesn't need to get a callback for init
- (void)initAndLoadRewardedVideoWithUserId:(NSString *)userId
                             adapterConfig:(ISAdapterConfig *)adapterConfig
                                  delegate:(id<ISRewardedVideoAdapterDelegate>)delegate {

    NSString *appId = adapterConfig.settings[kAppID];
    NSString *appSignature = adapterConfig.settings[kAppSignature];
    NSString *locationId = adapterConfig.settings[kLocationId];

    /* Configuration Validation */
    if (![self isConfigValueValid:appId]) {
        NSError *error = [self errorForMissingCredentialFieldWithName:kAppID];
        LogAdapterApi_Internal(@"failed - error.description = %@", error.description);
        [delegate adapterRewardedVideoHasChangedAvailability:NO];
        return;
    }
    
    if (![self isConfigValueValid:appSignature]) {
        NSError *error = [self errorForMissingCredentialFieldWithName:kAppSignature];
        LogAdapterApi_Internal(@"failed - error.description = %@", error.description);
        [delegate adapterRewardedVideoHasChangedAvailability:NO];
        return;
    }
    
    if (![self isConfigValueValid:locationId]) {
        NSError *error = [self errorForMissingCredentialFieldWithName:kLocationId];
        LogAdapterApi_Internal(@"failed - error.description = %@", error.description);
        [delegate adapterRewardedVideoHasChangedAvailability:NO];
        return;
    }
    
    LogAdapterApi_Internal(@"locationId = %@", locationId);
    
    ISChartboostRewardedVideoDelegate *rewardedVideoDelegate = [[ISChartboostRewardedVideoDelegate alloc] initWithLocationId:locationId
                                                                                                                 andDelegate:self];

    //add to rewarded video delegate map
    [_rewardedVideoLocationIdToChartboostAdDelegate setObject:rewardedVideoDelegate
                                                       forKey:locationId];
    
    [_rewardedVideoLocationIdToSmashDelegate setObject:delegate
                                                forKey:locationId];
    
    switch (_initState) {
        case INIT_STATE_NONE:
        case INIT_STATE_IN_PROGRESS:
            [self initSDKWithAppId:appId
                      appSignature:appSignature];
            break;
        case INIT_STATE_SUCCESS: {
            [self loadRewardedVideoInternal:locationId
                                   delegate:delegate];
            break;
        }
        case INIT_STATE_FAILED:
            LogAdapterApi_Internal(@"init failed - locationId = %@", locationId);
            [delegate adapterRewardedVideoHasChangedAvailability:NO];
            break;
    }
}


- (void)fetchRewardedVideoForAutomaticLoadWithAdapterConfig:(ISAdapterConfig *)adapterConfig
                                                   delegate:(id<ISRewardedVideoAdapterDelegate>)delegate {
    NSString *locationId = adapterConfig.settings[kLocationId];
    
    [self loadRewardedVideoInternal:locationId
                           delegate:delegate];
}

- (void)loadRewardedVideoInternal:(NSString *)locationId
                         delegate:(id<ISRewardedVideoAdapterDelegate>)delegate {

    LogAdapterApi_Internal(@"locationId = %@", locationId);
    
    CHBRewarded *rewardedVideoAd = [self getRewardedVideAdForLocationId:locationId];
    
    if (rewardedVideoAd) {
        // Load rewarded video
        [rewardedVideoAd cache];
    } else {
        [delegate adapterRewardedVideoHasChangedAvailability:NO];
    }
}

- (void)showRewardedVideoWithViewController:(UIViewController *)viewController
                              adapterConfig:(ISAdapterConfig *)adapterConfig
                                   delegate:(id<ISRewardedVideoAdapterDelegate>)delegate {
    
    NSString *locationId = adapterConfig.settings[kLocationId];
    LogAdapterApi_Internal(@"locationId = %@", locationId);
    
    [delegate adapterRewardedVideoHasChangedAvailability:NO];
    
    CHBRewarded *rewardedVideoAd = [_rewardedVideoLocationIdToAd objectForKey:locationId];
    
    if ([self hasRewardedVideoWithAdapterConfig:adapterConfig]) {
        [rewardedVideoAd showFromViewController:viewController];
        
    } else {
        NSError *error = [NSError errorWithDomain:kAdapterName
                                             code:ERROR_CODE_NO_ADS_TO_SHOW
                                         userInfo:@{NSLocalizedDescriptionKey:@"No ads to show"}];
        LogAdapterApi_Internal(@"error = %@", error);
        [delegate adapterRewardedVideoDidFailToShowWithError:error];
    }
}

- (BOOL)hasRewardedVideoWithAdapterConfig:(ISAdapterConfig *)adapterConfig {
    NSString *locationId = adapterConfig.settings[kLocationId];
    CHBRewarded *rewardedVideoAd = [_rewardedVideoLocationIdToAd objectForKey:locationId];
    return ((rewardedVideoAd != nil) && rewardedVideoAd.isCached);
}

#pragma mark - Rewarded Video Delegate

- (void)onRewardedVideoDidLoad:(nonnull NSString *)locationId {
    LogAdapterDelegate_Internal(@"locationId = %@", locationId);
    id<ISRewardedVideoAdapterDelegate> delegate = [_rewardedVideoLocationIdToSmashDelegate objectForKey:locationId];
    
    if (delegate) {
        [delegate adapterRewardedVideoHasChangedAvailability:YES];
    }
}

- (void)onRewardedVideoDidFailToLoad:(nonnull NSString *)locationId
                           withError:(nonnull CHBCacheError *)error {
    LogAdapterDelegate_Internal(@"locationId = %@, error = %@", locationId, error.description);
    id<ISRewardedVideoAdapterDelegate> delegate = [_rewardedVideoLocationIdToSmashDelegate objectForKey:locationId];

    if (delegate) {
        [delegate adapterRewardedVideoHasChangedAvailability:NO];
        
        NSInteger errorCode = (error.code == CHBCacheErrorCodeNoAdFound) ? ERROR_RV_LOAD_NO_FILL : error.code;
        NSError *smashError = [NSError errorWithDomain:kAdapterName
                                                  code:errorCode
                                              userInfo:@{NSLocalizedDescriptionKey:error.description}];
        
        [delegate adapterRewardedVideoDidFailToLoadWithError:smashError];
    }
}

- (void)onRewardedVideoDidOpen:(nonnull NSString *)locationId {
    LogAdapterDelegate_Internal(@"locationId = %@", locationId);
    id<ISRewardedVideoAdapterDelegate> delegate = [_rewardedVideoLocationIdToSmashDelegate objectForKey:locationId];

    if (delegate) {
        [delegate adapterRewardedVideoDidOpen];
        [delegate adapterRewardedVideoDidStart];
    }
}

- (void)onRewardedVideoShowFail:(nonnull NSString *)locationId
                      withError:(nonnull CHBShowError *)error {
    LogAdapterDelegate_Internal(@"locationId = %@, error = %@", locationId, error.description);
    id<ISRewardedVideoAdapterDelegate> delegate = [_rewardedVideoLocationIdToSmashDelegate objectForKey:locationId];

    if (delegate) {
        NSError *smashError = [NSError errorWithDomain:kAdapterName
                                                  code:error.code
                                              userInfo:@{NSLocalizedDescriptionKey: error.description}];
        [delegate adapterRewardedVideoDidFailToShowWithError:smashError];
    }
}

- (void)onRewardedVideoDidClick:(nonnull NSString *)locationId
                      withError:(nullable CHBClickError *)error {
    LogAdapterDelegate_Internal(@"locationId = %@", locationId);
    id<ISRewardedVideoAdapterDelegate> delegate = [_rewardedVideoLocationIdToSmashDelegate objectForKey:locationId];

    if (delegate) {
        [delegate adapterRewardedVideoDidClick];
        
        if (error) {
            LogAdapterDelegate_Internal(@"error = %@", error.description);
        }
    }
}

- (void)onRewardedVideoDidReceiveReward:(nonnull NSString *)locationId {
    LogAdapterDelegate_Internal(@"locationId = %@", locationId);
    id<ISRewardedVideoAdapterDelegate> delegate = [_rewardedVideoLocationIdToSmashDelegate objectForKey:locationId];

    if (delegate) {
        [delegate adapterRewardedVideoDidReceiveReward];
    }
}

- (void)onRewardedVideoDidEnd:(nonnull NSString *)locationId {
    LogAdapterDelegate_Internal(@"locationId = %@", locationId);
    id<ISRewardedVideoAdapterDelegate> delegate = [_rewardedVideoLocationIdToSmashDelegate objectForKey:locationId];

    if (delegate) {
        [delegate adapterRewardedVideoDidEnd];
    }
}

- (void)onRewardedVideoDidClose:(nonnull NSString *)locationId {
    LogAdapterDelegate_Internal(@"locationId = %@", locationId);
    id<ISRewardedVideoAdapterDelegate> delegate = [_rewardedVideoLocationIdToSmashDelegate objectForKey:locationId];

    if (delegate) {
        [delegate adapterRewardedVideoDidClose];
    }
}

#pragma mark - Interstitial API

- (void)initInterstitialWithUserId:(NSString *)userId
                     adapterConfig:(ISAdapterConfig *)adapterConfig
                          delegate:(id<ISInterstitialAdapterDelegate>)delegate {

    NSString *appId = adapterConfig.settings[kAppID];
    NSString *appSignature = adapterConfig.settings[kAppSignature];
    NSString *locationId = adapterConfig.settings[kLocationId];

    /* Configuration Validation */
    if (![self isConfigValueValid:appId]) {
        NSError *error = [self errorForMissingCredentialFieldWithName:kAppID];
        LogAdapterApi_Internal(@"error = %@", error.description);
        [delegate adapterInterstitialInitFailedWithError:error];
        return;
    }
    
    if (![self isConfigValueValid:appSignature]) {
        NSError *error = [self errorForMissingCredentialFieldWithName:kAppSignature];
        LogAdapterApi_Internal(@"error = %@", error.description);
        [delegate adapterInterstitialInitFailedWithError:error];
        return;
    }

    if (![self isConfigValueValid:locationId]) {
        NSError *error = [self errorForMissingCredentialFieldWithName:kLocationId];
        LogAdapterApi_Internal(@"error = %@", error.description);
        [delegate adapterInterstitialInitFailedWithError:error];
        return;
    }
    
    LogAdapterApi_Internal(@"locationId = %@", locationId);
    
    ISChartboostInterstitialDelegate *interstitialDelegate = [[ISChartboostInterstitialDelegate alloc] initWithLocationId:locationId
                                                                                                              andDelegate:self];
    
    //add to interstitial delegate map
    [_interstitialLocationIdToChartboostAdDelegate setObject:interstitialDelegate
                                                      forKey:locationId];
    
    [_interstitialLocationIdToSmashDelegate setObject:delegate
                                               forKey:locationId];
    
    switch (_initState) {
        case INIT_STATE_NONE:
        case INIT_STATE_IN_PROGRESS:
            [self initSDKWithAppId:appId
                      appSignature:appSignature];
            break;
        case INIT_STATE_SUCCESS:
            [delegate adapterInterstitialInitSuccess];
            break;
        case INIT_STATE_FAILED: {
            LogAdapterApi_Internal(@"init failed - locationId = %@", locationId);
            NSError *error = [NSError errorWithDomain:kAdapterName
                                                 code:ERROR_CODE_INIT_FAILED
                                             userInfo:@{NSLocalizedDescriptionKey:@"Chartboost SDK init failed"}];
            [delegate adapterInterstitialInitFailedWithError:error];
            break;
        }
    }
}

- (void)loadInterstitialWithAdapterConfig:(ISAdapterConfig *)adapterConfig
                                 delegate:(id<ISInterstitialAdapterDelegate>)delegate {
    NSString *locationId = adapterConfig.settings[kLocationId];
    LogAdapterApi_Internal(@"locationId = %@", locationId);
    
    CHBInterstitial *interstitialAd = [self getInterstitialAdForLocationId:locationId];

    if (interstitialAd) {
        // Load interstitial
        [interstitialAd cache];
        
    } else {
        NSError *error = [NSError errorWithDomain:kAdapterName
                                             code:ERROR_CODE_GENERIC
                                         userInfo:@{NSLocalizedDescriptionKey:@"load interstitial failed"}];
        LogAdapterApi_Internal(@"error = %@", error);
        [delegate adapterInterstitialDidFailToLoadWithError:error];
    }
}

- (void)showInterstitialWithViewController:(UIViewController *)viewController
                             adapterConfig:(ISAdapterConfig *)adapterConfig
                                  delegate:(id<ISInterstitialAdapterDelegate>)delegate {
    NSString *locationId = adapterConfig.settings[kLocationId];
    LogAdapterApi_Internal(@"locationId = %@", locationId);
    
    CHBInterstitial *interstitialAd = [_interstitialLocationIdToAd objectForKey:locationId];
    
    if ([self hasInterstitialWithAdapterConfig:adapterConfig]) {
        [interstitialAd showFromViewController:viewController];
        
    } else {
        NSError *error = [NSError errorWithDomain:kAdapterName
                                             code:ERROR_CODE_NO_ADS_TO_SHOW
                                         userInfo:@{NSLocalizedDescriptionKey:@"No ads to show"}];
        LogAdapterApi_Internal(@"error = %@", error);
        [delegate adapterInterstitialDidFailToShowWithError:error];
    }
}

- (BOOL) hasInterstitialWithAdapterConfig:(ISAdapterConfig *)adapterConfig {
    NSString *locationId = adapterConfig.settings[kLocationId];
    CHBInterstitial *interstitialAd = [_interstitialLocationIdToAd objectForKey:locationId];
    return ((interstitialAd != nil) && interstitialAd.isCached);
}

#pragma mark - Interstitial Delegate

- (void)onInterstitialDidLoad:(nonnull NSString *)locationId {
    LogAdapterDelegate_Internal(@"locationId = %@", locationId);
    id<ISInterstitialAdapterDelegate> delegate = [_interstitialLocationIdToSmashDelegate objectForKey:locationId];
    
    if (delegate) {
        [delegate adapterInterstitialDidLoad];
    }
}

- (void)onInterstitialDidFailToLoad:(nonnull NSString *)locationId
                          withError:(nonnull CHBCacheError *)error {
    LogAdapterDelegate_Internal(@"locationId = %@, error = %@", locationId, error.description);
    id<ISInterstitialAdapterDelegate> delegate = [_interstitialLocationIdToSmashDelegate objectForKey:locationId];

    if (delegate) {
        NSInteger errorCode = (error.code == CHBCacheErrorCodeNoAdFound) ? ERROR_IS_LOAD_NO_FILL : error.code;
        NSError *smashError = [NSError errorWithDomain:kAdapterName
                                                  code:errorCode
                                              userInfo:@{NSLocalizedDescriptionKey: error.description}];
        
        [delegate adapterInterstitialDidFailToLoadWithError:smashError];
    }
}

- (void)onInterstitialDidOpen:(NSString *)locationId {
    LogAdapterDelegate_Internal(@"locationId = %@", locationId);
    id<ISInterstitialAdapterDelegate> delegate = [_interstitialLocationIdToSmashDelegate objectForKey:locationId];

    if (delegate) {
        [delegate adapterInterstitialDidOpen];
        [delegate adapterInterstitialDidShow];
    }
}

- (void)onInterstitialShowFail:(nonnull NSString *)locationId
                     withError:(nonnull CHBShowError *)error {
    LogAdapterDelegate_Internal(@"locationId = %@, error = %@", locationId, error.description);
    id<ISInterstitialAdapterDelegate> delegate = [_interstitialLocationIdToSmashDelegate objectForKey:locationId];

    if (delegate) {
        NSError *smashError = [NSError errorWithDomain:kAdapterName
                                                  code:error.code
                                              userInfo:@{NSLocalizedDescriptionKey:error.description}];
        [delegate adapterInterstitialDidFailToShowWithError:smashError];
    }
}

- (void)onInterstitialDidClick:(nonnull NSString *)locationId
                     withError:(nullable CHBClickError *)error {

    LogAdapterDelegate_Internal(@"locationId = %@", locationId);
    id<ISInterstitialAdapterDelegate> delegate = [_interstitialLocationIdToSmashDelegate objectForKey:locationId];

    if (delegate) {
        [delegate adapterInterstitialDidClick];
        
        if (error) {
            LogAdapterDelegate_Internal(@"error = %@", error.description);
        }
    }
}

- (void)onInterstitialDidClose:(nonnull NSString *)locationId {
    LogAdapterDelegate_Internal(@"locationId = %@", locationId);
    id<ISInterstitialAdapterDelegate> delegate = [_interstitialLocationIdToSmashDelegate objectForKey:locationId];

    if (delegate) {
        [delegate adapterInterstitialDidClose];
    }
}

#pragma mark - Banner API

- (void)initBannerWithUserId:(nonnull NSString *)userId
               adapterConfig:(nonnull ISAdapterConfig *)adapterConfig
                    delegate:(nonnull id<ISBannerAdapterDelegate>)delegate {

    NSString *appId = adapterConfig.settings[kAppID];
    NSString *appSignature = adapterConfig.settings[kAppSignature];
    NSString *locationId = adapterConfig.settings[kLocationId];

    /* Configuration Validation */
    if (![self isConfigValueValid:appId]) {
        NSError *error = [self errorForMissingCredentialFieldWithName:kAppID];
        LogAdapterApi_Internal(@"error = %@", error.description);
        [delegate adapterBannerInitFailedWithError:error];
        return;
    }
        
    if (![self isConfigValueValid:appSignature]) {
        NSError *error = [self errorForMissingCredentialFieldWithName:kAppSignature];
        LogAdapterApi_Internal(@"error = %@", error.description);
        [delegate adapterBannerInitFailedWithError:error];
        return;
    }
    
    if (![self isConfigValueValid:locationId]) {
        NSError *error = [self errorForMissingCredentialFieldWithName:kLocationId];
        LogAdapterApi_Internal(@"error = %@", error.description);
        [delegate adapterBannerInitFailedWithError:error];
        return;
    }
    
    LogAdapterApi_Internal(@"locationId = %@", locationId);
    
    ISChartboostBannerDelegate *bannerDelegate = [[ISChartboostBannerDelegate alloc] initWithLocationId:locationId
                                                                                            andDelegate:self];

    //add to banner delegate map
    [_bannerLocationIdToChartboostAdDelegate setObject:bannerDelegate
                                                forKey:locationId];
    
    [_bannerLocationIdToSmashDelegate setObject:delegate
                                         forKey:locationId];
    
    switch (_initState) {
        case INIT_STATE_NONE:
        case INIT_STATE_IN_PROGRESS:
            [self initSDKWithAppId:appId
                      appSignature:appSignature];
            break;
        case INIT_STATE_SUCCESS:
            [delegate adapterBannerInitSuccess];
            break;
        case INIT_STATE_FAILED: {
            LogAdapterApi_Internal(@"init failed - locationId = %@", locationId);
            NSError *error = [NSError errorWithDomain:kAdapterName
                                                 code:ERROR_CODE_INIT_FAILED
                                             userInfo:@{NSLocalizedDescriptionKey:@"Chartboost SDK init failed"}];
            [delegate adapterBannerInitFailedWithError:error];
            break;
        }
    }
}

- (void)loadBannerWithViewController:(nonnull UIViewController *)viewController
                                size:(ISBannerSize *)size
                       adapterConfig:(nonnull ISAdapterConfig *)adapterConfig
                            delegate:(nonnull id <ISBannerAdapterDelegate>)delegate {

    NSString *locationId = adapterConfig.settings[kLocationId];
    
    if (![self isBannerSizeSupported:size]) {
        NSError *error = [NSError errorWithDomain:kAdapterName
                                             code:ERROR_BN_UNSUPPORTED_SIZE
                                         userInfo:@{NSLocalizedDescriptionKey:@"Chartboost unsupported banner size"}];
        LogAdapterApi_Internal(@"error = %@", error);
        [delegate adapterBannerDidFailToLoadWithError:error];
        return;
    }
    
    LogAdapterApi_Internal(@"locationId = %@", locationId);

    CHBBanner *bannerAd = [self getBannerAdForLocationId:viewController
                                                    size:size
                                              locationId:locationId];
    
    if (bannerAd) {
        // Load banner
        [bannerAd cache];
        
    } else {
        NSError *error = [NSError errorWithDomain:kAdapterName
                                             code:ERROR_CODE_GENERIC
                                         userInfo:@{NSLocalizedDescriptionKey:@"load banner failed"}];
        LogAdapterApi_Internal(@"error = %@", error);
        [delegate adapterBannerDidFailToLoadWithError:error];
    }
}

- (void)reloadBannerWithAdapterConfig:(nonnull ISAdapterConfig *)adapterConfig
                             delegate:(nonnull id <ISBannerAdapterDelegate>)delegate {
    LogInternal_Warning(@"Unsupported method");
}

- (void) destroyBannerWithAdapterConfig:(nonnull ISAdapterConfig *)adapterConfig {    
    NSString *locationId = adapterConfig.settings[kLocationId];
    LogAdapterApi_Internal(@"locationId = %@", locationId);

    [_bannerLocationIdToAd removeObjectForKey:locationId];
    [_bannerLocationIdToSize removeObjectForKey:locationId];
    [_bannerLocationIdToViewController removeObjectForKey:locationId];
    [_bannerLocationIdToChartboostAdDelegate removeObjectForKey:locationId];
    [_bannerLocationIdToSmashDelegate removeObjectForKey:locationId];
}

//network does not support banner reload
//return true if banner view needs to be bound again on reload
- (BOOL) shouldBindBannerViewOnReload {
    return YES;
}

#pragma mark - Banner Delegate

- (void)onBannerDidLoad:(nonnull NSString *)locationId {
    LogAdapterDelegate_Internal(@"locationId = %@", locationId);
    CHBBanner *bannerAd = [_bannerLocationIdToAd objectForKey:locationId];
    UIViewController *viewController = [_bannerLocationIdToViewController objectForKey:locationId];

    if (bannerAd && viewController) {
        id<ISBannerAdapterDelegate> delegate = [_bannerLocationIdToSmashDelegate objectForKey:locationId];

        if (delegate) {
            [delegate adapterBannerDidLoad:bannerAd];
            [bannerAd showFromViewController:viewController];
        }
    }
}

- (void)onBannerDidFailToLoad:(nonnull NSString *)locationId
                    withError:(nonnull CHBCacheError *)error {
    LogAdapterDelegate_Internal(@"locationId = %@, error = %@", locationId, error.description);
    id<ISBannerAdapterDelegate> delegate = [_bannerLocationIdToSmashDelegate objectForKey:locationId];

    if (delegate) {
        NSInteger errorCode = (error.code == CHBCacheErrorCodeNoAdFound) ? ERROR_BN_LOAD_NO_FILL : error.code;
        NSError *smashError = [NSError errorWithDomain:kAdapterName
                                                  code:errorCode
                                              userInfo:@{NSLocalizedDescriptionKey:error.description}];
        
        [delegate adapterBannerDidFailToLoadWithError:smashError];
    }
}

- (void)onBannerDidShow:(nonnull NSString *)locationId {
    LogAdapterDelegate_Internal(@"locationId = %@", locationId);
    id<ISBannerAdapterDelegate> delegate = [_bannerLocationIdToSmashDelegate objectForKey:locationId];

    if (delegate) {
        [delegate adapterBannerDidShow];
    }
}

- (void)onBannerDidFailToShow:(nonnull NSString *)locationId
                    withError:(nonnull CHBShowError *)error {
    LogAdapterDelegate_Internal(@"locationId = %@, error = %@", locationId, error.description);
}

- (void)onBannerDidClick:(nonnull NSString *)locationId
               withError:(nullable CHBClickError *)error {

    LogAdapterDelegate_Internal(@"locationId = %@", locationId);
    id<ISBannerAdapterDelegate> delegate = [_bannerLocationIdToSmashDelegate objectForKey:locationId];

    if (delegate) {
        [delegate adapterBannerDidClick];
        
        if (error) {
            LogAdapterDelegate_Internal(@"error = %@", error.description);
        }
    }
}

#pragma mark - Memory Handling

- (void)releaseMemoryWithAdapterConfig:(nonnull ISAdapterConfig *)adapterConfig {
    NSString *locationId = adapterConfig.settings[kLocationId];

    if ([_rewardedVideoLocationIdToAd hasObjectForKey:locationId]) {
        [_rewardedVideoLocationIdToSmashDelegate removeObjectForKey:locationId];
        [_rewardedVideoLocationIdToChartboostAdDelegate removeObjectForKey:locationId];
        [_rewardedVideoLocationIdToAd removeObjectForKey:locationId];
        [_rewardedVideoLocationIdsForInitCallbacks removeObject:locationId];
        
    } else if ([_interstitialLocationIdToAd hasObjectForKey:locationId]) {
        [_interstitialLocationIdToSmashDelegate removeObjectForKey:locationId];
        [_interstitialLocationIdToChartboostAdDelegate removeObjectForKey:locationId];
        [_interstitialLocationIdToAd removeObjectForKey:locationId];
        
    } else if ([_bannerLocationIdToAd hasObjectForKey:locationId]) {
        [_bannerLocationIdToSmashDelegate removeObjectForKey:locationId];
        [_bannerLocationIdToChartboostAdDelegate removeObjectForKey:locationId];
        [_bannerLocationIdToAd removeObjectForKey:locationId];
        [_bannerLocationIdToViewController removeObjectForKey:locationId];
        [_bannerLocationIdToSize removeObjectForKey:locationId];
    }
}

#pragma mark - Legal Methods

- (void)setConsent:(BOOL)consent {
    LogAdapterApi_Internal(@"consent = %@", consent ? @"Behavioral" : @"NonBehavioral");
    [Chartboost addDataUseConsent:[CHBGDPRDataUseConsent gdprConsent:(consent? CHBGDPRConsentBehavioral : CHBGDPRConsentNonBehavioral)]];
}

- (void)setCCPAValue:(BOOL)value {
    LogAdapterApi_Internal(@"value = %@", value? @"OptOutSale" : @"OptInSale");
    [Chartboost addDataUseConsent:[CHBCCPADataUseConsent ccpaConsent:(value ? CHBCCPAConsentOptOutSale : CHBCCPAConsentOptInSale)]];
}

- (void)setMetaDataWithKey:(NSString *)key
                 andValues:(NSMutableArray *)values {
    if (values.count == 0) {
        return;
    }
    
    // this is a list of 1 value
    NSString *value = values[0];
    LogAdapterApi_Internal(@"key = %@, value = %@", key, value);
    
    if ([ISMetaDataUtils isValidCCPAMetaDataWithKey:key
                                           andValue:value]) {
        [self setCCPAValue:[ISMetaDataUtils getCCPABooleanValue:value]];
    }
}

#pragma mark - Helpers

- (BOOL)isBannerSizeSupported:(ISBannerSize *)size {
    
    if ([size.sizeDescription isEqualToString:@"BANNER"]     ||
        [size.sizeDescription isEqualToString:@"LARGE"]      ||
        [size.sizeDescription isEqualToString:@"RECTANGLE"]  ||
        [size.sizeDescription isEqualToString:@"SMART"]) {
        return YES;
    } else if ([size.sizeDescription isEqualToString:@"CUSTOM"]) {
        return (size.height >= 40 && size.height <= 60);
    }

    return NO;
}

- (CHBBannerSize)getBannerSize:(ISBannerSize *)size {
    
    if ([size.sizeDescription isEqualToString:@"BANNER"] ||
        [size.sizeDescription isEqualToString:@"LARGE"]) {
        return CHBBannerSizeStandard;
        
    } else if ([size.sizeDescription isEqualToString:@"RECTANGLE"]) {
        return CHBBannerSizeMedium;
        
    } else if ([size.sizeDescription isEqualToString:@"SMART"]) {
        return (UI_USER_INTERFACE_IDIOM() == UIUserInterfaceIdiomPad) ? CHBBannerSizeLeaderboard : CHBBannerSizeStandard;
        
    } else if ([size.sizeDescription isEqualToString:@"CUSTOM"]) {
        if (size.height >= 40 && size.height <= 60) {
            return CHBBannerSizeStandard;
        }
    }
    
    return CGSizeZero;
}

- (CHBRewarded *)getRewardedVideAdForLocationId:(NSString *)locationId {
    CHBRewarded *rewardedVideoAd = [_rewardedVideoLocationIdToAd objectForKey:locationId];

    if (!rewardedVideoAd) {
        //create rewarded video delegate
        ISChartboostRewardedVideoDelegate *delegate = [_rewardedVideoLocationIdToChartboostAdDelegate objectForKey:locationId];

        // create rewarded video
        rewardedVideoAd = [[CHBRewarded alloc] initWithLocation:locationId
                                                       delegate:delegate];
        // add to dictionaries
        [_rewardedVideoLocationIdToAd setObject:rewardedVideoAd
                                        forKey:locationId];
    }
    
    return rewardedVideoAd;
}

- (CHBInterstitial *)getInterstitialAdForLocationId:(NSString *)locationId {
    CHBInterstitial *interstitialAd = [_interstitialLocationIdToAd objectForKey:locationId];
        
    if (!interstitialAd) {
        //create interstitial delegate
        ISChartboostInterstitialDelegate *delegate = [_interstitialLocationIdToChartboostAdDelegate objectForKey:locationId];
            
        // create interstitial
        interstitialAd = [[CHBInterstitial alloc] initWithLocation:locationId
                                                         mediation:[self getMediationInfo]
                                                          delegate:delegate];
        // add to dictionaries
        [_interstitialLocationIdToAd setObject:interstitialAd
                                       forKey:locationId];
    }
        
    return interstitialAd;
}

- (CHBBanner *)getBannerAdForLocationId:(nonnull UIViewController *)viewController
                                   size:(ISBannerSize *)size
                             locationId:(NSString *)locationId {
    
    CHBBanner *bannerAd = [_bannerLocationIdToAd objectForKey:locationId];

    if (!bannerAd) {
        //create banner delegate
        ISChartboostBannerDelegate *delegate = [_bannerLocationIdToChartboostAdDelegate objectForKey:locationId];
        
        // get size
        CHBBannerSize chartboostSize = [self getBannerSize:size];
        
        // create banner
        bannerAd = [[CHBBanner alloc] initWithSize:chartboostSize
                                          location:locationId
                                         mediation:[self getMediationInfo]
                                          delegate:delegate];
        
        // add to dictionaries
        [_bannerLocationIdToAd setObject:bannerAd
                                forKey:locationId];
        
        [_bannerLocationIdToSize setObject:size
                                   forKey:locationId];
        
        [_bannerLocationIdToViewController setObject:viewController
                                             forKey:locationId];
    }
    
    return bannerAd;
            
}

- (CHBMediation *)getMediationInfo {
    if (_mediationInfo == nil) {
        _mediationInfo = [[CHBMediation alloc] initWithName:kMediationName
                                             libraryVersion:[IronSource sdkVersion]
                                             adapterVersion:kAdapterVersion];
    }
    
    return _mediationInfo;
}

@end
