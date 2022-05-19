//
//  ISAdColonyAdapter.m
//  ISAdColonyAdapter
//
//  Created by Amit Goldhecht on 8/19/14.
//  Copyright (c) 2014 IronSource. All rights reserved.
//

#import "ISAdColonyAdapter.h"
#import "ISAdColonyBnListener.h"
#import "ISAdColonyIsListener.h"
#import "ISAdColonyRvListener.h"
#import <AdColony/AdColony.h>

static NSString * const kAdapterName        = @"AdColony";
static NSString * const kAdapterVersion     = AdColonyAdapterVersion;
static NSString * const kAppId              = @"appID";
static NSString * const kZoneId             = @"zoneId";
static NSString * const kAllZoneIds         = @"zoneIds";
static NSString * const kAdMarkupKey        = @"adm";
static NSString * const kClientOptions      = @"clientOptions";
static NSString * const kMetaDataCOPPAKey   = @"AdColony_COPPA";
static NSString * const kMediationName      = @"ironSource";

static NSInteger  const kNotLoadedErrorCode = 1201;


typedef NS_ENUM(NSInteger, InitState) {
    INIT_STATE_NONE,
    INIT_STATE_IN_PROGRESS,
    INIT_STATE_SUCCESS,
    INIT_STATE_FAILED
};

// init state is declared static because the network
// state should be the same for all class instances
static InitState _initState = INIT_STATE_NONE;

static AdColonyAppOptions *adColonyOptions = nil;
static NSArray<AdColonyZone *> *adColonyInitZones = nil;
static NSMutableSet<ISNetworkInitCallbackProtocol> *initCallbackDelegates = nil;

@interface ISAdColonyAdapter() <ISAdColonyISDelegateWrapper, ISAdColonyRVDelegateWrapper, ISAdColonyBNDelegateWrapper, ISNetworkInitCallbackProtocol>
{
    
    // rewarded video
    ConcurrentMutableDictionary*       rewardedVideoZoneIdToSmashDelegate;
    ConcurrentMutableDictionary*       rewardedVideoZoneIdToListener;
    ConcurrentMutableDictionary*       rewardedVideoZoneIdToAd;
    ConcurrentMutableSet*              rewardedVideoPlacementsForInitCallbacks;
    
    // interstitial
    ConcurrentMutableDictionary*       interstitialZoneIdToSmashDelegate;
    ConcurrentMutableDictionary*       interstitialZoneIdToListener;
    ConcurrentMutableDictionary*       interstitialZoneIdToAd;
    
    // banner
    ConcurrentMutableDictionary*       bannerZoneIdToSmashDelegate;
    ConcurrentMutableDictionary*       bannerZoneIdToListener;
    ConcurrentMutableDictionary*       bannerZoneIdToSize;
    ConcurrentMutableDictionary*       bannerZoneIdToViewController;
    ConcurrentMutableDictionary*       bannerZoneIdToAd;
}

@end

@implementation ISAdColonyAdapter

#pragma mark - Initializations Methods

- (instancetype)initAdapter:(NSString *)name {
    self = [super initAdapter:name];
    if (self) {
        // only initiated once for all instances
        if (adColonyOptions == nil) {
            adColonyOptions = [AdColonyAppOptions new];
        }
        
        if (initCallbackDelegates == nil) {
            initCallbackDelegates = [NSMutableSet<ISNetworkInitCallbackProtocol> new];
        }
        
        // rewarded video
        rewardedVideoZoneIdToSmashDelegate       = [ConcurrentMutableDictionary new];
        rewardedVideoZoneIdToAd                  = [ConcurrentMutableDictionary new];
        rewardedVideoZoneIdToListener            = [ConcurrentMutableDictionary new];
        rewardedVideoPlacementsForInitCallbacks  = [[ConcurrentMutableSet alloc] init];
        
        // interstital
        interstitialZoneIdToSmashDelegate        = [ConcurrentMutableDictionary new];
        interstitialZoneIdToListener             = [ConcurrentMutableDictionary new];
        interstitialZoneIdToAd                   = [ConcurrentMutableDictionary new];
        
        // banner
        bannerZoneIdToSmashDelegate              = [ConcurrentMutableDictionary new];
        bannerZoneIdToListener                   = [ConcurrentMutableDictionary new];
        bannerZoneIdToSize                       = [ConcurrentMutableDictionary new];
        bannerZoneIdToViewController             = [ConcurrentMutableDictionary new];
        bannerZoneIdToAd                         = [ConcurrentMutableDictionary new];
        
        // load while show
        LWSState = LOAD_WHILE_SHOW_BY_NETWORK;
    }
    
    return self;
}

#pragma mark - IronSource Protocol  Methods

- (NSString *)version {
    return kAdapterVersion;
}

- (NSString *)sdkVersion {
    return [AdColony getSDKVersion];
}

- (void)setMetaDataWithKey:(NSString *)key andValues:(NSMutableArray *) values {
    if (values.count == 0) {
        return;
    }
    
    NSString *value = values[0];
    LogAdapterApi_Internal(@"key = %@, value = %@", key, value);
    
    if ([ISMetaDataUtils isValidCCPAMetaDataWithKey:key andValue:value]) {
        [self setCCPAValue:value];
    } else if ([self isValidCOPPAMetaDataKey:key]) {
        NSString *formattedValue = [ISMetaDataUtils formatValue:value forType:(META_DATA_VALUE_BOOL)];
        
        if (formattedValue.length) {
            [self setCOPPAValue:formattedValue];
        }
    }
}

- (NSArray *)systemFrameworks {
    return @[@"AdSupport", @"AppTrackingTransparency", @"AudioToolbox", @"AVFoundation", @"CoreMedia", @"CoreServices", @"CoreTelephony", @"JavaScriptCore", @"MessageUI", @"SafariServices", @"Social", @"StoreKit", @"SystemConfiguration", @"WatchConnectivity", @"WebKit"];
}

- (NSString *)sdkName {
    return @"AdColony";
}

