//
//  ISUnityAdsAdapter.m
//  ISUnityAdsAdapter
//
//  Created by Clementine on 2/4/15.
//  Copyright (c) 2015 Clementine. All rights reserved.
//

#import "ISUnityAdsAdapter.h"
#import "ISUnityAdsBannerListener.h"
#import "ISUnityAdsInterstitialListener.h"
#import "ISUnityAdsRewardedVideoListener.h"
#import "IronSource/IronSource.h"
#import <UnityAds/UnityAds.h>


// UnityAds Mediation MetaData
static NSString * const kMediationName = @"ironSource";
static NSString * const kAdapterVersionKey = @"adapter_version";

// Network keys
static NSString * const kAdapterVersion         = UnityAdsAdapterVersion;
static NSString * const kAdapterName            = @"UnityAds";
static NSString * const kGameId                 = @"sourceId";
static NSString * const kPlacementId            = @"zoneId";

// Meta data flags
static NSString * const kMetaDataCOPPAKey       = @"unityads_coppa";
static NSString * const kCCPAUnityAdsFlag       = @"privacy.consent";
static NSString * const kGDPRUnityAdsFlag       = @"gdpr.consent";
static NSString * const kCOPPAUnityAdsFlag      = @"user.nonBehavioral";

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

// Feature flag key for getting token asynchronically
static NSString * const kIsAsyncTokenEnabled    = @"isAsyncTokenEnabled";
static NSString *asyncToken                     = nil;

// Feature flag key to support the network's capability to load a Rewarded Video ad while another Rewarded Video ad of that network is showing
static NSString * const kIsLWSSupported         = @"isSupportedLWS";

@interface ISUnityAdsAdapter () <UnityAdsInitializationDelegate, ISNetworkInitCallbackProtocol, ISUnityAdsBannerDelegateWrapper, ISUnityAdsInterstitialDelegateWrapper, ISUnityAdsRewardedVideoDelegateWrapper>

// Rewrded video
@property (nonatomic, strong) ConcurrentMutableDictionary *rewardedVideoPlacementIdToSmashDelegate;
@property (nonatomic, strong) ConcurrentMutableDictionary *rewardedVideoPlacementIdToObjectId;
@property (nonatomic, strong) ConcurrentMutableDictionary *rewardedVideoPlacementIdToListener;
@property (nonatomic, strong) ConcurrentMutableDictionary *rewardedVideoAdsAvailability;
@property (nonatomic, strong) ConcurrentMutableSet        *rewardedVideoPlacementIdsForInitCallbacks;

// Interstitial
@property (nonatomic, strong) ConcurrentMutableDictionary *interstitialPlacementIdToSmashDelegate;
@property (nonatomic, strong) ConcurrentMutableDictionary *interstitialPlacementIdToObjectId;
@property (nonatomic, strong) ConcurrentMutableDictionary *interstitialPlacementIdToListener;
@property (nonatomic, strong) ConcurrentMutableDictionary *interstitialAdsAvailability;

// Banner
@property (nonatomic, strong) ConcurrentMutableDictionary *bannerPlacementIdToSmashDelegate;
@property (nonatomic, strong) ConcurrentMutableDictionary *bannerPlacementIdToListener;
@property (nonatomic, strong) ConcurrentMutableDictionary *bannerPlacementIdToAd;

// synchronization lock
@property (nonatomic, strong) NSObject                    *UnityAdsStorageLock;

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

// network system frameworks
- (NSArray *) systemFrameworks {
    return @[@"AdSupport", @"CoreTelephony", @"StoreKit"];
}
    
- (NSString *) sdkName {
    return kAdapterName;
}

#pragma mark - Initializations Methods And Callbacks

- (instancetype) initAdapter:(NSString *)name {
    self = [super initAdapter:name];
    
    if (self) {
        if (initCallbackDelegates == nil) {
            initCallbackDelegates = [ConcurrentMutableSet<ISNetworkInitCallbackProtocol> set];
        }
        
        // Rewarded video
        _rewardedVideoPlacementIdToSmashDelegate = [ConcurrentMutableDictionary dictionary];
        _rewardedVideoPlacementIdToObjectId = [ConcurrentMutableDictionary dictionary];
        _rewardedVideoPlacementIdToListener = [ConcurrentMutableDictionary dictionary];
        _rewardedVideoAdsAvailability = [ConcurrentMutableDictionary dictionary];
        _rewardedVideoPlacementIdsForInitCallbacks = [ConcurrentMutableSet set];
        
        // Interstitial
        _interstitialPlacementIdToSmashDelegate = [ConcurrentMutableDictionary dictionary];
        _interstitialPlacementIdToObjectId = [ConcurrentMutableDictionary dictionary];
        _interstitialPlacementIdToListener = [ConcurrentMutableDictionary dictionary];
        _interstitialAdsAvailability = [ConcurrentMutableDictionary dictionary];
        
        // Banner
        _bannerPlacementIdToSmashDelegate = [ConcurrentMutableDictionary dictionary];
        _bannerPlacementIdToListener = [ConcurrentMutableDictionary dictionary];
        _bannerPlacementIdToAd = [ConcurrentMutableDictionary dictionary];
        
        _UnityAdsStorageLock = [NSObject new];
    }
    
    return self;
}

