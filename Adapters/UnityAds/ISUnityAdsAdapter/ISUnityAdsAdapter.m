//
//  ISUnityAdsAdapter.m
//  ISUnityAdsAdapter
//
//  Copyright © 2021-2025 Unity Technologies. All rights reserved.
//

#import <ISUnityAdsAdapter.h>
#import <ISUnityAdsRewardedVideoDelegate.h>
#import <ISUnityAdsInterstitialDelegate.h>
#import <ISUnityAdsBannerDelegate.h>
#import <ISUADSRewardedShowDelegate.h>
#import <ISUADSInterstitialShowDelegate.h>
#import <ISUADSBannerAdDelegate.h>
#import <UnityAds/UnityAds.h>

// UnityAds Mediation MetaData
static NSString * const kMediationName          = @"ironSource";
static NSString * const kAdapterVersionKey      = @"adapter_version";
static NSString * const kUnityAdsInitBlobKey    = @"uads_init_blob";
static NSString * const kUnityAdsEpTraitsKey    = @"traits";
static NSString * const kUnityAdsNewApiEnabled  = @"newApiEnabled";

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

// Feature flag key to disable the network's capability to load a Rewarded Video ad while another Rewarded Video ad of that network is showing
static NSString * const kIsLWSSupported         = @"isSupportedLWS";

static int const kUnityAdsNoFillError           = 52100;

@interface ISUnityAdsAdapter () <UnityAdsInitializationDelegate,
                                ISNetworkInitCallbackProtocol,
                                ISUnityAdsBannerDelegateWrapper,
                                ISUnityAdsInterstitialDelegateWrapper,
                                ISUnityAdsRewardedVideoDelegateWrapper>

// Rewarded video
@property (nonatomic, strong) ISConcurrentMutableDictionary *rewardedVideoPlacementIdToSmashDelegate;
@property (nonatomic, strong) ISConcurrentMutableDictionary *rewardedVideoPlacementIdToObjectId;
@property (nonatomic, strong) ISConcurrentMutableDictionary *rewardedVideoPlacementIdToDelegate;
@property (nonatomic, strong) ISConcurrentMutableDictionary *rewardedVideoAdsAvailability;

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


// New API
@property (nonatomic, assign) BOOL isNewAPIEnabled;
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
        _rewardedVideoPlacementIdToObjectId = [ISConcurrentMutableDictionary dictionary];
        _rewardedVideoPlacementIdToDelegate = [ISConcurrentMutableDictionary dictionary];
        _rewardedVideoAdsAvailability = [ISConcurrentMutableDictionary dictionary];
        
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
    
    [self readNewApiEnabled:adapterConfig];
    
    // add self to the init delegates only in case the initialization is not successful
    if (!UnityAds.isInitialized) {
        [initCallbackDelegates addObject:self];
    }
    
    if (self.isNewAPIEnabled) {
        [self newInitializeSDKWithGameId:gameId
                           adapterConfig:adapterConfig];
        return;
    }
    
    dispatch_async(dispatch_get_main_queue(), ^{
        LogAdapterApi_Internal(@"gameId = %@", gameId);
        
        static dispatch_once_t oncePredicate;
        dispatch_once(&oncePredicate, ^{
            @synchronized (self.unityAdsStorageLock) {
                UADSMediationMetaData *mediationMetaData = [[UADSMediationMetaData alloc] init];
                [mediationMetaData setName:kMediationName];
                [mediationMetaData setVersion:[LevelPlay sdkVersion]];
                [mediationMetaData set:kAdapterVersionKey
                                 value:kAdapterVersion];
                [mediationMetaData set:kUnityAdsInitBlobKey
                                 value:adapterConfig.settings[kUnityAdsInitBlobKey]];
                [mediationMetaData set:kUnityAdsEpTraitsKey
                                 value:adapterConfig.settings[kUnityAdsEpTraitsKey]];
                [mediationMetaData commit];
            }
        });
        
        [UnityAds setDebugMode:[ISConfigurations getConfigurations].adaptersDebug];
        LogAdapterApi_Internal(@"setDebugMode = %d", [ISConfigurations getConfigurations].adaptersDebug);
        
        [UnityAds initialize:gameId
                    testMode:NO
      initializationDelegate:self];
    });
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
    [self readNewApiEnabled:adapterConfig];
    
    NSString *placementId = adapterConfig.settings[kPlacementId];
    LogAdapterApi_Internal(@"placementId = %@", placementId);

    [_rewardedVideoAdsAvailability setObject:@NO
                                      forKey:placementId];
    
    // Register Rewarded Video delegate for placement in order to support OPW flow- the delegate passes as a param through adapter's API
    [_rewardedVideoPlacementIdToSmashDelegate setObject:delegate
                                                 forKey:placementId];
    
    if (self.isNewAPIEnabled) {
        [self newLoadRewardedVideoWithAdapterConfig:adapterConfig adData:adData serverData:serverData delegate:delegate];
        return;
    }
    
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
    
    if (self.isNewAPIEnabled) {
        [self newShowRewardedVideoWithViewController:viewController
                                       adapterConfig:adapterConfig
                                            delegate:delegate];
        return;
    }
    
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
    if (self.isNewAPIEnabled) {
        return [self.rewardedPlacementId isEqualToString:placementId] && self.rewardedAd != nil;
    } else {
        NSNumber *available = [_rewardedVideoAdsAvailability objectForKey:placementId];
        return (available != nil) && [available boolValue];
    }
}