- (void)setConsent:(BOOL)consent {
    NSString *consentVal = consent ? @"1" : @"0";

    [adColonyOptions setPrivacyFrameworkOfType:ADC_GDPR isRequired:YES];
    [adColonyOptions setPrivacyConsentString:consentVal forType:ADC_GDPR];

    if (_initState == INIT_STATE_SUCCESS) {
        [AdColony setAppOptions:adColonyOptions];
    }
}

#pragma mark - Rewarded Video API

- (NSDictionary *)getRewardedVideoBiddingDataWithAdapterConfig:(ISAdapterConfig *)adapterConfig {
    LogAdapterApi_Internal(@"");
    return [self getBiddingData];
}

- (void)initRewardedVideoForCallbacksWithUserId:(NSString *)userId
                                  adapterConfig:(ISAdapterConfig *)adapterConfig
                                       delegate:(id<ISRewardedVideoAdapterDelegate>)delegate {
    LogAdapterApi_Internal(@"");
    NSString *appId = adapterConfig.settings[kAppId];
    NSString *zoneId = adapterConfig.settings[kZoneId];
    NSString *allZoneIds = adapterConfig.settings[kAllZoneIds];
    
    if (![self isConfigValueValid:appId]) {
        NSError *error = [self errorForMissingCredentialFieldWithName:kAppId];
        LogAdapterApi_Internal(@"error.description = %@", error.description);
        [delegate adapterRewardedVideoInitFailed:error];
        return;
    }
    
    if (![self isConfigValueValid:zoneId]) {
        NSError *error = [self errorForMissingCredentialFieldWithName:kZoneId];
        LogAdapterApi_Internal(@"error.description = %@", error.description);
        [delegate adapterRewardedVideoInitFailed:error];
        return;
    }
    
    if (![self isConfigValueValid:allZoneIds]) {
        NSError *error = [self errorForMissingCredentialFieldWithName:kAllZoneIds];
        LogAdapterApi_Internal(@"error.description = %@", error.description);
        [delegate adapterRewardedVideoInitFailed:error];
        return;
    }
    
    LogAdapterApi_Internal(@"appId = %@, zoneId = %@", appId, zoneId);

    ISAdColonyRvListener *rewardedVideoListener = [[ISAdColonyRvListener alloc] initWithZoneId:zoneId andDelegate:self];
    [rewardedVideoZoneIdToListener setObject:rewardedVideoListener forKey:zoneId];
    [rewardedVideoZoneIdToSmashDelegate setObject:delegate forKey:zoneId];
    [rewardedVideoPlacementsForInitCallbacks addObject:zoneId];
    
    if (_initState == INIT_STATE_SUCCESS) {
        // register rewarded zones
        [self registerRewardedVideoZones];
        [delegate adapterRewardedVideoInitSuccess];
    } else if (_initState == INIT_STATE_FAILED) {
        NSError *error = [NSError errorWithDomain:kAdapterName code:ERROR_CODE_INIT_FAILED userInfo:@{NSLocalizedDescriptionKey:@"AdColony SDK init failed"}];
        LogAdapterApi_Internal(@"error.description = %@", error.description);
        [delegate adapterRewardedVideoInitFailed:error];
    } else {
        [self initWithAppId:appId userId:userId allZoneIds:allZoneIds];
    }
}

- (void)initAndLoadRewardedVideoWithUserId:(NSString *)userId
                             adapterConfig:(ISAdapterConfig *)adapterConfig
                                  delegate:(id<ISRewardedVideoAdapterDelegate>)delegate {
    LogAdapterApi_Internal(@"");
    NSString *appId = adapterConfig.settings[kAppId];
    NSString *zoneId = adapterConfig.settings[kZoneId];
    NSString *allZoneIds = adapterConfig.settings[kAllZoneIds];
    
    if (![self isConfigValueValid:appId]) {
        NSError *error = [self errorForMissingCredentialFieldWithName:kAppId];
        LogAdapterApi_Internal(@"error.description = %@", error.description);
        [delegate adapterRewardedVideoHasChangedAvailability:NO];
        return;
    }
    
    if (![self isConfigValueValid:zoneId]) {
        NSError *error = [self errorForMissingCredentialFieldWithName:kZoneId];
        LogAdapterApi_Internal(@"error.description = %@", error.description);
        [delegate adapterRewardedVideoHasChangedAvailability:NO];
        return;
    }
    
    if (![self isConfigValueValid:allZoneIds]) {
        NSError *error = [self errorForMissingCredentialFieldWithName:kAllZoneIds];
        LogAdapterApi_Internal(@"error.description = %@", error.description);
        [delegate adapterRewardedVideoHasChangedAvailability:NO];
        return;
    }
    
    LogAdapterApi_Internal(@"appId = %@, zoneId = %@", appId, zoneId);

    ISAdColonyRvListener *rewardedVideoListener = [[ISAdColonyRvListener alloc] initWithZoneId:zoneId andDelegate:self];
    [rewardedVideoZoneIdToListener setObject:rewardedVideoListener forKey:zoneId];
    [rewardedVideoZoneIdToSmashDelegate setObject:delegate forKey:zoneId];
    
    if (_initState == INIT_STATE_SUCCESS) {
        // register rewarded zones
        [self registerRewardedVideoZones];
        [self loadRewardedVideo:zoneId];
    } else if (_initState == INIT_STATE_FAILED) {
        NSError *error = [NSError errorWithDomain:kAdapterName code:ERROR_CODE_INIT_FAILED userInfo:@{NSLocalizedDescriptionKey:@"AdColony SDK init failed"}];
        LogAdapterApi_Internal(@"error.description = %@", error.description);
        [delegate adapterRewardedVideoHasChangedAvailability:NO];
    } else {
        [self initWithAppId:appId userId:userId allZoneIds:allZoneIds];
    }
}

