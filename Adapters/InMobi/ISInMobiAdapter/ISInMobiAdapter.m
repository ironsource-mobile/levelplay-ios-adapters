//
//  ISInMobiAdapter.m
//  ISInMobiAdapter
//
//  Copyright © 2024 ironSource Mobile Ltd. All rights reserved.
//

#import <ISInMobiAdapter.h>
#import <ISInMobiRewardedVideoDelegate.h>
#import <ISInMobiInterstitialDelegate.h>
#import <ISInMobiBannerDelegate.h>
#import <InMobiSDK/InMobiSDK.h>

// Network keys
static NSString * const kAdapterVersion             = InMobiAdapterVersion;
static NSString * const kAdapterName                = @"InMobi";
static NSString * const kAccountId                  = @"accountId";
static NSString * const kPlacementId                = @"placementId";
static NSString * const kToken                      = @"token";
static NSString * const kTP                         = @"tp";
static NSString * const kCUnitylevelplay            = @"c_unitylevelplay";
static NSString * const kTPVersion                  = @"tp-ver";

// Meta data flags
static NSString * const kMetaDataAgeRestrictedKey   = @"inMobi_AgeRestricted";
static NSString * const kInMobiDoNotSellKey         = @"do_not_sell";

// Consent and metadata
static NSString *consentCollectingUserData = nil;
static BOOL      isAgeRestrictionCollectingUserData = nil;
static NSNumber *doNotSellCollectingUserData = nil;

// Handle init callback for all adapter instances
static ISConcurrentMutableSet<ISNetworkInitCallbackProtocol> *initCallbackDelegates = nil;

// Init state
typedef NS_ENUM(NSInteger, InitState) {
    INIT_STATE_NONE,
    INIT_STATE_IN_PROGRESS,
    INIT_STATE_FAILED,
    INIT_STATE_SUCCESS
};

static InitState initState = INIT_STATE_NONE;

@interface ISInMobiAdapter () <ISInMobiRewardedVideoDelegateWrapper, ISInMobiInterstitialDelegateWrapper, ISInMobiBannerDelegateWrapper, ISNetworkInitCallbackProtocol>

// Rewarded Video
@property (nonatomic, strong) ISConcurrentMutableDictionary *placementIdToRewardedVideoAd;
@property (nonatomic, strong) ISConcurrentMutableDictionary *placementIdToRewardedVideoDelegate;
@property (nonatomic, strong) ISConcurrentMutableDictionary *placementIdToRewardedVideoSmashDelegate;
@property (nonatomic, strong) ISConcurrentMutableSet        *rewardedVideoPlacementIdsForInitCallbacks;

// Interstitial
@property (nonatomic, strong) ISConcurrentMutableDictionary *placementIdToInterstitialAd;
@property (nonatomic, strong) ISConcurrentMutableDictionary *placementIdToInterstitialDelegate;
@property (nonatomic, strong) ISConcurrentMutableDictionary *placementIdToInterstitialSmashDelegate;

// Banner
@property (nonatomic, strong) ISConcurrentMutableDictionary *placementIdToBannerAd;
@property (nonatomic, strong) ISConcurrentMutableDictionary *placementIdToBannerDelegate;
@property (nonatomic, strong) ISConcurrentMutableDictionary *placementIdToBannerSmashDelegate;

@end

@implementation ISInMobiAdapter

#pragma mark - IronSource Protocol Methods

- (NSString *)version {
    return kAdapterVersion;
}

- (NSString *)sdkVersion {
    return [IMSdk getVersion];
}

#pragma mark - Initializations Methods And Callbacks

- (instancetype)initAdapter:(NSString *)name
{
    self = [super initAdapter:name];
    if (self) {
        // only initiated once for all instances
        if (initCallbackDelegates == nil) {
            initCallbackDelegates = [ISConcurrentMutableSet<ISNetworkInitCallbackProtocol> set];
        }
        
        // Rewarded Video
        self.placementIdToRewardedVideoAd = [ISConcurrentMutableDictionary dictionary];
        self.placementIdToRewardedVideoDelegate = [ISConcurrentMutableDictionary dictionary];
        self.placementIdToRewardedVideoSmashDelegate = [ISConcurrentMutableDictionary dictionary];
        self.rewardedVideoPlacementIdsForInitCallbacks = [ISConcurrentMutableSet set];
        
        // Interstitial
        self.placementIdToInterstitialAd = [ISConcurrentMutableDictionary dictionary];
        self.placementIdToInterstitialDelegate = [ISConcurrentMutableDictionary dictionary];
        self.placementIdToInterstitialSmashDelegate = [ISConcurrentMutableDictionary dictionary];
        
        // Banner
        self.placementIdToBannerAd = [ISConcurrentMutableDictionary dictionary];
        self.placementIdToBannerDelegate = [ISConcurrentMutableDictionary dictionary];
        self.placementIdToBannerSmashDelegate = [ISConcurrentMutableDictionary dictionary];
        
        // The network's capability to load a Rewarded Video ad while another Rewarded Video ad of that network is showing
        LWSState = LOAD_WHILE_SHOW_BY_INSTANCE;
    }
    
    return self;
}

