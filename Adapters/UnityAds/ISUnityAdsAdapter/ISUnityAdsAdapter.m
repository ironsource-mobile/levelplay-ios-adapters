//
//  ISUnityAdsAdapter.m
//  ISUnityAdsAdapter
//
//  Copyright © 2024 ironSource Mobile Ltd. All rights reserved.
//

#import <ISUnityAdsAdapter.h>
#import <ISUnityAdsRewardedVideoDelegate.h>
#import <ISUnityAdsInterstitialDelegate.h>
#import <ISUnityAdsBannerDelegate.h>
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
static ISConcurrentMutableSet<ISNetworkInitCallbackProtocol> *initCallbackDelegates = nil;

// UnityAds asynchronous token
static NSString *asyncToken = nil;

// Feature flag key to disable the network's capability to load a Rewarded Video ad while another Rewarded Video ad of that network is showing
static NSString * const kIsLWSSupported         = @"isSupportedLWS";
static NSString * const kAdsGatewayFlag         = @"adsGatewayV2";



@interface ISUnityAdsAdapter () <UnityAdsInitializationDelegate,
                                ISNetworkInitCallbackProtocol,
                                ISUnityAdsBannerDelegateWrapper,
                                ISUnityAdsInterstitialDelegateWrapper,
                                ISUnityAdsRewardedVideoDelegateWrapper>

// Rewrded video
@property (nonatomic, strong) ISConcurrentMutableDictionary *rewardedVideoPlacementIdToSmashDelegate;
@property (nonatomic, strong) ISConcurrentMutableDictionary *rewardedVideoPlacementIdToObjectId;
@property (nonatomic, strong) ISConcurrentMutableDictionary *rewardedVideoPlacementIdToDelegate;
@property (nonatomic, strong) ISConcurrentMutableDictionary *rewardedVideoAdsAvailability;
@property (nonatomic, strong) ISConcurrentMutableSet        *rewardedVideoPlacementIdsForInitCallbacks;

// Interstitial
@property (nonatomic, strong) ISConcurrentMutableDictionary *interstitialPlacementIdToSmashDelegate;
@property (nonatomic, strong) ISConcurrentMutableDictionary *interstitialPlacementIdToObjectId;
@property (nonatomic, strong) ISConcurrentMutableDictionary *interstitialPlacementIdToDelegate;
@property (nonatomic, strong) ISConcurrentMutableDictionary *interstitialAdsAvailability;

// Banner
@property (nonatomic, strong) ISConcurrentMutableDictionary *bannerPlacementIdToSmashDelegate;
@property (nonatomic, strong) ISConcurrentMutableDictionary *bannerPlacementIdToDelegate;
@property (nonatomic, strong) ISConcurrentMutableDictionary *bannerPlacementIdToAd;

// synchronization lock
@property (nonatomic, strong) NSObject                      *unityAdsStorageLock;

@property (nonatomic, assign) BOOL                          isAdsGatewayEnabled;

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
        _rewardedVideoPlacementIdToObjectId = [ISConcurrentMutableDictionary dictionary];
        _rewardedVideoPlacementIdToDelegate = [ISConcurrentMutableDictionary dictionary];
        _rewardedVideoAdsAvailability = [ISConcurrentMutableDictionary dictionary];
        _rewardedVideoPlacementIdsForInitCallbacks = [ISConcurrentMutableSet set];
        
        // Interstitial
        _interstitialPlacementIdToSmashDelegate = [ISConcurrentMutableDictionary dictionary];
        _interstitialPlacementIdToObjectId = [ISConcurrentMutableDictionary dictionary];
        _interstitialPlacementIdToDelegate = [ISConcurrentMutableDictionary dictionary];
        _interstitialAdsAvailability = [ISConcurrentMutableDictionary dictionary];
        
        // Banner
        _bannerPlacementIdToSmashDelegate = [ISConcurrentMutableDictionary dictionary];
        _bannerPlacementIdToDelegate = [ISConcurrentMutableDictionary dictionary];
        _bannerPlacementIdToAd = [ISConcurrentMutableDictionary dictionary];
        
        _unityAdsStorageLock = [NSObject new];
    }
    
    return self;
}

