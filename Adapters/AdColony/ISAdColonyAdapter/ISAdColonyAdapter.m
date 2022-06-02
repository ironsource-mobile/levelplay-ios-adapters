//
//  ISAdColonyAdapter.m
//  ISAdColonyAdapter
//
//  Created by Amit Goldhecht on 8/19/14.
//  Copyright (c) 2014 IronSource. All rights reserved.
//

#import "ISAdColonyAdapter.h"
#import "ISAdColonyBannerListener.h"
#import "ISAdColonyInterstitialListener.h"
#import "ISAdColonyRewardedVideoListener.h"
#import <AdColony/AdColony.h>

//AdColony requires a mediation name
static NSString * const kMediationName      = @"ironSource";

static NSString * const kAdapterName        = @"AdColony";
static NSString * const kAppId              = @"appID";
static NSString * const kZoneId             = @"zoneId";
static NSString * const kAdMarkupKey        = @"adm";

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

// AdColony options
static AdColonyAppOptions *adColonyOptions = nil;

// Meta data keys
static NSString * const kMetaDataCOPPAKey   = @"AdColony_COPPA";


@interface ISAdColonyAdapter() <ISAdColonyInterstitialDelegateWrapper, ISAdColonyRewardedVideoDelegateWrapper, ISAdColonyBannerDelegateWrapper, ISNetworkInitCallbackProtocol> {
}
// Rewarded video
@property (nonatomic, strong) ConcurrentMutableDictionary *rewardedVideoZoneIdToSmashDelegate;
@property (nonatomic, strong) ConcurrentMutableDictionary *rewardedVideoZoneIdToListener;
@property (nonatomic, strong) ConcurrentMutableDictionary *rewardedVideoZoneIdToAd;
@property (nonatomic, strong) ConcurrentMutableSet        *rewardedVideoZoneIdsForInitCallbacks;

// Interstitial
@property (nonatomic, strong) ConcurrentMutableDictionary *interstitialZoneIdToSmashDelegate;
@property (nonatomic, strong) ConcurrentMutableDictionary *interstitialZoneIdToListener;
@property (nonatomic, strong) ConcurrentMutableDictionary *interstitialZoneIdToAd;

// Banner
@property (nonatomic, strong) ConcurrentMutableDictionary *bannerZoneIdToSmashDelegate;
@property (nonatomic, strong) ConcurrentMutableDictionary *bannerZoneIdToListener;
@property (nonatomic, strong) ConcurrentMutableDictionary *bannerZoneIdToSize;
@property (nonatomic, strong) ConcurrentMutableDictionary *bannerZoneIdToViewController;
@property (nonatomic, strong) ConcurrentMutableDictionary *bannerZoneIdToAd;


@end

@implementation ISAdColonyAdapter

#pragma mark - IronSource Protocol Methods

- (NSString *)version {
    return AdColonyAdapterVersion;
}

- (NSString *)sdkVersion {
    return [AdColony getSDKVersion];
}

- (NSArray *)systemFrameworks {
    return @[@"AdSupport", @"AppTrackingTransparency", @"AudioToolbox", @"AVFoundation", @"CoreMedia", @"CoreServices", @"CoreTelephony", @"JavaScriptCore", @"MessageUI", @"SafariServices", @"Social", @"StoreKit", @"SystemConfiguration", @"WatchConnectivity", @"WebKit"];
}

