//
//  ISVungleAdapter.m
//  ISVungleAdapter
//
//  Created by Amit Goldhecht on 8/20/14.
//  Copyright (c) 2014 IronSource. All rights reserved.
//
#import "ISVungleAdapterSingleton.h"
#import "ISVungleAdapter.h"
#import <VungleSDK/VungleSDK.h>
#import <VungleSDK/VungleSDKHeaderBidding.h>

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

// Banner state possible values
typedef NS_ENUM(NSUInteger, BANNER_STATE) {
    UNKNOWN,
    REQUESTING,
    REQUESTING_RELOAD,
    SHOWING
};

@interface ISVungleAdapter() < VungleDelegate, ISNetworkInitCallbackProtocol, InitiatorDelegate> {
}

// Rewarded video
@property (nonatomic, strong) ConcurrentMutableDictionary *rewardedVideoPlacementIdToSmashDelegate;
@property (nonatomic, strong) ConcurrentMutableDictionary *rewardedVideoPlacementIdToServerData;
@property (nonatomic, strong) ConcurrentMutableDictionary *rewardedVideoServerDataToSmashDelegate;
@property (nonatomic, strong) ConcurrentMutableSet        *rewardedVideoPlacementIdsForInitCallbacks;

// Interstitial
@property (nonatomic, strong) ConcurrentMutableDictionary *interstitialPlacementIdToSmashDelegate;
@property (nonatomic, strong) ConcurrentMutableDictionary *interstitialPlacementIdToServerData;
@property (nonatomic, strong) ConcurrentMutableDictionary *interstitialServerDataToSmashDelegate;

// Banner
@property (nonatomic, strong) ConcurrentMutableDictionary *bannerPlacementIdToSmashDelegate;
@property (nonatomic, strong) ConcurrentMutableDictionary *bannerPlacementIdToSize;
@property (nonatomic, strong) ConcurrentMutableDictionary *bannerPlacementIdToViewController;
@property (nonatomic, strong) ConcurrentMutableDictionary *bannerPlacementIdToBannerState;
@property (nonatomic, strong) ConcurrentMutableDictionary *bannerPlacementIdToServerData;
@property (nonatomic, strong) ConcurrentMutableDictionary *bannerServerDataToSmashDelegate;

@end

@implementation ISVungleAdapter

#pragma mark - IronSource Protocol Methods

// get adapter version
- (NSString *)version {
    return kAdapterVersion;
}

