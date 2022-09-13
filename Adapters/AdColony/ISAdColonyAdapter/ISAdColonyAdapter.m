//
//  ISAdColonyAdapter.m
//  ISAdColonyAdapter
//
//  Created by Amit Goldhecht on 8/19/14.
//  Copyright (c) 2014 IronSource. All rights reserved.
//

#import "ISAdColonyAdapter.h"
#import "ISAdColonyBannerDelegate.h"
#import "ISAdColonyInterstitialDelegate.h"
#import "ISAdColonyRewardedVideoDelegate.h"
#import <AdColony/AdColony.h>

// Mediation keys
static NSString * const kMediationName      = @"ironSource";

// Network keys
static NSString * const kAdapterVersion     = AdColonyAdapterVersion;
static NSString * const kAdapterName        = @"AdColony";
static NSString * const kAppId              = @"appID";
static NSString * const kZoneId             = @"zoneId";
static NSString * const kAdMarkupKey        = @"adm";

// AdColony network id
static NSString * const kAdColonyetworkId   = @"AdColony";

// AdColony options
static AdColonyAppOptions *adColonyOptions  = nil;

// Meta data keys
static NSString * const kMetaDataCOPPAKey   = @"AdColony_COPPA";

// Init state
typedef NS_ENUM(NSInteger, InitState) {
    INIT_STATE_NONE,
    INIT_STATE_IN_PROGRESS,
    INIT_STATE_SUCCESS,
    INIT_STATE_FAILED
};

// Handle init callback for all adapter instances
static NSMutableSet<ISNetworkInitCallbackProtocol> *initCallbackDelegates = nil;

static InitState _initState = INIT_STATE_NONE;
static NSArray<AdColonyZone *> *adColonyInitZones = nil;

@interface ISAdColonyAdapter() <ISAdColonyInterstitialDelegateWrapper, ISAdColonyRewardedVideoDelegateWrapper, ISAdColonyBannerDelegateWrapper, ISNetworkInitCallbackProtocol>

// Rewarded video
@property (nonatomic, strong) ConcurrentMutableDictionary *rewardedVideoZoneIdToSmashDelegate;
@property (nonatomic, strong) ConcurrentMutableDictionary *rewardedVideoZoneIdToAdColonyAdDelegate;
@property (nonatomic, strong) ConcurrentMutableDictionary *rewardedVideoZoneIdToAd;
@property (nonatomic, strong) ConcurrentMutableSet        *rewardedVideoZoneIdsForInitCallbacks;

// Interstitial
@property (nonatomic, strong) ConcurrentMutableDictionary *interstitialZoneIdToSmashDelegate;
@property (nonatomic, strong) ConcurrentMutableDictionary *interstitialZoneIdToAdColonyAdDelegate;
@property (nonatomic, strong) ConcurrentMutableDictionary *interstitialZoneIdToAd;

// Banner
@property (nonatomic, strong) ConcurrentMutableDictionary *bannerZoneIdToSmashDelegate;
@property (nonatomic, strong) ConcurrentMutableDictionary *bannerZoneIdToAdColonyAdDelegate;
@property (nonatomic, strong) ConcurrentMutableDictionary *bannerZoneIdToSize;
@property (nonatomic, strong) ConcurrentMutableDictionary *bannerZoneIdToViewController;
@property (nonatomic, strong) ConcurrentMutableDictionary *bannerZoneIdToAd;

@end

@implementation ISAdColonyAdapter

#pragma mark - IronSource Protocol Methods

- (NSString *)version {
    return kAdapterVersion;
}

- (NSString *)sdkVersion {
    return [AdColony getSDKVersion];
}

- (NSArray *)systemFrameworks {
    return @[@"AdSupport", @"AppTrackingTransparency", @"AudioToolbox", @"AVFoundation", @"CoreMedia", @"CoreServices", @"CoreTelephony", @"JavaScriptCore", @"MessageUI", @"SafariServices", @"Social", @"StoreKit", @"SystemConfiguration", @"WatchConnectivity", @"WebKit"];
}

- (NSString *)sdkName {
    return kAdColonyetworkId;
}

#pragma mark - Initializations Methods And Callbacks

- (instancetype)initAdapter:(NSString *)name {
    self = [super initAdapter:name];
    if (self) {
        // only initiated once for all instances
        if (adColonyOptions == nil) {
            adColonyOptions = [AdColonyAppOptions new];
        }
        
        if (initCallbackDelegates == nil) {
            initCallbackDelegates = [NSMutableSet<ISNetworkInitCallbackProtocol> new];
        }
        
        // rewarded video
        _rewardedVideoZoneIdToSmashDelegate       = [ConcurrentMutableDictionary new];
        _rewardedVideoZoneIdToAd                  = [ConcurrentMutableDictionary new];
        _rewardedVideoZoneIdToAdColonyAdDelegate  = [ConcurrentMutableDictionary new];
        _rewardedVideoZoneIdsForInitCallbacks     = [[ConcurrentMutableSet alloc] init];
        
        // interstital
        _interstitialZoneIdToSmashDelegate        = [ConcurrentMutableDictionary new];
        _interstitialZoneIdToAdColonyAdDelegate   = [ConcurrentMutableDictionary new];
        _interstitialZoneIdToAd                   = [ConcurrentMutableDictionary new];
        
        // banner
        _bannerZoneIdToSmashDelegate              = [ConcurrentMutableDictionary new];
        _bannerZoneIdToAdColonyAdDelegate         = [ConcurrentMutableDictionary new];
        _bannerZoneIdToSize                       = [ConcurrentMutableDictionary new];
        _bannerZoneIdToViewController             = [ConcurrentMutableDictionary new];
        _bannerZoneIdToAd                         = [ConcurrentMutableDictionary new];
        
        // The network's capability to load a Rewarded Video ad while another Rewarded Video ad of that network is showing
        LWSState = LOAD_WHILE_SHOW_BY_NETWORK;
    }
    
    return self;
}