- (NSString *)sdkName {
    return @"AdColony";
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
        _rewardedVideoZoneIdToListener            = [ConcurrentMutableDictionary new];
        _rewardedVideoZoneIdsForInitCallbacks     = [[ConcurrentMutableSet alloc] init];
        
        // interstital
        _interstitialZoneIdToSmashDelegate        = [ConcurrentMutableDictionary new];
        _interstitialZoneIdToListener             = [ConcurrentMutableDictionary new];
        _interstitialZoneIdToAd                   = [ConcurrentMutableDictionary new];
        
        // banner
        _bannerZoneIdToSmashDelegate              = [ConcurrentMutableDictionary new];
        _bannerZoneIdToListener                   = [ConcurrentMutableDictionary new];
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
            LogAdapterApi_Internal(@"set userID to %@", userId);
            adColonyOptions.userID = userId;
        }
        
        adColonyOptions.mediationNetwork = kMediationName;
        adColonyOptions.mediationNetworkVersion = AdColonyAdapterVersion;
        
        adColonyOptions.disableLogging = ![ISConfigurations getConfigurations].adaptersDebug;
        LogAdapterApi_Internal(@"set disableLogging to %d", adColonyOptions.disableLogging);
        
        
        LogAdapterApi_Internal(@"AdColony configureWithAppID %@", appID);
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