- (void)initSDKWithAccountId:(NSString *)accountId {
    
    // Add to init delegates only when init is not finished yet
    if (initState == INIT_STATE_NONE ||
        initState == INIT_STATE_IN_PROGRESS) {
        [initCallbackDelegates addObject:self];
    }
    
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        if (initState == INIT_STATE_NONE) {
            initState = INIT_STATE_IN_PROGRESS;
            
            BOOL isAdapterDebug = [ISConfigurations getConfigurations].adaptersDebug;
            [IMSdk setLogLevel: isAdapterDebug ? IMSDKLogLevelDebug : IMSDKLogLevelNone];
            
            NSString *message = [NSString stringWithFormat:@"ISInMobiAdapter:setLogLevel:%@",(isAdapterDebug ? @"YES" : @"NO")];
            LogAdapterApi_Internal(@"setLogLevel - message = %@", message);
            
            ISInMobiAdapter * __weak weakSelf = self;
            [IMSdk initWithAccountID:accountId
                   consentDictionary:[self getConsentDictionary]
                andCompletionHandler:^(NSError *error) {
                if (error == nil) {
                    [weakSelf initSuccess];
                } else {
                    NSString *errorMsg = [NSString stringWithFormat:@"InMobi SDK init failed %@", error ? error.description : @""];
                    [weakSelf initFailedWithError:errorMsg];
                }
            }];
        }
    });
}

- (void)initSuccess {
    LogAdapterDelegate_Internal(@"");
    
    initState = INIT_STATE_SUCCESS;
    
    NSArray *initDelegatesList = initCallbackDelegates.allObjects;
    for (id<ISNetworkInitCallbackProtocol> delegate in initDelegatesList) {
        [delegate onNetworkInitCallbackSuccess];
    }
    
    [initCallbackDelegates removeAllObjects];
}

- (void)initFailedWithError:(NSString *)errorMsg {
    LogAdapterDelegate_Internal(@"error = %@", errorMsg);
    
    initState = INIT_STATE_FAILED;
    
    NSArray *initDelegatesList = initCallbackDelegates.allObjects;
    for (id<ISNetworkInitCallbackProtocol> delegate in initDelegatesList) {
        [delegate onNetworkInitCallbackFailed:errorMsg];
    }
    
    [initCallbackDelegates removeAllObjects];
}

- (void)onNetworkInitCallbackSuccess {
    if (consentCollectingUserData != nil) {
        [self setAgeRestricted:consentCollectingUserData];
    }
    
    // Rewarded video
    NSArray *rewardedVideoPlacementIDs = self.placementIdToRewardedVideoSmashDelegate.allKeys;
    for (NSString* placementId in rewardedVideoPlacementIDs) {
        id<ISRewardedVideoAdapterDelegate> delegate = [self.placementIdToRewardedVideoSmashDelegate objectForKey:placementId];
        if ([self.rewardedVideoPlacementIdsForInitCallbacks hasObject:placementId]) {
            [delegate adapterRewardedVideoInitSuccess];
        } else {
            [self loadRewardedVideoInternalWithPlacementId:placementId
                                                serverData:nil
                                                  delegate:delegate];
        }
    }
    
    // Interstitial
    NSArray *interstitialPlacementIDs = self.placementIdToInterstitialSmashDelegate.allKeys;
    for (NSString *placementId in interstitialPlacementIDs) {
        id<ISInterstitialAdapterDelegate> delegate = [self.placementIdToInterstitialSmashDelegate objectForKey:placementId];
        [delegate adapterInterstitialInitSuccess];
    }
    
    // Banners
    NSArray *bannerPlacementIDs = self.placementIdToBannerSmashDelegate.allKeys;
    for (NSString *placementId in bannerPlacementIDs) {
        id<ISBannerAdapterDelegate> delegate = [self.placementIdToBannerSmashDelegate objectForKey:placementId];
        [delegate adapterBannerInitSuccess];
    }
}

- (void)onNetworkInitCallbackFailed:(nonnull NSString *)errorMessage {
    NSError *error = [ISError createErrorWithDomain:kAdapterName
                                               code:ERROR_CODE_INIT_FAILED
                                            message:errorMessage];
    // Rewarded video
    NSArray *rewardedVideoPlacementIDs = self.placementIdToRewardedVideoSmashDelegate.allKeys;
    for (NSString* placementId in rewardedVideoPlacementIDs) {
        id<ISRewardedVideoAdapterDelegate> delegate = [self.placementIdToRewardedVideoSmashDelegate objectForKey:placementId];
        if ([self.rewardedVideoPlacementIdsForInitCallbacks hasObject:placementId]) {
            [delegate adapterRewardedVideoInitFailed:error];
        } else {
            [delegate adapterRewardedVideoHasChangedAvailability:NO];
        }
    }
    
    // Interstitial
    NSArray *interstitialPlacementIDs = self.placementIdToInterstitialSmashDelegate.allKeys;
    for (NSString *placementId in interstitialPlacementIDs) {
        id<ISInterstitialAdapterDelegate> delegate = [self.placementIdToInterstitialSmashDelegate objectForKey:placementId];
        [delegate adapterInterstitialInitFailedWithError:error];
    }
    
    // Banners
    NSArray *bannerPlacementIDs = self.placementIdToBannerSmashDelegate.allKeys;
    for (NSString *placementId in bannerPlacementIDs) {
        id<ISBannerAdapterDelegate> delegate = [self.placementIdToBannerSmashDelegate objectForKey:placementId];
        [delegate adapterBannerInitFailedWithError:error];
    }
}

#pragma mark - Rewarded Video API

