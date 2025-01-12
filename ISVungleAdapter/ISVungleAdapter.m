//
//  ISVungleAdapter.m
//  ISVungleAdapter
//
//  Copyright © 2024 ironSource Mobile Ltd. All rights reserved.
//

#import <ISVungleAdapter.h>
#import "ISVungleConstant.h"
#import <ISVungleRewardedVideoDelegate.h>
#import <ISVungleInterstitialDelegate.h>
#import <ISVungleBannerDelegate.h>
#import <VungleAdsSDK/VungleAdsSDK.h>

// Handle init callback for all adapter instances
static ISConcurrentMutableSet<ISNetworkInitCallbackProtocol> *initCallbackDelegates = nil;
static InitState initState = INIT_STATE_NONE;

@interface ISVungleAdapter () <ISNetworkInitCallbackProtocol>

// Rewarded video
@property (nonatomic, strong) ISConcurrentMutableDictionary   *rewardedVideoPlacementIdToSmashDelegate;
@property (nonatomic, strong) ISConcurrentMutableDictionary   *rewardedVideoPlacementIdToVungleAdDelegate;
@property (nonatomic, strong) ISConcurrentMutableDictionary   *rewardedVideoPlacementIdToAd;
@property (nonatomic, strong) ISConcurrentMutableSet          *rewardedVideoPlacementIdsForInitCallbacks;

// Interstitial
@property (nonatomic, strong) ISConcurrentMutableDictionary   *interstitialPlacementIdToSmashDelegate;
@property (nonatomic, strong) ISConcurrentMutableDictionary   *interstitialPlacementIdToVungleAdDelegate;
@property (nonatomic, strong) ISConcurrentMutableDictionary   *interstitialPlacementIdToAd;

// Banner
@property (nonatomic, strong) ISConcurrentMutableDictionary   *bannerPlacementIdToSmashDelegate;
@property (nonatomic, strong) ISConcurrentMutableDictionary   *bannerPlacementIdToVungleAdDelegate;
@property (nonatomic, strong) ISConcurrentMutableDictionary   *bannerPlacementIdToAd;
@property (nonatomic, strong) ISConcurrentMutableDictionary   *bannerPlacementIdToAdSize;

@end

@implementation ISVungleAdapter

#pragma mark - IronSource Protocol Methods

// Get adapter version
- (NSString *)version {
    return VungleAdapterVersion;
}

// Get network sdk version
- (NSString *)sdkVersion {
    return [VungleAds sdkVersion];
}

#pragma mark - Initializations Methods And Callbacks

- (instancetype)initAdapter:(NSString *)name {
    self = [super initAdapter:name];
    
    if (self) {
        if (initCallbackDelegates == nil) {
            initCallbackDelegates = [ISConcurrentMutableSet<ISNetworkInitCallbackProtocol> set];
        }
        
        // Rewarded video
        _rewardedVideoPlacementIdToSmashDelegate         = [ISConcurrentMutableDictionary dictionary];
        _rewardedVideoPlacementIdToVungleAdDelegate      = [ISConcurrentMutableDictionary dictionary];
        _rewardedVideoPlacementIdToAd                    = [ISConcurrentMutableDictionary dictionary];
        _rewardedVideoPlacementIdsForInitCallbacks       = [ISConcurrentMutableSet set];
        
        // Interstitial
        _interstitialPlacementIdToSmashDelegate          = [ISConcurrentMutableDictionary dictionary];
        _interstitialPlacementIdToVungleAdDelegate       = [ISConcurrentMutableDictionary dictionary];
        _interstitialPlacementIdToAd                     = [ISConcurrentMutableDictionary dictionary];
        
        // Banner
        _bannerPlacementIdToSmashDelegate                = [ISConcurrentMutableDictionary dictionary];
        _bannerPlacementIdToVungleAdDelegate             = [ISConcurrentMutableDictionary dictionary];
        _bannerPlacementIdToAd                           = [ISConcurrentMutableDictionary dictionary];
        _bannerPlacementIdToAdSize                       = [ISConcurrentMutableDictionary dictionary];
        
        // The network's capability to load a Rewarded Video ad while another Rewarded Video ad of that network is showing
        LWSState = LOAD_WHILE_SHOW_BY_INSTANCE;
    }
    
    return self;
}

