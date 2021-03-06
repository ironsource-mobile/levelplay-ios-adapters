//
//  ISAppLovinAdapter.m
//  ISAppLovinAdapter
//
//  Created by Roni Pashani on 12/9/14.
//  Copyright (c) 2014 IronSource. All rights reserved.
//

#import "ISAppLovinAdapter.h"

#import "ISApplovinRewardedVideoListener.h"
#import "ISApplovinInterstitialListener.h"
#import "ISApplovinBannerListener.h"
#import "AppLovinSDK/AppLovinSDK.h"

// AppLovin keys
static NSString * const kSdkKey                    = @"sdkKey";
static NSString * const kMetaDataAgeRestrictionKey = @"AppLovin_AgeRestrictedUser";
static NSString * const kZoneID                    = @"zoneId";
static NSString * const kDefaultZoneID             = @"defaultZoneId";
static NSString * const kAdapterName               = @"AppLovin";

typedef NS_ENUM(NSInteger, InitState) {
    INIT_STATE_NONE,
    INIT_STATE_IN_PROGRESS,
    INIT_STATE_SUCCESS
};

// Handle init callback for all adapter instances
static InitState _initState = INIT_STATE_NONE;
static ConcurrentMutableSet<ISNetworkInitCallbackProtocol> *initCallbackDelegates = nil;

// AppLovin sdk instance
static ALSdk* _appLovinSDK = nil;

@interface ISAppLovinAdapter () <ISApplovinRewardedVideoListenerDelegate, ISApplovinInterstitialListenerDelegate, ISApplovinBannerListenerDelegate, ISNetworkInitCallbackProtocol> {
}
    
// Rewarded video
@property (nonatomic, strong) ConcurrentMutableDictionary *zoneIdToRewardedVideoSmashDelegate;
@property (nonatomic, strong) ConcurrentMutableDictionary *zoneIdToRewardedVideoListener;
@property (nonatomic, strong) ConcurrentMutableDictionary *zoneIdToRewardedVideoAd;
@property (nonatomic, strong) NSMutableSet                *zoneIdForRewardedVideoInitCallbacks;

// Interstitial
@property (nonatomic, strong) ConcurrentMutableDictionary *zoneIdToInterstitialSmashDelegate;
@property (nonatomic, strong) ConcurrentMutableDictionary *zoneIdToInterstitialListener;
@property (nonatomic, strong) ConcurrentMutableDictionary *zoneIdToInterstitialAd;
@property (nonatomic, strong) ConcurrentMutableDictionary *zoneIdToInterstitialLoadedAds;

// Banner
@property (nonatomic, strong) ConcurrentMutableDictionary *zoneIdToBannerSmashDelegate;
@property (nonatomic, strong) ConcurrentMutableDictionary *zoneIdToBannerListener;
@property (nonatomic, strong) ConcurrentMutableDictionary *zoneIdToBannerAd;
@property (nonatomic, strong) ConcurrentMutableDictionary *zoneIdToBannerAdSize;

@end

@implementation ISAppLovinAdapter

#pragma mark - IronSource Protocol Methods

- (NSString *)version {
    return AppLovinAdapterVersion;
}

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

- (NSString *)sdkName {
    return @"ALSdk";
}

#pragma mark - Initializations Methods And Callbacks