- (void)initAdColonySDKWithAppId:(NSString *)appID
                          userId:(NSString *)userId{
    
    // add self to the init delegates only in case the initialization has not finished yet
    if (_initState == INIT_STATE_NONE || _initState == INIT_STATE_IN_PROGRESS) {
        [initCallbackDelegates addObject:self];
    }
    
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        _initState = INIT_STATE_IN_PROGRESS;
        
        if (userId.length) {
            adColonyOptions.userID = userId;
        }
        
        adColonyOptions.mediationNetwork = kMediationName;
        adColonyOptions.mediationNetworkVersion = AdColonyAdapterVersion;
        
        adColonyOptions.disableLogging = ![ISConfigurations getConfigurations].adaptersDebug;
        
        LogAdapterApi_Internal(@"Initialize AdColony with appID  = %@", appID);
        [AdColony configureWithAppID:appID
                             options:adColonyOptions
                          completion:^(NSArray<AdColonyZone *> *adColonyZones) {
            if (adColonyZones.count) {
                adColonyInitZones = adColonyZones;
                // call init callback delegate success
                [self initializationSuccess];
            } else {
                // call init callback delegate failed
                [self initializationFailure];
            }
        }];
    });
}

- (void)initializationSuccess {
    LogAdapterDelegate_Internal(@"");

    _initState = INIT_STATE_SUCCESS;
    
    NSArray* initDelegatesList = initCallbackDelegates.allObjects;
    for(id<ISNetworkInitCallbackProtocol> initDelegate in initDelegatesList){
        [initDelegate onNetworkInitCallbackSuccess];
    }
    
    [initCallbackDelegates removeAllObjects];
}

- (void)initializationFailure {
    LogAdapterDelegate_Internal(@"");

    _initState = INIT_STATE_FAILED;
    
    NSArray* initDelegatesList = initCallbackDelegates.allObjects;
    for(id<ISNetworkInitCallbackProtocol> initDelegate in initDelegatesList){
        [initDelegate onNetworkInitCallbackFailed:@"AdColony SDK init failed"];
    }
    
    [initCallbackDelegates removeAllObjects];
}

- (void)onNetworkInitCallbackSuccess {
    
    // register rewarded zones
    [self registerRewardedVideoZones];

    // rewarded video
    NSArray *rewardedVideoZoneIDs = _rewardedVideoZoneIdToSmashDelegate.allKeys;
    for (NSString *zoneId in rewardedVideoZoneIDs) {
        if ([_rewardedVideoZoneIdsForInitCallbacks hasObject:zoneId]) {
            [[_rewardedVideoZoneIdToSmashDelegate objectForKey:zoneId] adapterRewardedVideoInitSuccess];
        } else {
            [self loadRewardedVideoInternal:zoneId withAdOptions:nil];
        }
    }
    
    // interstitial
    NSArray *interstitialZoneIDs = _interstitialZoneIdToSmashDelegate.allKeys;
    for (NSString *zoneId in interstitialZoneIDs) {
        id<ISInterstitialAdapterDelegate> delegate = [_interstitialZoneIdToSmashDelegate objectForKey:zoneId];
        [delegate adapterInterstitialInitSuccess];
    }
    
    // banner
    NSArray *bannerZoneIDs = _bannerZoneIdToSmashDelegate.allKeys;
    for (NSString *zoneId in bannerZoneIDs) {
        id<ISBannerAdapterDelegate> delegate = [_bannerZoneIdToSmashDelegate objectForKey:zoneId];
        [delegate adapterBannerInitSuccess];
    }
}

- (void)onNetworkInitCallbackFailed:(NSString *)errorMessage {

    NSError *error = [NSError errorWithDomain:kAdapterName
                                         code:ERROR_CODE_INIT_FAILED
                                     userInfo:@{NSLocalizedDescriptionKey:errorMessage}];
    
    // rewarded video
    NSArray *rewardedVideoZoneIDs = _rewardedVideoZoneIdToSmashDelegate.allKeys;
    for (NSString *zoneId in rewardedVideoZoneIDs) {
        if ([_rewardedVideoZoneIdsForInitCallbacks hasObject:zoneId]) {
            [[_rewardedVideoZoneIdToSmashDelegate objectForKey:zoneId] adapterRewardedVideoInitFailed:error];
        }
        else {
            [[_rewardedVideoZoneIdToSmashDelegate objectForKey:zoneId] adapterRewardedVideoHasChangedAvailability:NO];
        }
    }
        
    // interstitial
    NSArray *interstitialZoneIDs = _interstitialZoneIdToSmashDelegate.allKeys;
    for (NSString *zoneId in interstitialZoneIDs) {
        id<ISInterstitialAdapterDelegate> delegate = [_interstitialZoneIdToSmashDelegate objectForKey:zoneId];
        [delegate adapterInterstitialInitFailedWithError:error];
    }
    
    // banner
    NSArray *bannerZoneIDs = _bannerZoneIdToSmashDelegate.allKeys;
    for (NSString *zoneId in bannerZoneIDs) {
        id<ISBannerAdapterDelegate> delegate = [_bannerZoneIdToSmashDelegate objectForKey:zoneId];
        [delegate adapterBannerInitFailedWithError:error];
    }
}

#pragma mark - Rewarded Video API