- (void)initSDKWithAppId:(NSString *)appId {
    
    // Add self to the init delegates only in case the initialization has not finished yet
    if (initState == INIT_STATE_NONE || initState == INIT_STATE_IN_PROGRESS) {
        [initCallbackDelegates addObject:self];
    }
    
    static dispatch_once_t initSdkOnceToken;
    dispatch_once(&initSdkOnceToken, ^{
        initState = INIT_STATE_IN_PROGRESS;
        
        LogAdapterApi_Internal(@"appId = %@", appId);
        
        dispatch_async(dispatch_get_main_queue(), ^{
            
            [VungleAds setIntegrationName:kMediationName
                                  version:[self version]];
            
            ISVungleAdapter * __weak weakSelf = self;
            
            [VungleAds initWithAppId:appId
                          completion:^(NSError * _Nullable error) {
                
                __typeof__(self) strongSelf = weakSelf;
                
                if (error) {
                    NSString *errorMsg = [NSString stringWithFormat:@"Vungle SDK init failed %@", error.description];
                    [strongSelf initializationFailure:errorMsg];
                } else {
                    [strongSelf initializationSuccess];
                }
            }];
        });
    });
}

- (void)initializationSuccess {
    LogAdapterDelegate_Internal(@"");
    
    initState = INIT_STATE_SUCCESS;
    
    NSArray *initDelegatesList = initCallbackDelegates.allObjects;
    
    for (id<ISNetworkInitCallbackProtocol> initDelegate in initDelegatesList) {
        [initDelegate onNetworkInitCallbackSuccess];
    }
    
    [initCallbackDelegates removeAllObjects];
}

- (void)initializationFailure:(NSString *)error {
    LogAdapterDelegate_Internal(@"error = %@", error.description);
    
    initState = INIT_STATE_FAILED;
    
    NSArray *initDelegatesList = initCallbackDelegates.allObjects;
    
    for (id<ISNetworkInitCallbackProtocol> delegate in initDelegatesList) {
        [delegate onNetworkInitCallbackFailed:error];
    }
    
    [initCallbackDelegates removeAllObjects];
}

- (void)onNetworkInitCallbackSuccess {
    
    // Rewarded video
    NSArray *rewardedVideoPlacementIds = _rewardedVideoPlacementIdToSmashDelegate.allKeys;
    
    for (NSString *placementId in rewardedVideoPlacementIds) {
        id<ISRewardedVideoAdapterDelegate> delegate = [self.rewardedVideoPlacementIdToSmashDelegate objectForKey:placementId];
        if ([self.rewardedVideoPlacementIdsForInitCallbacks hasObject:placementId]) {
            [delegate adapterRewardedVideoInitSuccess];
        } else {
            [self loadRewardedVideoInternal:placementId
                                 serverData:nil
                                   delegate:delegate];
        }
    }
    
    // Interstitial
    NSArray *interstitialPlacementIds = _interstitialPlacementIdToSmashDelegate.allKeys;
    
    for (NSString *placementId in interstitialPlacementIds) {
        id<ISInterstitialAdapterDelegate> delegate = [self.interstitialPlacementIdToSmashDelegate objectForKey:placementId];
        [delegate adapterInterstitialInitSuccess];
    }
    
    // Banner
    NSArray *bannerPlacementIds = _bannerPlacementIdToSmashDelegate.allKeys;
    
    for (NSString *placementId in bannerPlacementIds) {
        id<ISBannerAdapterDelegate> delegate = [self.bannerPlacementIdToSmashDelegate objectForKey:placementId];
        [delegate adapterBannerInitSuccess];
    }
}

- (void)onNetworkInitCallbackFailed:(nonnull NSString *)errorMessage {
    
    NSError *error = [ISError createErrorWithDomain:kAdapterName
                                               code:ERROR_CODE_INIT_FAILED
                                            message:errorMessage];
    
    // Rewarded video
    NSArray *rewardedVideoPlacementIds = _rewardedVideoPlacementIdToSmashDelegate.allKeys;
    
    for (NSString *placementId in rewardedVideoPlacementIds) {
        id<ISRewardedVideoAdapterDelegate> delegate = [self.rewardedVideoPlacementIdToSmashDelegate objectForKey:placementId];
        if ([self.rewardedVideoPlacementIdsForInitCallbacks hasObject:placementId]) {
            [delegate adapterRewardedVideoInitFailed:error];
        } else {
            [delegate adapterRewardedVideoHasChangedAvailability:NO];
        }
    }
    
    
    // Interstitial
    NSArray *interstitialPlacementIds = _interstitialPlacementIdToSmashDelegate.allKeys;
    
    for (NSString *placementId in interstitialPlacementIds) {
        id<ISInterstitialAdapterDelegate> delegate = [self.interstitialPlacementIdToSmashDelegate objectForKey:placementId];
        [delegate adapterInterstitialInitFailedWithError:error];
    }
    
    
    // Banner
    NSArray *bannerPlacementIds = _bannerPlacementIdToSmashDelegate.allKeys;
    
    for (NSString *placementId in bannerPlacementIds) {
        id<ISBannerAdapterDelegate> delegate = [self.bannerPlacementIdToSmashDelegate objectForKey:placementId];
        [delegate adapterBannerInitFailedWithError:error];
    }
}