- (void)loadRewardedVideoForBiddingWithAdapterConfig:(ISAdapterConfig *)adapterConfig serverData:(NSString *)serverData delegate:(id<ISRewardedVideoAdapterDelegate>)delegate {
    NSString *zoneId = adapterConfig.settings[kZoneId];
    LogAdapterApi_Internal(@"zoneId = %@, serverData = %@", zoneId, serverData);
    ISAdColonyRvListener *rewardedVideoListener = [rewardedVideoZoneIdToListener objectForKey:zoneId];
    AdColonyAdOptions *adOptions = [AdColonyAdOptions new];
    [adOptions setOption:kAdMarkupKey withStringValue:serverData];
    [AdColony requestInterstitialInZone:zoneId options:adOptions andDelegate:rewardedVideoListener];
}

- (void)fetchRewardedVideoForAutomaticLoadWithAdapterConfig:(ISAdapterConfig *)adapterConfig delegate:(id<ISRewardedVideoAdapterDelegate>)delegate {
    LogAdapterApi_Internal(@"");
    NSString *zoneId = adapterConfig.settings[kZoneId];
    [self loadRewardedVideo:zoneId];
}

- (void)loadRewardedVideo:(NSString *)zoneId {
    LogAdapterApi_Internal(@"zoneId = %@", zoneId);
    ISAdColonyRvListener *rewardedVideoListener = [rewardedVideoZoneIdToListener objectForKey:zoneId];
    [AdColony requestInterstitialInZone:zoneId options:nil andDelegate:rewardedVideoListener];
}

- (BOOL)hasRewardedVideoWithAdapterConfig:(ISAdapterConfig *)adapterConfig {
    LogAdapterApi_Internal(@"");
    NSString *zoneId = adapterConfig.settings[kZoneId];
    AdColonyInterstitial *ad = [rewardedVideoZoneIdToAd objectForKey:zoneId];
    return (ad != nil) && !ad.expired;
}

- (void)showRewardedVideoWithViewController:(UIViewController *)viewController adapterConfig:(ISAdapterConfig *)adapterConfig delegate:(id<ISRewardedVideoAdapterDelegate>)delegate {
    NSString *zoneId = adapterConfig.settings[kZoneId];
    LogAdapterApi_Internal(@"zoneId = %@", zoneId);
    
    [delegate adapterRewardedVideoHasChangedAvailability:NO];
    AdColonyInterstitial *ad = [rewardedVideoZoneIdToAd objectForKey:zoneId];
    
    if ([self hasRewardedVideoWithAdapterConfig:adapterConfig]) {
        BOOL showReady = [ad showWithPresentingViewController:viewController];
        
        if (!showReady) {
            NSError *error = [NSError errorWithDomain:kAdapterName code:ERROR_CODE_GENERIC userInfo:@{NSLocalizedDescriptionKey : @"Unknown error"}];
            LogAdapterApi_Internal(@"error = %@", error);
            [delegate adapterRewardedVideoDidFailToShowWithError:error];
        }
    } else {
        NSError *error = [NSError errorWithDomain:kAdapterName code:kNotLoadedErrorCode userInfo:@{NSLocalizedDescriptionKey : @"not loaded"}];
        LogAdapterApi_Internal(@"error = %@", error);
        [delegate adapterRewardedVideoDidFailToShowWithError:error];
    }
}

#pragma mark - Rewarded Video Callbacks

- (void)rvDidLoad:(AdColonyInterstitial *)ad forZoneId:(NSString *)zoneId {
    LogAdapterDelegate_Internal(@"zoneId = %@", zoneId);
    [rewardedVideoZoneIdToAd setObject:ad forKey:zoneId];
    id<ISRewardedVideoAdapterDelegate> delegate = [rewardedVideoZoneIdToSmashDelegate objectForKey:zoneId];
    
    if (delegate) {
        [delegate adapterRewardedVideoHasChangedAvailability:YES];
    }
}

- (void)rvDidFailToLoadForZoneId:(NSString *)zoneId withError:(AdColonyAdRequestError *)error {
    LogAdapterDelegate_Internal(@"zoneId = %@, error = %@", zoneId, error);
    id<ISRewardedVideoAdapterDelegate> delegate = [rewardedVideoZoneIdToSmashDelegate objectForKey:zoneId];
    
    if (delegate) {
        [delegate adapterRewardedVideoHasChangedAvailability:NO];
        NSError *smashError;
        
        if (error.code == AdColonyRequestErrorNoFillForRequest) {
            smashError = [NSError errorWithDomain:kAdapterName code:ERROR_RV_LOAD_NO_FILL userInfo:@{NSLocalizedDescriptionKey:@"AdColony no fill"}];
        } else {
            smashError = error;
        }
        
        [delegate adapterRewardedVideoDidFailToLoadWithError:smashError];
    }
}

- (void)rvWillOpenForZoneId:(NSString *)zoneId {
    LogAdapterDelegate_Internal(@"zoneId = %@", zoneId);
    id<ISRewardedVideoAdapterDelegate> delegate = [rewardedVideoZoneIdToSmashDelegate objectForKey:zoneId];
    
    if (delegate) {
        [delegate adapterRewardedVideoDidOpen];
        [delegate adapterRewardedVideoDidStart];
    }
}

- (void)rvDidReceiveClickForZoneId:(NSString *)zoneId {
    LogAdapterDelegate_Internal(@"zoneId = %@", zoneId);
    id<ISRewardedVideoAdapterDelegate> delegate = [rewardedVideoZoneIdToSmashDelegate objectForKey:zoneId];
    
    if (delegate) {
        [delegate adapterRewardedVideoDidClick];
    }
}

- (void)rvDidCloseForZoneId:(NSString *)zoneId {
    LogAdapterDelegate_Internal(@"zoneId = %@", zoneId);
    id<ISRewardedVideoAdapterDelegate> delegate = [rewardedVideoZoneIdToSmashDelegate objectForKey:zoneId];
    
    if (delegate) {
        [delegate adapterRewardedVideoDidEnd];
        [delegate adapterRewardedVideoDidClose];
    }
}