// Used for flows when the mediation needs to get a callback for init
- (void)initRewardedVideoForCallbacksWithUserId:(NSString *)userId
                                  adapterConfig:(ISAdapterConfig *)adapterConfig
                                       delegate:(id<ISRewardedVideoAdapterDelegate>)delegate {
    NSString *appId = adapterConfig.settings[kAppId];
    NSString *zoneId = adapterConfig.settings[kZoneId];
   
    /* Configuration Validation */
    if (![self isConfigValueValid:appId]) {
        NSError *error = [self errorForMissingCredentialFieldWithName:kAppId];
        LogAdapterApi_Internal(@"error.description = %@", error.description);
        [delegate adapterRewardedVideoInitFailed:error];
        return;
    }
    
    if (![self isConfigValueValid:zoneId]) {
        NSError *error = [self errorForMissingCredentialFieldWithName:kZoneId];
        LogAdapterApi_Internal(@"error.description = %@", error.description);
        [delegate adapterRewardedVideoInitFailed:error];
        return;
    }
    
    LogAdapterApi_Internal(@"appId = %@, zoneId = %@", appId, zoneId);

    ISAdColonyRewardedVideoDelegate *rewardedVideoDelegate = [[ISAdColonyRewardedVideoDelegate alloc] initWithZoneId:zoneId
                                                                                                         andDelegate:self];
    //add to rewarded video delegate map
    [_rewardedVideoZoneIdToAdColonyAdDelegate setObject:rewardedVideoDelegate
                                                 forKey:zoneId];
    [_rewardedVideoZoneIdToSmashDelegate setObject:delegate
                                            forKey:zoneId];
    
    //add to rewarded video init callback map
    [_rewardedVideoZoneIdsForInitCallbacks addObject:zoneId];
    
    switch (_initState) {
        case INIT_STATE_NONE:
        case INIT_STATE_IN_PROGRESS:
            [self initAdColonySDKWithAppId:appId
                                    userId:userId];
            break;
        case INIT_STATE_SUCCESS:
            [self registerRewardedVideoZones];
            [delegate adapterRewardedVideoInitSuccess];
            break;
        case INIT_STATE_FAILED: {
            LogAdapterApi_Internal(@"init failed - zoneId = %@", zoneId);
            NSError *error = [NSError errorWithDomain:kAdapterName
                                                 code:ERROR_CODE_INIT_FAILED
                                             userInfo:@{NSLocalizedDescriptionKey:@"AdColony SDK init failed"}];
            [delegate adapterRewardedVideoInitFailed:error];
            break;
        }
    }
}

// Used for flows when the mediation doesn't need to get a callback for init
- (void)initAndLoadRewardedVideoWithUserId:(NSString *)userId
                             adapterConfig:(ISAdapterConfig *)adapterConfig
                                  delegate:(id<ISRewardedVideoAdapterDelegate>)delegate {
    NSString *appId = adapterConfig.settings[kAppId];
    NSString *zoneId = adapterConfig.settings[kZoneId];
    
    /* Configuration Validation */
    if (![self isConfigValueValid:appId]) {
        NSError *error = [self errorForMissingCredentialFieldWithName:kAppId];
        LogAdapterApi_Internal(@"error.description = %@", error.description);
        [delegate adapterRewardedVideoHasChangedAvailability:NO];
        return;
    }
    
    if (![self isConfigValueValid:zoneId]) {
        NSError *error = [self errorForMissingCredentialFieldWithName:kZoneId];
        LogAdapterApi_Internal(@"error.description = %@", error.description);
        [delegate adapterRewardedVideoHasChangedAvailability:NO];
        return;
    }
    
    LogAdapterApi_Internal(@"appId = %@, zoneId = %@", appId, zoneId);

    ISAdColonyRewardedVideoDelegate *rewardedVideoDelegate = [[ISAdColonyRewardedVideoDelegate alloc] initWithZoneId:zoneId
                                                                                                         andDelegate:self];
    //add to rewarded video delegate map
    [_rewardedVideoZoneIdToAdColonyAdDelegate setObject:rewardedVideoDelegate
                                                 forKey:zoneId];
    [_rewardedVideoZoneIdToSmashDelegate setObject:delegate
                                            forKey:zoneId];
    
    switch (_initState) {
        case INIT_STATE_NONE:
        case INIT_STATE_IN_PROGRESS:
            [self initAdColonySDKWithAppId:appId
                                    userId:userId];
            break;
        case INIT_STATE_SUCCESS:
            // register rewarded video zones
            [self registerRewardedVideoZones];
            [self loadRewardedVideoInternal:zoneId
                              withAdOptions:nil];
            break;
        case INIT_STATE_FAILED: {
            LogAdapterApi_Internal(@"init failed - zoneId = %@", zoneId);
            [delegate adapterRewardedVideoHasChangedAvailability:NO];
            break;
        }
    }
}

- (void)loadRewardedVideoForBiddingWithAdapterConfig:(ISAdapterConfig *)adapterConfig
                                          serverData:(NSString *)serverData
                                            delegate:(id<ISRewardedVideoAdapterDelegate>)delegate {
    NSString *zoneId = adapterConfig.settings[kZoneId];

    AdColonyAdOptions *adOptions = [AdColonyAdOptions new];
    [adOptions setOption:kAdMarkupKey
         withStringValue:serverData];
    
    [self loadRewardedVideoInternal:zoneId
                      withAdOptions:adOptions];

}

- (void)fetchRewardedVideoForAutomaticLoadWithAdapterConfig:(ISAdapterConfig *)adapterConfig
                                                   delegate:(id<ISRewardedVideoAdapterDelegate>)delegate {

    NSString *zoneId = adapterConfig.settings[kZoneId];
    
    [self loadRewardedVideoInternal:zoneId
                      withAdOptions:nil];
}

- (void)loadRewardedVideoInternal:(NSString *)zoneId
                    withAdOptions:(AdColonyAdOptions *)adOptions {
    
    LogAdapterApi_Internal(@"");
    ISAdColonyRewardedVideoDelegate *rewardedVideoDelegate = [_rewardedVideoZoneIdToAdColonyAdDelegate objectForKey:zoneId];
    
    [AdColony requestInterstitialInZone:zoneId
                                options:adOptions
                            andDelegate:rewardedVideoDelegate];
}


