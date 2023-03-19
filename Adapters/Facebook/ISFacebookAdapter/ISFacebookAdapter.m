//
//  ISFacebookAdapter.m
//  ISFacebookAdapter
//
//  Copyright © 2023 ironSource Mobile Ltd. All rights reserved.
//

#import <ISFacebookAdapter.h>
#import <ISFacebookRewardedVideoDelegate.h>
#import <ISFacebookInterstitialDelegate.h>
#import <ISFacebookBannerDelegate.h>
#import <FBAudienceNetwork/FBAudienceNetwork.h>

// Mediation keys
static NSString * const kMediationName              = @"IronSource";

// Network keys
static NSString * const kAdapterVersion             = FacebookAdapterVersion;
static NSString * const kAdapterName                = @"Facebook";
static NSString * const kPlacementId                = @"placementId";
static NSString * const kAllPlacementIds            = @"placementIds";

// Meta data keys
static NSString * const kMetaDataMixAudienceKey     = @"meta_mixed_audience";

// Meta error codes
static NSInteger kMetaNoFillErrorCode               = 1001;

// init state possible values
typedef NS_ENUM(NSInteger, InitState) {
    INIT_STATE_NONE,
    INIT_STATE_IN_PROGRESS,
    INIT_STATE_SUCCESS,
    INIT_STATE_FAILED
};

// Handle init callback for all adapter instances
static ISConcurrentMutableSet<ISNetworkInitCallbackProtocol> *initCallbackDelegates = nil;
static InitState _initState = INIT_STATE_NONE;
static NSString* _mediationService = nil;


@interface ISFacebookAdapter () <ISFacebookRewardedVideoDelegateWrapper, ISFacebookInterstitialDelegateWrapper, ISFacebookBannerDelegateWrapper, ISNetworkInitCallbackProtocol>

// Rewarded video
@property (nonatomic, strong) ISConcurrentMutableDictionary*       rewardedVideoPlacementIdToSmashDelegate;
@property (nonatomic, strong) ISConcurrentMutableDictionary*       rewardedVideoPlacementIdToFacebookAdDelegate;
@property (nonatomic, strong) ISConcurrentMutableDictionary*       rewardedVideoPlacementIdToAd;
@property (nonatomic, strong) ISConcurrentMutableSet*              rewardedVideoPlacementIdsForInitCallbacks;

// Interstitial
@property (nonatomic, strong) ISConcurrentMutableDictionary*       interstitialPlacementIdToSmashDelegate;
@property (nonatomic, strong) ISConcurrentMutableDictionary*       interstitialPlacementIdToFacebookAdDelegate;
@property (nonatomic, strong) ISConcurrentMutableDictionary*       interstitialPlacementIdToAd;
    
// Banner
@property (nonatomic, strong) ISConcurrentMutableDictionary*       bannerPlacementIdToSmashDelegate;
@property (nonatomic, strong) ISConcurrentMutableDictionary*       bannerPlacementIdToFacebookAdDelegate;
@property (nonatomic, strong) ISConcurrentMutableDictionary*       bannerPlacementIdToAd;

@end

@implementation ISFacebookAdapter

#pragma mark - IronSource Protocol Methods

- (NSString *)version {
    return kAdapterVersion;
}

- (NSString *)sdkVersion {
    return FB_AD_SDK_VERSION;
}

#pragma mark - Initializations Methods And Callbacks

- (instancetype)initAdapter:(NSString *)name
{
    self = [super initAdapter:name];
    
    if (self) {
        if (initCallbackDelegates == nil) {
            initCallbackDelegates =  [ISConcurrentMutableSet<ISNetworkInitCallbackProtocol> set];
        }
        
        // Rewarded video
        _rewardedVideoPlacementIdToSmashDelegate        = [ISConcurrentMutableDictionary dictionary];
        _rewardedVideoPlacementIdToFacebookAdDelegate   = [ISConcurrentMutableDictionary dictionary];
        _rewardedVideoPlacementIdToAd                   = [ISConcurrentMutableDictionary dictionary];
        _rewardedVideoPlacementIdsForInitCallbacks      = [ISConcurrentMutableSet set];
        
        // Interstitial
        _interstitialPlacementIdToSmashDelegate         = [ISConcurrentMutableDictionary dictionary];
        _interstitialPlacementIdToFacebookAdDelegate    = [ISConcurrentMutableDictionary dictionary];
        _interstitialPlacementIdToAd                    = [ISConcurrentMutableDictionary dictionary];
        
        // Banner
        _bannerPlacementIdToSmashDelegate               = [ISConcurrentMutableDictionary dictionary];
        _bannerPlacementIdToFacebookAdDelegate          = [ISConcurrentMutableDictionary dictionary];
        _bannerPlacementIdToAd                          = [ISConcurrentMutableDictionary dictionary];
        
        // The network's capability to load a Rewarded Video ad while another Rewarded Video ad of that network is showing
        LWSState = LOAD_WHILE_SHOW_BY_INSTANCE;
    }
    
    return self;
}