- (void)rvExpiredForZoneId:(NSString *)zoneId {
    LogAdapterDelegate_Internal(@"zoneId = %@", zoneId);
    id<ISRewardedVideoAdapterDelegate> delegate = [rewardedVideoZoneIdToSmashDelegate objectForKey:zoneId];
    
    // give indication of expired ads in events using callback
    if (delegate != nil) {
        NSError *error = [NSError errorWithDomain:kAdapterName code:ERROR_RV_EXPIRED_ADS userInfo:@{NSLocalizedDescriptionKey:@"ads are expired"}];
        [delegate adapterRewardedVideoDidFailToLoadWithError:error];
    }

}

#pragma mark - Interstitial API

- (NSDictionary *)getInterstitialBiddingDataWithAdapterConfig:(ISAdapterConfig *)adapterConfig {
    LogAdapterApi_Internal(@"");
    return [self getBiddingData];
}

- (void)initInterstitialForBiddingWithUserId:(NSString *)userId adapterConfig:(ISAdapterConfig *)adapterConfig delegate:(id<ISInterstitialAdapterDelegate>)delegate {
    LogAdapterApi_Internal(@"");
    [self initInterstitialWithUserId:userId adapterConfig:adapterConfig delegate:delegate];
}

- (void)initInterstitialWithUserId:(NSString *)userId adapterConfig:(ISAdapterConfig *)adapterConfig delegate:(id<ISInterstitialAdapterDelegate>)delegate {
    NSString *appId = adapterConfig.settings[kAppId];
    NSString *zoneId = adapterConfig.settings[kZoneId];
    NSString *allZoneIds = adapterConfig.settings[kAllZoneIds];
    
    if (![self isConfigValueValid:appId]) {
        NSError *error = [self errorForMissingCredentialFieldWithName:kAppId];
        LogAdapterApi_Internal(@"error.description = %@", error.description);
        [delegate adapterInterstitialInitFailedWithError:error];
        return;
    }
    
    if (![self isConfigValueValid:zoneId]) {
        NSError *error = [self errorForMissingCredentialFieldWithName:kZoneId];
        LogAdapterApi_Internal(@"error.description = %@", error.description);
        [delegate adapterInterstitialInitFailedWithError:error];
        return;
    }
    
    if (![self isConfigValueValid:allZoneIds]) {
        NSError *error = [self errorForMissingCredentialFieldWithName:kAllZoneIds];
        LogAdapterApi_Internal(@"error.description = %@", error.description);
        [delegate adapterInterstitialInitFailedWithError:error];
        return;
    }
    
    LogAdapterApi_Internal(@"appId = %@, zoneId = %@", appId, zoneId);
    
    ISAdColonyIsListener *interstitialListener = [[ISAdColonyIsListener alloc] initWithZoneId:zoneId andDelegate:self];
    [interstitialZoneIdToListener setObject:interstitialListener forKey:zoneId];
    [interstitialZoneIdToSmashDelegate setObject:delegate forKey:zoneId];
    
    if (_initState == INIT_STATE_SUCCESS) {
        [delegate adapterInterstitialInitSuccess];
    } else if (_initState == INIT_STATE_FAILED) {
        NSError *error = [NSError errorWithDomain:kAdapterName code:ERROR_CODE_INIT_FAILED userInfo:@{NSLocalizedDescriptionKey:@"AdColony SDK init failed"}];
        LogAdapterApi_Internal(@"error.description = %@", error.description);
        [delegate adapterInterstitialInitFailedWithError:error];
    } else {
        [self initWithAppId:appId userId:userId allZoneIds:allZoneIds];
    }
}

- (void)loadInterstitialForBiddingWithServerData:(NSString *)serverData adapterConfig:(ISAdapterConfig *)adapterConfig delegate:(id<ISInterstitialAdapterDelegate>)delegate {
    NSString *zoneId = adapterConfig.settings[kZoneId];
    LogAdapterApi_Internal(@"zoneId = %@, serverData = %@", zoneId, serverData);
    ISAdColonyIsListener *interstitialListener = [interstitialZoneIdToListener objectForKey:zoneId];
    AdColonyAdOptions *adOptions = [AdColonyAdOptions new];
    [adOptions setOption:kAdMarkupKey withStringValue:serverData];
    [AdColony requestInterstitialInZone:zoneId options:adOptions andDelegate:interstitialListener];
}

- (void)loadInterstitialWithAdapterConfig:(ISAdapterConfig *)adapterConfig delegate:(id<ISInterstitialAdapterDelegate>)delegate {
    NSString *zoneId = adapterConfig.settings[kZoneId];
    LogAdapterApi_Internal(@"zoneId = %@", zoneId);
    ISAdColonyIsListener *interstitialListener = [interstitialZoneIdToListener objectForKey:zoneId];
    [AdColony requestInterstitialInZone:zoneId options:nil andDelegate:interstitialListener];
}

- (BOOL)hasInterstitialWithAdapterConfig:(ISAdapterConfig *)adapterConfig {
    LogAdapterApi_Internal(@"");
    NSString *zoneId = adapterConfig.settings[kZoneId];
    AdColonyInterstitial *ad = [interstitialZoneIdToAd objectForKey:zoneId];
    return (ad != nil) && !ad.expired;
}

- (void)showInterstitialWithViewController:(UIViewController *)viewController adapterConfig:(ISAdapterConfig *)adapterConfig delegate:(id<ISInterstitialAdapterDelegate>)delegate {
    NSString *zoneId = adapterConfig.settings[kZoneId];
    LogAdapterApi_Internal(@"zoneId = %@", zoneId);
    AdColonyInterstitial *ad = [interstitialZoneIdToAd objectForKey:zoneId];
    
    if ([self hasInterstitialWithAdapterConfig:adapterConfig]) {
        BOOL showReady = [ad showWithPresentingViewController:viewController];
        
        if (!showReady) {
            NSError *error = [NSError errorWithDomain:kAdapterName code:ERROR_CODE_GENERIC userInfo:@{NSLocalizedDescriptionKey : @"unknown error"}];
            [delegate adapterInterstitialDidFailToShowWithError:error];
        }
    } else {
        NSError *error = [NSError errorWithDomain:kAdapterName code:kNotLoadedErrorCode userInfo:@{NSLocalizedDescriptionKey : @"not loaded"}];
        [delegate adapterInterstitialDidFailToShowWithError:error];
    }
}