- (void)initSDKWithGameId:(NSString *)gameId
            adapterConfig:(ISAdapterConfig *)adapterConfig  {

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

            @synchronized (self.unityAdsStorageLock) {
                UADSMediationMetaData *mediationMetaData = [[UADSMediationMetaData alloc] init];
                [mediationMetaData setName:kMediationName];
                [mediationMetaData setVersion:[IronSource sdkVersion]];
                [mediationMetaData set:kAdapterVersionKey
                                 value:kAdapterVersion];
                [mediationMetaData commit];
                
                NSNumber* adsGatewayFlag = [self getAdsGatewayFlag:adapterConfig];
                UADSMetaData *metaData = [[UADSMetaData alloc] init];
                [metaData setRaw:kAdsGatewayFlag value: adsGatewayFlag];
                [metaData commit];
                
                self.isAdsGatewayEnabled = adsGatewayFlag.boolValue;
            }

            [UnityAds setDebugMode:[ISConfigurations getConfigurations].adaptersDebug];
            LogAdapterApi_Internal(@"setDebugMode = %d", [ISConfigurations getConfigurations].adaptersDebug);

            [UnityAds initialize:gameId
                        testMode:NO
          initializationDelegate:self];
            
            if (!self.isAdsGatewayEnabled) {
                // Trying to fetch async token for the first load
                [self getAsyncToken];
            }
        });
        
    });
}

- (void)initializationComplete {
    LogAdapterDelegate_Internal(@"UnityAds init success");
    
    _initState = INIT_STATE_SUCCESS;
    
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
    
    LogAdapterDelegate_Internal(@"error - %@", errorMsg);

    _initState = INIT_STATE_FAILED;
    
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
        if ([_rewardedVideoPlacementIdsForInitCallbacks hasObject:placementId]) {
            [delegate adapterRewardedVideoInitSuccess];
        } else {
            [self loadRewardedVideoInternal:placementId
                                 serverData:nil
                                   delegate:delegate];
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
    
    NSError *error = [ISError createErrorWithDomain:kAdapterName
                                               code:ERROR_CODE_INIT_FAILED
                                            message:errorMessage];
    
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
    
    // Register rewarded video to init callback
    [_rewardedVideoPlacementIdsForInitCallbacks addObject:placementId];
    
    switch (_initState) {
        case INIT_STATE_NONE:
        case INIT_STATE_IN_PROGRESS:
            [self initSDKWithGameId:gameId
                      adapterConfig:adapterConfig];
            break;
        case INIT_STATE_FAILED:
            [delegate adapterRewardedVideoInitFailed:[NSError errorWithDomain:kAdapterName
                                                                         code:ERROR_CODE_INIT_FAILED
                                                                     userInfo:@{NSLocalizedDescriptionKey:@"UnityAds SDK init failed"}]];
            break;
        case INIT_STATE_SUCCESS:
            [delegate adapterRewardedVideoInitSuccess];
            break;
    }
}

// used for flows when the mediation doesn't need to get a callback for init
- (void)initAndLoadRewardedVideoWithUserId:(NSString *)userId
                             adapterConfig:(ISAdapterConfig *)adapterConfig
                                    adData:(NSDictionary *)adData
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
    [_rewardedVideoPlacementIdToSmashDelegate setObject:delegate
                                                 forKey:placementId];
    
    switch (_initState) {
        case INIT_STATE_NONE:
        case INIT_STATE_IN_PROGRESS:
            [self initSDKWithGameId:gameId
                      adapterConfig:adapterConfig];
            break;
        case INIT_STATE_FAILED:
            [delegate adapterRewardedVideoHasChangedAvailability:NO];
            break;
        case INIT_STATE_SUCCESS:
            [self loadRewardedVideoInternal:placementId
                                 serverData:nil
                                   delegate:delegate];
            break;
    }
}

- (void)loadRewardedVideoForBiddingWithAdapterConfig:(ISAdapterConfig *)adapterConfig
                                              adData:(NSDictionary *)adData
                                          serverData:(NSString *)serverData
                                            delegate:(id<ISRewardedVideoAdapterDelegate>)delegate {
    NSString *placementId = adapterConfig.settings[kPlacementId];
    LogAdapterApi_Internal(@"placementId = %@", placementId);
    
    [self loadRewardedVideoInternal:placementId
                         serverData:serverData
                           delegate:delegate];
}

