//
//  ISFacebookAdapter.m
//  ISFacebookAdapter
//
//  Created by Yotam Ohayon on 02/02/2016.
//  Copyright © 2016 IronSource. All rights reserved.
//

#import "ISFacebookAdapter.h"

@import FBAudienceNetwork;

#define SYSTEM_VERSION_GREATER_THAN_OR_EQUAL_TO(v)  ([[[UIDevice currentDevice] systemVersion] compare:v options:NSNumericSearch] != NSOrderedAscending)

typedef NS_ENUM(NSInteger, InitState) {
    INIT_STATE_NONE,
    INIT_STATE_IN_PROGRESS,
    INIT_STATE_ERROR,
    INIT_STATE_SUCCESS
};
static InitState _initState = INIT_STATE_NONE;
static ConcurrentMutableSet<ISNetworkInitCallbackProtocol> *initCallbackDelegates = nil;

static NSString * const kAdapterName                = @"Facebook";
static NSString * const kAdapterVersion             = FacebookAdapterVersion;
static NSString * const kPlacementId                = @"placementId";
static NSString * const kAllPlacementIds            = @"placementIds";
static NSString * const kMediationService           = @"IronSource";
static NSString * const kAppId                      = @"appId";
static NSString * const kMetaDataMixAudienceKey     = @"meta_mixed_audience";

static NSInteger kUnsupportedAdapterErrorCode          = 101;
static NSInteger kErrorLoadInterstitialErrorCode       = 102;
static NSInteger kErrorShowInterstitialErrorCode       = 103;
static NSInteger kErrorLoadBannerErrorCode             = 104;
static NSInteger kErrorShowRewardVideoErrorCode        = 105;
static NSInteger kErrorNoFillErrorCode                 = 1001;

static NSString * const kFBSdkVersion                 = FB_AD_SDK_VERSION;

@interface ISFacebookAdapter () <FBInterstitialAdDelegate, FBRewardedVideoAdDelegate, FBAdViewDelegate, ISNetworkInitCallbackProtocol>
{
    // Rewarded video
    ConcurrentMutableDictionary*       _rewardedVideoPlacementIdToDelegate;
    ConcurrentMutableDictionary*       _rewardedVideoPlacementIdToAd;
    
    // Interstitial
    ConcurrentMutableDictionary*       _interstitialPlacementIdToDelegate;
    ConcurrentMutableDictionary*       _interstitialPlacementIdToAd;
    
    // Banner
    ConcurrentMutableDictionary*       _bannerPlacementIdToDelegate;
    ConcurrentMutableDictionary*       _bannerPlacementIdToAd;
    
    // programmatic
    ConcurrentMutableSet*              _programmaticPlacementIds;
}

@end

@implementation ISFacebookAdapter

#pragma mark - Initializations Methods

- (instancetype)initAdapter:(NSString *)name
{
    self = [super initAdapter:name];
    
    if (self) {
        if (initCallbackDelegates == nil) {
            initCallbackDelegates =  [ConcurrentMutableSet<ISNetworkInitCallbackProtocol> set];
        }
        
        _rewardedVideoPlacementIdToDelegate = [ConcurrentMutableDictionary dictionary];
        _rewardedVideoPlacementIdToAd = [ConcurrentMutableDictionary dictionary];
        
        _interstitialPlacementIdToDelegate = [ConcurrentMutableDictionary dictionary];
        _interstitialPlacementIdToAd = [ConcurrentMutableDictionary dictionary];
        
        _bannerPlacementIdToDelegate = [ConcurrentMutableDictionary dictionary];
        _bannerPlacementIdToAd = [ConcurrentMutableDictionary dictionary];
        
        _programmaticPlacementIds = [ConcurrentMutableSet set];
        
        // load while show
        LWSState = LOAD_WHILE_SHOW_BY_INSTANCE;
    }
    
    return self;
}

#pragma mark - IronSource Protocol Methods

- (NSString *)version {
    return kAdapterVersion;
}

- (NSString *)sdkVersion {
    return kFBSdkVersion;
}

- (NSArray *)systemFrameworks {
    return @[@"AdSupport", @"AVFoundation", @"AudioToolbox", @"CFNetwork", @"CoreGraphics", @"CoreImage", @"CoreMedia", @"CoreMotion", @"CoreTelephony", @"LocalAuthentication", @"SafariServices", @"Security", @"StoreKit", @"SystemConfiguration", @"UIKit", @"VideoToolbox", @"WebKit"];
}

- (NSString *)sdkName {
    return @"FBInterstitialAd";
}

- (void)setMetaDataWithKey:(NSString *)key
                 andValues:(NSMutableArray *)values {
    if (values.count == 0) {
        return;
    }
    
    NSString *value = values[0];
    LogAdapterApi_Internal(@"key=%@, value=%@", key, value);
    
    NSString *formattedValue = [ISMetaDataUtils formatValue:value forType:(META_DATA_VALUE_BOOL)];
    if ([self isValidMixedAudienceMetaData:key andValue:formattedValue]) {
        [self setMixedAudience:[ISMetaDataUtils getCCPABooleanValue:formattedValue]];
    }
}

- (BOOL) isValidMixedAudienceMetaData:(NSString *)key
                             andValue:(NSString *)value {
    return ([key caseInsensitiveCompare:kMetaDataMixAudienceKey] == NSOrderedSame && (value.length));
}

- (void) setMixedAudience:(BOOL)isMixedAudience {
    LogAdapterApi_Internal(@"isMixedAudience = %@", isMixedAudience ? @"YES" : @"NO");
    [FBAdSettings setMixedAudience:isMixedAudience];
}

#pragma mark - Rewarded Video

- (NSDictionary *)getRewardedVideoBiddingDataWithAdapterConfig:(ISAdapterConfig *)adapterConfig {
    LogAdapterApi_Internal(@"");
    return [self getBiddingData];
}

- (void)initRewardedVideoForCallbacksWithUserId:(NSString *)userId
                                  adapterConfig:(ISAdapterConfig *)adapterConfig
                                       delegate:(id<ISRewardedVideoAdapterDelegate>)delegate {
    NSString *appId = adapterConfig.settings[kAppId];
    NSString *placementID = adapterConfig.settings[kPlacementId];
    NSString *allPlacementIDs = adapterConfig.settings[kAllPlacementIds];
    
    // check supported version
    if (![self isSupported]) {
        NSError *error = [self errorForUnsupportedAdapter:@"RV"];
        LogAdapterApi_Internal(@"error.description = %@", error.description);
        
        [delegate adapterRewardedVideoInitFailed:error];
        return;
    }
    
    // check appId
    if (![self isConfigValueValid:appId]) {
        NSError *error = [self errorForMissingCredentialFieldWithName:kAppId];
        LogAdapterApi_Internal(@"error.description = %@", error.description);
        
        [delegate adapterRewardedVideoInitFailed:error];
        return;
    }
    
    // check placementID
    if (![self isConfigValueValid:placementID]) {
        NSError *error = [self errorForMissingCredentialFieldWithName:kPlacementId];
        LogAdapterApi_Internal(@"error.description = %@", error.description);
        
        [delegate adapterRewardedVideoInitFailed:error];
        return;
    }
    
    // add to the dict
    [_rewardedVideoPlacementIdToDelegate setObject:delegate
                                            forKey:placementID];
    [_programmaticPlacementIds addObject:placementID];
    
    // set mediation name
    [FBAdSettings setMediationService:[self getMediationServiceName]];
    
    // check if debug mode needed
    FBAdLogLevel logLevel =[ISConfigurations getConfigurations].adaptersDebug ? FBAdLogLevelVerbose : FBAdLogLevelNone;
    [FBAdSettings setLogLevel:logLevel];
    LogAdapterApi_Internal(@"logLevel=%ld", logLevel);
    
    // In case we didn't receive the placement IDs we cannot manually init Facebook
    if (![self isConfigValueValid:allPlacementIDs]) {
        LogAdapterApi_Internal(@"Initialize rewarded video bidding without allPlacementIDs");
        LogAdapterApi_Internal(@"placementID = %@ - userID = %@", placementID, userId);
        
        [delegate adapterRewardedVideoInitSuccess];
    } else {
        LogAdapterApi_Internal(@"Initialize rewarded video bidding with allPlacementIDs");
        
        // create placements array for the init
        NSArray* placementIdsArr = [allPlacementIDs componentsSeparatedByString:@","];
        [self initSDKWithAppId:appId
                        userId:userId
                  placementIDs:placementIdsArr];
        
        // call init success
        if (_initState == INIT_STATE_SUCCESS) {
            LogAdapterApi_Internal(@"placementID = %@ - userID = %@", placementID, userId);
            [delegate adapterRewardedVideoInitSuccess];
        } else if (_initState == INIT_STATE_ERROR) {
            NSError *error = [NSError errorWithDomain:kAdapterName
                                                 code:ERROR_CODE_INIT_FAILED
                                             userInfo:@{NSLocalizedDescriptionKey:@"init error"}];
            LogAdapterApi_Internal(@"error.description = %@", error.description);
            
            [delegate adapterRewardedVideoInitFailed:error];
        }
    }
}