#pragma mark - Interstitial Callbacks

- (void)interstitialDidLoad:(AdColonyInterstitial *)ad forZoneId:(NSString *)zoneId {
    LogAdapterDelegate_Internal(@"zoneId = %@", zoneId);
    [interstitialZoneIdToAd setObject:ad forKey:zoneId];
    id<ISInterstitialAdapterDelegate> delegate = [interstitialZoneIdToSmashDelegate objectForKey:zoneId];
    
    if (delegate) {
        [delegate adapterInterstitialDidLoad];
    }
}

- (void)interstitialDidFailToLoadForZoneId:(NSString *)zoneId withError:(AdColonyAdRequestError *)error {
    LogAdapterDelegate_Internal(@"zoneId = %@, error = %@", zoneId, error);
    id<ISInterstitialAdapterDelegate> delegate = [interstitialZoneIdToSmashDelegate objectForKey:zoneId];
    
    if (delegate) {
        NSError *smashError;
    
        if (error.code == AdColonyRequestErrorNoFillForRequest) {
            smashError = [NSError errorWithDomain:kAdapterName code:ERROR_IS_LOAD_NO_FILL userInfo:@{NSLocalizedDescriptionKey:@"AdColony no fill"}];
        } else {
            smashError = error;
        }
        
        [delegate adapterInterstitialDidFailToLoadWithError:smashError];
    }
}

- (void)interstitialWillOpenForZoneId:(NSString *)zoneId {
    LogAdapterDelegate_Internal(@"zoneId = %@", zoneId);
    id<ISInterstitialAdapterDelegate> delegate = [interstitialZoneIdToSmashDelegate objectForKey:zoneId];
    
    if (delegate) {
        [delegate adapterInterstitialDidOpen];
        [delegate adapterInterstitialDidShow];
    }
}

- (void)interstitialDidReceiveClickForZoneId:(NSString *)zoneId {
    LogAdapterDelegate_Internal(@"zoneId = %@", zoneId);
    id<ISInterstitialAdapterDelegate> delegate = [interstitialZoneIdToSmashDelegate objectForKey:zoneId];
    
    if (delegate) {
        [delegate adapterInterstitialDidClick];
    }
}

- (void)interstitialDidCloseForZoneId:(NSString *)zoneId {
    LogAdapterDelegate_Internal(@"zoneId = %@", zoneId);
    id<ISInterstitialAdapterDelegate> delegate = [interstitialZoneIdToSmashDelegate objectForKey:zoneId];
    
    if (delegate) {
        [delegate adapterInterstitialDidClose];
    }
}

- (void)interstitialExpiredForZoneId:(NSString *)zoneId {
    LogAdapterDelegate_Internal(@"zoneId = %@", zoneId);
}

#pragma mark - Banner API

- (NSDictionary *)getBannerBiddingDataWithAdapterConfig:(ISAdapterConfig *)adapterConfig {
    LogAdapterApi_Internal(@"");
    return [self getBiddingData];
}

- (void)initBannerForBiddingWithUserId:(NSString *)userId
                         adapterConfig:(ISAdapterConfig *)adapterConfig
                              delegate:(id<ISBannerAdapterDelegate>)delegate {
    LogInternal_Internal(@"");
    [self initBannerWithUserId:userId adapterConfig:adapterConfig delegate:delegate];
}

- (void)initBannerWithUserId:(nonnull NSString *)userId
               adapterConfig:(nonnull ISAdapterConfig *)adapterConfig
                    delegate:(nonnull id<ISBannerAdapterDelegate>)delegate {
    NSString *appId = adapterConfig.settings[kAppId];
    NSString *zoneId = adapterConfig.settings[kZoneId];
    NSString *allZoneIds = adapterConfig.settings[kAllZoneIds];
    
    if (![self isConfigValueValid:appId]) {
        NSError *error = [self errorForMissingCredentialFieldWithName:kAppId];
        LogAdapterApi_Internal(@"error = %@", error);
        [delegate adapterBannerInitFailedWithError:error];
        return;
    }
    
    if (![self isConfigValueValid:zoneId]) {
        NSError *error = [self errorForMissingCredentialFieldWithName:kZoneId];
        LogAdapterApi_Internal(@"error = %@", error);
        [delegate adapterBannerInitFailedWithError:error];
        return;
    }
    
    if (![self isConfigValueValid:allZoneIds]) {
        NSError *error = [self errorForMissingCredentialFieldWithName:kAllZoneIds];
        LogAdapterApi_Internal(@"error = %@", error);
        [delegate adapterBannerInitFailedWithError:error];
        return;
    }
    
    LogAdapterApi_Internal(@"appId = %@, zoneId = %@", appId, zoneId);
    
    ISAdColonyBnListener *bannerListener = [[ISAdColonyBnListener alloc] initWithZoneId:zoneId andDelegate:self];
    [bannerZoneIdToListener setObject:bannerListener forKey:zoneId];
    // add delegate to dictionary
    [bannerZoneIdToSmashDelegate setObject:delegate forKey:zoneId];
    
    // call delegate if already inited
    if (_initState == INIT_STATE_SUCCESS) {
        [delegate adapterBannerInitSuccess];
    } else if (_initState == INIT_STATE_FAILED) {
        NSError *error = [NSError errorWithDomain:kAdapterName code:ERROR_CODE_INIT_FAILED userInfo:@{NSLocalizedDescriptionKey:@"AdColony SDK init failed"}];
        LogAdapterApi_Internal(@"error.description = %@", error.description);
        [delegate adapterBannerInitFailedWithError:error];
    } else {
        [self initWithAppId:appId userId:userId allZoneIds:allZoneIds];
    }
}