- (void)initRewardedVideoForCallbacksWithUserId:(NSString *)userId
                                  adapterConfig:(ISAdapterConfig *)adapterConfig
                                       delegate:(id<ISRewardedVideoAdapterDelegate>)delegate {
    NSString *placementId = adapterConfig.settings[kPlacementId];
    NSString *accountId = adapterConfig.settings[kAccountId];
    
    // Verified placementId
    if (![self isConfigValueValid:placementId]) {
        NSError *error = [self errorForMissingCredentialFieldWithName:kPlacementId];
        LogAdapterApi_Internal(@"error = %@", error);
        
        [delegate adapterRewardedVideoInitFailed:error];
        return;
    }
    
    // Verified accountId
    if (![self isConfigValueValid:accountId]) {
        NSError *error = [self errorForMissingCredentialFieldWithName:kAccountId];
        LogAdapterApi_Internal(@"error = %@", error);
        
        [delegate adapterRewardedVideoInitFailed:error];
        return;
    }
    
    LogAdapterApi_Internal(@"accountId = %@, placementId = %@", accountId, placementId);
    
    [self.placementIdToRewardedVideoSmashDelegate setObject:delegate
                                                     forKey:placementId];
    
    [self.rewardedVideoPlacementIdsForInitCallbacks addObject:placementId];
    
    // Handle init state if already initialized
    switch (initState) {
        case INIT_STATE_NONE:
        case INIT_STATE_IN_PROGRESS:{
            dispatch_async(dispatch_get_main_queue(), ^{
                [self initSDKWithAccountId:accountId];
            });
            
            break;
        }
        case INIT_STATE_FAILED:{
            NSError *error = [NSError errorWithDomain:kAdapterName
                                                 code:ERROR_CODE_INIT_FAILED
                                             userInfo:@{NSLocalizedDescriptionKey:@"InMobi SDK Init Failed"}];
            LogAdapterApi_Internal(@"error = %@", error);
            
            [delegate adapterRewardedVideoInitFailed:error];
            break;
        }
        case INIT_STATE_SUCCESS:
            LogAdapterApi_Internal(@"init rewarded video: INIT_STATE_SUCCESS");
            
            [delegate adapterRewardedVideoInitSuccess];
            break;
    }
}

- (void)initAndLoadRewardedVideoWithUserId:(NSString *)userId
                             adapterConfig:(ISAdapterConfig *)adapterConfig
                                    adData:(NSDictionary *)adData
                                  delegate:(id<ISRewardedVideoAdapterDelegate>)delegate {
    NSString *placementId = adapterConfig.settings[kPlacementId];
    NSString *accountId = adapterConfig.settings[kAccountId];
    
    // Verified placementId
    if (![self isConfigValueValid:placementId]) {
        NSError *error = [self errorForMissingCredentialFieldWithName:kPlacementId];
        LogAdapterApi_Internal(@"error = %@", error);
        
        [delegate adapterRewardedVideoHasChangedAvailability:NO];
        return;
    }
    
    // Verified accountId
    if (![self isConfigValueValid:accountId]) {
        NSError *error = [self errorForMissingCredentialFieldWithName:kAccountId];
        LogAdapterApi_Internal(@"error = %@", error);
        
        [delegate adapterRewardedVideoHasChangedAvailability:NO];
        return;
    }
    
    LogAdapterApi_Internal(@"accountId = %@, placementId = %@", accountId, placementId);
    
    [self.placementIdToRewardedVideoSmashDelegate setObject:delegate
                                                     forKey:placementId];
    
    // Handle init state if already initialized
    switch (initState) {
        case INIT_STATE_NONE:
        case INIT_STATE_IN_PROGRESS:{
            dispatch_async(dispatch_get_main_queue(), ^{
                [self initSDKWithAccountId:accountId];
            });
            
            break;
        }
        case INIT_STATE_FAILED:{
            NSError *error = [NSError errorWithDomain:kAdapterName
                                                 code:ERROR_CODE_INIT_FAILED
                                             userInfo:@{NSLocalizedDescriptionKey:@"InMobi SDK Init Failed"}];
            LogAdapterApi_Internal(@"error = %@", error);
            
            [delegate adapterRewardedVideoHasChangedAvailability:NO];
        }
        case INIT_STATE_SUCCESS:
            LogAdapterApi_Internal(@"init rewarded video: INIT_STATE_SUCCESS");
            
            [self loadRewardedVideoInternalWithPlacementId:placementId
                                                serverData:nil
                                                  delegate:delegate];
    }
}

- (void)loadRewardedVideoForBiddingWithAdapterConfig:(ISAdapterConfig *)adapterConfig
                                              adData:(NSDictionary *)adData
                                          serverData:(NSString *)serverData
                                            delegate:(id<ISRewardedVideoAdapterDelegate>)delegate {
    NSString *placementId = adapterConfig.settings[kPlacementId];
    [self loadRewardedVideoInternalWithPlacementId:placementId
                                        serverData:serverData
                                          delegate:delegate];
}

- (void)loadRewardedVideoWithAdapterConfig:(ISAdapterConfig *)adapterConfig
                                    adData:(NSDictionary *)adData
                                  delegate:(id<ISRewardedVideoAdapterDelegate>)delegate {
    NSString *placementId = adapterConfig.settings[kPlacementId];
    [self loadRewardedVideoInternalWithPlacementId:placementId
                                        serverData:nil
                                          delegate:delegate];
}

- (void)loadRewardedVideoInternalWithPlacementId:(NSString*)placementId
                                      serverData:(NSString *)serverData
                                        delegate:(id<ISRewardedVideoAdapterDelegate>) delegate {
    LogAdapterApi_Internal(@"placementId = %@", placementId);
    
    [self.placementIdToRewardedVideoSmashDelegate setObject:delegate
                                                     forKey:placementId];
    dispatch_async(dispatch_get_main_queue(), ^{

        ISInMobiRewardedVideoDelegate *rewardedVideoAdDelegate = [[ISInMobiRewardedVideoDelegate alloc] initWithPlacementId:placementId
                                                                                                                   delegate:self];
        [self.placementIdToRewardedVideoDelegate setObject:rewardedVideoAdDelegate
                                                    forKey:placementId];
        
        IMInterstitial* rewardedAd = [[IMInterstitial alloc] initWithPlacementId:[placementId longLongValue]
                                                                        delegate:rewardedVideoAdDelegate];
        if (rewardedAd != nil) {
            [self.placementIdToRewardedVideoAd setObject:rewardedAd
                                                  forKey:placementId];
            
            if (serverData == nil) {
                rewardedAd.extras = [self extras];
                [rewardedAd load];
            } else {
                NSData* data = [serverData dataUsingEncoding:NSUTF8StringEncoding];
                [rewardedAd load:data];
            }
        } else {
            NSError *error = [NSError errorWithDomain:kAdapterName
                                                 code:ERROR_CODE_GENERIC
                                             userInfo:@{NSLocalizedDescriptionKey:@"rewardedAd ad is nil - can't continue"}];
            LogAdapterApi_Internal(@"error = %@", error);
            
            id<ISRewardedVideoAdapterDelegate> delegate = [self.placementIdToRewardedVideoSmashDelegate objectForKey:placementId];
            [delegate adapterRewardedVideoHasChangedAvailability:NO];
        }
    });
}

