//
//  ISPangleAdapter.m
//  ISPangleAdapter
//
//  Copyright © 2023 ironSource Mobile Ltd. All rights reserved.
//

#import <ISPangleAdapter.h>
#import <ISPangleRewardedVideoDelegate.h>
#import <ISPangleInterstitialDelegate.h>
#import <ISPangleBannerDelegate.h>
#import <PAGAdSDK/PAGAdSDK.h>

// Network keys
static NSString * const kAdapterVersion     = PangleAdapterVersion;
static NSString * const kAdapterName        = @"Pangle";
static NSString * const kAppId              = @"appID";
static NSString * const kSlotId             = @"slotID";

// Meta data flags
static NSString * const kMetaDataCOPPAKey   = @"Pangle_COPPA";
static NSString * const kCOPPAChild         = @"1";
static NSString * const kCOPPAAdult         = @"0";

// Pangle errors
static NSInteger kFPangleNoFillErrorCode    = 20001;

// Init state possible values
typedef NS_ENUM(NSInteger, InitState) {
    INIT_STATE_NONE,
    INIT_STATE_IN_PROGRESS,
    INIT_STATE_SUCCESS,
    INIT_STATE_FAILED,
};

// Handle init callback for all adapter instances
static ISConcurrentMutableSet<ISNetworkInitCallbackProtocol> *initCallbackDelegates = nil;
static InitState _initState = INIT_STATE_NONE;

// Pangle SDK instance
static PAGSdk* _pangleSDK = nil;

@interface ISPangleAdapter () <ISPangleBannerDelegateWrapper, ISPangleInterstitialDelegateWrapper, ISPangleRewardedVideoDelegateWrapper, ISNetworkInitCallbackProtocol>

// Rewarded video
@property (nonatomic, strong) ISConcurrentMutableDictionary   *rewardedVideoSlotIdToSmashDelegate;
@property (nonatomic, strong) ISConcurrentMutableDictionary   *rewardedVideoSlotIdToPangleAdDelegate;
@property (nonatomic, strong) ISConcurrentMutableDictionary   *rewardedVideoSlotIdToAd;
@property (nonatomic, strong) ISConcurrentMutableDictionary   *rewardedVideoAdsAvailability;
@property (nonatomic, strong) ISConcurrentMutableSet          *rewardedVideoSlotIdsForInitCallbacks;

// Interstitial
@property (nonatomic, strong) ISConcurrentMutableDictionary   *interstitialSlotIdToSmashDelegate;
@property (nonatomic, strong) ISConcurrentMutableDictionary   *interstitialSlotIdToPangleAdDelegate;
@property (nonatomic, strong) ISConcurrentMutableDictionary   *interstitialSlotIdToAd;
@property (nonatomic, strong) ISConcurrentMutableDictionary   *interstitialAdsAvailability;

// Banner
@property (nonatomic, strong) ISConcurrentMutableDictionary   *bannerSlotIdToSmashDelegate;
@property (nonatomic, strong) ISConcurrentMutableDictionary   *bannerSlotIdToPangleAdDelegate;
@property (nonatomic, strong) ISConcurrentMutableDictionary   *bannerSlotIdToAd;
@property (nonatomic, strong) ISConcurrentMutableDictionary   *bannerSlotIdToAdSize;
@property (nonatomic, strong) ISConcurrentMutableDictionary   *bannerSlotIdToViewController;

@end

@implementation ISPangleAdapter

#pragma mark - IronSource Protocol Methods

// Get adapter version
- (NSString *)version {
    return kAdapterVersion;
}

// Get network sdk version
- (NSString *)sdkVersion {
    return [PAGSdk SDKVersion];
}

#pragma mark - Initializations Methods And Callbacks

- (instancetype)initAdapter:(NSString *)name {
    self = [super initAdapter:name];
    
    if (self) {
        if (initCallbackDelegates == nil) {
            initCallbackDelegates = [ISConcurrentMutableSet<ISNetworkInitCallbackProtocol> set];
        }
        
        // Rewarded video
        _rewardedVideoSlotIdToSmashDelegate         = [ISConcurrentMutableDictionary dictionary];
        _rewardedVideoSlotIdToPangleAdDelegate      = [ISConcurrentMutableDictionary dictionary];
        _rewardedVideoSlotIdToAd                    = [ISConcurrentMutableDictionary dictionary];
        _rewardedVideoAdsAvailability               = [ISConcurrentMutableDictionary dictionary];
        _rewardedVideoSlotIdsForInitCallbacks       = [ISConcurrentMutableSet set];

        // Interstitial
        _interstitialSlotIdToSmashDelegate          = [ISConcurrentMutableDictionary dictionary];
        _interstitialSlotIdToPangleAdDelegate       = [ISConcurrentMutableDictionary dictionary];
        _interstitialSlotIdToAd                     = [ISConcurrentMutableDictionary dictionary];
        _interstitialAdsAvailability                = [ISConcurrentMutableDictionary dictionary];
        
        // Banner
        _bannerSlotIdToSmashDelegate                = [ISConcurrentMutableDictionary dictionary];
        _bannerSlotIdToPangleAdDelegate             = [ISConcurrentMutableDictionary dictionary];
        _bannerSlotIdToAd                           = [ISConcurrentMutableDictionary dictionary];
        _bannerSlotIdToAdSize                       = [ISConcurrentMutableDictionary dictionary];
        _bannerSlotIdToViewController               = [ISConcurrentMutableDictionary dictionary];
                    
        // The network's capability to load a Rewarded Video ad while another Rewarded Video ad of that network is showing
        LWSState = LOAD_WHILE_SHOW_BY_INSTANCE;
    }
    
    return self;
}

