//
//  ISVungleAdapter.m
//  ISVungleAdapter
//
//  Created by Amit Goldhecht on 8/20/14.
//  Copyright (c) 2014 IronSource. All rights reserved.
//
#import "ISVungleAdapter.h"
#import <VungleAds/VungleAds.h>
#import "ISVungleBannerAdapterRouter.h"
#import "ISVungleRewardedVideoAdapterRouter.h"
#import "ISVungleInterstitialAdapterRouter.h"

// Network keys
static NSString * const kAdapterVersion         = VungleAdapterVersion;
static NSString * const kAdapterName            = @"Vungle";
static NSString * const kAppID                  = @"AppID";
static NSString * const kPlacementID            = @"PlacementId";

// Meta data flags
static NSString * const kMetaDataCOPPAKey       = @"Vungle_COPPA";

// Vungle Constants
static NSString * const kOrientationFlag        = @"vungle_adorientation";
static NSString * const kPortraitOrientation    = @"PORTRAIT";
static NSString * const kLandscapeOrientation   = @"LANDSCAPE";
static NSString * const kAutoRotateOrientation  = @"AUTO_ROTATE";

static NSString * const kLWSSupportedState      = @"isSupportedLWSByInstance";
static NSInteger const kShowErrorNotCached = 6000;

// members for network
static NSNumber * uiOrientation = nil;
static NSString * adOrientation = nil;

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

@interface ISVungleAdapter() <ISNetworkInitCallbackProtocol>

// Rewarded video
@property (nonatomic, strong) ConcurrentMutableDictionary *rewardedVideoPlacementIdToSmashRouter;
@property (nonatomic, strong) ConcurrentMutableSet        *rewardedVideoPlacementIdsForInitCallbacks;

// Interstitial
@property (nonatomic, strong) ConcurrentMutableDictionary *interstitialPlacementIdToSmashRouter;

// Banner
@property (nonatomic, strong) ConcurrentMutableDictionary *bannerPlacementIdToSmashRouter;

@end

@implementation ISVungleAdapter

#pragma mark - IronSource Protocol Methods

// get adapter version
- (NSString *)version {
    return kAdapterVersion;
}

// get network sdk version
- (NSString *)sdkVersion {
    return [VungleAds sdkVersion];
}

- (NSArray *)systemFrameworks {
    return @[@"AdSupport", @"AudioToolbox", @"AVFoundation", @"CFNetwork", @"CoreGraphics", @"CoreMedia", @"Foundation", @"MediaPlayer", @"QuartzCore", @"StoreKit", @"SystemConfiguration", @"UIKit", @"WebKit"];
}

- (NSString *)sdkName {
    return @"VungleSDK";
}

#pragma mark - Initializations Methods And Callbacks

- (instancetype)initAdapter:(NSString *)name {
    self = [super initAdapter:name];

    if (self) {
        if (initCallbackDelegates == nil) {
            initCallbackDelegates = [ConcurrentMutableSet<ISNetworkInitCallbackProtocol> set];
        }

        // Rewarded video
        _rewardedVideoPlacementIdToSmashRouter          = [ConcurrentMutableDictionary dictionary];
        _rewardedVideoPlacementIdsForInitCallbacks      = [ConcurrentMutableSet set];

        // Interstitial
        _interstitialPlacementIdToSmashRouter           = [ConcurrentMutableDictionary dictionary];

        // Banner
        _bannerPlacementIdToSmashRouter                 = [ConcurrentMutableDictionary dictionary];
    }

    return self;
}

- (void)initSDKWithAppId:(NSString *)appId {
    // add self to the init delegates only in case the initialization has not finished yet
    if ((_initState == INIT_STATE_NONE) || (_initState == INIT_STATE_IN_PROGRESS)) {
        [initCallbackDelegates addObject:self];
    }

    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        _initState = INIT_STATE_IN_PROGRESS;

        [VungleAds setIntegrationName:@"ironsource" version:[self version]];
        LogAdapterApi_Internal(@"appId = %@ adaptersDebug = %d", appId, [ISConfigurations getConfigurations].adaptersDebug);

        // init Vungle sdk
        [VungleAds initWithAppId:appId completion:^(NSError * _Nullable error) {
            if (error) {
                LogAdapterApi_Internal(@"Vungle SDK init failed - error = %@", error);
                [self initFailedWithError:error];
            }
            else {
                [self initSuccess];
            }
        }];
    });
}

