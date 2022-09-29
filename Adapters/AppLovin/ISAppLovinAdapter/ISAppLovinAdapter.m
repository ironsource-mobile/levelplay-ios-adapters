//
//  ISAppLovinAdapter.m
//  ISAppLovinAdapter
//
//  Copyright © 2022 IronSource. All rights reserved.
//

#import "ISAppLovinAdapter.h"
#import "ISApplovinRewardedVideoDelegate.h"
#import "ISApplovinInterstitialDelegate.h"
#import "ISApplovinBannerDelegate.h"
#import "AppLovinSDK/AppLovinSDK.h"

// Network keys
static NSString * const kAdapterVersion            = AppLovinAdapterVersion;
static NSString * const kAdapterName               = @"ALSdk";
static NSString * const kSdkKey                    = @"sdkKey";
static NSString * const kZoneID                    = @"zoneId";
static NSString * const kDefaultZoneID             = @"defaultZoneId";

// Meta data keys
static NSString * const kMetaDataAgeRestrictionKey = @"AppLovin_AgeRestrictedUser";

// init state possible values
typedef NS_ENUM(NSInteger, InitState) {
    INIT_STATE_NONE,
    INIT_STATE_IN_PROGRESS,
    INIT_STATE_SUCCESS
};

// Handle init callback for all adapter instances
static ConcurrentMutableSet<ISNetworkInitCallbackProtocol> *initCallbackDelegates = nil;
static InitState _initState = INIT_STATE_NONE;

// AppLovin sdk instance
static ALSdk* _appLovinSDK = nil;

@interface ISAppLovinAdapter () <ISApplovinRewardedVideoDelegateWrapper, ISApplovinInterstitialDelegateWrapper, ISApplovinBannerDelegateWrapper, ISNetworkInitCallbackProtocol>
    
// Rewarded video
@property (nonatomic, strong) ConcurrentMutableDictionary *rewardedVideoZoneIdToSmashDelegate;
@property (nonatomic, strong) ConcurrentMutableDictionary *rewardedVideoZoneIdToAppLovinAdDelegate;
@property (nonatomic, strong) ConcurrentMutableDictionary *rewardedVideoZoneIdToAd;
@property (nonatomic, strong) ConcurrentMutableSet        *rewardedVideoZoneIdForInitCallbacks;

// Interstitial
@property (nonatomic, strong) ConcurrentMutableDictionary *interstitialZoneIdToSmashDelegate;
@property (nonatomic, strong) ConcurrentMutableDictionary *interstitialZoneIdToAppLovinAdDelegate;
@property (nonatomic, strong) ConcurrentMutableDictionary *interstitialZoneIdToAd;
@property (nonatomic, strong) ConcurrentMutableDictionary *interstitialZoneIdToLoadedAds;

// Banner
@property (nonatomic, strong) ConcurrentMutableDictionary *bannerZoneIdToSmashDelegate;
@property (nonatomic, strong) ConcurrentMutableDictionary *bannerZoneIdToAppLovinAdDelegate;
@property (nonatomic, strong) ConcurrentMutableDictionary *bannerZoneIdToAd;
@property (nonatomic, strong) ConcurrentMutableDictionary *bannerZoneIdToAdSize;

@end

@implementation ISAppLovinAdapter

#pragma mark - IronSource Protocol Methods

// get adapter version
- (NSString *)version {
    return kAdapterVersion;
}

//get network sdk version
- (NSString *)sdkVersion {
    return [ALSdk version];
}

- (NSArray *)systemFrameworks {
    return @[
        @"AdSupport",
        @"AppTrackingTransparency",
        @"AudioToolbox",
        @"AVFoundation",
        @"CFNetwork",
        @"CoreGraphics",
        @"CoreMedia",
        @"CoreMotion",
        @"CoreTelephony",
        @"MessageUI",
        @"SafariServices",
        @"StoreKit",
        @"SystemConfiguration",
        @"UIKit",
        @"WebKit"
    ];
}

// get network sdk name
- (NSString *)sdkName {
    return kAdapterName;
}

#pragma mark - Initializations Methods And Callbacks

- (instancetype)initAdapter:(NSString *)name {
    self = [super initAdapter:name];
    
    if (self) {
        if (initCallbackDelegates == nil) {
            initCallbackDelegates = [ConcurrentMutableSet<ISNetworkInitCallbackProtocol> set];
        }
        
        // Rewarded video
        _rewardedVideoZoneIdToSmashDelegate         = [ConcurrentMutableDictionary dictionary];
        _rewardedVideoZoneIdToAppLovinAdDelegate    = [ConcurrentMutableDictionary dictionary];
        _rewardedVideoZoneIdToAd                    = [ConcurrentMutableDictionary dictionary];
        _rewardedVideoZoneIdForInitCallbacks        = [ConcurrentMutableSet set];

        // Interstitial
        _interstitialZoneIdToSmashDelegate          = [ConcurrentMutableDictionary dictionary];
        _interstitialZoneIdToAppLovinAdDelegate     = [ConcurrentMutableDictionary dictionary];
        _interstitialZoneIdToAd                     = [ConcurrentMutableDictionary dictionary];
        _interstitialZoneIdToLoadedAds              = [ConcurrentMutableDictionary dictionary];
        
        // Banner
        _bannerZoneIdToAd                           = [ConcurrentMutableDictionary dictionary];
        _bannerZoneIdToSmashDelegate                = [ConcurrentMutableDictionary dictionary];
        _bannerZoneIdToAppLovinAdDelegate           = [ConcurrentMutableDictionary dictionary];
        _bannerZoneIdToAdSize                       = [ConcurrentMutableDictionary dictionary];
                
        // The network's capability to load a Rewarded Video ad while another Rewarded Video ad of that network is showing
        LWSState = LOAD_WHILE_SHOW_BY_INSTANCE;
    }
    
    return self;
}