- (void)loadRewardedVideoWithAdapterConfig:(ISAdapterConfig *)adapterConfig
                                    adData:(NSDictionary *)adData
                                  delegate:(id<ISRewardedVideoAdapterDelegate>)delegate {
    NSString *placementId = adapterConfig.settings[kPlacementId];
    LogAdapterApi_Internal(@"placementId = %@", placementId);
    
    [self loadRewardedVideoInternal:placementId
                         serverData:nil
                           delegate:delegate];
}

- (void)loadRewardedVideoInternal:(NSString *)placementId
                       serverData:(NSString *)serverData
                         delegate:(id<ISRewardedVideoAdapterDelegate>)delegate {
    LogAdapterApi_Internal(@"placementId = %@", placementId);
    
    [_rewardedVideoAdsAvailability setObject:@NO
                                      forKey:placementId];
    
    // Register Rewarded Video delegate for placement in order to support OPW flow- the delegate passes as a param through adapter's API
    [_rewardedVideoPlacementIdToSmashDelegate setObject:delegate
                                                 forKey:placementId];
    
    // Create rewarded video delegate
    ISUnityAdsRewardedVideoDelegate *rewardedVideoAdDelegate = [[ISUnityAdsRewardedVideoDelegate alloc]
                                                                initWithPlacementId:placementId
                                                                           delegate:self];
    [_rewardedVideoPlacementIdToDelegate setObject:rewardedVideoAdDelegate
                                            forKey:placementId];
    
    UADSLoadOptions *options = [UADSLoadOptions new];
    
    // objectId is used to identify a loaded ad and to show it
    NSString *objectId = [[NSUUID UUID] UUIDString];
    [options setObjectId:objectId];
    
    if (serverData != nil) {
        // add adMarkup for bidder instances
        [options setAdMarkup:serverData];
    }
    
    [_rewardedVideoPlacementIdToObjectId setObject:objectId
                                            forKey:placementId];
    
    [UnityAds load:placementId
           options:options
      loadDelegate:rewardedVideoAdDelegate];
}

- (void)showRewardedVideoWithViewController:(UIViewController *)viewController
                              adapterConfig:(ISAdapterConfig *)adapterConfig
                                   delegate:(id<ISRewardedVideoAdapterDelegate>)delegate {
    NSString *placementId = adapterConfig.settings[kPlacementId];
    LogAdapterApi_Internal(@"placementId = %@", placementId);
    
    if (![self hasRewardedVideoWithAdapterConfig:adapterConfig]) {
        NSError *error = [ISError createError:ERROR_CODE_NO_ADS_TO_SHOW
                                  withMessage:[NSString stringWithFormat: @"%@ show failed", kAdapterName]];
        LogAdapterApi_Internal(@"error = %@", error);
        [delegate adapterRewardedVideoDidFailToShowWithError:error];
        return;
    }
    
    dispatch_async(dispatch_get_main_queue(), ^{
        @try {
            if ([self dynamicUserId]) {
                @synchronized (self.unityAdsStorageLock) {
                    id playerMetaData = [[UADSPlayerMetaData alloc] init];
                    [playerMetaData setServerId:[self dynamicUserId]];
                    [playerMetaData commit];
                }
            }
            
            UIViewController *vc = viewController == nil ? [self topMostController] : viewController;
            id<UnityAdsShowDelegate>showDelegate = [self.rewardedVideoPlacementIdToDelegate objectForKey:placementId];;
            
            UADSShowOptions *options = [UADSShowOptions new];
            
            NSString *objectId = [self.rewardedVideoPlacementIdToObjectId objectForKey:placementId];
            [options setObjectId:objectId];
            
            [UnityAds show:vc
               placementId:placementId
                   options:options
              showDelegate:showDelegate];
            
        } @catch (NSException *exception) {
            NSString *message = [NSString stringWithFormat:@"ISUnityAdsAdapter: Exception while trying to show a rewarded video ad. Description: '%@'", exception.description];
            LogAdapterApi_Internal(@"message = %@", message);
            NSError *showError = [NSError errorWithDomain:kAdapterName
                                                     code:ERROR_CODE_NO_ADS_TO_SHOW
                                                 userInfo:@{NSLocalizedDescriptionKey:message}];
            [delegate adapterRewardedVideoDidFailToShowWithError:showError];
        }
        
        [self.rewardedVideoAdsAvailability setObject:@NO
                                              forKey:placementId];
    });
}

