//
//  Created by IronSource on 2015.
//  Copyright (c) 2014 IronSource. All rights reserved.
//

#import "ISChartboostAdapter.h"
#import "ISChartboostInterstitialListener.h"
#import "ISChartboostRewardedListener.h"
#import "ISChartboostBannerListener.h"

#import <Chartboost+Mediation.h>

static NSString * const kAdapterVersion             = ChartboostAdapterVersion;

static NSString * const kAdapterName                = @"Chartboost";
static NSString * const kAppSignature               = @"appSignature";
static NSString * const kLocationId                 = @"adLocation";
static NSString * const kAppID                      = @"appID";

#define CHARTBOOST_MEDIATION_NAME CBMediationSupersonic

@interface ISChartboostAdapter () <ISChartboostInterstitialWrapper, ISChartboostRewardedWrapper, ISChartboostBannerWrapper, ISNetworkInitCallbackProtocol>
@end

typedef NS_ENUM(NSInteger, InitState) {
    INIT_STATE_NONE,
    INIT_STATE_IN_PROGRESS,
    INIT_STATE_FAILED,
    INIT_STATE_SUCCESS
};

static InitState initState = INIT_STATE_NONE;

static ConcurrentMutableSet<ISNetworkInitCallbackProtocol> *initCallbackDelegates = nil;

@implementation ISChartboostAdapter
{
    // rewarded video
    ConcurrentMutableDictionary *rewardedVideoLocationIdToSmashDelegate;
    ConcurrentMutableDictionary *rewardedVideoLocationIdToListener;
    ConcurrentMutableDictionary *rewardedVideoLocationIdToAd;
    NSMutableSet                *rewardedVideoPlacementsForInitCallbacks;

    // interstitial
    ConcurrentMutableDictionary *interstitialLocationIdToSmashDelegate;
    ConcurrentMutableDictionary *interstitialLocationIdToListener;
    ConcurrentMutableDictionary *interstitialLocationIdToAd;

    // banner
    ConcurrentMutableDictionary *bannerLocationIdToSmashDelegate;
    ConcurrentMutableDictionary *bannerLocationIdToListener;
    ConcurrentMutableDictionary *bannerLocationIdToAd;
    ConcurrentMutableDictionary *bannerLocationIdToViewController;
    ConcurrentMutableDictionary *bannerLocationIdToSize;
}

#pragma mark - Initializations Methods

- (instancetype) initAdapter:(NSString *)name {
    self = [super initAdapter:name];
    
    if (self) {
        if (initCallbackDelegates == nil) {
            initCallbackDelegates = [ConcurrentMutableSet<ISNetworkInitCallbackProtocol> set];
        }
        
        // rewarded video
        rewardedVideoLocationIdToSmashDelegate = [ConcurrentMutableDictionary dictionary];
        rewardedVideoLocationIdToListener = [ConcurrentMutableDictionary dictionary];
        rewardedVideoLocationIdToAd = [ConcurrentMutableDictionary dictionary];
        rewardedVideoPlacementsForInitCallbacks = [[NSMutableSet alloc] init];
        
        // interstitial
        interstitialLocationIdToSmashDelegate = [ConcurrentMutableDictionary dictionary];
        interstitialLocationIdToListener = [ConcurrentMutableDictionary dictionary];
        interstitialLocationIdToAd = [ConcurrentMutableDictionary dictionary];

        // banner
        bannerLocationIdToSmashDelegate = [ConcurrentMutableDictionary dictionary];
        bannerLocationIdToListener = [ConcurrentMutableDictionary dictionary];
        bannerLocationIdToAd = [ConcurrentMutableDictionary dictionary];
        bannerLocationIdToViewController = [ConcurrentMutableDictionary dictionary];
        bannerLocationIdToSize = [ConcurrentMutableDictionary dictionary];
        
        // load while show
        LWSState = LOAD_WHILE_SHOW_BY_NETWORK;
    }
    
    return self;
}

#pragma mark - IronSource Protocol Methods

- (NSString *) sdkVersion {
    return [Chartboost getSDKVersion];
}

- (NSString *) version {
    return kAdapterVersion;
}

- (NSArray *) systemFrameworks {
    return @[@"AdSupport", @"AVFoundation", @"CoreGraphics", @"CoreMedia", @"Foundation", @"StoreKit", @"UIKit", @"WebKit"];
}

- (NSString *) sdkName {
    return @"Chartboost";
}

- (void) setConsent:(BOOL)consent {
    LogAdapterApi_Internal(@"consent = %@", consent ? @"Yes" : @"No");
    [Chartboost addDataUseConsent:[CHBGDPRDataUseConsent gdprConsent:(consent? CHBGDPRConsentBehavioral : CHBGDPRConsentNonBehavioral)]];
}

#pragma mark - Rewarded Video API

