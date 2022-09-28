//
//  ISVungleAdapter.m
//  ISVungleAdapter
//
//  Created by Amit Goldhecht on 8/20/14.
//  Copyright (c) 2014 IronSource. All rights reserved.
//
#import "ISVungleAdapter.h"
#import <VungleAdsSDK/VungleAdsSDK.h>
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

@property (nonatomic, strong) ISVungleRewardedVideoAdapterRouter *rewardedVideoAdapterRouter;
@property (nonatomic, strong) ISVungleInterstitialAdapterRouter *interstitialAdapterRouter;
@property (nonatomic, strong) ISVungleBannerAdapterRouter *bannerAdapterRouter;

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
    if (self.rewardedVideoAdapterRouter) {
        self.rewardedVideoAdapterRouter.isNeededInitCallback ? [self.rewardedVideoAdapterRouter rewardedVideoInitSuccess] : [self loadRewardedVideoInternalWithPlacement];
    }

    // interstitial
    if (self.interstitialAdapterRouter) {
        [self.interstitialAdapterRouter interstitialInitSuccess];
    }

    // banner
    if (self.bannerAdapterRouter) {
        [self.bannerAdapterRouter bannerAdInitSuccess];
    }
}

- (void)onNetworkInitCallbackFailed:(nonnull NSString *)errorMessage {
    LogInternal_Internal(@"");

    NSError *error = [ISError createError:ERROR_CODE_INIT_FAILED withMessage:errorMessage];

    // rewarded video
    if (self.rewardedVideoAdapterRouter) {
        self.rewardedVideoAdapterRouter.isNeededInitCallback ? [self.rewardedVideoAdapterRouter rewardedVideoInitFailed:error] : [self.rewardedVideoAdapterRouter rewardedVideoHasChangedAvailability:NO];
    }

    // interstitial
    if (self.interstitialAdapterRouter) {
        [self.interstitialAdapterRouter interstitialInitFailed:error];
    }

    // banner
    if (self.bannerAdapterRouter) {
        [self.bannerAdapterRouter bannerAdInitFailed:error];
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

    self.rewardedVideoAdapterRouter = [[ISVungleRewardedVideoAdapterRouter alloc] initWithPlacementID:placementId parentAdapter:self delegate:delegate];
    self.rewardedVideoAdapterRouter.isNeededInitCallback = YES;

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

    self.rewardedVideoAdapterRouter = [[ISVungleRewardedVideoAdapterRouter alloc] initWithPlacementID:placementId parentAdapter:self delegate:delegate];

    switch (_initState) {
        case INIT_STATE_NONE:
        case INIT_STATE_IN_PROGRESS:
            [self initSDKWithAppId:appId];
            break;
        case INIT_STATE_SUCCESS:
            [self loadRewardedVideoInternalWithPlacement];
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
    [self loadRewardedVideoInternalWithPlacement:placementId serverData:serverData];
}

- (void)fetchRewardedVideoForAutomaticLoadWithAdapterConfig:(ISAdapterConfig *)adapterConfig
                                                   delegate:(id<ISRewardedVideoAdapterDelegate>)delegate {
    NSString *placementId = adapterConfig.settings[kPlacementID];
    [self loadRewardedVideoInternalWithPlacement:placementId serverData:nil];
}

- (void)loadRewardedVideoInternalWithPlacement:(NSString *)placementId
                                    serverData:(NSString *)serverData {
    if (![self.rewardedVideoAdapterRouter.placementID isEqualToString:placementId]) {
        return;
    }
    if (serverData) {
        [self.rewardedVideoAdapterRouter setBidPayload:serverData];
    }
    [self loadRewardedVideoInternalWithPlacement];
}

- (void)loadRewardedVideoInternalWithPlacement {
    LogAdapterApi_Internal(@"placementId = %@", self.rewardedVideoAdapterRouter.placementID);
    [self.rewardedVideoAdapterRouter loadRewardedVideoAd];
}

- (void)showRewardedVideoWithViewController:(UIViewController *)viewController
                              adapterConfig:(ISAdapterConfig *)adapterConfig
                                   delegate:(id<ISRewardedVideoAdapterDelegate>)delegate {
    NSString *placementId = adapterConfig.settings[kPlacementID];
    LogAdapterApi_Internal(@"placementId = %@", placementId);

    [delegate adapterRewardedVideoHasChangedAvailability:NO];
    
    if (![self.rewardedVideoAdapterRouter.placementID isEqualToString:placementId] || ![self.rewardedVideoAdapterRouter.rewardedVideoAd canPlayAd]) {
        NSError *error = [NSError errorWithDomain:kAdapterName
                                             code:kShowErrorNotCached
                                         userInfo:@{NSLocalizedDescriptionKey : @"Show error. ad not cached"}];
        LogAdapterApi_Internal(@"error = %@", error);
        [delegate adapterRewardedVideoDidFailToShowWithError:error];
        return;
    }
    
    dispatch_async(dispatch_get_main_queue(), ^{
        [self.rewardedVideoAdapterRouter playRewardedVideoAdWithViewController:viewController];
    });
}

- (BOOL)hasRewardedVideoWithAdapterConfig:(ISAdapterConfig *)adapterConfig {
    NSString *placementId = adapterConfig.settings[kPlacementID];
    if (![self.rewardedVideoAdapterRouter.placementID isEqualToString:placementId]) {
        return NO;
    }

    return [self.rewardedVideoAdapterRouter.rewardedVideoAd canPlayAd];
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
    self.interstitialAdapterRouter = [[ISVungleInterstitialAdapterRouter alloc] initWithPlacementID:placementId parentAdapter:self delegate:delegate];
    
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
    [self loadInterstitialInternalWithPlacement:placementId serverData:serverData];
}

- (void)loadInterstitialWithAdapterConfig:(ISAdapterConfig *)adapterConfig
                                 delegate:(id<ISInterstitialAdapterDelegate>)delegate {
    NSString *placementId = adapterConfig.settings[kPlacementID];
    [self loadInterstitialInternalWithPlacement:placementId serverData:nil];
}

- (void)loadInterstitialInternalWithPlacement:(NSString *)placementId
                                   serverData:(NSString *)serverData {
    if (![self.interstitialAdapterRouter.placementID isEqualToString:placementId]) {
        return;
    }

    LogAdapterApi_Internal(@"placementID = %@", placementId);
    if (serverData) {
        [self.interstitialAdapterRouter setBidPayload:serverData];
    }
    [self.interstitialAdapterRouter loadInterstitial];
}

- (void)showInterstitialWithViewController:(UIViewController *)viewController
                             adapterConfig:(ISAdapterConfig *)adapterConfig
                                  delegate:(id<ISInterstitialAdapterDelegate>)delegate {
    NSString *placementId = adapterConfig.settings[kPlacementID];
    LogAdapterApi_Internal(@"placementId = %@", placementId);

    if (![self.interstitialAdapterRouter.placementID isEqualToString:placementId] || ![self.interstitialAdapterRouter.interstitialAd canPlayAd]) {
        NSError *error = [NSError errorWithDomain:kAdapterName
                                             code:kShowErrorNotCached
                                         userInfo:@{NSLocalizedDescriptionKey : @"Show error. ad not cached"}];
        LogAdapterApi_Internal(@"error = %@", error);
        [delegate adapterInterstitialDidFailToShowWithError:error];
        return;
    }

    dispatch_async(dispatch_get_main_queue(), ^{
        [self.interstitialAdapterRouter playInterstitialAdWithViewController:viewController];
    });
}

- (BOOL)hasInterstitialWithAdapterConfig:(ISAdapterConfig *)adapterConfig {
    NSString *placementId = adapterConfig.settings[kPlacementID];
    if (![self.interstitialAdapterRouter.placementID isEqualToString:placementId]) {
        return NO;
    }

    return [self.interstitialAdapterRouter.interstitialAd canPlayAd];
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
    self.bannerAdapterRouter = [[ISVungleBannerAdapterRouter alloc] initWithPlacementID:placementId parentAdapter:self delegate:delegate];

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
    if (![self.bannerAdapterRouter.placementID isEqualToString:placementId]) {
        return;
    }

    // get Banner state
    [self.bannerAdapterRouter setSize:size];
    [self.bannerAdapterRouter setBidPayload:serverData];

    if (self.bannerAdapterRouter.bannerState == SHOWING) {
        [self dismissBannerWithServerData:serverData
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
    if (![self.bannerAdapterRouter.placementID isEqualToString:placementId]) {
        return;
    }

    // get Banner state
    [self.bannerAdapterRouter setSize:size];

    if (self.bannerAdapterRouter.bannerState == SHOWING) {
        [self dismissBannerWithServerData:nil
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
    self.bannerAdapterRouter.bannerState = REQUESTING_RELOAD;
    [self.bannerAdapterRouter destroy];
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

    //Set Banner state to - REQUESTING
    self.bannerAdapterRouter.bannerState = REQUESTING;
    [self.bannerAdapterRouter loadBannerAd];
}

- (void)reloadBannerWithAdapterConfig:(nonnull ISAdapterConfig *)adapterConfig
                             delegate:(nonnull id <ISBannerAdapterDelegate>)delegate {
    LogInternal_Warning(@"Unsupported method");
}

- (void)destroyBannerWithAdapterConfig:(nonnull ISAdapterConfig *)adapterConfig {
    NSString *placementId = adapterConfig.settings[kPlacementID];
    LogAdapterApi_Internal(@"placementId = %@", placementId);

    if ([self.bannerAdapterRouter.placementID isEqualToString:placementId]) {
        [self.bannerAdapterRouter destroy];
        self.bannerAdapterRouter.bannerState = UNKNOWN;
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