- (void)initAndLoadRewardedVideoWithUserId:(NSString *)userId
                             adapterConfig:(ISAdapterConfig *)adapterConfig
                                  delegate:(id<ISRewardedVideoAdapterDelegate>)delegate {
    NSString *appId = adapterConfig.settings[kAppId];
    NSString *placementID = adapterConfig.settings[kPlacementId];
    NSString *allPlacementIDs = adapterConfig.settings[kAllPlacementIds];
    
    // check supported version
    if (![self isSupported]) {
        NSError *error = [self errorForUnsupportedAdapter:@"RV"];
        LogAdapterApi_Internal(@"error.description = %@", error.description);
        
        [delegate adapterRewardedVideoHasChangedAvailability:NO];
        return;
    }
    
    // check appId
    if (![self isConfigValueValid:appId]) {
        NSError *error = [self errorForMissingCredentialFieldWithName:kAppId];
        LogAdapterApi_Internal(@"error.description = %@", error.description);
        
        [delegate adapterRewardedVideoHasChangedAvailability:NO];
        return;
    }
    
    // check placementID
    if (![self isConfigValueValid:placementID]) {
        NSError *error = [self errorForMissingCredentialFieldWithName:kPlacementId];
        LogAdapterApi_Internal(@"error.description = %@", error.description);
        
        [delegate adapterRewardedVideoHasChangedAvailability:NO];
        return;
    }
    
    
    // add delegate to the dict
    [_rewardedVideoPlacementIdToDelegate setObject:delegate
                                            forKey:placementID];
    
    // set mediation name
    [FBAdSettings setMediationService:[self getMediationServiceName]];
    
    // check if debug mode needed
    FBAdLogLevel logLevel =[ISConfigurations getConfigurations].adaptersDebug ? FBAdLogLevelVerbose : FBAdLogLevelNone;
    [FBAdSettings setLogLevel:logLevel];
    LogAdapterApi_Internal(@"logLevel=%ld", logLevel);
    
    // In case we didn't receive the placement IDs we cannot manually init Facebook
    if (![self isConfigValueValid:allPlacementIDs]) {
        LogAdapterApi_Internal(@"Initialize rewarded video without allPlacementIDs");
        LogAdapterApi_Internal(@"placementID = %@ - userID = %@", placementID, userId);
        
        [self loadRewardedVideoAdWithPlacement:placementID];
        
    } else {
        LogAdapterApi_Internal(@"Initialize rewarded video with allPlacementIDs");
        
        // create placements array for the init
        NSArray* placementIdsArr = [allPlacementIDs componentsSeparatedByString:@","];
        [self initSDKWithAppId:appId
                        userId:userId
                  placementIDs:placementIdsArr];
        
        // call init success
        if (_initState == INIT_STATE_SUCCESS) {
            LogAdapterApi_Internal(@"placementID = %@ - userID = %@", placementID, userId);
            [self loadRewardedVideoAdWithPlacement:placementID];
        } else if (_initState == INIT_STATE_ERROR) {
            LogAdapterApi_Internal(@"adapterRewardedVideoHasChangedAvailability:NO");
            [delegate adapterRewardedVideoHasChangedAvailability:NO];
        }
    }
}

- (void)showRewardedVideoWithViewController:(UIViewController *)viewController
                              adapterConfig:(ISAdapterConfig *)adapterConfig
                                   delegate:(id<ISRewardedVideoAdapterDelegate>)delegate {
    @try {
        NSString *placementID = adapterConfig.settings[kPlacementId];
        LogAdapterApi_Internal(@"placementID = %@", placementID);
        
        if (!viewController) {
            viewController = [self topMostController];
        }
        
        if ([self hasRewardedVideoWithAdapterConfig:adapterConfig]) {
            
            FBRewardedVideoAd *ad = [_rewardedVideoPlacementIdToAd objectForKey:placementID];
            
            if (ad && ad.isAdValid) {
                // set dynamic user id to ad if exists
                if ([self dynamicUserId]) {
                    [ad setRewardDataWithUserID:[self dynamicUserId]
                                   withCurrency:@"1"];
                }
                
                [ad showAdFromRootViewController:viewController];
            } else {
                NSString *reason = [NSString stringWithFormat:@"%@", ad ? @"ad is not valid" : @"ad is null"];
                NSError *error = [NSError errorWithDomain:[NSString stringWithFormat:@"ISFacebookAdapter - showRewardedVideo - reason = %@", reason]
                                                     code:100
                                                 userInfo:nil];
                LogAdapterApi_Internal(@"error.description = %@", error.description);
                [delegate adapterRewardedVideoDidFailToShowWithError:error];
            }
        } else {
            NSError *error = [NSError errorWithDomain:kAdapterName
                                                 code:100
                                             userInfo:nil];
            LogAdapterApi_Internal(@"error.description = %@", error.description);
            [delegate adapterRewardedVideoDidFailToShowWithError:error];
        }
        
    } @catch (NSException *exception) {
        NSError *error = [self errorForAd:exception
                                 withCode:kErrorShowRewardVideoErrorCode];
        LogAdapterApi_Internal(@"error.description = %@", error.description);
        [delegate adapterRewardedVideoDidFailToShowWithError:error];
    }
}

//Load rewarded video for bidding
- (void)loadRewardedVideoForBiddingWithAdapterConfig:(ISAdapterConfig *)adapterConfig
                                          serverData:(NSString *)serverData
                                            delegate:(id<ISRewardedVideoAdapterDelegate>)delegate{
    
    LogAdapterApi_Internal(@"adapterConfig.providerName = %@", adapterConfig.providerName);
    [self loadRewardedVideoInternal:adapterConfig
                           delegate:delegate
                         serverData:serverData];
}