#pragma mark - Rewarded Video API

// Used for flows when the mediation needs to get a callback for init
- (void)initRewardedVideoForCallbacksWithUserId:(NSString *)userId
                                  adapterConfig:(ISAdapterConfig *)adapterConfig
                                       delegate:(id<ISRewardedVideoAdapterDelegate>)delegate {
    
    NSString *appId = adapterConfig.settings[kAppId];
    NSString *placementId = adapterConfig.settings[kPlacementId];
    
    /* Configuration Validation */
    if (![self isConfigValueValid:appId]) {
        NSError *error = [self errorForMissingCredentialFieldWithName:kAppId];
        LogAdapterApi_Internal(@"error = %@", error.description);
        
        [delegate adapterRewardedVideoInitFailed:error];
        return;
    }
    
    if (![self isConfigValueValid:placementId]) {
        NSError *error = [self errorForMissingCredentialFieldWithName:kPlacementId];
        LogAdapterApi_Internal(@"error = %@", error.description);
        
        [delegate adapterRewardedVideoInitFailed:error];
        return;
    }
    
    LogAdapterApi_Internal(@"placementId = %@", placementId);
    
    // Add to rewarded video delegate map
    [self.rewardedVideoPlacementIdToSmashDelegate setObject:delegate
                                                     forKey:placementId];
    
    [self.rewardedVideoPlacementIdsForInitCallbacks addObject:placementId];
    
    switch (initState) {
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
    NSString *placementId = adapterConfig.settings[kPlacementId];
    
    /* Configuration Validation */
    if (![self isConfigValueValid:appId]) {
        NSError *error = [self errorForMissingCredentialFieldWithName:kAppId];
        LogAdapterApi_Internal(@"error = %@", error.description);
        [delegate adapterRewardedVideoHasChangedAvailability:NO];
        return;
    }
    
    if (![self isConfigValueValid:placementId]) {
        NSError *error = [self errorForMissingCredentialFieldWithName:kPlacementId];
        LogAdapterApi_Internal(@"error = %@", error.description);
        [delegate adapterRewardedVideoHasChangedAvailability:NO];
        return;
    }
    
    LogAdapterApi_Internal(@"placementId = %@", placementId);
    
    // Add to rewarded video delegate map
    [self.rewardedVideoPlacementIdToSmashDelegate setObject:delegate
                                                     forKey:placementId];
    
    switch (initState) {
        case INIT_STATE_NONE:
        case INIT_STATE_IN_PROGRESS:
            [self initSDKWithAppId:appId];
            break;
        case INIT_STATE_SUCCESS:
            [self loadRewardedVideoInternal:placementId
                                 serverData:nil
                                   delegate:delegate];
            break;
        case INIT_STATE_FAILED:
            [delegate adapterRewardedVideoHasChangedAvailability:NO];
            break;
    }
}

- (void)loadRewardedVideoForBiddingWithAdapterConfig:(ISAdapterConfig *)adapterConfig
                                              adData:(NSDictionary *)adData
                                          serverData:(NSString *)serverData
                                            delegate:(id<ISRewardedVideoAdapterDelegate>)delegate {
    NSString *placementId = adapterConfig.settings[kPlacementId];
    [self loadRewardedVideoInternal:placementId
                         serverData:serverData
                           delegate:delegate];
}

- (void)loadRewardedVideoWithAdapterConfig:(ISAdapterConfig *)adapterConfig
                                    adData:(NSDictionary *)adData
                                  delegate:(id<ISRewardedVideoAdapterDelegate>)delegate {
    NSString *placementId = adapterConfig.settings[kPlacementId];
    [self loadRewardedVideoInternal:placementId
                         serverData:nil
                           delegate:delegate];
}

- (void)loadRewardedVideoInternal:(NSString *)placementId
                       serverData:(NSString *)serverData
                         delegate:(id<ISRewardedVideoAdapterDelegate>)delegate {
    
    LogAdapterApi_Internal(@"placementId = %@", placementId);
    
    // In favor of supporting all of the Mediation modes there is a need to store the Rewarded Video delegate
    // in a dictionary on both init and load APIs
    [self.rewardedVideoPlacementIdToSmashDelegate setObject:delegate
                                                     forKey:placementId];
    
    ISVungleRewardedVideoDelegate *rewardedVideoAdDelegate = [[ISVungleRewardedVideoDelegate alloc] initWithPlacementId:placementId
                                                                                                            andDelegate:delegate];
    
    [self.rewardedVideoPlacementIdToVungleAdDelegate setObject:rewardedVideoAdDelegate
                                                        forKey:placementId];
    
    VungleRewarded *rewardedVideoAd = [[VungleRewarded alloc] initWithPlacementId:placementId];
    rewardedVideoAd.delegate = rewardedVideoAdDelegate;
    
    // Add rewarded video ad to dictionary
    [self.rewardedVideoPlacementIdToAd setObject:rewardedVideoAd
                                          forKey:placementId];
    
    [rewardedVideoAd load:serverData];
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
    
    VungleRewarded *rewardedVideoAd = [self.rewardedVideoPlacementIdToAd objectForKey:placementId];
    
    //set dynamic user Id
    if ([self dynamicUserId]) {
        LogAdapterApi_Internal(@"set userID to %@", [self dynamicUserId]);
        [rewardedVideoAd setUserIdWithUserId:self.dynamicUserId];
    }
    
    dispatch_async(dispatch_get_main_queue(), ^{
        [rewardedVideoAd presentWith:viewController];
    });
}

- (BOOL)hasRewardedVideoWithAdapterConfig:(ISAdapterConfig *)adapterConfig {
    NSString *placementId = adapterConfig.settings[kPlacementId];
    VungleRewarded *rewardedVideoAd = [self.rewardedVideoPlacementIdToAd objectForKey:placementId];
    return rewardedVideoAd != nil && [rewardedVideoAd canPlayAd];
}

- (NSDictionary *)getRewardedVideoBiddingDataWithAdapterConfig:(ISAdapterConfig *)adapterConfig
                                                        adData:(NSDictionary *)adData {
    NSString *placementId = adapterConfig.settings[kPlacementId];
    return [self getBiddingDataWithPlacementId:placementId];
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
    NSString *placementId = adapterConfig.settings[kPlacementId];
    
    // Configuration Validation
    if (![self isConfigValueValid:appId]) {
        NSError *error = [self errorForMissingCredentialFieldWithName:kAppId];
        LogAdapterApi_Internal(@"error = %@", error.description);
        [delegate adapterInterstitialInitFailedWithError:error];
        return;
    }
    
    if (![self isConfigValueValid:placementId]) {
        NSError *error = [self errorForMissingCredentialFieldWithName:kPlacementId];
        LogAdapterApi_Internal(@"error = %@", error.description);
        
        [delegate adapterInterstitialInitFailedWithError:error];
        return;
    }
    
    LogAdapterApi_Internal(@"placementId = %@", placementId);
    
    // Add to interstitial delegate map
    [self.interstitialPlacementIdToSmashDelegate setObject:delegate
                                                    forKey:placementId];
    
    switch (initState) {
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
            [delegate adapterInterstitialInitFailedWithError:error];
            break;
        }
    }
}