- (instancetype)initAdapter:(NSString *)name {
    self = [super initAdapter:name];
    
    if (self) {
        if (initCallbackDelegates == nil) {
            initCallbackDelegates =  [ConcurrentMutableSet<ISNetworkInitCallbackProtocol> set];
        }
        
        // Rewarded video
        _zoneIdToRewardedVideoSmashDelegate = [ConcurrentMutableDictionary dictionary];
        _zoneIdToRewardedVideoListener = [ConcurrentMutableDictionary dictionary];
        _zoneIdToRewardedVideoAd = [ConcurrentMutableDictionary dictionary];
        _zoneIdForRewardedVideoInitCallbacks = [[NSMutableSet alloc] init];

        // Interstitial
        _zoneIdToInterstitialSmashDelegate = [ConcurrentMutableDictionary dictionary];
        _zoneIdToInterstitialListener = [ConcurrentMutableDictionary dictionary];
        _zoneIdToInterstitialAd = [ConcurrentMutableDictionary dictionary];
        _zoneIdToInterstitialLoadedAds = [ConcurrentMutableDictionary dictionary];
        
        // Banner
        _zoneIdToBannerAd = [ConcurrentMutableDictionary dictionary];
        _zoneIdToBannerSmashDelegate = [ConcurrentMutableDictionary dictionary];
        _zoneIdToBannerListener = [ConcurrentMutableDictionary dictionary];
        _zoneIdToBannerAdSize = [ConcurrentMutableDictionary dictionary];
                
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
                _initState = INIT_STATE_SUCCESS;
                
                NSArray *initDelegatesList = initCallbackDelegates.allObjects;
                
                for (id<ISNetworkInitCallbackProtocol> initDelegate in initDelegatesList) {
                    [initDelegate onNetworkInitCallbackSuccess];
                }
                
                [initCallbackDelegates removeAllObjects];
            }];
        });
    });
}

