//
//  ISAppLovinAdapter.m
//  ISAppLovinAdapter
//
//  Copyright © 2024 ironSource Mobile Ltd. All rights reserved.
//

#import <ISAppLovinAdapter.h>
#import <ISAppLovinRewardedVideoDelegate.h>
#import <ISAppLovinInterstitialDelegate.h>
#import <ISAppLovinBannerDelegate.h>
#import "ISAppLovinAdHolder.h"
#import <AppLovinSDK/AppLovinSDK.h>

// Network keys
static NSString * const kAdapterVersion            = AppLovinAdapterVersion;
static NSString * const kAdapterName               = @"AppLovin";
static NSString * const kSdkKey                    = @"sdkKey";
static NSString * const kZoneID                    = @"zoneId";
static NSString * const kDefaultZoneID             = @"defaultZoneId";

// init state possible values
typedef NS_ENUM(NSInteger, InitState) {
    INIT_STATE_NONE,
    INIT_STATE_IN_PROGRESS,
    INIT_STATE_SUCCESS
};

// Handle init callback for all adapter instances
static ISConcurrentMutableSet<ISNetworkInitCallbackProtocol> *initCallbackDelegates = nil;
static InitState initState = INIT_STATE_NONE;

// Rewarded Video
static ISAppLovinAdHolder<ALIncentivizedInterstitialAd *> *rewardedVideoAds;

// Interstitial
static ISAppLovinAdHolder<ALInterstitialAd *> *interstitialAds;

// AppLovin sdk instance
static ALSdk* appLovinSDK = nil;

static ALSdkInitializationConfigurationBuilder* appLovinSettingsBuilder = nil;

@interface ISAppLovinAdapter () <ISAppLovinRewardedVideoDelegateWrapper, ISAppLovinInterstitialDelegateWrapper, ISAppLovinBannerDelegateWrapper, ISNetworkInitCallbackProtocol>
    
// Rewarded video
@property (nonatomic, strong) ISConcurrentMutableDictionary *rewardedVideoZoneIdToSmashDelegate;
@property (nonatomic, strong) ISConcurrentMutableDictionary *rewardedVideoZoneIdToAppLovinAdDelegate;
@property (nonatomic, strong) ISConcurrentMutableSet        *rewardedVideoZoneIdForInitCallbacks;
@property (nonatomic, strong, nullable) NSString            *rewardedVideoZoneId;

// Interstitial
@property (nonatomic, strong) ISConcurrentMutableDictionary *interstitialZoneIdToSmashDelegate;
@property (nonatomic, strong) ISConcurrentMutableDictionary *interstitialZoneIdToAppLovinAdDelegate;
@property (nonatomic, strong) ISConcurrentMutableDictionary *interstitialZoneIdToLoadedAds;
@property (nonatomic, strong, nullable) NSString            *interstitialZoneId;

// Banner
@property (nonatomic, strong) ISConcurrentMutableDictionary *bannerZoneIdToSmashDelegate;
@property (nonatomic, strong) ISConcurrentMutableDictionary *bannerZoneIdToAppLovinAdDelegate;
@property (nonatomic, strong) ISConcurrentMutableDictionary *bannerZoneIdToAd;
@property (nonatomic, strong) ISConcurrentMutableDictionary *bannerZoneIdToAdSize;

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

#pragma mark - Initializations Methods And Callbacks

- (instancetype)initAdapter:(NSString *)name {
    self = [super initAdapter:name];
    
    if (self) {
        if (initCallbackDelegates == nil) {
            initCallbackDelegates = [ISConcurrentMutableSet<ISNetworkInitCallbackProtocol> set];
        }
        
        // Rewarded video
        _rewardedVideoZoneIdToSmashDelegate         = [ISConcurrentMutableDictionary dictionary];
        _rewardedVideoZoneIdToAppLovinAdDelegate    = [ISConcurrentMutableDictionary dictionary];
        _rewardedVideoZoneIdForInitCallbacks        = [ISConcurrentMutableSet set];

        // Interstitial
        _interstitialZoneIdToSmashDelegate          = [ISConcurrentMutableDictionary dictionary];
        _interstitialZoneIdToAppLovinAdDelegate     = [ISConcurrentMutableDictionary dictionary];
        _interstitialZoneIdToLoadedAds              = [ISConcurrentMutableDictionary dictionary];
        
        // Banner
        _bannerZoneIdToAd                           = [ISConcurrentMutableDictionary dictionary];
        _bannerZoneIdToSmashDelegate                = [ISConcurrentMutableDictionary dictionary];
        _bannerZoneIdToAppLovinAdDelegate           = [ISConcurrentMutableDictionary dictionary];
        _bannerZoneIdToAdSize                       = [ISConcurrentMutableDictionary dictionary];
                
        // The network's capability to load a Rewarded Video ad while another Rewarded Video ad of that network is showing
        LWSState = LOAD_WHILE_SHOW_BY_INSTANCE;
    }
    
    return self;
}