- (void)initSDKWithPlacementIDs:(NSString *)allPlacementIDs {
        
    // add self to the init delegates only in case the initialization has not finished yet
    if (_initState == INIT_STATE_NONE || _initState == INIT_STATE_IN_PROGRESS) {
        [initCallbackDelegates addObject:self];
    }
    
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        
        _initState = INIT_STATE_IN_PROGRESS;
        
        NSArray* placementIdsArray = [allPlacementIDs componentsSeparatedByString:@","];

        FBAdInitSettings *initSettings = [[FBAdInitSettings alloc] initWithPlacementIDs:placementIdsArray
                                                                       mediationService:[self getMediationService]];
                
        // check if debug mode needed
        FBAdLogLevel logLevel =[ISConfigurations getConfigurations].adaptersDebug ? FBAdLogLevelVerbose : FBAdLogLevelNone;
        [FBAdSettings setLogLevel:logLevel];
        
        LogAdapterApi_Internal(@"Initialize Meta with placementIDs = %@", placementIdsArray);
        
        ISFacebookAdapter * __weak weakSelf = self;
        [FBAudienceNetworkAds initializeWithSettings:initSettings
                                   completionHandler:^(FBAdInitResults *results) {
                                
            if (results.success) {
                // call init callback delegate success
                [weakSelf initializationSuccess];
            } else {
                // call init callback delegate failed
                [weakSelf initializationFailure];
            }
        }];
    });
}

- (void)initializationSuccess {
    LogAdapterDelegate_Internal(@"");

    _initState = INIT_STATE_SUCCESS;
    
    // set mediation service
    [FBAdSettings setMediationService:[self getMediationService]];

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
        [initDelegate onNetworkInitCallbackFailed:@"Meta SDK init failed"];
    }
    
    [initCallbackDelegates removeAllObjects];
}