- (void)onNetworkInitCallbackSuccess {
    LogAdapterDelegate_Internal(@"");
    
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

- (void)onNetworkInitCallbackFailed:(nonnull NSString *)errorMessage {
    LogAdapterDelegate_Internal(@"");

    NSError *error = [NSError errorWithDomain:kAdapterName code:ERROR_CODE_INIT_FAILED userInfo:@{NSLocalizedDescriptionKey:errorMessage}];
    
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

    ISAdColonyRewardedVideoListener *rewardedVideoListener = [[ISAdColonyRewardedVideoListener alloc] initWithZoneId:zoneId andDelegate:self];
    [_rewardedVideoZoneIdToListener setObject:rewardedVideoListener forKey:zoneId];
    [_rewardedVideoZoneIdToSmashDelegate setObject:delegate forKey:zoneId];
    [_rewardedVideoZoneIdsForInitCallbacks addObject:zoneId];
    
    if (_initState == INIT_STATE_SUCCESS) {
        // register rewarded video zones
        [self registerRewardedVideoZones];
        [delegate adapterRewardedVideoInitSuccess];
    } else if (_initState == INIT_STATE_FAILED) {
        NSError *error = [NSError errorWithDomain:kAdapterName code:ERROR_CODE_INIT_FAILED userInfo:@{NSLocalizedDescriptionKey:@"AdColony SDK init failed"}];
        LogAdapterApi_Internal(@"error.description = %@", error.description);
        [delegate adapterRewardedVideoInitFailed:error];
    } else {
        [self initAdColonySDKWithAppId:appId userId:userId];
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

    ISAdColonyRewardedVideoListener *rewardedVideoListener = [[ISAdColonyRewardedVideoListener alloc] initWithZoneId:zoneId andDelegate:self];
    [_rewardedVideoZoneIdToListener setObject:rewardedVideoListener forKey:zoneId];
    [_rewardedVideoZoneIdToSmashDelegate setObject:delegate forKey:zoneId];
    
    if (_initState == INIT_STATE_SUCCESS) {
        // register rewarded video zones
        [self registerRewardedVideoZones];
        [self loadRewardedVideoInternal:zoneId withAdOptions:nil];
    } else if (_initState == INIT_STATE_FAILED) {
        NSError *error = [NSError errorWithDomain:kAdapterName code:ERROR_CODE_INIT_FAILED userInfo:@{NSLocalizedDescriptionKey:@"AdColony SDK init failed"}];
        LogAdapterApi_Internal(@"error.description = %@", error.description);
        [delegate adapterRewardedVideoHasChangedAvailability:NO];
    } else {
        [self initAdColonySDKWithAppId:appId userId:userId];
    }
}

- (void)loadRewardedVideoForBiddingWithAdapterConfig:(ISAdapterConfig *)adapterConfig serverData:(NSString *)serverData delegate:(id<ISRewardedVideoAdapterDelegate>)delegate {
    NSString *zoneId = adapterConfig.settings[kZoneId];
    LogAdapterApi_Internal(@"zoneId = %@, serverData = %@", zoneId, serverData);

    AdColonyAdOptions *adOptions = [AdColonyAdOptions new];
    [adOptions setOption:kAdMarkupKey withStringValue:serverData];
    [self loadRewardedVideoInternal:zoneId withAdOptions:adOptions];

}

- (void)fetchRewardedVideoForAutomaticLoadWithAdapterConfig:(ISAdapterConfig *)adapterConfig delegate:(id<ISRewardedVideoAdapterDelegate>)delegate {
    LogAdapterApi_Internal(@"");
    NSString *zoneId = adapterConfig.settings[kZoneId];
    [self loadRewardedVideoInternal:zoneId withAdOptions:nil];
}

- (void)loadRewardedVideoInternal:(NSString *)zoneId withAdOptions:(AdColonyAdOptions *)adOptions {
    ISAdColonyRewardedVideoListener *rewardedVideoListener = [_rewardedVideoZoneIdToListener objectForKey:zoneId];
    [AdColony requestInterstitialInZone:zoneId options:adOptions andDelegate:rewardedVideoListener];
}


- (void)showRewardedVideoWithViewController:(UIViewController *)viewController adapterConfig:(ISAdapterConfig *)adapterConfig delegate:(id<ISRewardedVideoAdapterDelegate>)delegate {
    NSString *zoneId = adapterConfig.settings[kZoneId];
    LogAdapterApi_Internal(@"zoneId = %@", zoneId);
    
    [delegate adapterRewardedVideoHasChangedAvailability:NO];
    AdColonyInterstitial *ad = [_rewardedVideoZoneIdToAd objectForKey:zoneId];
    
    if ([self hasRewardedVideoWithAdapterConfig:adapterConfig]) {
        BOOL showReady = [ad showWithPresentingViewController:viewController];
        if (!showReady) {
            NSError *error = [NSError errorWithDomain:kAdapterName code:ERROR_CODE_GENERIC userInfo:@{NSLocalizedDescriptionKey : @"AdColony SDK not ready to show ad"}];
            LogAdapterApi_Internal(@"error = %@", error);
            [delegate adapterRewardedVideoDidFailToShowWithError:error];
        }
    } else {
        NSError *error = [ISError createError:ERROR_CODE_NO_ADS_TO_SHOW withMessage:[NSString stringWithFormat: @"%@ show failed", kAdapterName]];
        LogAdapterApi_Internal(@"error = %@", error);
        [delegate adapterRewardedVideoDidFailToShowWithError:error];
    }
}

- (BOOL)hasRewardedVideoWithAdapterConfig:(ISAdapterConfig *)adapterConfig {
    LogAdapterApi_Internal(@"");
    NSString *zoneId = adapterConfig.settings[kZoneId];
    AdColonyInterstitial *ad = [_rewardedVideoZoneIdToAd objectForKey:zoneId];
    return (ad != nil) && !ad.expired;
}

- (NSDictionary *)getRewardedVideoBiddingDataWithAdapterConfig:(ISAdapterConfig *)adapterConfig {
    LogAdapterApi_Internal(@"");
    return [self getBiddingData];
}
#pragma mark - Rewarded Video Delegate

- (void)onRewardedVideoDidLoad:(AdColonyInterstitial *)ad forZoneId:(NSString *)zoneId {
    LogAdapterDelegate_Internal(@"zoneId = %@", zoneId);
    [_rewardedVideoZoneIdToAd setObject:ad forKey:zoneId];
    id<ISRewardedVideoAdapterDelegate> delegate = [_rewardedVideoZoneIdToSmashDelegate objectForKey:zoneId];
    
    if (delegate) {
        [delegate adapterRewardedVideoHasChangedAvailability:YES];
    }
}

- (void)onRewardedVideoDidFailToLoad:(NSString *)zoneId withError:(AdColonyAdRequestError *)error {
    LogAdapterDelegate_Internal(@"zoneId = %@, error = %@", zoneId, error);
    id<ISRewardedVideoAdapterDelegate> delegate = [_rewardedVideoZoneIdToSmashDelegate objectForKey:zoneId];
    
    if (delegate) {
        [delegate adapterRewardedVideoHasChangedAvailability:NO];
        NSError *smashError;
        
        if (error.code == AdColonyRequestErrorNoFillForRequest) {
            smashError = [NSError errorWithDomain:kAdapterName code:ERROR_RV_LOAD_NO_FILL userInfo:@{NSLocalizedDescriptionKey:@"AdColony no fill"}];
        } else {
            smashError = error;
        }
        
        [delegate adapterRewardedVideoDidFailToLoadWithError:smashError];
    }
}

- (void)onRewardedVideoDidOpen:(NSString *)zoneId {
    LogAdapterDelegate_Internal(@"zoneId = %@", zoneId);
    id<ISRewardedVideoAdapterDelegate> delegate = [_rewardedVideoZoneIdToSmashDelegate objectForKey:zoneId];
    
    if (delegate) {
        [delegate adapterRewardedVideoDidOpen];
        [delegate adapterRewardedVideoDidStart];
    }
}

- (void)onRewardedVideoDidClick:(NSString *)zoneId {
    LogAdapterDelegate_Internal(@"zoneId = %@", zoneId);
    id<ISRewardedVideoAdapterDelegate> delegate = [_rewardedVideoZoneIdToSmashDelegate objectForKey:zoneId];
    
    if (delegate) {
        [delegate adapterRewardedVideoDidClick];
    }
}

- (void)onRewardedVideoDidClose:(NSString *)zoneId {
    LogAdapterDelegate_Internal(@"zoneId = %@", zoneId);
    id<ISRewardedVideoAdapterDelegate> delegate = [_rewardedVideoZoneIdToSmashDelegate objectForKey:zoneId];
    
    if (delegate) {
        [delegate adapterRewardedVideoDidEnd];
        [delegate adapterRewardedVideoDidClose];
    }
}

- (void)onRewardedVideoExpired:(NSString *)zoneId {
    LogAdapterDelegate_Internal(@"zoneId = %@", zoneId);
    id<ISRewardedVideoAdapterDelegate> delegate = [_rewardedVideoZoneIdToSmashDelegate objectForKey:zoneId];
    
    // give indication of expired ads in events using callback
    if (delegate) {
        NSError *error = [NSError errorWithDomain:kAdapterName code:ERROR_RV_EXPIRED_ADS userInfo:@{NSLocalizedDescriptionKey:@"ads are expired"}];
        [delegate adapterRewardedVideoDidFailToLoadWithError:error];
    }

}

#pragma mark - Interstitial API

- (void)initInterstitialForBiddingWithUserId:(NSString *)userId adapterConfig:(ISAdapterConfig *)adapterConfig delegate:(id<ISInterstitialAdapterDelegate>)delegate {
    LogAdapterApi_Internal(@"");
    [self initInterstitialWithUserId:userId adapterConfig:adapterConfig delegate:delegate];
}

- (void)initInterstitialWithUserId:(NSString *)userId adapterConfig:(ISAdapterConfig *)adapterConfig delegate:(id<ISInterstitialAdapterDelegate>)delegate {
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
    
    ISAdColonyInterstitialListener *interstitialListener = [[ISAdColonyInterstitialListener alloc] initWithZoneId:zoneId andDelegate:self];
    [_interstitialZoneIdToListener setObject:interstitialListener forKey:zoneId];
    [_interstitialZoneIdToSmashDelegate setObject:delegate forKey:zoneId];
    
    if (_initState == INIT_STATE_SUCCESS) {
        [delegate adapterInterstitialInitSuccess];
    } else if (_initState == INIT_STATE_FAILED) {
        NSError *error = [NSError errorWithDomain:kAdapterName code:ERROR_CODE_INIT_FAILED userInfo:@{NSLocalizedDescriptionKey:@"AdColony SDK init failed"}];
        LogAdapterApi_Internal(@"error.description = %@", error.description);
        [delegate adapterInterstitialInitFailedWithError:error];
    } else {
        [self initAdColonySDKWithAppId:appId userId:userId];
    }
}

- (void)loadInterstitialForBiddingWithServerData:(NSString *)serverData adapterConfig:(ISAdapterConfig *)adapterConfig delegate:(id<ISInterstitialAdapterDelegate>)delegate {
    NSString *zoneId = adapterConfig.settings[kZoneId];
    LogAdapterApi_Internal(@"zoneId = %@, serverData = %@", zoneId, serverData);
    AdColonyAdOptions *adOptions = [AdColonyAdOptions new];
    [adOptions setOption:kAdMarkupKey withStringValue:serverData];
    [self loadInterstitialInternal:zoneId withAdOptions:adOptions];
}

- (void)loadInterstitialWithAdapterConfig:(ISAdapterConfig *)adapterConfig delegate:(id<ISInterstitialAdapterDelegate>)delegate {
    NSString *zoneId = adapterConfig.settings[kZoneId];
    LogAdapterApi_Internal(@"zoneId = %@", zoneId);
    [self loadInterstitialInternal:zoneId withAdOptions:nil];
}

- (void)loadInterstitialInternal:(NSString *)zoneId withAdOptions:(AdColonyAdOptions *)adOptions{
    ISAdColonyInterstitialListener *interstitialListener = [_interstitialZoneIdToListener objectForKey:zoneId];
    [AdColony requestInterstitialInZone:zoneId options:adOptions andDelegate:interstitialListener];
}

- (void)showInterstitialWithViewController:(UIViewController *)viewController adapterConfig:(ISAdapterConfig *)adapterConfig delegate:(id<ISInterstitialAdapterDelegate>)delegate {
    NSString *zoneId = adapterConfig.settings[kZoneId];
    LogAdapterApi_Internal(@"zoneId = %@", zoneId);
    AdColonyInterstitial *ad = [_interstitialZoneIdToAd objectForKey:zoneId];
    
    if ([self hasInterstitialWithAdapterConfig:adapterConfig]) {
        BOOL showReady = [ad showWithPresentingViewController:viewController];
        
        if (!showReady) {
            NSError *error = [NSError errorWithDomain:kAdapterName code:ERROR_CODE_GENERIC userInfo:@{NSLocalizedDescriptionKey : @"AdColony SDK not ready to show ad"}];
            [delegate adapterInterstitialDidFailToShowWithError:error];
        }
    } else {
        NSError *error = [ISError createError:ERROR_CODE_NO_ADS_TO_SHOW withMessage:[NSString stringWithFormat: @"%@ show failed", kAdapterName]];
        LogAdapterApi_Internal(@"error = %@", error);
        [delegate adapterInterstitialDidFailToShowWithError:error];
    }
}

- (BOOL)hasInterstitialWithAdapterConfig:(ISAdapterConfig *)adapterConfig {
    LogAdapterApi_Internal(@"");
    NSString *zoneId = adapterConfig.settings[kZoneId];
    AdColonyInterstitial *ad = [_interstitialZoneIdToAd objectForKey:zoneId];
    return (ad != nil) && !ad.expired;
}

- (NSDictionary *)getInterstitialBiddingDataWithAdapterConfig:(ISAdapterConfig *)adapterConfig {
    LogAdapterApi_Internal(@"");
    return [self getBiddingData];
}

#pragma mark - Interstitial Callbacks

- (void)onInterstitialDidLoad:(AdColonyInterstitial *)ad forZoneId:(NSString *)zoneId {
    LogAdapterDelegate_Internal(@"zoneId = %@", zoneId);
    [_interstitialZoneIdToAd setObject:ad forKey:zoneId];
    id<ISInterstitialAdapterDelegate> delegate = [_interstitialZoneIdToSmashDelegate objectForKey:zoneId];
    
    if (delegate) {
        [delegate adapterInterstitialDidLoad];
    }
}

- (void)onInterstitialDidFailToLoad:(NSString *)zoneId withError:(AdColonyAdRequestError *)error {
    LogAdapterDelegate_Internal(@"zoneId = %@, error = %@", zoneId, error);
    id<ISInterstitialAdapterDelegate> delegate = [_interstitialZoneIdToSmashDelegate objectForKey:zoneId];
    
    if (delegate) {
        NSError *smashError;
    
        if (error.code == AdColonyRequestErrorNoFillForRequest) {
            smashError = [NSError errorWithDomain:kAdapterName code:ERROR_IS_LOAD_NO_FILL userInfo:@{NSLocalizedDescriptionKey:@"AdColony no fill"}];
        } else {
            smashError = error;
        }
        
        [delegate adapterInterstitialDidFailToLoadWithError:smashError];
    }
}

- (void)onInterstitialDidOpen:(NSString *)zoneId {
    LogAdapterDelegate_Internal(@"zoneId = %@", zoneId);
    id<ISInterstitialAdapterDelegate> delegate = [_interstitialZoneIdToSmashDelegate objectForKey:zoneId];
    
    if (delegate) {
        [delegate adapterInterstitialDidOpen];
        [delegate adapterInterstitialDidShow];
    }
}

- (void)onInterstitialDidClick:(NSString *)zoneId {
    LogAdapterDelegate_Internal(@"zoneId = %@", zoneId);
    id<ISInterstitialAdapterDelegate> delegate = [_interstitialZoneIdToSmashDelegate objectForKey:zoneId];
    
    if (delegate) {
        [delegate adapterInterstitialDidClick];
    }
}

- (void)onInterstitialDidClose:(NSString *)zoneId {
    LogAdapterDelegate_Internal(@"zoneId = %@", zoneId);
    id<ISInterstitialAdapterDelegate> delegate = [_interstitialZoneIdToSmashDelegate objectForKey:zoneId];
    
    if (delegate) {
        [delegate adapterInterstitialDidClose];
    }
}

#pragma mark - Banner API

- (void)initBannerForBiddingWithUserId:(NSString *)userId
                         adapterConfig:(ISAdapterConfig *)adapterConfig
                              delegate:(id<ISBannerAdapterDelegate>)delegate {
    LogInternal_Internal(@"");
    [self initBannerWithUserId:userId adapterConfig:adapterConfig delegate:delegate];
}

- (void)initBannerWithUserId:(nonnull NSString *)userId
               adapterConfig:(nonnull ISAdapterConfig *)adapterConfig
                    delegate:(nonnull id<ISBannerAdapterDelegate>)delegate {
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
    
    ISAdColonyBannerListener *bannerListener = [[ISAdColonyBannerListener alloc] initWithZoneId:zoneId andDelegate:self];
    [_bannerZoneIdToListener setObject:bannerListener forKey:zoneId];
    // add delegate to dictionary
    [_bannerZoneIdToSmashDelegate setObject:delegate forKey:zoneId];
    
    // call delegate if already inited
    if (_initState == INIT_STATE_SUCCESS) {
        [delegate adapterBannerInitSuccess];
    } else if (_initState == INIT_STATE_FAILED) {
        NSError *error = [NSError errorWithDomain:kAdapterName code:ERROR_CODE_INIT_FAILED userInfo:@{NSLocalizedDescriptionKey:@"AdColony SDK init failed"}];
        LogAdapterApi_Internal(@"error.description = %@", error.description);
        [delegate adapterBannerInitFailedWithError:error];
    } else {
        [self initAdColonySDKWithAppId:appId userId:userId];
    }
}

- (void)loadBannerWithViewController:(nonnull UIViewController *)viewController
                                size:(nonnull ISBannerSize *)size
                       adapterConfig:(nonnull ISAdapterConfig *)adapterConfig
                            delegate:(nonnull id <ISBannerAdapterDelegate>)delegate {
    LogAdapterApi_Internal(@"");
    [self loadBannerInternal:adapterConfig delegate:delegate size:size viewController:viewController adOptions:nil];
}

- (void)loadBannerForBiddingWithServerData:(NSString *)serverData
                            viewController:(UIViewController *)viewController
                                      size:(ISBannerSize *)size
                             adapterConfig:(ISAdapterConfig *)adapterConfig
                                  delegate:(id <ISBannerAdapterDelegate>)delegate {
    LogAdapterApi_Internal(@"");
    AdColonyAdOptions *adOptions = [AdColonyAdOptions new];
    [adOptions setOption:kAdMarkupKey withStringValue:serverData];
    [self loadBannerInternal:adapterConfig delegate:delegate size:size viewController:viewController adOptions:adOptions];
}

- (void)loadBannerInternal:(ISAdapterConfig * _Nonnull)adapterConfig
                  delegate:(id<ISBannerAdapterDelegate> _Nonnull)delegate
                      size:(ISBannerSize * _Nonnull)size
            viewController:(UIViewController * _Nonnull)viewController
                 adOptions:(AdColonyAdOptions* _Nullable)adOptions {
    NSString *zoneId = adapterConfig.settings[kZoneId];
    
    // verify size
    if (![self isBannerSizeSupported:size]) {
        NSError *error = [NSError errorWithDomain:kAdapterName code:ERROR_BN_UNSUPPORTED_SIZE userInfo:@{NSLocalizedDescriptionKey:[NSString stringWithFormat:@"AdColony unsupported banner size = %@", size.sizeDescription]}];
        LogAdapterApi_Internal(@"error = %@", error);
        [delegate adapterBannerDidFailToLoadWithError:error];
    }
    
    // add delegate to dictionary
    [_bannerZoneIdToSmashDelegate setObject:delegate forKey:zoneId];
    
    // add size to dictionary
    [_bannerZoneIdToSize setObject:size forKey:zoneId];
    
    // add view controller to dictionary
    [_bannerZoneIdToViewController setObject:viewController forKey:zoneId];
    
    AdColonyAdSize bannerSize = [self getBannerSize:size];
    
    ISAdColonyBannerListener *bannerListener = [_bannerZoneIdToListener objectForKey:zoneId];
    
    // load banner
    [AdColony requestAdViewInZone:zoneId withSize:bannerSize
                       andOptions:adOptions viewController:viewController andDelegate:bannerListener];
}

- (void)reloadBannerWithAdapterConfig:(nonnull ISAdapterConfig *)adapterConfig
                             delegate:(nonnull id <ISBannerAdapterDelegate>)delegate {
    LogInternal_Warning(@"Unsupported method");
}

- (void)destroyBannerWithAdapterConfig:(nonnull ISAdapterConfig *)adapterConfig {
    NSString *zoneId = adapterConfig.settings[kZoneId];
    
    // get banner ad
    AdColonyAdView *bannerAd = [_bannerZoneIdToAd objectForKey:zoneId];
    
    if (bannerAd) {
        LogAdapterApi_Internal(@"destroy banner ad");
        // destroy banner
        [bannerAd destroy];
        
        // remove from dictionaries
        [_bannerZoneIdToSmashDelegate removeObjectForKey:zoneId];
        [_bannerZoneIdToListener removeObjectForKey:zoneId];
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

- (NSDictionary *)getBannerBiddingDataWithAdapterConfig:(ISAdapterConfig *)adapterConfig {
    LogAdapterApi_Internal(@"");
    return [self getBiddingData];
}


#pragma mark - Banner Delegate

- (void)onBannerLoadSuccess:(AdColonyAdView * _Nonnull)adView forZoneId:(NSString * _Nonnull)zoneId {
    LogAdapterDelegate_Internal(@"zoneId = %@", zoneId);
    [_bannerZoneIdToAd setObject:adView forKey:zoneId];
    
    id<ISBannerAdapterDelegate> delegate = [_bannerZoneIdToSmashDelegate objectForKey:zoneId];
    
    if (delegate) {
        [delegate adapterBannerDidLoad:adView];
        [delegate adapterBannerDidShow];
    }
}

- (void)onBannerLoadFail:(NSString * _Nonnull)zoneId WithError:(AdColonyAdRequestError * _Nonnull)error {
    LogAdapterDelegate_Internal(@"zoneId = %@, error = %@", zoneId, error.localizedDescription);
    id<ISBannerAdapterDelegate> delegate = [_bannerZoneIdToSmashDelegate objectForKey:zoneId];
    
    if (delegate) {
        NSError *bannerError = nil;
        
        if (error.code == AdColonyRequestErrorNoFillForRequest) {
            bannerError = [NSError errorWithDomain:kAdapterName code:ERROR_BN_LOAD_NO_FILL userInfo:@{NSLocalizedDescriptionKey:@"AdColony no fill"}];
        } else {
            bannerError = error;
        }
        
        [delegate adapterBannerDidFailToLoadWithError:bannerError];
    }
}

- (void)onBannerDidClick:(AdColonyAdView * _Nonnull)adView forZoneId:(NSString * _Nonnull)zoneId {
    LogAdapterDelegate_Internal(@"zoneId = %@", zoneId);
    id<ISBannerAdapterDelegate> delegate = [_bannerZoneIdToSmashDelegate objectForKey:zoneId];
    
    if (delegate) {
        [delegate adapterBannerDidClick];
    }
}

- (void)onBannerBannerWillLeaveApplication:(AdColonyAdView * _Nonnull)adView forZoneId:(NSString * _Nonnull)zoneId {
    LogAdapterDelegate_Internal(@"zoneId = %@", zoneId);
    id<ISBannerAdapterDelegate> delegate = [_bannerZoneIdToSmashDelegate objectForKey:zoneId];
    
    if (delegate) {
        [delegate adapterBannerWillLeaveApplication];
    }
}

- (void)onBannerBannerWillPresentScreen:(AdColonyAdView * _Nonnull)adView forZoneId:(NSString * _Nonnull)zoneId {
    LogAdapterDelegate_Internal(@"zoneId = %@", zoneId);
    id<ISBannerAdapterDelegate> delegate = [_bannerZoneIdToSmashDelegate objectForKey:zoneId];
    
    if (delegate) {
        [delegate adapterBannerWillPresentScreen];
    }
}

- (void)onBannerBannerDidDismissScreen:(AdColonyAdView * _Nonnull)adView forZoneId:(NSString * _Nonnull)zoneId {
    LogAdapterDelegate_Internal(@"zoneId = %@", zoneId);
    id<ISBannerAdapterDelegate> delegate = [_bannerZoneIdToSmashDelegate objectForKey:zoneId];
    
    if (delegate) {
        [delegate adapterBannerDidDismissScreen];
    }
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

- (void)setMetaDataWithKey:(NSString *)key andValues:(NSMutableArray *) values {
    if (values.count == 0) {
        return;
    }
    
    NSString *value = values[0];
    LogAdapterApi_Internal(@"key = %@, value = %@", key, value);
    
    if ([ISMetaDataUtils isValidCCPAMetaDataWithKey:key andValue:value]) {
        [self setCCPAValue:value];
    } else  {
        NSString *formattedValue = [ISMetaDataUtils formatValue:value forType:(META_DATA_VALUE_BOOL)];
        if ([self isValidCOPPAMetaDataKey:key andValue:formattedValue]) {
            [self setCOPPAValue:formattedValue];
        }
    }
}

- (void)setConsent:(BOOL)consent {
    NSString *consentVal = consent ? @"1" : @"0";
    [adColonyOptions setPrivacyFrameworkOfType:ADC_GDPR isRequired:YES];
    [adColonyOptions setPrivacyConsentString:consentVal forType:ADC_GDPR];

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
    [adColonyOptions setPrivacyFrameworkOfType:ADC_CCPA isRequired:YES];
    [adColonyOptions setPrivacyConsentString:consentString forType:ADC_CCPA];
    
    if (_initState == INIT_STATE_SUCCESS) {
        LogAdapterApi_Internal(@"key = %@ value = %@", ADC_CCPA, consentString);
        [AdColony setAppOptions:adColonyOptions];
    }
}

- (void)setCOPPAValue:(NSString *)value {
    
    BOOL isCOPPAOptedIn = [ISMetaDataUtils getCCPABooleanValue:value];
    

    [adColonyOptions setPrivacyFrameworkOfType:ADC_COPPA isRequired:isCOPPAOptedIn];
    
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