- (void)fetchRewardedVideoForAutomaticLoadWithAdapterConfig:(ISAdapterConfig *)adapterConfig
                                                   delegate:(id<ISRewardedVideoAdapterDelegate>)delegate {
    
    LogAdapterApi_Internal(@"adapterConfig.providerName = %@", adapterConfig.providerName);
    [self loadRewardedVideoInternal:adapterConfig
                           delegate:delegate
                         serverData:nil];
}

- (void)loadRewardedVideoInternal:(ISAdapterConfig *)adapterConfig
                         delegate:(id<ISRewardedVideoAdapterDelegate>)delegate
                       serverData:(NSString *)serverData {
    
    NSString *placementID = adapterConfig.settings[kPlacementId];
    
    // check supported version
    if (![self isSupported]) {
        LogAdapterApi_Internal(@"failed - unsupported iOS version for the SDK");
        [delegate adapterRewardedVideoHasChangedAvailability:NO];
        return;
    }
    
    /* Verify parameters */
    if (![self isConfigValueValid:placementID]) {
        NSError *error = [self errorForMissingCredentialFieldWithName:kPlacementId];
        LogAdapterApi_Internal(@"error.description = %@", error.description);
        
        [delegate adapterRewardedVideoHasChangedAvailability:NO];
        return;
    }
    
    LogAdapterApi_Internal(@"adapterConfig.providerName = %@", adapterConfig.providerName);
    
    [self loadRewardedVideoAdWithPlacement:placementID
                                serverData:serverData];
}

- (BOOL)hasRewardedVideoWithAdapterConfig:(ISAdapterConfig *)adapterConfig {
    
    NSString *placementID = adapterConfig.settings[kPlacementId];
    
    // check supported version
    if (![self isSupported]) {
        return NO;
    }
    
    FBRewardedVideoAd *rewardedVideoAd = [_rewardedVideoPlacementIdToAd objectForKey:placementID];
    
    if (rewardedVideoAd) {
        return rewardedVideoAd.adValid;
    }
    
    return NO;
}

#pragma mark - Interstitial

- (NSDictionary *)getInterstitialBiddingDataWithAdapterConfig:(ISAdapterConfig *)adapterConfig {
    
    LogAdapterApi_Internal(@"");
    return [self getBiddingData];
}

- (void)initInterstitialForBiddingWithUserId:(NSString *)userId
                               adapterConfig:(ISAdapterConfig *)adapterConfig
                                    delegate:(id<ISInterstitialAdapterDelegate>)delegate {
    
    LogAdapterApi_Internal(@"");
    [self initInterstitialWithUserId:userId
                       adapterConfig:adapterConfig
                            delegate:delegate];
}

- (void)initInterstitialWithUserId:(NSString *)userId
                     adapterConfig:(ISAdapterConfig *)adapterConfig
                          delegate:(id<ISInterstitialAdapterDelegate>)delegate {
    
    NSString *appId = adapterConfig.settings[kAppId];
    NSString *placementID = adapterConfig.settings[kPlacementId];
    NSString *allPlacementIDs = adapterConfig.settings[kAllPlacementIds];
    
    // check supported version
    if (![self isSupported]) {
        NSError *error = [self errorForUnsupportedAdapter:@"IS"];
        LogAdapterApi_Internal(@"error.description = %@", error.description);
        
        [delegate adapterInterstitialInitFailedWithError:error];
        return;
    }
    
    // check appId
    if (![self isConfigValueValid:appId]) {
        NSError *error = [self errorForMissingCredentialFieldWithName:kAppId];
        LogAdapterApi_Internal(@"error.description = %@", error.description);
        
        [delegate adapterInterstitialInitFailedWithError:error];
        return;
    }
    
    // check placementID
    if (![self isConfigValueValid:placementID]) {
        NSError *error = [self errorForMissingCredentialFieldWithName:kPlacementId];
        LogAdapterApi_Internal(@"error.description = %@", error.description);
        
        [delegate adapterInterstitialInitFailedWithError:error];
        return;
    }
    
    /* Register Delegate for placement */
    [_interstitialPlacementIdToDelegate setObject:delegate
                                           forKey:placementID];
    
    // set mediation name
    [FBAdSettings setMediationService:[self getMediationServiceName]];
    
    // check if debug mode needed
    FBAdLogLevel logLevel =[ISConfigurations getConfigurations].adaptersDebug ? FBAdLogLevelVerbose : FBAdLogLevelNone;
    [FBAdSettings setLogLevel:logLevel];
    LogAdapterApi_Internal(@"logLevel=%ld", logLevel);
    
    // In case we didn't receive the placement IDs we cannot manually init Facebook
    if (![self isConfigValueValid:allPlacementIDs]) {
        LogAdapterApi_Internal(@"Initialize interstitial without allPlacementIDs");
        LogAdapterApi_Internal(@"placementID = %@ - userId = %@", placementID, userId);
        
        [delegate adapterInterstitialInitSuccess];
        
    } else {
        LogAdapterApi_Internal(@"Initialize interstitial with allPlacementIDs");
        
        // create placements array for the init
        NSArray* placementIdsArr = [allPlacementIDs componentsSeparatedByString:@","];
        [self initSDKWithAppId:appId
                        userId:userId
                  placementIDs:placementIdsArr];
        
        // call init success
        if (_initState == INIT_STATE_SUCCESS) {
            LogAdapterApi_Internal(@"placementID = %@ - userId = %@", placementID, userId);
            [delegate adapterInterstitialInitSuccess];
        } else if (_initState == INIT_STATE_ERROR) {
            NSError *error = [NSError errorWithDomain:kAdapterName
                                                 code:ERROR_CODE_INIT_FAILED
                                             userInfo:@{NSLocalizedDescriptionKey:@"init failed"}];
            LogAdapterApi_Internal(@"error.description = %@", error.description);
            
            [delegate adapterInterstitialInitFailedWithError:error];
        }
    }
}

//Load interstitial for bidding
- (void)loadInterstitialForBiddingWithServerData:(NSString *)serverData
                                   adapterConfig:(ISAdapterConfig *)adapterConfig
                                        delegate:(id<ISInterstitialAdapterDelegate>)delegate {
    
    LogAdapterApi_Internal(@"placementID = %@", adapterConfig.settings[kPlacementId]);
    [self loadInterstitialInternal:adapterConfig
                    activeDelegate:delegate
                        serverData:serverData];
}

- (void)loadInterstitialWithAdapterConfig:(ISAdapterConfig *)adapterConfig
                                 delegate:(id<ISInterstitialAdapterDelegate>)delegate {
    
    LogAdapterApi_Internal(@"placementID = %@", adapterConfig.settings[kPlacementId]);
    [self loadInterstitialInternal:adapterConfig
                    activeDelegate:delegate
                        serverData:nil];
}

- (void)loadInterstitialInternal:(ISAdapterConfig *)adapterConfig
                  activeDelegate:(id<ISInterstitialAdapterDelegate>)activeDelegate
                      serverData:(NSString *)serverData {
    
    NSString *placementID = adapterConfig.settings[kPlacementId];
    LogAdapterApi_Internal(@"placementID = %@", placementID);
    
    dispatch_async(dispatch_get_main_queue(), ^{
        @try {
            
            /* Create the interstitial unit with a placement ID (generate your own on the Facebook app settings).
             * Use different ID for each ad placement in your app.
             */
            
            FBInterstitialAd *interstitialAd = [_interstitialPlacementIdToAd objectForKey:placementID];
            interstitialAd = [[FBInterstitialAd alloc] initWithPlacementID:placementID];
            interstitialAd.delegate = self;
            [_interstitialPlacementIdToAd setObject:interstitialAd
                                             forKey:placementID];
            
            //Auction will never return nil serverData (AdMarkup) for bidder
            if (serverData == nil) {
                [interstitialAd loadAd];
            } else {
                [interstitialAd loadAdWithBidPayload:serverData];
            }
        } @catch (NSException *exception) {
            NSError *error = [self errorForAd:exception
                                     withCode:kErrorLoadInterstitialErrorCode];
            LogAdapterApi_Internal(@"error.description = %@", error.description);
            
            [activeDelegate adapterInterstitialInitFailedWithError:error];
        }
    });
}