- (void)collectRewardedVideoBiddingDataWithAdapterConfig:(ISAdapterConfig *)adapterConfig
                                                  adData:(NSDictionary *)adData
                                                delegate:(id<ISBiddingDataDelegate>)delegate {
    [self readNewApiEnabled:adapterConfig];
    
    if (self.isNewAPIEnabled) {
        [self newGetBiddingDataFor:UADSAdFormatRewarded
                     adapterConfig:adapterConfig
                            adData:adData
                          delegate:delegate];
        return;
    }
    [self getBiddingDataFor:UnityAdsAdFormatRewarded withDelegate: delegate];
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
    [self readNewApiEnabled:adapterConfig];
    
    NSString *placementId = adapterConfig.settings[kPlacementId];
    LogAdapterApi_Internal(@"placementId = %@", placementId);
    [_interstitialAdsAvailability setObject:@NO
                                     forKey:placementId];
    
    // Register delegate for placement
    [_interstitialPlacementIdToSmashDelegate setObject:delegate
                                                forKey:placementId];
    
    if (self.isNewAPIEnabled) {
        [self newLoadInterstitialForBiddingWithAdapterConfig:adapterConfig
                                                      adData:adData
                                                  serverData:serverData
                                                    delegate:delegate];
        return;
    }
    
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
    
    if (self.isNewAPIEnabled) {
        [self newShowInterstitialWithViewController:viewController
                                      adapterConfig:adapterConfig
                                           delegate:delegate];
        return;
    }
    
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
    if (self.isNewAPIEnabled) {
        return [self.interstitialPlacementId isEqualToString:placementId] && self.interstitialAd != nil;
    } else {
        NSNumber *available = [_interstitialAdsAvailability objectForKey:placementId];
        return (available != nil) && [available boolValue];
    }
}