- (void)initSDKWithSDKKey:(NSString *)sdkKey {
    
    // add self to the init delegates only in case the initialization has not finished yet
    if (initState == INIT_STATE_NONE || initState == INIT_STATE_IN_PROGRESS) {
        [initCallbackDelegates addObject:self];
    }
    
    static dispatch_once_t initSdkOnceToken;
    dispatch_once(&initSdkOnceToken, ^{
        initState = INIT_STATE_IN_PROGRESS;
        
        rewardedVideoAds = [[ISAppLovinAdHolder alloc] init];
        interstitialAds = [[ISAppLovinAdHolder alloc] init];
        
        dispatch_async(dispatch_get_main_queue(), ^{
            
            appLovinSDK = [ALSdk shared];
            
            // Create the initialization configuration
            ALSdkInitializationConfiguration *initConfig = [ALSdkInitializationConfiguration configurationWithSdkKey:sdkKey builderBlock:^(ALSdkInitializationConfigurationBuilder *builder) {

              builder.mediationProvider = ALMediationProviderIronsource;
              appLovinSettingsBuilder = builder;
              // Perform any additional configuration/setting changes
            }];
            
            [ALSdk shared].settings.verboseLoggingEnabled = [ISConfigurations getConfigurations].adaptersDebug;
                                                            
            LogAdapterApi_Internal(@"sdkKey = %@, isVerboseLogging = %d", sdkKey, [ALSdk shared].settings.isVerboseLoggingEnabled);
            
            // AppLovin's initialization callback currently doesn't give any indication to initialization failure.
            // Once this callback is called we will treat the initialization as successful
            ISAppLovinAdapter * __weak weakSelf = self;
            [[ALSdk shared] initializeWithConfiguration: initConfig completionHandler:^(ALSdkConfiguration *sdkConfig) {
                __typeof__(self) strongSelf = weakSelf;
                [strongSelf initializationSuccess];
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

- (void)onNetworkInitCallbackSuccess {
    
    // Rewarded video
    NSArray *rewardedVideoZoneIds = self.rewardedVideoZoneIdToSmashDelegate.allKeys;
    
    for (NSString *zoneId in rewardedVideoZoneIds) {
        id<ISRewardedVideoAdapterDelegate> delegate = [self.rewardedVideoZoneIdToSmashDelegate objectForKey:zoneId];
        if ([self.rewardedVideoZoneIdForInitCallbacks hasObject:zoneId]) {
            [delegate adapterRewardedVideoInitSuccess];
        } else {
            [self loadRewardedVideoInternalWithZoneId:zoneId
                                             delegate:delegate];
        }
    }
    
    // Interstitial
    NSArray *interstitialZoneIds = self.interstitialZoneIdToSmashDelegate.allKeys;
    
    for (NSString *zoneId in interstitialZoneIds) {
        id<ISInterstitialAdapterDelegate> delegate = [self.interstitialZoneIdToSmashDelegate objectForKey:zoneId];
        [delegate adapterInterstitialInitSuccess];
    }
    
    // Banner
    NSArray *bannerZoneIds = self.bannerZoneIdToSmashDelegate.allKeys;
    
    for (NSString *zoneId in bannerZoneIds) {
        id<ISBannerAdapterDelegate> delegate = [self.bannerZoneIdToSmashDelegate objectForKey:zoneId];
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
    
    //add to rewarded video delegate map
    [self.rewardedVideoZoneIdToSmashDelegate setObject:delegate
                                            forKey:zoneId];
    
    //add to rewarded video init callback map
    [self.rewardedVideoZoneIdForInitCallbacks addObject:zoneId];
    
    switch (initState) {
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
                                    adData:(NSDictionary *)adData
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
    
    //add to rewarded video delegate map
    [self.rewardedVideoZoneIdToSmashDelegate setObject:delegate
                                            forKey:zoneId];
    
    switch (initState) {
        case INIT_STATE_NONE:
        case INIT_STATE_IN_PROGRESS:
            [self initSDKWithSDKKey:sdkKey];
            break;
        case INIT_STATE_SUCCESS:
            [self setAppLovinUserId:userId];
            [self loadRewardedVideoInternalWithZoneId:zoneId
                                             delegate:delegate];
            break;
    }
}

- (void)loadRewardedVideoWithAdapterConfig:(ISAdapterConfig *)adapterConfig
                                    adData:(NSDictionary *)adData
                                  delegate:(id<ISRewardedVideoAdapterDelegate>)delegate {
    
    NSString *zoneId = [self getZoneId:adapterConfig];
    
    // load rewarded video
    [self loadRewardedVideoInternalWithZoneId:zoneId
                                     delegate:delegate];
}

- (void)loadRewardedVideoInternalWithZoneId:(NSString *)zoneId
                                   delegate:(id<ISRewardedVideoAdapterDelegate>)delegate {
    LogAdapterApi_Internal(@"zoneId = %@", zoneId);
    
    // Handle case where an rewardedVideo ad is already loaded with the same zoneId
    if([self isRewardedVideoZoneIdExist:zoneId]) {
        NSError *error = [ISError createError:ERROR_CODE_GENERIC
                                  withMessage:[NSString stringWithFormat: @"%@ can't load multiple rewardedVideo ads for the same zoneId - %@, skipping load attempt since there is a loaded rewardedVideo ad for this zoneId", kAdapterName, zoneId]];
        [delegate adapterRewardedVideoDidFailToLoadWithError:error];
        return;
    }
    
    ALIncentivizedInterstitialAd *rewardedAd = [self createRewardedVideoAd:zoneId];
    
    if (rewardedAd == nil) {
        LogAdapterApi_Internal(@"rewardedAd is nil");
        return;
    }
    
    self.rewardedVideoZoneId = zoneId;
    [rewardedVideoAds storeAd:rewardedAd forKey:self];
    
    // add delegate to dictionary
    [self.rewardedVideoZoneIdToSmashDelegate setObject:delegate
                                            forKey:zoneId];
    
    ISAppLovinRewardedVideoDelegate *rewardedVideoAdDelegate = [self.rewardedVideoZoneIdToAppLovinAdDelegate objectForKey:zoneId];
    [rewardedAd preloadAndNotify:rewardedVideoAdDelegate];
}

- (void)showRewardedVideoWithViewController:(UIViewController *)viewController
                              adapterConfig:(ISAdapterConfig *)adapterConfig
                                   delegate:(id<ISRewardedVideoAdapterDelegate>)delegate {
    NSString *zoneId = [self getZoneId:adapterConfig];
    LogAdapterApi_Internal(@"zoneId = %@", zoneId);
    
    ISAppLovinRewardedVideoDelegate *rewardedVideoAdDelegate = [self.rewardedVideoZoneIdToAppLovinAdDelegate objectForKey:zoneId];

    if ([self hasRewardedVideoWithAdapterConfig:adapterConfig]) {
        
        // set dynamic user id to ad if exists
        [self setAppLovinUserId:self.dynamicUserId];
        
        dispatch_async(dispatch_get_main_queue(), ^{
            ALIncentivizedInterstitialAd *rewardedVideoAd = [rewardedVideoAds retrieveAdForKey:self];
            [rewardedVideoAd showAndNotify:rewardedVideoAdDelegate];
        });
    } else {
        
        // Remove the ad object to enable other rewardedVideo ad to be loaded
        [self disposeRewardedVideoAdWithAdapterConfig:adapterConfig];
        
        NSError *error = [ISError createError:ERROR_CODE_NO_ADS_TO_SHOW
                                  withMessage:[NSString stringWithFormat: @"%@ show failed", kAdapterName]];
        
        [delegate adapterRewardedVideoDidFailToShowWithError:error];
    }
}

- (BOOL)hasRewardedVideoWithAdapterConfig:(ISAdapterConfig *)adapterConfig {
    NSString *zoneId = [self getZoneId:adapterConfig];
    ALIncentivizedInterstitialAd *rewardedVideoAd = [rewardedVideoAds retrieveAdForKey:self];
    return rewardedVideoAd != nil && [rewardedVideoAd isReadyForDisplay] && [self isRewardedVideoZoneIdExist:zoneId];
}

- (BOOL)isRewardedVideoZoneIdExist:(NSString *)zoneId {
    @synchronized(rewardedVideoAds) {
        NSArray *adapters = [rewardedVideoAds getAdapters];
        for (id adapter in adapters) {
            if ([[(ISAppLovinAdapter *)adapter rewardedVideoZoneId] isEqualToString:zoneId]) {
                return YES;
            }
        }
    }
    return NO;
}

- (void)disposeRewardedVideoAdWithAdapterConfig:(ISAdapterConfig *)adapterConfig {
    NSString *zoneId = @"";
    
    if(adapterConfig!= nil) {
        zoneId = adapterConfig.settings[kZoneID];
    }
    [self disposeRewardedVideoAdWithZoneId:zoneId];
}

- (void)disposeRewardedVideoAdWithZoneId:(NSString *)zoneId {
    LogAdapterApi_Internal(@"Dispose rewardedVideo ad of %@, zoneId = %@", kAdapterName, zoneId);
    [rewardedVideoAds removeAdForKey:self];
}

#pragma mark - Rewarded Video Delegate

- (void)onRewardedVideoDidLoad:(nonnull NSString *)zoneId {
    LogAdapterDelegate_Internal(@"zoneId = %@", zoneId);
    id<ISRewardedVideoAdapterDelegate> delegate = [self.rewardedVideoZoneIdToSmashDelegate objectForKey:zoneId];
    
    [delegate adapterRewardedVideoHasChangedAvailability:YES];
}

- (void)onRewardedVideoDidFailToLoad:(nonnull NSString *)zoneId
                           errorCode:(int)code {
    NSString *errorReason = [self getErrorMessage:code];
    LogAdapterDelegate_Internal(@"zoneId = %@ , error code = %d, %@", zoneId, code, errorReason);
    id<ISRewardedVideoAdapterDelegate> delegate = [self.rewardedVideoZoneIdToSmashDelegate objectForKey:zoneId];
    
    [delegate adapterRewardedVideoHasChangedAvailability:NO];
    
    NSInteger errorCode = code == kALErrorCodeNoFill ? ERROR_RV_LOAD_NO_FILL : code;
    NSError *error = [NSError errorWithDomain:kAdapterName
                                         code:errorCode
                                     userInfo:@{NSLocalizedDescriptionKey:errorReason}];
    [delegate adapterRewardedVideoDidFailToLoadWithError:error];
}

- (void)onRewardedVideoDidOpen:(nonnull NSString *)zoneId {
    LogAdapterDelegate_Internal(@"zoneId = %@", zoneId);
    id<ISRewardedVideoAdapterDelegate> delegate = [self.rewardedVideoZoneIdToSmashDelegate objectForKey:zoneId];
    
    [delegate adapterRewardedVideoDidOpen];
}

- (void)onRewardedVideoDidStart:(nonnull NSString *)zoneId {
    LogAdapterDelegate_Internal(@"zoneId = %@", zoneId);
    id<ISRewardedVideoAdapterDelegate> delegate = [self.rewardedVideoZoneIdToSmashDelegate objectForKey:zoneId];
    
    [delegate adapterRewardedVideoDidStart];
}

- (void)onRewardedVideoDidClick:(nonnull NSString *)zoneId {
    LogAdapterDelegate_Internal(@"zoneId = %@", zoneId);
    id<ISRewardedVideoAdapterDelegate> delegate = [self.rewardedVideoZoneIdToSmashDelegate objectForKey:zoneId];
    
    [delegate adapterRewardedVideoDidClick];
}

- (void)onRewardedVideoDidEnd:(nonnull NSString *)zoneId {
    LogAdapterDelegate_Internal(@"zoneId = %@", zoneId);
    id<ISRewardedVideoAdapterDelegate> delegate = [self.rewardedVideoZoneIdToSmashDelegate objectForKey:zoneId];
    
    [delegate adapterRewardedVideoDidEnd];
}

- (void)onRewardedVideoDidReceiveReward:(nonnull NSString *)zoneId {
    LogAdapterDelegate_Internal(@"zoneId = %@", zoneId);
    id<ISRewardedVideoAdapterDelegate> delegate = [self.rewardedVideoZoneIdToSmashDelegate objectForKey:zoneId];
    
    [delegate adapterRewardedVideoDidReceiveReward];
}

- (void)onRewardedVideoDidClose:(nonnull NSString *)zoneId {
    LogAdapterDelegate_Internal(@"zoneId = %@", zoneId);
    id<ISRewardedVideoAdapterDelegate> delegate = [self.rewardedVideoZoneIdToSmashDelegate objectForKey:zoneId];
    
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
    
    // add to interstitial delegate map
    [self.interstitialZoneIdToSmashDelegate setObject:delegate
                                           forKey:zoneId];
    
    switch (initState) {
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
                                   adData:(NSDictionary *)adData
                                 delegate:(id<ISInterstitialAdapterDelegate>)delegate {
    dispatch_async(dispatch_get_main_queue(), ^{
        NSString *zoneId = [self getZoneId:adapterConfig];
        LogAdapterApi_Internal(@"zoneId = %@", zoneId);
        
        // Handle case where an interstitial ad is already loaded with the same zoneId
        if([self isInterstitialZoneIdExist:zoneId]) {
            NSError *error = [ISError createError:ERROR_CODE_GENERIC
                                      withMessage:[NSString stringWithFormat: @"%@ can't load multiple interstitial ads for the same zoneId - %@, skipping load attempt since there is a loaded interstitial ad for this zoneId", kAdapterName, zoneId]];
            
            [delegate adapterInterstitialDidFailToLoadWithError:error];
            return;
        }
        
        ALInterstitialAd *interstitialAd = [self createInterstitialAd:zoneId];
        
        if (interstitialAd == nil) {
            LogAdapterApi_Internal(@"interstitialAd is nil");
            return;
        }
        
        self.interstitialZoneId = zoneId;
        [interstitialAds storeAd:interstitialAd forKey:self];
        
        // add delegate to dictionary
        [self.interstitialZoneIdToSmashDelegate setObject:delegate
                                                   forKey:zoneId];
        
        ISAppLovinInterstitialDelegate *interstitialAdDelegate = [self.interstitialZoneIdToAppLovinAdDelegate objectForKey:zoneId];
        if ([zoneId isEqualToString:kDefaultZoneID]) {
            [[appLovinSDK adService] loadNextAd:ALAdSize.interstitial
                                       andNotify:interstitialAdDelegate];
        } else {
            [[appLovinSDK adService] loadNextAdForZoneIdentifier:zoneId
                                                        andNotify:interstitialAdDelegate];
        }
    });
}

- (void)showInterstitialWithViewController:(UIViewController *)viewController
                             adapterConfig:(ISAdapterConfig *)adapterConfig
                                  delegate:(id<ISInterstitialAdapterDelegate>)delegate {
    
    NSString *zoneId = [self getZoneId:adapterConfig];
    LogAdapterApi_Internal(@"zoneId = %@", zoneId);
    
    if ([self hasInterstitialWithAdapterConfig:adapterConfig]) {
        dispatch_async(dispatch_get_main_queue(), ^{
            ALAd *loadedAd = [self.interstitialZoneIdToLoadedAds objectForKey:zoneId];
            ALInterstitialAd *interstitialAd = [interstitialAds retrieveAdForKey:self];
            [interstitialAd showAd:loadedAd];
        });
    } else {
        
        // Remove the ad object to enable other interstitial ad to be loaded
        [self disposeInterstitialAdWithAdapterConfig:adapterConfig];
        
        NSError *error = [ISError createError:ERROR_CODE_NO_ADS_TO_SHOW
                                  withMessage:[NSString stringWithFormat: @"%@ show failed", kAdapterName]];
        
        [interstitialAds removeAdForKey:self];
        [delegate adapterInterstitialDidFailToShowWithError:error];
    }
}

- (BOOL)hasInterstitialWithAdapterConfig:(ISAdapterConfig *)adapterConfig {
    NSString *zoneId = [self getZoneId:adapterConfig];
    ALInterstitialAd *interstitialAd = [interstitialAds retrieveAdForKey:self];
    ALAd *loadedAd = [self.interstitialZoneIdToLoadedAds objectForKey:zoneId];
    return interstitialAd != nil && loadedAd != nil && [self isInterstitialZoneIdExist:zoneId];
}

- (void)disposeInterstitialAdWithAdapterConfig:(ISAdapterConfig *)adapterConfig {
    NSString *zoneId = @"";
    
    if(adapterConfig!= nil){
        zoneId = adapterConfig.settings[kZoneID];
    }
    [self disposeInterstitialAdWithZoneId:zoneId];
}

- (void)disposeInterstitialAdWithZoneId:(NSString *)zoneId {
    LogAdapterApi_Internal(@"Dispose interstitial ad of %@, zoneId = %@", kAdapterName, zoneId);
    [interstitialAds removeAdForKey:self];
}

- (BOOL)isInterstitialZoneIdExist:(NSString *)zoneId {
    @synchronized(interstitialAds) {
        NSArray *adapters = [interstitialAds getAdapters];
        for (id adapter in adapters) {
            if ([[(ISAppLovinAdapter *)adapter interstitialZoneId] isEqualToString:zoneId]) {
                return YES;
            }
        }
    }
    return NO;
}

#pragma mark - Interstitial Delegate

- (void)onInterstitialDidLoad:(nonnull NSString *)zoneId
                       adView:(ALAd *)adView {
    LogAdapterDelegate_Internal(@"zoneId = %@", zoneId);
    id<ISInterstitialAdapterDelegate> delegate = [self.interstitialZoneIdToSmashDelegate objectForKey:zoneId];
    
    [self.interstitialZoneIdToLoadedAds setObject:adView
                                       forKey:zoneId];
    
    [delegate adapterInterstitialDidLoad];
}

- (void)onInterstitialDidOpen:(nonnull NSString *)zoneId {
    LogAdapterDelegate_Internal(@"zoneId = %@", zoneId);
    id<ISInterstitialAdapterDelegate> delegate = [self.interstitialZoneIdToSmashDelegate objectForKey:zoneId];
    [self.interstitialZoneIdToLoadedAds removeObjectForKey:zoneId];

    [delegate adapterInterstitialDidOpen];
    [delegate adapterInterstitialDidShow];
}

- (void)onInterstitialDidFailToLoad:(nonnull NSString *)zoneId
                          errorCode:(int)code {
    NSString *errorReason = [self getErrorMessage:code];
    LogAdapterDelegate_Internal(@"zoneId = %@ , error code = %d, %@", zoneId, code, errorReason);
    id<ISInterstitialAdapterDelegate> delegate = [self.interstitialZoneIdToSmashDelegate objectForKey:zoneId];
    
    NSInteger errorCode = code == kALErrorCodeNoFill ? ERROR_IS_LOAD_NO_FILL : code;
    NSError *error = [[NSError alloc] initWithDomain:kAdapterName
                                                code:errorCode
                                            userInfo:@{NSLocalizedDescriptionKey:errorReason}];
    [delegate adapterInterstitialDidFailToLoadWithError:error];
}

- (void)onInterstitialDidClick:(nonnull NSString *)zoneId {
    LogAdapterDelegate_Internal(@"zoneId = %@", zoneId);
    id<ISInterstitialAdapterDelegate> delegate = [self.interstitialZoneIdToSmashDelegate objectForKey:zoneId];
    
    [delegate adapterInterstitialDidClick];
}

- (void)onInterstitialDidClose:(nonnull NSString *)zoneId {
    LogAdapterDelegate_Internal(@"zoneId = %@", zoneId);
    id<ISInterstitialAdapterDelegate> delegate = [self.interstitialZoneIdToSmashDelegate objectForKey:zoneId];
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
    
    //add to banner delegate map
    [self.bannerZoneIdToSmashDelegate setObject:delegate
                                     forKey:zoneId];

    switch (initState) {
        case INIT_STATE_NONE:
        case INIT_STATE_IN_PROGRESS:
            [self initSDKWithSDKKey:sdkKey];
            break;
        case INIT_STATE_SUCCESS:
            [delegate adapterBannerInitSuccess];
            break;
    }
}

- (void)loadBannerWithAdapterConfig:(ISAdapterConfig *)adapterConfig
                             adData:(NSDictionary *)adData
                     viewController:(UIViewController *)viewController
                               size:(ISBannerSize *)size
                           delegate:(id <ISBannerAdapterDelegate>)delegate {
    NSString *zoneId = [self getZoneId:adapterConfig];
    LogAdapterApi_Internal(@"zoneId = %@", zoneId);
    
    //add to banner delegate map
    [self.bannerZoneIdToSmashDelegate setObject:delegate
                                         forKey:zoneId];

    dispatch_async(dispatch_get_main_queue(), ^{
        // get banner size
        ALAdSize *appLovinSize = [self getBannerSize:size];
        
        // verify size
        if (appLovinSize) {
            // get delegate
            [self createBannerAd:appLovinSize
                            size:size
                          zoneId:zoneId];
            
            ISAppLovinBannerDelegate *bannerDelegate = [self.bannerZoneIdToAppLovinAdDelegate objectForKey:zoneId];
            
            // load ad
            if ([zoneId isEqualToString:kDefaultZoneID]) {
                [appLovinSDK.adService loadNextAd:appLovinSize
                                         andNotify:bannerDelegate];
            } else {
                [appLovinSDK.adService loadNextAdForZoneIdentifier:zoneId
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

- (void)destroyBannerWithAdapterConfig:(ISAdapterConfig *)adapterConfig {
    NSString *zoneId = [self getZoneId:adapterConfig];
    LogAdapterApi_Internal(@"zoneId = %@", zoneId);
    
    if ([self.bannerZoneIdToAd hasObjectForKey:zoneId]) {
        [self.bannerZoneIdToAd removeObjectForKey:zoneId];
    }
    if ([self.bannerZoneIdToSmashDelegate hasObjectForKey:zoneId]) {
        [self.bannerZoneIdToSmashDelegate removeObjectForKey:zoneId];
    }
}

#pragma mark - Banner Delegate

- (void)onBannerDidLoad:(nonnull NSString *)zoneId
                 adView:(ALAd *)adView {
    
    LogAdapterDelegate_Internal(@"zoneId = %@", zoneId);
    id<ISBannerAdapterDelegate> delegate = [self.bannerZoneIdToSmashDelegate objectForKey:zoneId];

    ALAdView *bannerAd = [self.bannerZoneIdToAd objectForKey:zoneId];

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
    id<ISBannerAdapterDelegate> delegate = [self.bannerZoneIdToSmashDelegate objectForKey:zoneId];
    
    NSInteger errorCode = code == kALErrorCodeNoFill ? ERROR_BN_LOAD_NO_FILL : code;
    NSError *error = [[NSError alloc] initWithDomain:kAdapterName
                                                code:errorCode
                                            userInfo:@{NSLocalizedDescriptionKey:errorReason}];
    
    [delegate adapterBannerDidFailToLoadWithError:error];
}

- (void)onBannerDidShow:(nonnull NSString *)zoneId {
    LogAdapterDelegate_Internal(@"zoneId = %@", zoneId);
    id<ISBannerAdapterDelegate> delegate = [self.bannerZoneIdToSmashDelegate objectForKey:zoneId];
    
    [delegate adapterBannerDidShow];
}

- (void)onBannerDidClick:(nonnull NSString *)zoneId {
    LogAdapterDelegate_Internal(@"zoneId = %@", zoneId);
    id<ISBannerAdapterDelegate> delegate = [self.bannerZoneIdToSmashDelegate objectForKey:zoneId];
    
    [delegate adapterBannerDidClick];
}

- (void)onBannerWillLeaveApplication:(nonnull NSString *)zoneId {
    LogAdapterDelegate_Internal(@"zoneId = %@", zoneId);
    id<ISBannerAdapterDelegate> delegate = [self.bannerZoneIdToSmashDelegate objectForKey:zoneId];
    
    [delegate adapterBannerWillLeaveApplication];
}

- (void)onBannerDidPresentFullscreen:(nonnull NSString *)zoneId {
    LogAdapterDelegate_Internal(@"zoneId = %@", zoneId);
    id<ISBannerAdapterDelegate> delegate = [self.bannerZoneIdToSmashDelegate objectForKey:zoneId];
    
    [delegate adapterBannerWillPresentScreen];
}

- (void)onBannerDidDismissFullscreen:(nonnull NSString *)zoneId {
    LogAdapterDelegate_Internal(@"zoneId = %@", zoneId);
    id<ISBannerAdapterDelegate> delegate = [self.bannerZoneIdToSmashDelegate objectForKey:zoneId];
    
    [delegate adapterBannerDidDismissScreen];
}

#pragma mark - Memory Handling

- (void)releaseMemoryWithAdapterConfig:(nonnull ISAdapterConfig *)adapterConfig {
    NSString *zoneId = [self getZoneId:adapterConfig];

    if ([self.rewardedVideoZoneIdToSmashDelegate hasObjectForKey:zoneId]) {
        [self disposeRewardedVideoAdWithZoneId:zoneId];
        [self.rewardedVideoZoneIdToAppLovinAdDelegate removeObjectForKey:zoneId];
        [self.rewardedVideoZoneIdToSmashDelegate removeObjectForKey:zoneId];
        
    } else if ([self.interstitialZoneIdToSmashDelegate objectForKey:zoneId]) {
        [self disposeInterstitialAdWithZoneId:zoneId];
        [self.interstitialZoneIdToAppLovinAdDelegate removeObjectForKey:zoneId];
        [self.interstitialZoneIdToSmashDelegate removeObjectForKey:zoneId];
        [self.interstitialZoneIdToLoadedAds removeObjectForKey:zoneId];
        
    } else if ([self.bannerZoneIdToAd hasObjectForKey:zoneId]) {
        [self.bannerZoneIdToAd removeObjectForKey:zoneId];
        [self.bannerZoneIdToAppLovinAdDelegate removeObjectForKey:zoneId];
        [self.bannerZoneIdToSmashDelegate removeObjectForKey:zoneId];
        [self.bannerZoneIdToAdSize removeObjectForKey:zoneId];
    }
}

// clean for NSMapTable to remove self from the map.
- (void)dealloc
{
    [rewardedVideoAds removeAdForKey:self];
    [interstitialAds removeAdForKey:self];
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
        [self setCCPAValue:[ISMetaDataUtils getMetaDataBooleanValue:value]];
    }
}

#pragma mark - Helper Methods

- (ALIncentivizedInterstitialAd *)createRewardedVideoAd:(NSString *)zoneId {
    ALIncentivizedInterstitialAd *rewardedVideoAd;
    
    if ([zoneId isEqualToString:kDefaultZoneID]) {
        rewardedVideoAd = [[ALIncentivizedInterstitialAd alloc] initWithSdk:appLovinSDK];
    } else {
        rewardedVideoAd = [[ALIncentivizedInterstitialAd alloc] initWithZoneIdentifier:zoneId
                                                                                   sdk:appLovinSDK];
    }

    ISAppLovinRewardedVideoDelegate *rewardedVideoAdDelegate = [[ISAppLovinRewardedVideoDelegate alloc] initWithZoneId:zoneId
                                                                                                                adapter:self
                                                                                                           delegate:self];
    [self.rewardedVideoZoneIdToAppLovinAdDelegate setObject:rewardedVideoAdDelegate
                                                 forKey:zoneId];
    
    rewardedVideoAd.adDisplayDelegate = rewardedVideoAdDelegate;
    rewardedVideoAd.adVideoPlaybackDelegate = rewardedVideoAdDelegate;
    
    return rewardedVideoAd;
}

- (ALInterstitialAd *)createInterstitialAd:(NSString *)zoneId {
    ALInterstitialAd *interstitialAd = [[ALInterstitialAd alloc] initWithSdk:appLovinSDK];
    
    ISAppLovinInterstitialDelegate *interstitialAdDelegate = [[ISAppLovinInterstitialDelegate alloc] initWithZoneId:zoneId
                                                                                                            adapter:self
                                                                                                        delegate:self];
    [self.interstitialZoneIdToAppLovinAdDelegate setObject:interstitialAdDelegate
                                                forKey:zoneId];
    
    interstitialAd.adDisplayDelegate = interstitialAdDelegate;
    interstitialAd.adLoadDelegate = interstitialAdDelegate;
    
    return interstitialAd;
}

- (void)createBannerAd:(ALAdSize *)appLovinSize
                  size:(ISBannerSize *)size
                zoneId:(NSString *)zoneId {
    
    ISAppLovinBannerDelegate *bannerAdDelegate = [[ISAppLovinBannerDelegate alloc] initWithZoneId:zoneId
                                                                                         delegate:self];
    [self.bannerZoneIdToAppLovinAdDelegate setObject:bannerAdDelegate
                                          forKey:zoneId];
    
    // create rect
    CGRect frame = [self getBannerFrame:size];
    
    // create banner view
    ALAdView *bnAd = [[ALAdView alloc] initWithFrame:frame
                                                size:appLovinSize
                                                 sdk:appLovinSDK];
    
    bnAd.adLoadDelegate = bannerAdDelegate;
    bnAd.adDisplayDelegate = bannerAdDelegate;
    bnAd.adEventDelegate = bannerAdDelegate;
    
    // add to dictionaries
    [self.bannerZoneIdToAdSize setObject:appLovinSize
                              forKey:zoneId];
    
    [self.bannerZoneIdToAd setObject:bnAd
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
        if ([UIDevice currentDevice].userInterfaceIdiom == UIUserInterfaceIdiomPad) {
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
        if ([UIDevice currentDevice].userInterfaceIdiom == UIUserInterfaceIdiomPad) {
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
        [ALSdk shared].settings.userIdentifier = userId;
    }
}

@end