- (BOOL)hasRewardedVideoWithAdapterConfig:(ISAdapterConfig *)adapterConfig {
    NSString *placementId = adapterConfig.settings[kPlacementId];
    NSNumber *available = [_rewardedVideoAdsAvailability objectForKey:placementId];
    return (available != nil) && [available boolValue];
}

- (NSDictionary *)getRewardedVideoBiddingDataWithAdapterConfig:(ISAdapterConfig *)adapterConfig
                                                        adData:(NSDictionary *)adData {
    return [self getBiddingData];
}

#pragma mark - Rewarded Video Delegate

- (void)onRewardedVideoDidLoad:(NSString * _Nonnull)placementId {
    LogAdapterDelegate_Internal(@"placementId = %@", placementId);
    [_rewardedVideoAdsAvailability setObject:@YES forKey:placementId];
    id<ISRewardedVideoAdapterDelegate> delegate = [_rewardedVideoPlacementIdToSmashDelegate objectForKey:placementId];
    
    [delegate adapterRewardedVideoHasChangedAvailability:YES];
}

- (void)onRewardedVideoDidFailToLoad:(NSString * _Nonnull)placementId
                           withError:(UnityAdsLoadError)error {
    NSString *loadError = [self unityAdsLoadErrorToString:error];
    LogAdapterDelegate_Internal(@"placementId = %@ reason - %@", placementId, loadError);
    [_rewardedVideoAdsAvailability setObject:@NO forKey:placementId];
    id<ISRewardedVideoAdapterDelegate> delegate = [_rewardedVideoPlacementIdToSmashDelegate objectForKey:placementId];
    
    NSInteger errorCode = (error == kUnityAdsLoadErrorNoFill) ? ERROR_RV_LOAD_NO_FILL : error;
    NSError *smashError = [NSError errorWithDomain:kAdapterName
                                              code:errorCode
                                          userInfo:@{NSLocalizedDescriptionKey:loadError}];
    [delegate adapterRewardedVideoHasChangedAvailability:NO];
    [delegate adapterRewardedVideoDidFailToLoadWithError:smashError];
}

- (void)onRewardedVideoDidOpen:(NSString * _Nonnull)placementId {
    LogAdapterDelegate_Internal(@"placementId = %@", placementId);
    id<ISRewardedVideoAdapterDelegate> delegate = [_rewardedVideoPlacementIdToSmashDelegate objectForKey:placementId];
    
    [delegate adapterRewardedVideoDidOpen];
    [delegate adapterRewardedVideoDidStart];
}

- (void)onRewardedVideoShowFail:(NSString * _Nonnull)placementId
                      withError:(UnityAdsShowError)error
                     andMessage:(NSString * _Nonnull)errorMessage {
    NSString *showError = [NSString stringWithFormat:@"%@ - %@", [self unityAdsShowErrorToString:error], errorMessage];
    LogAdapterDelegate_Internal(@"placementId = %@ reason = %@", placementId, showError);
    id<ISRewardedVideoAdapterDelegate> delegate = [_rewardedVideoPlacementIdToSmashDelegate objectForKey:placementId];

    NSError *smashError = [NSError errorWithDomain:kAdapterName
                                              code:error
                                          userInfo:@{NSLocalizedDescriptionKey:showError}];
    [delegate adapterRewardedVideoDidFailToShowWithError:smashError];
}

- (void)onRewardedVideoDidClick:(NSString * _Nonnull)placementId {
    LogAdapterDelegate_Internal(@"placementId = %@", placementId);
    id<ISRewardedVideoAdapterDelegate> delegate = [_rewardedVideoPlacementIdToSmashDelegate objectForKey:placementId];
    
    [delegate adapterRewardedVideoDidClick];
}