- (void)showInterstitialWithViewController:(UIViewController *)viewController
                             adapterConfig:(ISAdapterConfig *)adapterConfig
                                  delegate:(id<ISInterstitialAdapterDelegate>)delegate {
    
    NSString *placementID = adapterConfig.settings[kPlacementId];
    LogAdapterApi_Internal(@"placementID = %@", placementID);
    
    dispatch_async(dispatch_get_main_queue(), ^{
        @try {
            self.interstitialReady = NO;
            
            FBInterstitialAd *ad = [_interstitialPlacementIdToAd objectForKey:placementID];
            if (ad && ad.isAdValid) {
                [ad showAdFromRootViewController:viewController];
            } else {
                NSString *reason = [NSString stringWithFormat:@"%@", ad ? @"ad is not valid" : @"ad is null"];
                NSError *error = [NSError errorWithDomain:kAdapterName code:ERROR_CODE_NO_ADS_TO_SHOW userInfo:@{NSLocalizedDescriptionKey:[NSString stringWithFormat:@"ISFacebookAdapter - showInterstitial - reason = %@", reason]}];
                LogAdapterApi_Internal(@"error.description = %@", error.description);
                
                [delegate adapterInterstitialInitFailedWithError:error];
            }
        } @catch (NSException *exception) {
            NSError *error = [self errorForAd:exception withCode:kErrorShowInterstitialErrorCode];
            LogAdapterApi_Internal(@"error.description = %@", error.description);
            
            [delegate adapterInterstitialInitFailedWithError:error];
        }
        
    });
}

- (BOOL)hasInterstitialWithAdapterConfig:(ISAdapterConfig *)adapterConfig {
    
    NSString *placementID = adapterConfig.settings[kPlacementId];
    
    // check supported version
    if (![self isSupported]) {
        return NO;
    }
    
    FBInterstitialAd *interstitialAd = [_interstitialPlacementIdToAd objectForKey:placementID];
    
    if (interstitialAd) {
        return interstitialAd.adValid;
    }
    
    return NO;
}

#pragma mark - Banner

- (NSDictionary *)getBannerBiddingDataWithAdapterConfig:(ISAdapterConfig *)adapterConfig {
    
    LogAdapterApi_Internal(@"");
    return [self getBiddingData];
}

- (void)initBannerWithUserId:(nonnull NSString *)userId
               adapterConfig:(nonnull ISAdapterConfig *)adapterConfig
                    delegate:(nonnull id<ISBannerAdapterDelegate>)delegate {
    
    LogAdapterApi_Internal(@"");
    [self initBannersInternal:userId
                adapterConfig:adapterConfig
                     delegate:delegate];
}

- (void)initBannerForBiddingWithUserId:(NSString *)userId
                         adapterConfig:(ISAdapterConfig *)adapterConfig
                              delegate:(id<ISBannerAdapterDelegate>)delegate {
    
    LogAdapterApi_Internal(@"");
    [self initBannersInternal:userId
                adapterConfig:adapterConfig
                     delegate:delegate];
}

- (void)initBannersInternal:(NSString *)userId
              adapterConfig:(ISAdapterConfig *)adapterConfig
                   delegate:(id<ISBannerAdapterDelegate>)delegate {
    
    NSString *appId = adapterConfig.settings[kAppId];
    NSString *placementID = adapterConfig.settings[kPlacementId];
    NSString *allPlacementIDs = adapterConfig.settings[kAllPlacementIds];
    
    // check supported version
    if (![self isSupported]) {
        NSError *error = [self errorForUnsupportedAdapter:@"BN"];
        LogAdapterApi_Internal(@"error.description = %@", error.description);
        
        [delegate adapterBannerInitFailedWithError:error];
        return;
    }
    
    // check appId
    if (![self isConfigValueValid:appId]) {
        NSError *error = [self errorForMissingCredentialFieldWithName:kAppId];
        LogAdapterApi_Internal(@"error.description = %@", error.description);
        
        [delegate adapterBannerInitFailedWithError:error];
        return;
    }
    
    // check placementID
    if (![self isConfigValueValid:placementID]) {
        NSError *error = [self errorForMissingCredentialFieldWithName:kPlacementId];
        LogAdapterApi_Internal(@"error.description = %@", error.description);
        
        [delegate adapterBannerInitFailedWithError:error];
        return;
    }
    
    // add delegate to dictionary
    [_bannerPlacementIdToDelegate setObject:delegate
                                     forKey:placementID];
    
    // set mediation name
    [FBAdSettings setMediationService:[self getMediationServiceName]];
    
    // check if debug mode needed
    FBAdLogLevel logLevel =[ISConfigurations getConfigurations].adaptersDebug  ?FBAdLogLevelVerbose : FBAdLogLevelNone;
    [FBAdSettings setLogLevel:logLevel];
    LogAdapterApi_Internal(@"logLevel=%ld", logLevel);
    
    // In case we didn't receive the placement IDs we cannot manually init Facebook
    if (![self isConfigValueValid:allPlacementIDs]) {
        LogAdapterApi_Internal(@"Initialize banner without allPlacementIDs");
        LogAdapterApi_Internal(@"placementID = %@ - userID = %@", placementID, userId);
        
        [delegate adapterBannerInitSuccess];
    } else {
        LogAdapterApi_Internal(@"Initialize banner with allPlacementIDs");
        
        // create placements array for the init
        NSArray* placementIdsArr = [allPlacementIDs componentsSeparatedByString:@","];
        [self initSDKWithAppId:appId
                        userId:userId
                  placementIDs:placementIdsArr];
        
        // call init success
        if (_initState == INIT_STATE_SUCCESS) {
            LogAdapterApi_Internal(@"placementID = %@ - userId = %@", placementID, userId);
            [delegate adapterBannerInitSuccess];
        } else if (_initState == INIT_STATE_ERROR) {
            NSError *error = [NSError errorWithDomain:kAdapterName
                                                 code:ERROR_CODE_INIT_FAILED
                                             userInfo:@{NSLocalizedDescriptionKey:@"init failed"}];
            LogAdapterApi_Internal(@"error.description = %@", error.description);
            
            [delegate adapterBannerInitFailedWithError:error];
        }
    }
}

- (void)loadBannerForBiddingWithServerData:(NSString *)serverData
                            viewController:(UIViewController *)viewController
                                      size:(ISBannerSize *)size
                             adapterConfig:(ISAdapterConfig *)adapterConfig
                                  delegate:(id <ISBannerAdapterDelegate>)delegate {
    
    LogAdapterApi_Internal(@"");
    [self loadBannerInternal:serverData
              viewController:viewController
                        size:size
               adapterConfig:adapterConfig
                    delegate:delegate];
}