- (void) initAndLoadRewardedVideoWithUserId:(NSString *)userId
                              adapterConfig:(ISAdapterConfig *)adapterConfig
                                   delegate:(id<ISRewardedVideoAdapterDelegate>)delegate {
    
    if (delegate == nil) {
        LogAdapterApi_Internal(@"failed - delegate == nil");
        return;
    }
    
    NSString *appId = adapterConfig.settings[kAppID];
    
    if (![self isConfigValueValid:appId]) {
        NSError *error = [self errorForMissingCredentialFieldWithName:kAppID];
        LogAdapterApi_Internal(@"failed - error.description = %@", error.description);
        [delegate adapterRewardedVideoHasChangedAvailability:NO];
        return;
    }
    
    NSString *appSignature = adapterConfig.settings[kAppSignature];
    
    if (![self isConfigValueValid:appSignature]) {
        NSError *error = [self errorForMissingCredentialFieldWithName:kAppSignature];
        LogAdapterApi_Internal(@"failed - error.description = %@", error.description);
        [delegate adapterRewardedVideoHasChangedAvailability:NO];
        return;
    }
    
    NSString *locationId = [self getLocationId:adapterConfig];
    
    if (![self isConfigValueValid:locationId]) {
        NSError *error = [self errorForMissingCredentialFieldWithName:kLocationId];
        LogAdapterApi_Internal(@"failed - error.description = %@", error.description);
        [delegate adapterRewardedVideoHasChangedAvailability:NO];
        return;
    }
    
    LogAdapterApi_Internal(@"locationId = %@", locationId);
    [rewardedVideoLocationIdToSmashDelegate setObject:delegate
                                               forKey:locationId];

    // create listener
    ISChartboostRewardedListener *listener = [[ISChartboostRewardedListener alloc] initWithPlacementId:locationId
                                                                                           andDelegate:self];
    
    // add listener to dictionary
    [rewardedVideoLocationIdToListener setObject:listener
                                          forKey:locationId];
    
    switch (initState) {
        case INIT_STATE_NONE:
        case INIT_STATE_IN_PROGRESS:
            // init SDK
            [self initSDKWithAppId:appId
                      appSignature:appSignature
                          customId:userId];
            break;
        case INIT_STATE_SUCCESS: {
            CHBRewarded *rewardedAd = [self getRewardedAdForLocationId:locationId];
            LogAdapterApi_Internal(@"load rewarded video");
            [rewardedAd cache];
            break;
        }
        case INIT_STATE_FAILED:
            [delegate adapterRewardedVideoHasChangedAvailability:NO];
            break;
    }
}

- (void) initRewardedVideoForCallbacksWithUserId:(NSString *)userId
                                   adapterConfig:(ISAdapterConfig *)adapterConfig
                                        delegate:(id<ISRewardedVideoAdapterDelegate>)delegate {
    if (delegate == nil) {
        LogAdapterApi_Internal(@"failed - delegate == nil");
        return;
    }
    
    NSString *appId = adapterConfig.settings[kAppID];
    
    if (![self isConfigValueValid:appId]) {
        NSError *error = [self errorForMissingCredentialFieldWithName:kAppID];
        LogAdapterApi_Internal(@"error = %@", error);
        [delegate adapterRewardedVideoInitFailed:error];
        return;
    }
    
    NSString *appSignature = adapterConfig.settings[kAppSignature];
    
    if (![self isConfigValueValid:appSignature]) {
        NSError *error = [self errorForMissingCredentialFieldWithName:kAppSignature];
        LogAdapterApi_Internal(@"error = %@", error);
        [delegate adapterRewardedVideoInitFailed:error];
        return;
    }
    
    NSString *locationId = [self getLocationId:adapterConfig];
    
    if (![self isConfigValueValid:locationId]) {
        NSError *error = [self errorForMissingCredentialFieldWithName:kLocationId];
        LogAdapterApi_Internal(@"failed - error.description = %@", error.description);
        [delegate adapterRewardedVideoInitFailed:error];
        return;
    }
    
    LogAdapterApi_Internal(@"locationId = %@", locationId);
    [rewardedVideoLocationIdToSmashDelegate setObject:delegate
                                               forKey:locationId];

    // create listener
    ISChartboostRewardedListener *listener = [[ISChartboostRewardedListener alloc] initWithPlacementId:locationId
                                                                                           andDelegate:self];
    
    // add listener to dictionary
    [rewardedVideoLocationIdToListener setObject:listener
                                          forKey:locationId];
    
    [rewardedVideoPlacementsForInitCallbacks addObject:locationId];
    
    switch (initState) {
        case INIT_STATE_NONE:
        case INIT_STATE_IN_PROGRESS:
            // init SDK
            [self initSDKWithAppId:appId
                      appSignature:appSignature
                          customId:userId];
            break;
        case INIT_STATE_SUCCESS: {
            // Creating a rewarded video ad object
            [self getRewardedAdForLocationId:locationId];
            [delegate adapterRewardedVideoInitSuccess];
            break;
        }
        case INIT_STATE_FAILED: {
            NSError *error = [NSError errorWithDomain:kAdapterName
                                                 code:ERROR_CODE_INIT_FAILED
                                             userInfo:@{NSLocalizedDescriptionKey:@"Chartboost SDK init failed"}];
            LogAdapterApi_Internal(@"error = %@", error);
            [delegate adapterRewardedVideoInitFailed:error];
            break;
        }
    }
}

- (void) fetchRewardedVideoForAutomaticLoadWithAdapterConfig:(ISAdapterConfig *)adapterConfig
                                                    delegate:(id<ISRewardedVideoAdapterDelegate>)delegate {
    NSString *locationId = [self getLocationId:adapterConfig];
    LogAdapterApi_Internal(@"locationId = %@", locationId);
    
    CHBRewarded *rewardedLocation = [rewardedVideoLocationIdToAd objectForKey:locationId];
    
    if (rewardedLocation) {
        LogAdapterApi_Internal(@"load rewarded video");
        [rewardedLocation cache];
    } else {
        id<ISRewardedVideoAdapterDelegate> delegate = [rewardedVideoLocationIdToSmashDelegate objectForKey:locationId];
        
        if (delegate) {
            [delegate adapterRewardedVideoHasChangedAvailability:NO];
        }
    }
}