- (void)showRewardedVideoWithViewController:(UIViewController *)viewController
                              adapterConfig:(ISAdapterConfig *)adapterConfig
                                   delegate:(id<ISRewardedVideoAdapterDelegate>)delegate {
    NSString *zoneId = adapterConfig.settings[kZoneId];
    LogAdapterApi_Internal(@"zoneId = %@", zoneId);
    
    [delegate adapterRewardedVideoHasChangedAvailability:NO];
    
    AdColonyInterstitial *ad = [_rewardedVideoZoneIdToAd objectForKey:zoneId];
    
    if ([self hasRewardedVideoWithAdapterConfig:adapterConfig]) {
        BOOL showReady = [ad showWithPresentingViewController:viewController];
        if (!showReady) {
            NSError *error = [NSError errorWithDomain:kAdapterName
                                                 code:ERROR_CODE_GENERIC
                                             userInfo:@{NSLocalizedDescriptionKey : @"AdColony SDK not ready to show ad"}];
            LogAdapterApi_Internal(@"error = %@", error);
            [delegate adapterRewardedVideoDidFailToShowWithError:error];
        }
    } else {
        NSError *error = [ISError createError:ERROR_CODE_NO_ADS_TO_SHOW
                                  withMessage:[NSString stringWithFormat: @"%@ show failed", kAdapterName]];
        LogAdapterApi_Internal(@"error = %@", error);
        [delegate adapterRewardedVideoDidFailToShowWithError:error];
    }
}

- (BOOL)hasRewardedVideoWithAdapterConfig:(ISAdapterConfig *)adapterConfig {
    NSString *zoneId = adapterConfig.settings[kZoneId];
    AdColonyInterstitial *ad = [_rewardedVideoZoneIdToAd objectForKey:zoneId];
    return (ad != nil) && !ad.expired;
}

- (NSDictionary *)getRewardedVideoBiddingDataWithAdapterConfig:(ISAdapterConfig *)adapterConfig {
    return [self getBiddingData];
}

#pragma mark - Rewarded Video Delegate

- (void)onRewardedVideoDidLoad:(nonnull AdColonyInterstitial *)ad
                     forZoneId:(nonnull NSString *)zoneId {
    LogAdapterDelegate_Internal(@"zoneId = %@", zoneId);
    id<ISRewardedVideoAdapterDelegate> delegate = [_rewardedVideoZoneIdToSmashDelegate objectForKey:zoneId];
    
    [_rewardedVideoZoneIdToAd setObject:ad
                                 forKey:zoneId];
    
    [delegate adapterRewardedVideoHasChangedAvailability:YES];
    
}

- (void)onRewardedVideoDidFailToLoad:(nonnull NSString *)zoneId
                           withError:(nonnull AdColonyAdRequestError *)error {
    LogAdapterDelegate_Internal(@"zoneId = %@, error = %@", zoneId, error);
    id<ISRewardedVideoAdapterDelegate> delegate = [_rewardedVideoZoneIdToSmashDelegate objectForKey:zoneId];
    
    [delegate adapterRewardedVideoHasChangedAvailability:NO];
    
    if (error) {
        NSInteger errorCode = error.code == AdColonyRequestErrorNoFillForRequest ? ERROR_RV_LOAD_NO_FILL : error.code;
        NSError *rewardedVideoError = [NSError errorWithDomain:kAdapterName
                                                          code:errorCode
                                                      userInfo:@{NSLocalizedDescriptionKey:error.description}];
        
        [delegate adapterRewardedVideoDidFailToLoadWithError:rewardedVideoError];
        
    }
}

- (void)onRewardedVideoDidOpen:(nonnull NSString *)zoneId {
    LogAdapterDelegate_Internal(@"zoneId = %@", zoneId);
    id<ISRewardedVideoAdapterDelegate> delegate = [_rewardedVideoZoneIdToSmashDelegate objectForKey:zoneId];
    
    [delegate adapterRewardedVideoDidOpen];
    [delegate adapterRewardedVideoDidStart];
}

- (void)onRewardedVideoDidClick:(nonnull NSString *)zoneId {
    LogAdapterDelegate_Internal(@"zoneId = %@", zoneId);
    id<ISRewardedVideoAdapterDelegate> delegate = [_rewardedVideoZoneIdToSmashDelegate objectForKey:zoneId];
    
    [delegate adapterRewardedVideoDidClick];
}

- (void)onRewardedVideoExpired:(nonnull NSString *)zoneId {
    LogAdapterDelegate_Internal(@"zoneId = %@", zoneId);
    id<ISRewardedVideoAdapterDelegate> delegate = [_rewardedVideoZoneIdToSmashDelegate objectForKey:zoneId];
    
    // give indication of expired ads in events using callback
    NSError *error = [NSError errorWithDomain:kAdapterName
                                         code:ERROR_RV_EXPIRED_ADS
                                     userInfo:@{NSLocalizedDescriptionKey:@"ads are expired"}];
    [delegate adapterRewardedVideoDidFailToLoadWithError:error];
    
}

