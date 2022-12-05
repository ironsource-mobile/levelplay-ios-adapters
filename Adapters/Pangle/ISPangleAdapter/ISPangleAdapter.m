//
//  ISPangleAdapter.m
//  ISPangleAdapter
//
//  Copyright © 2022 ironSource Mobile Ltd. All rights reserved.
//

#import "ISPangleAdapter.h"
#import "ISPangleRewardedVideoDelegate.h"
#import "ISPangleInterstitialDelegate.h"
#import "ISPangleBannerDelegate.h"
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
static ConcurrentMutableSet<ISNetworkInitCallbackProtocol> *initCallbackDelegates = nil;
static InitState _initState = INIT_STATE_NONE;

// Pangle SDK instance
static PAGSdk* _pangleSDK = nil;

@interface ISPangleAdapter () <ISPangleBannerDelegateWrapper, ISPangleInterstitialDelegateWrapper, ISPangleRewardedVideoDelegateWrapper, ISNetworkInitCallbackProtocol>

// Rewarded video
@property (nonatomic, strong) ConcurrentMutableDictionary   *rewardedVideoSlotIdToSmashDelegate;
@property (nonatomic, strong) ConcurrentMutableDictionary   *rewardedVideoSlotIdToPangleAdDelegate;
@property (nonatomic, strong) ConcurrentMutableDictionary   *rewardedVideoSlotIdToAd;
@property (nonatomic, strong) ConcurrentMutableDictionary   *rewardedVideoAdsAvailability;
@property (nonatomic, strong) ConcurrentMutableSet          *rewardedVideoSlotIdsForInitCallbacks;

// Interstitial
@property (nonatomic, strong) ConcurrentMutableDictionary   *interstitialSlotIdToSmashDelegate;
@property (nonatomic, strong) ConcurrentMutableDictionary   *interstitialSlotIdToPangleAdDelegate;
@property (nonatomic, strong) ConcurrentMutableDictionary   *interstitialSlotIdToAd;
@property (nonatomic, strong) ConcurrentMutableDictionary   *interstitialAdsAvailability;

// Banner
@property (nonatomic, strong) ConcurrentMutableDictionary   *bannerSlotIdToSmashDelegate;
@property (nonatomic, strong) ConcurrentMutableDictionary   *bannerSlotIdToPangleAdDelegate;
@property (nonatomic, strong) ConcurrentMutableDictionary   *bannerSlotIdToAd;
@property (nonatomic, strong) ConcurrentMutableDictionary   *bannerSlotIdToAdSize;
@property (nonatomic, strong) ConcurrentMutableDictionary   *bannerSlotIdToViewController;

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

- (NSArray *)systemFrameworks {
    return @[@"Accelerate",
             @"AdSupport",
             @"AppTrackingTransparency",
             @"AudioToolbox",
             @"AVFoundation",
             @"CoreGraphics",
             @"CoreImage",
             @"CoreLocation",
             @"CoreMedia",
             @"CoreML",
             @"CoreMotion",
             @"CoreTelephony",
             @"CoreText",
             @"ImageIO",
             @"JavaScriptCore",
             @"MediaPlayer",
             @"MapKit",
             @"MobileCoreServices",
             @"QuartzCore",
             @"Security",
             @"StoreKit",
             @"SystemConfiguration",
             @"UIKit",
             @"WebKit"];
}

// Get network sdk name
- (NSString *)sdkName {
    return @"PAGSdk";
}

#pragma mark - Initializations Methods And Callbacks