- (void)initSDKWithAppId:(NSString *)appId {
    
    // Add self to the init delegates only in case the initialization has not finished yet
    if (_initState == INIT_STATE_NONE || _initState == INIT_STATE_IN_PROGRESS) {
        [initCallbackDelegates addObject:self];
    }
    
    static dispatch_once_t initSdkOnceToken;
    dispatch_once(&initSdkOnceToken, ^{
        _initState = INIT_STATE_IN_PROGRESS;

        LogAdapterApi_Internal(@"appId = %@", appId);
        
        dispatch_async(dispatch_get_main_queue(), ^{
            
            PAGConfig *config = [PAGConfig shareConfig];
            config.appID = appId;
            config.debugLog = [ISConfigurations getConfigurations].adaptersDebug ? YES : NO;
                
            ISPangleAdapter * __weak weakSelf = self;
            [PAGSdk startWithConfig:config
                  completionHandler:^(BOOL success, NSError *error) {
                if (success) {
                    [weakSelf initializationSuccess];
                } else {
                    NSString *errorMsg = [NSString stringWithFormat:@"Pangle SDK init failed %@", error ? error.description : @""];

                    [weakSelf initializationFailure:errorMsg];
                }
            }];
        });
    });
}

- (void)initializationSuccess {
    LogAdapterDelegate_Internal(@"");
    
    _initState = INIT_STATE_SUCCESS;
    
    NSArray *initDelegatesList = initCallbackDelegates.allObjects;
    
    for (id<ISNetworkInitCallbackProtocol> initDelegate in initDelegatesList) {
        [initDelegate onNetworkInitCallbackSuccess];
    }
    
    [initCallbackDelegates removeAllObjects];
}

- (void)initializationFailure:(NSString *)error {
    LogAdapterDelegate_Internal(@"error = %@", error.description);
    
    _initState = INIT_STATE_FAILED;
    
    NSArray *initDelegatesList = initCallbackDelegates.allObjects;

    for (id<ISNetworkInitCallbackProtocol> delegate in initDelegatesList) {
        [delegate onNetworkInitCallbackFailed:error];
    }
    
    [initCallbackDelegates removeAllObjects];
}

- (void)onNetworkInitCallbackSuccess {
    
    // Rewarded video
    NSArray *rewardedVideoSlotIds = _rewardedVideoSlotIdToSmashDelegate.allKeys;
    
    for (NSString * slotId in rewardedVideoSlotIds) {
        id<ISRewardedVideoAdapterDelegate> delegate = [_rewardedVideoSlotIdToSmashDelegate objectForKey:slotId];
        if ([_rewardedVideoSlotIdsForInitCallbacks hasObject:slotId]) {
            [delegate adapterRewardedVideoInitSuccess];
        } else {
            [self loadRewardedVideoInternal:slotId
                                   delegate:delegate
                                 serverData:nil];
        }
    }

    // Interstitial
    NSArray *interstitialSlotIds = _interstitialSlotIdToSmashDelegate.allKeys;
    
    for (NSString *slotId in interstitialSlotIds) {
        id<ISInterstitialAdapterDelegate> delegate = [_interstitialSlotIdToSmashDelegate objectForKey:slotId];
        [delegate adapterInterstitialInitSuccess];
    }
    
    // Banner
    NSArray *bannerSlotIds = _bannerSlotIdToSmashDelegate.allKeys;
    
    for (NSString *slotId in bannerSlotIds) {
        id<ISBannerAdapterDelegate> delegate = [_bannerSlotIdToSmashDelegate objectForKey:slotId];
        [delegate adapterBannerInitSuccess];
    }
}

- (void)onNetworkInitCallbackFailed:(nonnull NSString *)errorMessage {
    
    NSError *error = [ISError createErrorWithDomain:kAdapterName
                                               code:ERROR_CODE_INIT_FAILED
                                            message:errorMessage];
    
    // Rewarded video
    NSArray *rewardedVideoSlotIds = _rewardedVideoSlotIdToSmashDelegate.allKeys;
    
    for (NSString * slotId in rewardedVideoSlotIds) {
        id<ISRewardedVideoAdapterDelegate> delegate = [_rewardedVideoSlotIdToSmashDelegate objectForKey:slotId];
        if ([_rewardedVideoSlotIdsForInitCallbacks hasObject:slotId]) {
            [delegate adapterRewardedVideoInitFailed:error];
        } else {
            [delegate adapterRewardedVideoHasChangedAvailability:NO];
        }
    }
    
    // Interstitial
    NSArray *interstitialSlotIds = _interstitialSlotIdToSmashDelegate.allKeys;
    
    for (NSString *slotId in interstitialSlotIds) {
        id<ISInterstitialAdapterDelegate> delegate = [_interstitialSlotIdToSmashDelegate objectForKey:slotId];
        [delegate adapterInterstitialInitFailedWithError:error];
    }
    
    // Banner
    NSArray *bannerSlotIds = _bannerSlotIdToSmashDelegate.allKeys;
    
    for (NSString *slotId in bannerSlotIds) {
        id<ISBannerAdapterDelegate> delegate = [_bannerSlotIdToSmashDelegate objectForKey:slotId];
        [delegate adapterBannerInitFailedWithError:error];
    }
}

