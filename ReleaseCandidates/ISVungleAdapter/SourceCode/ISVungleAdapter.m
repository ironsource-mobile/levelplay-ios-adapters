//
//  ISVungleAdapter.m
//  ISVungleAdapter
//
//  Created by Amit Goldhecht on 8/20/14.
//  Copyright (c) 2014 IronSource. All rights reserved.
//
#import "ISVungleAdapterSingleton.h"
#import "ISVungleAdapter.h"
#import <VungleSDK.h>
#import <VungleSDKHeaderBidding.h>

typedef NS_ENUM(NSInteger, InitState) {
    NO_INIT,
    INIT_IN_PROGRESS,
    INIT_SUCCESS,
    INIT_FAILED
};

static NSString * const kAdapterName            = @"Vungle";
static NSString * const kAdapterVersion         = VungleAdapterVersion;
static NSString * const kAppID                  = @"AppID";
static NSString * const kPlacementID            = @"PlacementId";
static NSString * const kOrientationFlag        = @"vungle_adorientation";
static NSString * const kPortraitOrientation    = @"PORTRAIT";
static NSString * const kLandscapeOrientation   = @"LANDSCAPE";
static NSString * const kAutoRotateOrientation  = @"AUTO_ROTATE";
static NSString * const kLWSSupportedState      = @"isSupportedLWSByInstance";

//static NSInteger const kVungleAdSizeRectangle = 5000;
static NSInteger const kShowErrorNotCached = 6000;
//static NSInteger const kSdkInitErrorCode  = 6001;

static NSNumber * uiOrientation = nil;
static NSString * adOrientation = nil;


static InitState initState = NO_INIT;
static ConcurrentMutableSet<ISNetworkInitCallbackProtocol> *initCallbackDelegates = nil;

typedef NS_ENUM(NSUInteger, BANNER_STATE) {
    UNKNOWN,
    REQUESTING,
    REQUESTING_RELOAD,
    SHOWING
};

@interface ISVungleAdapter() < VungleDelegate, ISNetworkInitCallbackProtocol, InitiatorDelegate>
{
    // Rewarded video
    ConcurrentMutableDictionary *rewardedVideoPlacementToSmashDelegate;
    ConcurrentMutableDictionary *rewardedVideoPlacementToServerData;
    ConcurrentMutableDictionary *rewardedVideoServerDataToDelegate;
    ConcurrentMutableSet        *rewardedVideoProgrammaticPlacementIds;
    
    // Interstitial
    ConcurrentMutableDictionary *interstitialPlacementToSmashDelegate;
    ConcurrentMutableDictionary *interstitialPlacementToServerData;
    ConcurrentMutableDictionary *interstitialServerDataToDelegate;

    // Banner
    ConcurrentMutableDictionary *bannerPlacementToSmashDelegate;
    ConcurrentMutableDictionary *bannerPlacementToSize;
    ConcurrentMutableDictionary *bannerPlacementToViewController;
    ConcurrentMutableDictionary *bannerPlacementToBannerState;
    ConcurrentMutableDictionary *bannerPlacementToServerData;
    ConcurrentMutableDictionary *bannerServerDataToDelegate;

}

@end

@implementation ISVungleAdapter

#pragma mark - Initialization Methods

- (instancetype)initAdapter:(NSString *)name {
    self = [super initAdapter:name];
    
    if (self) {
        if (initCallbackDelegates == nil) {
            initCallbackDelegates = [ConcurrentMutableSet<ISNetworkInitCallbackProtocol> set];
        }
        
        // Rewarded video
        rewardedVideoPlacementToSmashDelegate   = [ConcurrentMutableDictionary dictionary];
        rewardedVideoPlacementToServerData      = [ConcurrentMutableDictionary dictionary];
        rewardedVideoServerDataToDelegate       = [ConcurrentMutableDictionary dictionary];
        rewardedVideoProgrammaticPlacementIds   = [ConcurrentMutableSet set];
        
        // Interstitial
        interstitialPlacementToSmashDelegate    = [ConcurrentMutableDictionary dictionary];
        interstitialPlacementToServerData       = [ConcurrentMutableDictionary dictionary];
        interstitialServerDataToDelegate        = [ConcurrentMutableDictionary dictionary];
        
        // Banner
        bannerPlacementToSmashDelegate          = [ConcurrentMutableDictionary dictionary];
        bannerPlacementToSize                   = [ConcurrentMutableDictionary dictionary];
        bannerPlacementToViewController         = [ConcurrentMutableDictionary dictionary];
        bannerPlacementToBannerState            = [ConcurrentMutableDictionary dictionary];
        bannerPlacementToServerData             = [ConcurrentMutableDictionary dictionary];
        bannerServerDataToDelegate              = [ConcurrentMutableDictionary dictionary];
    }
    
    return self;
}

#pragma mark - IronSource Protocol Methods

- (NSString *)sdkVersion {
    return VungleSDKVersion;
}

- (NSString *)version {
    return kAdapterVersion;
}

- (NSArray *)systemFrameworks {
    return @[@"AdSupport", @"AudioToolbox", @"AVFoundation", @"CFNetwork", @"CoreGraphics", @"CoreMedia", @"Foundation", @"MediaPlayer", @"QuartzCore", @"StoreKit", @"SystemConfiguration", @"UIKit", @"WebKit"];
}

- (NSString *)sdkName {
    return @"VungleSDK";
}

- (void)setConsent:(BOOL)consent {
    LogAdapterApi_Internal(@"consent = %@", consent ? @"YES" : @"NO");
    [[VungleSDK sharedSDK] updateConsentStatus:(consent? VungleConsentAccepted : VungleConsentDenied)
                         consentMessageVersion:@""];
}

- (void) setCCPAValue:(BOOL)value {
    // The Vungle CCPA API expects an indication if the user opts in to targeted advertising.
    // Given that this is opposite to the ironSource Mediation CCPA flag of do_not_sell
    // we will use the opposite value of what is passed to this method
    BOOL optIn = !value;
    VungleCCPAStatus status = optIn ? VungleCCPAAccepted : VungleCCPADenied;
    LogAdapterApi_Internal(@"key = VungleCCPAStatus, value  = %@", optIn ? @"VungleCCPAAccepted" : @"VungleCCPADenied");
    [[VungleSDK sharedSDK] updateCCPAStatus:status];
}

- (void)setMetaDataWithKey:(NSString *)key
                 andValues:(NSMutableArray *) values {
    if (values.count == 0) {
        return;
    }
    
    NSString *value = values[0];
    LogAdapterApi_Internal(@"setMetaData: key=%@, value=%@", key, value);
    
    if ([ISMetaDataUtils isValidCCPAMetaDataWithKey:key andValue:value]) {
        [self setCCPAValue:[ISMetaDataUtils getCCPABooleanValue:value]];
    } else if ([[key lowercaseString] isEqual:kOrientationFlag]) {
        adOrientation = value;
    }
}

#pragma mark - Rewarded Video

- (NSDictionary *)getRewardedVideoBiddingDataWithAdapterConfig:(ISAdapterConfig *)adapterConfig {
    return [self getBiddingDataWithAdapterConfig:adapterConfig];
}