- (instancetype)initAdapter:(NSString *)name {
    self = [super initAdapter:name];
    
    if (self) {
        if (initCallbackDelegates == nil) {
            initCallbackDelegates = [ConcurrentMutableSet<ISNetworkInitCallbackProtocol> set];
        }
        
        // Rewarded video
        _rewardedVideoSlotIdToSmashDelegate         = [ConcurrentMutableDictionary dictionary];
        _rewardedVideoSlotIdToPangleAdDelegate      = [ConcurrentMutableDictionary dictionary];
        _rewardedVideoSlotIdToAd                    = [ConcurrentMutableDictionary dictionary];
        _rewardedVideoAdsAvailability               = [ConcurrentMutableDictionary dictionary];
        _rewardedVideoSlotIdsForInitCallbacks       = [ConcurrentMutableSet set];

        // Interstitial
        _interstitialSlotIdToSmashDelegate          = [ConcurrentMutableDictionary dictionary];
        _interstitialSlotIdToPangleAdDelegate       = [ConcurrentMutableDictionary dictionary];
        _interstitialSlotIdToAd                     = [ConcurrentMutableDictionary dictionary];
        _interstitialAdsAvailability                = [ConcurrentMutableDictionary dictionary];
        
        // Banner
        _bannerSlotIdToSmashDelegate                = [ConcurrentMutableDictionary dictionary];
        _bannerSlotIdToPangleAdDelegate             = [ConcurrentMutableDictionary dictionary];
        _bannerSlotIdToAd                           = [ConcurrentMutableDictionary dictionary];
        _bannerSlotIdToAdSize                       = [ConcurrentMutableDictionary dictionary];
        _bannerSlotIdToViewController               = [ConcurrentMutableDictionary dictionary];
                    
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
                
            [PAGSdk startWithConfig:config
                  completionHandler:^(BOOL success, NSError * _Nonnull error) {
                if (success) {
                    [self initializationSuccess];
                } else {
                    [self initializationFailure:error.description];
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
    
    NSError *error = [NSError errorWithDomain:kAdapterName
                                         code:ERROR_CODE_INIT_FAILED
                                     userInfo:@{NSLocalizedDescriptionKey:errorMessage}];
    
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
    
    ISPangleRewardedVideoDelegate *rewardedVideoAdDelegate = [[ISPangleRewardedVideoDelegate alloc] initWithSlotId:slotId
                                                                                                       andDelegate:self];

    // Add to rewarded video delegate map
    [_rewardedVideoSlotIdToPangleAdDelegate setObject:rewardedVideoAdDelegate
                                               forKey:slotId];
    
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
    
    ISPangleRewardedVideoDelegate *rewardedVideoAdDelegate = [[ISPangleRewardedVideoDelegate alloc] initWithSlotId:slotId
                                                                                                       andDelegate:self];
                                                                                                                 
    // Add to rewarded video delegate map
    [_rewardedVideoSlotIdToPangleAdDelegate setObject:rewardedVideoAdDelegate
                                               forKey:slotId];
    
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
                                          serverData:(NSString *)serverData
                                            delegate:(id<ISRewardedVideoAdapterDelegate>)delegate{
   
    NSString *slotId = adapterConfig.settings[kSlotId];
    [self loadRewardedVideoInternal:slotId
                           delegate:delegate
                         serverData:serverData];
}

- (void)fetchRewardedVideoForAutomaticLoadWithAdapterConfig:(ISAdapterConfig *)adapterConfig
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
    
    dispatch_async(dispatch_get_main_queue(), ^{
       
        ISPangleRewardedVideoDelegate *rewardedVideoAdDelegate = [_rewardedVideoSlotIdToPangleAdDelegate objectForKey:slotId];
                
        [self.rewardedVideoAdsAvailability setObject:@NO
                                              forKey:slotId];
        
        PAGRewardedRequest *request = [PAGRewardedRequest request];
         
        if (serverData) {
            [request setAdString:serverData];
        }
        
        [PAGRewardedAd loadAdWithSlotID:slotId
                                request:request
                      completionHandler:^(PAGRewardedAd * _Nullable rewardedAd, NSError * _Nullable error) {
            
            if (error) {
                [self onRewardedVideoDidFailToLoad:slotId
                                         withError:error];
                return;
            }
            
            rewardedAd.delegate = rewardedVideoAdDelegate;
            
            // Add rewarded video ad to dictionary
            [_rewardedVideoSlotIdToAd setObject:rewardedAd
                                         forKey:slotId];
                
            [self onRewardedVideoDidLoad:slotId];
            
        }];
    });
}

- (void)showRewardedVideoWithViewController:(UIViewController *)viewController
                              adapterConfig:(ISAdapterConfig *)adapterConfig
                                   delegate:(id<ISRewardedVideoAdapterDelegate>)delegate {
    
    NSString *slotId = adapterConfig.settings[kSlotId];
    LogAdapterApi_Internal(@"slotId = %@", slotId);
    
    PAGRewardedAd *rewardedVideoAd = [_rewardedVideoSlotIdToAd objectForKey:slotId];
    
    [delegate adapterRewardedVideoHasChangedAvailability:NO];

    if ([self hasRewardedVideoWithAdapterConfig:adapterConfig]) {
        [self.rewardedVideoAdsAvailability setObject:@NO
                                              forKey:slotId];
        
        [rewardedVideoAd presentFromRootViewController:viewController];
        
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

- (NSDictionary *)getRewardedVideoBiddingDataWithAdapterConfig:(ISAdapterConfig *)adapterConfig {
    NSString *slotId = adapterConfig.settings[kSlotId];
    return [self getBiddingDataWithSlotId:slotId];
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

    ISPangleInterstitialDelegate *interstitialAdDelegate = [[ISPangleInterstitialDelegate alloc] initWithSlotId:slotId
                                                                                                  andDelegate:self];
                                                                                                           
    // Add to interstitial delegate map
    [_interstitialSlotIdToPangleAdDelegate setObject:interstitialAdDelegate
                                              forKey:slotId];

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

- (void)loadInterstitialForBiddingWithServerData:(NSString *)serverData
                                   adapterConfig:(ISAdapterConfig *)adapterConfig
                                        delegate:(id<ISInterstitialAdapterDelegate>)delegate {
    
    NSString *slotId = adapterConfig.settings[kSlotId];
    [self loadInterstitialInternal:slotId
                          delegate:delegate
                        serverData:serverData];
}

- (void)loadInterstitialWithAdapterConfig:(ISAdapterConfig *)adapterConfig
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
    
    dispatch_async(dispatch_get_main_queue(), ^{
        
        ISPangleInterstitialDelegate *interstitialAdDelegate = [_interstitialSlotIdToPangleAdDelegate objectForKey:slotId];
        
        [self.interstitialAdsAvailability setObject:@NO
                                             forKey:slotId];
        
        PAGInterstitialRequest *request = [PAGInterstitialRequest request];
        
        if (serverData) {
            [request setAdString:serverData];
        }
        
        [PAGLInterstitialAd loadAdWithSlotID:slotId
                                     request:request
                           completionHandler:^(PAGLInterstitialAd * _Nullable interstitialAd, NSError * _Nullable error) {
            
            if (error) {
                    [self onInterstitialDidFailToLoad:slotId
                                            withError:error];
                    return;
                }
                        
            interstitialAd.delegate = interstitialAdDelegate;
            
            // Add interstitial ad to dictionary
            [_interstitialSlotIdToAd setObject:interstitialAd
                                        forKey:slotId];
                
            [self onInterstitialDidLoad:slotId];
            
         }];
    });
}

- (void)showInterstitialWithViewController:(UIViewController *)viewController
                             adapterConfig:(ISAdapterConfig *)adapterConfig
                                  delegate:(id<ISInterstitialAdapterDelegate>)delegate {
    
    NSString *slotId = adapterConfig.settings[kSlotId];
    LogAdapterApi_Internal(@"slotId = %@", slotId);
    
    dispatch_async(dispatch_get_main_queue(), ^{

        PAGLInterstitialAd *interstitialAd = [_interstitialSlotIdToAd objectForKey:slotId];
        
        if ([self hasInterstitialWithAdapterConfig:adapterConfig]) {
            [self.interstitialAdsAvailability setObject:@NO
                                                 forKey:slotId];
            
            [interstitialAd presentFromRootViewController:viewController];
            
        } else {
            NSError *error = [NSError errorWithDomain:kAdapterName
                                                 code:ERROR_CODE_NO_ADS_TO_SHOW
                                             userInfo:@{NSLocalizedDescriptionKey:@"No ads to show"}];
            LogAdapterApi_Internal(@"error = %@", error);
            
            [delegate adapterInterstitialDidFailToShowWithError:error];
        }
    });
}

- (BOOL)hasInterstitialWithAdapterConfig:(ISAdapterConfig *)adapterConfig {
    NSString *slotId = adapterConfig.settings[kSlotId];
    PAGLInterstitialAd *interstitialAd = [_interstitialSlotIdToAd objectForKey:slotId];
    NSNumber *available = [_interstitialAdsAvailability objectForKey:slotId];
    return interstitialAd != nil && available != nil && [available boolValue];
}

- (NSDictionary *)getInterstitialBiddingDataWithAdapterConfig:(ISAdapterConfig *)adapterConfig {
    NSString *slotId = adapterConfig.settings[kSlotId];
    return [self getBiddingDataWithSlotId:slotId];
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

    ISPangleBannerDelegate *bannerAdDelegate = [[ISPangleBannerDelegate alloc] initWithSlotId:slotId
                                                                                  andDelegate:self];
                                                                                        
    // Add banner ad to dictionary
    [_bannerSlotIdToPangleAdDelegate setObject:bannerAdDelegate
                                        forKey:slotId];
    
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

- (void)loadBannerForBiddingWithServerData:(NSString *)serverData
                            viewController:(UIViewController *)viewController
                                      size:(ISBannerSize *)size
                             adapterConfig:(ISAdapterConfig *)adapterConfig
                                  delegate:(id<ISBannerAdapterDelegate>)delegate {
    
    NSString *slotId = adapterConfig.settings[kSlotId];
    LogAdapterApi_Internal(@"slotId = %@", slotId);
    
    dispatch_async(dispatch_get_main_queue(), ^{
        
        ISPangleBannerDelegate *bannerAdDelegate = [_bannerSlotIdToPangleAdDelegate objectForKey:slotId];
                
        PAGBannerRequest *request = [PAGBannerRequest requestWithBannerSize:[self getBannerSize:size]];
         
        if (serverData) {
            [request setAdString:serverData];
        }
        
        [PAGBannerAd loadAdWithSlotID:slotId
                              request:request
                    completionHandler:^(PAGBannerAd * _Nullable bannerAd, NSError * _Nullable error) {
            
            if (error) {
                [self onBannerDidFailToLoad:slotId
                                  withError:error];
                return;
            }

            bannerAd.delegate = bannerAdDelegate;
            
            bannerAd.rootViewController = viewController;
            
            CGRect bannerFrame = [self getBannerFrame:size];
            bannerAd.bannerView.frame = bannerFrame;
            
            // Add banner ad to dictionary
            [_bannerSlotIdToAd setObject:bannerAd
                                  forKey:slotId];
            [_bannerSlotIdToViewController setObject:viewController
                                              forKey:slotId];
            [_bannerSlotIdToAdSize setObject:size
                                      forKey:slotId];
            
            [self onBannerDidLoad:slotId];
        }];
    });
}

- (void)destroyBannerWithAdapterConfig:(ISAdapterConfig *)adapterConfig {
    // There is no required implementation for Pangle destroy banner
}

- (NSDictionary *)getBannerBiddingDataWithAdapterConfig:(ISAdapterConfig *)adapterConfig {
    NSString *slotId = adapterConfig.settings[kSlotId];
    return [self getBiddingDataWithSlotId:slotId];
}

// Network does not support banner reload
// Return true if banner view needs to be bound again on reload
- (BOOL)shouldBindBannerViewOnReload {
    return YES;
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
    
    if ([self isValidCOPPAMetaDataWithKey:key
                                 andValue:value]) {
        [self setCOPPAValue:value.integerValue];
    } else if ([ISMetaDataUtils isValidCCPAMetaDataWithKey:key
                                                  andValue:value]) {
        [self setCCPAValue:[ISMetaDataUtils getCCPABooleanValue:value]];
    }
}

- (BOOL) isValidCOPPAMetaDataWithKey:(NSString *)key
                            andValue:(NSString *)value {
    return ([key caseInsensitiveCompare:kMetaDataCOPPAKey] == NSOrderedSame && ([value isEqualToString:kCOPPAChild] || [value isEqualToString:kCOPPAAdult]));
}

#pragma mark - Helper Methods

- (NSDictionary *)getBiddingDataWithSlotId:(NSString *)slotId {
    if (_initState != INIT_STATE_SUCCESS) {
        LogAdapterApi_Internal(@"returning nil as token since init isn't successful");
        return nil;
    }
    
    NSString *bidderToken = [PAGSdk getBiddingToken:slotId];
    NSString *returnedToken = bidderToken? bidderToken : @"";
    
    LogAdapterApi_Internal(@"token = %@", returnedToken);
    
    return @{@"token": returnedToken};
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