- (void) showRewardedVideoWithViewController:(UIViewController *)viewController
                               adapterConfig:(ISAdapterConfig *)adapterConfig
                                    delegate:(id<ISRewardedVideoAdapterDelegate>)delegate {
    NSString *locationId = [self getLocationId:adapterConfig];
    LogAdapterApi_Internal(@"locationId = %@", locationId);
    [delegate adapterRewardedVideoHasChangedAvailability:NO];
    CHBRewarded *rewardedLocation = [rewardedVideoLocationIdToAd objectForKey:locationId];
    
    if ([self hasRewardedVideoWithAdapterConfig:adapterConfig]) {
        LogAdapterApi_Internal(@"show rewarded video");
        [rewardedLocation showFromViewController:viewController];
    } else {
        NSError *error = [NSError errorWithDomain:kAdapterName
                                             code:ERROR_CODE_NO_ADS_TO_SHOW
                                         userInfo:@{NSLocalizedDescriptionKey:@"ISChartboost showRewardedVideoWithViewController"}];
        LogAdapterApi_Internal(@"error = %@", error);
        [delegate adapterRewardedVideoDidFailToShowWithError:error];
    }
}

- (BOOL) hasRewardedVideoWithAdapterConfig:(ISAdapterConfig *)adapterConfig {
    NSString *locationId = [self getLocationId:adapterConfig];
    CHBRewarded *rewardedAd = [rewardedVideoLocationIdToAd objectForKey:locationId];
    return ((rewardedAd != nil) && rewardedAd.isCached);
}

#pragma mark - Interstitial API

- (void) initInterstitialWithUserId:(NSString *)userId
                      adapterConfig:(ISAdapterConfig *)adapterConfig
                           delegate:(id<ISInterstitialAdapterDelegate>)delegate {
    if (delegate == nil) {
        LogAdapterApi_Internal(@"delegate == nil");
        return;
    }
    
    NSString *appId = adapterConfig.settings[kAppID];
    
    if (![self isConfigValueValid:appId]) {
        NSError *error = [self errorForMissingCredentialFieldWithName:kAppID];
        LogAdapterApi_Internal(@"error = %@", error);
        [delegate adapterInterstitialInitFailedWithError:error];
        return;
    }
    
    NSString *appSignature = adapterConfig.settings[kAppSignature];
    
    if (![self isConfigValueValid:appSignature]) {
        NSError *error = [self errorForMissingCredentialFieldWithName:kAppSignature];
        LogAdapterApi_Internal(@"error = %@", error);
        [delegate adapterInterstitialInitFailedWithError:error];
        return;
    }
    
    NSString *locationId = [self getLocationId:adapterConfig];
    
    if (![self isConfigValueValid:locationId]) {
        NSError *error = [self errorForMissingCredentialFieldWithName:kLocationId];
        LogAdapterApi_Internal(@"failed - error.description = %@", error.description);
        [delegate adapterInterstitialInitFailedWithError:error];
        return;
    }
    
    LogAdapterApi_Internal(@"locationId = %@", locationId);
    [interstitialLocationIdToSmashDelegate setObject:delegate
                                              forKey:locationId];
    
    // create listener
    ISChartboostInterstitialListener *listener = [[ISChartboostInterstitialListener alloc] initWithPlacementId:locationId
                                                                                                   andDelegate:self];
    
    // add listener to dictionary
    [interstitialLocationIdToListener setObject:listener
                                         forKey:locationId];
    
    switch (initState) {
        case INIT_STATE_NONE:
        case INIT_STATE_IN_PROGRESS:
            // init SDK
            [self initSDKWithAppId:appId
                      appSignature:appSignature
                          customId:userId];
            break;
        case INIT_STATE_SUCCESS:
            [delegate adapterInterstitialInitSuccess];
            break;
        case INIT_STATE_FAILED: {
            NSError *error = [NSError errorWithDomain:kAdapterName
                                                 code:ERROR_CODE_INIT_FAILED
                                             userInfo:@{NSLocalizedDescriptionKey:@"Chartboost SDK init failed"}];
            LogAdapterApi_Internal(@"error = %@", error);
            [delegate adapterInterstitialInitFailedWithError:error];
            break;
        }
    }
}

- (void) loadInterstitialWithAdapterConfig:(ISAdapterConfig *)adapterConfig
                                  delegate:(id<ISInterstitialAdapterDelegate>)delegate {
    NSString *locationId = [self getLocationId:adapterConfig];
    LogAdapterApi_Internal(@"locationId = %@", locationId);
    
    // get interstitial
    CHBInterstitial *interstitialAd = [self getChartboostInterstitial:locationId];

    if (interstitialAd) {
        LogAdapterApi_Internal(@"load interstitial");
        [interstitialAd cache];
    } else {
        id<ISInterstitialAdapterDelegate> delegate = [interstitialLocationIdToSmashDelegate objectForKey:locationId];
        
        if (delegate) {
            NSError *error = [NSError errorWithDomain:kAdapterName
                                                 code:ERROR_IS_LOAD_FAILED_NO_CANDIDATES
                                             userInfo:@{NSLocalizedDescriptionKey:@"Chartboost SDK load interstitial failed"}];
            LogAdapterApi_Internal(@"error = %@", error);
            [delegate adapterInterstitialDidFailToLoadWithError:error];
        }
    }
}

- (void) showInterstitialWithViewController:(UIViewController *)viewController
                              adapterConfig:(ISAdapterConfig *)adapterConfig
                                   delegate:(id<ISInterstitialAdapterDelegate>)delegate {
    NSString *locationId = [self getLocationId:adapterConfig];
    LogAdapterApi_Internal(@"locationId = %@", locationId);
    
    CHBInterstitial *interstitialAd = [interstitialLocationIdToAd objectForKey:locationId];
    
    if ([self hasInterstitialWithAdapterConfig:adapterConfig]) {
        LogAdapterApi_Internal(@"show interstitial");
        [interstitialAd showFromViewController:viewController];
    } else {
        NSError *error = [NSError errorWithDomain:kAdapterName
                                             code:ERROR_CODE_NO_ADS_TO_SHOW
                                         userInfo:@{NSLocalizedDescriptionKey:@"ISChartboost showInterstitialWithViewController"}];
        LogAdapterApi_Internal(@"error = %@", error);
        [delegate adapterInterstitialDidFailToShowWithError:error];
    }
}