- (void)initSuccess {
    
    _initState = INIT_STATE_SUCCESS;
    
    NSArray *initDelegatesList = initCallbackDelegates.allObjects;
    
    // call init callback delegate success
    for (id<ISNetworkInitCallbackProtocol> delegate in initDelegatesList) {
        [delegate onNetworkInitCallbackSuccess];
    }
    
    [initCallbackDelegates removeAllObjects];
}

- (void)initFailedWithError:(NSError *)error {
    
    _initState = INIT_STATE_FAILED;
    
    NSArray *initDelegatesList = initCallbackDelegates.allObjects;
    
    // call init callback delegate fail
    for (id<ISNetworkInitCallbackProtocol> delegate in initDelegatesList) {
        [delegate onNetworkInitCallbackFailed:@"Vungle SDK init failed"];
    }
    
    [initCallbackDelegates removeAllObjects];
}

- (void)onNetworkInitCallbackSuccess {
    LogAdapterDelegate_Internal(@"");
    
    // rewarded video
    NSArray *rewardedVideoPlacementIDs = _rewardedVideoPlacementIdToSmashRouter.allKeys;
    for (NSString *placementId in rewardedVideoPlacementIDs) {
        if ([_rewardedVideoPlacementIdsForInitCallbacks hasObject:placementId]) {
            [[_rewardedVideoPlacementIdToSmashRouter objectForKey:placementId] rewardedVideoInitSuccess];
        } else {
            [self loadRewardedVideoInternalWithPlacement:placementId];
        }
    }
    
    // interstitial
    NSArray *interstitialPlacementIDs = _interstitialPlacementIdToSmashRouter.allKeys;
    for (NSString *placementId in interstitialPlacementIDs) {
        ISVungleInterstitialAdapterRouter *interstitialRouter = [_interstitialPlacementIdToSmashRouter objectForKey:placementId];
        [interstitialRouter interstitialInitSuccess];
    }
    
    // banner
    NSArray *bannerPlacementIDs = _bannerPlacementIdToSmashRouter.allKeys;
    for (NSString *placementId in bannerPlacementIDs) {
        ISVungleBannerAdapterRouter *bannerRouter = [_bannerPlacementIdToSmashRouter objectForKey:placementId];
        [bannerRouter bannerAdInitSuccess];
    }
}

- (void)onNetworkInitCallbackFailed:(nonnull NSString *)errorMessage {
    LogInternal_Internal(@"");
    
    NSError *error = [ISError createError:ERROR_CODE_INIT_FAILED withMessage:errorMessage];
    
    // rewarded video
    NSArray *rewardedVideoPlacementIDs = _rewardedVideoPlacementIdToSmashRouter.allKeys;
    for (NSString *placementId in rewardedVideoPlacementIDs) {
        if ([_rewardedVideoPlacementIdsForInitCallbacks hasObject:placementId]) {
            [[_rewardedVideoPlacementIdToSmashRouter objectForKey:placementId] rewardedVideoInitFailed:error];
        } else {
            [[_rewardedVideoPlacementIdToSmashRouter objectForKey:placementId] rewardedVideoHasChangedAvailability:NO];
        }
    }
    
    // interstitial
    NSArray *interstitialPlacementIDs = _interstitialPlacementIdToSmashRouter.allKeys;
    for (NSString *placementId in interstitialPlacementIDs) {
        ISVungleInterstitialAdapterRouter *interstitialRouter = [_interstitialPlacementIdToSmashRouter objectForKey:placementId];
        [interstitialRouter interstitialInitFailed:error];
    }

    // banner
    NSArray *bannerPlacementIDs = _bannerPlacementIdToSmashRouter.allKeys;
    for (NSString *placementId in bannerPlacementIDs) {
        ISVungleBannerAdapterRouter *bannerRouter = [_bannerPlacementIdToSmashRouter objectForKey:placementId];
        [bannerRouter bannerAdInitFailed:error];
    }
}