- (void)loadBannerWithViewController:(nonnull UIViewController *)viewController
                                size:(ISBannerSize *)size
                       adapterConfig:(nonnull ISAdapterConfig *)adapterConfig
                            delegate:(nonnull id <ISBannerAdapterDelegate>)delegate {
    
    LogAdapterApi_Internal(@"");
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
    
    dispatch_async(dispatch_get_main_queue(), ^{
        @try {
            if ([self isBannerSizeSupported:size]) {
                // get size
                FBAdSize fbSize = [self getBannerSize:size];
                
                // get rect
                CGRect rect = [self getBannerRect:size];
                
                // create banner view
                FBAdView *bannerAd = [[FBAdView alloc] initWithPlacementID:placementID
                                                                    adSize:fbSize
                                                        rootViewController:viewController];
                bannerAd.frame = rect;
                
                // Set a delegate
                bannerAd.delegate = self;
                
                // add to dictionary
                [_bannerPlacementIdToAd setObject:bannerAd
                                           forKey:placementID];
                
                // load the ad
                if (serverData == nil) {
                    [bannerAd loadAd];
                } else {
                    [bannerAd loadAdWithBidPayload:serverData];
                }
            } else {
                // banner size not supported
                NSError *error = [NSError errorWithDomain:kAdapterName
                                                     code:ERROR_BN_UNSUPPORTED_SIZE
                                                 userInfo:@{NSLocalizedDescriptionKey:@"Facebook unsupported banner size"}];
                LogAdapterApi_Internal(@"error.description = %@", error.description);
                
                [delegate adapterBannerDidFailToLoadWithError:error];
            }
        } @catch (NSException *exception) {
            NSError *error = [self errorForAd:exception withCode:kErrorLoadBannerErrorCode];
            LogAdapterApi_Internal(@"error.description = %@", error.description);
            
            [delegate adapterBannerDidFailToLoadWithError:error];
        }
    });
}

/// This method will not be called from version 6.14.0 - we leave it here for backwords compatibility
- (void)reloadBannerWithAdapterConfig:(nonnull ISAdapterConfig *)adapterConfig delegate:(nonnull id <ISBannerAdapterDelegate>)delegate {
    
    dispatch_async(dispatch_get_main_queue(), ^{
        NSString *placementID = adapterConfig.settings[kPlacementId];
        LogAdapterApi_Internal(@"placementID = %@", placementID);
        
        @try {
            FBAdView *bannerAd = [_bannerPlacementIdToAd objectForKey:placementID];
            
            if (bannerAd) {
                [bannerAd loadAd];
            }
        }
        @catch (NSException *exception) {
            LogAdapterApi_Internal(@"exception = %@", exception);
            id<ISBannerAdapterDelegate> delegate = [_bannerPlacementIdToDelegate objectForKey:placementID];
            
            if (delegate) {
                NSError *error = [self errorForAd:exception
                                         withCode:kErrorLoadBannerErrorCode];
                LogAdapterApi_Internal(@"error.description = %@", error.description);
                
                [delegate adapterBannerDidFailToLoadWithError:error];
            }
        }
    });
}

- (void)destroyBannerWithAdapterConfig:(nonnull ISAdapterConfig *)adapterConfig {
    // there is no required implementation for facebook destroy banner
}

#pragma mark - Banner Delegate

/**
 Sent after an FBAdView fails to load the ad.
 
 - Parameter adView: An FBAdView object sending the message.
 - Parameter error: An error object containing details of the error.
 */
- (void)adView:(FBAdView *)adView didFailWithError:(NSError *)error {
    
    LogAdapterDelegate_Internal(@"adView.placementID = %@", adView.placementID);
    /* Get delegate for placement */
    if (adView.placementID.length &&
        [_bannerPlacementIdToDelegate objectForKey:adView.placementID]) {
        id<ISBannerAdapterDelegate> delegate = [_bannerPlacementIdToDelegate objectForKey:adView.placementID];
        NSError *bannerError = nil;
        
        if (error.code == kErrorNoFillErrorCode) {
            bannerError = [NSError errorWithDomain:kAdapterName
                                              code:ERROR_BN_LOAD_NO_FILL
                                          userInfo:@{NSLocalizedDescriptionKey:@"Facebook no fill"}];
        } else {
            bannerError = error;
        }
        
        LogAdapterApi_Internal(@"error.description = %@", bannerError.description);
        
        [delegate adapterBannerDidFailToLoadWithError:bannerError];
        [_bannerPlacementIdToAd removeObjectForKey:adView.placementID];
    }
}

/**
 Sent when an ad has been successfully loaded.
 
 - Parameter adView: An FBAdView object sending the message.
 */
- (void)adViewDidLoad:(FBAdView *)adView {
    
    LogAdapterDelegate_Internal(@"adView.placementID = %@", adView.placementID);
    
    /* Get delegate for placement */
    if (adView.placementID.length) {
        id<ISBannerAdapterDelegate> delegate = [_bannerPlacementIdToDelegate objectForKey:adView.placementID];
        
        if (delegate) {
            [delegate adapterBannerDidLoad:adView];
        }
    }
}

/**
 Sent immediately before the impression of an FBAdView object will be logged.
 
 - Parameter adView: An FBAdView object sending the message.
 */
- (void)adViewWillLogImpression:(FBAdView *)adView {
    
    LogAdapterDelegate_Internal(@"adView.placementID = %@", adView.placementID);
    
    /* Get delegate for placement */
    if (adView.placementID.length) {
        id<ISBannerAdapterDelegate> delegate = [_bannerPlacementIdToDelegate objectForKey:adView.placementID];
        [delegate adapterBannerDidShow];
    }
}

/**
 Sent after an ad has been clicked by the person.
 
 - Parameter adView: An FBAdView object sending the message.
 */
- (void)adViewDidClick:(FBAdView *)adView {
    
    LogAdapterDelegate_Internal(@"adView.placementID = %@", adView.placementID);
    
    /* Get delegate for placement */
    if (adView.placementID.length) {
        id<ISBannerAdapterDelegate> delegate = [_bannerPlacementIdToDelegate objectForKey:adView.placementID];
        
        if (delegate) {
            [delegate adapterBannerDidClick];
        }
    }
}

/**
 When an ad is clicked, the modal view will be presented. And when the user finishes the
 interaction with the modal view and dismiss it, this message will be sent, returning control
 to the application.
 
 - Parameter adView: An FBAdView object sending the message.
 */
- (void)adViewDidFinishHandlingClick:(FBAdView *)adView {
    LogAdapterDelegate_Internal(@"adView.placementID = %@", adView.placementID);
}

#pragma mark - Rewarded Video Delegate

/**
 Sent after an FBRewardedVideoAd fails to load the ad.
 @param rewardedVideoAd An FBRewardedVideoAd object sending the message.
 @param error An error object containing details of the error.
 */
- (void)rewardedVideoAd:(FBRewardedVideoAd *)rewardedVideoAd
       didFailWithError:(NSError *)error {
    
    LogAdapterDelegate_Internal(@"rewardedVideoAd.placementID = %@", rewardedVideoAd.placementID);
    LogAdapterApi_Internal(@"error.description = %@", error.description);
    
    /* Get delegate for placement */
    if (rewardedVideoAd.placementID.length && [_rewardedVideoPlacementIdToDelegate objectForKey:rewardedVideoAd.placementID]) {
        id<ISRewardedVideoAdapterDelegate> delegate = [_rewardedVideoPlacementIdToDelegate objectForKey:rewardedVideoAd.placementID];
        
        NSError *smashError = nil;
        
        if (error.code == kErrorNoFillErrorCode) {
            smashError = [NSError errorWithDomain:kAdapterName
                                             code:ERROR_RV_LOAD_NO_FILL
                                         userInfo:@{NSLocalizedDescriptionKey : @"Facebook no fill"}];
        } else {
            smashError = error;
        }
        
        [delegate adapterRewardedVideoHasChangedAvailability:NO];
        [delegate adapterRewardedVideoDidFailToLoadWithError:smashError];
    }
}