- (void) initSDKWithGameId:(NSString *)gameId adapterConfig:(ISAdapterConfig *)adapterConfig  {

    // add self to the init delegates only in case the initialization has not finished yet
    if (_initState == INIT_STATE_NONE || _initState == INIT_STATE_IN_PROGRESS) {
        [initCallbackDelegates addObject:self];
    }
    
    // Init SDK should be called only once
    static dispatch_once_t oncePredicate;
    dispatch_once(&oncePredicate, ^{
        dispatch_async(dispatch_get_main_queue(), ^{
            _initState = INIT_STATE_IN_PROGRESS;
            LogAdapterApi_Internal(@"gameId = %@", gameId);



            @synchronized (_UnityAdsStorageLock) {
                UADSMediationMetaData *mediationMetaData = [[UADSMediationMetaData alloc] init];
                [mediationMetaData setName:kMediationName];
                
                [mediationMetaData setVersion:[IronSource sdkVersion]];
                [mediationMetaData set:kAdapterVersionKey value:kAdapterVersion];
                [mediationMetaData commit];
            }

            [UnityAds setDebugMode:[ISConfigurations getConfigurations].adaptersDebug];
            LogAdapterApi_Internal(@"setDebugMode = %d", [ISConfigurations getConfigurations].adaptersDebug);

            [UnityAds initialize:gameId testMode:NO initializationDelegate:self];
            
            // trying to fetch async token for the first load
            [self getAsyncToken:adapterConfig];
        });
        
    });
}

- (void) initializationComplete {
    LogAdapterDelegate_Internal(@"UnityAds init success");
    
    _initState = INIT_STATE_SUCCESS;
    
    NSArray *initDelegatesList = initCallbackDelegates.allObjects;
    
    // call init callback delegate success
    for (id<ISNetworkInitCallbackProtocol> initDelegate in initDelegatesList) {
        [initDelegate onNetworkInitCallbackSuccess];
    }
    
    [initCallbackDelegates removeAllObjects];
}

- (void)initializationFailed: (UnityAdsInitializationError)error
                 withMessage: (NSString *)message {
    NSString *initError = [NSString stringWithFormat:@"%@ - %@", [self unityAdsInitErrorToString:error], message];
    LogAdapterDelegate_Internal(@"init failed error - %@", initError);

    _initState = INIT_STATE_FAILED;
    
    NSArray *initDelegatesList = initCallbackDelegates.allObjects;
    
    // call init callback delegate fail
    for (id<ISNetworkInitCallbackProtocol> initDelegate in initDelegatesList) {
        [initDelegate onNetworkInitCallbackFailed:initError];
    }
    
    [initCallbackDelegates removeAllObjects];
}