- (void)initRewardedVideoForCallbacksWithUserId:(NSString *)userId
                                  adapterConfig:(ISAdapterConfig *)adapterConfig
                                       delegate:(id<ISRewardedVideoAdapterDelegate>)delegate {
    NSString *appId = adapterConfig.settings[kAppID];
    NSString *placementId = adapterConfig.settings[kPlacementID];

    // check appId
    if (![self isConfigValueValid:appId]) {
        NSError *error = [self errorForMissingCredentialFieldWithName:kAppID];
        LogInternal_Error(@"error = %@", error);
        [delegate adapterRewardedVideoInitFailed:error];
        return;
    }
    
    // check placementId
    if (![self isConfigValueValid:placementId]) {
        NSError *error = [self errorForMissingCredentialFieldWithName:kPlacementID];
        LogInternal_Error(@"error = %@", error);
        [delegate adapterRewardedVideoInitFailed:error];
        return;
    }
    
    LogInternal_Internal(@"appId = %@, placementId = %@", appId, placementId);
    
    // add delegate to dictionary
    [rewardedVideoPlacementToSmashDelegate setObject:delegate
                                              forKey:placementId];
   
    [rewardedVideoProgrammaticPlacementIds addObject:placementId];
    
    // init sdk
    [self initSDK:appId
         isBidder:adapterConfig.isBidder];

    // check init state and if already initiated call delegate
    if (initState == INIT_SUCCESS) {
        [delegate adapterRewardedVideoInitSuccess];
    } else if (initState == INIT_FAILED) {
        NSError *error = [NSError errorWithDomain:kAdapterName
                                             code:ERROR_CODE_INIT_FAILED
                                         userInfo:@{NSLocalizedDescriptionKey:@"init error"}];
        LogAdapterApi_Internal(@"error.description = %@", error.description);
        [delegate adapterRewardedVideoInitFailed:error];
    }
}

- (void)initAndLoadRewardedVideoWithUserId:(NSString *)userId
                             adapterConfig:(ISAdapterConfig *)adapterConfig
                                  delegate:(id<ISRewardedVideoAdapterDelegate>)delegate {
    NSString *appId = adapterConfig.settings[kAppID];
    NSString *placementId = adapterConfig.settings[kPlacementID];

    // check appId
    if (![self isConfigValueValid:appId]) {
        NSError *error = [self errorForMissingCredentialFieldWithName:kAppID];
        LogAdapterApi_Internal(@"error = %@", error);
        [delegate adapterRewardedVideoHasChangedAvailability:NO];
        return;
    }
    
    // check placementId
    if (![self isConfigValueValid:placementId]) {
        NSError *error = [self errorForMissingCredentialFieldWithName:kPlacementID];
        LogAdapterApi_Internal(@"error = %@", error);
        [delegate adapterRewardedVideoHasChangedAvailability:NO];
        return;
    }
    
    LogInternal_Internal(@"appId = %@, placementId = %@", appId, placementId);
    
    // add delegate to dictionary
    [rewardedVideoPlacementToSmashDelegate setObject:delegate
                                              forKey:placementId];
    
    // add rewarded video to singleton
    [[ISVungleAdapterSingleton sharedInstance] addRewardedVideoDelegate:self
                                                         forKey:placementId];
    
    // init sdk
    [self initSDK:appId
         isBidder:adapterConfig.isBidder];

    // check init state and if already initiated call delegate
    if (initState == INIT_SUCCESS) {
        [self loadRewardedVideoInternalWithPlacement:placementId];
    } else if (initState == INIT_FAILED) {
        [delegate adapterRewardedVideoHasChangedAvailability:NO];
    }
}

- (void)loadRewardedVideoForBiddingWithAdapterConfig:(ISAdapterConfig *)adapterConfig
                                          serverData:(NSString *)serverData
                                            delegate:(id<ISRewardedVideoAdapterDelegate>)delegate {
    NSString *placementId = adapterConfig.settings[kPlacementID];
    
    // saving server data to dictionary for the loading proccess
    [rewardedVideoPlacementToServerData setObject:serverData
                                           forKey:placementId];
    
    // saving delegate to dictionary for the lws flow (vungle api limitation only for bidding)
    [rewardedVideoServerDataToDelegate setObject:delegate
                                          forKey:serverData];
    
    // add rewarded video to singleton - used here instead of Init callback for LWS only (supported only on bidding flow)
    [[ISVungleAdapterSingleton sharedInstance] addRewardedVideoDelegate:self
                                                         forKey:serverData];
    
    // load rv
    [self loadRewardedVideoInternalWithPlacement:placementId];
}

- (void)fetchRewardedVideoForAutomaticLoadWithAdapterConfig:(ISAdapterConfig *)adapterConfig
                                                   delegate:(id<ISRewardedVideoAdapterDelegate>)delegate {
    NSString *placementId = adapterConfig.settings[kPlacementID];
    
    // load rv
    [self loadRewardedVideoInternalWithPlacement:placementId];
}

- (void)loadRewardedVideoInternalWithPlacement:(NSString *)placementId {
    if (![rewardedVideoPlacementToSmashDelegate objectForKey:placementId]) {
        LogAdapterApi_Internal(@"unknown placementId");
        return;
    }
    
    LogAdapterApi_Internal(@"placementId = %@", placementId);

    id<ISRewardedVideoAdapterDelegate> delegate = [rewardedVideoPlacementToSmashDelegate objectForKey:placementId];
    NSString *serverData = [rewardedVideoPlacementToServerData objectForKey:placementId];
    BOOL loadAttemptSucceeded = YES;
    NSError *error = nil;
    
    if (serverData != nil) {
        LogInternal_Internal(@"serverData = %@", serverData);
        loadAttemptSucceeded = [[VungleSDK sharedSDK] loadPlacementWithID:placementId
                                                                 adMarkup:serverData
                                                                    error:&error];
    } else {
        loadAttemptSucceeded = [[VungleSDK sharedSDK] loadPlacementWithID:placementId
                                                                    error:&error];
    }
    
    if (!loadAttemptSucceeded) {
        LogAdapterApi_Internal(@"error = %@", error);
        [delegate adapterRewardedVideoHasChangedAvailability:NO];
        
        if (error != nil) {
            [delegate adapterRewardedVideoDidFailToLoadWithError:error];
        }
    }
}

- (BOOL)hasRewardedVideoWithAdapterConfig:(ISAdapterConfig *)adapterConfig {
    NSString *placementId = adapterConfig.settings[kPlacementID];
    LogAdapterApi_Internal(@"placementId = %@", placementId);

    // Vungle cache ads that were loaded in the last week.
    // This means that [[VungleSDK sharedSDK] isAdCachedForPlacementID:] could return YES for placements that we didn't try to load during this session.
    // This is the reason we also check if the placementId is contained in the ConcurrentMutableDictionary
    if (![rewardedVideoPlacementToSmashDelegate hasObjectForKey:placementId]) {
        return NO;
    }
    
    if (adapterConfig.isBidder) {
        NSString *serverData = [rewardedVideoPlacementToServerData objectForKey:placementId];
        return [[VungleSDK sharedSDK] isAdCachedForPlacementID:placementId
                                                      adMarkup:serverData];
    }
    
    return [[VungleSDK sharedSDK] isAdCachedForPlacementID:placementId];
}

- (void)showRewardedVideoWithViewController:(UIViewController *)viewController
                              adapterConfig:(ISAdapterConfig *)adapterConfig
                                   delegate:(id<ISRewardedVideoAdapterDelegate>)delegate {
    NSString *placementId = adapterConfig.settings[kPlacementID];
    LogAdapterApi_Internal(@"placementId = %@", placementId);
    
    [delegate adapterRewardedVideoHasChangedAvailability:NO];
    
    if (![self isAdCachedForPlacement:placementId]) {
        NSError *error = [NSError errorWithDomain:@"ISVungleAdapter"
                                             code:kShowErrorNotCached
                                         userInfo:@{NSLocalizedDescriptionKey : @"Show error. ad not cached"}];
        LogAdapterApi_Internal(@"error = %@", error);
        [delegate adapterRewardedVideoDidFailToShowWithError:error];
        return;
    }
    
    dispatch_async(dispatch_get_main_queue(), ^{
        NSDictionary *options = [self createAdOptionsWithDynamicUserID:YES];
        NSString *serverData = [rewardedVideoPlacementToServerData objectForKey:placementId];
        BOOL showAttemptSucceeded = YES;
        NSError *error;
        
        if (serverData != nil) {
            LogInternal_Internal(@"serverData = %@", serverData);
            showAttemptSucceeded = [[VungleSDK sharedSDK] playAd:viewController
                                                         options:options
                                                     placementID:placementId
                                                        adMarkup:serverData
                                                           error:&error];
        } else {
            showAttemptSucceeded = [[VungleSDK sharedSDK] playAd:viewController
                                                         options:options
                                                     placementID:placementId
                                                           error:&error];
        }
        
        if (!showAttemptSucceeded) {
            LogAdapterApi_Internal(@"error = %@", error);
            [delegate adapterRewardedVideoDidFailToShowWithError:error];
        }
    });
}