- (void)onRewardedVideoDidShowComplete:(NSString * _Nonnull)placementId
                       withFinishState:(UnityAdsShowCompletionState)state {
    LogAdapterDelegate_Internal(@"placementId = %@ and completion state = %d", placementId, (int)state);
    id<ISRewardedVideoAdapterDelegate> delegate = [_rewardedVideoPlacementIdToSmashDelegate objectForKey:placementId];
       
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
    
    switch (_initState) {
        case INIT_STATE_NONE:
        case INIT_STATE_IN_PROGRESS:
            [self initSDKWithGameId:gameId
                      adapterConfig:adapterConfig];
            break;
        case INIT_STATE_FAILED:
            [delegate adapterInterstitialInitFailedWithError:[NSError errorWithDomain:kAdapterName
                                                                                 code:ERROR_CODE_INIT_FAILED
                                                                             userInfo:@{NSLocalizedDescriptionKey:@"UnityAds SDK init failed"}]];
            break;
        case INIT_STATE_SUCCESS:
            [delegate adapterInterstitialInitSuccess];
            break;
    }
}

- (void)loadInterstitialForBiddingWithAdapterConfig:(ISAdapterConfig *)adapterConfig
                                             adData:(NSDictionary *)adData
                                         serverData:(NSString *)serverData
                                           delegate:(id<ISInterstitialAdapterDelegate>)delegate {
    
    NSString *placementId = adapterConfig.settings[kPlacementId];
    LogAdapterApi_Internal(@"placementId = %@", placementId);
    
    [self loadInterstitialInternal:placementId
                     andServerData:serverData
                          delegate:delegate];
}

- (void)loadInterstitialWithAdapterConfig:(ISAdapterConfig *)adapterConfig
                                   adData:(NSDictionary *)adData
                                 delegate:(id<ISInterstitialAdapterDelegate>)delegate {
    NSString *placementId = adapterConfig.settings[kPlacementId];
    LogAdapterApi_Internal(@"placementId = %@", placementId);
    
    [self loadInterstitialInternal:placementId
                     andServerData:nil
                          delegate:delegate];
}

- (void)loadInterstitialInternal:(NSString *)placementId
                   andServerData:(NSString *)serverData
                        delegate:(id<ISInterstitialAdapterDelegate>)delegate {
    LogAdapterApi_Internal(@"placementId = %@", placementId);
    [_interstitialAdsAvailability setObject:@NO
                                     forKey:placementId];
    
    // Register delegate for placement
    [_interstitialPlacementIdToSmashDelegate setObject:delegate
                                                forKey:placementId];
    
    // Create interstitial Delegate
    ISUnityAdsInterstitialDelegate *interstitialAdDelegate = [[ISUnityAdsInterstitialDelegate alloc] initWithPlacementId:placementId
                                                                                                             andDelegate:self];
    [_interstitialPlacementIdToDelegate setObject:interstitialAdDelegate
                                           forKey:placementId];

    UADSLoadOptions *options = [UADSLoadOptions new];

    // objectId is used to identify a loaded ad and to show it
    NSString *objectId = [[NSUUID UUID] UUIDString];
    [options setObjectId:objectId];
    
    if (serverData != nil) {
        // add adMarkup for bidder instances
        [options setAdMarkup:serverData];
    }
    
    [_interstitialPlacementIdToObjectId setObject:objectId
                                           forKey:placementId];
    
    [UnityAds load:placementId
           options:options
      loadDelegate:interstitialAdDelegate];
}

- (void)showInterstitialWithViewController:(UIViewController *)viewController
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
                @synchronized (self.unityAdsStorageLock) {
                    id playerMetaData = [[UADSPlayerMetaData alloc] init];
                    [playerMetaData setServerId:[self dynamicUserId]];
                    [playerMetaData commit];
                }
            }
            
            UIViewController *vc = viewController == nil ? [self topMostController] : viewController;
            id<UnityAdsShowDelegate>showDelegate = [self.interstitialPlacementIdToDelegate objectForKey:placementId];;
            
            UADSShowOptions *options = [UADSShowOptions new];
            
            NSString *objectId = [self.interstitialPlacementIdToObjectId objectForKey:placementId];
            [options setObjectId:objectId];
           
            [UnityAds show:vc
               placementId:placementId
                   options:options
              showDelegate:showDelegate];
        
        }
        @catch (NSException *exception) {
            NSString *message = [NSString stringWithFormat:@"ISUnityAdsAdapter: Exception while trying to show an interstitial ad. Description: '%@'", exception.description];
            LogAdapterApi_Internal(@"message = %@", message);
            NSError *showError = [NSError errorWithDomain:kAdapterName
                                                     code:ERROR_CODE_NO_ADS_TO_SHOW
                                                 userInfo:@{NSLocalizedDescriptionKey:message}];
            [delegate adapterInterstitialDidFailToShowWithError:showError];
        }
        
        [self.interstitialAdsAvailability setObject:@NO
                                             forKey:placementId];
    });
}