- (void)loadInterstitialForBiddingWithAdapterConfig:(ISAdapterConfig *)adapterConfig
                                             adData:(NSDictionary *)adData
                                         serverData:(NSString *)serverData
                                           delegate:(id<ISInterstitialAdapterDelegate>)delegate {
    
    NSString *placementId = adapterConfig.settings[kPlacementId];
    [self loadInterstitialInternal:placementId
                        serverData:serverData
                          delegate:delegate];
}

- (void)loadInterstitialWithAdapterConfig:(ISAdapterConfig *)adapterConfig
                                   adData:(NSDictionary *)adData
                                 delegate:(id<ISInterstitialAdapterDelegate>)delegate {
    
    NSString *placementId = adapterConfig.settings[kPlacementId];
    [self loadInterstitialInternal:placementId
                        serverData:nil
                          delegate:delegate];
}

- (void)loadInterstitialInternal:(NSString *)placementId
                      serverData:(NSString *)serverData
                        delegate:(id<ISInterstitialAdapterDelegate>)delegate {
    
    LogAdapterApi_Internal(@"placementId = %@", placementId);
    
    // In favor of supporting all of the Mediation modes there is a need to store the Interstitial delegate
    // in a dictionary on both init and load APIs
    [self.interstitialPlacementIdToSmashDelegate setObject:delegate
                                                    forKey:placementId];
    
    ISVungleInterstitialDelegate *interstitialAdDelegate = [[ISVungleInterstitialDelegate alloc] initWithPlacementId:placementId
                                                                                                         andDelegate:delegate];
    
    [self.interstitialPlacementIdToVungleAdDelegate setObject:interstitialAdDelegate
                                                       forKey:placementId];
    
    VungleInterstitial *interstitialAd = [[VungleInterstitial alloc] initWithPlacementId:placementId];
    interstitialAd.delegate = interstitialAdDelegate;
    
    // Add interstitial ad to dictionary
    [self.interstitialPlacementIdToAd setObject:interstitialAd
                                         forKey:placementId];
    
    [interstitialAd load:serverData];
}