/**
 Sent when an ad has been successfully loaded.
 @param rewardedVideoAd An FBRewardedVideoAd object sending the message.
 */
- (void)rewardedVideoAdDidLoad:(FBRewardedVideoAd *)rewardedVideoAd {
    
    LogAdapterDelegate_Internal(@"rewardedVideoAd.placementID = %@", rewardedVideoAd.placementID);
    
    BOOL hasAvailableAds = NO;
    FBRewardedVideoAd *ad = [_rewardedVideoPlacementIdToAd objectForKey:rewardedVideoAd.placementID];
    if (ad) {
        hasAvailableAds = ad.adValid;
    }
    
    /* Get delegate for placement */
    if (rewardedVideoAd.placementID.length &&
        [_rewardedVideoPlacementIdToDelegate objectForKey:rewardedVideoAd.placementID]) {
        id<ISRewardedVideoAdapterDelegate> delegate = [_rewardedVideoPlacementIdToDelegate objectForKey:rewardedVideoAd.placementID];
        
        [delegate adapterRewardedVideoHasChangedAvailability:hasAvailableAds];
    }
}

/**
 Sent immediately before the impression of an FBRewardedVideoAd object will be logged.
 @param rewardedVideoAd An FBRewardedVideoAd object sending the message.
 */
- (void)rewardedVideoAdWillLogImpression:(FBRewardedVideoAd *)rewardedVideoAd {
    
    LogAdapterDelegate_Internal(@"rewardedVideoAd.placementID = %@", rewardedVideoAd.placementID);
    
    /* Get delegate for placement */
    if (rewardedVideoAd.placementID.length &&
        [_rewardedVideoPlacementIdToDelegate objectForKey:rewardedVideoAd.placementID]) {
        id<ISRewardedVideoAdapterDelegate> delegate = [_rewardedVideoPlacementIdToDelegate objectForKey:rewardedVideoAd.placementID];
        
        [delegate adapterRewardedVideoDidOpen];
        [delegate adapterRewardedVideoDidStart];
        [delegate adapterRewardedVideoHasChangedAvailability:NO];
    }
}

/**
 Sent after an ad has been clicked by the person.
 @param rewardedVideoAd An FBRewardedVideoAd object sending the message.
 */
- (void)rewardedVideoAdDidClick:(FBRewardedVideoAd *)rewardedVideoAd {
    
    LogAdapterDelegate_Internal(@"rewardedVideoAd.placementID = %@", rewardedVideoAd.placementID);
    
    /* Get delegate for placement */
    if (rewardedVideoAd.placementID.length &&
        [_rewardedVideoPlacementIdToDelegate objectForKey:rewardedVideoAd.placementID]) {
        id<ISRewardedVideoAdapterDelegate> delegate = [_rewardedVideoPlacementIdToDelegate objectForKey:rewardedVideoAd.placementID];
        
        [delegate adapterRewardedVideoDidClick];
    }
}

/**
 Sent if server call to publisher's reward endpoint did not return HTTP status code 200
 or if the endpoint timed out.
 @param rewardedVideoAd An FBRewardedVideoAd object sending the message.
 */
- (void)rewardedVideoAdServerRewardDidFail:(FBRewardedVideoAd *)rewardedVideoAd {
    LogAdapterDelegate_Internal(@"rewardedVideoAd.placementID = %@", rewardedVideoAd.placementID);
}

/**
 Sent if server call to publisher's reward endpoint returned HTTP status code 200.
 @param rewardedVideoAd An FBRewardedVideoAd object sending the message.
 */
- (void)rewardedVideoAdServerRewardDidSucceed:(FBRewardedVideoAd *)rewardedVideoAd {
    LogAdapterDelegate_Internal(@"rewardedVideoAd.placementID = %@", rewardedVideoAd.placementID);
}

/**
 Sent after the FBRewardedVideoAd object has finished playing the video successfully.
 Reward the user on this callback.
 @param rewardedVideoAd An FBRewardedVideoAd object sending the message.
 */
- (void)rewardedVideoAdVideoComplete:(FBRewardedVideoAd *)rewardedVideoAd {
    
    LogAdapterDelegate_Internal(@"rewardedVideoAd.placementID = %@", rewardedVideoAd.placementID);
    /* Get delegate for placement */
    if (rewardedVideoAd.placementID.length &&
        [_rewardedVideoPlacementIdToDelegate objectForKey:rewardedVideoAd.placementID]) {
        id<ISRewardedVideoAdapterDelegate> delegate = [_rewardedVideoPlacementIdToDelegate objectForKey:rewardedVideoAd.placementID];
        
        [delegate adapterRewardedVideoDidReceiveReward];
        [delegate adapterRewardedVideoDidEnd];
    }
}

/**
 Sent immediately before an FBRewardedVideoAd object will be dismissed from the screen.
 @param rewardedVideoAd An FBRewardedVideoAd object sending the message.
 */
- (void)rewardedVideoAdWillClose:(FBRewardedVideoAd *)rewardedVideoAd {
    LogAdapterDelegate_Internal(@"rewardedVideoAd.placementID = %@", rewardedVideoAd.placementID);
}

/**
 Sent after an FBRewardedVideoAd object has been dismissed from the screen, returning control
 to your application.
 @param rewardedVideoAd An FBRewardedVideoAd object sending the message.
 */
- (void)rewardedVideoAdDidClose:(FBRewardedVideoAd *)rewardedVideoAd {
    
    LogAdapterDelegate_Internal(@"rewardedVideoAd.placementID = %@", rewardedVideoAd.placementID);
    
    /* Get delegate for placement */
    if (rewardedVideoAd.placementID.length &&
        [_rewardedVideoPlacementIdToDelegate objectForKey:rewardedVideoAd.placementID]) {
        id<ISRewardedVideoAdapterDelegate> delegate = [_rewardedVideoPlacementIdToDelegate objectForKey:rewardedVideoAd.placementID];
        
        [delegate adapterRewardedVideoDidClose];
    }
}

#pragma mark - Interstitial Delegate

/**
 Sent when an FBInterstitialAd failes to load an ad.
 @param interstitialAd An FBInterstitialAd object sending the message.
 @param error An error object containing details of the error.
 */
- (void)interstitialAd:(FBInterstitialAd *)interstitialAd
      didFailWithError:(NSError *)error {
    
    LogAdapterDelegate_Internal(@"interstitialAd.placementID = %@", interstitialAd.placementID);
    self.interstitialReady = NO;
    LogAdapterDelegate_Internal(@"error.description = %@", error.description);
    
    /* Get delegate for placement */
    if (interstitialAd.placementID.length &&
        [_interstitialPlacementIdToDelegate objectForKey:interstitialAd.placementID]) {
        id<ISInterstitialAdapterDelegate> delegate = [_interstitialPlacementIdToDelegate objectForKey:interstitialAd.placementID];
        
        NSError *smashError = nil;
        
        if (error.code == kErrorNoFillErrorCode) {
            smashError = [NSError errorWithDomain:kAdapterName
                                             code:ERROR_IS_LOAD_NO_FILL
                                         userInfo:@{NSLocalizedDescriptionKey : @"Facebook no fill"}];
        }
        else {
            smashError = error;
        }
        
        [delegate adapterInterstitialDidFailToLoadWithError:smashError];
    }
}

/**
 Sent when an FBInterstitialAd successfully loads an ad.
 @param interstitialAd An FBInterstitialAd object sending the message.
 */