- (BOOL)hasInterstitialWithAdapterConfig:(ISAdapterConfig *)adapterConfig {
    NSString *placementId = adapterConfig.settings[kPlacementId];
    NSNumber *available = [_interstitialAdsAvailability objectForKey:placementId];
    return (available != nil) && [available boolValue];
}

- (NSDictionary *)getInterstitialBiddingDataWithAdapterConfig:(ISAdapterConfig *)adapterConfig
                                                       adData:(NSDictionary *)adData {
    return [self getBiddingData];
}

#pragma mark - Interstitial Delegate

- (void)onInterstitialDidLoad:(NSString * _Nonnull)placementId {
    LogAdapterDelegate_Internal(@"placementId = %@", placementId);
    [_interstitialAdsAvailability setObject:@YES forKey:placementId];
    id<ISInterstitialAdapterDelegate> delegate = [_interstitialPlacementIdToSmashDelegate objectForKey:placementId];
    
    [delegate adapterInterstitialDidLoad];
}

- (void)onInterstitialDidFailToLoad:(NSString * _Nonnull)placementId
                          withError:(UnityAdsLoadError)error {
    NSString *loadError = [self unityAdsLoadErrorToString:error];
    LogAdapterDelegate_Internal(@"placementId = %@ reason - %@", placementId, loadError);
    [_interstitialAdsAvailability setObject:@NO forKey:placementId];
    id<ISInterstitialAdapterDelegate> delegate = [_interstitialPlacementIdToSmashDelegate objectForKey:placementId];
    
    NSInteger errorCode = (error == kUnityAdsLoadErrorNoFill) ? ERROR_IS_LOAD_NO_FILL : error;
    NSError *smashError = [NSError errorWithDomain:kAdapterName
                                              code:errorCode
                                          userInfo:@{NSLocalizedDescriptionKey:loadError}];
    [delegate adapterInterstitialDidFailToLoadWithError:smashError];
}

- (void)onInterstitialDidOpen:(NSString * _Nonnull)placementId {
    LogAdapterDelegate_Internal(@"placementId = %@", placementId);
    id<ISInterstitialAdapterDelegate> delegate = [_interstitialPlacementIdToSmashDelegate objectForKey:placementId];
    
    [delegate adapterInterstitialDidOpen];
    [delegate adapterInterstitialDidShow];
}

- (void)onInterstitialShowFail:(NSString * _Nonnull)placementId
                     withError:(UnityAdsShowError)error
                    andMessage:(NSString * _Nonnull)errorMessage {
    NSString *showError = [NSString stringWithFormat:@"%@ - %@", [self unityAdsShowErrorToString:error], errorMessage];
    LogAdapterDelegate_Internal(@"placementId = %@ reason = %@", placementId, showError);
    id<ISInterstitialAdapterDelegate> delegate = [_interstitialPlacementIdToSmashDelegate objectForKey:placementId];

    NSError *smashError = [NSError errorWithDomain:kAdapterName
                                              code:error
                                          userInfo:@{NSLocalizedDescriptionKey:showError}];
    [delegate adapterInterstitialDidFailToShowWithError:smashError];
}

- (void)onInterstitialDidClick:(NSString * _Nonnull)placementId {
    LogAdapterDelegate_Internal(@"placementId = %@", placementId);
    id<ISInterstitialAdapterDelegate> delegate = [_interstitialPlacementIdToSmashDelegate objectForKey:placementId];
    
    [delegate adapterInterstitialDidClick];
}