- (void) onNetworkInitCallbackSuccess {
    // rewarded video
    NSArray *rewardedVideoPlacementIDs = _rewardedVideoPlacementIdToSmashDelegate.allKeys;
    
    for (NSString *placementId in rewardedVideoPlacementIDs) {
        if ([_rewardedVideoPlacementIdsForInitCallbacks hasObject:placementId]) {
            id<ISRewardedVideoAdapterDelegate> delegate = [_rewardedVideoPlacementIdToSmashDelegate objectForKey:placementId];
            [delegate adapterRewardedVideoInitSuccess];
        } else {
            [self loadRewardedVideoInternal:placementId andServerData:nil];
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

- (void) onNetworkInitCallbackFailed:(nonnull NSString *)errorMessage {
    NSError *error = [NSError errorWithDomain:kAdapterName code:ERROR_CODE_INIT_FAILED userInfo:@{NSLocalizedDescriptionKey:errorMessage}];
    
    // rewarded video
    NSArray *rewardedVideoPlacementIDs = _rewardedVideoPlacementIdToSmashDelegate.allKeys;

    for (NSString *placementId in rewardedVideoPlacementIDs) {
        id<ISRewardedVideoAdapterDelegate> delegate = [_rewardedVideoPlacementIdToSmashDelegate objectForKey:placementId];
        
        if ([_rewardedVideoPlacementIdsForInitCallbacks hasObject:placementId]) {
            [delegate adapterRewardedVideoInitFailed:error];
        } else {
            [delegate adapterRewardedVideoHasChangedAvailability:NO];
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
- (void) initRewardedVideoForCallbacksWithUserId:(NSString *)userId
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
    [_rewardedVideoPlacementIdToSmashDelegate setObject:delegate forKey:placementId];
    
    // Create rewarded video listener
    ISUnityAdsRewardedVideoListener *rewardedVideoListener = [[ISUnityAdsRewardedVideoListener alloc] initWithPlacementId:placementId andDelegate:self];
    [_rewardedVideoPlacementIdToListener setObject:rewardedVideoListener forKey:placementId];
    
    // Register rewarded video to init callback
    [_rewardedVideoPlacementIdsForInitCallbacks addObject:placementId];
    
    switch (_initState) {
        case INIT_STATE_NONE:
        case INIT_STATE_IN_PROGRESS:
            [self initSDKWithGameId:gameId adapterConfig:adapterConfig];
            break;
        case INIT_STATE_FAILED:
            [delegate adapterRewardedVideoInitFailed:[NSError errorWithDomain:kAdapterName code:ERROR_CODE_INIT_FAILED userInfo:@{NSLocalizedDescriptionKey:@"UnityAds SDK init failed"}]];
            break;
        case INIT_STATE_SUCCESS:
            [delegate adapterRewardedVideoInitSuccess];
            break;
    }
}

// used for flows when the mediation doesn't need to get a callback for init
- (void) initAndLoadRewardedVideoWithUserId:(NSString *)userId
                              adapterConfig:(ISAdapterConfig *)adapterConfig
                                   delegate:(id<ISRewardedVideoAdapterDelegate>)delegate {
    NSString *gameId = adapterConfig.settings[kGameId];
    NSString *placementId = adapterConfig.settings[kPlacementId];

    // Configuration Validation
    if (![self isConfigValueValid:gameId]) {
        NSError *error = [self errorForMissingCredentialFieldWithName:kGameId];
        LogAdapterApi_Internal(@"error = %@", error);
        [delegate adapterRewardedVideoHasChangedAvailability:NO];
        return;
    }
    
    if (![self isConfigValueValid:placementId]) {
        NSError *error = [self errorForMissingCredentialFieldWithName:kPlacementId];
        LogAdapterApi_Internal(@"error = %@", error);
        [delegate adapterRewardedVideoHasChangedAvailability:NO];
        return;
    }
    
    LogAdapterApi_Internal(@"placementId = %@", placementId);
    
    // Register Delegate for placement
    [_rewardedVideoPlacementIdToSmashDelegate setObject:delegate forKey:placementId];
    
    // Create rewarded video listener
    ISUnityAdsRewardedVideoListener *rewardedVideoListener = [[ISUnityAdsRewardedVideoListener alloc] initWithPlacementId:placementId andDelegate:self];
    [_rewardedVideoPlacementIdToListener setObject:rewardedVideoListener forKey:placementId];
    
    switch (_initState) {
        case INIT_STATE_NONE:
        case INIT_STATE_IN_PROGRESS:
            [self initSDKWithGameId:gameId adapterConfig:adapterConfig];
            break;
        case INIT_STATE_FAILED:
            [delegate adapterRewardedVideoHasChangedAvailability:NO];
            break;
        case INIT_STATE_SUCCESS:
            [self loadRewardedVideoInternal:placementId andServerData:nil];
            break;
    }
}

- (void) loadRewardedVideoForBiddingWithAdapterConfig:(ISAdapterConfig *)adapterConfig
                                           serverData:(NSString *)serverData
                                             delegate:(id<ISRewardedVideoAdapterDelegate>)delegate{
    NSString *placementId = adapterConfig.settings[kPlacementId];
    LogAdapterApi_Internal(@"placementId = %@", placementId);
    [self loadRewardedVideoInternal:placementId andServerData:serverData];
}

- (void) fetchRewardedVideoForAutomaticLoadWithAdapterConfig:(ISAdapterConfig *)adapterConfig
                                                    delegate:(id<ISRewardedVideoAdapterDelegate>)delegate {
    NSString *placementId = adapterConfig.settings[kPlacementId];
    LogAdapterApi_Internal(@"placementId = %@", placementId);
    [self loadRewardedVideoInternal:placementId andServerData:nil];
}

- (void) loadRewardedVideoInternal:(NSString *)placementId andServerData:(NSString *)serverData {
    LogAdapterApi_Internal(@"placementId = %@", placementId);
    [_rewardedVideoAdsAvailability setObject:@NO forKey:placementId];
    if(serverData != nil) {
        UADSLoadOptions *options = [UADSLoadOptions new];
        // objectId is used to identify a loaded ad and to show it
        NSString *objectId = [[NSUUID UUID] UUIDString];
        [options setObjectId:objectId];
        [options setAdMarkup:serverData];
        [_rewardedVideoPlacementIdToObjectId setObject:objectId forKey:placementId];
        
        // Load rewarded video for bidding instance
        [UnityAds load:placementId options:options loadDelegate:[_rewardedVideoPlacementIdToListener objectForKey:placementId]];
    } else {
        // Load rewarded video for non bidding instance
        [UnityAds load:placementId loadDelegate:[_rewardedVideoPlacementIdToListener objectForKey:placementId]];
    }

}

- (void) showRewardedVideoWithViewController:(UIViewController *)viewController
                               adapterConfig:(ISAdapterConfig *)adapterConfig
                                    delegate:(id<ISRewardedVideoAdapterDelegate>)delegate {
    NSString *placementId = adapterConfig.settings[kPlacementId];
    LogAdapterApi_Internal(@"placementId = %@", placementId);
    
    if (![self hasRewardedVideoWithAdapterConfig:adapterConfig]) {
        NSError *error = [ISError createError:ERROR_CODE_NO_ADS_TO_SHOW withMessage:[NSString stringWithFormat: @"%@ show failed", kAdapterName]];
        LogAdapterApi_Internal(@"error = %@", error);
        [delegate adapterRewardedVideoDidFailToShowWithError:error];
        return;
    }
    
    [delegate adapterRewardedVideoHasChangedAvailability:NO];

    dispatch_async(dispatch_get_main_queue(), ^{
        @try {
            if ([self dynamicUserId]) {
                @synchronized (_UnityAdsStorageLock) {
                    id playerMetaData = [[UADSPlayerMetaData alloc] init];
                    [playerMetaData setServerId:[self dynamicUserId]];
                    [playerMetaData commit];
                }
            }
            
            UIViewController *vc = viewController == nil ? [self topMostController] : viewController;
            id<UnityAdsShowDelegate>showDelegate = [_rewardedVideoPlacementIdToListener objectForKey:placementId];;
            
            if ([_rewardedVideoPlacementIdToObjectId hasObjectForKey:placementId]) {
                // Show rewarded video for bidding instance
                UADSShowOptions *options = [UADSShowOptions new];
                [options setObjectId:[_rewardedVideoPlacementIdToObjectId objectForKey:placementId]];
                [UnityAds show:vc placementId:placementId options:options showDelegate:showDelegate];
            } else {
                // Show rewarded video for non bidding instance
                [UnityAds show:vc placementId:placementId showDelegate:showDelegate];
            }
        }
        @catch (NSException *exception) {
            NSString *message = [NSString stringWithFormat:@"ISUnityAdsAdapter: Exception while trying to show a rewarded video ad. Description: '%@'", exception.description];
            LogAdapterApi_Internal(@"message = %@", message);
            NSError *showError = [NSError errorWithDomain:kAdapterName code:ERROR_CODE_NO_ADS_TO_SHOW userInfo:@{NSLocalizedDescriptionKey: message}];
            [delegate adapterRewardedVideoDidFailToShowWithError:showError];
        }
        
        [_rewardedVideoAdsAvailability setObject:@NO forKey:placementId];
    });
}

- (BOOL) hasRewardedVideoWithAdapterConfig:(ISAdapterConfig *)adapterConfig {
    NSString *placementId = adapterConfig.settings[kPlacementId];
    NSNumber *available = [_rewardedVideoAdsAvailability objectForKey:placementId];
    return (available != nil) && [available boolValue];
}

- (NSDictionary *) getRewardedVideoBiddingDataWithAdapterConfig:(ISAdapterConfig *)adapterConfig {
    LogAdapterApi_Internal(@"");
    return [self getBiddingData];
}

#pragma mark - Rewarded Video Delegate

- (void) onRewardedVideoLoadSuccess:(NSString * _Nonnull)placementId {
    LogAdapterDelegate_Internal(@"placementId = %@", placementId);
    [_rewardedVideoAdsAvailability setObject:@YES forKey:placementId];
    id<ISRewardedVideoAdapterDelegate> delegate = [_rewardedVideoPlacementIdToSmashDelegate objectForKey:placementId];
    
    if (delegate) {
        [delegate adapterRewardedVideoHasChangedAvailability:YES];
    }
}

- (void) onRewardedVideoLoadFail:(NSString * _Nonnull)placementId
                       withError:(UnityAdsLoadError)error {
    NSString *loadError = [self unityAdsLoadErrorToString:error];
    LogAdapterDelegate_Internal(@"placementId = %@ reason - %@", placementId, loadError);
    [_rewardedVideoAdsAvailability setObject:@NO forKey:placementId];
    id<ISRewardedVideoAdapterDelegate> delegate = [_rewardedVideoPlacementIdToSmashDelegate objectForKey:placementId];
    
    if (delegate) {
        NSInteger errorCode = (error == kUnityAdsLoadErrorNoFill) ? ERROR_RV_LOAD_NO_FILL : error;
        NSError *smashError = [NSError errorWithDomain:kAdapterName code:errorCode userInfo:@{NSLocalizedDescriptionKey:loadError}];
        [delegate adapterRewardedVideoHasChangedAvailability:NO];
        [delegate adapterRewardedVideoDidFailToLoadWithError:smashError];
    }
}


- (void) onRewardedVideoDidShow:(NSString * _Nonnull)placementId {
    LogAdapterDelegate_Internal(@"placementId = %@", placementId);
    id<ISRewardedVideoAdapterDelegate> delegate = [_rewardedVideoPlacementIdToSmashDelegate objectForKey:placementId];
    
    if (delegate) {
        [delegate adapterRewardedVideoDidOpen];
        [delegate adapterRewardedVideoDidStart];
    }
}

- (void) onRewardedVideoShowFail:(NSString * _Nonnull)placementId
                       withError:(UnityAdsShowError)error
                      andMessage:(NSString * _Nonnull)errorMessage {
    NSString *showError = [NSString stringWithFormat:@"%@ - %@", [self unityAdsShowErrorToString:error], errorMessage];
    LogAdapterDelegate_Internal(@"placementId = %@ reason = %@", placementId, showError);
    id<ISRewardedVideoAdapterDelegate> delegate = [_rewardedVideoPlacementIdToSmashDelegate objectForKey:placementId];

    if (delegate) {
        NSError *smashError = [NSError errorWithDomain:kAdapterName code:error userInfo:@{NSLocalizedDescriptionKey: showError}];
        [delegate adapterRewardedVideoDidFailToShowWithError:smashError];
    }
}

- (void) onRewardedVideoDidClick:(NSString * _Nonnull)placementId {
    LogAdapterDelegate_Internal(@"placementId = %@", placementId);
    id<ISRewardedVideoAdapterDelegate> delegate = [_rewardedVideoPlacementIdToSmashDelegate objectForKey:placementId];
    
    if (delegate) {
        [delegate adapterRewardedVideoDidClick];
    }
}

- (void) onRewardedVideoDidShowComplete:(NSString * _Nonnull)placementId
                        withFinishState:(UnityAdsShowCompletionState)state {
    LogAdapterDelegate_Internal(@"placementId = %@ and completion state = %d", placementId, (int)state);
    id<ISRewardedVideoAdapterDelegate> delegate = [_rewardedVideoPlacementIdToSmashDelegate objectForKey:placementId];
       
    if (delegate) {
       switch (state) {
           case kUnityShowCompletionStateSkipped: {
               [delegate adapterRewardedVideoDidClose];
               break;
           }
           case kUnityShowCompletionStateCompleted: {
               [delegate adapterRewardedVideoDidEnd];
               [delegate adapterRewardedVideoDidReceiveReward];
               [delegate adapterRewardedVideoDidClose];
               break;
           }
           default:
               break;
       }
    }
}

#pragma mark - Interstitial API

- (void) initInterstitialForBiddingWithUserId:(NSString *)userId
                                adapterConfig:(ISAdapterConfig *)adapterConfig
                                     delegate:(id<ISInterstitialAdapterDelegate>)delegate {
    LogAdapterApi_Internal(@"");
    [self initInterstitialWithUserId:userId adapterConfig:adapterConfig delegate:delegate];
}

- (void) initInterstitialWithUserId:(NSString *)userId adapterConfig:(ISAdapterConfig *)adapterConfig delegate:(id<ISInterstitialAdapterDelegate>)delegate {
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
    [_interstitialPlacementIdToSmashDelegate setObject:delegate forKey:placementId];
    
    // Create interstitial listener
    ISUnityAdsInterstitialListener *interstitialListener = [[ISUnityAdsInterstitialListener alloc] initWithPlacementId:placementId andDelegate:self];
    [_interstitialPlacementIdToListener setObject:interstitialListener forKey:placementId];
    
    switch (_initState) {
        case INIT_STATE_NONE:
        case INIT_STATE_IN_PROGRESS:
            [self initSDKWithGameId:gameId adapterConfig:adapterConfig];
            break;
        case INIT_STATE_FAILED:
            [delegate adapterInterstitialInitFailedWithError:[NSError errorWithDomain:kAdapterName code:ERROR_CODE_INIT_FAILED userInfo:@{NSLocalizedDescriptionKey:@"UnityAds SDK init failed"}]];
            break;
        case INIT_STATE_SUCCESS:
            [delegate adapterInterstitialInitSuccess];
            break;
    }
}

- (void) loadInterstitialForBiddingWithServerData:(NSString *)serverData
                                    adapterConfig:(ISAdapterConfig *)adapterConfig
                                         delegate:(id<ISInterstitialAdapterDelegate>)delegate {
    NSString *placementId = adapterConfig.settings[kPlacementId];
    LogAdapterApi_Internal(@"placementId = %@", placementId);
    [self loadInterstitialInternal:placementId andServerData:serverData];

}

- (void) loadInterstitialWithAdapterConfig:(ISAdapterConfig *)adapterConfig delegate:(id<ISInterstitialAdapterDelegate>)delegate {
    NSString *placementId = adapterConfig.settings[kPlacementId];
    LogAdapterApi_Internal(@"placementId = %@", placementId);
    [self loadInterstitialInternal:placementId andServerData:nil];
}


- (void) loadInterstitialInternal:(NSString *)placementId andServerData:(NSString *)serverData {
    LogAdapterApi_Internal(@"placementId = %@", placementId);
    [_interstitialAdsAvailability setObject:@NO forKey:placementId];

    if(serverData != nil) {
        UADSLoadOptions *options = [UADSLoadOptions new];
        // objectId is used to identify a loaded ad and to show it
        NSString *objectId = [[NSUUID UUID] UUIDString];
        [options setObjectId:objectId];
        [options setAdMarkup:serverData];
        [_interstitialPlacementIdToObjectId setObject:objectId forKey:placementId];
        // Load interstitial for bidding instance
        [UnityAds load:placementId options:options loadDelegate:[_interstitialPlacementIdToListener objectForKey:placementId]];

    } else {
        // Load interstitial for non bidding instance
        [UnityAds load:placementId loadDelegate:[_interstitialPlacementIdToListener objectForKey:placementId]];
    }

}
- (void) showInterstitialWithViewController:(UIViewController *)viewController
                              adapterConfig:(ISAdapterConfig *)adapterConfig
                                   delegate:(id<ISInterstitialAdapterDelegate>)delegate {
    NSString *placementId = adapterConfig.settings[kPlacementId];
    LogAdapterApi_Internal(@"placementId = %@", placementId);
    
    if (![self hasInterstitialWithAdapterConfig:adapterConfig]) {
        NSError *error = [ISError createError:ERROR_CODE_NO_ADS_TO_SHOW withMessage:[NSString stringWithFormat: @"%@ show failed", kAdapterName]];
        LogAdapterApi_Internal(@"error = %@", error);
        [delegate adapterInterstitialDidFailToShowWithError:error];
        return;
    }
    
    dispatch_async(dispatch_get_main_queue(), ^{
        @try {
            if ([self dynamicUserId]) {
                @synchronized (_UnityAdsStorageLock) {
                    id playerMetaData = [[UADSPlayerMetaData alloc] init];
                    [playerMetaData setServerId:[self dynamicUserId]];
                    [playerMetaData commit];
                }
            }
            
            UIViewController *vc = viewController == nil ? [self topMostController] : viewController;
            id<UnityAdsShowDelegate>showDelegate = [_interstitialPlacementIdToListener objectForKey:placementId];;
            
            if ([_interstitialPlacementIdToObjectId hasObjectForKey:placementId]) {
                // Show interstitial for bidding instance
                UADSShowOptions *options = [UADSShowOptions new];
                [options setObjectId:[_interstitialPlacementIdToObjectId objectForKey:placementId]];
                [UnityAds show:vc placementId:placementId options:options showDelegate:showDelegate];
            } else {
                // Show interstitial for non bidding instance
                [UnityAds show:vc placementId:placementId showDelegate:showDelegate];
            }
        }
        @catch (NSException *exception) {
            NSString *message = [NSString stringWithFormat:@"ISUnityAdsAdapter: Exception while trying to show an interstitial ad. Description: '%@'", exception.description];
            LogAdapterApi_Internal(@"message = %@", message);
            NSError *showError = [NSError errorWithDomain:kAdapterName code:ERROR_CODE_NO_ADS_TO_SHOW userInfo:@{NSLocalizedDescriptionKey: message}];
            [delegate adapterInterstitialDidFailToShowWithError:showError];
        }
        
        [_interstitialAdsAvailability setObject:@NO forKey:placementId];
    });
}

- (BOOL) hasInterstitialWithAdapterConfig:(ISAdapterConfig *)adapterConfig {
    NSString *placementId = adapterConfig.settings[kPlacementId];
    NSNumber *available = [_interstitialAdsAvailability objectForKey:placementId];
    return (available != nil) && [available boolValue];
}

- (NSDictionary *) getInterstitialBiddingDataWithAdapterConfig:(ISAdapterConfig *)adapterConfig {
    LogAdapterApi_Internal(@"");
    return [self getBiddingData];
}

#pragma mark - Interstitial Delegate

- (void) onInterstitialLoadSuccess:(nonnull NSString *)placementId {
    LogAdapterDelegate_Internal(@"placementId = %@", placementId);
    [_interstitialAdsAvailability setObject:@YES forKey:placementId];
    id<ISInterstitialAdapterDelegate> delegate = [_interstitialPlacementIdToSmashDelegate objectForKey:placementId];
    
    if (delegate) {
        [delegate adapterInterstitialDidLoad];
    }
}

- (void) onInterstitialLoadFail:(nonnull NSString *)placementId
                      withError:(UnityAdsLoadError)error {
    NSString *loadError = [self unityAdsLoadErrorToString:error];
    LogAdapterDelegate_Internal(@"placementId = %@ reason - %@", placementId, loadError);
    [_interstitialAdsAvailability setObject:@NO forKey:placementId];
    id<ISInterstitialAdapterDelegate> delegate = [_interstitialPlacementIdToSmashDelegate objectForKey:placementId];
    
    if (delegate) {
        NSInteger errorCode = (error == kUnityAdsLoadErrorNoFill) ? ERROR_IS_LOAD_NO_FILL : error;
        NSError *smashError = [NSError errorWithDomain:kAdapterName code:errorCode userInfo:@{NSLocalizedDescriptionKey:loadError}];
        [delegate adapterInterstitialDidFailToLoadWithError:smashError];
    }
}

- (void) onInterstitialDidShow:(NSString * _Nonnull)placementId {
    LogAdapterDelegate_Internal(@"placementId = %@", placementId);
    id<ISInterstitialAdapterDelegate> delegate = [_interstitialPlacementIdToSmashDelegate objectForKey:placementId];
    
    if (delegate) {
        [delegate adapterInterstitialDidOpen];
        [delegate adapterInterstitialDidShow];
    }
}

- (void) onInterstitialShowFail:(NSString * _Nonnull)placementId
                      withError:(UnityAdsShowError)error
                     andMessage:(NSString * _Nonnull)errorMessage {
    NSString *showError = [NSString stringWithFormat:@"%@ - %@", [self unityAdsShowErrorToString:error], errorMessage];
    LogAdapterDelegate_Internal(@"placementId = %@ reason = %@", placementId, showError);
    id<ISInterstitialAdapterDelegate> delegate = [_interstitialPlacementIdToSmashDelegate objectForKey:placementId];

    if (delegate) {
        NSError *smashError = [NSError errorWithDomain:kAdapterName code:error userInfo:@{NSLocalizedDescriptionKey: showError}];
        [delegate adapterInterstitialDidFailToShowWithError:smashError];
    }
}

- (void) onInterstitialDidClick:(NSString * _Nonnull)placementId {
    LogAdapterDelegate_Internal(@"placementId = %@", placementId);
    id<ISInterstitialAdapterDelegate> delegate = [_interstitialPlacementIdToSmashDelegate objectForKey:placementId];
    
    if (delegate) {
        [delegate adapterInterstitialDidClick];
    }
}

- (void) onInterstitialDidShowComplete:(NSString * _Nonnull)placementId withFinishState:(UnityAdsShowCompletionState)state {
    LogAdapterDelegate_Internal(@"placementId = %@ and completion state = %d", placementId, (int)state);
    id<ISInterstitialAdapterDelegate> delegate = [_interstitialPlacementIdToSmashDelegate objectForKey:placementId];
    
    if (delegate) {
        switch (state) {
            case kUnityShowCompletionStateSkipped:
            case kUnityShowCompletionStateCompleted: {
                [delegate adapterInterstitialDidClose];
                break;
            }
            default:
                break;
        }
    }
}

#pragma mark - Banner API

- (void) initBannerWithUserId:(nonnull NSString *)userId
                adapterConfig:(nonnull ISAdapterConfig *)adapterConfig
                     delegate:(nonnull id<ISBannerAdapterDelegate>)delegate {
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
    [_bannerPlacementIdToSmashDelegate setObject:delegate forKey:placementId];
    
    // Create banner listener
    ISUnityAdsBannerListener *bannerListener = [[ISUnityAdsBannerListener alloc] initWithDelegate:self];
    [_bannerPlacementIdToListener setObject:bannerListener forKey:placementId];
    
    switch (_initState) {
        case INIT_STATE_NONE:
        case INIT_STATE_IN_PROGRESS:
            [self initSDKWithGameId:gameId adapterConfig:adapterConfig];
            break;
        case INIT_STATE_FAILED:
            [delegate adapterBannerInitFailedWithError:[NSError errorWithDomain:kAdapterName code:ERROR_CODE_INIT_FAILED userInfo:@{NSLocalizedDescriptionKey:@"UnityAds SDK init failed"}]];
            break;
        case INIT_STATE_SUCCESS:
            [delegate adapterBannerInitSuccess];
            break;
    }
}

- (void) loadBannerWithViewController:(nonnull UIViewController *)viewController
                                 size:(ISBannerSize *)size
                        adapterConfig:(nonnull ISAdapterConfig *)adapterConfig
                             delegate:(nonnull id <ISBannerAdapterDelegate>)delegate {
    NSString *placementId = adapterConfig.settings[kPlacementId];
    
    // Verify size
    if (![self isBannerSizeSupported:size]) {
        NSError *error = [ISError createError:ERROR_BN_UNSUPPORTED_SIZE withMessage:[NSString stringWithFormat:@"UnityAds unsupported banner size - %@", size.sizeDescription]];
        LogAdapterApi_Internal(@"error = %@", error);
        [delegate adapterBannerDidFailToLoadWithError:error];
        return;
    }
    
    LogAdapterApi_Internal(@"placementId = %@", placementId);
    
    
    dispatch_async(dispatch_get_main_queue(), ^{
        @try {
            // Create banner
            UADSBannerView *bannerView = [[UADSBannerView alloc] initWithPlacementId:placementId size:[self getBannerSize:size]];
            
            // Add to ad dictionary
            [_bannerPlacementIdToAd setObject:bannerView forKey:placementId];
            
            // Set delegate
            bannerView.delegate = [_bannerPlacementIdToListener objectForKey:placementId];
            
            // Load banner
            [bannerView load];
        } @catch (NSException *exception) {
            NSString *message = [NSString stringWithFormat:@"ISUnityAdsAdapter: Exception while trying to load a banner ad. Description: '%@'", exception.description];
            LogAdapterApi_Internal(@"message = %@", message);
            id<ISBannerAdapterDelegate> delegate = [_bannerPlacementIdToSmashDelegate objectForKey:placementId];
            NSError *smashError = [NSError errorWithDomain:kAdapterName code:ERROR_CODE_GENERIC userInfo:@{NSLocalizedDescriptionKey:message}];
            [delegate adapterBannerDidFailToLoadWithError:smashError];
        }
    });
}

- (void) reloadBannerWithAdapterConfig:(nonnull ISAdapterConfig *)adapterConfig
                              delegate:(nonnull id <ISBannerAdapterDelegate>)delegate {
    LogInternal_Warning(@"Unsupported method");
}

- (void) destroyBannerWithAdapterConfig:(nonnull ISAdapterConfig *)adapterConfig {
    NSString *placementId = adapterConfig.settings[kPlacementId];
    
    // Get banner
    UADSBannerView *bannerView = [_bannerPlacementIdToAd objectForKey:placementId];
    
    // Remove delegate
    if (bannerView) {
        bannerView.delegate = nil;
    }
    
    // Remove from ad dictionary and set null
    [_bannerPlacementIdToAd removeObjectForKey:placementId];
    bannerView = nil;
}


//network does not support banner reload
//return true if banner view needs to be bound again on reload
- (BOOL) shouldBindBannerViewOnReload {
    return YES;
}


#pragma mark - Banner Delegate

- (void) onBannerLoadSuccess:(UADSBannerView * _Nonnull)bannerView {
    LogAdapterDelegate_Internal(@"placementId = %@", bannerView.placementId);
    id<ISBannerAdapterDelegate> delegate = [_bannerPlacementIdToSmashDelegate objectForKey:bannerView.placementId];
    
    if (delegate) {
        [delegate adapterBannerDidLoad:bannerView];
        [delegate adapterBannerDidShow];
    }
}

- (void) onBannerLoadFail:(UADSBannerView * _Nonnull)bannerView
                withError:(UADSBannerError * _Nullable)error {
    LogAdapterDelegate_Internal(@"placementId = %@ reason - %@", bannerView.placementId, error);
    id<ISBannerAdapterDelegate> delegate = [_bannerPlacementIdToSmashDelegate objectForKey:bannerView.placementId];
    
    if (delegate) {
        NSInteger errorCode = (error.code == UADSBannerErrorCodeNoFillError)? ERROR_BN_LOAD_NO_FILL : error.code;
        NSError *smashError = [NSError errorWithDomain:kAdapterName code:errorCode userInfo:@{NSLocalizedDescriptionKey:error.description}];
        [delegate adapterBannerDidFailToLoadWithError:smashError];
    }
}

- (void) onBannerDidClick:(UADSBannerView * _Nonnull)bannerView {
    LogAdapterDelegate_Internal(@"placementId = %@", bannerView.placementId);
    id<ISBannerAdapterDelegate> delegate = [_bannerPlacementIdToSmashDelegate objectForKey:bannerView.placementId];
    
    if (delegate) {
        [delegate adapterBannerDidClick];
    }
}

- (void) onBannerWillLeaveApplication:(UADSBannerView * _Nonnull)bannerView {
    LogAdapterDelegate_Internal(@"placementId = %@", bannerView.placementId);
    id<ISBannerAdapterDelegate> delegate = [_bannerPlacementIdToSmashDelegate objectForKey:bannerView.placementId];
    
    if (delegate) {
        [delegate adapterBannerWillLeaveApplication];
    }
}

#pragma mark - Memory Handling

- (void)releaseMemoryWithAdapterConfig:(nonnull ISAdapterConfig *)adapterConfig {
    NSString *placementId = adapterConfig.settings[kPlacementId];
    UADSBannerView *bannerAd= [_bannerPlacementIdToAd objectForKey:placementId];
    
    if (bannerAd) {
        [self destroyBannerWithAdapterConfig:adapterConfig];
    }
} 

#pragma mark - Legal Methods

- (void) setMetaDataWithKey:(NSString *)key
                  andValues:(NSMutableArray *)values {
    if (values.count == 0) {
        return;
    }
    
    // this is a list of 1 value
    NSString *value = values[0];
    LogAdapterApi_Internal(@"setMetaData: key=%@, value=%@", key, value);
    
    if ([ISMetaDataUtils isValidCCPAMetaDataWithKey:key andValue:value]) {
        [self setCCPAValue:[ISMetaDataUtils getCCPABooleanValue:value]];
    } else {
        NSString *formattedValue = [ISMetaDataUtils formatValue:value forType:(META_DATA_VALUE_BOOL)];
        
        if ([self isValidCOPPAMetaDataWithKey:key andValue:formattedValue]) {
            [self setCOPPAValue:[ISMetaDataUtils getCCPABooleanValue:formattedValue]];
        }
    }
}

- (void) setCCPAValue:(BOOL)value {
    // The UnityAds CCPA API expects an indication if the user opts in to targeted advertising.
    // Given that this is opposite to the ironSource Mediation CCPA flag of do_not_sell
    // we will use the opposite value of what is passed to this method
    BOOL optIn = !value;
    [self setUnityAdsMetaDataWithKey:kCCPAUnityAdsFlag value:optIn];
}


- (void) setConsent:(BOOL)consent {
    [self setUnityAdsMetaDataWithKey:kGDPRUnityAdsFlag value:consent];
}

- (void) setCOPPAValue:(BOOL)value {
    [self setUnityAdsMetaDataWithKey:kCOPPAUnityAdsFlag value:value];
}

- (BOOL) isValidCOPPAMetaDataWithKey:(NSString *)key
                            andValue:(NSString *)value {
    return ([key caseInsensitiveCompare:kMetaDataCOPPAKey] == NSOrderedSame && (value.length));
}

- (void) setUnityAdsMetaDataWithKey:(NSString *)key
                              value:(BOOL)value {
    LogAdapterApi_Internal(@"key = %@, value = %@", key, value? @"YES" : @"NO");
    
    @synchronized (_UnityAdsStorageLock) {
        UADSMetaData *unityAdsMetaData = [[UADSMetaData alloc] init];
        [unityAdsMetaData set:key value:value ? @YES : @NO];
        [unityAdsMetaData commit];
    }
}

#pragma mark - Private Methods

// in case this method is called before the init we will try using the token that was received asynchronically
- (NSDictionary *) getBiddingData {
    NSString *bidderToken = nil;

    if (_initState == INIT_STATE_SUCCESS) {
        bidderToken = [UnityAds getToken];
    } else if (asyncToken.length) {
        bidderToken = asyncToken;
    } else {
        LogAdapterApi_Internal(@"returning nil as token since init did not finish successfully");
        return nil;
    }
    
    NSString *returnedToken = bidderToken? bidderToken : @"";
    LogAdapterApi_Internal(@"token = %@", returnedToken);
    
    return @{@"token": returnedToken};
}

-(void) getAsyncToken:(ISAdapterConfig *)adapterConfig {
    if (adapterConfig != nil && [adapterConfig.settings objectForKey:kIsAsyncTokenEnabled] != nil) {
        BOOL isAsyncTokenEnabled = [[adapterConfig.settings objectForKey:kIsAsyncTokenEnabled] boolValue];
        
        if (isAsyncTokenEnabled) {
            LogInternal_Internal(@"Trying to get UnityAds async token");
            [UnityAds getToken:^(NSString * _Nullable token) {
                if (token.length) {
                    LogInternal_Internal(@"async token returned");
                    asyncToken = token;
                }
            }];
        }
    }
}


- (BOOL) isBannerSizeSupported:(ISBannerSize *)size {
    if ([size.sizeDescription isEqualToString:@"BANNER"] ||
        [size.sizeDescription isEqualToString:@"LARGE"] ||
        [size.sizeDescription isEqualToString:@"SMART"]) {
        return YES;
    }
    
    return NO;
}

- (CGSize) getBannerSize:(ISBannerSize *)size {
    if ([size.sizeDescription isEqualToString:@"BANNER"] ||
        [size.sizeDescription isEqualToString:@"LARGE"]) {
        return CGSizeMake(320, 50);
    }
    else if ([size.sizeDescription isEqualToString:@"SMART"]) {
        if (UI_USER_INTERFACE_IDIOM() == UIUserInterfaceIdiomPad) {
            return CGSizeMake(728, 90);
        }
        else {
            return CGSizeMake(320, 50);
        }
    }
    
    return CGSizeZero;
}

- (NSString *) unityAdsInitErrorToString:(UnityAdsInitializationError)error {
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
            result = @"UNKOWN_ERROR";
    }
    
    return result;
}

- (NSString *) unityAdsLoadErrorToString:(UnityAdsLoadError)error {
    NSString *result = nil;
    
    switch (error) {
        case kUnityAdsLoadErrorInitializeFailed:
            result = @"SDK_NOT_INITIALIZED";
            break;
        case kUnityAdsLoadErrorInternal:
            result = @"INTERNAL_ERROR";
            break;
        case kUnityAdsLoadErrorInvalidArgument:
            result = @"INVALID_ARGUMENT";
            break;
        case kUnityAdsLoadErrorNoFill:
            result = @"NO_FILL";
            break;
        case kUnityAdsLoadErrorTimeout:
            result = @"LOAD_TIMEOUT";
            break;
        default:
            result = @"UNKOWN_ERROR";
    }
    
    return result;
}

- (NSString *) unityAdsShowErrorToString:(UnityAdsShowError)error {
    NSString *result = nil;
    
    switch (error) {
        case kUnityShowErrorNotInitialized:
            result = @"SDK_NOT_INITIALIZED";
            break;
        case kUnityShowErrorNotReady:
            result = @"PLACEMENT_NOT_READY";
            break;
        case kUnityShowErrorVideoPlayerError:
            result = @"VIDEO_PLAYER_ERROR";
            break;
        case kUnityShowErrorInvalidArgument:
            result = @"INVALID_ARGUMENT";
            break;
        case kUnityShowErrorNoConnection:
            result = @"NO_INTERNET_CONNECTION";
            break;
        case kUnityShowErrorAlreadyShowing:
            result = @"AD_IS_ALREADY_BEIGN_SHOWED";
            break;
        case kUnityShowErrorInternalError:
            result = @"NO_INTERNET_CONNECTION";
            break;
        case kUnityShowErrorTimeout:
            result = @"AD_EXPIRED";
            break;
        default:
            result = @"UNKOWN_ERROR";
    }
    
    return result;
}

// The network's capability to load a Rewarded Video ad while another Rewarded Video ad of that network is showing
- (ISLoadWhileShowSupportState) getLWSSupportState:(ISAdapterConfig *)adapterConfig {
    ISLoadWhileShowSupportState state = LWSState;
    
    if (adapterConfig != nil && [adapterConfig.settings objectForKey:kIsLWSSupported] != nil) {
        BOOL isLWSSupported = [[adapterConfig.settings objectForKey:kIsLWSSupported] boolValue];
        
        if (isLWSSupported) {
            state =  LOAD_WHILE_SHOW_BY_INSTANCE;
        }
    }
    
    return state;
}


@end