- (BOOL) hasInterstitialWithAdapterConfig:(ISAdapterConfig *)adapterConfig {
    NSString *locationId = [self getLocationId:adapterConfig];
    CHBInterstitial *interstitialAd = [interstitialLocationIdToAd objectForKey:locationId];
    return ((interstitialAd != nil) && interstitialAd.isCached);
}

#pragma mark - Banner API

- (void) initBannerWithUserId:(nonnull NSString *)userId
                adapterConfig:(nonnull ISAdapterConfig *)adapterConfig
                     delegate:(nonnull id<ISBannerAdapterDelegate>)delegate {
    if (delegate == nil) {
        LogAdapterApi_Internal(@"delegate == nil");
        return;
    }
    
    NSString *appId = adapterConfig.settings[kAppID];
    
    if (![self isConfigValueValid:appId]) {
        NSError *error = [self errorForMissingCredentialFieldWithName:kAppID];
        LogAdapterApi_Internal(@"error = %@", error);
        [delegate adapterBannerInitFailedWithError:error];
        return;
    }
    
    NSString *appSignature = adapterConfig.settings[kAppSignature];
    
    if (![self isConfigValueValid:appSignature]) {
        NSError *error = [self errorForMissingCredentialFieldWithName:kAppSignature];
        LogAdapterApi_Internal(@"error = %@", error);
        [delegate adapterBannerInitFailedWithError:error];
        return;
    }
    
    NSString *locationId = [self getLocationId:adapterConfig];
    
    if (![self isConfigValueValid:locationId]) {
        NSError *error = [self errorForMissingCredentialFieldWithName:kLocationId];
        LogAdapterApi_Internal(@"error = %@", error);
        [delegate adapterBannerInitFailedWithError:error];
        return;
    }
    
    LogAdapterApi_Internal(@"locationId = %@", locationId);
    [bannerLocationIdToSmashDelegate setObject:delegate
                                        forKey:locationId];
    
    // create listener
    ISChartboostBannerListener *listener = [[ISChartboostBannerListener alloc] initWithPlacementId:locationId
                                                                                       andDelegate:self];
    
    // add listener to dictionary
    [bannerLocationIdToListener setObject:listener
                                   forKey:locationId];
    
    switch (initState) {
        case INIT_STATE_NONE:
        case INIT_STATE_IN_PROGRESS:
            // init SDK
            [self initSDKWithAppId:appId
                      appSignature:appSignature
                          customId:userId];
            break;
        case INIT_STATE_SUCCESS:
            [delegate adapterBannerInitSuccess];
            break;
        case INIT_STATE_FAILED: {
            NSError *error = [NSError errorWithDomain:kAdapterName
                                                 code:ERROR_CODE_INIT_FAILED
                                             userInfo:@{NSLocalizedDescriptionKey:@"Chartboost SDK init failed"}];
            LogAdapterApi_Internal(@"error = %@", error);
            [delegate adapterBannerInitFailedWithError:error];
            break;
        }
    }
}

- (void) loadBannerWithViewController:(nonnull UIViewController *)viewController
                                 size:(ISBannerSize *)size
                        adapterConfig:(nonnull ISAdapterConfig *)adapterConfig
                             delegate:(nonnull id <ISBannerAdapterDelegate>)delegate {
    NSString *locationId = [self getLocationId:adapterConfig];
    
    if (![self isConfigValueValid:locationId]) {
        NSError *error = [self errorForMissingCredentialFieldWithName:kLocationId];
        LogAdapterApi_Internal(@"error = %@", error);
        [delegate adapterBannerDidFailToLoadWithError:error];
        return;
    }
    
    LogAdapterApi_Internal(@"locationId = %@", locationId);
    
    if ([self isBannerSizeSupported:size]) {
        CHBBanner *bannerAd = [bannerLocationIdToAd objectForKey:locationId];
        
        if (bannerAd) {
            [bannerAd cache];
        } else {
            [self createAndLoadBannerWithViewController:viewController
                                                   size:size
                                             locationId:locationId];
        }
    } else {
         // size not supported
        NSError *error = [NSError errorWithDomain:kAdapterName
                                             code:ERROR_BN_UNSUPPORTED_SIZE
                                         userInfo:@{NSLocalizedDescriptionKey:@"Chartboost unsupported banner size"}];
         LogAdapterApi_Internal(@"error = %@", error);
         [delegate adapterBannerDidFailToLoadWithError:error];
    }
}

- (void) reloadBannerWithAdapterConfig:(nonnull ISAdapterConfig *)adapterConfig
                              delegate:(nonnull id <ISBannerAdapterDelegate>)delegate {
    // get location id
    NSString *locationId = [self getLocationId:adapterConfig];
    LogAdapterApi_Internal(@"locationId = %@", locationId);
    
    // get view controller
    UIViewController *viewController = [bannerLocationIdToViewController objectForKey:locationId];
    
    // get size
    ISBannerSize *size = [bannerLocationIdToSize objectForKey:locationId];
    
    if (viewController && size) {
        // call load
        [self loadBannerWithViewController:viewController
                                      size:size
                             adapterConfig:adapterConfig
                                  delegate:delegate];
    } else {
        NSError *error = [NSError errorWithDomain:kAdapterName
                                             code:ERROR_CODE_NO_ADS_TO_RELOAD
                                         userInfo:@{NSLocalizedDescriptionKey:[NSString stringWithFormat:@"no data for locationId = %@", locationId]}];
        LogAdapterApi_Internal(@"error = %@", error);
        [delegate adapterBannerDidFailToLoadWithError:error];
    }
}