- (void)collectInterstitialBiddingDataWithAdapterConfig:(ISAdapterConfig *)adapterConfig
                                                 adData:(NSDictionary *)adData
                                               delegate:(id<ISBiddingDataDelegate>)delegate {
    [self readNewApiEnabled:adapterConfig];
    
    if (self.isNewAPIEnabled) {
        [self newGetBiddingDataFor:UADSAdFormatInterstitial
                     adapterConfig:adapterConfig
                            adData:adData
                          delegate:delegate];
        return;
    }
    [self getBiddingDataFor:UnityAdsAdFormatInterstitial withDelegate:delegate];
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
    [self readNewApiEnabled:adapterConfig];
    
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
            if (self.isNewAPIEnabled) {
                [self newLoadBannerForBiddingWithAdapterConfig:adapterConfig
                                                        adData:adData
                                                    serverData:serverData
                                                viewController:viewController
                                                          size:size
                                                      delegate:delegate];
                return;
            }
            
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
    if (_isNewAPIEnabled) {
        [self newDestroyBannerWithAdapterConfig:adapterConfig];
        return;
    }
    
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

- (void)collectBannerBiddingDataWithAdapterConfig:(ISAdapterConfig *)adapterConfig
                                           adData:(NSDictionary *)adData
                                         delegate:(id<ISBiddingDataDelegate>)delegate {
    [self readNewApiEnabled:adapterConfig];
    
    if (self.isNewAPIEnabled) {
        [self newGetBiddingDataFor:UADSAdFormatBanner
                     adapterConfig:adapterConfig
                            adData:adData
                          delegate:delegate];
        return;
    }
    [self getBiddingDataFor:UnityAdsAdFormatBanner withDelegate: delegate];
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

- (void)getBiddingDataFor:(UnityAdsAdFormat)format withDelegate:(id<ISBiddingDataDelegate>)delegate {
    UnityAdsTokenConfiguration *config = [UnityAdsTokenConfiguration newWithAdFormat:format];
    [UnityAds getTokenWith:config completion:^(NSString * _Nullable token) {
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
            result = @"UNKNOWN_ERROR";
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
            result = @"AD_IS_ALREADY_BEING_SHOWN";
            break;
        case kUnityShowErrorInternalError:
            result = @"INTERNAL_ERROR";
            break;
        case kUnityShowErrorTimeout:
            result = @"SHOW_TIMEOUT";
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


#pragma mark - New API Init

- (void)readNewApiEnabled:(ISAdapterConfig *)adapterConfig {
    _isNewAPIEnabled = adapterConfig.settings[kUnityAdsEpTraitsKey][kUnityAdsNewApiEnabled];
}

- (void)newInitializeSDKWithGameId:(NSString *)gameId
                     adapterConfig:(ISAdapterConfig *)adapterConfig {
    
    UADSInitializationConfigurationBuilder *builder = [[UADSInitializationConfigurationBuilder alloc] initWithGameId:gameId];
    builder = [builder withTestMode:NO];
    builder = [builder withLogLevel:[ISConfigurations getConfigurations].adaptersDebug ? UADSLogLevelDebug : UADSLogLevelInfo]; // or disabled if false?
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

#pragma mark - New API Rewarded

- (void)newLoadRewardedVideoWithAdapterConfig:(ISAdapterConfig *)adapterConfig
                                       adData:(NSDictionary *)adData
                                   serverData:(NSString *)serverData
                                     delegate:(id<ISRewardedVideoAdapterDelegate>)delegate {
    NSString *placementId = adapterConfig.settings[kPlacementId];
    LogAdapterApi_Internal(@"placementId = %@", placementId);
    
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
            self.rewardedAd = rewardedAd;
            self.rewardedPlacementId = placementId;
            [delegate adapterRewardedVideoHasChangedAvailability:YES];
        } else {
            LogAdapterDelegate_Internal(@"placementId = %@ reason - %ld %@", placementId, error.code, error.message);
            NSInteger errorCode = (error.code == kUnityAdsNoFillError) ? ERROR_RV_LOAD_NO_FILL : error.code;
            NSError *smashError = [NSError errorWithDomain:kAdapterName
                                                      code:errorCode
                                                  userInfo:@{NSLocalizedDescriptionKey:error.message}];
            [delegate adapterRewardedVideoHasChangedAvailability:NO];
            [delegate adapterRewardedVideoDidFailToLoadWithError:smashError];
        }
        
    }];
}

- (void)newShowRewardedVideoWithViewController:(UIViewController *)viewController
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
    
    _rewardedShowDelegate = [[ISUADSRewardedShowDelegate alloc] initWithPlacementId:placementId delegate:delegate];
    [_rewardedAd show:[builder build] delegate:_rewardedShowDelegate];
}

- (void)destroyRewardedVideoAdWithAdapterConfig:(ISAdapterConfig *)adapterConfig {
    NSString *placementId = adapterConfig.settings[kPlacementId];
    
    if ([placementId isEqualToString:self.rewardedPlacementId]) {
        _rewardedAd = nil;
        _rewardedPlacementId = nil;
        _rewardedShowDelegate = nil;
    }
}

#pragma mark - New API Interstitial

- (void)newLoadInterstitialForBiddingWithAdapterConfig:(ISAdapterConfig *)adapterConfig
                                                adData:(NSDictionary *)adData
                                            serverData:(NSString *)serverData
                                              delegate:(id<ISInterstitialAdapterDelegate>)delegate {
    NSString *placementId = adapterConfig.settings[kPlacementId];
    LogAdapterApi_Internal(@"placementId = %@", placementId);
    
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
            self.interstitialAd = interstitialAd;
            self.interstitialPlacementId = placementId;
            [delegate adapterInterstitialDidLoad];
        } else {
            LogAdapterDelegate_Internal(@"placementId = %@ reason - %ld %@", placementId, error.code, error.message);
            NSInteger errorCode = (error.code == kUnityAdsNoFillError) ? ERROR_IS_LOAD_NO_FILL : error.code;
            NSError *smashError = [NSError errorWithDomain:kAdapterName
                                                      code:errorCode
                                                  userInfo:@{NSLocalizedDescriptionKey:error.message}];
            [delegate adapterInterstitialDidFailToLoadWithError:smashError];
        }
    }];
}