- (void)onNetworkInitCallbackSuccess {
    LogAdapterDelegate_Internal(@"");
    
    // Rewarded video
    NSArray *rewardedVideoZoneIds = _zoneIdToRewardedVideoSmashDelegate.allKeys;
    
    for (NSString *zoneId in rewardedVideoZoneIds) {
        if ([_zoneIdForRewardedVideoInitCallbacks containsObject:zoneId]) {
            id<ISRewardedVideoAdapterDelegate> delegate = [_zoneIdToRewardedVideoSmashDelegate objectForKey:zoneId];
            [delegate adapterRewardedVideoInitSuccess];
        } else {
            [self loadRewardedVideoInternalWithZoneId:zoneId];
        }
    }
    
    // Interstitial
    NSArray *interstitialZoneIds = _zoneIdToInterstitialSmashDelegate.allKeys;
    
    for (NSString *zoneId in interstitialZoneIds) {
        id<ISInterstitialAdapterDelegate> delegate = [_zoneIdToInterstitialSmashDelegate objectForKey:zoneId];
        [delegate adapterInterstitialInitSuccess];
    }
    
    // Banner
    NSArray *bannerZoneIds = _zoneIdToBannerSmashDelegate.allKeys;
    
    for (NSString *zoneId in bannerZoneIds) {
        id<ISBannerAdapterDelegate> delegate = [_zoneIdToBannerSmashDelegate objectForKey:zoneId];
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
    LogAdapterApi_Internal(@"");
    NSString *sdkKey = adapterConfig.settings[kSdkKey];
    NSString *zoneId = [self getZoneId:adapterConfig];

    if (!sdkKey.length) {
        NSError *error = [self errorForMissingCredentialFieldWithName:kSdkKey];
        LogAdapterApi_Internal(@"failed - error.description = %@", error.description);
        [delegate adapterRewardedVideoInitFailed:error];
        return;
    }
    
    LogAdapterApi_Internal(@"zoneId = %@, sdkKey = %@", zoneId, sdkKey);
    
    // create the ad listener
    ISApplovinRewardedVideoListener *listener = [[ISApplovinRewardedVideoListener alloc] initWithZoneId:zoneId
                                                                      andDelegate:self];
    [_zoneIdToRewardedVideoListener setObject:listener
                                       forKey:zoneId];
    
    // save smash delegate
    [_zoneIdToRewardedVideoSmashDelegate setObject:delegate
                                            forKey:zoneId];
    
    // add rewarded video for init callback
    [_zoneIdForRewardedVideoInitCallbacks addObject:zoneId];
    
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
    LogAdapterApi_Internal(@"");
    NSString *sdkKey = adapterConfig.settings[kSdkKey];
    NSString *zoneId = [self getZoneId:adapterConfig];
    
    if (!sdkKey.length) {
        NSError *error = [self errorForMissingCredentialFieldWithName:kSdkKey];
        LogAdapterApi_Internal(@"failed - error.description = %@", error.description);
        [delegate adapterRewardedVideoHasChangedAvailability:NO];
        return;
    }
    
    LogAdapterApi_Internal(@"zoneId = %@, sdkKey = %@", zoneId, sdkKey);
    
    // create the ad listener
    ISApplovinRewardedVideoListener *listener = [[ISApplovinRewardedVideoListener alloc] initWithZoneId:zoneId
                                                                                            andDelegate:self];
    [_zoneIdToRewardedVideoListener setObject:listener
                                       forKey:zoneId];
    
    // save smash delegate
    [_zoneIdToRewardedVideoSmashDelegate setObject:delegate
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
    LogAdapterApi_Internal(@"");
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
    
    ISApplovinRewardedVideoListener *listener = [_zoneIdToRewardedVideoListener objectForKey:zoneId];
    [ad preloadAndNotify:listener];
}

- (void)showRewardedVideoWithViewController:(UIViewController *)viewController
                              adapterConfig:(ISAdapterConfig *)adapterConfig
                                   delegate:(id<ISRewardedVideoAdapterDelegate>)delegate {
    NSString *zoneId = [self getZoneId:adapterConfig];
    LogAdapterApi_Internal(@"zoneId = %@", zoneId);
    
    ALIncentivizedInterstitialAd *ad = [_zoneIdToRewardedVideoAd objectForKey:zoneId];
    ISApplovinRewardedVideoListener *listener = [_zoneIdToRewardedVideoListener objectForKey:zoneId];

    [delegate adapterRewardedVideoHasChangedAvailability:NO];

    if ([self hasRewardedVideoWithAdapterConfig:adapterConfig]) {
        [self setAppLovinUserId:self.dynamicUserId];
        [ad showAndNotify:listener];
    } else {
        NSError *error = [ISError createError:ERROR_CODE_NO_ADS_TO_SHOW withMessage:[NSString stringWithFormat: @"%@ show failed", kAdapterName]];
        LogAdapterApi_Internal(@"error = %@", error);
        [delegate adapterRewardedVideoDidFailToShowWithError:error];
    }
}

- (BOOL)hasRewardedVideoWithAdapterConfig:(ISAdapterConfig *)adapterConfig {
    NSString *zoneId = [self getZoneId:adapterConfig];
    ALIncentivizedInterstitialAd *ad = [_zoneIdToRewardedVideoAd objectForKey:zoneId];
    return ad != nil && [ad isReadyForDisplay];
}

#pragma mark - Rewarded Video Delegate

- (void)onRewardedVideoDidLoad:(NSString *)zoneId {
    LogAdapterDelegate_Internal(@"zoneId = %@", zoneId);
    id<ISRewardedVideoAdapterDelegate> delegate = [_zoneIdToRewardedVideoSmashDelegate objectForKey:zoneId];
    
    if (delegate != nil) {
        [delegate adapterRewardedVideoHasChangedAvailability:YES];
    }
}

- (void)onRewardedVideoDidFailToLoadWithError:(int)code
                                       zoneId:(NSString *)zoneId {
    NSString *errorReason = [self getErrorMessage:code];
    LogAdapterDelegate_Internal(@"zoneId = %@ , error code = %d, %@", zoneId, code, errorReason);
    id<ISRewardedVideoAdapterDelegate> delegate = [_zoneIdToRewardedVideoSmashDelegate objectForKey:zoneId];
    
    if (delegate != nil) {
        [delegate adapterRewardedVideoHasChangedAvailability:NO];
        NSInteger errorCode = code == kALErrorCodeNoFill ? ERROR_RV_LOAD_NO_FILL : code;
        NSError *error = [NSError errorWithDomain:kAdapterName
                                             code:errorCode
                                         userInfo:@{NSLocalizedDescriptionKey:errorReason}];
        [delegate adapterRewardedVideoDidFailToLoadWithError:error];
    }
}

- (void)onRewardedVideoDidOpen:(UIView *)view
                        zoneId:(NSString *)zoneId {
    LogAdapterDelegate_Internal(@"zoneId = %@", zoneId);
    id<ISRewardedVideoAdapterDelegate> delegate = [_zoneIdToRewardedVideoSmashDelegate objectForKey:zoneId];
    
    if (delegate != nil) {
        [delegate adapterRewardedVideoDidOpen];
    }
}

- (void)onRewardedVideoDidStart:(NSString *)zoneId {
    LogAdapterDelegate_Internal(@"zoneId = %@", zoneId);
    id<ISRewardedVideoAdapterDelegate> delegate = [_zoneIdToRewardedVideoSmashDelegate objectForKey:zoneId];
    
    if (delegate != nil) {
        [delegate adapterRewardedVideoDidStart];
    }
}

- (void)onRewardedVideoDidClick:(UIView *)view
                         zoneId:(NSString *)zoneId {
    LogAdapterDelegate_Internal(@"zoneId = %@", zoneId);
    id<ISRewardedVideoAdapterDelegate> delegate = [_zoneIdToRewardedVideoSmashDelegate objectForKey:zoneId];
    
    if (delegate != nil) {
        [delegate adapterRewardedVideoDidClick];
    }
}

- (void)onRewardedVideoDidEnd:(NSString *)zoneId
             didReceiveReward:(BOOL)wasFullyWatched {
    LogAdapterDelegate_Internal(@"zoneId = %@ fullyWatched = %d", zoneId, wasFullyWatched);
    id<ISRewardedVideoAdapterDelegate> delegate = [_zoneIdToRewardedVideoSmashDelegate objectForKey:zoneId];
    
    if (delegate != nil) {
        [delegate adapterRewardedVideoDidEnd];
        
        if (wasFullyWatched) {
            [delegate adapterRewardedVideoDidReceiveReward];
        }
    }
}

- (void)onRewardedVideoDidClose:(UIView *)view
                         zoneId:(NSString *)zoneId {
    LogAdapterDelegate_Internal(@"zoneId = %@", zoneId);
    id<ISRewardedVideoAdapterDelegate> delegate = [_zoneIdToRewardedVideoSmashDelegate objectForKey:zoneId];
    
    if (delegate != nil) {
        [delegate adapterRewardedVideoDidClose];
    }
}


#pragma mark - Interstitial API

- (void)initInterstitialWithUserId:(NSString *)userId
                     adapterConfig:(ISAdapterConfig *)adapterConfig
                          delegate:(id<ISInterstitialAdapterDelegate>)delegate {
    LogAdapterApi_Internal(@"");
    NSString *sdkKey = adapterConfig.settings[kSdkKey];
    NSString *zoneId = [self getZoneId:adapterConfig];

    if (!sdkKey.length) {
        NSError *error = [self errorForMissingCredentialFieldWithName:kSdkKey];
        LogAdapterApi_Internal(@"failed - error.description = %@", error.description);
        [delegate adapterInterstitialInitFailedWithError:error];
        return;
    }

    LogAdapterApi_Internal(@"sdkKey = %@, zoneId = %@", sdkKey, zoneId);
    
    // create the ad listener
    ISApplovinInterstitialListener *listener = [[ISApplovinInterstitialListener alloc] initWithZoneId:zoneId
                                                                      andDelegate:self];
    [_zoneIdToInterstitialListener setObject:listener
                                      forKey:zoneId];
    
    // save smash delegate
    [_zoneIdToInterstitialSmashDelegate setObject:delegate
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
        
        ISApplovinInterstitialListener *listener = [_zoneIdToInterstitialListener objectForKey:zoneId];
        
        if ([zoneId isEqualToString:kDefaultZoneID]) {
            [[_appLovinSDK adService] loadNextAd:ALAdSize.interstitial
                                       andNotify:listener];
        } else {
            [[_appLovinSDK adService] loadNextAdForZoneIdentifier:zoneId
                                                        andNotify:listener];
        }
    });
}

- (void)showInterstitialWithViewController:(UIViewController *)viewController
                             adapterConfig:(ISAdapterConfig *)adapterConfig
                                  delegate:(id<ISInterstitialAdapterDelegate>)delegate {
    LogAdapterApi_Internal(@"");
    NSString *zoneId = [self getZoneId:adapterConfig];
    ALAd *loadedAd = [_zoneIdToInterstitialLoadedAds objectForKey:zoneId];
    ALInterstitialAd *ad = [_zoneIdToInterstitialAd objectForKey:zoneId];
    
    if ([self hasInterstitialWithAdapterConfig:adapterConfig]) {
        [ad showAd:loadedAd];
    } else {
        NSError *error = [ISError createError:ERROR_CODE_NO_ADS_TO_SHOW withMessage:[NSString stringWithFormat: @"%@ show failed", kAdapterName]];
        LogAdapterApi_Internal(@"error = %@", error);
        [delegate adapterInterstitialDidFailToShowWithError:error];
    }
}

- (BOOL)hasInterstitialWithAdapterConfig:(ISAdapterConfig *)adapterConfig {
    NSString *zoneId = [self getZoneId:adapterConfig];
    ALInterstitialAd *ad = [_zoneIdToInterstitialAd objectForKey:zoneId];
    ALAd *loadedAd = [_zoneIdToInterstitialLoadedAds objectForKey:zoneId];
    return ad != nil && loadedAd != nil;
}

#pragma mark - Interstitial Delegate

- (void)onInterstitialDidLoad:(NSString *)zoneId
                           ad:(ALAd *)ad {
    LogAdapterDelegate_Internal(@"zoneId = %@", zoneId);
    id<ISInterstitialAdapterDelegate> delegate = [_zoneIdToInterstitialSmashDelegate objectForKey:zoneId];
    [_zoneIdToInterstitialLoadedAds setObject:ad
                                        forKey:zoneId];
    
    if (delegate != nil) {
        [delegate adapterInterstitialDidLoad];
    }
}

- (void)onInterstitialDidOpen:(UIView *)view
                       zoneId:(NSString *)zoneId {
    LogAdapterDelegate_Internal(@"zoneId = %@", zoneId);
    id<ISInterstitialAdapterDelegate> delegate = [_zoneIdToInterstitialSmashDelegate objectForKey:zoneId];
    [_zoneIdToInterstitialLoadedAds removeObjectForKey:zoneId];

    if (delegate != nil) {
        [delegate adapterInterstitialDidOpen];
        [delegate adapterInterstitialDidShow];
    }
}

- (void)onInterstitialDidFailToLoadWithError:(int)code
                                      zoneId:(NSString *)zoneId {
    NSString *errorReason = [self getErrorMessage:code];
    LogAdapterDelegate_Internal(@"zoneId = %@ , error code = %d, %@", zoneId, code, errorReason);
    id<ISInterstitialAdapterDelegate> delegate = [_zoneIdToInterstitialSmashDelegate objectForKey:zoneId];
    
    if (delegate != nil) {
        NSInteger errorCode = code == kALErrorCodeNoFill ? ERROR_IS_LOAD_NO_FILL : code;
        NSError *error = [[NSError alloc] initWithDomain:kAdapterName
                                                    code:errorCode
                                                userInfo:@{NSLocalizedDescriptionKey:errorReason}];
        [delegate adapterInterstitialDidFailToLoadWithError:error];
    }
}

- (void)onInterstitialDidClick:(UIView *)view
                        zoneId:(NSString *)zoneId {
    LogAdapterDelegate_Internal(@"zoneId = %@", zoneId);
    id<ISInterstitialAdapterDelegate> delegate = [_zoneIdToInterstitialSmashDelegate objectForKey:zoneId];
    
    if (delegate != nil) {
        [delegate adapterInterstitialDidClick];
    }
}

- (void)onInterstitialDidClose:(UIView *)view
                        zoneId:(NSString *)zoneId {
    LogAdapterDelegate_Internal(@"zoneId = %@", zoneId);
    id<ISInterstitialAdapterDelegate> delegate = [_zoneIdToInterstitialSmashDelegate objectForKey:zoneId];
    
    if (delegate != nil) {
        [delegate adapterInterstitialDidClose];
    }
}

#pragma mark - Banner API

- (void)initBannerWithUserId:(nonnull NSString *)userId
               adapterConfig:(nonnull ISAdapterConfig *)adapterConfig
                    delegate:(nonnull id<ISBannerAdapterDelegate>)delegate {
    LogAdapterApi_Internal(@"");
    NSString *sdkKey = adapterConfig.settings[kSdkKey];
    NSString *zoneId = [self getZoneId:adapterConfig];
    
    if (!sdkKey.length) {
        NSError *error = [self errorForMissingCredentialFieldWithName:kSdkKey];
        LogAdapterApi_Internal(@"failed - error.description = %@", error.description);
        [delegate adapterBannerInitFailedWithError:error];
        return;
    }
    
    LogAdapterApi_Internal(@"sdkKey = %@, zoneId = %@", sdkKey, zoneId);

    // create the ad listener
    ISApplovinBannerListener *bnListener = [[ISApplovinBannerListener alloc] initWithZoneId:zoneId
                                                                                andDelegate:self];
    [_zoneIdToBannerListener setObject:bnListener
                                forKey:zoneId];
    
    // save smash listener
    [_zoneIdToBannerSmashDelegate setObject:delegate
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

- (void)loadBannerWithViewController:(nonnull UIViewController *)viewController
                                size:(ISBannerSize *)size
                       adapterConfig:(nonnull ISAdapterConfig *)adapterConfig
                            delegate:(nonnull id <ISBannerAdapterDelegate>)delegate {
    NSString *zoneId = [self getZoneId:adapterConfig];
    LogAdapterApi_Internal(@"zoneId = %@", zoneId);
    
    dispatch_async(dispatch_get_main_queue(), ^{
        
        // get banner size
        ALAdSize *applovinSize = [self getBannerSize:size];
        
        // verify size
        if (applovinSize) {
            // get listener
            [self createBannerAd:applovinSize size:size zoneId:zoneId];
            
            ISApplovinBannerListener *bnListener = [_zoneIdToBannerListener objectForKey:zoneId];
            
            // load ad
            if ([zoneId isEqualToString:kDefaultZoneID]) {
                [_appLovinSDK.adService loadNextAd:applovinSize
                                         andNotify:bnListener];
            } else {
                [_appLovinSDK.adService loadNextAdForZoneIdentifier:zoneId
                                                          andNotify:bnListener];
            }
        } else {
            // size not supported
            NSError *error = [ISError createError:ERROR_BN_UNSUPPORTED_SIZE
                                      withMessage:@"AppLovin unsupported banner size"];
            LogAdapterApi_Internal(@"error = %@", error);
            [delegate adapterBannerDidFailToLoadWithError:error];
        }
    });
}

- (void)reloadBannerWithAdapterConfig:(nonnull ISAdapterConfig *)adapterConfig
                             delegate:(nonnull id <ISBannerAdapterDelegate>)delegate {
    LogInternal_Warning(@"Unsupported method");
}

- (void)destroyBannerWithAdapterConfig:(nonnull ISAdapterConfig *)adapterConfig {
    LogAdapterApi_Internal(@"");
    NSString *zoneId = [self getZoneId:adapterConfig];
    
    if ([_zoneIdToBannerAd hasObjectForKey:zoneId]) {
        [_zoneIdToBannerAd removeObjectForKey:zoneId];
    }
}

#pragma mark - Banner Delegate

- (void)onBannerLoadSuccess:(ALAd *)ad
                 zoneID:(NSString *)zoneId {
    LogAdapterDelegate_Internal(@"zoneId = %@", zoneId);
    ALAdView *bannerAd = [_zoneIdToBannerAd objectForKey:zoneId];
    id<ISBannerAdapterDelegate> bnSmashDelegate = [_zoneIdToBannerSmashDelegate objectForKey:zoneId];
    
    if (bannerAd == nil) {
        LogAdapterDelegate_Internal(@"bannerAd is nil");
        return;
    }
    
    if (bnSmashDelegate == nil) {
        LogAdapterDelegate_Internal(@"bnSmashDelegate is nil");
        return;
    }
    
    [bnSmashDelegate adapterBannerDidLoad:bannerAd];
    [bannerAd render:ad];
}

- (void)onBannerLoadFail:(NSString *)zoneId
                   error:(int)code {
    NSString *errorReason = [self getErrorMessage:code];
    LogAdapterDelegate_Internal(@"zoneId = %@ , error code = %d, %@", zoneId, code, errorReason);
    id<ISBannerAdapterDelegate> delegate = [_zoneIdToBannerSmashDelegate objectForKey:zoneId];
    
    if (delegate != nil) {
        NSInteger errorCode = code == kALErrorCodeNoFill ? ERROR_BN_LOAD_NO_FILL : code;
        NSError *error = [[NSError alloc] initWithDomain:kAdapterName
                                                    code:errorCode
                                                userInfo:@{NSLocalizedDescriptionKey:errorReason}];
        [delegate adapterBannerDidFailToLoadWithError:error];
    }
}

- (void)onBannerDidShow:(UIView *)view
                 zoneID:(NSString *)zoneId {
    LogAdapterDelegate_Internal(@"zoneId = %@", zoneId);
    id<ISBannerAdapterDelegate> bnSmashDelegate = [_zoneIdToBannerSmashDelegate objectForKey:zoneId];
    
    if (bnSmashDelegate != nil) {
        [bnSmashDelegate adapterBannerDidShow];
    }
}

- (void)onBannerDidClick:(NSString *)zoneId {
    LogAdapterDelegate_Internal(@"zoneId = %@", zoneId);
    id<ISBannerAdapterDelegate> bnSmashDelegate = [_zoneIdToBannerSmashDelegate objectForKey:zoneId];
    
    if (bnSmashDelegate != nil) {
        [bnSmashDelegate adapterBannerDidClick];
    }
}

- (void)onBannerWillLeaveApplication:(NSString *)zoneId {
    LogAdapterDelegate_Internal(@"zoneId = %@", zoneId);
    id<ISBannerAdapterDelegate> bnSmashDelegate = [_zoneIdToBannerSmashDelegate objectForKey:zoneId];
    
    if (bnSmashDelegate != nil) {
        [bnSmashDelegate adapterBannerWillLeaveApplication];
    }
}

- (void)onBannerDidPresentFullscreen:(NSString *)zoneId {
    LogAdapterDelegate_Internal(@"zoneId = %@", zoneId);
    id<ISBannerAdapterDelegate> bnSmashDelegate = [_zoneIdToBannerSmashDelegate objectForKey:zoneId];
    
    if (bnSmashDelegate != nil) {
        [bnSmashDelegate adapterBannerWillPresentScreen];
    }
}

- (void)onBannerDidDismissFullscreen:(NSString *)zoneId {
    LogAdapterDelegate_Internal(@"zoneId = %@", zoneId);
    id<ISBannerAdapterDelegate> bnSmashDelegate = [_zoneIdToBannerSmashDelegate objectForKey:zoneId];
    
    if (bnSmashDelegate != nil) {
        [bnSmashDelegate adapterBannerDidDismissScreen];
    }
}

#pragma mark - Memory Handling

- (void)releaseMemoryWithAdapterConfig:(nonnull ISAdapterConfig *)adapterConfig {
    NSString *zoneId = [self getZoneId:adapterConfig];

    if ([_zoneIdToRewardedVideoAd hasObjectForKey:zoneId]) {
        [_zoneIdToRewardedVideoAd removeObjectForKey:zoneId];
        [_zoneIdToRewardedVideoListener removeObjectForKey:zoneId];
        [_zoneIdToRewardedVideoSmashDelegate removeObjectForKey:zoneId];
    } else if ([_zoneIdToInterstitialAd hasObjectForKey:zoneId]) {
        [_zoneIdToInterstitialAd removeObjectForKey:zoneId];
        [_zoneIdToInterstitialListener removeObjectForKey:zoneId];
        [_zoneIdToInterstitialSmashDelegate removeObjectForKey:zoneId];
        [_zoneIdToInterstitialLoadedAds removeObjectForKey:zoneId];
    } else if ([_zoneIdToBannerAd hasObjectForKey:zoneId]) {
        [_zoneIdToBannerAd removeObjectForKey:zoneId];
        [_zoneIdToBannerListener removeObjectForKey:zoneId];
        [_zoneIdToBannerSmashDelegate removeObjectForKey:zoneId];
        [_zoneIdToBannerAdSize removeObjectForKey:zoneId];
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
    }
    
    NSString *ageRestrictionVal = [ISMetaDataUtils formatValue:value
                                                       forType:(META_DATA_VALUE_BOOL)];
    if ([self isValidAgeRestrictionMetaDataWithKey:key
                                          andValue:ageRestrictionVal]) {
        [self setAgeRestricionValue:[ISMetaDataUtils getCCPABooleanValue:ageRestrictionVal]];
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
        rewardedVideoAd =  [[ALIncentivizedInterstitialAd alloc] initWithSdk:_appLovinSDK];
    } else {
        rewardedVideoAd = [[ALIncentivizedInterstitialAd alloc] initWithZoneIdentifier:zoneId
                                                                                   sdk:_appLovinSDK];
    }
    
    ISApplovinRewardedVideoListener *listener = [_zoneIdToRewardedVideoListener objectForKey:zoneId];
    rewardedVideoAd.adDisplayDelegate = listener;
    rewardedVideoAd.adVideoPlaybackDelegate = listener;
    [_zoneIdToRewardedVideoAd setObject:rewardedVideoAd
                                 forKey:zoneId];
    
    return rewardedVideoAd;
}

- (ALInterstitialAd *)createInterstitialAd:(NSString *)zoneId {
    ALInterstitialAd *interstitialAd = [[ALInterstitialAd alloc] initWithSdk:_appLovinSDK];
    ISApplovinInterstitialListener *listener = [_zoneIdToInterstitialListener objectForKey:zoneId];
    interstitialAd.adDisplayDelegate = listener;
    interstitialAd.adLoadDelegate = listener;
    
    [_zoneIdToInterstitialAd setObject:interstitialAd
                                forKey:zoneId];
    
    return interstitialAd;
}

- (void)createBannerAd:(ALAdSize *)applovinSize
                  size:(ISBannerSize * _Nonnull)size
                zoneId:(NSString *)zoneId {
    ISApplovinBannerListener *bnListener = [_zoneIdToBannerListener objectForKey:zoneId];
    
    // create rect
    CGRect frame = [self getBannerFrame:size];
    
    // create banner view
    ALAdView *bnAd = [[ALAdView alloc] initWithFrame:frame
                                                size:applovinSize
                                                 sdk:_appLovinSDK];
    
    bnAd.adLoadDelegate = bnListener;
    bnAd.adDisplayDelegate = bnListener;
    bnAd.adEventDelegate = bnListener;
    
    // add to dictionaries
    [_zoneIdToBannerAdSize setObject:applovinSize
                              forKey:zoneId];
    [_zoneIdToBannerAd setObject:bnAd
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