- (void)interstitialAdDidLoad:(FBInterstitialAd *)interstitialAd {
    
    self.interstitialReady = YES;
    LogAdapterDelegate_Internal(@"interstitialAd.placementID = %@", interstitialAd.placementID);
    
    /* Get delegate for placement */
    if (interstitialAd.placementID.length &&
        [_interstitialPlacementIdToDelegate objectForKey:interstitialAd.placementID]) {
        id<ISInterstitialAdapterDelegate> delegate = [_interstitialPlacementIdToDelegate objectForKey:interstitialAd.placementID];
        
        [delegate adapterInterstitialDidLoad];
    }
}

/**
 Sent immediately before the impression of an FBInterstitialAd object will be logged.
 @param interstitialAd An FBInterstitialAd object sending the message.
 */
- (void)interstitialAdWillLogImpression:(FBInterstitialAd *)interstitialAd {
    
    LogAdapterDelegate_Internal(@"interstitialAd.placementID = %@", interstitialAd.placementID);
    
    /* Get delegate for placement */
    if (interstitialAd.placementID.length &&
        [_interstitialPlacementIdToDelegate objectForKey:interstitialAd.placementID]) {
        id<ISInterstitialAdapterDelegate> delegate = [_interstitialPlacementIdToDelegate objectForKey:interstitialAd.placementID];
        
        [delegate adapterInterstitialDidOpen];
        [delegate adapterInterstitialDidShow];
    }
}

/**
 Sent after an ad in the FBInterstitialAd object is clicked. The appropriate app store view or
 app browser will be launched.
 @param interstitialAd An FBInterstitialAd object sending the message.
 */
- (void)interstitialAdDidClick:(FBInterstitialAd *)interstitialAd {
    
    LogAdapterDelegate_Internal(@"interstitialAd.placementID = %@", interstitialAd.placementID);
    
    /* Get delegate for placement */
    if (interstitialAd.placementID.length &&
        [_interstitialPlacementIdToDelegate objectForKey:interstitialAd.placementID]) {
        id<ISInterstitialAdapterDelegate> delegate = [_interstitialPlacementIdToDelegate objectForKey:interstitialAd.placementID];
        
        [delegate adapterInterstitialDidClick];
    }
}

/**
 Sent immediately before an FBInterstitialAd object will be dismissed from the screen.
 @param interstitialAd An FBInterstitialAd object sending the message.
 */
- (void)interstitialAdWillClose:(FBInterstitialAd *)interstitialAd {
    
    LogAdapterDelegate_Internal(@"interstitialAd.placementID = %@", interstitialAd.placementID);
}

/**
 Sent after an FBInterstitialAd object has been dismissed from the screen, returning control
 to your application.
 @param interstitialAd An FBInterstitialAd object sending the message.
 */
- (void)interstitialAdDidClose:(FBInterstitialAd *)interstitialAd {
    
    LogAdapterDelegate_Internal(@"interstitialAd.placementID = %@", interstitialAd.placementID);
    
    /* Get delegate for placement */
    if (interstitialAd.placementID.length &&
        [_interstitialPlacementIdToDelegate objectForKey:interstitialAd.placementID]) {
        id<ISInterstitialAdapterDelegate> delegate = [_interstitialPlacementIdToDelegate objectForKey:interstitialAd.placementID];
        
        [delegate adapterInterstitialDidClose];
    }
}

#pragma mark - Private Methods

- (void)loadRewardedVideoAdWithPlacement:(NSString *)rewardedVideoPlacementId {
    
    [self loadRewardedVideoAdWithPlacement:rewardedVideoPlacementId serverData:nil];
}

- (void)loadRewardedVideoAdWithPlacement:(NSString *)rewardedVideoPlacementId
                              serverData:(NSString *)serverData {
    
    dispatch_async(dispatch_get_main_queue(), ^{
        @try {
            FBRewardedVideoAd *rewardedVideoAd = [[FBRewardedVideoAd alloc] initWithPlacementID:rewardedVideoPlacementId];
            rewardedVideoAd.delegate = self;
            [_rewardedVideoPlacementIdToAd setObject:rewardedVideoAd
                                              forKey:rewardedVideoPlacementId];
            
            LogAdapterApi_Internal(@"rewardedVideoPlacementId = %@", rewardedVideoPlacementId);
            
            //Auction will never return nil serverData (AdMarkup) for bidder
            if (serverData == nil) {
                [rewardedVideoAd loadAd];
            } else {
                [rewardedVideoAd loadAdWithBidPayload:serverData];
            }
            
        } @catch (NSException *exception) {
            LogAdapterApi_Internal(@"exception = %@", exception);
            id<ISRewardedVideoAdapterDelegate> delegate = [_rewardedVideoPlacementIdToDelegate objectForKey:rewardedVideoPlacementId];
            if (delegate) {
                [delegate adapterRewardedVideoHasChangedAvailability:NO];
            }
        }
    });
}

#pragma mark - private inner methods

- (void)initSDKWithAppId:(NSString *)appID
                  userId:(NSString *)userId
            placementIDs:(NSArray *)placementIDs {
    
    LogAdapterApi_Internal(@"");
    
    // add self to init delegates only
    // when init not finished yet
    if (_initState == INIT_STATE_NONE ||
        _initState == INIT_STATE_IN_PROGRESS) {
        [initCallbackDelegates addObject:self];
    }
    
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        if (_initState == INIT_STATE_NONE) {
            
            _initState = INIT_STATE_IN_PROGRESS;
            
            FBAdInitSettings *initSettings = [[FBAdInitSettings alloc] initWithPlacementIDs:placementIDs
                                                                           mediationService:[self getMediationServiceName]];
            
            LogAdapterApi_Internal(@"Initialize Facebook with placementIDs = %@", placementIDs);
            [FBAudienceNetworkAds initializeWithSettings:initSettings
                                       completionHandler:^(FBAdInitResults *results) {
                
                NSArray* initDelegatesList = initCallbackDelegates.allObjects;
                
                // set state
                _initState = results.success ? INIT_STATE_SUCCESS : INIT_STATE_ERROR;
                
                // call init callback delegate success
                for (id<ISNetworkInitCallbackProtocol> initDelegate in initDelegatesList) {
                    if(results.success){
                        [initDelegate onNetworkInitCallbackSuccess];
                    } else {
                        NSString *errorMessage = (results.message && results.message.length) ? results.message : @"Init Failed";
                        [initDelegate onNetworkInitCallbackFailed:errorMessage];
                    }
                }
                // remove all init callback delegates
                [initCallbackDelegates removeAllObjects];
            }];
        }
    });
}