- (void)onRewardedVideoDidClose:(nonnull NSString *)zoneId {
    LogAdapterDelegate_Internal(@"zoneId = %@", zoneId);
    id<ISRewardedVideoAdapterDelegate> delegate = [_rewardedVideoZoneIdToSmashDelegate objectForKey:zoneId];
    
    [delegate adapterRewardedVideoDidEnd];
    [delegate adapterRewardedVideoDidClose];
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
    NSString *appId = adapterConfig.settings[kAppId];
    NSString *zoneId = adapterConfig.settings[kZoneId];
    
    /* Configuration Validation */
    if (![self isConfigValueValid:appId]) {
        NSError *error = [self errorForMissingCredentialFieldWithName:kAppId];
        LogAdapterApi_Internal(@"error.description = %@", error.description);
        [delegate adapterInterstitialInitFailedWithError:error];
        return;
    }
    
    if (![self isConfigValueValid:zoneId]) {
        NSError *error = [self errorForMissingCredentialFieldWithName:kZoneId];
        LogAdapterApi_Internal(@"error.description = %@", error.description);
        [delegate adapterInterstitialInitFailedWithError:error];
        return;
    }
    
    LogAdapterApi_Internal(@"appId = %@, zoneId = %@", appId, zoneId);
    
    ISAdColonyInterstitialDelegate *interstitialDelegate = [[ISAdColonyInterstitialDelegate alloc] initWithZoneId:zoneId
                                                                                                      andDelegate:self];
    //add to interstitial delegate map
    [_interstitialZoneIdToAdColonyAdDelegate setObject:interstitialDelegate
                                                forKey:zoneId];
    [_interstitialZoneIdToSmashDelegate setObject:delegate
                                           forKey:zoneId];
    
    switch (_initState) {
        case INIT_STATE_NONE:
        case INIT_STATE_IN_PROGRESS:
            [self initAdColonySDKWithAppId:appId
                                    userId:userId];
            break;
        case INIT_STATE_SUCCESS:
            [delegate adapterInterstitialInitSuccess];
            break;
        case INIT_STATE_FAILED: {
            LogAdapterApi_Internal(@"init failed - zoneId = %@", zoneId);
            NSError *error = [NSError errorWithDomain:kAdapterName
                                                 code:ERROR_CODE_INIT_FAILED
                                             userInfo:@{NSLocalizedDescriptionKey:@"AdColony SDK init failed"}];
        [delegate adapterInterstitialInitFailedWithError:error];
            break;
        }
    }
}

- (void)loadInterstitialForBiddingWithServerData:(NSString *)serverData
                                   adapterConfig:(ISAdapterConfig *)adapterConfig
                                        delegate:(id<ISInterstitialAdapterDelegate>)delegate {
    NSString *zoneId = adapterConfig.settings[kZoneId];
    
    AdColonyAdOptions *adOptions = [AdColonyAdOptions new];
    [adOptions setOption:kAdMarkupKey
         withStringValue:serverData];
    
    [self loadInterstitialInternal:zoneId
                     withAdOptions:adOptions];
}

- (void)loadInterstitialWithAdapterConfig:(ISAdapterConfig *)adapterConfig
                                 delegate:(id<ISInterstitialAdapterDelegate>)delegate {
    NSString *zoneId = adapterConfig.settings[kZoneId];
    
    [self loadInterstitialInternal:zoneId
                     withAdOptions:nil];
}

- (void)loadInterstitialInternal:(NSString *)zoneId
                   withAdOptions:(AdColonyAdOptions *)adOptions{
    LogAdapterApi_Internal(@"");
    ISAdColonyInterstitialDelegate *interstitialDelegate = [_interstitialZoneIdToAdColonyAdDelegate objectForKey:zoneId];
    
    [AdColony requestInterstitialInZone:zoneId
                                options:adOptions
                            andDelegate:interstitialDelegate];
}

- (void)showInterstitialWithViewController:(UIViewController *)viewController
                             adapterConfig:(ISAdapterConfig *)adapterConfig
                                  delegate:(id<ISInterstitialAdapterDelegate>)delegate {
    NSString *zoneId = adapterConfig.settings[kZoneId];
    LogAdapterApi_Internal(@"zoneId = %@", zoneId);
    AdColonyInterstitial *ad = [_interstitialZoneIdToAd objectForKey:zoneId];
    
    if ([self hasInterstitialWithAdapterConfig:adapterConfig]) {
        BOOL showReady = [ad showWithPresentingViewController:viewController];
        
        if (!showReady) {
            NSError *error = [NSError errorWithDomain:kAdapterName
                                                 code:ERROR_CODE_GENERIC
                                             userInfo:@{NSLocalizedDescriptionKey : @"AdColony SDK not ready to show ad"}];
            [delegate adapterInterstitialDidFailToShowWithError:error];
        }
    } else {
        NSError *error = [ISError createError:ERROR_CODE_NO_ADS_TO_SHOW
                                  withMessage:[NSString stringWithFormat: @"%@ show failed", kAdapterName]];
        LogAdapterApi_Internal(@"error = %@", error);
        [delegate adapterInterstitialDidFailToShowWithError:error];
    }
}

- (BOOL)hasInterstitialWithAdapterConfig:(ISAdapterConfig *)adapterConfig {
    NSString *zoneId = adapterConfig.settings[kZoneId];
    AdColonyInterstitial *ad = [_interstitialZoneIdToAd objectForKey:zoneId];
    return (ad != nil) && !ad.expired;
}

- (NSDictionary *)getInterstitialBiddingDataWithAdapterConfig:(ISAdapterConfig *)adapterConfig {
    return [self getBiddingData];
}

#pragma mark - Interstitial Delegate

- (void)onInterstitialDidLoad:(nonnull AdColonyInterstitial *)ad
                    forZoneId:(nonnull NSString *)zoneId {
    LogAdapterDelegate_Internal(@"zoneId = %@", zoneId);
    id<ISInterstitialAdapterDelegate> delegate = [_interstitialZoneIdToSmashDelegate objectForKey:zoneId];
    
    [_interstitialZoneIdToAd setObject:ad
                                forKey:zoneId];
    
    [delegate adapterInterstitialDidLoad];
}

- (void)onInterstitialDidFailToLoad:(nonnull NSString *)zoneId
                          withError:(nonnull AdColonyAdRequestError *)error {
    LogAdapterDelegate_Internal(@"zoneId = %@, error = %@", zoneId, error);
    id<ISInterstitialAdapterDelegate> delegate = [_interstitialZoneIdToSmashDelegate objectForKey:zoneId];
    
    NSInteger errorCode;
    NSString *errorReason;
    
    if (error) {
        errorCode = error.code == AdColonyRequestErrorNoFillForRequest ? ERROR_IS_LOAD_NO_FILL : error.code;
        errorReason = error.description;
    } else {
        errorCode = ERROR_CODE_GENERIC;
        errorReason = @"Load attempt failed";
    }
    
    NSError *interstitialError = [NSError errorWithDomain:kAdapterName
                                                     code:errorCode
                                                 userInfo:@{NSLocalizedDescriptionKey:errorReason}];
    
    [delegate adapterInterstitialDidFailToLoadWithError:interstitialError];
}