#pragma mark - Interstitial

- (NSDictionary *)getInterstitialBiddingDataWithAdapterConfig:(ISAdapterConfig *)adapterConfig {
    return [self getBiddingDataWithAdapterConfig:adapterConfig];
}

- (void)initInterstitialForBiddingWithUserId:(NSString *)userId
                               adapterConfig:(ISAdapterConfig *)adapterConfig
                                    delegate:(id<ISInterstitialAdapterDelegate>)delegate {
    LogInternal_Internal(@"");
    [self initInterstitialWithUserId:userId
                       adapterConfig:adapterConfig
                            delegate:delegate];
}

- (void)initInterstitialWithUserId:(NSString *)userId
                     adapterConfig:(ISAdapterConfig *)adapterConfig
                          delegate:(id<ISInterstitialAdapterDelegate>)delegate {
    NSString *appId = adapterConfig.settings[kAppID];
    NSString *placementId = adapterConfig.settings[kPlacementID];

    // check appId
    if (![self isConfigValueValid:appId]) {
        NSError *error = [self errorForMissingCredentialFieldWithName:kAppID];
        LogAdapterApi_Internal(@"error = %@", error);
        [delegate adapterInterstitialInitFailedWithError:error];
        return;
    }
    
    // check placementId
    if (![self isConfigValueValid:placementId]) {
        NSError *error = [self errorForMissingCredentialFieldWithName:kPlacementID];
        LogAdapterApi_Internal(@"error = %@", error);
        [delegate adapterInterstitialInitFailedWithError:error];
        return;
    }
    
    LogInternal_Internal(@"appId = %@, placementId = %@", appId, placementId);

    // add interstitial to singleton
    [[ISVungleAdapterSingleton sharedInstance] addInterstitialDelegate:self
                                                        forPlacementID:placementId];
    
    // add delegate to dictionary
    [interstitialPlacementToSmashDelegate setObject:delegate
                                             forKey:placementId];
    
    // init sdk
    [self initSDK:appId
         isBidder:adapterConfig.isBidder];
    
    // check init state and if already initiated call delegate
    if (initState == INIT_SUCCESS) {
        [delegate adapterInterstitialInitSuccess];
    } else if (initState == INIT_FAILED) {
        NSError *error = [NSError errorWithDomain:@"ISVungleAdapter"
                                             code:ERROR_CODE_INIT_FAILED
                                         userInfo:@{NSLocalizedDescriptionKey : @"vungle sdk initialization failed"}];
        LogAdapterApi_Internal(@"error = %@", error);
        [delegate adapterInterstitialInitFailedWithError:error];
    }
}

- (void)loadInterstitialForBiddingWithServerData:(NSString *)serverData
                                   adapterConfig:(ISAdapterConfig *)adapterConfig
                                        delegate:(id<ISInterstitialAdapterDelegate>)delegate {
    NSString *placementId = adapterConfig.settings[kPlacementID];
    
    // saving server data to dictionary for the loading proccess
    [interstitialPlacementToServerData setObject:serverData
                                          forKey:adapterConfig.settings[kPlacementID]];

    // saving delegate to dictionary for the lws flow (vungle api limitation only for bidding)
    [interstitialServerDataToDelegate setObject:delegate
                                         forKey:serverData];
    
    // load is
    [self loadInterstitialInternalWithPlacement:placementId];
}

- (void)loadInterstitialWithAdapterConfig:(ISAdapterConfig *)adapterConfig
                                 delegate:(id<ISInterstitialAdapterDelegate>)delegate {
    NSString *placementId = adapterConfig.settings[kPlacementID];
    
    // load is
    [self loadInterstitialInternalWithPlacement:placementId];
}

- (void)loadInterstitialInternalWithPlacement:(NSString *)placementId {
    LogAdapterApi_Internal(@"placementID = %@", placementId);
    
    if (![interstitialPlacementToSmashDelegate objectForKey:placementId]) {
        LogAdapterApi_Internal(@"unknown placementID");
        return;
    }
    
    id<ISInterstitialAdapterDelegate> delegate = [interstitialPlacementToSmashDelegate objectForKey:placementId];
    NSString *serverData = [interstitialPlacementToServerData objectForKey:placementId];
    BOOL loadAttemptSucceeded = YES;
    NSError *error;
    
    if (serverData != nil) {
        loadAttemptSucceeded = [[VungleSDK sharedSDK] loadPlacementWithID:placementId
                                                                 adMarkup:serverData
                                                                    error:&error];
    } else {
        loadAttemptSucceeded = [[VungleSDK sharedSDK] loadPlacementWithID:placementId
                                                                    error:&error];
    }
    
    if (!loadAttemptSucceeded) {
        LogAdapterApi_Internal(@"error = %@", error);
        [delegate adapterInterstitialDidFailToLoadWithError:error];
    }
}

- (BOOL)hasInterstitialWithAdapterConfig:(ISAdapterConfig *)adapterConfig {
    NSString *placementId = adapterConfig.settings[kPlacementID];
    LogAdapterApi_Internal(@"placementId = %@", placementId);

    // Vungle cache ads that were loaded in the last week.
    // This means that [[VungleSDK sharedSDK] isAdCachedForPlacementID:] could return YES for placements that we didn't try to load during this session.
    // This is the reason we also check if the placementId is contained in the ConcurrentMutableDictionary
    if (![interstitialPlacementToSmashDelegate hasObjectForKey:placementId]) {
        return NO;
    }
    
    if (adapterConfig.isBidder) {
        NSString *serverData = [interstitialPlacementToServerData objectForKey:placementId];
        return [[VungleSDK sharedSDK] isAdCachedForPlacementID:placementId
                                                      adMarkup:serverData];
    }
    
    return [[VungleSDK sharedSDK] isAdCachedForPlacementID:placementId];
}

- (void)showInterstitialWithViewController:(UIViewController *)viewController
                             adapterConfig:(ISAdapterConfig *)adapterConfig
                                  delegate:(id<ISInterstitialAdapterDelegate>)delegate {
    NSString *placementId = adapterConfig.settings[kPlacementID];
    LogAdapterApi_Internal(@"placementId = %@", placementId);
    
    if (![self isAdCachedForPlacement:placementId]) {
        NSError *error = [NSError errorWithDomain:@"ISVungleAdapter"
                                             code:kShowErrorNotCached
                                         userInfo:@{NSLocalizedDescriptionKey : @"Show error. ad not cached"}];
        LogAdapterApi_Internal(@"error = %@", error);
        [delegate adapterInterstitialDidFailToShowWithError:error];
        return;
    }
    
    dispatch_async(dispatch_get_main_queue(), ^{
        NSDictionary *options = [self createAdOptionsWithDynamicUserID:NO];
        NSString *serverData = [interstitialPlacementToServerData objectForKey:placementId];
        BOOL showAttemptSucceeded = YES;
        NSError *error;
        
        if (serverData != nil) {
            showAttemptSucceeded = [[VungleSDK sharedSDK] playAd:viewController
                                                         options:options
                                                     placementID:placementId
                                                        adMarkup:serverData
                                                           error:&error];
        } else {
            showAttemptSucceeded = [[VungleSDK sharedSDK] playAd:viewController
                                                         options:options
                                                     placementID:placementId
                                                           error:&error];
        }
        
        if (!showAttemptSucceeded) {
            LogAdapterApi_Internal(@"error = %@", error);
            [delegate adapterInterstitialDidFailToShowWithError:error];
        }
    });
}

#pragma mark - Banner API

- (NSDictionary *)getBannerBiddingDataWithAdapterConfig:(ISAdapterConfig *)adapterConfig {
    return [self getBiddingDataWithAdapterConfig:adapterConfig];
}