- (void) destroyBannerWithAdapterConfig:(nonnull ISAdapterConfig *)adapterConfig {
    LogAdapterApi_Internal(@"");
    // NO required API to destroy the banner
    
    NSString *locationId = [self getLocationId:adapterConfig];
    [bannerLocationIdToAd removeObjectForKey:locationId];
    [bannerLocationIdToSize removeObjectForKey:locationId];
    [bannerLocationIdToViewController removeObjectForKey:locationId];
    [bannerLocationIdToListener removeObjectForKey:locationId];
    [bannerLocationIdToSmashDelegate removeObjectForKey:locationId];
}

- (BOOL) shouldBindBannerViewOnReload {
    return YES;
}

#pragma mark - Rewarded Video Delegate

// Called after a rewarded video has been loaded from the Chartboost API servers and cached locally.
- (void) didCacheRewardedVideo:(NSString *)locationId {
    LogAdapterDelegate_Internal(@"locationId = %@", locationId);
    id<ISRewardedVideoAdapterDelegate> delegate = [rewardedVideoLocationIdToSmashDelegate objectForKey:locationId];
    
    if (delegate) {
        [delegate adapterRewardedVideoHasChangedAvailability:YES];
    }
}

- (void) didFailToCacheRewardedVideo:(NSString *)locationId
                           withError:(CHBCacheError *)error {
    LogAdapterDelegate_Internal(@"locationId = %@, error = %ld - %@", locationId, (long)error.code, error.description);
    id<ISRewardedVideoAdapterDelegate> delegate = [rewardedVideoLocationIdToSmashDelegate objectForKey:locationId];
    
    if (delegate) {
        [delegate adapterRewardedVideoHasChangedAvailability:NO];
        
        if (error) {
            NSInteger errorCode = (error.code == CHBCacheErrorCodeNoAdFound) ? ERROR_RV_LOAD_NO_FILL : error.code;
            NSError *smashError = [NSError errorWithDomain:kAdapterName
                                                      code:errorCode
                                                  userInfo:@{NSLocalizedDescriptionKey:error.description}];
            [delegate adapterRewardedVideoDidFailToLoadWithError:smashError];
        }
    }
}

- (void) didDisplayRewardedVideo:(NSString *)locationId {
    LogAdapterDelegate_Internal(@"locationId = %@", locationId);
    id<ISRewardedVideoAdapterDelegate> delegate = [rewardedVideoLocationIdToSmashDelegate objectForKey:locationId];
    
    if (delegate) {
        [delegate adapterRewardedVideoDidOpen];
        [delegate adapterRewardedVideoDidStart];
    }
}

- (void) didFailToShowRewardedVideo:(NSString *)locationId
                          withError:(CHBShowError *)error {
    LogAdapterDelegate_Internal(@"locationId = %@, error = %ld - %@", locationId, (long)error.code, error.description);
    id<ISRewardedVideoAdapterDelegate> delegate = [rewardedVideoLocationIdToSmashDelegate objectForKey:locationId];
    
    if (delegate) {
        NSError *smashError = [NSError errorWithDomain:kAdapterName
                                                  code:error.code
                                              userInfo:@{NSLocalizedDescriptionKey: error.description}];
        [delegate adapterRewardedVideoDidFailToShowWithError:smashError];
    }
}

- (void) didClickRewardedVideo:(NSString *)locationId {
    LogAdapterDelegate_Internal(@"locationId = %@", locationId);
    id<ISRewardedVideoAdapterDelegate> delegate = [rewardedVideoLocationIdToSmashDelegate objectForKey:locationId];
    
    if (delegate) {
        [delegate adapterRewardedVideoDidClick];
    }
}

- (void) didCompleteRewardedVideo:(NSString *)locationId {
    LogAdapterDelegate_Internal(@"locationId = %@", locationId);
    id<ISRewardedVideoAdapterDelegate> delegate = [rewardedVideoLocationIdToSmashDelegate objectForKey:locationId];
    
    if (delegate) {
        [delegate adapterRewardedVideoDidReceiveReward];
    }
}

- (void) didDismissRewardedVideo:(NSString *)locationId {
    LogAdapterDelegate_Internal(@"locationId = %@", locationId);
    id<ISRewardedVideoAdapterDelegate> delegate = [rewardedVideoLocationIdToSmashDelegate objectForKey:locationId];
    
    if (delegate) {
        [delegate adapterRewardedVideoDidClose];
    }
}

#pragma mark - Interstitial Delegate

- (void) didCacheInterstitial:(NSString *)locationId {
    LogAdapterDelegate_Internal(@"locationId = %@", locationId);
    id<ISInterstitialAdapterDelegate> delegate = [interstitialLocationIdToSmashDelegate objectForKey:locationId];
    
    if (delegate) {
        [delegate adapterInterstitialDidLoad];
    }
}

- (void) didFailToCacheInterstitial:(NSString *)locationId
                          withError:(CHBCacheError *)error {
    LogAdapterDelegate_Internal(@"locationId = %@, error = %ld - %@", locationId, (long)error.code, error.description);
    id<ISInterstitialAdapterDelegate> delegate = [interstitialLocationIdToSmashDelegate objectForKey:locationId];
    
    if (delegate) {
        NSInteger errorCode = (error.code == CHBCacheErrorCodeNoAdFound) ? ERROR_IS_LOAD_NO_FILL : error.code;
        NSError *smashError = [NSError errorWithDomain:kAdapterName
                                                  code:errorCode
                                              userInfo:@{NSLocalizedDescriptionKey: error.description}];
        [delegate adapterInterstitialDidFailToLoadWithError:smashError];
    }
}