- (void)onInterstitialDidOpen:(nonnull NSString *)zoneId {
    LogAdapterDelegate_Internal(@"zoneId = %@", zoneId);
    id<ISInterstitialAdapterDelegate> delegate = [_interstitialZoneIdToSmashDelegate objectForKey:zoneId];
    
    [delegate adapterInterstitialDidOpen];
    [delegate adapterInterstitialDidShow];
}

- (void)onInterstitialDidClick:(nonnull NSString *)zoneId {
    LogAdapterDelegate_Internal(@"zoneId = %@", zoneId);
    id<ISInterstitialAdapterDelegate> delegate = [_interstitialZoneIdToSmashDelegate objectForKey:zoneId];
    
    [delegate adapterInterstitialDidClick];
}

- (void)onInterstitialDidClose:(nonnull NSString *)zoneId {
    LogAdapterDelegate_Internal(@"zoneId = %@", zoneId);
    id<ISInterstitialAdapterDelegate> delegate = [_interstitialZoneIdToSmashDelegate objectForKey:zoneId];
    
    [delegate adapterInterstitialDidClose];
}

#pragma mark - Banner API

- (void)initBannerForBiddingWithUserId:(NSString *)userId
                         adapterConfig:(ISAdapterConfig *)adapterConfig
                              delegate:(id<ISBannerAdapterDelegate>)delegate {
    [self initBannerWithUserId:userId
                 adapterConfig:adapterConfig
                      delegate:delegate];
}

- (void)initBannerWithUserId:(NSString *)userId
               adapterConfig:(ISAdapterConfig *)adapterConfig
                    delegate:(id<ISBannerAdapterDelegate>)delegate {
    NSString *appId = adapterConfig.settings[kAppId];
    NSString *zoneId = adapterConfig.settings[kZoneId];
    
    /* Configuration Validation */
    if (![self isConfigValueValid:appId]) {
        NSError *error = [self errorForMissingCredentialFieldWithName:kAppId];
        LogAdapterApi_Internal(@"error = %@", error);
        [delegate adapterBannerInitFailedWithError:error];
        return;
    }
    
    if (![self isConfigValueValid:zoneId]) {
        NSError *error = [self errorForMissingCredentialFieldWithName:kZoneId];
        LogAdapterApi_Internal(@"error = %@", error);
        [delegate adapterBannerInitFailedWithError:error];
        return;
    }
    
    LogAdapterApi_Internal(@"appId = %@, zoneId = %@", appId, zoneId);
    
    ISAdColonyBannerDelegate *bannerDelegate = [[ISAdColonyBannerDelegate alloc] initWithZoneId:zoneId
                                                                                    andDelegate:self];
    //add to banner delegate map
    [_bannerZoneIdToAdColonyAdDelegate setObject:bannerDelegate
                                          forKey:zoneId];
    [_bannerZoneIdToSmashDelegate setObject:delegate
                                     forKey:zoneId];
    
    switch (_initState) {
        case INIT_STATE_NONE:
        case INIT_STATE_IN_PROGRESS:
            [self initAdColonySDKWithAppId:appId
                                    userId:userId];
            break;
        case INIT_STATE_SUCCESS:
            [delegate adapterBannerInitSuccess];
            break;
        case INIT_STATE_FAILED: {
            LogAdapterApi_Internal(@"init failed - zoneId = %@", zoneId);
            NSError *error = [NSError errorWithDomain:kAdapterName
                                                 code:ERROR_CODE_INIT_FAILED
                                             userInfo:@{NSLocalizedDescriptionKey:@"AdColony SDK init failed"}];
            [delegate adapterBannerInitFailedWithError:error];
            break;
        }
    }
}

- (void)loadBannerWithViewController:(UIViewController *)viewController
                                size:(ISBannerSize *)size
                       adapterConfig:(ISAdapterConfig *)adapterConfig
                            delegate:(id <ISBannerAdapterDelegate>)delegate {
    [self loadBannerInternal:adapterConfig
                    delegate:delegate
                        size:size
              viewController:viewController
                   adOptions:nil];
}

- (void)loadBannerForBiddingWithServerData:(NSString *)serverData
                            viewController:(UIViewController *)viewController
                                      size:(ISBannerSize *)size
                             adapterConfig:(ISAdapterConfig *)adapterConfig
                                  delegate:(id <ISBannerAdapterDelegate>)delegate {
    AdColonyAdOptions *adOptions = [AdColonyAdOptions new];
    [adOptions setOption:kAdMarkupKey withStringValue:serverData];
    
    [self loadBannerInternal:adapterConfig
                    delegate:delegate
                        size:size
              viewController:viewController
                   adOptions:adOptions];
}

- (void)loadBannerInternal:(ISAdapterConfig *)adapterConfig
                  delegate:(id<ISBannerAdapterDelegate>)delegate
                      size:(ISBannerSize *)size
            viewController:(UIViewController *)viewController
                 adOptions:(AdColonyAdOptions*)adOptions {
    NSString *zoneId = adapterConfig.settings[kZoneId];
    
    // verify size
    if (![self isBannerSizeSupported:size]) {
        NSError *error = [NSError errorWithDomain:kAdapterName
                                             code:ERROR_BN_UNSUPPORTED_SIZE
                                         userInfo:@{NSLocalizedDescriptionKey:[NSString stringWithFormat:@"AdColony unsupported banner size = %@", size.sizeDescription]}];
        LogAdapterApi_Internal(@"error = %@", error);
        [delegate adapterBannerDidFailToLoadWithError:error];
    }
    
    // add delegate to dictionary
    [_bannerZoneIdToSmashDelegate setObject:delegate
                                     forKey:zoneId];
    
    // add size to dictionary
    [_bannerZoneIdToSize setObject:size
                            forKey:zoneId];
    
    // add view controller to dictionary
    [_bannerZoneIdToViewController setObject:viewController
                                      forKey:zoneId];
    
    AdColonyAdSize bannerSize = [self getBannerSize:size];
    
    ISAdColonyBannerDelegate *bannerDelegate = [_bannerZoneIdToAdColonyAdDelegate objectForKey:zoneId];
    
    // load banner
    [AdColony requestAdViewInZone:zoneId
                         withSize:bannerSize
                       andOptions:adOptions
                   viewController:viewController
                      andDelegate:bannerDelegate];
}