- (void)initBannerForBiddingWithUserId:(NSString *)userId
                         adapterConfig:(ISAdapterConfig *)adapterConfig
                              delegate:(id<ISBannerAdapterDelegate>)delegate {
    LogAdapterApi_Internal(@"");
    [self initBannersInternal:userId
                adapterConfig:adapterConfig
                     delegate:delegate];
}

- (void)initBannerWithUserId:(nonnull NSString *)userId
               adapterConfig:(nonnull ISAdapterConfig *)adapterConfig
                    delegate:(nonnull id<ISBannerAdapterDelegate>)delegate {
    LogAdapterApi_Internal(@"");
    [self initBannersInternal:userId
                adapterConfig:adapterConfig
                     delegate:delegate];
}

- (void)initBannersInternal:(NSString *)userId
              adapterConfig:(ISAdapterConfig *)adapterConfig
                   delegate:(id<ISBannerAdapterDelegate>)delegate {
    
    NSString *appId = adapterConfig.settings[kAppID];
    NSString *placementId = adapterConfig.settings[kPlacementID];

    // check appId
    if (![self isConfigValueValid:appId]) {
        NSError *error = [self errorForMissingCredentialFieldWithName:kAppID];
        LogAdapterApi_Internal(@"error = %@", error);
        [delegate adapterBannerInitFailedWithError:error];
        return;
    }
    
    // check placementId
    if (![self isConfigValueValid:placementId]) {
        NSError *error = [self errorForMissingCredentialFieldWithName:kPlacementID];
        LogAdapterApi_Internal(@"error = %@", error);
        [delegate adapterBannerInitFailedWithError:error];
        return;
    }
    
    LogInternal_Internal(@"appId = %@, placementId = %@", appId, placementId);

    // disable banner refresh
    [[VungleSDK sharedSDK] disableBannerRefresh];
       
    // add banner to singleton
    [[ISVungleAdapterSingleton sharedInstance] addBannerDelegate:self
                                                  forPlacementID:placementId];

    // add delegate to dictionary
    [bannerPlacementToSmashDelegate setObject:delegate
                                       forKey:placementId];
    
    // init sdk
    [self initSDK:appId
         isBidder:adapterConfig.isBidder];
    
    // check init state and if already initiated call delegate
    if (initState == INIT_SUCCESS) {
        [delegate adapterBannerInitSuccess];
    } else if (initState == INIT_FAILED) {
        NSError *error = [NSError errorWithDomain:@"ISVungleAdapter"
                                             code:ERROR_CODE_INIT_FAILED
                                         userInfo:@{NSLocalizedDescriptionKey : @"vungle sdk initialization failed"}];
        LogAdapterApi_Internal(@"error = %@", error);
        [delegate adapterBannerInitFailedWithError:error];
    }
}

- (void)loadBannerForBiddingWithServerData:(NSString *)serverData
                            viewController:(UIViewController *)viewController
                                      size:(ISBannerSize *)size
                             adapterConfig:(ISAdapterConfig *)adapterConfig
                                  delegate:(id<ISBannerAdapterDelegate>)delegate {
    NSString *placementId = adapterConfig.settings[kPlacementID];
    
    // saving server data to dictionary for the loading proccess
    [bannerPlacementToServerData setObject:serverData
                                    forKey:placementId];

    // saving delegate to dictionary for the lws flow (vungle api limitation only for bidding)
    [bannerServerDataToDelegate setObject:delegate
                                   forKey:serverData];
    
    // load bn
    [self loadBannerInternalWithServerData:serverData
                            viewController:viewController
                                      size:size
                             adapterConfig:adapterConfig
                                  delegate:delegate];
}

- (void)loadBannerWithViewController:(nonnull UIViewController *)viewController
                                size:(ISBannerSize *)size
                       adapterConfig:(nonnull ISAdapterConfig *)adapterConfig
                            delegate:(nonnull id <ISBannerAdapterDelegate>)delegate {
    // load bn
    [self loadBannerInternalWithServerData:nil
                            viewController:viewController
                                      size:size
                             adapterConfig:adapterConfig
                                  delegate:delegate];
}

- (void)loadBannerInternalWithServerData:(NSString *)serverData
                          viewController:(UIViewController *)viewController
                                    size:(ISBannerSize *)size
                           adapterConfig:(ISAdapterConfig *)adapterConfig
                                delegate:(id <ISBannerAdapterDelegate>)delegate {
    NSString *placementId = adapterConfig.settings[kPlacementID];
    
    // check placementId
    if (![self isConfigValueValid:placementId]) {
        NSError *error = [self errorForMissingCredentialFieldWithName:kPlacementID];
        LogAdapterApi_Internal(@"error = %@", error);
        [delegate adapterBannerDidFailToLoadWithError:error];
        return;
    }
    
    // verify size
    if (![self isBannerSizeSupported:size]) {
        NSError *error = [ISError createError:ERROR_BN_UNSUPPORTED_SIZE
                                  withMessage:[NSString stringWithFormat:@"Vungle unsupported banner size - %@", size.sizeDescription]];
        LogAdapterApi_Internal(@"error = %@", error);
        [delegate adapterBannerDidFailToLoadWithError:error];
        return;
    }
    
    LogAdapterApi_Internal(@"placementId = %@, size = %@", placementId, size.sizeDescription);
    
    // get current state
    BANNER_STATE currentBannerState = [self getCurrentBannerState:placementId];
    LogAdapterApi_Internal(@"currentBannerState = %@", [self getBannerStateString:currentBannerState]);
    
    if (currentBannerState == SHOWING) {
        // add banner state to dictionary - REQUESTING_RELOAD
        [bannerPlacementToBannerState setObject:[self getBannerStateObject:REQUESTING_RELOAD]
                                         forKey:placementId];
    
        // finish ad
        if (adapterConfig.isBidder) {
            [[VungleSDK sharedSDK] finishDisplayingAd:placementId
                                             adMarkup:serverData];
        } else {
            [[VungleSDK sharedSDK] finishDisplayingAd:placementId];
        }
    } else {
        // load banner
        [self loadBannerWithPlacement:placementId
                       viewController:viewController
                                 size:size];
    }
}

- (void)loadBannerWithPlacement:(NSString *)placementId viewController:(nonnull UIViewController *)viewController size:(ISBannerSize *)size {
    LogAdapterApi_Internal(@"placementID = %@", placementId);
   
    // add size to dictionary
    [bannerPlacementToSize setObject:size forKey:placementId];

    // add view controller to dictionary
    [bannerPlacementToViewController setObject:viewController
                                        forKey:placementId];

    // add banner state to dictionary - REQUESTING
    [bannerPlacementToBannerState setObject:[self getBannerStateObject:REQUESTING]
                                     forKey:placementId];
    
    NSString *serverData = [bannerPlacementToServerData objectForKey:placementId];
    BOOL loadAttemptSucceeded = YES;
    NSError *error;
    
    // load is different for rectangle & banners
    if ([size.sizeDescription isEqualToString:@"RECTANGLE"]) {
        // rectangle load
        if (serverData != nil) {
            loadAttemptSucceeded = [[VungleSDK sharedSDK] loadPlacementWithID:placementId
                                                                     adMarkup:serverData
                                                                        error:&error];
        } else {
            loadAttemptSucceeded = [[VungleSDK sharedSDK] loadPlacementWithID:placementId
                                                                        error:&error];
        }
    } else {
        // get size
        VungleAdSize vungleBannerSize = [self getBannerSize:size];
        
        // banner load
        if (serverData != nil) {
            loadAttemptSucceeded = [[VungleSDK sharedSDK] loadPlacementWithID:placementId
                                                                     adMarkup:serverData
                                                                     withSize:vungleBannerSize
                                                                        error:&error];
        } else {
            loadAttemptSucceeded = [[VungleSDK sharedSDK] loadPlacementWithID:placementId
                                                                     withSize:vungleBannerSize
                                                                        error:&error];
        }
    }
    
    if (!loadAttemptSucceeded) {
        LogAdapterApi_Internal(@"error = %@", error);
        [[bannerPlacementToSmashDelegate objectForKey:placementId] adapterBannerDidFailToLoadWithError:error];
    }
}