- (void)loadBannerWithViewController:(nonnull UIViewController *)viewController
                                size:(nonnull ISBannerSize *)size
                       adapterConfig:(nonnull ISAdapterConfig *)adapterConfig
                            delegate:(nonnull id <ISBannerAdapterDelegate>)delegate {
    LogAdapterApi_Internal(@"");
    [self loadBannerInternal:adapterConfig delegate:delegate size:size viewController:viewController adOptions:nil];
}

- (void)loadBannerForBiddingWithServerData:(NSString *)serverData
                            viewController:(UIViewController *)viewController
                                      size:(ISBannerSize *)size
                             adapterConfig:(ISAdapterConfig *)adapterConfig
                                  delegate:(id <ISBannerAdapterDelegate>)delegate {
    LogAdapterApi_Internal(@"");
    AdColonyAdOptions *adOptions = [AdColonyAdOptions new];
    [adOptions setOption:kAdMarkupKey withStringValue:serverData];
    [self loadBannerInternal:adapterConfig delegate:delegate size:size viewController:viewController adOptions:adOptions];
}

- (void)loadBannerInternal:(ISAdapterConfig * _Nonnull)adapterConfig
                  delegate:(id<ISBannerAdapterDelegate> _Nonnull)delegate
                      size:(ISBannerSize * _Nonnull)size
            viewController:(UIViewController * _Nonnull)viewController
                 adOptions:(AdColonyAdOptions* _Nullable)adOptions {
    NSString *zoneId = adapterConfig.settings[kZoneId];
    
    if (![self isConfigValueValid:zoneId]) {
        NSError *error = [self errorForMissingCredentialFieldWithName:kZoneId];
        LogAdapterApi_Internal(@"error = %@", error);
        [delegate adapterBannerDidFailToLoadWithError:error];
        return;
    }
    
    // verify size
    if (![self isBannerSizeSupported:size]) {
        NSError *error = [NSError errorWithDomain:kAdapterName code:ERROR_BN_UNSUPPORTED_SIZE userInfo:@{NSLocalizedDescriptionKey:[NSString stringWithFormat:@"AdColony unsupported banner size = %@", size.sizeDescription]}];
        LogAdapterApi_Internal(@"error = %@", error);
        [delegate adapterBannerDidFailToLoadWithError:error];
    }
    
    // add delegate to dictionary
    [bannerZoneIdToSmashDelegate setObject:delegate forKey:zoneId];
    
    // add size to dictionary
    [bannerZoneIdToSize setObject:size forKey:zoneId];
    
    // add view controller to dictionary
    [bannerZoneIdToViewController setObject:viewController forKey:zoneId];
    
    AdColonyAdSize bannerSize = [self getBannerSize:size];
    
    ISAdColonyBnListener *bannerListener = [bannerZoneIdToListener objectForKey:zoneId];
    
    // load banner
    [AdColony requestAdViewInZone:zoneId withSize:bannerSize
                       andOptions:adOptions viewController:viewController andDelegate:bannerListener];
}

- (void)reloadBannerWithAdapterConfig:(nonnull ISAdapterConfig *)adapterConfig
                             delegate:(nonnull id <ISBannerAdapterDelegate>)delegate {

    // zone id
    NSString *zoneId = adapterConfig.settings[kZoneId];
    
    if (![self isConfigValueValid:zoneId]) {
        NSError *error = [self errorForMissingCredentialFieldWithName:kZoneId];
        LogAdapterApi_Internal(@"error = %@", error);
        [delegate adapterBannerDidFailToLoadWithError:error];
        return;
    }
    
    LogAdapterApi_Internal(@"zoneId = %@", zoneId);
    
    // get size
    ISBannerSize *size = [bannerZoneIdToSize objectForKey:zoneId];
    
    // view controller
    UIViewController *viewController = [bannerZoneIdToViewController objectForKey:zoneId];
    
    // call load
    [self loadBannerWithViewController:viewController size:size adapterConfig:adapterConfig delegate:delegate];
}

- (BOOL)shouldBindBannerViewOnReload {
    return YES;
}

- (void)destroyBannerWithAdapterConfig:(nonnull ISAdapterConfig *)adapterConfig {
    NSString *zoneId = adapterConfig.settings[kZoneId];
    
    // get banner ad
    AdColonyAdView *bannerAd = [bannerZoneIdToAd objectForKey:zoneId];
    
    if (bannerAd) {
        LogAdapterApi_Internal(@"destroy banner ad");
        // destroy banner
        [bannerAd destroy];
        
        // remove from dictionaries
        [bannerZoneIdToSmashDelegate removeObjectForKey:zoneId];
        [bannerZoneIdToListener removeObjectForKey:zoneId];
        [bannerZoneIdToViewController removeObjectForKey:zoneId];
        [bannerZoneIdToSize removeObjectForKey:zoneId];
        [bannerZoneIdToAd removeObjectForKey:zoneId];
    }
}

- (void)releaseMemoryWithAdapterConfig:(nonnull ISAdapterConfig *)adapterConfig {
    // releasing memory currently only for banners
    NSString *zoneId = adapterConfig.settings[kZoneId];
    AdColonyAdView *bannerAd = [bannerZoneIdToAd objectForKey:zoneId];
    
    if (bannerAd) {
        [self destroyBannerWithAdapterConfig:adapterConfig];
    }
}

#pragma mark - Banner Callbacks

- (void)onBannerLoadSuccess:(AdColonyAdView * _Nonnull)adView forZoneId:(NSString * _Nonnull)zoneId {
    LogAdapterDelegate_Internal(@"zoneId = %@", zoneId);
    [bannerZoneIdToAd setObject:adView forKey:zoneId];
    
    // get delegate
    id<ISBannerAdapterDelegate> delegate = [bannerZoneIdToSmashDelegate objectForKey:zoneId];
    
    if (delegate) {
        [delegate adapterBannerDidLoad:adView];
        [delegate adapterBannerDidShow];
    }
}