- (void) didDisplayInterstitial:(NSString *)locationId {
    LogAdapterDelegate_Internal(@"locationId = %@", locationId);
    id<ISInterstitialAdapterDelegate> delegate = [interstitialLocationIdToSmashDelegate objectForKey:locationId];
    
    if (delegate) {
        [delegate adapterInterstitialDidShow];
        [delegate adapterInterstitialDidOpen];
    }
}

- (void) didFailToShowInterstitial:(NSString *)locationId
                         withError:(CHBCacheError *)error {
    LogAdapterDelegate_Internal(@"locationId = %@, error = %ld - %@", locationId, (long)error.code, error.description);
    id<ISInterstitialAdapterDelegate> delegate = [interstitialLocationIdToSmashDelegate objectForKey:locationId];
    
    if (delegate) {
        NSError *smashError = [NSError errorWithDomain:kAdapterName
                                                  code:error.code
                                              userInfo:@{NSLocalizedDescriptionKey:error.description}];
        [delegate adapterInterstitialDidFailToShowWithError:smashError];
    }
}

- (void) didClickInterstitial:(NSString *)locationId {
    LogAdapterDelegate_Internal(@"locationId = %@", locationId);
    id<ISInterstitialAdapterDelegate> delegate = [interstitialLocationIdToSmashDelegate objectForKey:locationId];
    
    if (delegate) {
        [delegate adapterInterstitialDidClick];
    }
}

- (void) didDismissInterstitial:(NSString *)locationId {
    LogAdapterDelegate_Internal(@"locationId = %@", locationId);
    id<ISInterstitialAdapterDelegate> delegate = [interstitialLocationIdToSmashDelegate objectForKey:locationId];
    
    if (delegate) {
        [delegate adapterInterstitialDidClose];
    }
}


#pragma mark - Banner Delegate

- (void) didCacheBanner:(NSString *)locationId {
    LogAdapterDelegate_Internal(@"locationId = %@", locationId);
    CHBBanner *banner = [bannerLocationIdToAd objectForKey:locationId];
    UIViewController *viewController = [bannerLocationIdToViewController objectForKey:locationId];

    if (banner && viewController) {
        id<ISBannerAdapterDelegate> delegate = [bannerLocationIdToSmashDelegate objectForKey:locationId];

        if (delegate && [banner isCached]) {
            [delegate adapterBannerDidLoad:banner];
            [banner showFromViewController:viewController];
        }
    }
}

- (void) didFailToCacheBanner:(NSString *)locationId
                    withError:(CHBCacheError *)error {
    LogAdapterDelegate_Internal(@"locationId = %@, error = %@", locationId, error);
    id<ISBannerAdapterDelegate> delegate = [bannerLocationIdToSmashDelegate objectForKey:locationId];

    if (delegate) {
        NSError *smashError;
        
        if (error.code == CHBCacheErrorCodeNoAdFound) {
            smashError = [NSError errorWithDomain:kAdapterName
                                             code:ERROR_BN_LOAD_NO_FILL
                                         userInfo:@{NSLocalizedDescriptionKey:@"ISChartboost didFailToCacheBanner"}];
        } else {
            smashError = [NSError errorWithDomain:kAdapterName
                                             code:error.code
                                         userInfo:@{NSLocalizedDescriptionKey:error.description}];
        }
        
        [delegate adapterBannerDidFailToLoadWithError:smashError];
    }
}

- (void) didShowBanner:(NSString *)locationId {
    LogAdapterDelegate_Internal(@"locationId = %@", locationId);
    id<ISBannerAdapterDelegate> delegate = [bannerLocationIdToSmashDelegate objectForKey:locationId];

    if (delegate) {
        [delegate adapterBannerDidShow];
    }
}

- (void) didFailToShowBanner:(NSString *)locationId
                   withError:(CHBShowError *)error {
    LogAdapterDelegate_Internal(@"locationId = %@, error = %@", locationId, error);
}

- (void) didClickBanner:(NSString *)locationId {
    LogAdapterDelegate_Internal(@"locationId = %@", locationId);
    id<ISBannerAdapterDelegate> delegate = [bannerLocationIdToSmashDelegate objectForKey:locationId];
    
    if (delegate) {
        [delegate adapterBannerDidClick];
    }
}

#pragma mark - Chartboost Init

- (void) initSDKWithAppId:(NSString *)appId
             appSignature:(NSString *)signature
                 customId:(NSString *)userId {
    // add self to init delegates only
    // when init not finished yet
    if ((initState == INIT_STATE_NONE) || (initState == INIT_STATE_IN_PROGRESS)) {
        [initCallbackDelegates addObject:self];
    }
    
    static dispatch_once_t initToken;
    dispatch_once(&initToken, ^{
        LogAdapterApi_Internal(@"appId = %@ - signature = %@ - userId = %@", appId, signature, userId);
        initState = INIT_STATE_IN_PROGRESS;
        
        if ([self.pluginType isEqualToString:@"Unity"] && self.pluginFrameworkVersion) {
            [Chartboost setFramework:CBFrameworkUnity
                         withVersion:self.pluginFrameworkVersion];
        }
        
        CBLoggingLevel logLevel = ([ISConfigurations getConfigurations].adaptersDebug) ? CBLoggingLevelVerbose : CBLoggingLevelError;
        [Chartboost setLoggingLevel:(logLevel)];
        LogAdapterApi_Internal(@"loggingLevel = %lu", (unsigned long)logLevel);

        [Chartboost startWithAppId:appId
                      appSignature:signature
                        completion:^(BOOL success) {
            LogAdapterDelegate_Internal(@"status = %@", success ? @"succeeded" : @"failed");
            NSArray *initDelegatesList = initCallbackDelegates.allObjects;

            if (success) {
                initState = INIT_STATE_SUCCESS;
                
                for (id<ISNetworkInitCallbackProtocol> delegate in initDelegatesList) {
                    [delegate onNetworkInitCallbackSuccess];
                }
            } else {
                initState = INIT_STATE_FAILED;
                
                for (id<ISNetworkInitCallbackProtocol> delegate in initDelegatesList) {
                    [delegate onNetworkInitCallbackFailed:@"Chartboost SDK init failed"];
                }
            }
            
            // remove all init callback delegates
            [initCallbackDelegates removeAllObjects];
        }];

        if (userId && userId.length) {
            LogAdapterApi_Internal(@"set userID to %@", userId);
            [Chartboost setCustomId:userId];
        }
    });
}