- (void)showRewardedVideoWithViewController:(UIViewController *)viewController
                              adapterConfig:(ISAdapterConfig *)adapterConfig
                                   delegate:(id<ISRewardedVideoAdapterDelegate>)delegate {
    NSString *placementId = adapterConfig.settings[kPlacementId];
    LogAdapterApi_Internal(@"placementId = %@", placementId);
    
    IMInterstitial* rewardedAd = [self.placementIdToRewardedVideoAd objectForKey:placementId];
    
    if (![self hasRewardedVideoWithAdapterConfig:adapterConfig]) {
        NSError *error = [NSError errorWithDomain:kAdapterName
                                             code:ERROR_CODE_GENERIC
                                         userInfo:@{NSLocalizedDescriptionKey:@"show failed, rewardedAd isn't ready"}];
        LogAdapterApi_Internal(@"error = %@", error);
        
        [delegate adapterRewardedVideoDidFailToShowWithError:error];
        return;
    }
    
    dispatch_async(dispatch_get_main_queue(), ^{
        [rewardedAd showFrom:viewController];
    });
}

- (BOOL)hasRewardedVideoWithAdapterConfig:(ISAdapterConfig *)adapterConfig {
    NSString *placementId = adapterConfig.settings[kPlacementId];
    
    IMInterstitial* rewardedAd = [self.placementIdToRewardedVideoAd objectForKey:placementId];
    
    return (rewardedAd != nil &&
            [rewardedAd isReady]);
}

- (NSDictionary *)getRewardedVideoBiddingDataWithAdapterConfig:(ISAdapterConfig *)adapterConfig
                                                        adData:(NSDictionary *)adData {
    return [self getBiddingData];
}

#pragma mark - Rewarded Video Delegate

- (void)onRewardedVideoDidLoad:(IMInterstitial *)rewardedVideo
                   placementId:(NSString *)placementId {
    LogAdapterDelegate_Internal(@"placementId = %@", placementId);
    
    id<ISRewardedVideoAdapterDelegate> delegate = [self.placementIdToRewardedVideoSmashDelegate objectForKey:placementId];
    [delegate adapterRewardedVideoHasChangedAvailability:YES];
}

- (void)onRewardedVideoDidFailToLoad:(IMInterstitial *)rewardedVideo
                               error:(IMRequestStatus *)error
                         placementId:(NSString *)placementId {
    LogAdapterDelegate_Internal(@"placementId = %@, error = %@", placementId, error);
    
    id<ISRewardedVideoAdapterDelegate> delegate = [self.placementIdToRewardedVideoSmashDelegate objectForKey:placementId];
    NSError *smashError = nil;
    if (error.code == IMStatusCodeNoFill){
        // No fill
        smashError = [NSError errorWithDomain:kAdapterName
                                         code:ERROR_RV_LOAD_NO_FILL
                                     userInfo:@{NSLocalizedDescriptionKey:@"no fill"}];
    } else {
        smashError = error;
    }
    
    [delegate adapterRewardedVideoHasChangedAvailability:NO];
    [delegate adapterRewardedVideoDidFailToLoadWithError:smashError];
}

- (void)onRewardedVideoDidOpen:(IMInterstitial *)rewardedVideo
                   placementId:(NSString *)placementId{
    LogAdapterDelegate_Internal(@"placementId = %@", placementId);
    
    id<ISRewardedVideoAdapterDelegate> delegate = [self.placementIdToRewardedVideoSmashDelegate objectForKey:placementId];
    [delegate adapterRewardedVideoDidOpen];
}

- (void)onRewardedVideoDidFailToShow:(IMInterstitial *)rewardedVideo
                               error:(IMRequestStatus *)error
                         placementId:(NSString *)placementId{
    LogAdapterDelegate_Internal(@"placementId = %@, error = %@", placementId, error);
    
    id<ISRewardedVideoAdapterDelegate> delegate = [self.placementIdToRewardedVideoSmashDelegate objectForKey:placementId];
    [delegate adapterRewardedVideoDidFailToShowWithError:error];
}

- (void)onRewardedVideoDidClick:(IMInterstitial *)rewardedVideo
                         params:(NSDictionary *)params
                    placementId:(NSString *)placementId {
    LogAdapterDelegate_Internal(@"placementId = %@", placementId);
    
    id<ISRewardedVideoAdapterDelegate> delegate = [self.placementIdToRewardedVideoSmashDelegate objectForKey:placementId];
    [delegate adapterRewardedVideoDidClick];
}

- (void)onRewardedVideoDidClose:(IMInterstitial *)rewardedVideo
                    placementId:(NSString *)placementId{
    LogAdapterDelegate_Internal(@"placementId = %@", placementId);
    
    id<ISRewardedVideoAdapterDelegate> delegate = [self.placementIdToRewardedVideoSmashDelegate objectForKey:placementId];
    [delegate adapterRewardedVideoDidClose];
}