- (void)onBannerLoadFailWithError:(AdColonyAdRequestError * _Nonnull)error forZoneId:(NSString * _Nonnull)zoneId {
    LogAdapterDelegate_Internal(@"zoneId = %@, error = %@", zoneId, error.localizedDescription);
    id<ISBannerAdapterDelegate> delegate = [bannerZoneIdToSmashDelegate objectForKey:zoneId];
    
    if (delegate) {
        LogAdapterDelegate_Internal(@"error.description = %@", error.description);
        NSError *bannerError = nil;
        
        if (error.code == AdColonyRequestErrorNoFillForRequest) {
            bannerError = [NSError errorWithDomain:kAdapterName code:ERROR_BN_LOAD_NO_FILL userInfo:@{NSLocalizedDescriptionKey:@"AdColony no fill"}];
        } else {
            bannerError = error;
        }
        
        [delegate adapterBannerDidFailToLoadWithError:bannerError];
    }
}

- (void)onBannerDidClick:(AdColonyAdView * _Nonnull)adView forZoneId:(NSString * _Nonnull)zoneId {
    LogAdapterDelegate_Internal(@"zoneId = %@", zoneId);
    id<ISBannerAdapterDelegate> delegate = [bannerZoneIdToSmashDelegate objectForKey:zoneId];
    
    if (delegate) {
        [delegate adapterBannerDidClick];
    }
}

- (void)onBannerBannerWillLeaveApplication:(AdColonyAdView * _Nonnull)adView forZoneId:(NSString * _Nonnull)zoneId {
    LogAdapterDelegate_Internal(@"zoneId = %@", zoneId);
    id<ISBannerAdapterDelegate> delegate = [bannerZoneIdToSmashDelegate objectForKey:zoneId];
    
    if (delegate) {
        [delegate adapterBannerWillLeaveApplication];
    }
}

- (void)onBannerBannerWillPresentScreen:(AdColonyAdView * _Nonnull)adView forZoneId:(NSString * _Nonnull)zoneId {
    LogAdapterDelegate_Internal(@"zoneId = %@", zoneId);
    id<ISBannerAdapterDelegate> delegate = [bannerZoneIdToSmashDelegate objectForKey:zoneId];
    
    if (delegate) {
        [delegate adapterBannerWillPresentScreen];
    }
}

- (void)onBannerBannerDidDismissScreen:(AdColonyAdView * _Nonnull)adView forZoneId:(NSString * _Nonnull)zoneId {
    LogAdapterDelegate_Internal(@"zoneId = %@", zoneId);
    id<ISBannerAdapterDelegate> delegate = [bannerZoneIdToSmashDelegate objectForKey:zoneId];
    
    if (delegate) {
        [delegate adapterBannerDidDismissScreen];
    }
}

#pragma mark - Private Methods

- (void)initWithAppId:(NSString *)appID
               userId:(NSString *)userId
           allZoneIds:(NSString *)allZoneIds {
    
    // add self to init delegates only
    // when init not finished yet
    if (_initState == INIT_STATE_NONE || _initState == INIT_STATE_IN_PROGRESS) {
        [initCallbackDelegates addObject:self];
    }
    
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        _initState = INIT_STATE_IN_PROGRESS;
        
        if (userId.length) {
            LogAdapterApi_Internal(@"set userID to %@", userId);
            adColonyOptions.userID = userId;
        }
        
        adColonyOptions.mediationNetwork = kMediationName;
        adColonyOptions.mediationNetworkVersion = AdColonyAdapterVersion;
        
        adColonyOptions.disableLogging = ![ISConfigurations getConfigurations].adaptersDebug;
        LogAdapterApi_Internal(@"set disableLogging to %d", adColonyOptions.disableLogging);
        
        NSArray *allZoneIdsArray = [allZoneIds componentsSeparatedByString:@","];
        
        LogAdapterApi_Internal(@"AdColony configureWithAppID %@", appID);
        [AdColony configureWithAppID:appID
                             zoneIDs:allZoneIdsArray
                             options:adColonyOptions
                          completion:^(NSArray<AdColonyZone *> *adColonyZones) {
            if (adColonyZones.count) {
                _initState = INIT_STATE_SUCCESS;
                adColonyInitZones = adColonyZones;
                
                // call init callback delegate success
                for (id<ISNetworkInitCallbackProtocol> initDelegate in initCallbackDelegates) {
                    [initDelegate onNetworkInitCallbackSuccess];
                }
            } else {
                _initState = INIT_STATE_FAILED;
            
                // call init callback delegate failed
                for (id<ISNetworkInitCallbackProtocol> initDelegate in initCallbackDelegates) {
                    [initDelegate onNetworkInitCallbackFailed:@""];
                }
            }

            // remove all init callback delegates
            [initCallbackDelegates removeAllObjects];
        }];
    });
}

// In case in the future we would recognize a case of failure to init AdColony we should return nil
- (NSDictionary *)getBiddingData {
    NSString *bidderToken = [AdColony collectSignals];
    NSString *returnedToken = bidderToken? bidderToken : @"";
    NSString *sdkVersion = [self sdkVersion];
    LogAdapterApi_Internal(@"token = %@", returnedToken);
    LogAdapterApi_Internal(@"sdkVersion = %@", sdkVersion);
    return @{@"token": returnedToken, @"sdkVersion": sdkVersion};
}

- (void)registerRewardedVideoZones {
    LogAdapterApi_Internal(@"");
    
    // zones from init
    for (AdColonyZone *zone in adColonyInitZones) {
        NSString *zoneId = zone.identifier;
        id<ISRewardedVideoAdapterDelegate> delegate = [rewardedVideoZoneIdToSmashDelegate objectForKey:zoneId];
        
        if (delegate && zone.rewarded) {
            LogAdapterApi_Internal(@"register zoneId = %@", zoneId);
            [zone setReward:^(BOOL success, NSString *name, int amount) {
                LogAdapterDelegate_Internal(@"zone %@ reward - success = %@", zoneId, success ? @"YES" : @"NO");
                if (success) {
                    [delegate adapterRewardedVideoDidReceiveReward];
                }
            }];
        }
    }
}