- (void)onNetworkInitCallbackSuccess {
    
    // rewarded video
    NSArray *rewardedVideoPlacementIDs = _rewardedVideoPlacementIdToSmashDelegate.allKeys;
    
    for (NSString * placementId in rewardedVideoPlacementIDs) {
        id<ISRewardedVideoAdapterDelegate> delegate = [_rewardedVideoPlacementIdToSmashDelegate objectForKey:placementId];
        if ([_rewardedVideoPlacementIdsForInitCallbacks hasObject:placementId]) {
            [delegate adapterRewardedVideoInitSuccess];
        } else {
            [self loadRewardedVideoInternal:placementId
                                   delegate:delegate
                                 serverData:nil];
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

- (void)onNetworkInitCallbackFailed:(NSString *)errorMessage {
    
    NSError *error = [ISError createErrorWithDomain:kAdapterName
                                               code:ERROR_CODE_INIT_FAILED
                                            message:errorMessage];
    
    // rewarded video
    NSArray *rewardedVideoPlacementIDs = _rewardedVideoPlacementIdToSmashDelegate.allKeys;
    
    for (NSString * placementId in rewardedVideoPlacementIDs) {
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

// Used for flows when the mediation needs to get a callback for init
- (void)initRewardedVideoForCallbacksWithUserId:(NSString *)userId
                                  adapterConfig:(ISAdapterConfig *)adapterConfig
                                       delegate:(id<ISRewardedVideoAdapterDelegate>)delegate {
    NSString *placementID = adapterConfig.settings[kPlacementId];
    NSString *allPlacementIDs = adapterConfig.settings[kAllPlacementIds];
    
    /* Configuration Validation */
    if (![self isConfigValueValid:placementID]) {
        NSError *error = [self errorForMissingCredentialFieldWithName:kPlacementId];
        LogAdapterApi_Internal(@"error.description = %@", error.description);
        [delegate adapterRewardedVideoInitFailed:error];
        return;
    }
    
    if (![self isConfigValueValid:allPlacementIDs]) {
        NSError *error = [self errorForMissingCredentialFieldWithName:kAllPlacementIds];
        LogAdapterApi_Internal(@"error.description = %@", error.description);
        [delegate adapterRewardedVideoInitFailed:error];
        return;
    }
    
    LogAdapterApi_Internal(@"placementID = %@", placementID);

    //add to rewarded video delegate map
    [_rewardedVideoPlacementIdToSmashDelegate setObject:delegate
                                                 forKey:placementID];
    
    //add to rewarded video init callback map
    [_rewardedVideoPlacementIdsForInitCallbacks addObject:placementID];
            
    switch (_initState) {
        case INIT_STATE_NONE:
        case INIT_STATE_IN_PROGRESS:
            [self initSDKWithPlacementIDs:allPlacementIDs];
            break;
        case INIT_STATE_SUCCESS:
            [delegate adapterRewardedVideoInitSuccess];
            break;
        case INIT_STATE_FAILED: {
            LogAdapterApi_Internal(@"init failed - placementID = %@", placementID);
            NSError *error = [NSError errorWithDomain:kAdapterName
                                                 code:ERROR_CODE_INIT_FAILED
                                             userInfo:@{NSLocalizedDescriptionKey:@"Meta SDK init failed"}];
            [delegate adapterRewardedVideoInitFailed:error];
            break;
        }
    }
}

// used for flows when the mediation doesn't need to get a callback for init
- (void)initAndLoadRewardedVideoWithUserId:(NSString *)userId
                             adapterConfig:(ISAdapterConfig *)adapterConfig
                                    adData:(NSDictionary *)adData
                                  delegate:(id<ISRewardedVideoAdapterDelegate>)delegate {
    NSString *placementID = adapterConfig.settings[kPlacementId];
    NSString *allPlacementIDs = adapterConfig.settings[kAllPlacementIds];
    
    /* Configuration Validation */
    if (![self isConfigValueValid:placementID]) {
        NSError *error = [self errorForMissingCredentialFieldWithName:kPlacementId];
        LogAdapterApi_Internal(@"error.description = %@", error.description);
        [delegate adapterRewardedVideoHasChangedAvailability:NO];
        return;
    }
    
    if (![self isConfigValueValid:allPlacementIDs]) {
        NSError *error = [self errorForMissingCredentialFieldWithName:kAllPlacementIds];
        LogAdapterApi_Internal(@"error.description = %@", error.description);
        [delegate adapterRewardedVideoHasChangedAvailability:NO];
        return;
    }
    
    //add to rewarded video delegate map
    [_rewardedVideoPlacementIdToSmashDelegate setObject:delegate
                                                 forKey:placementID];

    switch (_initState) {
        case INIT_STATE_NONE:
        case INIT_STATE_IN_PROGRESS:
            [self initSDKWithPlacementIDs:allPlacementIDs];
            break;
        case INIT_STATE_SUCCESS:
            [self loadRewardedVideoInternal:placementID
                                   delegate:delegate
                                 serverData:nil];
            break;
        case INIT_STATE_FAILED: {
            LogAdapterApi_Internal(@"init failed - placementID = %@", placementID);
            [delegate adapterRewardedVideoHasChangedAvailability:NO];
            break;
        }
    }
}

- (void)loadRewardedVideoForBiddingWithAdapterConfig:(ISAdapterConfig *)adapterConfig
                                              adData:(NSDictionary *)adData
                                          serverData:(NSString *)serverData
                                            delegate:(id<ISRewardedVideoAdapterDelegate>)delegate {
   
    NSString *placementID = adapterConfig.settings[kPlacementId];
    [self loadRewardedVideoInternal:placementID
                           delegate:delegate
                         serverData:serverData];
}

- (void)loadRewardedVideoWithAdapterConfig:(ISAdapterConfig *)adapterConfig
                                    adData:(NSDictionary *)adData
                                  delegate:(id<ISRewardedVideoAdapterDelegate>)delegate {
    NSString *placementID = adapterConfig.settings[kPlacementId];
    [self loadRewardedVideoInternal:placementID
                           delegate:delegate
                         serverData:nil];
}

- (void)loadRewardedVideoInternal:(NSString *)placementID
                         delegate:(id<ISRewardedVideoAdapterDelegate>)delegate
                       serverData:(NSString *)serverData {
    
    dispatch_async(dispatch_get_main_queue(), ^{
        LogAdapterApi_Internal(@"placementID = %@", placementID);

        @try {
            
            //add to rewarded video delegate map
            [self.rewardedVideoPlacementIdToSmashDelegate setObject:delegate
                                                         forKey:placementID];
            
            ISFacebookRewardedVideoDelegate *rewardedVideoAdDelegate = [[ISFacebookRewardedVideoDelegate alloc] initWithPlacementID:placementID
                                                                                                                        andDelegate:self];
            [self.rewardedVideoPlacementIdToFacebookAdDelegate setObject:rewardedVideoAdDelegate
                                                              	  forKey:placementID];

            FBRewardedVideoAd *rewardedVideoAd = [[FBRewardedVideoAd alloc] initWithPlacementID:placementID];
            rewardedVideoAd.delegate = rewardedVideoAdDelegate;
            
            [self.rewardedVideoPlacementIdToAd setObject:rewardedVideoAd
                                                  forKey:placementID];
            
            if (serverData == nil) {
                [rewardedVideoAd loadAd];
            } else {
                [rewardedVideoAd loadAdWithBidPayload:serverData];
            }
        } @catch (NSException *exception) {
            LogAdapterApi_Internal(@"exception = %@", exception);
            [delegate adapterRewardedVideoHasChangedAvailability:NO];
        }
    });
}

- (void)showRewardedVideoWithViewController:(UIViewController *)viewController
                              adapterConfig:(ISAdapterConfig *)adapterConfig
                                   delegate:(id<ISRewardedVideoAdapterDelegate>)delegate {

    dispatch_async(dispatch_get_main_queue(), ^{
        NSString *placementID = adapterConfig.settings[kPlacementId];
        LogAdapterApi_Internal(@"placementID = %@", placementID);

        @try {
            
            if ([self hasRewardedVideoWithAdapterConfig:adapterConfig]) {
                
                FBRewardedVideoAd *ad = [self.rewardedVideoPlacementIdToAd objectForKey:placementID];
                
                // set dynamic user id to ad if exists
                if ([self dynamicUserId]) {
                    [ad setRewardDataWithUserID:[self dynamicUserId]
                                   withCurrency:@""];
                }
                
                [ad showAdFromRootViewController:viewController];

            } else {
                NSError *error = [ISError createError:ERROR_CODE_NO_ADS_TO_SHOW
                                          withMessage:[NSString stringWithFormat: @"%@ show failed", kAdapterName]];
                [delegate adapterRewardedVideoDidFailToShowWithError:error];
            }
            
        } @catch (NSException *exception) {
            LogAdapterApi_Internal(@"exception = %@", exception);
            NSError *error = [ISError createError:ERROR_CODE_GENERIC
                                      withMessage:[NSString stringWithFormat: @"%@ show failed", kAdapterName]];
            [delegate adapterRewardedVideoDidFailToShowWithError:error];
        }
    });
}

- (BOOL)hasRewardedVideoWithAdapterConfig:(ISAdapterConfig *)adapterConfig {
    NSString *placementID = adapterConfig.settings[kPlacementId];
    FBRewardedVideoAd *rewardedVideoAd = [_rewardedVideoPlacementIdToAd objectForKey:placementID];
    return rewardedVideoAd != nil && rewardedVideoAd.adValid;
}

- (NSDictionary *)getRewardedVideoBiddingDataWithAdapterConfig:(ISAdapterConfig *)adapterConfig
                                                        adData:(NSDictionary *)adData {
    LogAdapterApi_Internal(@"");
    return [self getBiddingData];
}

#pragma mark - Rewarded Video Delegate

- (void)onRewardedVideoDidLoad:(nonnull NSString *)placementID {
    LogAdapterDelegate_Internal(@"placementID = %@", placementID);
    id<ISRewardedVideoAdapterDelegate> delegate = [_rewardedVideoPlacementIdToSmashDelegate objectForKey:placementID];
    
    if (delegate) {
        [delegate adapterRewardedVideoHasChangedAvailability:YES];
    }
}

- (void)onRewardedVideoDidFailToLoad:(nonnull NSString *)placementID
                           withError:(nullable NSError *)error {
    
    LogAdapterDelegate_Internal(@"placementID = %@, error = %@", placementID, error.description);
    id<ISRewardedVideoAdapterDelegate> delegate = [_rewardedVideoPlacementIdToSmashDelegate objectForKey:placementID];

    if (delegate) {
        
        // Report load failure
        [delegate adapterRewardedVideoHasChangedAvailability:NO];

        // For Rewarded Videos, when an adapter receives a failure reason from the network, it will pass it to the Mediation.
        if (error) {
            NSInteger errorCode = error.code == kMetaNoFillErrorCode ? ERROR_RV_LOAD_NO_FILL : error.code;
            NSError *rewardedVideoError = [NSError errorWithDomain:kAdapterName
                                                              code:errorCode
                                                          userInfo:@{NSLocalizedDescriptionKey:error.description}];
            
            [delegate adapterRewardedVideoDidFailToLoadWithError:rewardedVideoError];
        }
    }
}

- (void)onRewardedVideoDidOpen:(nonnull NSString *)placementID {
    LogAdapterDelegate_Internal(@"placementID = %@", placementID);
    id<ISRewardedVideoAdapterDelegate> delegate = [_rewardedVideoPlacementIdToSmashDelegate objectForKey:placementID];

    if (delegate) {
        [delegate adapterRewardedVideoDidOpen];
        [delegate adapterRewardedVideoDidStart];
    }
}

- (void)onRewardedVideoDidClick:(nonnull NSString *)placementID {
    LogAdapterDelegate_Internal(@"placementID = %@", placementID);
    id<ISRewardedVideoAdapterDelegate> delegate = [_rewardedVideoPlacementIdToSmashDelegate objectForKey:placementID];

    if (delegate) {
        [delegate adapterRewardedVideoDidClick];
    }
}

- (void)onRewardedVideoDidEnd:(nonnull NSString *)placementID {
    LogAdapterDelegate_Internal(@"placementID = %@", placementID);
    id<ISRewardedVideoAdapterDelegate> delegate = [_rewardedVideoPlacementIdToSmashDelegate objectForKey:placementID];

    if (delegate) {
        [delegate adapterRewardedVideoDidReceiveReward];
        [delegate adapterRewardedVideoDidEnd];
    }
}

- (void)onRewardedVideoDidClose:(nonnull NSString *)placementID {
    LogAdapterDelegate_Internal(@"placementID = %@", placementID);
    id<ISRewardedVideoAdapterDelegate> delegate = [_rewardedVideoPlacementIdToSmashDelegate objectForKey:placementID];

    if (delegate) {
        [delegate adapterRewardedVideoDidClose];
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
    
    NSString *placementID = adapterConfig.settings[kPlacementId];
    NSString *allPlacementIDs = adapterConfig.settings[kAllPlacementIds];
    
    /* Configuration Validation */
    if (![self isConfigValueValid:placementID]) {
        NSError *error = [self errorForMissingCredentialFieldWithName:kPlacementId];
        LogAdapterApi_Internal(@"error.description = %@", error.description);
        [delegate adapterInterstitialInitFailedWithError:error];
        return;
    }
    
    if (![self isConfigValueValid:allPlacementIDs]) {
        NSError *error = [self errorForMissingCredentialFieldWithName:kAllPlacementIds];
        LogAdapterApi_Internal(@"error.description = %@", error.description);
        [delegate adapterInterstitialInitFailedWithError:error];
        return;
    }
    
    LogAdapterApi_Internal(@"placementID = %@", placementID);

    //add to interstitial delegate map
    [_interstitialPlacementIdToSmashDelegate setObject:delegate
                                                forKey:placementID];
    
    switch (_initState) {
        case INIT_STATE_NONE:
        case INIT_STATE_IN_PROGRESS:
            [self initSDKWithPlacementIDs:allPlacementIDs];
            break;
        case INIT_STATE_SUCCESS:
            [delegate adapterInterstitialInitSuccess];
            break;
        case INIT_STATE_FAILED: {
            LogAdapterApi_Internal(@"init failed - placementID = %@", placementID);
            NSError *error = [NSError errorWithDomain:kAdapterName
                                                 code:ERROR_CODE_INIT_FAILED
                                             userInfo:@{NSLocalizedDescriptionKey:@"Meta SDK init failed"}];
            [delegate adapterInterstitialInitFailedWithError:error];
            break;
        }
    }
}

- (void)loadInterstitialForBiddingWithAdapterConfig:(ISAdapterConfig *)adapterConfig
                                             adData:(NSDictionary *)adData
                                         serverData:(NSString *)serverData
                                           delegate:(id<ISInterstitialAdapterDelegate>)delegate {
    
    [self loadInterstitialInternal:adapterConfig
                          delegate:delegate
                        serverData:serverData];
}

- (void)loadInterstitialWithAdapterConfig:(ISAdapterConfig *)adapterConfig
                                   adData:(NSDictionary *)adData
                                 delegate:(id<ISInterstitialAdapterDelegate>)delegate {
    [self loadInterstitialInternal:adapterConfig
                          delegate:delegate
                        serverData:nil];
}

- (void)loadInterstitialInternal:(ISAdapterConfig *)adapterConfig
                  delegate:(id<ISInterstitialAdapterDelegate>)delegate
                      serverData:(NSString *)serverData {
    
    dispatch_async(dispatch_get_main_queue(), ^{
        NSString *placementID = adapterConfig.settings[kPlacementId];
        LogAdapterApi_Internal(@"placementID = %@", placementID);
        
        @try {
            // add delegate to dictionary
            [self.interstitialPlacementIdToSmashDelegate setObject:delegate
                                                            forKey:placementID];
            
            ISFacebookInterstitialDelegate *interstitialAdDelegate = [[ISFacebookInterstitialDelegate alloc] initWithPlacementID:placementID
                                                                                                                   	 andDelegate:self];
            [self.interstitialPlacementIdToFacebookAdDelegate setObject:interstitialAdDelegate
                                                           		 forKey:placementID];

            FBInterstitialAd *interstitialAd = [[FBInterstitialAd alloc] initWithPlacementID:placementID];
            interstitialAd.delegate = interstitialAdDelegate;
            
            [self.interstitialPlacementIdToAd setObject:interstitialAd
                                                 forKey:placementID];
            
            if (serverData == nil) {
                [interstitialAd loadAd];
            } else {
                [interstitialAd loadAdWithBidPayload:serverData];
            }
        } @catch (NSException *exception) {
            LogAdapterApi_Internal(@"exception = %@", exception);
            NSError *error = [NSError errorWithDomain:kAdapterName
                                                 code:ERROR_CODE_GENERIC
                                             userInfo:@{NSLocalizedDescriptionKey:exception.description}];
            [delegate adapterInterstitialInitFailedWithError:error];
        }
    });
}

- (void)showInterstitialWithViewController:(UIViewController *)viewController
                             adapterConfig:(ISAdapterConfig *)adapterConfig
                                  delegate:(id<ISInterstitialAdapterDelegate>)delegate {
    
    dispatch_async(dispatch_get_main_queue(), ^{
        NSString *placementID = adapterConfig.settings[kPlacementId];
        LogAdapterApi_Internal(@"placementID = %@", placementID);
        
        @try {
            
            if ([self hasInterstitialWithAdapterConfig:adapterConfig]) {
                FBInterstitialAd *ad = [self.interstitialPlacementIdToAd objectForKey:placementID];
                [ad showAdFromRootViewController:viewController];
                
            } else {
                NSError *error = [ISError createError:ERROR_CODE_NO_ADS_TO_SHOW
                                          withMessage:[NSString stringWithFormat: @"%@ show failed", kAdapterName]];
                [delegate adapterInterstitialInitFailedWithError:error];
            }
            
        } @catch (NSException *exception) {
            LogAdapterApi_Internal(@"exception = %@", exception);
            NSError *error = [NSError errorWithDomain:kAdapterName
                                                 code:ERROR_CODE_GENERIC
                                             userInfo:@{NSLocalizedDescriptionKey:exception.description}];
            [delegate adapterInterstitialInitFailedWithError:error];
        }
        
    });
}

- (BOOL)hasInterstitialWithAdapterConfig:(ISAdapterConfig *)adapterConfig {
    NSString *placementID = adapterConfig.settings[kPlacementId];
    FBInterstitialAd *interstitialAd = [_interstitialPlacementIdToAd objectForKey:placementID];
    return interstitialAd != nil && interstitialAd.adValid;
}

- (NSDictionary *)getInterstitialBiddingDataWithAdapterConfig:(ISAdapterConfig *)adapterConfig
                                                       adData:(NSDictionary *)adData {
    LogAdapterApi_Internal(@"");
    return [self getBiddingData];
}

#pragma mark - Interstitial Delegate

- (void)onInterstitialDidLoad:(nonnull NSString *)placementID {
    LogAdapterDelegate_Internal(@"placementID = %@", placementID);
    id<ISInterstitialAdapterDelegate> delegate = [_interstitialPlacementIdToSmashDelegate objectForKey:placementID];

    if (delegate) {
        [delegate adapterInterstitialDidLoad];
    }
}

- (void)onInterstitialDidFailToLoad:(nonnull NSString *)placementID
                          withError:(nullable NSError *)error {
    
    LogAdapterDelegate_Internal(@"placementID = %@, error = %@", placementID, error.description);
    id<ISInterstitialAdapterDelegate> delegate = [_interstitialPlacementIdToSmashDelegate objectForKey:placementID];

    if (delegate) {
        NSInteger errorCode;
        NSString *errorReason;

        if (error) {
            errorCode = error.code == kMetaNoFillErrorCode ? ERROR_IS_LOAD_NO_FILL : error.code;
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
}

- (void)onInterstitialDidOpen:(nonnull NSString *)placementID {
    LogAdapterDelegate_Internal(@"placementID = %@", placementID);
    id<ISInterstitialAdapterDelegate> delegate = [_interstitialPlacementIdToSmashDelegate objectForKey:placementID];

    if (delegate) {
        [delegate adapterInterstitialDidOpen];
        [delegate adapterInterstitialDidShow];
    }
}

- (void)onInterstitialDidClick:(nonnull NSString *)placementID {
    LogAdapterDelegate_Internal(@"placementID = %@", placementID);
    id<ISInterstitialAdapterDelegate> delegate = [_interstitialPlacementIdToSmashDelegate objectForKey:placementID];

    if (delegate) {
        [delegate adapterInterstitialDidClick];
    }
}

- (void)onInterstitialDidClose:(nonnull NSString *)placementID {
    LogAdapterDelegate_Internal(@"placementID = %@", placementID);
    id<ISInterstitialAdapterDelegate> delegate = [_interstitialPlacementIdToSmashDelegate objectForKey:placementID];

    if (delegate) {
        [delegate adapterInterstitialDidClose];
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
    
    NSString *placementID = adapterConfig.settings[kPlacementId];
    NSString *allPlacementIDs = adapterConfig.settings[kAllPlacementIds];
    
    /* Configuration Validation */
    if (![self isConfigValueValid:placementID]) {
        NSError *error = [self errorForMissingCredentialFieldWithName:kPlacementId];
        LogAdapterApi_Internal(@"error.description = %@", error.description);
        [delegate adapterBannerInitFailedWithError:error];
        return;
    }
    
    if (![self isConfigValueValid:allPlacementIDs]) {
        NSError *error = [self errorForMissingCredentialFieldWithName:kAllPlacementIds];
        LogAdapterApi_Internal(@"error.description = %@", error.description);
        [delegate adapterBannerInitFailedWithError:error];
        return;
    }
    
    LogAdapterApi_Internal(@"placementID = %@", placementID);

    //add to banner delegate map
    [_bannerPlacementIdToSmashDelegate setObject:delegate
                                          forKey:placementID];
    
    switch (_initState) {
        case INIT_STATE_NONE:
        case INIT_STATE_IN_PROGRESS:
            [self initSDKWithPlacementIDs:allPlacementIDs];
            break;
        case INIT_STATE_SUCCESS:
            [delegate adapterBannerInitSuccess];
            break;
        case INIT_STATE_FAILED: {
            LogAdapterApi_Internal(@"init failed - placementID = %@", placementID);
            NSError *error = [NSError errorWithDomain:kAdapterName
                                                 code:ERROR_CODE_INIT_FAILED
                                             userInfo:@{NSLocalizedDescriptionKey:@"Meta SDK init failed"}];
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
    
    [self loadBannerInternal:serverData
              viewController:viewController
                        size:size
               adapterConfig:adapterConfig
                    delegate:delegate];
}

- (void)loadBannerWithAdapterConfig:(ISAdapterConfig *)adapterConfig
                             adData:(NSDictionary *)adData
                     viewController:(UIViewController *)viewController
                               size:(ISBannerSize *)size
                           delegate:(id <ISBannerAdapterDelegate>)delegate {
    
    [self loadBannerInternal:nil
              viewController:viewController
                        size:size
               adapterConfig:adapterConfig
                    delegate:delegate];
}

- (void)loadBannerInternal:(NSString *)serverData
            viewController:(UIViewController *)viewController
                      size:(ISBannerSize *)size
             adapterConfig:(ISAdapterConfig *)adapterConfig
                  delegate:(id <ISBannerAdapterDelegate>)delegate {

    NSString *placementID = adapterConfig.settings[kPlacementId];
    LogAdapterApi_Internal(@"placementID = %@", placementID);

    //add to banner delegate map
    [self.bannerPlacementIdToSmashDelegate setObject:delegate
                                              forKey:placementID];

    dispatch_async(dispatch_get_main_queue(), ^{

        @try {

            // get size
            FBAdSize fbSize = [self getBannerSize:size];
            
            // get banner frame
            CGRect bannerFrame = [self getBannerFrame:size];

            if (CGRectEqualToRect(bannerFrame, CGRectZero)) {
                NSError *error = [NSError errorWithDomain:kAdapterName
                                                     code:ERROR_BN_UNSUPPORTED_SIZE
                                                 userInfo:@{NSLocalizedDescriptionKey:@"Meta unsupported banner size"}];
                [delegate adapterBannerDidFailToLoadWithError:error];
                return;
            }
            
            ISFacebookBannerDelegate *bannerAdDelegate = [[ISFacebookBannerDelegate alloc] initWithPlacementID:placementID
                                                                                                   andDelegate:self];
            [self.bannerPlacementIdToFacebookAdDelegate setObject:bannerAdDelegate
                                                     	   forKey:placementID];

            // create banner view
            FBAdView *bannerAd = [[FBAdView alloc] initWithPlacementID:placementID
                                                                adSize:fbSize
                                                    rootViewController:viewController];
            bannerAd.frame = bannerFrame;
            
            // Set a delegate
            bannerAd.delegate = bannerAdDelegate;
            
            // add banner ad to dictionary
            [self.bannerPlacementIdToAd setObject:bannerAd
                                           forKey:placementID];
            
            // load the ad
            if (serverData == nil) {
                [bannerAd loadAd];
            } else {
                [bannerAd loadAdWithBidPayload:serverData];
            }

        } @catch (NSException *exception) {
            LogAdapterApi_Internal(@"exception = %@", exception);
            NSError *error = [NSError errorWithDomain:kAdapterName
                                                 code:ERROR_CODE_GENERIC
                                             userInfo:@{NSLocalizedDescriptionKey:exception.description}];
            [delegate adapterBannerDidFailToLoadWithError:error];
        }
    });
}

- (void)destroyBannerWithAdapterConfig:(ISAdapterConfig *)adapterConfig {
    // there is no required implementation for Meta destroy banner
}

- (NSDictionary *)getBannerBiddingDataWithAdapterConfig:(ISAdapterConfig *)adapterConfig
                                                 adData:(NSDictionary *)adData {
    LogAdapterApi_Internal(@"");
    return [self getBiddingData];
}

#pragma mark - Banner Delegate

- (void)onBannerDidLoad:(nonnull NSString *)placementID
             bannerView:(FBAdView *)bannerView {
    
    LogAdapterDelegate_Internal(@"placementID = %@", placementID);
    id<ISBannerAdapterDelegate> delegate = [_bannerPlacementIdToSmashDelegate objectForKey:placementID];

    if (delegate) {
        [delegate adapterBannerDidLoad:bannerView];
    }
}

- (void)onBannerDidFailToLoad:(nonnull NSString *)placementID
                    withError:(nullable NSError *)error {
    
    LogAdapterDelegate_Internal(@"placementID = %@, error = %@", placementID, error);
    id<ISBannerAdapterDelegate> delegate = [_bannerPlacementIdToSmashDelegate objectForKey:placementID];

    if (delegate) {
        NSInteger errorCode;
        NSString *errorReason;

        if (error) {
            errorCode = error.code == kMetaNoFillErrorCode ? ERROR_BN_LOAD_NO_FILL : error.code;
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
}

- (void)onBannerDidShow:(nonnull NSString *)placementID {
    LogAdapterDelegate_Internal(@"placementID = %@", placementID);
    id<ISBannerAdapterDelegate> delegate = [_bannerPlacementIdToSmashDelegate objectForKey:placementID];

    if (delegate) {
        [delegate adapterBannerDidShow];
    }
}

- (void)onBannerDidClick:(nonnull NSString *)placementID {
    LogAdapterDelegate_Internal(@"placementID = %@", placementID);
    id<ISBannerAdapterDelegate> delegate = [_bannerPlacementIdToSmashDelegate objectForKey:placementID];

    if (delegate) {
        [delegate adapterBannerDidClick];
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
    LogAdapterApi_Internal(@"key = %@, value = %@", key, value);
    
    NSString *formattedValue = [ISMetaDataUtils formatValue:value
                                                    forType:(META_DATA_VALUE_BOOL)];
    
    if ([ISMetaDataUtils isValidMetaDataWithKey:key
                                           flag:kMetaDataMixAudienceKey
                                       andValue:formattedValue]) {
        [self setMixedAudience:[ISMetaDataUtils getMetaDataBooleanValue:formattedValue]];
    }
}

- (void)setMixedAudience:(BOOL)isMixedAudience {
    LogAdapterApi_Internal(@"isMixedAudience = %@", isMixedAudience ? @"YES" : @"NO");
    [FBAdSettings setMixedAudience:isMixedAudience];
}

#pragma mark - Helper Methods

- (NSDictionary *)getBiddingData {
    if (_initState == INIT_STATE_FAILED) {
        LogAdapterApi_Internal(@"returning nil as token since init failed");
        return nil;
    }
    
    NSString *bidderToken = [FBAdSettings bidderToken];
    NSString *returnedToken = bidderToken ? bidderToken : @"";
    LogAdapterApi_Internal(@"token = %@", returnedToken);
    
    return @{@"token": returnedToken};
}

- (FBAdSize)getBannerSize:(ISBannerSize *)size {
    // Initing the banner size so it will have a default value. Since FBAdSize doesn't support CGSizeZero we used the default banner size isntead
    FBAdSize fbSize = kFBAdSizeHeight50Banner;
    
    if ([size.sizeDescription isEqualToString:@"BANNER"]) {
        fbSize = kFBAdSizeHeight50Banner;
    } else if ([size.sizeDescription isEqualToString:@"LARGE"]) {
        fbSize = kFBAdSizeHeight90Banner;
    } else if ([size.sizeDescription isEqualToString:@"RECTANGLE"]) {
        fbSize = kFBAdSizeHeight250Rectangle;
    } else if ([size.sizeDescription isEqualToString:@"SMART"]) {
        if (UI_USER_INTERFACE_IDIOM() == UIUserInterfaceIdiomPad) {
            fbSize = kFBAdSizeHeight90Banner;
        } else {
            fbSize = kFBAdSizeHeight50Banner;
        }
    } else if ([size.sizeDescription isEqualToString:@"CUSTOM"]) {
        if (size.height == 50) {
            fbSize = kFBAdSizeHeight50Banner;
        } else if (size.height == 90) {
            fbSize = kFBAdSizeHeight90Banner;
        } else if (size.height == 250) {
            fbSize = kFBAdSizeHeight250Rectangle;
        }
    }
    
    return fbSize;
}

- (CGRect)getBannerFrame:(ISBannerSize *)size {
    CGRect rect = CGRectZero;

    if ([size.sizeDescription isEqualToString:@"BANNER"]) {
        rect = CGRectMake(0, 0, 320, 50);
    } else if ([size.sizeDescription isEqualToString:@"LARGE"]) {
        rect = CGRectMake(0, 0, 320, 90);
    } else if ([size.sizeDescription isEqualToString:@"RECTANGLE"]) {
        rect = CGRectMake(0, 0, 300, 250);
    } else if ([size.sizeDescription isEqualToString:@"SMART"]) {
        if (UI_USER_INTERFACE_IDIOM() == UIUserInterfaceIdiomPad) {
            rect = CGRectMake(0, 0, 728, 90);
        } else {
            rect = CGRectMake(0, 0, 320, 50);
        }
    } else if ([size.sizeDescription isEqualToString:@"CUSTOM"]) {
        if (size.height == 50) {
            rect = CGRectMake(0, 0, 320, 50);
        } else if (size.height == 90) {
            rect = CGRectMake(0, 0, 320, 90);
        } else if (size.height == 250) {
            rect = CGRectMake(0, 0, 300, 250);
        }
    }
    
    return rect;
}

- (NSString *)getMediationService {
    if (!_mediationService) {
        _mediationService = [NSString stringWithFormat:@"%@_%@:%@", kMediationName, [IronSource sdkVersion], kAdapterVersion];
        LogAdapterApi_Internal(@"mediationService = %@", _mediationService);
    }
    
    return _mediationService;
}

@end