- (void)onRewardedVideoDidReceiveReward:(IMInterstitial *)rewardedVideo
                                rewards:(NSDictionary *)rewards
                            placementId:(NSString *)placementId {
    LogAdapterDelegate_Internal(@"placementId = %@", placementId);
    
    id<ISRewardedVideoAdapterDelegate> delegate = [self.placementIdToRewardedVideoSmashDelegate objectForKey:placementId];
    [delegate adapterRewardedVideoDidReceiveReward];
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
    NSString *placementId = adapterConfig.settings[kPlacementId];
    NSString *accountId = adapterConfig.settings[kAccountId];
    
    // Verify placementId
    if (![self isConfigValueValid:placementId]) {
        NSError *error = [self errorForMissingCredentialFieldWithName:kPlacementId];
        LogAdapterApi_Internal(@"error = %@", error);
        
        [delegate adapterInterstitialInitFailedWithError:error];
        return;
    }
    
    // Verify accountId
    if (![self isConfigValueValid:accountId]) {
        NSError *error = [self errorForMissingCredentialFieldWithName:kAccountId];
        LogAdapterApi_Internal(@"error = %@", error);
        
        [delegate adapterInterstitialInitFailedWithError:error];
        return;
    }
    
    LogAdapterApi_Internal(@"accountId = %@, placementId = %@", accountId, placementId);
    
    [self.placementIdToInterstitialSmashDelegate setObject:delegate
                                                    forKey:placementId];
    
    // Handle init state if already initialized
    switch (initState) {
        case INIT_STATE_NONE:
        case INIT_STATE_IN_PROGRESS:{
            dispatch_async(dispatch_get_main_queue(), ^{
                [self initSDKWithAccountId:accountId];
            });
            
            break;
        }
        case INIT_STATE_FAILED:{
            NSError *error = [NSError errorWithDomain:kAdapterName
                                                 code:ERROR_CODE_INIT_FAILED
                                             userInfo:@{NSLocalizedDescriptionKey:@"InMobi SDK Init Failed"}];
            LogAdapterApi_Internal(@"error = %@", error);
            break;
        }
        case INIT_STATE_SUCCESS:
            LogAdapterApi_Internal(@"init interstitial: INIT_STATE_SUCCESS");
            
            [delegate adapterInterstitialInitSuccess];
            break;
    }
}

- (void)loadInterstitialForBiddingWithAdapterConfig:(ISAdapterConfig *)adapterConfig
                                             adData:(NSDictionary *)adData
                                         serverData:(NSString *)serverData
                                           delegate:(id<ISInterstitialAdapterDelegate>)delegate {
    NSString *placementId = adapterConfig.settings[kPlacementId];
    [self loadInterstitialInternalWithDelegate:delegate
                                   placementId:placementId
                                    serverData:serverData];
}

- (void)loadInterstitialWithAdapterConfig:(ISAdapterConfig *)adapterConfig
                                   adData:(NSDictionary *)adData
                                 delegate:(id<ISInterstitialAdapterDelegate>)delegate {
    NSString *placementId = adapterConfig.settings[kPlacementId];
    [self loadInterstitialInternalWithDelegate:delegate
                                   placementId:placementId
                                    serverData:nil];
}

- (void)loadInterstitialInternalWithDelegate:(id<ISInterstitialAdapterDelegate>)delegate
                                 placementId:(NSString *)placementId
                                  serverData:(NSString *)serverData {
    LogAdapterApi_Internal(@"placementId = %@", placementId);
    
    [self.placementIdToInterstitialSmashDelegate setObject:delegate
                                                    forKey:placementId];
    
    dispatch_async(dispatch_get_main_queue(), ^{
        LogAdapterApi_Internal(@"interstitial create ad");
        
        ISInMobiInterstitialDelegate *interstitialAdDelegate = [[ISInMobiInterstitialDelegate alloc] initWithPlacementId:placementId
                                                                                                                delegate:self];
        [self.placementIdToInterstitialDelegate setObject:interstitialAdDelegate
                                                   forKey:placementId];
        
        // Create interstitial ad
        IMInterstitial* inMobiInterstitial = [[IMInterstitial alloc] initWithPlacementId:[placementId longLongValue]
                                                                                delegate:interstitialAdDelegate];
        
        if (inMobiInterstitial != nil) {
            // Add to dictionary
            [self.placementIdToInterstitialAd setObject:inMobiInterstitial
                                                 forKey:placementId];
            
            // Load ad
            if (serverData == nil) {
                inMobiInterstitial.extras = [self extras];
                [inMobiInterstitial load];
            } else {
                NSData* data = [serverData dataUsingEncoding:NSUTF8StringEncoding];
                [inMobiInterstitial load:data];
            }
        } else {
            NSError *error = [NSError errorWithDomain:kAdapterName
                                                 code:ERROR_CODE_GENERIC
                                             userInfo:@{NSLocalizedDescriptionKey:@"inMobiInterstitial ad is nil - can't continue"}];
            LogAdapterApi_Internal(@"error = %@", error);
            
            [delegate adapterInterstitialDidFailToLoadWithError:error];
        }
    });
}

- (void)showInterstitialWithViewController:(UIViewController *)viewController
                             adapterConfig:(ISAdapterConfig *)adapterConfig
                                  delegate:(id<ISInterstitialAdapterDelegate>)delegate {
    NSString *placementId = adapterConfig.settings[kPlacementId];
    LogAdapterApi_Internal(@"placementId = %@", placementId);
    
    IMInterstitial* inMobiInterstitial = [_placementIdToInterstitialAd objectForKey:placementId];
    
    if (![self hasInterstitialWithAdapterConfig:adapterConfig]) {
        NSString *message = @"inMobiInterstitial is not ready";
        NSError *error = [NSError errorWithDomain:@"ISInMobiAdapter"
                                             code:ERROR_CODE_GENERIC
                                         userInfo:@{NSLocalizedDescriptionKey : message}];
        LogAdapterApi_Internal(@"error = %@", error);
        
        [delegate adapterInterstitialDidFailToShowWithError:error];
        return;
    }
    
    dispatch_async(dispatch_get_main_queue(), ^{
        [inMobiInterstitial showFrom:viewController];
    });
}