- (void) onNetworkInitCallbackSuccess {
    LogAdapterApi_Internal(@"");
    
    // handle rewarded video
    NSArray *rewardedVideoLocationIDs = rewardedVideoLocationIdToSmashDelegate.allKeys;

    for (NSString *locationId in rewardedVideoLocationIDs) {
        // In case of init and load this a preperation of the ad object
        // In case of init without load we are prepering the ad object for the upcoming fetch
        CHBRewarded *rewarded = [self getRewardedAdForLocationId:locationId];
        
        if ([rewardedVideoPlacementsForInitCallbacks containsObject:locationId]) {
            id<ISRewardedVideoAdapterDelegate> delegate = [rewardedVideoLocationIdToSmashDelegate objectForKey:locationId];
            [delegate adapterRewardedVideoInitSuccess];
        } else {
            // load video
            LogAdapterApi_Internal(@"load rewarded video");
            [rewarded cache];
        }
    }
    
    // handle interstitial
    NSArray *interstitialLocationIDs = interstitialLocationIdToSmashDelegate.allKeys;

    for (NSString *locationId in interstitialLocationIDs) {
        id<ISInterstitialAdapterDelegate> delegate = [interstitialLocationIdToSmashDelegate objectForKey:locationId];
        [delegate adapterInterstitialInitSuccess];
    }
    
    // handle banners
    NSArray *bannerLocationIDs = bannerLocationIdToSmashDelegate.allKeys;

    for (NSString *locationId in bannerLocationIDs) {
        id<ISBannerAdapterDelegate> delegate = [bannerLocationIdToSmashDelegate objectForKey:locationId];
        [delegate adapterBannerInitSuccess];
    }
}

- (void) onNetworkInitCallbackFailed:(nonnull NSString *)errorMessage {
    NSError *error = [NSError errorWithDomain:kAdapterName
                                         code:ERROR_CODE_INIT_FAILED
                                     userInfo:@{NSLocalizedDescriptionKey:errorMessage}];
    LogAdapterDelegate_Internal(@"error = %@", error);
    
    // handle rewarded video
    NSArray *rewardedVideoLocationIDs = rewardedVideoLocationIdToSmashDelegate.allKeys;

    for (NSString *locationId in rewardedVideoLocationIDs) {
        id<ISRewardedVideoAdapterDelegate> delegate = [rewardedVideoLocationIdToSmashDelegate objectForKey:locationId];
        
        if ([rewardedVideoPlacementsForInitCallbacks containsObject:locationId]) {
            [delegate adapterRewardedVideoInitFailed:error];
        } else {
            [delegate adapterRewardedVideoHasChangedAvailability:NO];
        }
    }
    
    // handle interstitial
    NSArray *interstitialLocationIDs = interstitialLocationIdToSmashDelegate.allKeys;

    for (NSString *locationId in interstitialLocationIDs) {
        id<ISInterstitialAdapterDelegate> delegate = [interstitialLocationIdToSmashDelegate objectForKey:locationId];
        [delegate adapterInterstitialInitFailedWithError:error];
    }
    
    // handle banners
    NSArray *bannerLocationIDs = bannerLocationIdToSmashDelegate.allKeys;

    for (NSString *locationId in bannerLocationIDs) {
        id<ISBannerAdapterDelegate> delegate = [bannerLocationIdToSmashDelegate objectForKey:locationId];
        [delegate adapterBannerInitFailedWithError:error];
    }
}

#pragma mark - Helpers

- (NSString *) getLocationId:(ISAdapterConfig *)adapterConfig {
    NSString *locationId = adapterConfig.settings[kLocationId];
    
    if (!locationId || !locationId.length) {
        return CBLocationDefault;
    }
    
    return locationId;
}

- (BOOL) isBannerSizeSupported:(ISBannerSize *)size {
    if ([size.sizeDescription isEqualToString:@"BANNER"]     ||
        [size.sizeDescription isEqualToString:@"LARGE"]      ||
        [size.sizeDescription isEqualToString:@"RECTANGLE"]  ||
        [size.sizeDescription isEqualToString:@"SMART"]) {
        return YES;
    } else if ([size.sizeDescription isEqualToString:@"CUSTOM"]) {
        return (size.height >= 40 && size.height <= 60);
    }

    return NO;
}