#pragma mark - Rewarded Video API

// used for flows when the mediation needs to get a callback for init
- (void)initRewardedVideoForCallbacksWithUserId:(NSString *)userId
                                  adapterConfig:(ISAdapterConfig *)adapterConfig
                                       delegate:(id<ISRewardedVideoAdapterDelegate>)delegate {
    
    NSString *appId = adapterConfig.settings[kAppID];
    NSString *placementId = adapterConfig.settings[kPlacementID];

    /* Configuration Validation */
    if (![self isConfigValueValid:appId]) {
        NSError *error = [self errorForMissingCredentialFieldWithName:kAppID];
        LogInternal_Error(@"error = %@", error);
        [delegate adapterRewardedVideoInitFailed:error];
        return;
    }
    
    if (![self isConfigValueValid:placementId]) {
        NSError *error = [self errorForMissingCredentialFieldWithName:kPlacementID];
        LogInternal_Error(@"error = %@", error);
        [delegate adapterRewardedVideoInitFailed:error];
        return;
    }
    
    LogInternal_Internal(@"appId = %@, placementId = %@", appId, placementId);
    
    // add to Rewarded video router map
    ISVungleRewardedVideoAdapterRouter *rewardedRouter = [[ISVungleRewardedVideoAdapterRouter alloc] initWithPlacementID:placementId parentAdapter:self delegate:delegate];
    [_rewardedVideoPlacementIdToSmashRouter setObject:rewardedRouter
                                               forKey:placementId];
    
    // add to rewarded video init callback map
    [_rewardedVideoPlacementIdsForInitCallbacks addObject:placementId];
    
    switch (_initState) {
        case INIT_STATE_NONE:
        case INIT_STATE_IN_PROGRESS:
            [self initSDKWithAppId:appId];
            break;
        case INIT_STATE_SUCCESS:
            [delegate adapterRewardedVideoInitSuccess];
            break;
        case INIT_STATE_FAILED: {
            NSError *error = [NSError errorWithDomain:kAdapterName
                                                 code:ERROR_CODE_INIT_FAILED
                                             userInfo:@{NSLocalizedDescriptionKey:@"Vungle SDK init failed"}];
            LogAdapterApi_Internal(@"error.description = %@", error.description);
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
    NSString *placementId = adapterConfig.settings[kPlacementID];

    /* Configuration Validation */
    if (![self isConfigValueValid:appId]) {
        NSError *error = [self errorForMissingCredentialFieldWithName:kAppID];
        LogAdapterApi_Internal(@"error = %@", error);
        [delegate adapterRewardedVideoHasChangedAvailability:NO];
        return;
    }
    
    if (![self isConfigValueValid:placementId]) {
        NSError *error = [self errorForMissingCredentialFieldWithName:kPlacementID];
        LogAdapterApi_Internal(@"error = %@", error);
        [delegate adapterRewardedVideoHasChangedAvailability:NO];
        return;
    }
    
    LogInternal_Internal(@"appId = %@, placementId = %@", appId, placementId);
    
    // add to Rewarded video router map
    ISVungleRewardedVideoAdapterRouter *rewardedRouter = [[ISVungleRewardedVideoAdapterRouter alloc] initWithPlacementID:placementId parentAdapter:self delegate:delegate];
    [_rewardedVideoPlacementIdToSmashRouter setObject:rewardedRouter
                                               forKey:placementId];

    switch (_initState) {
        case INIT_STATE_NONE:
        case INIT_STATE_IN_PROGRESS:
            [self initSDKWithAppId:appId];
            break;
        case INIT_STATE_SUCCESS:
            [self loadRewardedVideoInternalWithPlacement:placementId];
            break;
        case INIT_STATE_FAILED: {
            LogAdapterApi_Internal(@"init failed - placementId = %@", placementId);
            [delegate adapterRewardedVideoHasChangedAvailability:NO];
            break;
        }
    }
}

- (void)loadRewardedVideoForBiddingWithAdapterConfig:(ISAdapterConfig *)adapterConfig
                                          serverData:(NSString *)serverData
                                            delegate:(id<ISRewardedVideoAdapterDelegate>)delegate {
    NSString *placementId = adapterConfig.settings[kPlacementID];
    ISVungleRewardedVideoAdapterRouter *rewardedRouter = [_rewardedVideoPlacementIdToSmashRouter objectForKey:placementId];
    [rewardedRouter setBidPayload:serverData];
    [self loadRewardedVideoInternalWithPlacement:placementId];
}

- (void)fetchRewardedVideoForAutomaticLoadWithAdapterConfig:(ISAdapterConfig *)adapterConfig
                                                   delegate:(id<ISRewardedVideoAdapterDelegate>)delegate {
    NSString *placementId = adapterConfig.settings[kPlacementID];
    [self loadRewardedVideoInternalWithPlacement:placementId];
}

- (void)loadRewardedVideoInternalWithPlacement:(NSString *)placementId {
    LogAdapterApi_Internal(@"placementId = %@", placementId);

    ISVungleRewardedVideoAdapterRouter *rewardedRouter = [_rewardedVideoPlacementIdToSmashRouter objectForKey:placementId];
    [rewardedRouter loadRewardedVideoAd];
}

- (void)showRewardedVideoWithViewController:(UIViewController *)viewController
                              adapterConfig:(ISAdapterConfig *)adapterConfig
                                   delegate:(id<ISRewardedVideoAdapterDelegate>)delegate {
    NSString *placementId = adapterConfig.settings[kPlacementID];
    LogAdapterApi_Internal(@"placementId = %@", placementId);

    [delegate adapterRewardedVideoHasChangedAvailability:NO];
    ISVungleRewardedVideoAdapterRouter *rewardedRouter  = [_rewardedVideoPlacementIdToSmashRouter objectForKey:placementId];
    
    if (![rewardedRouter.rewardedVideoAd canPlayAd]) {
        NSError *error = [NSError errorWithDomain:kAdapterName
                                             code:kShowErrorNotCached
                                         userInfo:@{NSLocalizedDescriptionKey : @"Show error. ad not cached"}];
        LogAdapterApi_Internal(@"error = %@", error);
        [delegate adapterRewardedVideoDidFailToShowWithError:error];
        return;
    }
    
    dispatch_async(dispatch_get_main_queue(), ^{
        [rewardedRouter playRewardedVideoAdWithViewController:viewController];
    });
}

- (BOOL)hasRewardedVideoWithAdapterConfig:(ISAdapterConfig *)adapterConfig {
    NSString *placementId = adapterConfig.settings[kPlacementID];

    // Vungle cache ads that were loaded in the last week.
    // This means that [VungleRewarded canPlayAd] could return YES for placements that we didn't try to load during this session.
    // This is the reason we also check if the placementId is contained in the ConcurrentMutableDictionary
    if (![_rewardedVideoPlacementIdToSmashRouter hasObjectForKey:placementId]) {
        return NO;
    }

    ISVungleRewardedVideoAdapterRouter *rewardedRouter  = [_rewardedVideoPlacementIdToSmashRouter objectForKey:placementId];
    return [rewardedRouter.rewardedVideoAd canPlayAd];
}

- (NSDictionary *)getRewardedVideoBiddingDataWithAdapterConfig:(ISAdapterConfig *)adapterConfig {
    return [self getBiddingDataWithAdapterConfig:adapterConfig];
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
    NSString *appId = adapterConfig.settings[kAppID];
    NSString *placementId = adapterConfig.settings[kPlacementID];

    /* Configuration Validation */
    if (![self isConfigValueValid:appId]) {
        NSError *error = [self errorForMissingCredentialFieldWithName:kAppID];
        LogAdapterApi_Internal(@"error = %@", error);
        [delegate adapterInterstitialInitFailedWithError:error];
        return;
    }
    
    if (![self isConfigValueValid:placementId]) {
        NSError *error = [self errorForMissingCredentialFieldWithName:kPlacementID];
        LogAdapterApi_Internal(@"error = %@", error);
        [delegate adapterInterstitialInitFailedWithError:error];
        return;
    }
    
    LogInternal_Internal(@"appId = %@, placementId = %@", appId, placementId);
    // add to Interstitial router map
    ISVungleInterstitialAdapterRouter *interstitialRouter = [[ISVungleInterstitialAdapterRouter alloc] initWithPlacementID:placementId parentAdapter:self delegate:delegate];
    [_interstitialPlacementIdToSmashRouter setObject:interstitialRouter
                                               forKey:placementId];
    
    switch (_initState) {
        case INIT_STATE_NONE:
        case INIT_STATE_IN_PROGRESS:
            [self initSDKWithAppId:appId];
            break;
        case INIT_STATE_SUCCESS:
            [delegate adapterInterstitialInitSuccess];
            break;
        case INIT_STATE_FAILED: {
            NSError *error = [NSError errorWithDomain:kAdapterName
                                                 code:ERROR_CODE_INIT_FAILED
                                             userInfo:@{NSLocalizedDescriptionKey:@"Vungle SDK init failed"}];
            LogAdapterApi_Internal(@"error = %@", error);
            [delegate adapterInterstitialInitFailedWithError:error];
            break;
        }
    }
}

- (void)loadInterstitialForBiddingWithServerData:(NSString *)serverData
                                   adapterConfig:(ISAdapterConfig *)adapterConfig
                                        delegate:(id<ISInterstitialAdapterDelegate>)delegate {
    NSString *placementId = adapterConfig.settings[kPlacementID];
    ISVungleInterstitialAdapterRouter *interstitialRouter = [_interstitialPlacementIdToSmashRouter objectForKey:placementId];
    [interstitialRouter setBidPayload:serverData];

    [self loadInterstitialInternalWithPlacement:placementId];
}

- (void)loadInterstitialWithAdapterConfig:(ISAdapterConfig *)adapterConfig
                                 delegate:(id<ISInterstitialAdapterDelegate>)delegate {
    NSString *placementId = adapterConfig.settings[kPlacementID];
    [self loadInterstitialInternalWithPlacement:placementId];
}

- (void)loadInterstitialInternalWithPlacement:(NSString *)placementId {
    LogAdapterApi_Internal(@"placementID = %@", placementId);

    ISVungleInterstitialAdapterRouter *interstitialRouter = [_interstitialPlacementIdToSmashRouter objectForKey:placementId];
    [interstitialRouter loadInterstitial];
}

- (void)showInterstitialWithViewController:(UIViewController *)viewController
                             adapterConfig:(ISAdapterConfig *)adapterConfig
                                  delegate:(id<ISInterstitialAdapterDelegate>)delegate {
    NSString *placementId = adapterConfig.settings[kPlacementID];
    LogAdapterApi_Internal(@"placementId = %@", placementId);
    ISVungleInterstitialAdapterRouter *interstitialRouter = [_interstitialPlacementIdToSmashRouter objectForKey:placementId];
    
    if (![interstitialRouter.interstitialAd canPlayAd]) {
        NSError *error = [NSError errorWithDomain:kAdapterName
                                             code:kShowErrorNotCached
                                         userInfo:@{NSLocalizedDescriptionKey : @"Show error. ad not cached"}];
        LogAdapterApi_Internal(@"error = %@", error);
        [delegate adapterInterstitialDidFailToShowWithError:error];
        return;
    }

    dispatch_async(dispatch_get_main_queue(), ^{
        [interstitialRouter playInterstitialAdWithViewController:viewController];
    });
}

- (BOOL)hasInterstitialWithAdapterConfig:(ISAdapterConfig *)adapterConfig {
    NSString *placementId = adapterConfig.settings[kPlacementID];

    // Vungle cache ads that were loaded in the last week.
    // This means that [VungleInterstitial canPlayAd] could return YES for placements that we didn't try to load during this session.
    // This is the reason we also check if the placementId is contained in the ConcurrentMutableDictionary
    if (![_interstitialPlacementIdToSmashRouter hasObjectForKey:placementId]) {
        return NO;
    }

    ISVungleInterstitialAdapterRouter *interstitialRouter = [_interstitialPlacementIdToSmashRouter objectForKey:placementId];
    return [interstitialRouter.interstitialAd canPlayAd];
}

- (NSDictionary *)getInterstitialBiddingDataWithAdapterConfig:(ISAdapterConfig *)adapterConfig {
    return [self getBiddingDataWithAdapterConfig:adapterConfig];
}

#pragma mark - Banner API

- (void)initBannerForBiddingWithUserId:(NSString *)userId
                         adapterConfig:(ISAdapterConfig *)adapterConfig
                              delegate:(id<ISBannerAdapterDelegate>)delegate {
    [self initBannerWithUserId:userId
                 adapterConfig:adapterConfig
                      delegate:delegate];
}

- (void)initBannerWithUserId:(nonnull NSString *)userId
               adapterConfig:(nonnull ISAdapterConfig *)adapterConfig
                    delegate:(nonnull id<ISBannerAdapterDelegate>)delegate {
    NSString *appId = adapterConfig.settings[kAppID];
    NSString *placementId = adapterConfig.settings[kPlacementID];

    /* Configuration Validation */
    if (![self isConfigValueValid:appId]) {
        NSError *error = [self errorForMissingCredentialFieldWithName:kAppID];
        LogAdapterApi_Internal(@"error = %@", error);
        [delegate adapterBannerInitFailedWithError:error];
        return;
    }
    
    if (![self isConfigValueValid:placementId]) {
        NSError *error = [self errorForMissingCredentialFieldWithName:kPlacementID];
        LogAdapterApi_Internal(@"error = %@", error);
        [delegate adapterBannerInitFailedWithError:error];
        return;
    }

    LogInternal_Internal(@"appId = %@, placementId = %@", appId, placementId);
    // add to Banner Router map
    ISVungleBannerAdapterRouter *bannerRouter = [[ISVungleBannerAdapterRouter alloc] initWithPlacementID:placementId parentAdapter:self delegate:delegate];
    [_bannerPlacementIdToSmashRouter setObject:bannerRouter forKey:placementId];

    switch (_initState) {
        case INIT_STATE_NONE:
        case INIT_STATE_IN_PROGRESS:
            [self initSDKWithAppId:appId];
            break;
        case INIT_STATE_SUCCESS:
            [delegate adapterBannerInitSuccess];
            break;
        case INIT_STATE_FAILED: {
            NSError *error = [NSError errorWithDomain:kAdapterName
                                                 code:ERROR_CODE_INIT_FAILED
                                             userInfo:@{NSLocalizedDescriptionKey:@"Vungle SDK init failed"}];
            LogAdapterApi_Internal(@"error = %@", error);
            [delegate adapterBannerInitFailedWithError:error];
            break;
        }
    }
}

- (void)loadBannerForBiddingWithServerData:(NSString *)serverData
                            viewController:(UIViewController *)viewController
                                      size:(ISBannerSize *)size
                             adapterConfig:(ISAdapterConfig *)adapterConfig
                                  delegate:(id<ISBannerAdapterDelegate>)delegate {
    NSString *placementId = adapterConfig.settings[kPlacementID];

    // get Banner state
    ISVungleBannerAdapterRouter *bannerRouter = [_bannerPlacementIdToSmashRouter objectForKey:placementId];
    [bannerRouter setSize:size];
    [bannerRouter setBidPayload:serverData];

    if (bannerRouter.bannerState == SHOWING) {
        [self dismissBannerWithServerData:serverData
                             bannerRouter:bannerRouter
                                     size:size
                              placementId:placementId
                                 delegate:delegate];
    } else {
        [self loadBannerInternalWithPlacement:placementId
                               viewController:viewController
                                         size:size
                                     delegate:delegate];
    }
}

- (void)loadBannerWithViewController:(nonnull UIViewController *)viewController
                                size:(ISBannerSize *)size
                       adapterConfig:(nonnull ISAdapterConfig *)adapterConfig
                            delegate:(nonnull id <ISBannerAdapterDelegate>)delegate {
    NSString *placementId = adapterConfig.settings[kPlacementID];

    // get Banner state
    ISVungleBannerAdapterRouter *bannerRouter = [_bannerPlacementIdToSmashRouter objectForKey:placementId];
    [bannerRouter setSize:size];

    if (bannerRouter.bannerState == SHOWING) {
        [self dismissBannerWithServerData:nil
                             bannerRouter:bannerRouter
                                     size:size
                              placementId:placementId
                                 delegate:delegate];
    } else {
        [self loadBannerInternalWithPlacement:placementId
                               viewController:viewController
                                         size:size
                                     delegate:delegate];
    }
}

- (void)dismissBannerWithServerData:(NSString *)serverData
                      bannerRouter:(ISVungleBannerAdapterRouter *)bannerRouter
                               size:(ISBannerSize *)size
                        placementId:(NSString *)placementId
                           delegate:(id <ISBannerAdapterDelegate>)delegate {
    // verify size
    if (![self isBannerSizeSupported:size]) {
        NSError *error = [ISError createError:ERROR_BN_UNSUPPORTED_SIZE
                                  withMessage:[NSString stringWithFormat:@"Vungle unsupported banner size - %@", size.sizeDescription]];
        LogAdapterApi_Internal(@"error = %@", error);
        [delegate adapterBannerDidFailToLoadWithError:error];
        return;
    }
    
    LogAdapterApi_Internal(@"placementId = %@, size = %@", placementId, size.sizeDescription);
    // Set Banner state to REQUESTING_RELOAD
    bannerRouter.bannerState = REQUESTING_RELOAD;
    //TODO : destory or just finish playing
    [bannerRouter destroy];
}

- (void)loadBannerInternalWithPlacement:(NSString *)placementId
                         viewController:(nonnull UIViewController *)viewController
                                   size:(ISBannerSize *)size
                               delegate:(id <ISBannerAdapterDelegate>)delegate {
    // verify size
    if (![self isBannerSizeSupported:size]) {
        NSError *error = [ISError createError:ERROR_BN_UNSUPPORTED_SIZE
                                  withMessage:[NSString stringWithFormat:@"Vungle unsupported banner size - %@", size.sizeDescription]];
        LogAdapterApi_Internal(@"error = %@", error);
        [delegate adapterBannerDidFailToLoadWithError:error];
        return;
    }
    
    LogAdapterApi_Internal(@"placementId = %@, size = %@", placementId, size.sizeDescription);

    ISVungleBannerAdapterRouter *bannerRouter = [_bannerPlacementIdToSmashRouter objectForKey:placementId];
    //Set Banner state to - REQUESTING
    bannerRouter.bannerState = REQUESTING;

    [bannerRouter loadBannerAd];
}

- (void)reloadBannerWithAdapterConfig:(nonnull ISAdapterConfig *)adapterConfig
                             delegate:(nonnull id <ISBannerAdapterDelegate>)delegate {
    LogInternal_Warning(@"Unsupported method");
}

- (void)destroyBannerWithAdapterConfig:(nonnull ISAdapterConfig *)adapterConfig {
    NSString *placementId = adapterConfig.settings[kPlacementID];
    LogAdapterApi_Internal(@"placementId = %@", placementId);
    
    ISVungleBannerAdapterRouter *bannerRouter = [_bannerPlacementIdToSmashRouter objectForKey:placementId];
    if (bannerRouter) {
        [_bannerPlacementIdToSmashRouter removeObjectForKey:placementId];
        [bannerRouter destroy];
    }
}

//network does not support banner reload
//return true if banner view needs to be bound again on reload
- (BOOL)shouldBindBannerViewOnReload {
    return YES;
}

- (NSDictionary *)getBannerBiddingDataWithAdapterConfig:(ISAdapterConfig *)adapterConfig {
    return [self getBiddingDataWithAdapterConfig:adapterConfig];
}

#pragma mark - Memory Handling

- (void)releaseMemoryWithAdapterConfig:(nonnull ISAdapterConfig *)adapterConfig {
    // releasing memory currently only for banners
    [self destroyBannerWithAdapterConfig:adapterConfig];
}

#pragma mark - Progressive loading handling

// ability to override the adapter flag with a platform configuration in order to support load while show
- (ISLoadWhileShowSupportState) getLWSSupportState:(ISAdapterConfig *)adapterConfig {
    ISLoadWhileShowSupportState state = LOAD_WHILE_SHOW_BY_NETWORK;
    
    if (adapterConfig != nil && [adapterConfig.settings objectForKey:kLWSSupportedState] != nil) {
        BOOL isLWSSupportedByInstance = [[adapterConfig.settings objectForKey:kLWSSupportedState] boolValue];
        
        if (isLWSSupportedByInstance) {
            state = LOAD_WHILE_SHOW_BY_INSTANCE;
        }
    }
    
    return state;
}

#pragma mark - Legal Methods

- (void)setConsent:(BOOL)consent {
    LogAdapterApi_Internal(@"consent = %@", consent ? @"Opt in" : @"Opt out");
    [VunglePrivacySettings setGDPRStatus:consent];
    [VunglePrivacySettings setGDPRMessageVersion:@""];
}

- (void)setCCPAValue:(BOOL)value {
    // The Vungle CCPA API expects an indication if the user opts in to targeted advertising.
    // Given that this is opposite to the ironSource Mediation CCPA flag of do_not_sell
    // we will use the opposite value of what is passed to this method
    BOOL optIn = !value;
    LogAdapterApi_Internal(@"key = VungleCCPAStatus, value  = %@", optIn ? @"Opt in" : @"Opt out");
    [VunglePrivacySettings setCCPAStatus:optIn];
}

- (void)setMetaDataWithKey:(NSString *)key
                 andValues:(NSMutableArray *) values {
    
    if (values.count == 0) {
        return;
    }
    
    // this is a list of 1 value
    NSString *value = values[0];

    LogAdapterApi_Internal(@"key = %@, value = %@", key, value);
    
    if ([ISMetaDataUtils isValidCCPAMetaDataWithKey:key
                                           andValue:value]) {
        [self setCCPAValue:[ISMetaDataUtils getCCPABooleanValue:value]];
    } else if ([[key lowercaseString] isEqual:kOrientationFlag]) {
        adOrientation = value;
    } else {
        NSString *formattedValue = [ISMetaDataUtils formatValue:value
                                                           forType:(META_DATA_VALUE_BOOL)];
        if ([self isValidCOPPAMetaDataWithKey:key
                                     andValue:formattedValue]) {
            [self setCOPPAValue:[ISMetaDataUtils getCCPABooleanValue:formattedValue]];
        }
    }
}

- (void) setCOPPAValue:(BOOL)value {
    LogAdapterApi_Internal(@"COPPA value = %@", value ? @"Opt in" : @"Opt out");
    [VunglePrivacySettings setCOPPAStatus:value];
}

- (BOOL) isValidCOPPAMetaDataWithKey:(NSString*)key andValue:(NSString*)value {
    return (([key caseInsensitiveCompare:kMetaDataCOPPAKey] == NSOrderedSame) && (value.length > 0));
}

#pragma mark - Helper Methods

- (BOOL)isBannerSizeSupported:(ISBannerSize *)size {
    LogAdapterApi_Internal(@"size = %@", size.sizeDescription);
    
    if ([size.sizeDescription isEqualToString:@"BANNER"]     ||
        [size.sizeDescription isEqualToString:@"LARGE"]      ||
        [size.sizeDescription isEqualToString:@"RECTANGLE"]  ||
        [size.sizeDescription isEqualToString:@"SMART"]
        ) {
        return YES;
    }
    
    return NO;
}

- (NSDictionary *)getBiddingDataWithAdapterConfig:(ISAdapterConfig *)adapterConfig {
    if (_initState == INIT_STATE_FAILED) {
        LogInternal_Error(@"Returning nil as token since init failed");
        return nil;
    }

    NSString *bidderToken = [VungleAds getBiddingToken];
    NSString *returnedToken = bidderToken ?: @"";
    NSString *sdkVersion = [self sdkVersion];
    LogAdapterApi_Internal(@"token = %@", returnedToken);
    LogAdapterApi_Internal(@"sdkVersion = %@", sdkVersion);
    return @{@"token": returnedToken, @"sdkVersion": sdkVersion};
}

@end