- (BOOL)hasInterstitialWithAdapterConfig:(ISAdapterConfig *)adapterConfig {
    NSString *placementId = adapterConfig.settings[kPlacementId];
    
    IMInterstitial* inMobiInterstitial = [_placementIdToInterstitialAd objectForKey:placementId];
    
    return (inMobiInterstitial != nil &&
            [inMobiInterstitial isReady]);
}

- (NSDictionary *)getInterstitialBiddingDataWithAdapterConfig:(ISAdapterConfig *)adapterConfig
                                                       adData:(NSDictionary *)adData {
    return [self getBiddingData];
}

#pragma mark - Interstitial Delegate

- (void)onInterstitialDidLoad:(IMInterstitial *)interstitial
                  placementId:(NSString *)placementId {
    LogAdapterDelegate_Internal(@"placementId = %@", placementId);
    
    id<ISInterstitialAdapterDelegate> delegate = [self.placementIdToInterstitialSmashDelegate objectForKey:placementId];
    [delegate adapterInterstitialDidLoad];
}

- (void)onInterstitialDidFailToLoad:(IMInterstitial *)interstitial
                              error:(IMRequestStatus *)error
                        placementId:(NSString *)placementId {
    LogAdapterDelegate_Internal(@"placementId = %@, error = %@", placementId, error);
    
    id<ISInterstitialAdapterDelegate> delegate = [self.placementIdToInterstitialSmashDelegate objectForKey:placementId];
    NSError *smashError = nil;
    if (error.code == IMStatusCodeNoFill){
        // no fill
        smashError = [NSError errorWithDomain:kAdapterName
                                         code:ERROR_IS_LOAD_NO_FILL
                                     userInfo:@{NSLocalizedDescriptionKey:@"no fill"}];
    } else {
        smashError = error;
    }
    
    [delegate adapterInterstitialDidFailToLoadWithError:smashError];
}

- (void)onInterstitialDidOpen:(IMInterstitial *)interstitial
                  placementId:(NSString *)placementId {
    LogAdapterDelegate_Internal(@"placementId = %@", placementId);
    
    id<ISInterstitialAdapterDelegate> delegate = [self.placementIdToInterstitialSmashDelegate objectForKey:placementId];
    [delegate adapterInterstitialDidOpen];
    [delegate adapterInterstitialDidShow];
}

- (void)onInterstitialDidFailToShow:(IMInterstitial *)interstitial
                              error:(IMRequestStatus *)error
                        placementId:(NSString *)placementId {
    LogAdapterDelegate_Internal(@"placementId = %@, error = %@", placementId, error);
    
    id<ISInterstitialAdapterDelegate> delegate = [self.placementIdToInterstitialSmashDelegate objectForKey:placementId];
    [delegate adapterInterstitialDidFailToShowWithError:error];
}

- (void)onInterstitialDidClick:(IMInterstitial *)interstitial
                        params:(NSDictionary *)params
                   placementId:(NSString *)placementId {
    LogAdapterDelegate_Internal(@"placementId = %@", placementId);
    
    id<ISInterstitialAdapterDelegate> delegate = [self.placementIdToInterstitialSmashDelegate objectForKey:placementId];
    [delegate adapterInterstitialDidClick];
}