- (void)showInterstitialWithViewController:(UIViewController *)viewController
                             adapterConfig:(ISAdapterConfig *)adapterConfig
                                  delegate:(id<ISInterstitialAdapterDelegate>)delegate {
    
    NSString *placementId = adapterConfig.settings[kPlacementId];
    LogAdapterApi_Internal(@"placementId = %@", placementId);
    
    if (![self hasInterstitialWithAdapterConfig:adapterConfig]) {
        NSError *error = [ISError createError:ERROR_CODE_NO_ADS_TO_SHOW
                                  withMessage:[NSString stringWithFormat: @"%@ show failed", kAdapterName]];
        LogAdapterApi_Internal(@"error = %@", error);
        [delegate adapterInterstitialDidFailToShowWithError:error];
        return;
    }
    
    VungleInterstitial *interstitialAd = [self.interstitialPlacementIdToAd objectForKey:placementId];
    dispatch_async(dispatch_get_main_queue(), ^{
        [interstitialAd presentWith:viewController];
    });
}

- (BOOL)hasInterstitialWithAdapterConfig:(ISAdapterConfig *)adapterConfig {
    NSString *placementId = adapterConfig.settings[kPlacementId];
    VungleInterstitial *interstitialAd = [self.interstitialPlacementIdToAd objectForKey:placementId];
    return interstitialAd != nil && [interstitialAd canPlayAd];
}

- (NSDictionary *)getInterstitialBiddingDataWithAdapterConfig:(ISAdapterConfig *)adapterConfig
                                                       adData:(NSDictionary *)adData {
    NSString *placementId = adapterConfig.settings[kPlacementId];
    return [self getBiddingDataWithPlacementId:placementId];
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
    NSString *placementId = adapterConfig.settings[kPlacementId];
    
    /* Configuration Validation */
    if (![self isConfigValueValid:appId]) {
        NSError *error = [self errorForMissingCredentialFieldWithName:kAppId];
        LogAdapterApi_Internal(@"error = %@", error.description);
        [delegate adapterBannerInitFailedWithError:error];
        return;
    }
    
    if (![self isConfigValueValid:placementId]) {
        NSError *error = [self errorForMissingCredentialFieldWithName:kPlacementId];
        LogAdapterApi_Internal(@"error = %@", error.description);
        [delegate adapterBannerInitFailedWithError:error];
        return;
    }
    
    LogAdapterApi_Internal(@"placementId = %@", placementId);
    
    // Add banner ad to dictionary
    [self.bannerPlacementIdToSmashDelegate setObject:delegate
                                              forKey:placementId];
    
    switch (initState) {
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
            [delegate adapterBannerInitFailedWithError:error];
            break;
        }
    }
}

- (void)loadBannerForBiddingWithAdapterConfig:(ISAdapterConfig *)adapterConfig
                                       adData:(NSDictionary *)adData
                                   serverData:(NSString *)serverData
                               viewController:(UIViewController *)viewController
                                         size:(ISBannerSize *)size
                                     delegate:(id <ISBannerAdapterDelegate>)delegate {
    
    NSString *placementId = adapterConfig.settings[kPlacementId];
    [self loadBannerInternal:placementId
                  serverData:serverData
              viewController:viewController
                        size:size
                    delegate:delegate];
}