- (void)reloadBannerWithAdapterConfig:(nonnull ISAdapterConfig *)adapterConfig
                             delegate:(nonnull id <ISBannerAdapterDelegate>)delegate {
    NSString *placementId = adapterConfig.settings[kPlacementID];
    LogAdapterApi_Internal(@"placementId = %@", placementId);
    
    // get size
    ISBannerSize *size = [bannerPlacementToSize objectForKey:placementId];
    
    // get view controller
    UIViewController *viewController = [bannerPlacementToViewController objectForKey:placementId];
    
    if (size && viewController) {
        // call load
        NSString *serverData = [bannerPlacementToServerData objectForKey:placementId];
        [self loadBannerInternalWithServerData:serverData
                                viewController:viewController
                                          size:size
                                 adapterConfig:adapterConfig
                                      delegate:delegate];
    } else {
        NSError *error = [ISError createError:ERROR_BN_LOAD_EXCEPTION
                                  withMessage:[NSString stringWithFormat:@"Vungle reload failed - no data for placementId = %@", placementId]];
        LogAdapterApi_Internal(@"error = %@", error);
        [delegate adapterBannerDidFailToLoadWithError:error];
    }
}

- (BOOL)shouldBindBannerViewOnReload {
    return YES;
}


- (void)releaseMemoryWithAdapterConfig:(nonnull ISAdapterConfig *)adapterConfig {
    // releasing memory currently only for banners
    NSString *placementId = adapterConfig.settings[kPlacementID];
    ISBannerSize *size = [bannerPlacementToSize objectForKey:placementId];
    
    if (size) {
        [self destroyBannerWithAdapterConfig:adapterConfig];
    }
}

- (void)destroyBannerWithAdapterConfig:(nonnull ISAdapterConfig *)adapterConfig {
    NSString *placementId = adapterConfig.settings[kPlacementID];
    NSString *serverData = [bannerPlacementToServerData objectForKey:placementId];
    
    // remove from dictionaries
    [bannerPlacementToSize removeObjectForKey:placementId];
    [bannerPlacementToViewController removeObjectForKey:placementId];
    [bannerPlacementToBannerState removeObjectForKey:placementId];
    
    LogAdapterApi_Internal(@"finishDisplayingAd placementId = %@", placementId);
    
    // call vungle finish
    if (serverData != nil) {
        [[VungleSDK sharedSDK] finishDisplayingAd:placementId
                                         adMarkup:serverData];
    } else {
        [[VungleSDK sharedSDK] finishDisplayingAd:placementId];
    }
}

#pragma mark - Vungle init Delegate

- (void)initSuccess {
    initState = INIT_SUCCESS;
    NSArray *initDelegatesList = initCallbackDelegates.allObjects;
    
    // call init callback delegate success
    for (id<ISNetworkInitCallbackProtocol> delegate in initDelegatesList) {
        [delegate onNetworkInitCallbackSuccess];
    }
    
    [initCallbackDelegates removeAllObjects];
}

- (void)initFailedWithError:(NSError *)error {
    initState = INIT_FAILED;
    NSArray *initDelegatesList = initCallbackDelegates.allObjects;
    
    // call init callback delegate fail
    for (id<ISNetworkInitCallbackProtocol> delegate in initDelegatesList) {
        [delegate onNetworkInitCallbackFailed:error.localizedDescription];
    }
    
    [initCallbackDelegates removeAllObjects];
}

- (void)onNetworkInitCallbackSuccess {
    LogAdapterDelegate_Internal(@"");
    
    // rewarded video
    NSArray *rewardedVideoPlacementIDs = rewardedVideoPlacementToSmashDelegate.allKeys;
    
    for (NSString *placementId in rewardedVideoPlacementIDs) {
        if ([rewardedVideoProgrammaticPlacementIds hasObject:placementId]) {
            [[rewardedVideoPlacementToSmashDelegate objectForKey:placementId] adapterRewardedVideoInitSuccess];
        } else {
            [self loadRewardedVideoInternalWithPlacement:placementId];
        }
    }
    
    // interstitial
    NSArray *interstitialPlacementIDs = interstitialPlacementToSmashDelegate.allKeys;
    
    for (NSString *placementId in interstitialPlacementIDs) {
        id<ISInterstitialAdapterDelegate> delegate = [interstitialPlacementToSmashDelegate objectForKey:placementId];
        [delegate adapterInterstitialInitSuccess];
    }
    
    // banner
    NSArray *bannerPlacementIDs = bannerPlacementToSmashDelegate.allKeys;
    
    for (NSString *placementId in bannerPlacementIDs) {
        id<ISBannerAdapterDelegate> delegate = [bannerPlacementToSmashDelegate objectForKey:placementId];
        [delegate adapterBannerInitSuccess];
    }
}

- (void)onNetworkInitCallbackFailed:(nonnull NSString *)errorMessage {
    NSError *error = [ISError createError:ERROR_CODE_INIT_FAILED withMessage:@"Vungle SDK init failed"];
    LogAdapterDelegate_Internal(@"error = %@", error);
    
    // rewarded video
    NSArray *rewardedVideoPlacementIDs = rewardedVideoPlacementToSmashDelegate.allKeys;
    
    for (NSString *placementId in rewardedVideoPlacementIDs) {
        if ([rewardedVideoProgrammaticPlacementIds hasObject:placementId]) {
            [[rewardedVideoPlacementToSmashDelegate objectForKey:placementId] adapterRewardedVideoInitFailed:error];
        } else {
            [[rewardedVideoPlacementToSmashDelegate objectForKey:placementId] adapterRewardedVideoHasChangedAvailability:NO];
        }
    }
    
    // interstitial
    NSArray *interstitialPlacementIDs = interstitialPlacementToSmashDelegate.allKeys;
    
    for (NSString *placementId in interstitialPlacementIDs) {
        id<ISInterstitialAdapterDelegate> delegate = [interstitialPlacementToSmashDelegate objectForKey:placementId];
        [delegate adapterInterstitialInitFailedWithError:error];
    }
    
    // banner
    NSArray *bannerPlacementIDs = bannerPlacementToSmashDelegate.allKeys;
    
    for (NSString *placementId in bannerPlacementIDs) {
        id<ISBannerAdapterDelegate> delegate = [bannerPlacementToSmashDelegate objectForKey:placementId];
        [delegate adapterBannerInitFailedWithError:error];
    }
}

#pragma mark - Vungle Rewarded Video Delegate

-(void)rewardedVideoPlayabilityUpdate:(BOOL)isAdPlayable placementID:(NSString *)placementID serverData:(NSString *)serverData error:(NSError *)error {
    LogAdapterDelegate_Internal(@"placementId = %@, isAdPlayable = %@, error = %@", placementID, isAdPlayable ? @"YES" : @"NO", error);
    LogInternal_Internal(@"serverData = %@", serverData);

    // get delegate
    id<ISRewardedVideoAdapterDelegate> rewardedVideoDelegate;
    if (serverData.length && [rewardedVideoServerDataToDelegate hasObjectForKey:serverData]) {
        rewardedVideoDelegate = [rewardedVideoServerDataToDelegate objectForKey:serverData];
    } else {
        rewardedVideoDelegate = [rewardedVideoPlacementToSmashDelegate objectForKey:placementID];
    }
    

    if (isAdPlayable && ![self isAdCachedForPlacement:placementID]) {
        // When isAdPlayable is YES the isAdCachedForPlacement should also return YES
        // If for some reason that is not the case we can also catch it on the Show method
        LogAdapterDelegate_Internal(@"Vungle Ad is playable but not ready to be shown");
    }
        
    // rewarded video
    if (rewardedVideoDelegate) {
        if (isAdPlayable) {
            [rewardedVideoDelegate adapterRewardedVideoHasChangedAvailability:YES];
        } else {
            [rewardedVideoDelegate adapterRewardedVideoHasChangedAvailability:NO];
            
            if (error != nil) {
                [rewardedVideoDelegate adapterRewardedVideoDidFailToLoadWithError:error];
            }
        }
    }
}