- (void)newShowInterstitialWithViewController:(UIViewController *)viewController
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
    
    _interstitialShowDelegate = [[ISUADSInterstitialShowDelegate alloc] initWithPlacementId:placementId delegate:delegate];
    [_interstitialAd show:[builder build] delegate:_interstitialShowDelegate];
}

- (void)destroyInterstitialAdWithAdapterConfig:(ISAdapterConfig *)adapterConfig {
    NSString *placementId = adapterConfig.settings[kPlacementId];
    
    if ([placementId isEqualToString:self.interstitialPlacementId]) {
        _interstitialAd = nil;
        _interstitialPlacementId = nil;
        _interstitialShowDelegate = nil;
    }
}

#pragma mark - New API Banner

- (void)newLoadBannerForBiddingWithAdapterConfig:(ISAdapterConfig *)adapterConfig
                                          adData:(NSDictionary *)adData
                                      serverData:(NSString *)serverData
                                  viewController:(UIViewController *)viewController
                                            size:(ISBannerSize *)size
                                        delegate:(id <ISBannerAdapterDelegate>)delegate {
    NSString *placementId = adapterConfig.settings[kPlacementId];
    LogAdapterApi_Internal(@"placementId = %@", placementId);
 
    _bannerAdDelegate = [[ISUADSBannerAdDelegate alloc] initWithPlacementId:placementId delegate:delegate];
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
            self.bannerAd = bannerAd;
            self.bannerPlacementId = placementId;
            [delegate adapterBannerDidLoad:bannerAd.view];
        } else {
            LogAdapterDelegate_Internal(@"placementId = %@ reason - %ld %@", placementId, error.code, error.message);
            
            NSInteger errorCode = (error.code == kUnityAdsNoFillError)? ERROR_BN_LOAD_NO_FILL : error.code;
            NSError *smashError = [NSError errorWithDomain:kAdapterName
                                                      code:errorCode
                                                  userInfo:@{NSLocalizedDescriptionKey:error.message}];
            [delegate adapterBannerDidFailToLoadWithError:smashError];
        }
    }];
}

- (void)newDestroyBannerWithAdapterConfig:(ISAdapterConfig *)adapterConfig {
    NSString *placementId = adapterConfig.settings[kPlacementId];
    
    if ([placementId isEqualToString:self.bannerPlacementId]) {
        _bannerAd = nil;
        _bannerPlacementId = nil;
        _bannerAdDelegate = nil;
    }
}

#pragma mark - New API GetToken

- (void)newGetBiddingDataFor:(UADSAdFormat)format
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

#pragma mark - New API Helpers

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