// get network sdk version
- (NSString *)sdkVersion {
    return VungleSDKVersion;
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
        _rewardedVideoPlacementIdToSmashDelegate        = [ConcurrentMutableDictionary dictionary];
        _rewardedVideoPlacementIdToServerData           = [ConcurrentMutableDictionary dictionary];
        _rewardedVideoServerDataToSmashDelegate         = [ConcurrentMutableDictionary dictionary];
        _rewardedVideoPlacementIdsForInitCallbacks      = [ConcurrentMutableSet set];
        
        // Interstitial
        _interstitialPlacementIdToSmashDelegate         = [ConcurrentMutableDictionary dictionary];
        _interstitialPlacementIdToServerData            = [ConcurrentMutableDictionary dictionary];
        _interstitialServerDataToSmashDelegate          = [ConcurrentMutableDictionary dictionary];
        
        // Banner
        _bannerPlacementIdToSmashDelegate               = [ConcurrentMutableDictionary dictionary];
        _bannerPlacementIdToSize                        = [ConcurrentMutableDictionary dictionary];
        _bannerPlacementIdToViewController              = [ConcurrentMutableDictionary dictionary];
        _bannerPlacementIdToBannerState                 = [ConcurrentMutableDictionary dictionary];
        _bannerPlacementIdToServerData                  = [ConcurrentMutableDictionary dictionary];
        _bannerServerDataToSmashDelegate                = [ConcurrentMutableDictionary dictionary];
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

        #pragma clang diagnostic push
        #pragma clang diagnostic ignored "-Wundeclared-selector"
        [[VungleSDK sharedSDK] performSelector:@selector(setPluginName:version:)
                                    withObject:@"ironsource"
                                    withObject:[self version]];
        #pragma clang diagnostic pop
                
        LogAdapterApi_Internal(@"appId = %@ adaptersDebug = %d", appId, [ISConfigurations getConfigurations].adaptersDebug);
        
        // set Vungle delegates
        [[VungleSDK sharedSDK] setSdkHBDelegate:[ISVungleAdapterSingleton sharedInstance]];
        [[VungleSDK sharedSDK] setDelegate:[ISVungleAdapterSingleton sharedInstance]];
        
        // set debug log
        [[VungleSDK sharedSDK] setLoggingEnabled:[ISConfigurations getConfigurations].adaptersDebug];
        
        // initiate singelton
        [[ISVungleAdapterSingleton sharedInstance] addFirstInitiatorDelegate:self];
        
        NSError *error;
        
        // init Vungle sdk
        if (![[VungleSDK sharedSDK] startWithAppId:appId
                                             error:&error]) {
            _initState = INIT_STATE_FAILED;
            LogAdapterApi_Internal(@"Vungle SDK init failed - error = %@", error);
        }
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
    NSArray *rewardedVideoPlacementIDs = _rewardedVideoPlacementIdToSmashDelegate.allKeys;
    
    for (NSString *placementId in rewardedVideoPlacementIDs) {
        if ([_rewardedVideoPlacementIdsForInitCallbacks hasObject:placementId]) {
            [[_rewardedVideoPlacementIdToSmashDelegate objectForKey:placementId] adapterRewardedVideoInitSuccess];
        } else {
            [self loadRewardedVideoInternalWithPlacement:placementId];
        }
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
    LogInternal_Internal(@"");
    
    NSError *error = [ISError createError:ERROR_CODE_INIT_FAILED withMessage:errorMessage];
    
    // rewarded video
    NSArray *rewardedVideoPlacementIDs = _rewardedVideoPlacementIdToSmashDelegate.allKeys;
    
    for (NSString *placementId in rewardedVideoPlacementIDs) {
        if ([_rewardedVideoPlacementIdsForInitCallbacks hasObject:placementId]) {
            [[_rewardedVideoPlacementIdToSmashDelegate objectForKey:placementId] adapterRewardedVideoInitFailed:error];
        } else {
            [[_rewardedVideoPlacementIdToSmashDelegate objectForKey:placementId] adapterRewardedVideoHasChangedAvailability:NO];
        }
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
    
    // add to rewarded video delegate map
    [_rewardedVideoPlacementIdToSmashDelegate setObject:delegate
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
    
    // add to rewarded video delegate map
    [_rewardedVideoPlacementIdToSmashDelegate setObject:delegate
                                                 forKey:placementId];
    
    // add rewarded video to singleton
    [[ISVungleAdapterSingleton sharedInstance] addRewardedVideoDelegate:self
                                                         forPlacementID:placementId];
    
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
    [_rewardedVideoPlacementIdToServerData setObject:serverData
                                              forKey:placementId];
    [_rewardedVideoServerDataToSmashDelegate setObject:delegate
                                                forKey:serverData];
    
    // add rewarded video to singleton - used here instead of Init callback for progressive loading only (supported only on bidding flow)
    [[ISVungleAdapterSingleton sharedInstance] addRewardedVideoDelegate:self
                                                         forPlacementID:serverData];
    
    [self loadRewardedVideoInternalWithPlacement:placementId];
}

- (void)fetchRewardedVideoForAutomaticLoadWithAdapterConfig:(ISAdapterConfig *)adapterConfig
                                                   delegate:(id<ISRewardedVideoAdapterDelegate>)delegate {
    NSString *placementId = adapterConfig.settings[kPlacementID];
    [self loadRewardedVideoInternalWithPlacement:placementId];
}

- (void)loadRewardedVideoInternalWithPlacement:(NSString *)placementId {
    LogAdapterApi_Internal(@"placementId = %@", placementId);

    id<ISRewardedVideoAdapterDelegate> delegate = [_rewardedVideoPlacementIdToSmashDelegate objectForKey:placementId];
    NSString *serverData = [_rewardedVideoPlacementIdToServerData objectForKey:placementId];
    BOOL loadAttemptSucceeded = YES;
    NSError *error = nil;
    
    if (serverData) {
        // Load rewarded video for bidding instance
        loadAttemptSucceeded = [[VungleSDK sharedSDK] loadPlacementWithID:placementId
                                                                 adMarkup:serverData
                                                                    error:&error];
    } else {
        // Load rewarded video for non bidding instance
        loadAttemptSucceeded = [[VungleSDK sharedSDK] loadPlacementWithID:placementId
                                                                    error:&error];
    }
    
    if (!loadAttemptSucceeded) {
        [delegate adapterRewardedVideoHasChangedAvailability:NO];
        
        if (error) {
            LogAdapterApi_Internal(@"Load attempt failed, error = %@", error);
            [delegate adapterRewardedVideoDidFailToLoadWithError:error];
        }
    }
}

- (void)showRewardedVideoWithViewController:(UIViewController *)viewController
                              adapterConfig:(ISAdapterConfig *)adapterConfig
                                   delegate:(id<ISRewardedVideoAdapterDelegate>)delegate {
    NSString *placementId = adapterConfig.settings[kPlacementID];
    LogAdapterApi_Internal(@"placementId = %@", placementId);
    
    [delegate adapterRewardedVideoHasChangedAvailability:NO];
    
    if (![self isAdCachedForPlacement:placementId]) {
        NSError *error = [NSError errorWithDomain:kAdapterName
                                             code:kShowErrorNotCached
                                         userInfo:@{NSLocalizedDescriptionKey : @"Show error. ad not cached"}];
        LogAdapterApi_Internal(@"error = %@", error);
        [delegate adapterRewardedVideoDidFailToShowWithError:error];
        return;
    }
    
    dispatch_async(dispatch_get_main_queue(), ^{
        NSDictionary *options = [self createAdOptionsWithDynamicUserID:YES];
        NSString *serverData = [_rewardedVideoPlacementIdToServerData objectForKey:placementId];
        BOOL showAttemptSucceeded = YES;
        NSError *error;
        
        if (serverData) {
            // Show rewarded video for bidding instance
            showAttemptSucceeded = [[VungleSDK sharedSDK] playAd:viewController
                                                         options:options
                                                     placementID:placementId
                                                        adMarkup:serverData
                                                           error:&error];
        } else {
            // Show rewarded video for non bidding instance
            showAttemptSucceeded = [[VungleSDK sharedSDK] playAd:viewController
                                                         options:options
                                                     placementID:placementId
                                                           error:&error];
        }
        
        if (!showAttemptSucceeded) {
            if (!error) {
                error = [NSError errorWithDomain:kAdapterName
                                            code:ERROR_CODE_NO_ADS_TO_SHOW
                                        userInfo:@{NSLocalizedDescriptionKey : @"Show rewarded video failed - no ads to show"}];
            }
            
            LogAdapterApi_Internal(@"Show attempt failed, error = %@", error);
            [delegate adapterRewardedVideoDidFailToShowWithError:error];
        }
    });
}

- (BOOL)hasRewardedVideoWithAdapterConfig:(ISAdapterConfig *)adapterConfig {
    NSString *placementId = adapterConfig.settings[kPlacementID];

    // Vungle cache ads that were loaded in the last week.
    // This means that [[VungleSDK sharedSDK] isAdCachedForPlacementID:] could return YES for placements that we didn't try to load during this session.
    // This is the reason we also check if the placementId is contained in the ConcurrentMutableDictionary
    if (![_rewardedVideoPlacementIdToSmashDelegate hasObjectForKey:placementId]) {
        return NO;
    }
    
    NSString *serverData = [_rewardedVideoPlacementIdToServerData objectForKey:placementId];

    if (serverData) {
        return [[VungleSDK sharedSDK] isAdCachedForPlacementID:placementId
                                                      adMarkup:serverData];
    }
    
    return [[VungleSDK sharedSDK] isAdCachedForPlacementID:placementId];
}

- (NSDictionary *)getRewardedVideoBiddingDataWithAdapterConfig:(ISAdapterConfig *)adapterConfig {
    return [self getBiddingDataWithAdapterConfig:adapterConfig];
}

#pragma mark - Rewarded Video Delegate

-(void)rewardedVideoPlayabilityUpdate:(BOOL)isAdPlayable
                          placementID:(NSString *)placementID
                           serverData:(NSString *)serverData
                                error:(NSError *)error {
    
    LogAdapterDelegate_Internal(@"placementId = %@, isAdPlayable = %@, error = %@", placementID, isAdPlayable ? @"YES" : @"NO", error);

    // get delegate
    id<ISRewardedVideoAdapterDelegate> rewardedVideoDelegate = [self getRewardedVideoSmashDelegateWithPlacementId:placementID
                                                                                                    andServerData:serverData];

    if (isAdPlayable && ![self isAdCachedForPlacement:placementID]) {
        // When isAdPlayable is YES the isAdCachedForPlacement should also return YES
        // If for some reason that is not the case we can also catch it on the Show method
        LogAdapterDelegate_Internal(@"Vungle Ad is playable but not ready to be shown");
    }
        
    // rewarded video
    if (rewardedVideoDelegate) {
        if (isAdPlayable) {
            [rewardedVideoDelegate adapterRewardedVideoHasChangedAvailability:YES];
        } else {
            [rewardedVideoDelegate adapterRewardedVideoHasChangedAvailability:NO];
            
            if (error != nil) {
                [rewardedVideoDelegate adapterRewardedVideoDidFailToLoadWithError:error];
            }
        }
    }
}

-(void)rewardedVideoAdViewedForPlacement:(NSString *)placementID
                              serverData:(NSString *)serverData {
    LogAdapterDelegate_Internal(@"placementID = %@", placementID);

    // get delegate
    id<ISRewardedVideoAdapterDelegate> rewardedVideoDelegate = [self getRewardedVideoSmashDelegateWithPlacementId:placementID
                                                                                                    andServerData:serverData];

    if (rewardedVideoDelegate) {
        [rewardedVideoDelegate adapterRewardedVideoDidOpen];
        [rewardedVideoDelegate adapterRewardedVideoDidStart];
    }

}

-(void)rewardedVideoDidClickForPlacementID:(NSString *)placementID
                                serverData:(NSString *)serverData {
    LogAdapterDelegate_Internal(@"placementId = %@", placementID);

    // get delegate
    id<ISRewardedVideoAdapterDelegate> rewardedVideoDelegate = [self getRewardedVideoSmashDelegateWithPlacementId:placementID
                                                                                                    andServerData:serverData];

    if (rewardedVideoDelegate) {
        [rewardedVideoDelegate adapterRewardedVideoDidClick];
    }
}

-(void)rewardedVideoDidRewardedAdWithPlacementID:(NSString *)placementID
                                      serverData:(NSString *)serverData {
    LogAdapterDelegate_Internal(@"placementID = %@", placementID);

    // get delegate
    id<ISRewardedVideoAdapterDelegate> rewardedVideoDelegate = [self getRewardedVideoSmashDelegateWithPlacementId:placementID
                                                                                                    andServerData:serverData];

    if (rewardedVideoDelegate) {
        [rewardedVideoDelegate adapterRewardedVideoDidReceiveReward];
    }
}

-(void)rewardedVideoDidCloseAdWithPlacementID:(NSString *)placementID
                                   serverData:(NSString *)serverData {
    LogAdapterDelegate_Internal(@"placementId = %@", placementID);

    // get delegate
    id<ISRewardedVideoAdapterDelegate> rewardedVideoDelegate = [self getRewardedVideoSmashDelegateWithPlacementId:placementID
                                                                                                    andServerData:serverData];

    if (rewardedVideoDelegate) {
        [rewardedVideoDelegate adapterRewardedVideoDidEnd];
        [rewardedVideoDelegate adapterRewardedVideoDidClose];
    }
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

    // add to interstitial delegate map
    [_interstitialPlacementIdToSmashDelegate setObject:delegate
                                                forKey:placementId];

    // add interstitial to singleton
    [[ISVungleAdapterSingleton sharedInstance] addInterstitialDelegate:self
                                                        forPlacementID:placementId];
    
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
    [_interstitialPlacementIdToServerData setObject:serverData
                                             forKey:adapterConfig.settings[kPlacementID]];
    [_interstitialServerDataToSmashDelegate setObject:delegate
                                               forKey:serverData];
    
    [self loadInterstitialInternalWithPlacement:placementId];
}

- (void)loadInterstitialWithAdapterConfig:(ISAdapterConfig *)adapterConfig
                                 delegate:(id<ISInterstitialAdapterDelegate>)delegate {
    NSString *placementId = adapterConfig.settings[kPlacementID];
    [self loadInterstitialInternalWithPlacement:placementId];
}

- (void)loadInterstitialInternalWithPlacement:(NSString *)placementId {
    LogAdapterApi_Internal(@"placementID = %@", placementId);

    id<ISInterstitialAdapterDelegate> delegate = [_interstitialPlacementIdToSmashDelegate objectForKey:placementId];
    NSString *serverData = [_interstitialPlacementIdToServerData objectForKey:placementId];
    BOOL loadAttemptSucceeded = YES;
    NSError *error;
    
    if (serverData) {
        // Load interstitial for bidding instance
        loadAttemptSucceeded = [[VungleSDK sharedSDK] loadPlacementWithID:placementId
                                                                 adMarkup:serverData
                                                                    error:&error];
    } else {
        // Load interstitial for non bidding instance
        loadAttemptSucceeded = [[VungleSDK sharedSDK] loadPlacementWithID:placementId
                                                                    error:&error];
    }
    
    if (!loadAttemptSucceeded) {
        if (!error) {
            error = [NSError errorWithDomain:kAdapterName
                                        code:ERROR_CODE_GENERIC
                                    userInfo:@{NSLocalizedDescriptionKey : @"Load attempt failed"}];
        }
        
        LogAdapterApi_Internal(@"Load attempt failed, error = %@", error);
        [delegate adapterInterstitialDidFailToLoadWithError:error];
    }
}

- (void)showInterstitialWithViewController:(UIViewController *)viewController
                             adapterConfig:(ISAdapterConfig *)adapterConfig
                                  delegate:(id<ISInterstitialAdapterDelegate>)delegate {
    NSString *placementId = adapterConfig.settings[kPlacementID];
    LogAdapterApi_Internal(@"placementId = %@", placementId);
    
    if (![self isAdCachedForPlacement:placementId]) {
        NSError *error = [NSError errorWithDomain:kAdapterName
                                             code:kShowErrorNotCached
                                         userInfo:@{NSLocalizedDescriptionKey : @"Show error. ad not cached"}];
        LogAdapterApi_Internal(@"error = %@", error);
        [delegate adapterInterstitialDidFailToShowWithError:error];
        return;
    }
    
    dispatch_async(dispatch_get_main_queue(), ^{
        NSDictionary *options = [self createAdOptionsWithDynamicUserID:NO];
        NSString *serverData = [_interstitialPlacementIdToServerData objectForKey:placementId];
        BOOL showAttemptSucceeded = YES;
        NSError *error;
        
        if (serverData) {
            // Show interstitial for bidding instance
            showAttemptSucceeded = [[VungleSDK sharedSDK] playAd:viewController
                                                         options:options
                                                     placementID:placementId
                                                        adMarkup:serverData
                                                           error:&error];
        } else {
            // Show interstitial for non bidding instance
            showAttemptSucceeded = [[VungleSDK sharedSDK] playAd:viewController
                                                         options:options
                                                     placementID:placementId
                                                           error:&error];
        }
        
        if (!showAttemptSucceeded) {
            if (!error) {
                error = [NSError errorWithDomain:kAdapterName
                                            code:ERROR_CODE_NO_ADS_TO_SHOW
                                        userInfo:@{NSLocalizedDescriptionKey : @"Show interstitial failed - no ads to show"}];
            }
            
            LogAdapterApi_Internal(@"Show attempt failed, error = %@", error);
            [delegate adapterInterstitialDidFailToShowWithError:error];
        }
    });
}

- (BOOL)hasInterstitialWithAdapterConfig:(ISAdapterConfig *)adapterConfig {
    NSString *placementId = adapterConfig.settings[kPlacementID];

    // Vungle cache ads that were loaded in the last week.
    // This means that [[VungleSDK sharedSDK] isAdCachedForPlacementID:] could return YES for placements that we didn't try to load during this session.
    // This is the reason we also check if the placementId is contained in the ConcurrentMutableDictionary
    if (![_interstitialPlacementIdToSmashDelegate hasObjectForKey:placementId]) {
        return NO;
    }
    
    NSString *serverData = [_interstitialPlacementIdToServerData objectForKey:placementId];

    if (serverData) {
        return [[VungleSDK sharedSDK] isAdCachedForPlacementID:placementId
                                                      adMarkup:serverData];
    }
    
    return [[VungleSDK sharedSDK] isAdCachedForPlacementID:placementId];
}

- (NSDictionary *)getInterstitialBiddingDataWithAdapterConfig:(ISAdapterConfig *)adapterConfig {
    return [self getBiddingDataWithAdapterConfig:adapterConfig];
}

#pragma mark - Interstitial Delegate

-(void)interstitialPlayabilityUpdate:(BOOL)isAdPlayable
                         placementID:(NSString *)placementID
                          serverData:(NSString *)serverData
                               error:(NSError *)error {
    
    LogAdapterDelegate_Internal(@"placementId = %@, isAdPlayable = %@, error = %@", placementID, isAdPlayable ? @"YES" : @"NO", error);
    
    // get delegate
    id<ISInterstitialAdapterDelegate> interstitialDelegate = [self getInterstitialSmashDelegateWithPlacementId:placementID
                                                                                                 andServerData:serverData];
    
    if (isAdPlayable && ![self isAdCachedForPlacement:placementID]) {
        // When isAdPlayable is YES the isAdCachedForPlacement should also return YES
        // If for some reason that is not the case we can also catch it on the Show method
        LogAdapterDelegate_Internal(@"Vungle Ad is playable but not ready to be shown");
    }
        
    if (interstitialDelegate) {
        if (isAdPlayable) {
            [interstitialDelegate adapterInterstitialDidLoad];
        } else if (error != nil) {
                [interstitialDelegate adapterInterstitialDidFailToLoadWithError:error];
        }
    }
}


-(void)interstitialVideoAdViewedForPlacement:(NSString *)placementID
                                  serverData:(NSString *)serverData {
    LogAdapterDelegate_Internal(@"placementID = %@", placementID);
    
    // get delegate
    id<ISInterstitialAdapterDelegate> interstitialDelegate = [self getInterstitialSmashDelegateWithPlacementId:placementID
                                                                                                 andServerData:serverData];

    if (interstitialDelegate) {
        [interstitialDelegate adapterInterstitialDidOpen];
        [interstitialDelegate adapterInterstitialDidShow];
    }

}

-(void)interstitialDidClickForPlacementID:(NSString *)placementID
                               serverData:(NSString *)serverData {
    LogAdapterDelegate_Internal(@"placementId = %@", placementID);
    
    // get delegate
    id<ISInterstitialAdapterDelegate> interstitialDelegate = [self getInterstitialSmashDelegateWithPlacementId:placementID
                                                                                                 andServerData:serverData];

    if (interstitialDelegate) {
        [interstitialDelegate adapterInterstitialDidClick];
    }
}

-(void)interstitialDidCloseAdWithPlacementID:(NSString *)placementID
                                  serverData:(NSString *)serverData {
    LogAdapterDelegate_Internal(@"placementId = %@", placementID);
    
    // get delegate
    id<ISInterstitialAdapterDelegate> interstitialDelegate = [self getInterstitialSmashDelegateWithPlacementId:placementID
                                                                                                 andServerData:serverData];

    if (interstitialDelegate) {
        [interstitialDelegate adapterInterstitialDidClose];
    }
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

    // disable banner refresh
    [[VungleSDK sharedSDK] disableBannerRefresh];
    
    // add to banner delegate map
    [_bannerPlacementIdToSmashDelegate setObject:delegate
                                          forKey:placementId];
       
    // add banner to singleton
    [[ISVungleAdapterSingleton sharedInstance] addBannerDelegate:self
                                                  forPlacementID:placementId];

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
    [_bannerPlacementIdToServerData setObject:serverData
                                       forKey:placementId];
    [_bannerServerDataToSmashDelegate setObject:delegate
                                         forKey:serverData];
    
    // get current state
    BANNER_STATE currentBannerState = [self getCurrentBannerState:placementId];

    if (currentBannerState == SHOWING) {
        [self dismissBannerWithServerData:serverData
                           viewController:viewController
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

    // get current state
    BANNER_STATE currentBannerState = [self getCurrentBannerState:placementId];

    if (currentBannerState == SHOWING) {
        [self dismissBannerWithServerData:nil
                           viewController:viewController
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
                     viewController:(UIViewController *)viewController
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
        
    // add banner state to dictionary - REQUESTING_RELOAD
    [_bannerPlacementIdToBannerState setObject:[self getBannerStateObject:REQUESTING_RELOAD]
                                        forKey:placementId];

    // A Vungle banner ad is currently showing. We would like to dismiss it before loading a new Vungle banner
    if (serverData) {
        // Dismisses banner for bidding instance
        [[VungleSDK sharedSDK] finishDisplayingAd:placementId
                                         adMarkup:serverData];
    } else {
        // Dismisses banner for non bidding instance
        [[VungleSDK sharedSDK] finishDisplayingAd:placementId];
    }
 
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

    [_bannerPlacementIdToSize setObject:size
                                 forKey:placementId];
    [_bannerPlacementIdToViewController setObject:viewController
                                           forKey:placementId];

    // add banner state to dictionary - REQUESTING
    [_bannerPlacementIdToBannerState setObject:[self getBannerStateObject:REQUESTING]
                                        forKey:placementId];
    
    NSString *serverData = [_bannerPlacementIdToServerData objectForKey:placementId];
    BOOL loadAttemptSucceeded = YES;
    NSError *error;
    
    // Vungle load API for MREC is different than the API for other banner sizes
    if ([size.sizeDescription isEqualToString:@"RECTANGLE"]) {
        // MREC load
        if (serverData) {
            // Load MREC for bidding instance
            loadAttemptSucceeded = [[VungleSDK sharedSDK] loadPlacementWithID:placementId
                                                                     adMarkup:serverData
                                                                        error:&error];
        } else {
            // Load MREC for non bidding instance
            loadAttemptSucceeded = [[VungleSDK sharedSDK] loadPlacementWithID:placementId
                                                                        error:&error];
        }
    } else {
        // get size
        VungleAdSize vungleBannerSize = [self getBannerSize:size];
        
        // banner load
        if (serverData) {
            // Load banner for bidding instance
            loadAttemptSucceeded = [[VungleSDK sharedSDK] loadPlacementWithID:placementId
                                                                     adMarkup:serverData
                                                                     withSize:vungleBannerSize
                                                                        error:&error];
        } else {
            // Load banner for non bidding instance
            loadAttemptSucceeded = [[VungleSDK sharedSDK] loadPlacementWithID:placementId
                                                                     withSize:vungleBannerSize
                                                                        error:&error];
        }
    }
    
    if (!loadAttemptSucceeded) {
        LogAdapterApi_Internal(@"Load attempt failed, error = %@", error);
        [[_bannerPlacementIdToSmashDelegate objectForKey:placementId] adapterBannerDidFailToLoadWithError:error];
    }
}

- (void)reloadBannerWithAdapterConfig:(nonnull ISAdapterConfig *)adapterConfig
                             delegate:(nonnull id <ISBannerAdapterDelegate>)delegate {
    LogInternal_Warning(@"Unsupported method");
}

- (void)destroyBannerWithAdapterConfig:(nonnull ISAdapterConfig *)adapterConfig {
    NSString *placementId = adapterConfig.settings[kPlacementID];
    NSString *serverData = [_bannerPlacementIdToServerData objectForKey:placementId];
    
    // remove from dictionaries
    [_bannerPlacementIdToSize removeObjectForKey:placementId];
    [_bannerPlacementIdToViewController removeObjectForKey:placementId];
    [_bannerPlacementIdToBannerState removeObjectForKey:placementId];
    
    LogAdapterApi_Internal(@"placementId = %@", placementId);
    
    // call Vungle finish
    if (serverData) {
        [[VungleSDK sharedSDK] finishDisplayingAd:placementId
                                         adMarkup:serverData];
    } else {
        [[VungleSDK sharedSDK] finishDisplayingAd:placementId];
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

#pragma mark - Banner Delegate

-(void)bannerPlayabilityUpdate:(BOOL)isAdPlayable
                   placementID:(NSString *)placementID
                    serverData:(NSString *)serverData
                         error:(NSError *)error {
    
    LogAdapterDelegate_Internal(@"placementId = %@, isAdPlayable = %@, error = %@", placementID, isAdPlayable ? @"YES" : @"NO", error);
    
    // get delegate
    id<ISBannerAdapterDelegate> bannerDelegate = [self getBannerSmashDelegateWithPlacementId:placementID
                                                                               andServerData:serverData];
    
    if (bannerDelegate) {
        // if we are in a requesting state we handle the update, otherwise we ignore
        BANNER_STATE currentBannerState = [self getCurrentBannerState:placementID];
        LogAdapterDelegate_Internal(@"currentBannerState = %@", [self getBannerStateString:currentBannerState]);
        
        if (currentBannerState == REQUESTING) {
            // handle banners
            if (isAdPlayable) {
                // get size
                ISBannerSize *size = [_bannerPlacementIdToSize objectForKey:placementID];
                
                if (![self isBannerAdCachedForPlacement:placementID
                                             serverData:serverData]) {
                    // When isAdPlayable is YES the isBannerAdCachedForPlacement should also return YES
                    // If for some reason that is not the case we might want to not show the banner
                    LogAdapterDelegate_Internal(@"Vungle Banner Ad is playable but not ready to be shown");
                }
                
                dispatch_async(dispatch_get_main_queue(), ^{
                    // create container
                    UIView *containerView = [self createBannerViewContainer:size];
                    NSError *vungleError;
                    
                    // call Vungle api for showing banner in our container
                    if (serverData.length) {
                        [[VungleSDK sharedSDK] addAdViewToView:containerView
                                                   withOptions:@{}
                                                   placementID:placementID
                                                      adMarkup:serverData
                                                         error:&vungleError];
                    } else {
                        [[VungleSDK sharedSDK] addAdViewToView:containerView
                                                   withOptions:@{}
                                                   placementID:placementID
                                                         error:&vungleError];
                    }
                    
                    if (vungleError) {
                        LogAdapterDelegate_Internal(@"Vungle failed to add view - vungleError = %@", vungleError);
                        [bannerDelegate adapterBannerDidFailToLoadWithError:vungleError];
                    } else {
                        // update banner state - SHOWING
                        [_bannerPlacementIdToBannerState setObject:[self getBannerStateObject:SHOWING]
                                                            forKey:placementID];
                        // call delegate success
                        [bannerDelegate adapterBannerDidLoad:containerView];
                    }
                });
            } else {
                // update banner state - UNKNOWN
                [_bannerPlacementIdToBannerState setObject:[self getBannerStateObject:UNKNOWN]
                                                    forKey:placementID];
                
                NSError *smashError = [ISError createError:ERROR_BN_LOAD_NO_FILL
                                               withMessage:[NSString stringWithFormat:@"Vungle - banner no ads to show for placementId = %@", placementID]];
                
                [bannerDelegate adapterBannerDidFailToLoadWithError:smashError];
            }
        }
    }
}

-(void)bannerAdViewedForPlacement:(NSString *)placementID
                       serverData:(NSString *)serverData {
    LogAdapterDelegate_Internal(@"placementID = %@", placementID);
    
    // get delegate
    id<ISBannerAdapterDelegate> bannerDelegate = [self getBannerSmashDelegateWithPlacementId:placementID
                                                                               andServerData:serverData];

    if (bannerDelegate) {
        [bannerDelegate adapterBannerDidShow];
    }
}

-(void)bannerDidClickForPlacementID:(NSString *)placementID
                         serverData:(NSString *)serverData {
    LogAdapterDelegate_Internal(@"placementId = %@", placementID);
    
    // get delegate
    id<ISBannerAdapterDelegate> bannerDelegate = [self getBannerSmashDelegateWithPlacementId:placementID
                                                                               andServerData:serverData];

    if (bannerDelegate) {
        [bannerDelegate adapterBannerDidClick];
    }
}

-(void)bannerWillAdLeaveApplicationForPlacementID:(NSString *)placementID
                                       serverData:(NSString *)serverData {
    LogAdapterDelegate_Internal(@"placementID = %@", placementID);

    // get delegate
    id<ISBannerAdapterDelegate> bannerDelegate = [self getBannerSmashDelegateWithPlacementId:placementID
                                                                               andServerData:serverData];

    if (bannerDelegate) {
        [bannerDelegate adapterBannerWillLeaveApplication];
    }
}

-(void)bannerDidCloseAdWithPlacementID:(NSString *)placementID
                            serverData:(NSString *)serverData {
    LogAdapterDelegate_Internal(@"placementId = %@", placementID);
    
    // get delegate
    id<ISBannerAdapterDelegate> bannerDelegate = [self getBannerSmashDelegateWithPlacementId:placementID
                                                                               andServerData:serverData];

    if (bannerDelegate) {
        BANNER_STATE currentBannerState = [self getCurrentBannerState:placementID];
        LogAdapterDelegate_Internal(@"currentBannerState = %@", [self getBannerStateString:currentBannerState]);
        
        if (currentBannerState == REQUESTING_RELOAD) {
            
            // get size
            ISBannerSize *size = [_bannerPlacementIdToSize objectForKey:placementID];
            
            // get view controller
            UIViewController *viewController = [_bannerPlacementIdToViewController objectForKey:placementID];
            
            if (size && viewController) {
                // The previously shown Vungle banner ad was dismissed and a new banner ad can be loaded
                [self loadBannerInternalWithPlacement:placementID
                                       viewController:viewController
                                                 size:size
                                             delegate:bannerDelegate];
            }
        }
    }
}

#pragma mark - Memory Handling

- (void)releaseMemoryWithAdapterConfig:(nonnull ISAdapterConfig *)adapterConfig {
    // releasing memory currently only for banners
    NSString *placementId = adapterConfig.settings[kPlacementID];
    ISBannerSize *size = [_bannerPlacementIdToSize objectForKey:placementId];
    
    if (size) {
        [self destroyBannerWithAdapterConfig:adapterConfig];
    }
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
    LogAdapterApi_Internal(@"consent = %@", consent ? @"VungleConsentAccepted" : @"VungleConsentDenied");
    [[VungleSDK sharedSDK] updateConsentStatus:(consent ? VungleConsentAccepted : VungleConsentDenied)
                         consentMessageVersion:@""];
}

- (void) setCCPAValue:(BOOL)value {
    // The Vungle CCPA API expects an indication if the user opts in to targeted advertising.
    // Given that this is opposite to the ironSource Mediation CCPA flag of do_not_sell
    // we will use the opposite value of what is passed to this method
    BOOL optIn = !value;
    VungleCCPAStatus status = optIn ? VungleCCPAAccepted : VungleCCPADenied;
    LogAdapterApi_Internal(@"key = VungleCCPAStatus, value  = %@", optIn ? @"VungleCCPAAccepted" : @"VungleCCPADenied");
    [[VungleSDK sharedSDK] updateCCPAStatus:status];
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
    LogAdapterApi_Internal(@"value = %@", value ? @"YES" : @"NO");
    [[VungleSDK sharedSDK] updateCOPPAStatus:value];
}

- (BOOL) isValidCOPPAMetaDataWithKey:(NSString*)key andValue:(NSString*)value {
    return (([key caseInsensitiveCompare:kMetaDataCOPPAKey] == NSOrderedSame) && (value.length > 0));
}

#pragma mark - Helper Methods

- (id<ISRewardedVideoAdapterDelegate>)getRewardedVideoSmashDelegateWithPlacementId:(NSString *)placementID
                                                                     andServerData:(NSString *)serverData {
    id<ISRewardedVideoAdapterDelegate> rewardedVideoDelegate;
    if (serverData.length && [_rewardedVideoServerDataToSmashDelegate hasObjectForKey:serverData]) {
        rewardedVideoDelegate = [_rewardedVideoServerDataToSmashDelegate objectForKey:serverData];
    } else {
        rewardedVideoDelegate = [_rewardedVideoPlacementIdToSmashDelegate objectForKey:placementID];
    }
    
    return rewardedVideoDelegate;
}

- (id<ISInterstitialAdapterDelegate>)getInterstitialSmashDelegateWithPlacementId:(NSString *)placementID
                                                                   andServerData:(NSString *)serverData {
    id<ISInterstitialAdapterDelegate> interstitialDelegate;
    if (serverData.length && [_interstitialServerDataToSmashDelegate hasObjectForKey:serverData]) {
        interstitialDelegate = [_interstitialServerDataToSmashDelegate objectForKey:serverData];
    } else {
        interstitialDelegate = [_interstitialPlacementIdToSmashDelegate objectForKey:placementID];
    }
    
    return interstitialDelegate;
}

- (id<ISBannerAdapterDelegate>)getBannerSmashDelegateWithPlacementId:(NSString *)placementID
                                                       andServerData:(NSString *)serverData {
    id<ISBannerAdapterDelegate> bannerDelegate;
    if (serverData.length && [_bannerServerDataToSmashDelegate hasObjectForKey:serverData]) {
        bannerDelegate = [_bannerServerDataToSmashDelegate objectForKey:serverData];
    } else {
        bannerDelegate = [_bannerPlacementIdToSmashDelegate objectForKey:placementID];
    }
    
    return bannerDelegate;
}

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

- (VungleAdSize)getBannerSize:(ISBannerSize *)size {
    VungleAdSize vungleAdSize = VungleAdSizeUnknown;
    
    if ([size.sizeDescription isEqualToString:@"BANNER"]     ||
        [size.sizeDescription isEqualToString:@"LARGE"]
        ) {
        vungleAdSize = VungleAdSizeBanner;
    } else if ([size.sizeDescription isEqualToString:@"RECTANGLE"]) {
        // no need to assign rectangle size because the load is different from banner and does not need it
    } else if ([size.sizeDescription isEqualToString:@"SMART"]) {
        if (UI_USER_INTERFACE_IDIOM() == UIUserInterfaceIdiomPad) {
            vungleAdSize = VungleAdSizeBannerLeaderboard;
        } else {
            vungleAdSize = VungleAdSizeBanner;
        }
    }

    return vungleAdSize;
}

- (UIView *)createBannerViewContainer:(ISBannerSize *)size {
    
    // create rect
    CGRect rect = CGRectZero;
    
    // set rect size
    if ([size.sizeDescription isEqualToString:@"BANNER"] || [size.sizeDescription isEqualToString:@"LARGE"]) {
        rect = CGRectMake(0, 0, 320, 50);
    } else if ([size.sizeDescription isEqualToString:@"RECTANGLE"]) {
        rect = CGRectMake(0, 0, 300, 250);
    } else if ([size.sizeDescription isEqualToString:@"SMART"]) {
        if (UI_USER_INTERFACE_IDIOM() == UIUserInterfaceIdiomPad) {
            rect = CGRectMake(0, 0, 728, 90);
        } else {
            rect = CGRectMake(0, 0, 320, 50);
        }
    }
    
    // return container view
    UIView *containerView = [[UIView alloc] initWithFrame:rect];
    return containerView;
}

- (NSNumber *)getBannerStateObject:(BANNER_STATE)state {
    LogAdapterApi_Internal(@"for state = %@", [self getBannerStateString:state]);
    NSNumber *number = [NSNumber numberWithUnsignedLong:(unsigned long)state];
    return number;
}

- (NSString *)getBannerStateString:(BANNER_STATE)state {
    switch (state) {
        case UNKNOWN:
            return @"UNKNOWN";
        case REQUESTING:
            return @"REQUESTING";
        case REQUESTING_RELOAD:
            return @"REQUESTING_RELOAD";
        case SHOWING:
            return @"SHOWING";
    }
    
    return @"UNKNOWN";
}

- (BANNER_STATE)getCurrentBannerState:(NSString *)placementId {
    if ([_bannerPlacementIdToBannerState objectForKey:placementId] != nil) {
        BANNER_STATE currentBannerState = (BANNER_STATE)[[_bannerPlacementIdToBannerState objectForKey:placementId] intValue];
        return currentBannerState;
    }
    
    return UNKNOWN;
}

- (NSDictionary *)getBiddingDataWithAdapterConfig:(ISAdapterConfig *)adapterConfig {
    if (_initState == INIT_STATE_FAILED) {
        LogInternal_Error(@"Returning nil as token since init failed");
        return nil;
    }
    
    NSString *placementId = adapterConfig.settings[kPlacementID];
    NSString *bidderToken = [[VungleSDK sharedSDK] currentSuperTokenForPlacementID:placementId forSize:0];
    NSString *returnedToken = bidderToken? bidderToken : @"";
    NSString *sdkVersion = [self sdkVersion];
    LogAdapterApi_Internal(@"token = %@", returnedToken);
    LogAdapterApi_Internal(@"sdkVersion = %@", sdkVersion);
    return @{@"token": returnedToken, @"sdkVersion": sdkVersion};
}

- (NSDictionary *)createAdOptionsWithDynamicUserID:(BOOL) shouldIncludeDynamicUserID {
    NSMutableDictionary *optionsSet = [[NSMutableDictionary alloc] init];
    
    // set Dynamic user id
    if (shouldIncludeDynamicUserID && [self dynamicUserId] != nil) {
        [optionsSet setObject:[self dynamicUserId]
                       forKey:VunglePlayAdOptionKeyUser];
    }

    // Add orientation configuration
    if (adOrientation.length) {
        if ([adOrientation isEqual:kPortraitOrientation]) {
            uiOrientation = @(UIInterfaceOrientationMaskPortrait);
        } else if ([adOrientation isEqual:kLandscapeOrientation]) {
            uiOrientation  = @(UIInterfaceOrientationMaskLandscape);
        } else if ([adOrientation isEqual:kAutoRotateOrientation]) {
            uiOrientation  = @(UIInterfaceOrientationMaskAll);
        }
        
        if (uiOrientation != nil) {
            // add to dictionary
            [optionsSet setObject:uiOrientation
                           forKey:VunglePlayAdOptionKeyOrientations];
            LogInternal_Internal(@"set Vungle ad orientation - %@",adOrientation );
        }
    }
    
    return [optionsSet mutableCopy];
}

-(NSString *)getServerDataForPlacementId:(NSString *)placementId {
    NSString *serverData = @"";
    
    if ([_rewardedVideoPlacementIdToServerData objectForKey:placementId]) {
        serverData = [_rewardedVideoPlacementIdToServerData objectForKey:placementId];
    } else if ([_interstitialPlacementIdToServerData objectForKey:placementId]) {
        serverData = [_interstitialPlacementIdToServerData objectForKey:placementId];
    } else if ([_bannerPlacementIdToServerData objectForKey:placementId]) {
        serverData = [_bannerPlacementIdToServerData objectForKey:placementId];
    }
    
    return serverData;
}

-(BOOL)isAdCachedForPlacement:(NSString *)placementId {
    NSString *serverData = [self getServerDataForPlacementId:placementId];
    
    if (serverData.length) {
        return [[VungleSDK sharedSDK] isAdCachedForPlacementID:placementId
                                                      adMarkup:serverData];
    }
    
    return [[VungleSDK sharedSDK] isAdCachedForPlacementID:placementId];
}

-(BOOL)isBannerAdCachedForPlacement:(NSString *)placementId {
    NSString *serverData = [self getServerDataForPlacementId:placementId];

    if (serverData.length) {
        serverData = [_bannerPlacementIdToServerData objectForKey:placementId];
    }
    
    return [self isBannerAdCachedForPlacement:placementId
                                   serverData:serverData];
}

-(BOOL)isBannerAdCachedForPlacement:(NSString *)placementId
                         serverData:(NSString *)serverData {
    ISBannerSize *size = [_bannerPlacementIdToSize objectForKey:placementId];
    
    if ([size.sizeDescription isEqualToString:@"RECTANGLE"]) {
        if (serverData.length) {
            return [[VungleSDK sharedSDK] isAdCachedForPlacementID:placementId
                                                          adMarkup:serverData];
        }
        
        return [[VungleSDK sharedSDK] isAdCachedForPlacementID:placementId];
    } else {
        VungleAdSize vungleBannerSize = [self getBannerSize:size];
        
        if (serverData.length) {
            return [[VungleSDK sharedSDK] isAdCachedForPlacementID:placementId
                                                          adMarkup:serverData
                                                          withSize:vungleBannerSize];
        }
        
        return [[VungleSDK sharedSDK] isAdCachedForPlacementID:placementId
                                                      withSize:vungleBannerSize];
    }
}

@end