-(void)rewardedVideoAdViewedForPlacement:(NSString *)placementID serverData:(NSString *)serverData {
    LogAdapterDelegate_Internal(@"placementID = %@", placementID);
    LogInternal_Internal(@"serverData = %@", serverData);

    // get delegate
    id<ISRewardedVideoAdapterDelegate> rewardedVideoDelegate;
    if (serverData.length && [rewardedVideoServerDataToDelegate hasObjectForKey:serverData]) {
        rewardedVideoDelegate = [rewardedVideoServerDataToDelegate objectForKey:serverData];
    } else {
        rewardedVideoDelegate = [rewardedVideoPlacementToSmashDelegate objectForKey:placementID];
    }
    
    if (rewardedVideoDelegate) {
        [rewardedVideoDelegate adapterRewardedVideoDidOpen];
        [rewardedVideoDelegate adapterRewardedVideoDidStart];
    }

}

-(void)rewardedVideoDidCloseAdWithPlacementID:(NSString *)placementID
                                   serverData:(NSString *)serverData {
    LogAdapterDelegate_Internal(@"placementId = %@", placementID);
    LogInternal_Internal(@"serverData = %@", serverData);

    // get delegate
    id<ISRewardedVideoAdapterDelegate> rewardedVideoDelegate;
    if (serverData.length && [rewardedVideoServerDataToDelegate hasObjectForKey:serverData]) {
        rewardedVideoDelegate = [rewardedVideoServerDataToDelegate objectForKey:serverData];
    } else {
        rewardedVideoDelegate = [rewardedVideoPlacementToSmashDelegate objectForKey:placementID];
    }
    
    if (rewardedVideoDelegate) {
        [rewardedVideoDelegate adapterRewardedVideoDidEnd];
        [rewardedVideoDelegate adapterRewardedVideoDidClose];
    }
}

-(void)rewardedVideoDidClickForPlacementID:(NSString *)placementID
                                serverData:(NSString *)serverData {
    LogAdapterDelegate_Internal(@"placementId = %@", placementID);
    LogInternal_Internal(@"serverData = %@", serverData);

    // get delegate
    id<ISRewardedVideoAdapterDelegate> rewardedVideoDelegate;
    if (serverData.length && [rewardedVideoServerDataToDelegate hasObjectForKey:serverData]) {
        rewardedVideoDelegate = [rewardedVideoServerDataToDelegate objectForKey:serverData];
    } else {
        rewardedVideoDelegate = [rewardedVideoPlacementToSmashDelegate objectForKey:placementID];
    }
    
    if (rewardedVideoDelegate) {
        [rewardedVideoDelegate adapterRewardedVideoDidClick];
    }
}

-(void)rewardedVideoDidRewardedAdWithPlacementID:(NSString *)placementID
                                      serverData:(NSString *)serverData {
    LogAdapterDelegate_Internal(@"placementID = %@", placementID);
    LogInternal_Internal(@"serverData = %@", serverData);

    // get delegate
    id<ISRewardedVideoAdapterDelegate> rewardedVideoDelegate;
    if (serverData.length && [rewardedVideoServerDataToDelegate hasObjectForKey:serverData]) {
        rewardedVideoDelegate = [rewardedVideoServerDataToDelegate objectForKey:serverData];
    } else {
        rewardedVideoDelegate = [rewardedVideoPlacementToSmashDelegate objectForKey:placementID];
    }
    
    if (rewardedVideoDelegate) {
        [rewardedVideoDelegate adapterRewardedVideoDidReceiveReward];
    }
}

#pragma mark - Vungle Interstitial Delegate

-(void)interstitialPlayabilityUpdate:(BOOL)isAdPlayable
                         placementID:(NSString *)placementID
                          serverData:(NSString *)serverData
                               error:(NSError *)error {
    LogAdapterDelegate_Internal(@"placementId = %@, isAdPlayable = %@, error = %@", placementID, isAdPlayable ? @"YES" : @"NO", error);
    
    // get delegate
    id<ISInterstitialAdapterDelegate> interstitialDelegate;
    if (serverData.length && [interstitialServerDataToDelegate hasObjectForKey:serverData]) {
        interstitialDelegate = [interstitialServerDataToDelegate objectForKey:serverData];
    } else {
        interstitialDelegate = [interstitialPlacementToSmashDelegate objectForKey:placementID];
    }
    
    if (isAdPlayable && ![self isAdCachedForPlacement:placementID]) {
        // When isAdPlayable is YES the isAdCachedForPlacement should also return YES
        // If for some reason that is not the case we can also catch it on the Show method
        LogAdapterDelegate_Internal(@"Vungle Ad is playable but not ready to be shown");
    }
        
    if (interstitialDelegate) {
        if (isAdPlayable) {
            [interstitialDelegate adapterInterstitialDidLoad];
        } else {
            NSError *smashError;
            
            if (error != nil) {
                smashError = error;
            }
            else {
                smashError = [ISError createError:ERROR_CODE_GENERIC
                                      withMessage:[NSString stringWithFormat:@"Vungle interstitial load failed for placementId %@", placementID]];
            }
            
            [interstitialDelegate adapterInterstitialDidFailToLoadWithError:smashError];
        }
    }
}

-(void)interstitialVideoAdViewedForPlacement:(NSString *)placementID
                                  serverData:(NSString *)serverData {
    LogAdapterDelegate_Internal(@"placementID = %@", placementID);
    
    // get delegate
    id<ISInterstitialAdapterDelegate> interstitialDelegate;
    if (serverData.length && [interstitialServerDataToDelegate hasObjectForKey:serverData]) {
        interstitialDelegate = [interstitialServerDataToDelegate objectForKey:serverData];
    } else {
        interstitialDelegate = [interstitialPlacementToSmashDelegate objectForKey:placementID];
    }
    
    if (interstitialDelegate) {
        [interstitialDelegate adapterInterstitialDidOpen];
        [interstitialDelegate adapterInterstitialDidShow];
    }

}

-(void)interstitialDidCloseAdWithPlacementID:(NSString *)placementID
                                  serverData:(NSString *)serverData {
    LogAdapterDelegate_Internal(@"placementId = %@", placementID);
    
    // get delegate
    id<ISInterstitialAdapterDelegate> interstitialDelegate;
    if (serverData.length && [interstitialServerDataToDelegate hasObjectForKey:serverData]) {
        interstitialDelegate = [interstitialServerDataToDelegate objectForKey:serverData];
    } else {
        interstitialDelegate = [interstitialPlacementToSmashDelegate objectForKey:placementID];
    }
    
    if (interstitialDelegate) {
        [interstitialDelegate adapterInterstitialDidClose];
    }
}

-(void)interstitialDidClickForPlacementID:(NSString *)placementID
                               serverData:(NSString *)serverData {
    LogAdapterDelegate_Internal(@"placementId = %@", placementID);
    
    // get delegate
    id<ISInterstitialAdapterDelegate> interstitialDelegate;
    if (serverData.length && [interstitialServerDataToDelegate hasObjectForKey:serverData]) {
        interstitialDelegate = [interstitialServerDataToDelegate objectForKey:serverData];
    } else {
        interstitialDelegate = [interstitialPlacementToSmashDelegate objectForKey:placementID];
    }
    
    if (interstitialDelegate) {
        [interstitialDelegate adapterInterstitialDidClick];
    }
}

#pragma mark - Vungle Banner Delegate