- (void)onNetworkInitCallbackSuccess {
    LogAdapterApi_Internal(@"");
    
    // register rewarded zones
    [self registerRewardedVideoZones];
    
    NSArray *rewardedVideoZoneIDs = rewardedVideoZoneIdToSmashDelegate.allKeys;

    // rewarded video
    for (NSString *zoneId in rewardedVideoZoneIDs) {
        if ([rewardedVideoPlacementsForInitCallbacks hasObject:zoneId]) {
            [[rewardedVideoZoneIdToSmashDelegate objectForKey:zoneId] adapterRewardedVideoInitSuccess];
        } else {
            [self loadRewardedVideo:zoneId];
        }
    }
    
    NSArray *interstitialZoneIDs = interstitialZoneIdToSmashDelegate.allKeys;
    
    // interstitial
    for (NSString *zoneId in interstitialZoneIDs) {
        id<ISInterstitialAdapterDelegate> delegate = [interstitialZoneIdToSmashDelegate objectForKey:zoneId];
        [delegate adapterInterstitialInitSuccess];
    }
    
    NSArray *bannerZoneIDs = bannerZoneIdToSmashDelegate.allKeys;

    // banner
    for (NSString *zoneId in bannerZoneIDs) {
        id<ISBannerAdapterDelegate> delegate = [bannerZoneIdToSmashDelegate objectForKey:zoneId];
        [delegate adapterBannerInitSuccess];
    }
}

- (void)onNetworkInitCallbackFailed:(nonnull NSString *)errorMessage {
    NSError *error = [NSError errorWithDomain:kAdapterName code:ERROR_CODE_INIT_FAILED userInfo:@{NSLocalizedDescriptionKey:@"AdColony SDK init failed"}];
    
    NSArray *rewardedVideoZoneIDs = rewardedVideoZoneIdToSmashDelegate.allKeys;

    // rewarded video
    for (NSString *zoneId in rewardedVideoZoneIDs) {
        if ([rewardedVideoPlacementsForInitCallbacks hasObject:zoneId]) {
            [[rewardedVideoZoneIdToSmashDelegate objectForKey:zoneId] adapterRewardedVideoInitFailed:error];
        }
        else {
            [[rewardedVideoZoneIdToSmashDelegate objectForKey:zoneId] adapterRewardedVideoHasChangedAvailability:NO];
        }
    }
    
    NSArray *interstitialZoneIDs = interstitialZoneIdToSmashDelegate.allKeys;
    
    // interstitial
    for (NSString *zoneId in interstitialZoneIDs) {
        id<ISInterstitialAdapterDelegate> delegate = [interstitialZoneIdToSmashDelegate objectForKey:zoneId];
        [delegate adapterInterstitialInitFailedWithError:error];
    }
    
    NSArray *bannerZoneIDs = bannerZoneIdToSmashDelegate.allKeys;

    // banner
    for (NSString *zoneId in bannerZoneIDs) {
        id<ISBannerAdapterDelegate> delegate = [bannerZoneIdToSmashDelegate objectForKey:zoneId];
        [delegate adapterBannerInitFailedWithError:error];
    }
}

- (BOOL)isBannerSizeSupported:(ISBannerSize *)size {
    if ([size.sizeDescription isEqualToString:@"BANNER"]     ||
        [size.sizeDescription isEqualToString:@"LARGE"]      ||
        [size.sizeDescription isEqualToString:@"RECTANGLE"]  ||
        [size.sizeDescription isEqualToString:@"SMART"]      ||
        [size.sizeDescription isEqualToString:@"CUSTOM"]
        ) {
        return YES;
    }
    
    return NO;
}

- (AdColonyAdSize)getBannerSize:(ISBannerSize *)size {
    if ([size.sizeDescription isEqualToString:@"BANNER"]     ||
        [size.sizeDescription isEqualToString:@"LARGE"]
       ) {
        return kAdColonyAdSizeBanner;
    } else if ([size.sizeDescription isEqualToString:@"RECTANGLE"]) {
        return kAdColonyAdSizeMediumRectangle;
    } else if ([size.sizeDescription isEqualToString:@"SMART"]) {
        return (UI_USER_INTERFACE_IDIOM() == UIUserInterfaceIdiomPad) ? kAdColonyAdSizeLeaderboard : kAdColonyAdSizeBanner;
    } else if ([size.sizeDescription isEqualToString:@"CUSTOM"]) {
        return AdColonyAdSizeMake(size.width, size.height);
    }
    
    return AdColonyAdSizeMake(0, 0);
}

- (void)setCCPAValue:(NSString *)value {
    //When "do_not_sell" is YES --> report consentString = NO
    //When "do_not_sell" is NO --> report consentString = YES
    BOOL isCCPAOptedIn = ![ISMetaDataUtils getCCPABooleanValue:value];
    NSString *consentString = isCCPAOptedIn ? @"1" : @"0";
    LogAdapterApi_Internal(@"value = %@ consentString = %@", value, consentString);
    [adColonyOptions setPrivacyFrameworkOfType:ADC_CCPA isRequired:YES];
    [adColonyOptions setPrivacyConsentString:consentString forType:ADC_CCPA];
    
    if (_initState == INIT_STATE_SUCCESS) {
        [AdColony setAppOptions:adColonyOptions];
    }
}

- (void)setCOPPAValue:(NSString *)value {
    LogAdapterApi_Internal(@"value = %@", value);
    
    BOOL isCOPPAOptedIn = [ISMetaDataUtils getCCPABooleanValue:value];
    [adColonyOptions setPrivacyFrameworkOfType:ADC_COPPA isRequired:isCOPPAOptedIn];
    
    if (_initState == INIT_STATE_SUCCESS) {
        [AdColony setAppOptions:adColonyOptions];
    }
}

/**
This method checks if the Meta Data key is the AdColony COPPA key

@param key The Meta Data key
*/
- (BOOL)isValidCOPPAMetaDataKey:(NSString *)key {
    return ([key caseInsensitiveCompare:kMetaDataCOPPAKey] == NSOrderedSame);
}

@end