- (void)loadBannerWithAdapterConfig:(ISAdapterConfig *)adapterConfig
                             adData:(NSDictionary *)adData
                     viewController:(UIViewController *)viewController
                               size:(ISBannerSize *)size
                           delegate:(id <ISBannerAdapterDelegate>)delegate {
    
    NSString *placementId = adapterConfig.settings[kPlacementId];
    [self loadBannerInternal:placementId
                  serverData:nil
              viewController:viewController
                        size:size
                    delegate:delegate];
}

- (void)loadBannerInternal:(NSString *)placementId
                serverData:(NSString *)serverData
            viewController:(UIViewController *)viewController
                      size:(ISBannerSize *)size
                  delegate:(id <ISBannerAdapterDelegate>)delegate {
    
    LogAdapterApi_Internal(@"placementId = %@", placementId);
    
    // In favor of supporting all of the Mediation modes there is a need to store the Banner delegate
    // in a dictionary on both init and load APIs
    [self.bannerPlacementIdToSmashDelegate setObject:delegate
                                              forKey:placementId];
    
    // create Vungle banner view
    dispatch_async(dispatch_get_main_queue(), ^{
        // initialize banner ad delegate
        ISVungleBannerDelegate *bannerAdDelegate = [[ISVungleBannerDelegate alloc] initWithPlacementId:placementId
                                                                                           andDelegate:delegate];
        
        [self.bannerPlacementIdToVungleAdDelegate setObject:bannerAdDelegate
                                                     forKey:placementId];
        
        [self.bannerPlacementIdToAdSize setObject:size
                                           forKey:placementId];
        
        // calculate Vungle Ad Size
        VungleAdSize *adSize = [self getBannerSize:size];
        
        NSLog(@"------------- VungleSDK requested size (%ld,%ld)", (long)adSize.size.width, (long)adSize.size.height);
        
        // create Vungle banner ad
        VungleBannerView *vungleBannerView = [[VungleBannerView alloc] initWithPlacementId:placementId
                                                                              vungleAdSize:adSize];
        
        // set delegate
        vungleBannerView.delegate = bannerAdDelegate;
        
        [self.bannerPlacementIdToAd setObject:vungleBannerView
                                       forKey:placementId];
        
        // load banner
        [vungleBannerView load:serverData];
    });
}

- (void)destroyBannerWithAdapterConfig:(ISAdapterConfig *)adapterConfig {
    NSString *placementId = adapterConfig.settings[kPlacementId];
    VungleBannerView *banner = [self.bannerPlacementIdToAd objectForKey:placementId];
    
    if (banner) {
        banner.delegate = nil;
        
        [self.bannerPlacementIdToSmashDelegate removeObjectForKey:placementId];
        [self.bannerPlacementIdToVungleAdDelegate removeObjectForKey:placementId];
        [self.bannerPlacementIdToAd removeObjectForKey:placementId];
        [self.bannerPlacementIdToAdSize removeObjectForKey:placementId];
    }
}

- (CGFloat)getAdaptiveHeightWithWidth:(CGFloat)width {
    CGFloat height = [self getVungleAdaptiveHeightWithWidth:width];
    LogAdapterApi_Internal(@"%@", [NSString stringWithFormat:@"height - %.2f for width - %.2f", height, width]);
    
    return height;
}

- (NSDictionary *)getBannerBiddingDataWithAdapterConfig:(ISAdapterConfig *)adapterConfig
                                                 adData:(NSDictionary *)adData {
    NSString *placementId = adapterConfig.settings[kPlacementId];
    return [self getBiddingDataWithPlacementId:placementId];
}

#pragma mark - Memory Handling