- (void)reloadBannerWithAdapterConfig:(ISAdapterConfig *)adapterConfig
                             delegate:(id <ISBannerAdapterDelegate>)delegate {
    LogInternal_Warning(@"Unsupported method");
}

- (void)destroyBannerWithAdapterConfig:(ISAdapterConfig *)adapterConfig {
    NSString *zoneId = adapterConfig.settings[kZoneId];
    LogAdapterApi_Internal(@"");
    
    // get banner ad
    AdColonyAdView *bannerAd = [_bannerZoneIdToAd objectForKey:zoneId];
    
    if (bannerAd) {
        // destroy banner
        [bannerAd destroy];
        
        // remove from dictionaries
        [_bannerZoneIdToSmashDelegate removeObjectForKey:zoneId];
        [_bannerZoneIdToAdColonyAdDelegate removeObjectForKey:zoneId];
        [_bannerZoneIdToViewController removeObjectForKey:zoneId];
        [_bannerZoneIdToSize removeObjectForKey:zoneId];
        [_bannerZoneIdToAd removeObjectForKey:zoneId];
    }
}

//network does not support banner reload
//return true if banner view needs to be bound again on reload
- (BOOL)shouldBindBannerViewOnReload {
    return YES;
}

- (nonnull NSDictionary *)getBannerBiddingDataWithAdapterConfig:(ISAdapterConfig *)adapterConfig {
    return [self getBiddingData];
}


#pragma mark - Banner Delegate

- (void)onBannerDidLoad:(nonnull AdColonyAdView *)bannerView
              forZoneId:(nonnull NSString *)zoneId {
    LogAdapterDelegate_Internal(@"zoneId = %@", zoneId);
    id<ISBannerAdapterDelegate> delegate = [_bannerZoneIdToSmashDelegate objectForKey:zoneId];
    
    [_bannerZoneIdToAd setObject:bannerView
                          forKey:zoneId];

    [delegate adapterBannerDidLoad:bannerView];
}

- (void)onBannerDidFailToLoad:(nonnull NSString *)zoneId
                    withError:(nonnull AdColonyAdRequestError *)error {
    LogAdapterDelegate_Internal(@"zoneId = %@, error = %@", zoneId, error.localizedDescription);
    id<ISBannerAdapterDelegate> delegate = [_bannerZoneIdToSmashDelegate objectForKey:zoneId];

    NSInteger errorCode;
    NSString *errorReason;

    if (error) {
        errorCode = error.code == AdColonyRequestErrorNoFillForRequest ? ERROR_BN_LOAD_NO_FILL : error.code;
        errorReason = error.description;
    } else {
        errorCode = ERROR_CODE_GENERIC;
        errorReason = @"Load attempt failed";
    }
    
    NSError *bannerError = [NSError errorWithDomain:kAdapterName
                                               code:errorCode
                                           userInfo:@{NSLocalizedDescriptionKey:errorReason}];

    [delegate adapterBannerDidFailToLoadWithError:bannerError];

}

- (void)onBannerDidShow:(nonnull NSString *)zoneId {
    LogAdapterDelegate_Internal(@"zoneId = %@", zoneId);
    id<ISBannerAdapterDelegate> delegate = [_bannerZoneIdToSmashDelegate objectForKey:zoneId];
    
    [delegate adapterBannerDidShow];
}

- (void)onBannerDidClick:(nonnull AdColonyAdView *)bannerView
               forZoneId:(nonnull NSString *)zoneId {
    LogAdapterDelegate_Internal(@"zoneId = %@", zoneId);
    id<ISBannerAdapterDelegate> delegate = [_bannerZoneIdToSmashDelegate objectForKey:zoneId];
    
    [delegate adapterBannerDidClick];
}

- (void)onBannerBannerWillLeaveApplication:(nonnull AdColonyAdView *)bannerView
                                 forZoneId:(nonnull NSString *)zoneId {
    LogAdapterDelegate_Internal(@"zoneId = %@", zoneId);
    id<ISBannerAdapterDelegate> delegate = [_bannerZoneIdToSmashDelegate objectForKey:zoneId];
    
    [delegate adapterBannerWillLeaveApplication];
}

- (void)onBannerBannerWillPresentScreen:(nonnull AdColonyAdView *)bannerView
                              forZoneId:(nonnull NSString *)zoneId {
    LogAdapterDelegate_Internal(@"zoneId = %@", zoneId);
    id<ISBannerAdapterDelegate> delegate = [_bannerZoneIdToSmashDelegate objectForKey:zoneId];
    
    [delegate adapterBannerWillPresentScreen];
}

- (void)onBannerBannerDidDismissScreen:(nonnull AdColonyAdView *)bannerView
                             forZoneId:(nonnull NSString *)zoneId {
    LogAdapterDelegate_Internal(@"zoneId = %@", zoneId);
    id<ISBannerAdapterDelegate> delegate = [_bannerZoneIdToSmashDelegate objectForKey:zoneId];
    
    [delegate adapterBannerDidDismissScreen];
}

#pragma mark - Memory Handling