- (CHBBannerSize) getBannerSize:(ISBannerSize *)size {
    LogAdapterApi_Internal(@"banner size = %@", size.sizeDescription);

    if ([size.sizeDescription isEqualToString:@"BANNER"] ||
        [size.sizeDescription isEqualToString:@"LARGE"]) {
        return CHBBannerSizeStandard;
    } else if ([size.sizeDescription isEqualToString:@"RECTANGLE"]) {
        return CHBBannerSizeMedium;
    } else if ([size.sizeDescription isEqualToString:@"SMART"]) {
        return (UI_USER_INTERFACE_IDIOM() == UIUserInterfaceIdiomPad) ? CHBBannerSizeLeaderboard : CHBBannerSizeStandard;
    } else if ([size.sizeDescription isEqualToString:@"CUSTOM"]) {
        if (size.height >= 40 && size.height <= 60) {
            return CHBBannerSizeStandard;
        }
    }
    
    return CGSizeZero;
}

- (CHBRewarded *) getRewardedAdForLocationId:(NSString *)locationId {
    // create rewarded video
    CHBRewarded *rewardedAd = [rewardedVideoLocationIdToAd objectForKey:locationId];

    if (!rewardedAd) {
        // create listener
        ISChartboostRewardedListener *listener = [rewardedVideoLocationIdToListener objectForKey:locationId];

        // create rewarded video
        rewardedAd = [[CHBRewarded alloc] initWithLocation:locationId
                                                  delegate:listener];
        
        LogAdapterApi_Internal(@"initializing Chartboost rewarded video with locationId = %@", locationId);

        // add to dictionaries
        [rewardedVideoLocationIdToAd setObject:rewardedAd
                                        forKey:locationId];
    }
    
    return rewardedAd;
}

- (CHBInterstitial *) getChartboostInterstitial:(NSString *)locationId {
    // create interstitial
    CHBInterstitial *interstitialAd = [interstitialLocationIdToAd objectForKey:locationId];
        
    if (!interstitialAd) {
        //create listener
        ISChartboostInterstitialListener *listener = [interstitialLocationIdToListener objectForKey:locationId];
            
        // create interstitial
        interstitialAd = [[CHBInterstitial alloc] initWithLocation:locationId mediation:[self getMediation] delegate:listener];

        LogAdapterApi_Internal(@"initializing Chartboost interstitial with locationId = %@", locationId);
        
        // add to dictionaries
        [interstitialLocationIdToAd setObject:interstitialAd
                                       forKey:locationId];
    }
        
    return interstitialAd;
}

- (void) createAndLoadBannerWithViewController:(nonnull UIViewController *)viewController
                                          size:(ISBannerSize *)size
                                    locationId:(NSString *)locationId {
    dispatch_async(dispatch_get_main_queue(), ^{
        //create listener
        ISChartboostBannerListener *listener = [bannerLocationIdToListener objectForKey:locationId];
        
        // get size
        CHBBannerSize chartboostSize = [self getBannerSize:size];
        
        // create banner
        CHBBanner *bannerAd = [[CHBBanner alloc] initWithSize:chartboostSize
                                                     location:locationId
                                                    mediation:[self getMediation]
                                                     delegate:listener];
        
        LogAdapterApi_Internal(@"initializing chartboost banner with locationId = %@", locationId);
        
        // add to dictionaries
        [bannerLocationIdToAd setObject:bannerAd
                                forKey:locationId];
        [bannerLocationIdToSize setObject:size
                                   forKey:locationId];
        [bannerLocationIdToViewController setObject:viewController
                                             forKey:locationId];
        
        // disable auto refresh
        [bannerAd setAutomaticallyRefreshesContent:NO];
        
        // load banner
        [bannerAd cache];
    });
}

- (void)releaseMemoryWithAdapterConfig:(nonnull ISAdapterConfig *)adapterConfig {
    NSString *locationId = [self getLocationId:adapterConfig];
    
    if ([rewardedVideoLocationIdToAd objectForKey:locationId]) {
        [rewardedVideoLocationIdToSmashDelegate removeObjectForKey:locationId];
        [rewardedVideoLocationIdToListener removeObjectForKey:locationId];
        [rewardedVideoLocationIdToAd removeObjectForKey:locationId];
    } else if ([interstitialLocationIdToAd objectForKey:locationId]) {
        [interstitialLocationIdToSmashDelegate removeObjectForKey:locationId];
        [interstitialLocationIdToListener removeObjectForKey:locationId];
        [interstitialLocationIdToAd removeObjectForKey:locationId];
    } else if ([bannerLocationIdToAd objectForKey:locationId]) {
        [bannerLocationIdToSmashDelegate removeObjectForKey:locationId];
        [bannerLocationIdToListener removeObjectForKey:locationId];
        [bannerLocationIdToAd removeObjectForKey:locationId];
        [bannerLocationIdToViewController removeObjectForKey:locationId];
        [bannerLocationIdToSize removeObjectForKey:locationId];
    }
}

- (CHBMediation *) getMediation {
  return [[CHBMediation alloc] initWithType:CBMediationSupersonic
                             libraryVersion:MEDIATION_VERSION
                             adapterVersion:kAdapterVersion];
}

- (void) setCCPAValue:(BOOL)value {
    LogAdapterApi_Internal(@"value = %@", value? @"YES" : @"NO");
    [Chartboost addDataUseConsent:[CHBCCPADataUseConsent ccpaConsent:(value ? CHBCCPAConsentOptOutSale : CHBCCPAConsentOptInSale)]];
}

- (void) setMetaDataWithKey:(NSString *)key
                  andValues:(NSMutableArray *)values {
    if (values.count == 0) {
        return;
    }
    
    NSString *value = values[0];
    LogAdapterApi_Internal(@"key = %@, value = %@", key, value);
    
    if ([ISMetaDataUtils isValidCCPAMetaDataWithKey:key
                                           andValue:value]) {
        [self setCCPAValue:[ISMetaDataUtils getCCPABooleanValue:value]];
    }
}

@end