- (void)releaseMemoryWithAdapterConfig:(nonnull ISAdapterConfig *)adapterConfig {
    NSString *placementId = adapterConfig.settings[kPlacementId];

    if ([self.rewardedVideoPlacementIdToAd hasObjectForKey:placementId]) {
        [self.rewardedVideoPlacementIdToSmashDelegate removeObjectForKey:placementId];
        [self.rewardedVideoPlacementIdToVungleAdDelegate removeObjectForKey:placementId];
        [self.rewardedVideoPlacementIdToAd removeObjectForKey:placementId];
        [self.rewardedVideoPlacementIdsForInitCallbacks removeObject:placementId];

    } else if ([self.interstitialPlacementIdToAd hasObjectForKey:placementId]) {
        [self.interstitialPlacementIdToSmashDelegate removeObjectForKey:placementId];
        [self.interstitialPlacementIdToVungleAdDelegate removeObjectForKey:placementId];
        [self.interstitialPlacementIdToAd removeObjectForKey:placementId];

    } else if ([self.bannerPlacementIdToAd hasObjectForKey:placementId]) {
        [self destroyBannerWithAdapterConfig:adapterConfig];
    }
}

#pragma mark - Legal Methods

- (void)setConsent:(BOOL)consent {
    LogAdapterApi_Internal(@"consent = %@", consent ? @"YES" : @"NO");
    [VunglePrivacySettings setGDPRStatus:consent];
    [VunglePrivacySettings setGDPRMessageVersion:@""];
}

- (void)setCOPPAValue:(BOOL)value {
    LogAdapterApi_Internal(@"value = %@", value ? @"YES" : @"NO");
    [VunglePrivacySettings setCOPPAStatus:value];
}

- (void)setCCPAValue:(BOOL)value {
    // The Vungle CCPA API expects an indication if the user opts in to targeted advertising.
    // Given that this is opposite to the LevelPlay Mediation CCPA flag of do_not_sell
    // we will use the opposite value of what is passed to this method
    BOOL optIn = !value;
    LogAdapterApi_Internal(@"optIn = %@", optIn ? @"YES" : @"NO");
    [VunglePrivacySettings setCCPAStatus:optIn];
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

#pragma mark - Helper Methods

- (NSDictionary *)getBiddingDataWithPlacementId:(NSString *)placementId {
    if (initState == INIT_STATE_FAILED) {
        LogAdapterApi_Internal(@"returning nil as token since init isn't successful");
        return nil;
    }

    LogAdapterApi_Internal(@"placementId = %@", placementId);

    NSString *bidderToken = [VungleAds getBiddingToken];
    NSString *returnedToken = bidderToken? bidderToken : @"";

    LogAdapterApi_Internal(@"token = %@", returnedToken);

    return @{@"token": returnedToken};
}

- (VungleAdSize *)getBannerSize:(ISBannerSize *)size {
    VungleAdSize * vungleAdSize = [VungleAdSize VungleAdSizeBannerRegular];
    if ([size.sizeDescription isEqualToString:kSizeCustom]) {
        vungleAdSize = [VungleAdSize VungleAdSizeFromCGSize:CGSizeMake(size.width, size.height)];
    } else if ([size.sizeDescription isEqualToString:kSizeRectangle]) {
        vungleAdSize = [VungleAdSize VungleAdSizeMREC];
    } else if ([size.sizeDescription isEqualToString:kSizeLeaderboard]) {
        vungleAdSize = [VungleAdSize VungleAdSizeLeaderboard];
    } else if ([size.sizeDescription isEqualToString:kSizeSmart]) {
        if ([UIDevice.currentDevice userInterfaceIdiom] == UIUserInterfaceIdiomPad) {
            vungleAdSize = [VungleAdSize VungleAdSizeLeaderboard];
        }
    }
    
    if ([size respondsToSelector:@selector(containerParams)]) {
        if (size.isAdaptive) {
            vungleAdSize = [VungleAdSize VungleAdSizeFromCGSize:CGSizeMake(size.containerParams.width, 0)];
            LogAdapterApi_Internal(@"default height - %@ container height - %@ default width - %@ container width - %@", @(size.height), @(size.containerParams.height), @(size.width), @(size.containerParams.width));
        }
    } else {
        LogInternal_Error(@"containerParams is not supported");
    }
    
    return vungleAdSize;
}

- (CGFloat)getVungleAdaptiveHeightWithWidth:(CGFloat)width {
    __block CGFloat height;
    
    void (^calculateAdaptiveHeight)(void) = ^{
        height = [[UIScreen mainScreen] bounds].size.height;
    };
    
    if ([NSThread isMainThread]) {
        calculateAdaptiveHeight();
    } else {
        dispatch_sync(dispatch_get_main_queue(), ^{
            calculateAdaptiveHeight();
        });
    }
    
    return height;
}

@end