#pragma mark - Rewarded Video API

// Used for flows when the mediation needs to get a callback for init
- (void)initRewardedVideoForCallbacksWithUserId:(NSString *)userId
                                  adapterConfig:(ISAdapterConfig *)adapterConfig
                                       delegate:(id<ISRewardedVideoAdapterDelegate>)delegate {
    
    NSString *appId = adapterConfig.settings[kAppId];
    NSString *slotId = adapterConfig.settings[kSlotId];

    /* Configuration Validation */
    if (![self isConfigValueValid:appId]) {
        NSError *error = [self errorForMissingCredentialFieldWithName:kAppId];
        LogAdapterApi_Internal(@"error = %@", error.description);
        
        [delegate adapterRewardedVideoInitFailed:error];
        return;
    }
    
    if (![self isConfigValueValid:slotId]) {
        NSError *error = [self errorForMissingCredentialFieldWithName:kSlotId];
        LogAdapterApi_Internal(@"error = %@", error.description);
        
        [delegate adapterRewardedVideoInitFailed:error];
        return;
    }
    
    LogAdapterApi_Internal(@"slotId = %@", slotId);
    
    // Add to rewarded video delegate map
    [_rewardedVideoSlotIdToSmashDelegate setObject:delegate
                                            forKey:slotId];
    
    [_rewardedVideoSlotIdsForInitCallbacks addObject:slotId];
    
    switch (_initState) {
        case INIT_STATE_NONE:
        case INIT_STATE_IN_PROGRESS:
            [self initSDKWithAppId:appId];
            break;
        case INIT_STATE_SUCCESS:
            [delegate adapterRewardedVideoInitSuccess];
            break;
        case INIT_STATE_FAILED: {
            LogAdapterApi_Internal(@"init failed - slotId = %@", slotId);
            NSError *error = [NSError errorWithDomain:kAdapterName
                                                 code:ERROR_CODE_INIT_FAILED
                                             userInfo:@{NSLocalizedDescriptionKey:@"Pangle SDK init failed"}];
            [delegate adapterRewardedVideoInitFailed:error];
            break;
        }
    }
}

// Used for flows when the mediation doesn't need to get a callback for init
- (void)initAndLoadRewardedVideoWithUserId:(NSString *)userId
                             adapterConfig:(ISAdapterConfig *)adapterConfig
                                    adData:(NSDictionary *)adData
                                  delegate:(id<ISRewardedVideoAdapterDelegate>)delegate {
    NSString *appId = adapterConfig.settings[kAppId];
    NSString *slotId = adapterConfig.settings[kSlotId];

    /* Configuration Validation */
    if (![self isConfigValueValid:appId]) {
        NSError *error = [self errorForMissingCredentialFieldWithName:kAppId];
        LogAdapterApi_Internal(@"failed - error.description = %@", error.description);
        [delegate adapterRewardedVideoHasChangedAvailability:NO];
        return;
    }
    
    if (![self isConfigValueValid:slotId]) {
        NSError *error = [self errorForMissingCredentialFieldWithName:kSlotId];
        LogAdapterApi_Internal(@"failed - error.description = %@", error.description);
        [delegate adapterRewardedVideoHasChangedAvailability:NO];
        return;
    }
    
    LogAdapterApi_Internal(@"slotId = %@", slotId);
                                                                  
    // Add to rewarded video delegate map
    [_rewardedVideoSlotIdToSmashDelegate setObject:delegate
                                            forKey:slotId];
    
    switch (_initState) {
        case INIT_STATE_NONE:
        case INIT_STATE_IN_PROGRESS:
            [self initSDKWithAppId:appId];
            break;
        case INIT_STATE_SUCCESS:
            [self loadRewardedVideoInternal:slotId
                                   delegate:delegate
                                 serverData:nil];
            break;
        case INIT_STATE_FAILED:
            LogAdapterApi_Internal(@"init failed - slotId = %@", slotId);
            [delegate adapterRewardedVideoHasChangedAvailability:NO];
            break;
    }
}

- (void)loadRewardedVideoForBiddingWithAdapterConfig:(ISAdapterConfig *)adapterConfig
                                              adData:(NSDictionary *)adData
                                          serverData:(NSString *)serverData
                                            delegate:(id<ISRewardedVideoAdapterDelegate>)delegate {
    NSString *slotId = adapterConfig.settings[kSlotId];
    [self loadRewardedVideoInternal:slotId
                           delegate:delegate
                         serverData:serverData];
}

- (void)loadRewardedVideoWithAdapterConfig:(ISAdapterConfig *)adapterConfig
                                    adData:(NSDictionary *)adData
                                  delegate:(id<ISRewardedVideoAdapterDelegate>)delegate {
    NSString *slotId = adapterConfig.settings[kSlotId];
    [self loadRewardedVideoInternal:slotId
                           delegate:delegate
                         serverData:nil];
}