-(void)bannerPlayabilityUpdate:(BOOL)isAdPlayable
                   placementID:(NSString *)placementID
                    serverData:(NSString *)serverData
                         error:(NSError *)error {
    LogAdapterDelegate_Internal(@"placementId = %@, isAdPlayable = %@, error = %@", placementID, isAdPlayable ? @"YES" : @"NO", error);
    
    // get delegate
    id<ISBannerAdapterDelegate> bannerDelegate;
    if (serverData.length && [bannerServerDataToDelegate hasObjectForKey:serverData]) {
        bannerDelegate = [bannerServerDataToDelegate objectForKey:serverData];
    } else {
        bannerDelegate = [bannerPlacementToSmashDelegate objectForKey:placementID];
    }
    
    if (bannerDelegate) {
        // if we are in a requesting state we handle the update, otherwise we ignore
        BANNER_STATE currentBannerState = [self getCurrentBannerState:placementID];
        LogAdapterDelegate_Internal(@"currentBannerState = %@", [self getBannerStateString:currentBannerState]);
        
        if (currentBannerState == REQUESTING) {
            // handle banners
            if (isAdPlayable) {
                // get size
                ISBannerSize *size = [bannerPlacementToSize objectForKey:placementID];
                
                if (![self isBannerAdCachedForPlacement:placementID
                                             serverData:serverData]) {
                    // When isAdPlayable is YES the isBannerAdCachedForPlacement should also return YES
                    // If for some reason that is not the case we might want to not show the banner
                    LogAdapterDelegate_Internal(@"Vungle Banner Ad is playable but not ready to be shown");
                }
                
                dispatch_async(dispatch_get_main_queue(), ^{
                    // create container
                    UIView *containerView = [self createBannerViewContainer:size];
                    NSError *vungleError;
                    
                    // call vungle api for showing banner in our container
                    if (serverData.length) {
                        [[VungleSDK sharedSDK] addAdViewToView:containerView
                                                   withOptions:@{}
                                                   placementID:placementID
                                                      adMarkup:serverData
                                                         error:&vungleError];
                    } else {
                        [[VungleSDK sharedSDK] addAdViewToView:containerView
                                                   withOptions:@{}
                                                   placementID:placementID
                                                         error:&vungleError];
                    }
                    
                    if (vungleError) {
                        LogAdapterDelegate_Internal(@"Vungle failed to add view - vungleError = %@", vungleError);
                        [bannerDelegate adapterBannerDidFailToLoadWithError:vungleError];
                    } else {
                        // update banner state - SHOWING
                        [bannerPlacementToBannerState setObject:[self getBannerStateObject:SHOWING] forKey:placementID];
                        // call delegate success
                        [bannerDelegate adapterBannerDidLoad:containerView];
                    }
                });
            } else {
                // update banner state - UNKNOWN
                [bannerPlacementToBannerState setObject:[self getBannerStateObject:UNKNOWN] forKey:placementID];
                
                NSError *smashError = [ISError createError:ERROR_BN_LOAD_NO_FILL
                                               withMessage:[NSString stringWithFormat:@"Vungle - banner no ads to show for placementId = %@", placementID]];
                
                [bannerDelegate adapterBannerDidFailToLoadWithError:smashError];
            }
        }
    }
}

-(void)bannerAdViewedForPlacement:(NSString *)placementID
                       serverData:(NSString *)serverData {
    LogAdapterDelegate_Internal(@"placementID = %@", placementID);
    
    // get delegate
    id<ISBannerAdapterDelegate> bannerDelegate;
    if (serverData.length && [bannerServerDataToDelegate hasObjectForKey:serverData]) {
        bannerDelegate = [bannerServerDataToDelegate objectForKey:serverData];
    } else {
        bannerDelegate = [bannerPlacementToSmashDelegate objectForKey:placementID];
    }
    
    if (bannerDelegate) {
        [bannerDelegate adapterBannerDidShow];
    }
}

-(void)bannerDidCloseAdWithPlacementID:(NSString *)placementID
                            serverData:(NSString *)serverData {
    LogAdapterDelegate_Internal(@"placementId = %@", placementID);
    
    // get delegate
    id<ISBannerAdapterDelegate> bannerDelegate;
    if (serverData.length && [bannerServerDataToDelegate hasObjectForKey:serverData]) {
        bannerDelegate = [bannerServerDataToDelegate objectForKey:serverData];
    } else {
        bannerDelegate = [bannerPlacementToSmashDelegate objectForKey:placementID];
    }
        
    if (bannerDelegate) {
        BANNER_STATE currentBannerState = [self getCurrentBannerState:placementID];
        LogAdapterDelegate_Internal(@"currentBannerState = %@", [self getBannerStateString:currentBannerState]);
        
        if (currentBannerState == REQUESTING_RELOAD) {
            
            // get size
            ISBannerSize *size = [bannerPlacementToSize objectForKey:placementID];
            
            // get view controller
            UIViewController *viewController = [bannerPlacementToViewController objectForKey:placementID];
            
            if (size && viewController) {
                // call load
                [self loadBannerWithPlacement:placementID
                               viewController:viewController
                                         size:size];
            }
        }
    }
}

-(void)bannerDidClickForPlacementID:(NSString *)placementID
                         serverData:(NSString *)serverData {
    LogAdapterDelegate_Internal(@"placementId = %@", placementID);
    
    // get delegate
    id<ISBannerAdapterDelegate> bannerDelegate;
    if (serverData.length && [bannerServerDataToDelegate hasObjectForKey:serverData]) {
        bannerDelegate = [bannerServerDataToDelegate objectForKey:serverData];
    } else {
        bannerDelegate = [bannerPlacementToSmashDelegate objectForKey:placementID];
    }
    
    if (bannerDelegate) {
        [bannerDelegate adapterBannerDidClick];
    }
}

-(void)bannerWillAdLeaveApplicationForPlacementID:(NSString *)placementID
                                       serverData:(NSString *)serverData {
    LogAdapterDelegate_Internal(@"placementID = %@", placementID);

    // get delegate
    id<ISBannerAdapterDelegate> bannerDelegate;
    if (serverData.length && [bannerServerDataToDelegate hasObjectForKey:serverData]) {
        bannerDelegate = [bannerServerDataToDelegate objectForKey:serverData];
    } else {
        bannerDelegate = [bannerPlacementToSmashDelegate objectForKey:placementID];
    }
    
    if (bannerDelegate) {
        [bannerDelegate adapterBannerWillLeaveApplication];
    }
}

#pragma mark - Private

- (void)initSDK:(NSString *)appId
       isBidder:(BOOL)bidder {
    
    if ((initState == NO_INIT) || (initState == INIT_IN_PROGRESS)) {
        [initCallbackDelegates addObject:self];
    }
    
    static dispatch_once_t onceToken;
    
    dispatch_once(&onceToken, ^{
        LogAdapterApi_Internal(@"");
        
        #pragma clang diagnostic push
        #pragma clang diagnostic ignored "-Wundeclared-selector"
        [[VungleSDK sharedSDK] performSelector:@selector(setPluginName:version:)
                                    withObject:@"ironsource"
                                    withObject:[self version]];
        #pragma clang diagnostic pop

        if (initState != NO_INIT) {
            LogAdapterApi_Internal(@"init state != no init");
            return;
        }
        
        // set init state
        initState = INIT_IN_PROGRESS;
        LogAdapterApi_Internal(@"appId = %@ adaptersDebug = %d", appId, [ISConfigurations getConfigurations].adaptersDebug);
        
        // set vungle delegate for bidding or non bidding flows
        [[VungleSDK sharedSDK] setSdkHBDelegate:[ISVungleAdapterSingleton sharedInstance]];
        [[VungleSDK sharedSDK] setDelegate:[ISVungleAdapterSingleton sharedInstance]];
        
        // set debug log
        [[VungleSDK sharedSDK] setLoggingEnabled:[ISConfigurations getConfigurations].adaptersDebug];
        
        // initiate singelton
        [[ISVungleAdapterSingleton sharedInstance] addFirstInitiatorDelegate:self];
        NSError *error;
        
        // init vungle sdk
        if (![[VungleSDK sharedSDK] startWithAppId:appId
                                             error:&error]) {
            initState = INIT_FAILED;
            LogAdapterApi_Internal(@"error = %@", error);
        }
    });
}