- (void)onInterstitialDidShowComplete:(NSString * _Nonnull)placementId
                      withFinishState:(UnityAdsShowCompletionState)state {
    LogAdapterDelegate_Internal(@"placementId = %@ and completion state = %d", placementId, (int)state);
    id<ISInterstitialAdapterDelegate> delegate = [_interstitialPlacementIdToSmashDelegate objectForKey:placementId];
    
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
    
    switch (_initState) {
        case INIT_STATE_NONE:
        case INIT_STATE_IN_PROGRESS:
            [self initSDKWithGameId:gameId adapterConfig:adapterConfig];
            break;
        case INIT_STATE_FAILED:
            [delegate adapterBannerInitFailedWithError:[NSError errorWithDomain:kAdapterName
                                                                           code:ERROR_CODE_INIT_FAILED
                                                                       userInfo:@{NSLocalizedDescriptionKey:@"UnityAds SDK init failed"}]];
            break;
        case INIT_STATE_SUCCESS:
            [delegate adapterBannerInitSuccess];
            break;
    }
}

- (void)loadBannerForBiddingWithAdapterConfig:(ISAdapterConfig *)adapterConfig
                                       adData:(NSDictionary *)adData
                                   serverData:(NSString *)serverData
                               viewController:(UIViewController *)viewController
                                         size:(ISBannerSize *)size
                                     delegate:(id <ISBannerAdapterDelegate>)delegate {
    
    [self loadBannerInternalWithAdapterConfig:adapterConfig
                                     delegate:delegate
                                         size:size
                                   serverData:serverData];
}

- (void)loadBannerWithAdapterConfig:(ISAdapterConfig *)adapterConfig
                             adData:(NSDictionary *)adData
                     viewController:(UIViewController *)viewController
                               size:(ISBannerSize *)size
                           delegate:(id <ISBannerAdapterDelegate>)delegate {
    
    [self loadBannerInternalWithAdapterConfig:adapterConfig
                                     delegate:delegate
                                         size:size
                                   serverData:nil];
}

- (void)loadBannerInternalWithAdapterConfig:(ISAdapterConfig *)adapterConfig
                                   delegate:(id<ISBannerAdapterDelegate>)delegate
                                       size:(ISBannerSize *)size
                                 serverData:(NSString *)serverData {
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

    dispatch_async(dispatch_get_main_queue(), ^{
        @try {
            // Create banner
            UADSBannerView *bannerView = [[UADSBannerView alloc] initWithPlacementId:placementId
                                                                                size:[self getBannerSize:size]];
            
            // Add to ad dictionary
            [self.bannerPlacementIdToAd setObject:bannerView
                                           forKey:placementId];
            
            // Create banner Delegate
            ISUnityAdsBannerDelegate *bannerAdDelegate = [[ISUnityAdsBannerDelegate alloc] initWithDelegate:self];
            [self.bannerPlacementIdToDelegate setObject:bannerAdDelegate
                                                 forKey:placementId];
            
            // Set delegate
            bannerView.delegate = bannerAdDelegate;
            
            UADSLoadOptions *options = [UADSLoadOptions new];

            // objectId is used to identify a loaded ad and to show it
            NSString *objectId = [[NSUUID UUID] UUIDString];
            [options setObjectId:objectId];
            
            if (serverData != nil) {
                // add adMarkup for bidder instances
                [options setAdMarkup:serverData];
            }
            
            // Load banner
            [bannerView loadWithOptions:options];
            
        } @catch (NSException *exception) {
            NSString *message = [NSString stringWithFormat:@"ISUnityAdsAdapter: Exception while trying to load a banner ad. Description: '%@'", exception.description];
            LogAdapterApi_Internal(@"message = %@", message);
            id<ISBannerAdapterDelegate> delegate = [self.bannerPlacementIdToSmashDelegate objectForKey:placementId];
            NSError *smashError = [NSError errorWithDomain:kAdapterName
                                                      code:ERROR_CODE_GENERIC
                                                  userInfo:@{NSLocalizedDescriptionKey:message}];
            [delegate adapterBannerDidFailToLoadWithError:smashError];
        }
    });
}