- (void)loadRewardedVideoInternal:(NSString *)slotId
                         delegate:(id<ISRewardedVideoAdapterDelegate>)delegate
                       serverData:(NSString *)serverData {
    
    LogAdapterApi_Internal(@"slotId = %@", slotId);
    
    // Add to rewarded video delegate map - needed seperately than init
    [_rewardedVideoSlotIdToSmashDelegate setObject:delegate
                                            forKey:slotId];

    dispatch_async(dispatch_get_main_queue(), ^{
        
        ISPangleRewardedVideoDelegate *rewardedVideoAdDelegate = [[ISPangleRewardedVideoDelegate alloc] initWithSlotId:slotId
                                                                                                           andDelegate:self];
        [self.rewardedVideoSlotIdToPangleAdDelegate setObject:rewardedVideoAdDelegate
                                                       forKey:slotId];
                
        [self.rewardedVideoAdsAvailability setObject:@NO
                                              forKey:slotId];
        
        PAGRewardedRequest *request = [PAGRewardedRequest request];
         
        if (serverData) {
            [request setAdString:serverData];
        }
        
        ISPangleAdapter * __weak weakSelf = self;
        [PAGRewardedAd loadAdWithSlotID:slotId
                                request:request
                      completionHandler:^(PAGRewardedAd * _Nullable rewardedAd, NSError * _Nullable error) {
            
            __typeof__(self) strongSelf = weakSelf;

            if (error) {
                [strongSelf onRewardedVideoDidFailToLoad:slotId
                                               withError:error];
                return;
            }
            
            rewardedAd.delegate = rewardedVideoAdDelegate;
            
            // Add rewarded video ad to dictionary
            [strongSelf.rewardedVideoSlotIdToAd setObject:rewardedAd
                                                   forKey:slotId];
                
            [strongSelf onRewardedVideoDidLoad:slotId];
            
        }];
    });
}