- (void)onInterstitialDidClose:(IMInterstitial *)interstitial
                   placementId:(NSString *)placementId {
    LogAdapterDelegate_Internal(@"placementId = %@", placementId);
    
    id<ISInterstitialAdapterDelegate> delegate = [self.placementIdToInterstitialSmashDelegate objectForKey:placementId];
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

- (void)initBannerWithUserId:(nonnull NSString *)userId
               adapterConfig:(nonnull ISAdapterConfig *)adapterConfig
                    delegate:(nonnull id<ISBannerAdapterDelegate>)delegate {
    NSString *placementId = adapterConfig.settings[kPlacementId];
    NSString *accountId = adapterConfig.settings[kAccountId];
    
    // Verify placementId
    if (![self isConfigValueValid:placementId]) {
        NSError *error = [self errorForMissingCredentialFieldWithName:kPlacementId];
        LogAdapterApi_Internal(@"error = %@", error);
        
        [delegate adapterBannerInitFailedWithError:error];
        return;
    }
    
    // Verify accountId
    if (![self isConfigValueValid:accountId]) {
        NSError *error = [self errorForMissingCredentialFieldWithName:kAccountId];
        LogAdapterApi_Internal(@"error = %@", error);
        
        [delegate adapterBannerInitFailedWithError:error];
        return;
    }
    
    LogAdapterApi_Internal(@"accountId = %@, placementId = %@", accountId, placementId);
    
    [self.placementIdToBannerSmashDelegate setObject:delegate
                                              forKey:placementId];

    // Handle init state if already initialized
    switch (initState) {
        case INIT_STATE_NONE:
        case INIT_STATE_IN_PROGRESS:{
            dispatch_async(dispatch_get_main_queue(), ^{
                [self initSDKWithAccountId:accountId];
            });
            
            break;
        }
        case INIT_STATE_FAILED:{
            NSError *error = [NSError errorWithDomain:kAdapterName
                                                 code:ERROR_CODE_INIT_FAILED
                                             userInfo:@{NSLocalizedDescriptionKey:@"InMobi SDK Init Failed"}];
            LogAdapterApi_Internal(@"error = %@", error);
            break;
        }
        case INIT_STATE_SUCCESS:
            LogAdapterApi_Internal(@"init banner: INIT_STATE_SUCCESS");
            
            [delegate adapterBannerInitSuccess];
            break;
    }
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

- (void)loadBannerInternalWithAdapterConfig:(ISAdapterConfig *)adapterConfig
                                   delegate:(id<ISBannerAdapterDelegate>)delegate
                                       size:(ISBannerSize * _Nonnull)size
                                 serverData:(NSString *)serverData {
    NSString *placementId = adapterConfig.settings[kPlacementId];
    LogAdapterApi_Internal(@"placementId = %@", placementId);
    
    [self.placementIdToBannerSmashDelegate setObject:delegate
                                              forKey:placementId];
    
    dispatch_async(dispatch_get_main_queue(), ^{
        // Verify banner
        if ([self isBannerSizeSupported:size]) {
            
            ISInMobiBannerDelegate *bannerAdDelegate = [[ISInMobiBannerDelegate alloc] initWithPlacementId:placementId
                                                                                                  delegate:self];
            [self.placementIdToBannerDelegate setObject:bannerAdDelegate
                                                 forKey:placementId];
            
            IMBanner *inMobiBanner = [self getInMobiBanner:bannerAdDelegate
                                                      size:size
                                               placementId:placementId];
            // Disable auto refresh
            [inMobiBanner shouldAutoRefresh:NO];
            
            [self.placementIdToBannerAd setObject:inMobiBanner
                                           forKey:placementId];
            
            // Load ad
            if (serverData == nil) {
                inMobiBanner.extras = [self extras];
                [inMobiBanner load];
            } else {
                NSData* data = [serverData dataUsingEncoding:NSUTF8StringEncoding];
                [inMobiBanner load:data];
            }
        } else {
            // banner size not supported
            NSError *error = [NSError errorWithDomain:kAdapterName
                                                 code:ERROR_BN_UNSUPPORTED_SIZE
                                             userInfo:@{NSLocalizedDescriptionKey:@"unsupported banner size"}];
            LogAdapterApi_Internal(@"error = %@", error);
            
            [delegate adapterBannerDidFailToLoadWithError:error];
        }
    });
}


- (void)destroyBannerWithAdapterConfig:(nonnull ISAdapterConfig *)adapterConfig {
    NSString *placementId = adapterConfig.settings[kPlacementId];
    LogAdapterApi_Internal(@"placementId = %@", placementId);
    dispatch_async(dispatch_get_main_queue(), ^{
        IMBanner *banner = [self.placementIdToBannerAd objectForKey:placementId];
        if (banner != nil) {
            [banner removeFromSuperview];
            banner.delegate = nil;
            banner = nil;
        }
    });
    [self.placementIdToBannerAd removeObjectForKey:placementId];
    [self.placementIdToBannerDelegate removeObjectForKey:placementId];
    [self.placementIdToBannerSmashDelegate removeObjectForKey:placementId];
}

- (NSDictionary *)getBannerBiddingDataWithAdapterConfig:(ISAdapterConfig *)adapterConfig
                                                 adData:(NSDictionary *)adData {
    return [self getBiddingData];
}

#pragma mark - Banner Delegate

- (void)onBannerDidLoad:(IMBanner *)banner
            placementId:(NSString *)placementId {
    LogAdapterDelegate_Internal(@"placementId = %@", placementId);
    
    id<ISBannerAdapterDelegate> delegate = [self.placementIdToBannerSmashDelegate objectForKey:placementId];
    [delegate adapterBannerDidLoad:banner];
}

- (void)onBannerDidFailToLoad:(IMBanner *)banner
                        error:(IMRequestStatus *)error
                  placementId:(NSString *)placementId {
    LogAdapterDelegate_Internal(@"placementId = %@, error = %@", placementId, error);
    
    id<ISBannerAdapterDelegate> delegate = [self.placementIdToBannerSmashDelegate objectForKey:placementId];
    NSError* smashError;
    if (error.code == IMStatusCodeNoFill){
        // no fill
        smashError = [NSError errorWithDomain:kAdapterName
                                         code:ERROR_BN_LOAD_NO_FILL
                                     userInfo:@{NSLocalizedDescriptionKey:@"no fill"}];
    } else {
        smashError = error;
    }
    
    [delegate adapterBannerDidFailToLoadWithError:smashError];
}

- (void)onBannerDidShow:(IMBanner *)banner
            placementId:(NSString *)placementId {
    LogAdapterDelegate_Internal(@"placementId = %@", placementId);
    
    id<ISBannerAdapterDelegate> delegate = [self.placementIdToBannerSmashDelegate objectForKey:placementId];
    [delegate adapterBannerDidShow];
}

- (void)onBannerDidClick:(IMBanner *)banner
                  params:(NSDictionary *)params
             placementId:(NSString *)placementId {
    LogAdapterDelegate_Internal(@"placementId = %@", placementId);
    
    id<ISBannerAdapterDelegate> delegate = [self.placementIdToBannerSmashDelegate objectForKey:placementId];
    [delegate adapterBannerDidClick];
}

- (void)onBannerWillLeaveApplication:(IMBanner *)banner
                         placementId:(NSString *)placementId {
    LogAdapterDelegate_Internal(@"placementId = %@", placementId);
    
    id<ISBannerAdapterDelegate> delegate = [self.placementIdToBannerSmashDelegate objectForKey:placementId];
    [delegate adapterBannerWillLeaveApplication];
}

- (void)onBannerWillPresentScreenWithPlacementId:(NSString *)placementId {
    LogAdapterDelegate_Internal(@"placementId = %@", placementId);
    
    id<ISBannerAdapterDelegate> delegate = [self.placementIdToBannerSmashDelegate objectForKey:placementId];
    [delegate adapterBannerWillPresentScreen];
}

- (void)onBannerDidDismissScreenWithPlacementId:(NSString *)placementId {
    LogAdapterDelegate_Internal(@"placementId = %@", placementId);
    
    id<ISBannerAdapterDelegate> delegate = [self.placementIdToBannerSmashDelegate objectForKey:placementId];
    [delegate adapterBannerDidDismissScreen];
}

#pragma mark - Memory Handling

- (void)releaseMemoryWithAdapterConfig:(ISAdapterConfig *)adapterConfig {
    // Release memory - currently only for banners
    [self destroyBannerWithAdapterConfig:adapterConfig];
}

#pragma mark - Legal Methods

- (void)setConsent:(BOOL)consent {
    consentCollectingUserData = [NSString stringWithFormat:@"%s", consent ? "true" : "false"];
    
    if (initState == INIT_STATE_SUCCESS) {
        LogAdapterApi_Internal(@"consent = %@", consent ? @"YES" : @"NO");
        [IMSdk updateGDPRConsent:[self getConsentDictionary]];
    }
}

- (void)setMetaDataWithKey:(NSString *)key
                 andValues:(NSMutableArray *) values {
    if (values.count == 0) {
        return;
    }
    
    NSString *value = values[0];
    LogAdapterApi_Internal(@"key=%@, value=%@", key, value);
    
    if ([ISMetaDataUtils isValidCCPAMetaDataWithKey:key
                                           andValue:value]) {
        doNotSellCollectingUserData = [ISMetaDataUtils getMetaDataBooleanValue:value] ? @(1) : @(0);
        return;
    }
    
    NSString *formattedValue = [ISMetaDataUtils formatValue:value
                                                    forType:(META_DATA_VALUE_BOOL)];
    
    if ([ISMetaDataUtils isValidMetaDataWithKey:key
                                           flag:kMetaDataAgeRestrictedKey
                                       andValue:formattedValue]) {
        [self setAgeRestricted:[ISMetaDataUtils getMetaDataBooleanValue:formattedValue]];
    }
}


- (void)setAgeRestricted:(BOOL)isAgeRestricted {
    if (initState == INIT_STATE_SUCCESS) {
        LogAdapterApi_Internal(@"Restricted = %@", isAgeRestricted ? @"YES" : @"NO");
        [IMSdk setIsAgeRestricted:isAgeRestricted];
    } else {
        isAgeRestrictionCollectingUserData = isAgeRestricted;
    }
}

- (NSDictionary *)extras {
    NSMutableDictionary *extras = [NSMutableDictionary dictionaryWithDictionary:@{kTP : kCUnitylevelplay,
                                                                                  kTPVersion : kAdapterVersion}];
    if (doNotSellCollectingUserData != nil) {
        [extras setObject:doNotSellCollectingUserData
                   forKey:kInMobiDoNotSellKey];
    }
    
    return extras;
}

#pragma mark - Helper Methods

- (IMBanner *)getInMobiBanner:(id<IMBannerDelegate>)delegate
                         size:(ISBannerSize *)size
                  placementId:(NSString *)placementId {
    IMBanner *inMobiBanner = nil;
    
    if ([size.sizeDescription isEqualToString:@"BANNER"] ||
        [size.sizeDescription isEqualToString:@"LARGE"]) {
        inMobiBanner = [[IMBanner alloc] initWithFrame:CGRectMake(0, 0, 320, 50)
                                           placementId:[placementId longLongValue]
                                              delegate:delegate];
    } else if ([size.sizeDescription isEqualToString:@"RECTANGLE"]) {
        inMobiBanner = [[IMBanner alloc] initWithFrame:CGRectMake(0, 0, 300, 250)
                                           placementId:[placementId longLongValue]
                                              delegate:delegate];
    } else if ([size.sizeDescription isEqualToString:@"SMART"]) {
        if (UI_USER_INTERFACE_IDIOM() == UIUserInterfaceIdiomPad) {
            inMobiBanner = [[IMBanner alloc] initWithFrame:CGRectMake(0, 0, 728, 90)
                                               placementId:[placementId longLongValue]
                                                  delegate:delegate];
        } else {
            inMobiBanner = [[IMBanner alloc] initWithFrame:CGRectMake(0, 0, 320, 50)
                                               placementId:[placementId longLongValue]
                                                  delegate:delegate];
        }
    } else if ([size.sizeDescription isEqualToString:@"CUSTOM"]) {
        inMobiBanner = [[IMBanner alloc] initWithFrame:CGRectMake(0, 0, size.width, size.height)
                                           placementId:[placementId longLongValue]
                                              delegate:delegate];
    }
    
    return inMobiBanner;
}

- (BOOL)isBannerSizeSupported:(ISBannerSize *)size {
    BOOL isSupported = NO;
    
    if ([size.sizeDescription isEqualToString:@"BANNER"] ||
        [size.sizeDescription isEqualToString:@"LARGE"]) {
        isSupported = YES;
    } else if ([size.sizeDescription isEqualToString:@"RECTANGLE"]) {
        isSupported = YES;
    } else if ([size.sizeDescription isEqualToString:@"SMART"]) {
        isSupported = YES;
    } else if ([size.sizeDescription isEqualToString:@"CUSTOM"]) {
        isSupported = YES;
    }
    
    return isSupported;
}

- (NSDictionary *)getConsentDictionary {
    if (consentCollectingUserData.length > 0) {
        return @{[IMCommonConstants IM_GDPR_CONSENT_AVAILABLE]:consentCollectingUserData};
    }
    
    return @{};
}

- (NSDictionary *)getBiddingData {
    if (initState != INIT_STATE_SUCCESS) {
        LogAdapterApi_Internal(@"returning nil as token since init failed");
        
        return nil;
    }
    
    NSString *bidderToken = [IMSdk getTokenWithExtras:[self extras]
                                          andKeywords:kEmptyString];
    NSString *returnedToken = bidderToken ? bidderToken : kEmptyString;
    LogAdapterApi_Internal(@"token = %@", returnedToken);
    
    return @{kToken : returnedToken};
}

@end