- (void)destroyBannerWithAdapterConfig:(ISAdapterConfig *)adapterConfig {
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

- (NSDictionary *)getBannerBiddingDataWithAdapterConfig:(ISAdapterConfig *)adapterConfig
                                                 adData:(NSDictionary *)adData {
    return [self getBiddingData];
}

#pragma mark - Banner Delegate

- (void)onBannerDidLoad:(UADSBannerView * _Nonnull)bannerView {
    LogAdapterDelegate_Internal(@"placementId = %@", bannerView.placementId);
    id<ISBannerAdapterDelegate> delegate = [_bannerPlacementIdToSmashDelegate objectForKey:bannerView.placementId];
    
    [delegate adapterBannerDidLoad:bannerView];
}

- (void)onBannerDidShow:(UADSBannerView * _Nonnull)bannerView {
    LogAdapterDelegate_Internal(@"placementId = %@", bannerView.placementId);
    id<ISBannerAdapterDelegate> delegate = [_bannerPlacementIdToSmashDelegate objectForKey:bannerView.placementId];
    [delegate adapterBannerDidShow];
}

- (void)onBannerDidFailToLoad:(UADSBannerView * _Nonnull)bannerView
                    withError:(UADSBannerError * _Nullable)error {
    LogAdapterDelegate_Internal(@"placementId = %@ reason - %@", bannerView.placementId, error);
    id<ISBannerAdapterDelegate> delegate = [_bannerPlacementIdToSmashDelegate objectForKey:bannerView.placementId];
    
    NSInteger errorCode = (error.code == UADSBannerErrorCodeNoFillError)? ERROR_BN_LOAD_NO_FILL : error.code;
    NSError *smashError = [NSError errorWithDomain:kAdapterName
                                              code:errorCode
                                          userInfo:@{NSLocalizedDescriptionKey:error.description}];
    [delegate adapterBannerDidFailToLoadWithError:smashError];
}

- (void)onBannerDidClick:(UADSBannerView * _Nonnull)bannerView {
    LogAdapterDelegate_Internal(@"placementId = %@", bannerView.placementId);
    id<ISBannerAdapterDelegate> delegate = [_bannerPlacementIdToSmashDelegate objectForKey:bannerView.placementId];
    
    [delegate adapterBannerDidClick];
}

- (void)onBannerWillLeaveApplication:(UADSBannerView * _Nonnull)bannerView {
    LogAdapterDelegate_Internal(@"placementId = %@", bannerView.placementId);
    id<ISBannerAdapterDelegate> delegate = [_bannerPlacementIdToSmashDelegate objectForKey:bannerView.placementId];
    
    [delegate adapterBannerWillLeaveApplication];
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
}

- (void)setConsent:(BOOL)consent {
    [self setUnityAdsMetaDataWithKey:kGDPRUnityAdsFlag
                               value:consent];
}

- (void)setCOPPAValue:(BOOL)value {
    [self setUnityAdsMetaDataWithKey:kCOPPAUnityAdsFlag
                               value:value];
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

// in case this method is called before the init we will try using the token that was received asynchronically
- (NSDictionary *)getBiddingData {
    NSString *bidderToken = nil;

    if (self.isAdsGatewayEnabled) {
        bidderToken = [UnityAds getToken];
    } else {
           if (_initState == INIT_STATE_SUCCESS) {
               bidderToken = [UnityAds getToken];
           } else if (asyncToken.length) {
               bidderToken = asyncToken;
               // Fetching a fresh async token for the next load
               [self getAsyncToken];
           } else {
               LogAdapterApi_Internal(@"returning nil as token since init did not finish successfully and async token did not return");
               return nil;
           }
       }
    
    NSString *returnedToken = bidderToken? bidderToken : @"";
    LogAdapterApi_Internal(@"token = %@", returnedToken);
    
    return @{@"token": returnedToken};
}

- (void)getAsyncToken {
    LogInternal_Internal(@"");
    [UnityAds getToken:^(NSString * _Nullable token) {
        if (token.length) {
            LogInternal_Internal(@"async token returned");
            asyncToken = token;
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
            result = @"UNKOWN_ERROR";
    }
    
    return result;
}

- (NSString *)unityAdsLoadErrorToString:(UnityAdsLoadError)error {
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

- (NSString *)unityAdsShowErrorToString:(UnityAdsShowError)error {
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

- (NSNumber *)getAdsGatewayFlag:(ISAdapterConfig *)adapterConfig {
    BOOL adsGatewayFlag = false;
    if (adapterConfig != nil && [adapterConfig.settings objectForKey:kAdsGatewayFlag] != nil) {
        adsGatewayFlag = [[adapterConfig.settings objectForKey:kAdsGatewayFlag] boolValue];
    }
    return [NSNumber numberWithBool: adsGatewayFlag];
}

@end