- (void)onNetworkInitCallbackSuccess {
    
    LogAdapterDelegate_Internal(@"");
    
    // banner
    NSArray *bannerPlacementIDs = _bannerPlacementIdToDelegate.allKeys;
    
    for (NSString *placementId in bannerPlacementIDs) {
        id<ISBannerAdapterDelegate> delegate = [_bannerPlacementIdToDelegate objectForKey:placementId];
        LogAdapterApi_Internal(@"adapterBannerInitSuccess");
        [delegate adapterBannerInitSuccess];
    }
    
    // interstitial
    NSArray *interstitialPlacementIDs = _interstitialPlacementIdToDelegate.allKeys;
    
    for (NSString *placementId in interstitialPlacementIDs) {
        id<ISInterstitialAdapterDelegate> delegate = [_interstitialPlacementIdToDelegate objectForKey:placementId];
        LogAdapterApi_Internal(@"adapterInterstitialInitSuccess");
        [delegate adapterInterstitialInitSuccess];
    }
    
    // rewarded video
    NSArray *rewardedVideoPlacementIDs = _rewardedVideoPlacementIdToDelegate.allKeys;
    
    for (NSString * placementId in rewardedVideoPlacementIDs) {
        id<ISRewardedVideoAdapterDelegate> delegate = [_rewardedVideoPlacementIdToDelegate objectForKey:placementId];
        if ([_programmaticPlacementIds hasObject:placementId]) {
            LogAdapterApi_Internal(@"adapterRewardedVideoInitSuccess - placementId = %@", placementId);
            [delegate adapterRewardedVideoInitSuccess];
        }
        else {
            LogAdapterApi_Internal(@"loadVideoInternal - placementId = %@", placementId);
            [self loadRewardedVideoAdWithPlacement:placementId];
        }
    }
}

- (void)onNetworkInitCallbackFailed:(NSString *)errorMessage {
    
    LogAdapterDelegate_Internal(@"errorMessage = %@", errorMessage);
    NSError *error = [NSError errorWithDomain:kAdapterName
                                         code:ERROR_CODE_INIT_FAILED
                                     userInfo:@{NSLocalizedDescriptionKey:errorMessage}];
    
    // banner
    NSArray *bannerPlacementIDs = _bannerPlacementIdToDelegate.allKeys;
    
    for (NSString *placementId in bannerPlacementIDs) {
        id<ISBannerAdapterDelegate> delegate = [_bannerPlacementIdToDelegate objectForKey:placementId];
        LogAdapterApi_Internal(@"adapterBannerInitFailedWithError - error = %@", error);
        [delegate adapterBannerInitFailedWithError:error];
    }
    
    // interstitial
    NSArray *interstitialPlacementIDs = _interstitialPlacementIdToDelegate.allKeys;
    
    for (NSString *placementId in interstitialPlacementIDs) {
        id<ISInterstitialAdapterDelegate> delegate = [_interstitialPlacementIdToDelegate objectForKey:placementId];
        LogAdapterApi_Internal(@"adapterInterstitialInitFailedWithError - error = %@", error);
        [delegate adapterInterstitialInitFailedWithError:error];
    }
    
    // rewarded video
    NSArray *rewardedVideoPlacementIDs = _rewardedVideoPlacementIdToDelegate.allKeys;
    
    for (NSString * placementId in rewardedVideoPlacementIDs) {
        id<ISRewardedVideoAdapterDelegate> delegate = [_rewardedVideoPlacementIdToDelegate objectForKey:placementId];
        if ([_programmaticPlacementIds hasObject:placementId]) {
            LogAdapterApi_Internal(@"adapterRewardedVideoInitFailed - error = %@", error);
            [delegate adapterRewardedVideoInitFailed:error];
        }
        else {
            LogAdapterApi_Internal(@"adapterRewardedVideoHasChangedAvailability:NO");
            [delegate adapterRewardedVideoHasChangedAvailability:NO];
        }
    }
}

- (NSDictionary *)getBiddingData {
    if (_initState == INIT_STATE_ERROR) {
        LogAdapterApi_Internal(@"returning nil as token since init failed");
        return nil;
    }
    
    NSString *bidderToken = [FBAdSettings bidderToken];
    NSString *returnedToken = bidderToken ? bidderToken : @"";
    LogAdapterApi_Internal(@"token = %@", returnedToken);
    
    return @{@"token": returnedToken};
}

- (NSString *)getMediationServiceName {
    
    NSString * result = [NSString stringWithFormat:@"%@_%@:%@", kMediationService, MEDIATION_VERSION, kAdapterVersion];
    LogAdapterApi_Internal(@"result = %@", result);
    
    return result;
}

- (NSError *)errorForUnsupportedAdapter:(NSString *)adUnit {
    
    LogAdapterApi_Internal(@"adUnit = %@", adUnit);
    NSString *desc = [NSString stringWithFormat:@"init failed due to unsupported OS version for %@ %@", [self adapterName], adUnit];
    NSError *error = [NSError errorWithDomain:kAdapterName
                                         code:kUnsupportedAdapterErrorCode
                                     userInfo:@{NSLocalizedDescriptionKey:desc}];
    
    return error;
}

- (NSError *)errorForAd:(NSException *) exception withCode:(NSInteger)code {
    
    NSMutableDictionary* info = [NSMutableDictionary dictionary];
    info[@"ExceptionName"] = exception.name;
    info[@"ExceptionReason"] = exception.reason;
    
    NSError *error = [NSError errorWithDomain:kAdapterName
                                         code:code
                                     userInfo:info];
    
    return error;
}

- (BOOL) isSupported {
    BOOL isSupported = NO;
    
    @try {
        if (SYSTEM_VERSION_GREATER_THAN_OR_EQUAL_TO(@"9.0")) {
            isSupported = YES;
        }
    } @catch (NSException * e) {
        NSLog(@"Exception: %@", e);
    }
    
    return isSupported;
}

- (BOOL) isBannerSizeSupported:(ISBannerSize *)size {
    if ([size.sizeDescription isEqualToString:@"BANNER"]) {
        return YES;
    }
    else if ([size.sizeDescription isEqualToString:@"LARGE"]) {
        return YES;
    }
    else if ([size.sizeDescription isEqualToString:@"RECTANGLE"]) {
        return YES;
    }
    else if ([size.sizeDescription isEqualToString:@"SMART"]) {
        return YES;
    }
    
    return NO;
}

- (FBAdSize)getBannerSize:(ISBannerSize *)size {
    // Initing the banner size so it will have a default value. Since FBAdSize doesn't support CGSizeZero we used the default banner size isntead
    FBAdSize fbSize = kFBAdSizeHeight50Banner;
    
    if ([size.sizeDescription isEqualToString:@"BANNER"] || size.height == 50) {
        fbSize = kFBAdSizeHeight50Banner;
    }
    else if ([size.sizeDescription isEqualToString:@"LARGE"] || size.height == 90) {
        fbSize = kFBAdSizeHeight90Banner;
    }
    else if ([size.sizeDescription isEqualToString:@"RECTANGLE"] || size.height == 250) {
        fbSize = kFBAdSizeHeight250Rectangle;
    }
    else if ([size.sizeDescription isEqualToString:@"SMART"]) {
        if (UI_USER_INTERFACE_IDIOM() == UIUserInterfaceIdiomPad) {
            fbSize = kFBAdSizeHeight90Banner;
        }
        else {
            fbSize = kFBAdSizeHeight50Banner;
        }
    }
    
    return fbSize;
}

- (CGRect)getBannerRect:(ISBannerSize *)size {
    
    if ([size.sizeDescription isEqualToString:@"BANNER"] || size.height == 50) {
        return CGRectMake(0, 0, 320, 50);
    }
    else if ([size.sizeDescription isEqualToString:@"LARGE"] || size.height == 90) {
        return CGRectMake(0, 0, 320, 90);
    }
    else if ([size.sizeDescription isEqualToString:@"RECTANGLE"] || size.height == 250) {
        return CGRectMake(0, 0, 300, 250);
    }
    else if ([size.sizeDescription isEqualToString:@"SMART"]) {
        if (UI_USER_INTERFACE_IDIOM() == UIUserInterfaceIdiomPad) {
            return CGRectMake(0, 0, 728, 90);
        }
        else {
            return CGRectMake(0, 0, 320, 50);
        }
    }
    
    return CGRectMake(0, 0, 0, 0);
}

@end