- (BOOL)isBannerSizeSupported:(ISBannerSize *)size {
    LogAdapterApi_Internal(@"size = %@", size.sizeDescription);
    
    if ([size.sizeDescription isEqualToString:@"BANNER"]) {
        return YES;
    } else if ([size.sizeDescription isEqualToString:@"LARGE"]) {
        return YES;
    } else if ([size.sizeDescription isEqualToString:@"RECTANGLE"]) {
        return YES;
    } else if ([size.sizeDescription isEqualToString:@"SMART"]) {
        return YES;
    }
    
    return NO;
}

- (VungleAdSize)getBannerSize:(ISBannerSize *)size {
    VungleAdSize vungleAdSize = VungleAdSizeUnknown;
    
    if ([size.sizeDescription isEqualToString:@"BANNER"]) {
        vungleAdSize = VungleAdSizeBanner;
    } else if ([size.sizeDescription isEqualToString:@"LARGE"]) {
        vungleAdSize = VungleAdSizeBanner;
    } else if ([size.sizeDescription isEqualToString:@"RECTANGLE"]) {
        // no need to assign rectangle size because the load is different from banner and does not need it
    } else if ([size.sizeDescription isEqualToString:@"SMART"]) {
        if (UI_USER_INTERFACE_IDIOM() == UIUserInterfaceIdiomPad) {
            vungleAdSize = VungleAdSizeBannerLeaderboard;
        } else {
            vungleAdSize = VungleAdSizeBanner;
        }
    }

    return vungleAdSize;
}

- (UIView *)createBannerViewContainer:(ISBannerSize *)size {
    
    // create rect
    CGRect rect = CGRectZero;
    
    // set rect size
    if ([size.sizeDescription isEqualToString:@"BANNER"] || [size.sizeDescription isEqualToString:@"LARGE"]) {
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
    
    // return container view
    UIView *containerView = [[UIView alloc] initWithFrame:rect];
    return containerView;
}

- (NSNumber *)getBannerStateObject:(BANNER_STATE)state {
    LogAdapterApi_Internal(@"for state = %@", [self getBannerStateString:state]);
    NSNumber *number = [NSNumber numberWithUnsignedLong:(unsigned long)state];
    return number;
}

- (NSString *)getBannerStateString:(BANNER_STATE)state {
    switch (state) {
        case UNKNOWN:
            return @"UNKNOWN";
        case REQUESTING:
            return @"REQUESTING";
        case REQUESTING_RELOAD:
            return @"REQUESTING_RELOAD";
        case SHOWING:
            return @"SHOWING";
    }
    
    return @"UNKNOWN";
}

- (BANNER_STATE)getCurrentBannerState:(NSString *)placementId {
    if ([bannerPlacementToBannerState objectForKey:placementId] != nil) {
        BANNER_STATE currentBannerState = (BANNER_STATE)[[bannerPlacementToBannerState objectForKey:placementId] intValue];
        return currentBannerState;
    }
    
    return UNKNOWN;
}

- (NSDictionary *)getBiddingDataWithAdapterConfig:(ISAdapterConfig *)adapterConfig {
    if (initState == INIT_FAILED) {
        LogInternal_Error(@"Returning nil as token since init failed");
        return nil;
    }
    
    NSString *bidderToken = [[VungleSDK sharedSDK] currentSuperToken];
    NSString *returnedToken = bidderToken? bidderToken : @"";
    NSString *sdkVersion = [self sdkVersion];
    LogAdapterApi_Internal(@"token = %@", returnedToken);
    LogAdapterApi_Internal(@"sdkVersion = %@", sdkVersion);
    return @{@"token": returnedToken, @"sdkVersion": sdkVersion};
}

- (NSDictionary *)createAdOptionsWithDynamicUserID:(BOOL) shouldIncludeDynamicUserID {
    NSMutableDictionary *optionsSet = [[NSMutableDictionary alloc] init];
    
    //set Dynamic user id
    if (shouldIncludeDynamicUserID && [self dynamicUserId] != nil) {
        [optionsSet setObject:[self dynamicUserId] forKey:VunglePlayAdOptionKeyUser];
    }

    //Add orientation configuration
    if (adOrientation.length) {
        if ([adOrientation isEqual:kPortraitOrientation]) {
            uiOrientation = @(UIInterfaceOrientationMaskPortrait);
        } else if ([adOrientation isEqual:kLandscapeOrientation]) {
            uiOrientation  = @(UIInterfaceOrientationMaskLandscape);
        } else if ([adOrientation isEqual:kAutoRotateOrientation]) {
            uiOrientation  = @(UIInterfaceOrientationMaskAll);
        }
        
        if (uiOrientation != nil) {
            //add to dictionary
            [optionsSet setObject:uiOrientation forKey:VunglePlayAdOptionKeyOrientations];
            LogInternal_Internal(@"set Vungle ad orientation - %@",adOrientation );
        }
    }
    
    return [optionsSet mutableCopy];
}

-(NSString *)getServerDataForPlacementId:(NSString *)placementId {
    NSString *serverData = @"";
    
    if ([rewardedVideoPlacementToServerData objectForKey:placementId]) {
        serverData = [rewardedVideoPlacementToServerData objectForKey:placementId];
    } else if ([interstitialPlacementToServerData objectForKey:placementId]) {
        serverData = [interstitialPlacementToServerData objectForKey:placementId];
    } else if ([bannerPlacementToServerData objectForKey:placementId]) {
        serverData = [bannerPlacementToServerData objectForKey:placementId];
    }
    
    return serverData;
}

-(BOOL)isAdCachedForPlacement:(NSString *)placementId {
    NSString *serverData = [self getServerDataForPlacementId:placementId];
    
    if (serverData.length) {
        return [[VungleSDK sharedSDK] isAdCachedForPlacementID:placementId
                                                      adMarkup:serverData];
    }
    
    return [[VungleSDK sharedSDK] isAdCachedForPlacementID:placementId];
}

-(BOOL)isBannerAdCachedForPlacement:(NSString *)placementId {
    NSString *serverData = [self getServerDataForPlacementId:placementId];

    if (serverData.length) {
        serverData = [bannerPlacementToServerData objectForKey:placementId];
    }
    
    return [self isBannerAdCachedForPlacement:placementId
                                   serverData:serverData];
}

-(BOOL)isBannerAdCachedForPlacement:(NSString *)placementId
                         serverData:(NSString *)serverData {
    ISBannerSize *size = [bannerPlacementToSize objectForKey:placementId];
    
    if ([size.sizeDescription isEqualToString:@"RECTANGLE"]) {
        if (serverData.length) {
            return [[VungleSDK sharedSDK] isAdCachedForPlacementID:placementId
                                                          adMarkup:serverData];
        }
        
        return [[VungleSDK sharedSDK] isAdCachedForPlacementID:placementId];
    } else {
        VungleAdSize vungleBannerSize = [self getBannerSize:size];
        
        if (serverData.length) {
            return [[VungleSDK sharedSDK] isAdCachedForPlacementID:placementId
                                                          adMarkup:serverData
                                                          withSize:vungleBannerSize];
        }
        
        return [[VungleSDK sharedSDK] isAdCachedForPlacementID:placementId
                                                      withSize:vungleBannerSize];
    }
}

// ability to override the adapter flag with a platform configuration in order to support load while show
- (ISLoadWhileShowSupportState) getLWSSupportState:(ISAdapterConfig *)adapterConfig {
    ISLoadWhileShowSupportState state = LWSState;
    
    if (adapterConfig != nil && [adapterConfig.settings objectForKey:kLWSSupportedState] != nil) {
        BOOL isLWSSupportedByInstance = [[adapterConfig.settings objectForKey:kLWSSupportedState] boolValue];
        
        if (isLWSSupportedByInstance) {
            state = LOAD_WHILE_SHOW_BY_INSTANCE;
        } else {
            state = LOAD_WHILE_SHOW_BY_NETWORK;
        }
    }
    
    return state;
}

@end