- (void)showRewardedVideoWithViewController:(UIViewController *)viewController
                              adapterConfig:(ISAdapterConfig *)adapterConfig
                                   delegate:(id<ISRewardedVideoAdapterDelegate>)delegate {
    
    NSString *slotId = adapterConfig.settings[kSlotId];
    LogAdapterApi_Internal(@"slotId = %@", slotId);
    
    PAGRewardedAd *rewardedVideoAd = [self.rewardedVideoSlotIdToAd objectForKey:slotId];
    
    if ([self hasRewardedVideoWithAdapterConfig:adapterConfig]) {
        [self.rewardedVideoAdsAvailability setObject:@NO
                                              forKey:slotId];
        
        dispatch_async(dispatch_get_main_queue(), ^{
            [rewardedVideoAd presentFromRootViewController:viewController];
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
    NSString *slotId = adapterConfig.settings[kSlotId];
    PAGRewardedAd *rewardedVideoAd = [_rewardedVideoSlotIdToAd objectForKey:slotId];
    NSNumber *available = [self.rewardedVideoAdsAvailability objectForKey:slotId];
    return rewardedVideoAd != nil && available != nil && [available boolValue];
}

- (void)collectRewardedVideoBiddingDataWithAdapterConfig:(ISAdapterConfig *)adapterConfig
                                                  adData:(NSDictionary *)adData
                                                delegate:(id<ISBiddingDataDelegate>)delegate{

    [self collectBiddingDataWithAdapterConfig:adapterConfig delegate:delegate];
}

#pragma mark - Rewarded Video Delegate

- (void)onRewardedVideoDidLoad:(nonnull NSString *)slotId {
    LogAdapterDelegate_Internal(@"slotId = %@", slotId);
    
    [self.rewardedVideoAdsAvailability setObject:@YES
                                          forKey:slotId];
    
    id<ISRewardedVideoAdapterDelegate> delegate = [_rewardedVideoSlotIdToSmashDelegate objectForKey:slotId];
    [delegate adapterRewardedVideoHasChangedAvailability:YES];
}

- (void)onRewardedVideoDidFailToLoad:(nonnull NSString *)slotId
                           withError:(nonnull NSError *)error {
    
    LogAdapterDelegate_Internal(@"slotId = %@, error = %@", slotId, error.description);
    id<ISRewardedVideoAdapterDelegate> delegate = [_rewardedVideoSlotIdToSmashDelegate objectForKey:slotId];

    [delegate adapterRewardedVideoHasChangedAvailability:NO];

    NSInteger errorCode = (error.code == kFPangleNoFillErrorCode) ? ERROR_RV_LOAD_NO_FILL : error.code;
    NSError *rewardedVideoError = [NSError errorWithDomain:kAdapterName
                                                      code:errorCode
                                                  userInfo:@{NSLocalizedDescriptionKey:error.description}];
        
    [delegate adapterRewardedVideoDidFailToLoadWithError:rewardedVideoError];
}

- (void)onRewardedVideoDidOpen:(nonnull NSString *)slotId {
    LogAdapterDelegate_Internal(@"slotId = %@", slotId);
    id<ISRewardedVideoAdapterDelegate> delegate = [_rewardedVideoSlotIdToSmashDelegate objectForKey:slotId];

    [delegate adapterRewardedVideoDidOpen];
    [delegate adapterRewardedVideoDidStart];
}

- (void)onRewardedVideoDidClick:(nonnull NSString *)slotId {
    LogAdapterDelegate_Internal(@"slotId = %@", slotId);
    id<ISRewardedVideoAdapterDelegate> delegate = [_rewardedVideoSlotIdToSmashDelegate objectForKey:slotId];

    [delegate adapterRewardedVideoDidClick];
}

- (void)onRewardedVideoDidReceiveReward:(nonnull NSString *)slotId {
    LogAdapterDelegate_Internal(@"slotId = %@", slotId);
    id<ISRewardedVideoAdapterDelegate> delegate = [_rewardedVideoSlotIdToSmashDelegate objectForKey:slotId];
    
    [delegate adapterRewardedVideoDidReceiveReward];
}

- (void)onRewardedVideoDidEnd:(nonnull NSString *)slotId {
    LogAdapterDelegate_Internal(@"slotId = %@", slotId);
    id<ISRewardedVideoAdapterDelegate> delegate = [_rewardedVideoSlotIdToSmashDelegate objectForKey:slotId];

    [delegate adapterRewardedVideoDidEnd];
}

- (void)onRewardedVideoDidClose:(nonnull NSString *)slotId {
    LogAdapterDelegate_Internal(@"slotId = %@", slotId);
    id<ISRewardedVideoAdapterDelegate> delegate = [_rewardedVideoSlotIdToSmashDelegate objectForKey:slotId];

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
    NSString *slotId = adapterConfig.settings[kSlotId];
    
    /* Configuration Validation */
    if (![self isConfigValueValid:appId]) {
        NSError *error = [self errorForMissingCredentialFieldWithName:kAppId];
        LogAdapterApi_Internal(@"error = %@", error.description);
        [delegate adapterInterstitialInitFailedWithError:error];
        return;
    }
    
    if (![self isConfigValueValid:slotId]) {
        NSError *error = [self errorForMissingCredentialFieldWithName:kSlotId];
        LogAdapterApi_Internal(@"error = %@", error.description);
        
        [delegate adapterInterstitialInitFailedWithError:error];
        return;
    }
    
    LogAdapterApi_Internal(@"slotId = %@", slotId);

    // Add to interstitial delegate map
    [_interstitialSlotIdToSmashDelegate setObject:delegate
                                           forKey:slotId];
    
    switch (_initState) {
        case INIT_STATE_NONE:
        case INIT_STATE_IN_PROGRESS:
            [self initSDKWithAppId:appId];
            break;
        case INIT_STATE_SUCCESS:
            [delegate adapterInterstitialInitSuccess];
            break;
        case INIT_STATE_FAILED: {
            LogAdapterApi_Internal(@"init failed - slotId = %@", slotId);
            NSError *error = [NSError errorWithDomain:kAdapterName
                                                 code:ERROR_CODE_INIT_FAILED
                                             userInfo:@{NSLocalizedDescriptionKey:@"Pangle SDK init failed"}];
            [delegate adapterInterstitialInitFailedWithError:error];
            break;
        }
    }
}

- (void)loadInterstitialForBiddingWithAdapterConfig:(ISAdapterConfig *)adapterConfig
                                             adData:(NSDictionary *)adData
                                         serverData:(NSString *)serverData
                                           delegate:(id<ISInterstitialAdapterDelegate>)delegate {
    
    NSString *slotId = adapterConfig.settings[kSlotId];
    [self loadInterstitialInternal:slotId
                          delegate:delegate
                        serverData:serverData];
}

- (void)loadInterstitialWithAdapterConfig:(ISAdapterConfig *)adapterConfig
                                   adData:(NSDictionary *)adData
                                 delegate:(id<ISInterstitialAdapterDelegate>)delegate {
    
    NSString *slotId = adapterConfig.settings[kSlotId];
    [self loadInterstitialInternal:slotId
                          delegate:delegate
                        serverData:nil];
}

- (void)loadInterstitialInternal:(NSString *)slotId
                        delegate:(id<ISInterstitialAdapterDelegate>)delegate
                      serverData:(NSString *)serverData {
    
    LogAdapterApi_Internal(@"slotId = %@", slotId);
    
    // Add to interstitial delegate map - needed for load separately from init methods
    [_interstitialSlotIdToSmashDelegate setObject:delegate
                                           forKey:slotId];

    dispatch_async(dispatch_get_main_queue(), ^{
        ISPangleInterstitialDelegate *interstitialAdDelegate = [[ISPangleInterstitialDelegate alloc] initWithSlotId:slotId
                                                                                                        andDelegate:self];
        [self.interstitialSlotIdToPangleAdDelegate setObject:interstitialAdDelegate
                                                      forKey:slotId];
        
        [self.interstitialAdsAvailability setObject:@NO
                                             forKey:slotId];
        
        PAGInterstitialRequest *request = [PAGInterstitialRequest request];
        
        if (serverData) {
            [request setAdString:serverData];
        }
        
        ISPangleAdapter * __weak weakSelf = self;
        [PAGLInterstitialAd loadAdWithSlotID:slotId
                                     request:request
                           completionHandler:^(PAGLInterstitialAd * _Nullable interstitialAd, NSError * _Nullable error) {
            if (error) {
                [weakSelf onInterstitialDidFailToLoad:slotId
                                            withError:error];
                return;
            }
                        
            interstitialAd.delegate = interstitialAdDelegate;
            
            // Add interstitial ad to dictionary
            [weakSelf.interstitialSlotIdToAd setObject:interstitialAd
                                                forKey:slotId];
                
            [weakSelf onInterstitialDidLoad:slotId];
            
         }];
    });
}

- (void)showInterstitialWithViewController:(UIViewController *)viewController
                             adapterConfig:(ISAdapterConfig *)adapterConfig
                                  delegate:(id<ISInterstitialAdapterDelegate>)delegate {
    
    NSString *slotId = adapterConfig.settings[kSlotId];
    LogAdapterApi_Internal(@"slotId = %@", slotId);
    

    PAGLInterstitialAd *interstitialAd = [self.interstitialSlotIdToAd objectForKey:slotId];

    if ([self hasInterstitialWithAdapterConfig:adapterConfig]) {
        [self.interstitialAdsAvailability setObject:@NO
                                             forKey:slotId];

        dispatch_async(dispatch_get_main_queue(), ^{
            
            [interstitialAd presentFromRootViewController:viewController];
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
    NSString *slotId = adapterConfig.settings[kSlotId];
    PAGLInterstitialAd *interstitialAd = [_interstitialSlotIdToAd objectForKey:slotId];
    NSNumber *available = [_interstitialAdsAvailability objectForKey:slotId];
    return interstitialAd != nil && available != nil && [available boolValue];
}

- (void)collectInterstitialBiddingDataWithAdapterConfig:(ISAdapterConfig *)adapterConfig
                                                 adData:(NSDictionary *)adData
                                               delegate:(id<ISBiddingDataDelegate>)delegate{

    [self collectBiddingDataWithAdapterConfig:adapterConfig delegate:delegate];
}


#pragma mark - Interstitial Delegate

- (void)onInterstitialDidLoad:(nonnull NSString *)slotId {
    LogAdapterDelegate_Internal(@"slotId = %@", slotId);
    
    [self.interstitialAdsAvailability setObject:@YES
                                         forKey:slotId];
    
    id<ISInterstitialAdapterDelegate> delegate = [_interstitialSlotIdToSmashDelegate objectForKey:slotId];
    
    [delegate adapterInterstitialDidLoad];
}

- (void)onInterstitialDidFailToLoad:(nonnull NSString *)slotId
                          withError:(nonnull NSError *)error {
    LogAdapterDelegate_Internal(@"slotId = %@, error = %@", slotId, error.description);
    id<ISInterstitialAdapterDelegate> delegate = [_interstitialSlotIdToSmashDelegate objectForKey:slotId];

    NSInteger errorCode = (error.code == kFPangleNoFillErrorCode) ? ERROR_IS_LOAD_NO_FILL : error.code;
    NSError *interstitialError = [NSError errorWithDomain:kAdapterName
                                                     code:errorCode
                                                 userInfo:@{NSLocalizedDescriptionKey:error.description}];
    
    [delegate adapterInterstitialDidFailToLoadWithError:interstitialError];
}

- (void)onInterstitialDidOpen:(nonnull NSString *)slotId {
    LogAdapterDelegate_Internal(@"slotId = %@", slotId);
    id<ISInterstitialAdapterDelegate> delegate = [_interstitialSlotIdToSmashDelegate objectForKey:slotId];

    [delegate adapterInterstitialDidOpen];
    [delegate adapterInterstitialDidShow];
}

- (void)onInterstitialDidClick:(nonnull NSString *)slotId {
    LogAdapterDelegate_Internal(@"slotId = %@", slotId);
    id<ISInterstitialAdapterDelegate> delegate = [_interstitialSlotIdToSmashDelegate objectForKey:slotId];

    [delegate adapterInterstitialDidClick];
}

- (void)onInterstitialDidClose:(nonnull NSString *)slotId {
    LogAdapterDelegate_Internal(@"slotId = %@", slotId);
    id<ISInterstitialAdapterDelegate> delegate = [_interstitialSlotIdToSmashDelegate objectForKey:slotId];

    [delegate adapterInterstitialDidClose];
}

#pragma mark - Banner API

- (void)initBannerForBiddingWithUserId:(NSString *)userId
                         adapterConfig:(ISAdapterConfig *)adapterConfig
                              delegate:(id<ISBannerAdapterDelegate>)delegate {
   
    NSString *appId = adapterConfig.settings[kAppId];
    NSString *slotId = adapterConfig.settings[kSlotId];

    /* Configuration Validation */
    if (![self isConfigValueValid:appId]) {
        NSError *error = [self errorForMissingCredentialFieldWithName:kAppId];
        LogAdapterApi_Internal(@"error = %@", error.description);
        [delegate adapterBannerInitFailedWithError:error];
        return;
    }
    
    if (![self isConfigValueValid:slotId]) {
        NSError *error = [self errorForMissingCredentialFieldWithName:kSlotId];
        LogAdapterApi_Internal(@"error = %@", error.description);
        [delegate adapterBannerInitFailedWithError:error];
        return;
    }
    
    LogAdapterApi_Internal(@"slotId = %@", slotId);

    // Add banner ad to dictionary
    [_bannerSlotIdToSmashDelegate setObject:delegate
                                     forKey:slotId];

    switch (_initState) {
        case INIT_STATE_NONE:
        case INIT_STATE_IN_PROGRESS:
            [self initSDKWithAppId:appId];
            break;
        case INIT_STATE_SUCCESS:
            [delegate adapterBannerInitSuccess];
            break;
        case INIT_STATE_FAILED:
            LogAdapterApi_Internal(@"init failed - slotId = %@", slotId);
            NSError *error = [NSError errorWithDomain:kAdapterName
                                                 code:ERROR_CODE_INIT_FAILED
                                             userInfo:@{NSLocalizedDescriptionKey:@"Pangle SDK init failed"}];
            [delegate adapterBannerInitFailedWithError:error];
            break;
    }
}

- (void)loadBannerForBiddingWithAdapterConfig:(ISAdapterConfig *)adapterConfig
                                       adData:(NSDictionary *)adData
                                   serverData:(NSString *)serverData
                               viewController:(UIViewController *)viewController
                                         size:(ISBannerSize *)size
                                     delegate:(id <ISBannerAdapterDelegate>)delegate {
    NSString *slotId = adapterConfig.settings[kSlotId];
    LogAdapterApi_Internal(@"slotId = %@", slotId);
    
    // add to banner delegate map - needed seperatly from init method
    [_bannerSlotIdToSmashDelegate setObject:delegate
                                     forKey:slotId];

    dispatch_async(dispatch_get_main_queue(), ^{
        ISPangleBannerDelegate *bannerAdDelegate = [[ISPangleBannerDelegate alloc] initWithSlotId:slotId
                                                                                      andDelegate:self];
        [self.bannerSlotIdToPangleAdDelegate setObject:bannerAdDelegate
                                                forKey:slotId];
        PAGBannerRequest *request = [PAGBannerRequest requestWithBannerSize:[self getBannerSize:size]];
         
        if (serverData) {
            [request setAdString:serverData];
        }
        
        ISPangleAdapter * __weak weakSelf = self;
        [PAGBannerAd loadAdWithSlotID:slotId
                              request:request
                    completionHandler:^(PAGBannerAd * _Nullable bannerAd, NSError * _Nullable error) {
            if (error) {
                [weakSelf onBannerDidFailToLoad:slotId
                                      withError:error];
                return;
            }

            bannerAd.delegate = bannerAdDelegate;
            
            bannerAd.rootViewController = viewController;
            
            CGRect bannerFrame = [self getBannerFrame:size];
            bannerAd.bannerView.frame = bannerFrame;
            
            // Add banner ad to dictionary
            [weakSelf.bannerSlotIdToAd setObject:bannerAd
                                          forKey:slotId];
            [weakSelf.bannerSlotIdToViewController setObject:viewController
                                                      forKey:slotId];
            [weakSelf.bannerSlotIdToAdSize setObject:size
                                              forKey:slotId];
            
            [weakSelf onBannerDidLoad:slotId];
        }];
    });
}

- (void)destroyBannerWithAdapterConfig:(ISAdapterConfig *)adapterConfig {
    // There is no required implementation for Pangle destroy banner
}

- (void)collectBannerBiddingDataWithAdapterConfig:(ISAdapterConfig *)adapterConfig
                                              adData:(NSDictionary *)adData
                                            delegate:(id<ISBiddingDataDelegate>)delegate{

    [self collectBiddingDataWithAdapterConfig:adapterConfig delegate:delegate];
}

#pragma mark - Banner Delegate

- (void)onBannerDidLoad:(nonnull NSString *)slotId {
    LogAdapterDelegate_Internal(@"slotId = %@", slotId);
    
    id<ISBannerAdapterDelegate> delegate = [_bannerSlotIdToSmashDelegate objectForKey:slotId];
    PAGBannerAd *bannerAd = [_bannerSlotIdToAd objectForKey:slotId];
    [delegate adapterBannerDidLoad:bannerAd.bannerView];
}

- (void)onBannerDidFailToLoad:(nonnull NSString *)slotId
                    withError:(nonnull NSError *)error {
    LogAdapterDelegate_Internal(@"slotId = %@, error = %@", slotId, error);
    id<ISBannerAdapterDelegate> delegate = [_bannerSlotIdToSmashDelegate objectForKey:slotId];

    NSInteger errorCode = (error.code == kFPangleNoFillErrorCode) ? ERROR_BN_LOAD_NO_FILL : error.code;
    NSError *bannerError = [NSError errorWithDomain:kAdapterName
                                               code:errorCode
                                           userInfo:@{NSLocalizedDescriptionKey:error.description}];

    [delegate adapterBannerDidFailToLoadWithError:bannerError];
}

- (void)onBannerDidShow:(nonnull NSString *)slotId {
    LogAdapterDelegate_Internal(@"slotId = %@", slotId);
    id<ISBannerAdapterDelegate> delegate = [_bannerSlotIdToSmashDelegate objectForKey:slotId];
    
    [delegate adapterBannerDidShow];
}

- (void)onBannerDidClick:(nonnull NSString *)slotId {
    LogAdapterDelegate_Internal(@"slotId = %@", slotId);
    id<ISBannerAdapterDelegate> delegate = [_bannerSlotIdToSmashDelegate objectForKey:slotId];

    [delegate adapterBannerDidClick];
}

#pragma mark - Memory Handling

- (void)releaseMemoryWithAdapterConfig:(nonnull ISAdapterConfig *)adapterConfig {
    NSString *slotId = adapterConfig.settings[kSlotId];

    if ([_rewardedVideoSlotIdToAd hasObjectForKey:slotId]) {
        [_rewardedVideoSlotIdToSmashDelegate removeObjectForKey:slotId];
        [_rewardedVideoSlotIdToPangleAdDelegate removeObjectForKey:slotId];
        [_rewardedVideoSlotIdToAd removeObjectForKey:slotId];
        [_rewardedVideoAdsAvailability removeObjectForKey:slotId];
        [_rewardedVideoSlotIdsForInitCallbacks removeObject:slotId];
        
    } else if ([_interstitialSlotIdToAd hasObjectForKey:slotId]) {
        [_interstitialSlotIdToSmashDelegate removeObjectForKey:slotId];
        [_interstitialSlotIdToPangleAdDelegate removeObjectForKey:slotId];
        [_interstitialSlotIdToAd removeObjectForKey:slotId];
        [_interstitialAdsAvailability removeObjectForKey:slotId];
        
    } else if ([_bannerSlotIdToAd hasObjectForKey:slotId]) {
        [_bannerSlotIdToSmashDelegate removeObjectForKey:slotId];
        [_bannerSlotIdToPangleAdDelegate removeObjectForKey:slotId];
        [_bannerSlotIdToAd removeObjectForKey:slotId];
        [_bannerSlotIdToViewController removeObjectForKey:slotId];
        [_bannerSlotIdToAdSize removeObjectForKey:slotId];
    }
}

#pragma mark - Legal Methods

- (void)setConsent:(BOOL)consent {
    LogAdapterApi_Internal(@"consent = %@", consent ? @"PAGGDPRConsentTypeConsent" : @"PAGGDPRConsentTypeNoConsent");
    PAGConfig *config = [PAGConfig shareConfig];
    config.GDPRConsent = consent ? PAGGDPRConsentTypeConsent : PAGGDPRConsentTypeNoConsent;
}

- (void) setCOPPAValue:(NSInteger)value {
    LogAdapterApi_Internal(@"value = %@", value == 1 ? @"PAGChildDirectedTypeChild" : @"PAGChildDirectedTypeNonChild");
    PAGConfig *config = [PAGConfig shareConfig];
    config.childDirected = value == 1 ? PAGChildDirectedTypeChild : PAGChildDirectedTypeNonChild;
}

- (void)setCCPAValue:(BOOL)value {
    LogAdapterApi_Internal(@"value = %@", value ? @"PAGDoNotSellTypeNotSell" : @"PAGDoNotSellTypeSell");
    PAGConfig *config = [PAGConfig shareConfig];
    config.doNotSell = value ? PAGDoNotSellTypeNotSell : PAGDoNotSellTypeSell;
}

- (void)setMetaDataWithKey:(NSString *)key
                 andValues:(NSMutableArray *)values {
    
    if (values.count == 0) {
        return;
    }
    
    // This is an array of 1 value
    NSString *value = values[0];
    
    if ([ISMetaDataUtils isValidCCPAMetaDataWithKey:key
                                           andValue:value]) {
        [self setCCPAValue:[ISMetaDataUtils getMetaDataBooleanValue:value]];
        
    } else if ([ISMetaDataUtils isValidMetaDataWithKey:key
                                                  flag:kMetaDataCOPPAKey
                                              andValue:value]) {
        if ([value isEqualToString:kCOPPAChild] || [value isEqualToString:kCOPPAAdult]) {
            [self setCOPPAValue:value.integerValue];
        }
    }
}

#pragma mark - Helper Methods

- (void)collectBiddingDataWithAdapterConfig:(ISAdapterConfig *)adapterConfig
                                   delegate:(id<ISBiddingDataDelegate>)delegate {
    NSString *slotId = adapterConfig.settings[kSlotId];
    if (_initState == INIT_STATE_FAILED) {
        NSString *error = [NSString stringWithFormat:@"returning nil as token since init hasn't finished successfully"];
        LogAdapterApi_Internal(@"%@", error);
        [delegate failureWithError:error];
        return;
    }
    
    [PAGSdk getBiddingToken:slotId completion:^(NSString *biddingToken) {
        if (biddingToken.length > 0) {
            NSDictionary *biddingDataDictionary = @{@"token": biddingToken};
            LogAdapterApi_Internal(@"token = %@", biddingToken);
            [delegate successWithBiddingData:biddingDataDictionary];
        }
        else {
            NSString *error = [NSString stringWithFormat:@"token is nil or empty"];
            LogAdapterApi_Internal(@"%@", error);
            [delegate failureWithError:error];
        }
    }];
}

- (PAGBannerAdSize)getBannerSize:(ISBannerSize *)size {
    if ([size.sizeDescription isEqualToString:@"BANNER"]) {
        return kPAGBannerSize320x50;
    } else if ([size.sizeDescription isEqualToString:@"RECTANGLE"]) {
        return kPAGBannerSize300x250;
    } else if ([size.sizeDescription isEqualToString:@"SMART"]) {
        if (UI_USER_INTERFACE_IDIOM() == UIUserInterfaceIdiomPad) {
            return kPAGBannerSize728x90;
        }
    }
        
    return kPAGBannerSize320x50;
}

- (CGRect)getBannerFrame:(ISBannerSize *)size {
    CGRect rect = CGRectZero;

    if ([size.sizeDescription isEqualToString:@"BANNER"]) {
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
    
    return rect;
}

@end