- (void)releaseMemoryWithAdapterConfig:(nonnull ISAdapterConfig *)adapterConfig {
    // releasing memory currently only for banners
    NSString *zoneId = adapterConfig.settings[kZoneId];
    AdColonyAdView *bannerAd = [_bannerZoneIdToAd objectForKey:zoneId];
    
    if (bannerAd) {
        [self destroyBannerWithAdapterConfig:adapterConfig];
    }
}

#pragma mark - Legal Methods

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
        [self setCCPAValue:value];
    } else  {
        NSString *formattedValue = [ISMetaDataUtils formatValue:value
                                                        forType:(META_DATA_VALUE_BOOL)];
        if ([self isValidCOPPAMetaDataKey:key
                                 andValue:formattedValue]) {
            [self setCOPPAValue:formattedValue];
        }
    }
}

- (void)setConsent:(BOOL)consent {
    NSString *consentVal = consent ? @"1" : @"0";
    [adColonyOptions setPrivacyFrameworkOfType:ADC_GDPR
                                    isRequired:YES];
    [adColonyOptions setPrivacyConsentString:consentVal
                                     forType:ADC_GDPR];

    if (_initState == INIT_STATE_SUCCESS) {
        LogAdapterApi_Internal(@"key = %@, value = %@", ADC_GDPR, consentVal);
        [AdColony setAppOptions:adColonyOptions];
    }
}

- (void)setCCPAValue:(NSString *)value {
    //When "do_not_sell" is YES --> report consentString = NO
    //When "do_not_sell" is NO --> report consentString = YES
    BOOL isCCPAOptedIn = ![ISMetaDataUtils getCCPABooleanValue:value];
    NSString *consentString = isCCPAOptedIn ? @"1" : @"0";
    [adColonyOptions setPrivacyFrameworkOfType:ADC_CCPA
                                    isRequired:YES];
    [adColonyOptions setPrivacyConsentString:consentString
                                     forType:ADC_CCPA];
    
    if (_initState == INIT_STATE_SUCCESS) {
        LogAdapterApi_Internal(@"key = %@ value = %@", ADC_CCPA, consentString);
        [AdColony setAppOptions:adColonyOptions];
    }
}

- (void)setCOPPAValue:(NSString *)value {
    
    BOOL isCOPPAOptedIn = [ISMetaDataUtils getCCPABooleanValue:value];
    
    [adColonyOptions setPrivacyFrameworkOfType:ADC_COPPA
                                    isRequired:isCOPPAOptedIn];
    
    if (_initState == INIT_STATE_SUCCESS) {
        LogAdapterApi_Internal(@"key = %@, value = %d", ADC_COPPA, isCOPPAOptedIn);
        [AdColony setAppOptions:adColonyOptions];
    }
}


//This method checks if the Meta Data key is the AdColony COPPA key
- (BOOL)isValidCOPPAMetaDataKey:(NSString *)key andValue:(NSString *)value {
    return ([key caseInsensitiveCompare:kMetaDataCOPPAKey] == NSOrderedSame && (value.length > 0));
}



#pragma mark - Helper Methods


- (NSDictionary *)getBiddingData {
    if (_initState == INIT_STATE_FAILED) {
        LogAdapterApi_Internal(@"returning nil as token since init failed");
        return nil;
    }
    NSString *bidderToken = [AdColony collectSignals];
    NSString *returnedToken = bidderToken? bidderToken : @"";
    NSString *sdkVersion = [self sdkVersion];
    LogAdapterApi_Internal(@"token = %@", returnedToken);
    LogAdapterApi_Internal(@"sdkVersion = %@", sdkVersion);
    return @{@"token": returnedToken, @"sdkVersion": sdkVersion};
}

// register all the rewarded video zones for rewarded callback after init completed
- (void)registerRewardedVideoZones {
    LogAdapterApi_Internal(@"");
    
    // zones from init
    for (AdColonyZone *zone in adColonyInitZones) {
        NSString *zoneId = zone.identifier;
        id<ISRewardedVideoAdapterDelegate> delegate = [_rewardedVideoZoneIdToSmashDelegate objectForKey:zoneId];
        
        if (delegate && zone.rewarded) {
            LogAdapterApi_Internal(@"register zoneId = %@", zoneId);
            [zone setReward:^(BOOL success, NSString *name, int amount) {
                LogAdapterDelegate_Internal(@"zone %@ reward - success = %@", zoneId, success ? @"YES" : @"NO");
                if (success) {
                    [delegate adapterRewardedVideoDidReceiveReward];
                }
            }];
        }
    }
}

- (BOOL)isBannerSizeSupported:(ISBannerSize *)size {
    if ([size.sizeDescription isEqualToString:@"BANNER"]     ||
        [size.sizeDescription isEqualToString:@"LARGE"]      ||
        [size.sizeDescription isEqualToString:@"RECTANGLE"]  ||
        [size.sizeDescription isEqualToString:@"SMART"]      ||
        [size.sizeDescription isEqualToString:@"CUSTOM"]
        ) {
        return YES;
    }
    
    return NO;
}

- (AdColonyAdSize)getBannerSize:(ISBannerSize *)size {
    if ([size.sizeDescription isEqualToString:@"BANNER"]     ||
        [size.sizeDescription isEqualToString:@"LARGE"]
       ) {
        return kAdColonyAdSizeBanner;
    } else if ([size.sizeDescription isEqualToString:@"RECTANGLE"]) {
        return kAdColonyAdSizeMediumRectangle;
    } else if ([size.sizeDescription isEqualToString:@"SMART"]) {
        return (UI_USER_INTERFACE_IDIOM() == UIUserInterfaceIdiomPad) ? kAdColonyAdSizeLeaderboard : kAdColonyAdSizeBanner;
    } else if ([size.sizeDescription isEqualToString:@"CUSTOM"]) {
        return AdColonyAdSizeMake(size.width, size.height);
    }
    
    return AdColonyAdSizeMake(0, 0);
}


@end