- (void)initSDKWithSDKKey:(NSString *)sdkKey {
    
    // add self to the init delegates only in case the initialization has not finished yet
    if (_initState == INIT_STATE_NONE || _initState == INIT_STATE_IN_PROGRESS) {
        [initCallbackDelegates addObject:self];
    }
    
    static dispatch_once_t initSdkOnceToken;
    dispatch_once(&initSdkOnceToken, ^{
        _initState = INIT_STATE_IN_PROGRESS;

        dispatch_async(dispatch_get_main_queue(), ^{
            
            _appLovinSDK = [ALSdk sharedWithKey:sdkKey];
            
            _appLovinSDK.settings.isVerboseLogging = [ISConfigurations getConfigurations].adaptersDebug;
            
            LogAdapterApi_Internal(@"sdkKey = %@, isVerboseLogging = %d", sdkKey, _appLovinSDK.settings.isVerboseLogging);
            
            // AppLovin's initialization callback currently doesn't give any indication to initialization failure.
            // Once this callback is called we will treat the initialization as successful
            [_appLovinSDK initializeSdkWithCompletionHandler:^(ALSdkConfiguration * _Nonnull configuration) {
                [self initializationSuccess];
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

- (void)onNetworkInitCallbackSuccess {
    
    // Rewarded video
    NSArray *rewardedVideoZoneIds = _rewardedVideoZoneIdToSmashDelegate.allKeys;
    
    for (NSString *zoneId in rewardedVideoZoneIds) {
        if ([_rewardedVideoZoneIdForInitCallbacks hasObject:zoneId]) {
            id<ISRewardedVideoAdapterDelegate> delegate = [_rewardedVideoZoneIdToSmashDelegate objectForKey:zoneId];
            [delegate adapterRewardedVideoInitSuccess];
        } else {
            [self loadRewardedVideoInternalWithZoneId:zoneId];
        }
    }
    
    // Interstitial
    NSArray *interstitialZoneIds = _interstitialZoneIdToSmashDelegate.allKeys;
    
    for (NSString *zoneId in interstitialZoneIds) {
        id<ISInterstitialAdapterDelegate> delegate = [_interstitialZoneIdToSmashDelegate objectForKey:zoneId];
        [delegate adapterInterstitialInitSuccess];
    }
    
    // Banner
    NSArray *bannerZoneIds = _bannerZoneIdToSmashDelegate.allKeys;
    
    for (NSString *zoneId in bannerZoneIds) {
        id<ISBannerAdapterDelegate> delegate = [_bannerZoneIdToSmashDelegate objectForKey:zoneId];
        [delegate adapterBannerInitSuccess];
    }
}

- (void)onNetworkInitCallbackFailed:(nonnull NSString *)errorMessage {
}


#pragma mark - Rewarded Video API

// Used for flows when the mediation needs to get a callback for init
- (void)initRewardedVideoForCallbacksWithUserId:(NSString *)userId
                                  adapterConfig:(ISAdapterConfig *)adapterConfig
                                       delegate:(id<ISRewardedVideoAdapterDelegate>)delegate {
    
    NSString *sdkKey = adapterConfig.settings[kSdkKey];
    NSString *zoneId = [self getZoneId:adapterConfig];

    /* Configuration Validation */
    if (!sdkKey.length) {
        NSError *error = [self errorForMissingCredentialFieldWithName:kSdkKey];
        LogAdapterApi_Internal(@"error = %@", error.description);
        [delegate adapterRewardedVideoInitFailed:error];
        return;
    }
    
    LogAdapterApi_Internal(@"zoneId = %@, sdkKey = %@", zoneId, sdkKey);
    
    ISApplovinRewardedVideoDelegate *rewardedVideoDelegate = [[ISApplovinRewardedVideoDelegate alloc] initWithZoneId:zoneId
                                                                                                            delegate:self];
    
    //add to rewarded video delegate map
    [_rewardedVideoZoneIdToAppLovinAdDelegate setObject:rewardedVideoDelegate
                                                 forKey:zoneId];
    
    [_rewardedVideoZoneIdToSmashDelegate setObject:delegate
                                            forKey:zoneId];
    
    //add to rewarded video init callback map
    [_rewardedVideoZoneIdForInitCallbacks addObject:zoneId];
    
    switch (_initState) {
        case INIT_STATE_NONE:
        case INIT_STATE_IN_PROGRESS:
            [self initSDKWithSDKKey:sdkKey];
            break;
        case INIT_STATE_SUCCESS:
            [self setAppLovinUserId:userId];
            [delegate adapterRewardedVideoInitSuccess];
            break;
    }
}

// Used for flows when the mediation doesn't need to get a callback for init
- (void)initAndLoadRewardedVideoWithUserId:(NSString *)userId
                             adapterConfig:(ISAdapterConfig *)adapterConfig
                                  delegate:(id<ISRewardedVideoAdapterDelegate>)delegate {

    NSString *sdkKey = adapterConfig.settings[kSdkKey];
    NSString *zoneId = [self getZoneId:adapterConfig];
    
    /* Configuration Validation */
    if (!sdkKey.length) {
        NSError *error = [self errorForMissingCredentialFieldWithName:kSdkKey];
        LogAdapterApi_Internal(@"error = %@", error.description);
        [delegate adapterRewardedVideoHasChangedAvailability:NO];
        return;
    }
    
    LogAdapterApi_Internal(@"zoneId = %@, sdkKey = %@", zoneId, sdkKey);
    
    ISApplovinRewardedVideoDelegate *rewardedVideoDelegate = [[ISApplovinRewardedVideoDelegate alloc] initWithZoneId:zoneId
                                                                                                            delegate:self];
    
    //add to rewarded video delegate map
    [_rewardedVideoZoneIdToAppLovinAdDelegate setObject:rewardedVideoDelegate
                                                 forKey:zoneId];
    
    [_rewardedVideoZoneIdToSmashDelegate setObject:delegate
                                            forKey:zoneId];
    
    switch (_initState) {
        case INIT_STATE_NONE:
        case INIT_STATE_IN_PROGRESS:
            [self initSDKWithSDKKey:sdkKey];
            break;
        case INIT_STATE_SUCCESS:
            [self setAppLovinUserId:userId];
            [self loadRewardedVideoInternalWithZoneId:zoneId];
            break;
    }
}

- (void)fetchRewardedVideoForAutomaticLoadWithAdapterConfig:(ISAdapterConfig *)adapterConfig
                                                   delegate:(id<ISRewardedVideoAdapterDelegate>)delegate {
    
    NSString *zoneId = [self getZoneId:adapterConfig];
    
    // load rewarded video
    [self loadRewardedVideoInternalWithZoneId:zoneId];
}

-(void)loadRewardedVideoInternalWithZoneId:(NSString *)zoneId {
    LogAdapterApi_Internal(@"zoneId = %@", zoneId);
    
    ALIncentivizedInterstitialAd *ad = [self createRewardedVideoAd:zoneId];
    
    if (ad == nil) {
        LogAdapterApi_Internal(@"ad is nil");
        return;
    }
    
    ISApplovinRewardedVideoDelegate *rewardedVideoAdDelegate = [_rewardedVideoZoneIdToAppLovinAdDelegate objectForKey:zoneId];
    [ad preloadAndNotify:rewardedVideoAdDelegate];
}

- (void)showRewardedVideoWithViewController:(UIViewController *)viewController
                              adapterConfig:(ISAdapterConfig *)adapterConfig
                                   delegate:(id<ISRewardedVideoAdapterDelegate>)delegate {
    NSString *zoneId = [self getZoneId:adapterConfig];
    LogAdapterApi_Internal(@"zoneId = %@", zoneId);
    
    ALIncentivizedInterstitialAd *rewardedVideoAd = [_rewardedVideoZoneIdToAd objectForKey:zoneId];
    ISApplovinRewardedVideoDelegate *rewardedVideoAdDelegate = [_rewardedVideoZoneIdToAppLovinAdDelegate objectForKey:zoneId];

    [delegate adapterRewardedVideoHasChangedAvailability:NO];

    if ([self hasRewardedVideoWithAdapterConfig:adapterConfig]) {
        
        // set dynamic user id to ad if exists
        [self setAppLovinUserId:self.dynamicUserId];
        
        [rewardedVideoAd showAndNotify:rewardedVideoAdDelegate];
    } else {
        NSError *error = [ISError createError:ERROR_CODE_NO_ADS_TO_SHOW
                                  withMessage:[NSString stringWithFormat: @"%@ show failed", kAdapterName]];
        
        [delegate adapterRewardedVideoDidFailToShowWithError:error];
    }
}

- (BOOL)hasRewardedVideoWithAdapterConfig:(ISAdapterConfig *)adapterConfig {
    NSString *zoneId = [self getZoneId:adapterConfig];
    ALIncentivizedInterstitialAd *rewardedVideoAd = [_rewardedVideoZoneIdToAd objectForKey:zoneId];
    return rewardedVideoAd != nil && [rewardedVideoAd isReadyForDisplay];
}

#pragma mark - Rewarded Video Delegate

- (void)onRewardedVideoDidLoad:(nonnull NSString *)zoneId {
    LogAdapterDelegate_Internal(@"zoneId = %@", zoneId);
    id<ISRewardedVideoAdapterDelegate> delegate = [_rewardedVideoZoneIdToSmashDelegate objectForKey:zoneId];
    
    [delegate adapterRewardedVideoHasChangedAvailability:YES];
}

- (void)onRewardedVideoDidFailToLoad:(nonnull NSString *)zoneId
                           errorCode:(int)code {
    NSString *errorReason = [self getErrorMessage:code];
    LogAdapterDelegate_Internal(@"zoneId = %@ , error code = %d, %@", zoneId, code, errorReason);
    id<ISRewardedVideoAdapterDelegate> delegate = [_rewardedVideoZoneIdToSmashDelegate objectForKey:zoneId];
    
    [delegate adapterRewardedVideoHasChangedAvailability:NO];
    
    NSInteger errorCode = code == kALErrorCodeNoFill ? ERROR_RV_LOAD_NO_FILL : code;
    NSError *error = [NSError errorWithDomain:kAdapterName
                                         code:errorCode
                                     userInfo:@{NSLocalizedDescriptionKey:errorReason}];
    [delegate adapterRewardedVideoDidFailToLoadWithError:error];
}

- (void)onRewardedVideoDidOpen:(nonnull NSString *)zoneId {
    LogAdapterDelegate_Internal(@"zoneId = %@", zoneId);
    id<ISRewardedVideoAdapterDelegate> delegate = [_rewardedVideoZoneIdToSmashDelegate objectForKey:zoneId];
    
    [delegate adapterRewardedVideoDidOpen];
}

- (void)onRewardedVideoDidStart:(nonnull NSString *)zoneId {
    LogAdapterDelegate_Internal(@"zoneId = %@", zoneId);
    id<ISRewardedVideoAdapterDelegate> delegate = [_rewardedVideoZoneIdToSmashDelegate objectForKey:zoneId];
    
    [delegate adapterRewardedVideoDidStart];
}

- (void)onRewardedVideoDidClick:(nonnull NSString *)zoneId {
    LogAdapterDelegate_Internal(@"zoneId = %@", zoneId);
    id<ISRewardedVideoAdapterDelegate> delegate = [_rewardedVideoZoneIdToSmashDelegate objectForKey:zoneId];
    
    [delegate adapterRewardedVideoDidClick];
}

- (void)onRewardedVideoDidEnd:(nonnull NSString *)zoneId {
    LogAdapterDelegate_Internal(@"zoneId = %@", zoneId);
    id<ISRewardedVideoAdapterDelegate> delegate = [_rewardedVideoZoneIdToSmashDelegate objectForKey:zoneId];
    
    [delegate adapterRewardedVideoDidEnd];
}

- (void)onRewardedVideoDidReceiveReward:(nonnull NSString *)zoneId {
    LogAdapterDelegate_Internal(@"zoneId = %@", zoneId);
    id<ISRewardedVideoAdapterDelegate> delegate = [_rewardedVideoZoneIdToSmashDelegate objectForKey:zoneId];
    
    [delegate adapterRewardedVideoDidReceiveReward];
}

- (void)onRewardedVideoDidClose:(nonnull NSString *)zoneId {
    LogAdapterDelegate_Internal(@"zoneId = %@", zoneId);
    id<ISRewardedVideoAdapterDelegate> delegate = [_rewardedVideoZoneIdToSmashDelegate objectForKey:zoneId];
    
    [delegate adapterRewardedVideoDidClose];
}


#pragma mark - Interstitial API

- (void)initInterstitialWithUserId:(NSString *)userId
                     adapterConfig:(ISAdapterConfig *)adapterConfig
                          delegate:(id<ISInterstitialAdapterDelegate>)delegate {
    
    NSString *sdkKey = adapterConfig.settings[kSdkKey];
    NSString *zoneId = [self getZoneId:adapterConfig];

    /* Configuration Validation */
    if (!sdkKey.length) {
        NSError *error = [self errorForMissingCredentialFieldWithName:kSdkKey];
        LogAdapterApi_Internal(@"error = %@", error.description);
        [delegate adapterInterstitialInitFailedWithError:error];
        return;
    }

    LogAdapterApi_Internal(@"sdkKey = %@, zoneId = %@", sdkKey, zoneId);
    
    ISApplovinInterstitialDelegate *interstitialAdDelegate = [[ISApplovinInterstitialDelegate alloc] initWithZoneId:zoneId
                                                                                                           delegate:self];
    // add to interstitial delegate map
    [_interstitialZoneIdToAppLovinAdDelegate setObject:interstitialAdDelegate
                                                forKey:zoneId];
    
    [_interstitialZoneIdToSmashDelegate setObject:delegate
                                           forKey:zoneId];
    
    switch (_initState) {
        case INIT_STATE_NONE:
        case INIT_STATE_IN_PROGRESS:
            [self initSDKWithSDKKey:sdkKey];
            break;
        case INIT_STATE_SUCCESS:
            [delegate adapterInterstitialInitSuccess];
            break;
    }
}

- (void)loadInterstitialWithAdapterConfig:(ISAdapterConfig *)adapterConfig
                                 delegate:(id<ISInterstitialAdapterDelegate>)delegate {
    dispatch_async(dispatch_get_main_queue(), ^{
        NSString *zoneId = [self getZoneId:adapterConfig];
        LogAdapterApi_Internal(@"zoneId = %@", zoneId);
        
        ALInterstitialAd *ad = [self createInterstitialAd:zoneId];
        
        if (ad == nil) {
            LogAdapterApi_Internal(@"ad is nil");
            return;
        }
        
        ISApplovinInterstitialDelegate *interstitialAdDelegate = [_interstitialZoneIdToAppLovinAdDelegate objectForKey:zoneId];
        
        if ([zoneId isEqualToString:kDefaultZoneID]) {
            [[_appLovinSDK adService] loadNextAd:ALAdSize.interstitial
                                       andNotify:interstitialAdDelegate];
        } else {
            [[_appLovinSDK adService] loadNextAdForZoneIdentifier:zoneId
                                                        andNotify:interstitialAdDelegate];
        }
    });
}

- (void)showInterstitialWithViewController:(UIViewController *)viewController
                             adapterConfig:(ISAdapterConfig *)adapterConfig
                                  delegate:(id<ISInterstitialAdapterDelegate>)delegate {
    
    NSString *zoneId = [self getZoneId:adapterConfig];
    LogAdapterApi_Internal(@"zoneId = %@", zoneId);
    
    ALAd *loadedAd = [_interstitialZoneIdToLoadedAds objectForKey:zoneId];
    ALInterstitialAd *ad = [_interstitialZoneIdToAd objectForKey:zoneId];
    
    if ([self hasInterstitialWithAdapterConfig:adapterConfig]) {
        [ad showAd:loadedAd];
    } else {
        NSError *error = [ISError createError:ERROR_CODE_NO_ADS_TO_SHOW
                                  withMessage:[NSString stringWithFormat: @"%@ show failed", kAdapterName]];
        
        [delegate adapterInterstitialDidFailToShowWithError:error];
    }
}

- (BOOL)hasInterstitialWithAdapterConfig:(ISAdapterConfig *)adapterConfig {
    NSString *zoneId = [self getZoneId:adapterConfig];
    ALInterstitialAd *ad = [_interstitialZoneIdToAd objectForKey:zoneId];
    ALAd *loadedAd = [_interstitialZoneIdToLoadedAds objectForKey:zoneId];
    return ad != nil && loadedAd != nil;
}

#pragma mark - Interstitial Delegate

- (void)onInterstitialDidLoad:(nonnull NSString *)zoneId
                       adView:(ALAd *)adView {
    LogAdapterDelegate_Internal(@"zoneId = %@", zoneId);
    id<ISInterstitialAdapterDelegate> delegate = [_interstitialZoneIdToSmashDelegate objectForKey:zoneId];
    
    [_interstitialZoneIdToLoadedAds setObject:adView
                                       forKey:zoneId];
    
    [delegate adapterInterstitialDidLoad];
}

- (void)onInterstitialDidOpen:(nonnull NSString *)zoneId {
    LogAdapterDelegate_Internal(@"zoneId = %@", zoneId);
    id<ISInterstitialAdapterDelegate> delegate = [_interstitialZoneIdToSmashDelegate objectForKey:zoneId];
    [_interstitialZoneIdToLoadedAds removeObjectForKey:zoneId];

    [delegate adapterInterstitialDidOpen];
    [delegate adapterInterstitialDidShow];
}

- (void)onInterstitialDidFailToLoad:(nonnull NSString *)zoneId
                          errorCode:(int)code {
    NSString *errorReason = [self getErrorMessage:code];
    LogAdapterDelegate_Internal(@"zoneId = %@ , error code = %d, %@", zoneId, code, errorReason);
    id<ISInterstitialAdapterDelegate> delegate = [_interstitialZoneIdToSmashDelegate objectForKey:zoneId];
    
    NSInteger errorCode = code == kALErrorCodeNoFill ? ERROR_IS_LOAD_NO_FILL : code;
    NSError *error = [[NSError alloc] initWithDomain:kAdapterName
                                                code:errorCode
                                            userInfo:@{NSLocalizedDescriptionKey:errorReason}];
    
    [delegate adapterInterstitialDidFailToLoadWithError:error];
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

- (void)initBannerWithUserId:(NSString *)userId
               adapterConfig:(ISAdapterConfig *)adapterConfig
                    delegate:(id<ISBannerAdapterDelegate>)delegate {
    
    NSString *sdkKey = adapterConfig.settings[kSdkKey];
    NSString *zoneId = [self getZoneId:adapterConfig];
    
    /* Configuration Validation */
    if (!sdkKey.length) {
        NSError *error = [self errorForMissingCredentialFieldWithName:kSdkKey];
        LogAdapterApi_Internal(@"error = %@", error.description);
        [delegate adapterBannerInitFailedWithError:error];
        return;
    }
    
    LogAdapterApi_Internal(@"sdkKey = %@, zoneId = %@", sdkKey, zoneId);
    
    ISApplovinBannerDelegate *bannerDelegate = [[ISApplovinBannerDelegate alloc] initWithZoneId:zoneId
                                                                                       delegate:self];
    
    //add to banner delegate map
    [_bannerZoneIdToAppLovinAdDelegate setObject:bannerDelegate
                                          forKey:zoneId];
    
    [_bannerZoneIdToSmashDelegate setObject:delegate
                                     forKey:zoneId];

    switch (_initState) {
        case INIT_STATE_NONE:
        case INIT_STATE_IN_PROGRESS:
            [self initSDKWithSDKKey:sdkKey];
            break;
        case INIT_STATE_SUCCESS:
            [delegate adapterBannerInitSuccess];
            break;
    }
}

- (void)loadBannerWithViewController:(UIViewController *)viewController
                                size:(ISBannerSize *)size
                       adapterConfig:(ISAdapterConfig *)adapterConfig
                            delegate:(id <ISBannerAdapterDelegate>)delegate {
    NSString *zoneId = [self getZoneId:adapterConfig];
    LogAdapterApi_Internal(@"zoneId = %@", zoneId);
    
    dispatch_async(dispatch_get_main_queue(), ^{
        
        // get banner size
        ALAdSize *applovinSize = [self getBannerSize:size];
        
        // verify size
        if (applovinSize) {
            // get delegate
            [self createBannerAd:applovinSize size:size zoneId:zoneId];
            
            ISApplovinBannerDelegate *bannerDelegate = [_bannerZoneIdToAppLovinAdDelegate objectForKey:zoneId];
            
            // load ad
            if ([zoneId isEqualToString:kDefaultZoneID]) {
                [_appLovinSDK.adService loadNextAd:applovinSize
                                         andNotify:bannerDelegate];
            } else {
                [_appLovinSDK.adService loadNextAdForZoneIdentifier:zoneId
                                                          andNotify:bannerDelegate];
            }
        } else {
            // size not supported
            NSError *error = [NSError errorWithDomain:kAdapterName
                                                 code:ERROR_BN_UNSUPPORTED_SIZE
                                             userInfo:@{NSLocalizedDescriptionKey:@"AppLovin unsupported banner size"}];
            
            [delegate adapterBannerDidFailToLoadWithError:error];
        }
    });
}

- (void)reloadBannerWithAdapterConfig:(ISAdapterConfig *)adapterConfig
                             delegate:(id <ISBannerAdapterDelegate>)delegate {
    LogInternal_Warning(@"Unsupported method");
}

- (void)destroyBannerWithAdapterConfig:(ISAdapterConfig *)adapterConfig {
    NSString *zoneId = [self getZoneId:adapterConfig];
    LogAdapterApi_Internal(@"zoneId = %@", zoneId);
    
    if ([_bannerZoneIdToAd hasObjectForKey:zoneId]) {
        [_bannerZoneIdToAd removeObjectForKey:zoneId];
    }
}

#pragma mark - Banner Delegate

- (void)onBannerDidLoad:(nonnull NSString *)zoneId
                 adView:(ALAd *)adView {
    
    LogAdapterDelegate_Internal(@"zoneId = %@", zoneId);
    id<ISBannerAdapterDelegate> delegate = [_bannerZoneIdToSmashDelegate objectForKey:zoneId];

    ALAdView *bannerAd = [_bannerZoneIdToAd objectForKey:zoneId];

    if (bannerAd == nil) {
        LogAdapterDelegate_Internal(@"bannerAd is nil");
        return;
    }
    
    [delegate adapterBannerDidLoad:bannerAd];
    [bannerAd render:adView];
}

- (void)onBannerDidFailToLoad:(nonnull NSString *)zoneId
                    errorCode:(int)code {
    NSString *errorReason = [self getErrorMessage:code];
    LogAdapterDelegate_Internal(@"zoneId = %@ , error code = %d, %@", zoneId, code, errorReason);
    id<ISBannerAdapterDelegate> delegate = [_bannerZoneIdToSmashDelegate objectForKey:zoneId];
    
    NSInteger errorCode = code == kALErrorCodeNoFill ? ERROR_BN_LOAD_NO_FILL : code;
    NSError *error = [[NSError alloc] initWithDomain:kAdapterName
                                                code:errorCode
                                            userInfo:@{NSLocalizedDescriptionKey:errorReason}];
    
    [delegate adapterBannerDidFailToLoadWithError:error];
}

- (void)onBannerDidShow:(nonnull NSString *)zoneId {
    LogAdapterDelegate_Internal(@"zoneId = %@", zoneId);
    id<ISBannerAdapterDelegate> delegate = [_bannerZoneIdToSmashDelegate objectForKey:zoneId];
    
    [delegate adapterBannerDidShow];
}

- (void)onBannerDidClick:(nonnull NSString *)zoneId {
    LogAdapterDelegate_Internal(@"zoneId = %@", zoneId);
    id<ISBannerAdapterDelegate> delegate = [_bannerZoneIdToSmashDelegate objectForKey:zoneId];
    
    [delegate adapterBannerDidClick];
}

- (void)onBannerWillLeaveApplication:(nonnull NSString *)zoneId {
    LogAdapterDelegate_Internal(@"zoneId = %@", zoneId);
    id<ISBannerAdapterDelegate> delegate = [_bannerZoneIdToSmashDelegate objectForKey:zoneId];
    
    [delegate adapterBannerWillLeaveApplication];
}

- (void)onBannerDidPresentFullscreen:(nonnull NSString *)zoneId {
    LogAdapterDelegate_Internal(@"zoneId = %@", zoneId);
    id<ISBannerAdapterDelegate> delegate = [_bannerZoneIdToSmashDelegate objectForKey:zoneId];
    
    [delegate adapterBannerWillPresentScreen];
}

- (void)onBannerDidDismissFullscreen:(nonnull NSString *)zoneId {
    LogAdapterDelegate_Internal(@"zoneId = %@", zoneId);
    id<ISBannerAdapterDelegate> delegate = [_bannerZoneIdToSmashDelegate objectForKey:zoneId];
    
    [delegate adapterBannerDidDismissScreen];
}

#pragma mark - Memory Handling

- (void)releaseMemoryWithAdapterConfig:(nonnull ISAdapterConfig *)adapterConfig {
    NSString *zoneId = [self getZoneId:adapterConfig];

    if ([_rewardedVideoZoneIdToAd hasObjectForKey:zoneId]) {
        [_rewardedVideoZoneIdToAd removeObjectForKey:zoneId];
        [_rewardedVideoZoneIdToAppLovinAdDelegate removeObjectForKey:zoneId];
        [_rewardedVideoZoneIdToSmashDelegate removeObjectForKey:zoneId];
        
    } else if ([_interstitialZoneIdToAd hasObjectForKey:zoneId]) {
        [_interstitialZoneIdToAd removeObjectForKey:zoneId];
        [_interstitialZoneIdToAppLovinAdDelegate removeObjectForKey:zoneId];
        [_interstitialZoneIdToSmashDelegate removeObjectForKey:zoneId];
        [_interstitialZoneIdToLoadedAds removeObjectForKey:zoneId];
        
    } else if ([_bannerZoneIdToAd hasObjectForKey:zoneId]) {
        [_bannerZoneIdToAd removeObjectForKey:zoneId];
        [_bannerZoneIdToAppLovinAdDelegate removeObjectForKey:zoneId];
        [_bannerZoneIdToSmashDelegate removeObjectForKey:zoneId];
        [_bannerZoneIdToAdSize removeObjectForKey:zoneId];
    }
}

#pragma mark - Legal Methods

- (void)setConsent:(BOOL)consent {
    LogAdapterApi_Internal(@"consent = %@", consent ? @"YES" : @"NO");
    [ALPrivacySettings setHasUserConsent: consent];
}

- (void)setCCPAValue:(BOOL)value {
    LogAdapterApi_Internal(@"value = %@", value ? @"YES" : @"NO");
    [ALPrivacySettings setDoNotSell:value];
}

- (void)setAgeRestricionValue:(BOOL)value {
    LogAdapterApi_Internal(@"value = %@", value ? @"YES" : @"NO");
    [ALPrivacySettings setIsAgeRestrictedUser:value];
}

- (void)setMetaDataWithKey:(NSString *)key
                 andValues:(NSMutableArray *)values {
    if (values.count == 0) {
        return;
    }
    
    // this is an array of 1 value
    NSString *value = values[0];
    LogAdapterApi_Internal(@"key = %@, value = %@", key, value);
    
    if ([ISMetaDataUtils isValidCCPAMetaDataWithKey:key
                                           andValue:value]) {
        [self setCCPAValue:[ISMetaDataUtils getCCPABooleanValue:value]];
    } else {
        NSString *ageRestrictionVal = [ISMetaDataUtils formatValue:value
                                                           forType:(META_DATA_VALUE_BOOL)];
        if ([self isValidAgeRestrictionMetaDataWithKey:key
                                              andValue:ageRestrictionVal]) {
            [self setAgeRestricionValue:[ISMetaDataUtils getCCPABooleanValue:ageRestrictionVal]];
        }
    }
}

//This method checks if the Meta Data key is the age restriction key and the value is valid
- (BOOL)isValidAgeRestrictionMetaDataWithKey:(NSString *)key
                                    andValue:(NSString *)value {
    return ([key caseInsensitiveCompare:kMetaDataAgeRestrictionKey] == NSOrderedSame && (value.length > 0));
}

#pragma mark - Helper Methods

- (ALIncentivizedInterstitialAd *)createRewardedVideoAd:(NSString *)zoneId {
    ALIncentivizedInterstitialAd *rewardedVideoAd;
    
    if ([zoneId isEqualToString:kDefaultZoneID]) {
        rewardedVideoAd = [[ALIncentivizedInterstitialAd alloc] initWithSdk:_appLovinSDK];
    } else {
        rewardedVideoAd = [[ALIncentivizedInterstitialAd alloc] initWithZoneIdentifier:zoneId
                                                                                   sdk:_appLovinSDK];
    }
    
    ISApplovinRewardedVideoDelegate *rewardedVideoDelegate = [_rewardedVideoZoneIdToAppLovinAdDelegate objectForKey:zoneId];
    
    rewardedVideoAd.adDisplayDelegate = rewardedVideoDelegate;
    rewardedVideoAd.adVideoPlaybackDelegate = rewardedVideoDelegate;
    
    [_rewardedVideoZoneIdToAd setObject:rewardedVideoAd
                                 forKey:zoneId];
    
    return rewardedVideoAd;
}

- (ALInterstitialAd *)createInterstitialAd:(NSString *)zoneId {
    ALInterstitialAd *interstitialAd = [[ALInterstitialAd alloc] initWithSdk:_appLovinSDK];
    
    ISApplovinInterstitialDelegate *interstitialAdDelegate = [_interstitialZoneIdToAppLovinAdDelegate objectForKey:zoneId];
    
    interstitialAd.adDisplayDelegate = interstitialAdDelegate;
    interstitialAd.adLoadDelegate = interstitialAdDelegate;
    
    [_interstitialZoneIdToAd setObject:interstitialAd
                                forKey:zoneId];
    
    return interstitialAd;
}

- (void)createBannerAd:(ALAdSize *)applovinSize
                  size:(ISBannerSize *)size
                zoneId:(NSString *)zoneId {
    ISApplovinBannerDelegate *bannerDelegate = [_bannerZoneIdToAppLovinAdDelegate objectForKey:zoneId];
    
    // create rect
    CGRect frame = [self getBannerFrame:size];
    
    // create banner view
    ALAdView *bnAd = [[ALAdView alloc] initWithFrame:frame
                                                size:applovinSize
                                                 sdk:_appLovinSDK];
    
    bnAd.adLoadDelegate = bannerDelegate;
    bnAd.adDisplayDelegate = bannerDelegate;
    bnAd.adEventDelegate = bannerDelegate;
    
    // add to dictionaries
    [_bannerZoneIdToAdSize setObject:applovinSize
                              forKey:zoneId];
    
    [_bannerZoneIdToAd setObject:bnAd
                          forKey:zoneId];
}

- (NSString *)getErrorMessage:(int)code {
    NSString *errorCode = @"Unknown error";
    
    switch (code) {
        case kALErrorCodeSdkDisabled:
            errorCode = @"The SDK is currently disabled.";
            break;
        case kALErrorCodeNoFill:
            errorCode = @"No ads are currently eligible for your device & location.";
            break;
        case kALErrorCodeAdRequestNetworkTimeout:
            errorCode = @"A fetch ad request timed out (usually due to poor connectivity).";
            break;
        case kALErrorCodeNotConnectedToInternet:
            errorCode = @"The device is not connected to internet (for instance if user is in Airplane mode).";
            break;
        case kALErrorCodeAdRequestUnspecifiedError:
            errorCode = @"An unspecified network issue occured.";
            break;
        case kALErrorCodeUnableToRenderAd:
            errorCode = @"There has been a failure to render an ad on screen.";
            break;
        case kALErrorCodeInvalidZone:
            errorCode = @"The zone provided is invalid; the zone needs to be added to your AppLovin account or may still be propagating to our servers.";
            break;
        case kALErrorCodeInvalidAdToken:
            errorCode = @"The provided ad token is invalid; ad token must be returned from AppLovin S2S integration.";
            break;
        case kALErrorCodeUnableToPrecacheResources:
            errorCode = @"An attempt to cache a resource to the filesystem failed; the device may be out of space.";
            break;
        case kALErrorCodeUnableToPrecacheImageResources:
            errorCode = @"An attempt to cache an image resource to the filesystem failed; the device may be out of space.";
            break;
        case kALErrorCodeUnableToPrecacheVideoResources:
            errorCode = @"An attempt to cache a video resource to the filesystem failed; the device may be out of space.";
            break;
        case kALErrorCodeInvalidResponse:
            errorCode = @"The AppLovin servers have returned an invalid response.";
            break;
        case kALErrorCodeIncentiviziedAdNotPreloaded:
            errorCode = @"The developer called for a rewarded video before one was available.";
            break;
        case kALErrorCodeIncentivizedUnknownServerError:
            errorCode = @"An unknown server-side error occurred.";
            break;
        case kALErrorCodeIncentivizedValidationNetworkTimeout:
            errorCode = @"A reward validation requested timed out (usually due to poor connectivity)";
            break;
        case kALErrorCodeIncentivizedUserClosedVideo:
            errorCode = @"The user exited out of the video early. You may or may not wish to grant a reward depending on your preference.";
            break;
        case kALErrorCodeInvalidURL:
            errorCode = @"A postback URL you attempted to dispatch was empty or nil.";
            break;
        default:
            errorCode = [NSString stringWithFormat:@"Unknown error code %d", code];
            break;
    }
    
    return errorCode;
}

- (ALAdSize *)getBannerSize:(ISBannerSize *)size {
    if ([size.sizeDescription isEqualToString:@"BANNER"] ||
        [size.sizeDescription isEqualToString:@"LARGE"]) {
        return ALAdSize.banner;
    } else if ([size.sizeDescription isEqualToString:@"RECTANGLE"]) {
        return ALAdSize.mrec;
    } else if ([size.sizeDescription isEqualToString:@"SMART"]) {
        if (UI_USER_INTERFACE_IDIOM() == UIUserInterfaceIdiomPad) {
            return ALAdSize.leader;
        } else {
            return ALAdSize.banner;
        }
    } else if (size.height >= 40 && size.height <= 60) {
        return ALAdSize.banner;
    }
    
    return nil;
}

- (CGRect)getBannerFrame:(ISBannerSize *)size {
    if ([size.sizeDescription isEqualToString:@"BANNER"] ||
        [size.sizeDescription isEqualToString:@"LARGE"]) {
        return CGRectMake(0, 0, 320, 50);
    } else if ([size.sizeDescription isEqualToString:@"RECTANGLE"]) {
        return CGRectMake(0, 0, 300, 250);
    } else if ([size.sizeDescription isEqualToString:@"SMART"]) {
        if (UI_USER_INTERFACE_IDIOM() == UIUserInterfaceIdiomPad) {
            return CGRectMake(0, 0, 728, 90);
        } else {
            return CGRectMake(0, 0, 320, 50);
        }
    } else if (size.height >= 40 && size.height <= 60) {
        return CGRectMake(0, 0, 320, 50);
    }
    
    return CGRectZero;
}

- (NSString *)getZoneId:(ISAdapterConfig *)adapterConfig {
    NSString *zoneId = adapterConfig.settings[kZoneID];
    
    if (!zoneId.length) {
        return kDefaultZoneID;
    }
    
    return zoneId;
}

- (void)setAppLovinUserId:(NSString *)userId {
    if (!userId.length) {
        LogAdapterApi_Internal(@"set userID to %@", userId);
        _appLovinSDK.userIdentifier = userId;
    }
}

@end

