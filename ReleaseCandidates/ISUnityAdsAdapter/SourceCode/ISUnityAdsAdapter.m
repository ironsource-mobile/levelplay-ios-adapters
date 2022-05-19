//
//  ISUnityAdsAdapter.m
//  ISUnityAdsAdapter
//
//  Created by Clementine on 2/4/15.
//  Copyright (c) 2015 Clementine. All rights reserved.
//

#import "ISUnityAdsAdapter.h"
#import "ISUnityAdsBannerListener.h"
#import "ISUnityAdsInterstitialListener.h"
#import "ISUnityAdsRewardedVideoListener.h"
#import <UnityAds/UnityAds.h>
#import "IronSource/ISGlobals.h"

static NSString * const kAdapterVersion         = UnityAdsAdapterVersion;
static NSString * const kSourceId               = @"sourceId";
static NSString * const kPlacementId            = @"zoneId";
static NSString * const kAdapterName            = @"UnityAds";
static NSString * const kIsAsyncTokenEnabled    = @"isAsyncTokenEnabled";

static NSString * const kMetaDataCOPPAKey   = @"unityads_coppa";
static NSString * const kCCPAUnityAdsFlag   = @"privacy.consent";
static NSString * const kGDPRUnityAdsFlag   = @"gdpr.consent";
static NSString * const kCOPPAUnityAdsFlag  = @"user.nonBehavioral";

static NSString * const kIsLWSSupported     = @"isSupportedLWS";

typedef NS_ENUM(NSInteger, InitState) {
    INIT_STATE_NONE,
    INIT_STATE_IN_PROGRESS,
    INIT_STATE_FAILED,
    INIT_STATE_SUCCESS
};

#define ISAdapterStateString(enum) [@[@"INIT_STATE_NONE",@"INIT_STATE_IN_PROGRESS",@"INIT_STATE_FAILED",@"INIT_STATE_SUCCESS"] objectAtIndex:enum]

static InitState _initState = INIT_STATE_NONE;

static ConcurrentMutableSet<ISNetworkInitCallbackProtocol> *initCallbackDelegates = nil;

static NSString *asyncToken = nil;

@interface ISUnityAdsAdapter () <UnityAdsInitializationDelegate, ISNetworkInitCallbackProtocol, ISUnityAdsBannerDelegateWrapper, ISUnityAdsInterstitialDelegateWrapper, ISUnityAdsRewardedVideoDelegateWrapper>

// Rewrded video
@property (nonatomic, strong) ConcurrentMutableDictionary *placementIdToRewardedVideoSmashDelegate;
@property (nonatomic, strong) ConcurrentMutableDictionary *placementIdToRewardedVideoObjectId;
@property (nonatomic, strong) ConcurrentMutableDictionary *placementIdToRewardedVideoListener;
@property (nonatomic, strong) ConcurrentMutableDictionary *rewardedVideoAdsAvailability;
@property (nonatomic, strong) ConcurrentMutableSet        *rewardedVideoPlacementsForInitCallbacks;

// Interstitial
@property (nonatomic, strong) ConcurrentMutableDictionary *placementIdToInterstitialSmashDelegate;
@property (nonatomic, strong) ConcurrentMutableDictionary *placementIdToInterstitialObjectId;
@property (nonatomic, strong) ConcurrentMutableDictionary *placementIdToInterstitialListener;
@property (nonatomic, strong) ConcurrentMutableDictionary *interstitialAdsAvailability;

// Banner
@property (nonatomic, strong) ConcurrentMutableDictionary *placementIdToBannerSmashDelegate;
@property (nonatomic, strong) ConcurrentMutableDictionary *placementIdToBannerListener;
@property (nonatomic, strong) ConcurrentMutableDictionary *placementIdToBannerAd;
@property (nonatomic, strong) ConcurrentMutableDictionary *placementIdToBannerSize;

// synchronization lock
@property (nonatomic, strong) NSObject                    *UnityAdsStorageLock;

@end

@implementation ISUnityAdsAdapter

#pragma mark - Initialization Methods

- (instancetype) initAdapter:(NSString *)name {
    self = [super initAdapter:name];
    
    if (self) {
        if (initCallbackDelegates == nil) {
            initCallbackDelegates = [ConcurrentMutableSet<ISNetworkInitCallbackProtocol> set];
        }
        
        _placementIdToRewardedVideoSmashDelegate = [ConcurrentMutableDictionary dictionary];
        _placementIdToRewardedVideoObjectId = [ConcurrentMutableDictionary dictionary];
        _placementIdToRewardedVideoListener = [ConcurrentMutableDictionary dictionary];
        _rewardedVideoAdsAvailability = [ConcurrentMutableDictionary dictionary];
        _rewardedVideoPlacementsForInitCallbacks = [ConcurrentMutableSet set];
        
        _placementIdToInterstitialSmashDelegate = [ConcurrentMutableDictionary dictionary];
        _placementIdToInterstitialObjectId = [ConcurrentMutableDictionary dictionary];
        _placementIdToInterstitialListener = [ConcurrentMutableDictionary dictionary];
        _interstitialAdsAvailability = [ConcurrentMutableDictionary dictionary];
        
        _placementIdToBannerSmashDelegate = [ConcurrentMutableDictionary dictionary];
        _placementIdToBannerListener = [ConcurrentMutableDictionary dictionary];
        _placementIdToBannerAd = [ConcurrentMutableDictionary dictionary];
        _placementIdToBannerSize = [ConcurrentMutableDictionary dictionary];
        
        _UnityAdsStorageLock = [NSObject new];
    }
    
    return self;
}

#pragma mark - IronSource Protocol Methods

- (NSString *) sdkVersion {
    return [UnityAds getVersion];
}

- (NSString *) version {
    return kAdapterVersion;
}

- (NSArray *) systemFrameworks {
    return @[@"AdSupport", @"CoreTelephony", @"StoreKit"];
}
    
- (NSString *) sdkName {
    return kAdapterName;
}

- (void) setMetaDataWithKey:(NSString *)key
                  andValues:(NSMutableArray *)values {
    if (values.count == 0) {
        return;
    }
    
    NSString *value = values[0];
    LogAdapterApi_Internal(@"setMetaData: key=%@, value=%@", key, value);
    
    if ([ISMetaDataUtils isValidCCPAMetaDataWithKey:key andValue:value]) {
        [self setCCPAValue:[ISMetaDataUtils getCCPABooleanValue:value]];
    } else {
        NSString *formattedValue = [ISMetaDataUtils formatValue:value forType:(META_DATA_VALUE_BOOL)];
        
        if ([self isValidCOPPAMetaDataWithKey:key andValue:formattedValue]) {
            [self setCOPPAValue:[ISMetaDataUtils getCCPABooleanValue:formattedValue]];
        }
    }
}

- (void) setCCPAValue:(BOOL)value {
    // The UnityAds CCPA API expects an indication if the user opts in to targeted advertising.
    // Given that this is opposite to the ironSource Mediation CCPA flag of do_not_sell
    // we will use the opposite value of what is passed to this method
    BOOL optIn = !value;
    [self setUnityAdsMetaDataWithKey:kCCPAUnityAdsFlag value:optIn];
}

- (void) setCOPPAValue:(BOOL)value {
    [self setUnityAdsMetaDataWithKey:kCOPPAUnityAdsFlag value:value];
}

- (void) setConsent:(BOOL)consent {
    [self setUnityAdsMetaDataWithKey:kGDPRUnityAdsFlag value:consent];
}

- (void) setUnityAdsMetaDataWithKey:(NSString *)key
                              value:(BOOL)value {
    LogAdapterApi_Internal(@"key = %@, value = %@", key, value? @"YES" : @"NO");
    
    @synchronized (_UnityAdsStorageLock) {
        /* (10/9/19) The synchronized statement below is important and cannot be removed.
           This is the way UnityAds work and currently they have no plans to change that.
           If two threads reach the consent block simultaneously the app will crash.
           For more details see Jira ticket PS-9511 */
        
        UADSMetaData *unityAdsMetaData = [[UADSMetaData alloc] init];
        [unityAdsMetaData set:key value:value ? @YES : @NO];
        [unityAdsMetaData commit];
    }
}
    
#pragma mark - Rewarded Video API

- (NSDictionary *) getRewardedVideoBiddingDataWithAdapterConfig:(ISAdapterConfig *)adapterConfig {
    LogAdapterApi_Internal(@"");
    return [self getBiddingData];
}

- (void) initRewardedVideoForCallbacksWithUserId:(NSString *)userId
                                   adapterConfig:(ISAdapterConfig *)adapterConfig
                                        delegate:(id<ISRewardedVideoAdapterDelegate>)delegate {
    NSString *sourceId = adapterConfig.settings[kSourceId];
    NSString *placementId = adapterConfig.settings[kPlacementId];

    // Configuration Validation
    if (![self isConfigValueValid:sourceId]) {
        NSError *error = [self errorForMissingCredentialFieldWithName:kSourceId];
        LogAdapterApi_Internal(@"error = %@", error);
        [delegate adapterRewardedVideoInitFailed:error];
        return;
    }
    
    if (![self isConfigValueValid:placementId]) {
        NSError *error = [self errorForMissingCredentialFieldWithName:kPlacementId];
        LogAdapterApi_Internal(@"error = %@", error);
        [delegate adapterRewardedVideoInitFailed:error];
        return;
    }
    
    LogAdapterApi_Internal(@"placementId = %@", placementId);
    
    // Register Delegate for placement
    [_placementIdToRewardedVideoSmashDelegate setObject:delegate forKey:placementId];
    
    // Create rewarded video listener
    ISUnityAdsRewardedVideoListener *rewardedVideoListener = [[ISUnityAdsRewardedVideoListener alloc] initWithPlacementId:placementId andDelegate:self];
    [_placementIdToRewardedVideoListener setObject:rewardedVideoListener forKey:placementId];
    
    // Register to programmatic RV
    [_rewardedVideoPlacementsForInitCallbacks addObject:placementId];
    
    switch (_initState) {
        case INIT_STATE_NONE:
        case INIT_STATE_IN_PROGRESS:
            [self initWithSourceId:sourceId adapterConfig:adapterConfig];
            break;
        case INIT_STATE_FAILED:
            [delegate adapterRewardedVideoInitFailed:[NSError errorWithDomain:kAdapterName code:ERROR_CODE_INIT_FAILED userInfo:@{NSLocalizedDescriptionKey:@"UnityAds SDK init failed"}]];
            break;
        case INIT_STATE_SUCCESS:
            [delegate adapterRewardedVideoInitSuccess];
            break;
    }
}

- (void) initAndLoadRewardedVideoWithUserId:(NSString *)userId
                              adapterConfig:(ISAdapterConfig *)adapterConfig
                                   delegate:(id<ISRewardedVideoAdapterDelegate>)delegate {
    NSString *sourceId = adapterConfig.settings[kSourceId];
    NSString *placementId = adapterConfig.settings[kPlacementId];

    // Configuration Validation
    if (![self isConfigValueValid:sourceId]) {
        NSError *error = [self errorForMissingCredentialFieldWithName:kSourceId];
        LogAdapterApi_Internal(@"error = %@", error);
        [delegate adapterRewardedVideoHasChangedAvailability:NO];
        return;
    }
    
    if (![self isConfigValueValid:placementId]) {
        NSError *error = [self errorForMissingCredentialFieldWithName:kPlacementId];
        LogAdapterApi_Internal(@"error = %@", error);
        [delegate adapterRewardedVideoHasChangedAvailability:NO];
        return;
    }
    
    LogAdapterApi_Internal(@"placementId = %@", placementId);
    
    // Register Delegate for placement
    [_placementIdToRewardedVideoSmashDelegate setObject:delegate forKey:placementId];
    
    // Create rewarded video listener
    ISUnityAdsRewardedVideoListener *rewardedVideoListener = [[ISUnityAdsRewardedVideoListener alloc] initWithPlacementId:placementId andDelegate:self];
    [_placementIdToRewardedVideoListener setObject:rewardedVideoListener forKey:placementId];
    
    switch (_initState) {
        case INIT_STATE_NONE:
        case INIT_STATE_IN_PROGRESS:
            [self initWithSourceId:sourceId adapterConfig:adapterConfig];
            break;
        case INIT_STATE_FAILED:
            [delegate adapterRewardedVideoHasChangedAvailability:NO];
            break;
        case INIT_STATE_SUCCESS:
            [self loadRewardedVideo:placementId];
            break;
    }
}

- (void) fetchRewardedVideoForAutomaticLoadWithAdapterConfig:(ISAdapterConfig *)adapterConfig
                                                    delegate:(id<ISRewardedVideoAdapterDelegate>)delegate {
    NSString *placementId = adapterConfig.settings[kPlacementId];
    LogAdapterApi_Internal(@"placementId = %@", placementId);
    [self loadRewardedVideo:placementId];
}

- (void) loadRewardedVideo:(NSString *)placementId {
    LogAdapterApi_Internal(@"placementId = %@", placementId);
    [_rewardedVideoAdsAvailability setObject:@NO forKey:placementId];
    [UnityAds load:placementId loadDelegate:[_placementIdToRewardedVideoListener objectForKey:placementId]];
}

//Load rewarded video for bidding
- (void) loadRewardedVideoForBiddingWithAdapterConfig:(ISAdapterConfig *)adapterConfig
                                           serverData:(NSString *)serverData
                                             delegate:(id<ISRewardedVideoAdapterDelegate>)delegate{
    NSString *placementId = adapterConfig.settings[kPlacementId];
    LogAdapterApi_Internal(@"placementId = %@", placementId);
    
    UADSLoadOptions *options = [UADSLoadOptions new];
    NSString *objectId = [[NSUUID UUID] UUIDString];
    [options setObjectId:objectId];
    [options setAdMarkup:serverData];
    [_placementIdToRewardedVideoObjectId setObject:objectId forKey:placementId];
    
    [_rewardedVideoAdsAvailability setObject:@NO forKey:placementId];
    [UnityAds load:placementId options:options loadDelegate:[_placementIdToRewardedVideoListener objectForKey:placementId]];
}

- (BOOL) hasRewardedVideoWithAdapterConfig:(ISAdapterConfig *)adapterConfig {
    NSString *placementId = adapterConfig.settings[kPlacementId];
    NSNumber *available = [_rewardedVideoAdsAvailability objectForKey:placementId];
    return (available != nil) && [available boolValue];
}

- (void) showRewardedVideoWithViewController:(UIViewController *)viewController
                               adapterConfig:(ISAdapterConfig *)adapterConfig
                                    delegate:(id<ISRewardedVideoAdapterDelegate>)delegate {
    NSString *placementId = adapterConfig.settings[kPlacementId];
    LogAdapterApi_Internal(@"placementId = %@", placementId);
    
    if (![self hasRewardedVideoWithAdapterConfig:adapterConfig]) {
        NSError *error = [ISError createError:ERROR_CODE_NO_ADS_TO_SHOW withMessage:[NSString stringWithFormat: @"%@ show failed", kAdapterName]];
        LogAdapterApi_Internal(@"error = %@", error);
        [delegate adapterRewardedVideoDidFailToShowWithError:error];
        return;
    }
    
    [self.dispatcher dispatchAsyncWithQueue:dispatch_get_main_queue() withBlock:^{
        @try {
            if ([self dynamicUserId]) {
                @synchronized (_UnityAdsStorageLock) {
                    id playerMetaData = [[UADSPlayerMetaData alloc] init];
                    [playerMetaData setServerId:[self dynamicUserId]];
                    [playerMetaData commit];
                }
            }
            
            UIViewController *vc = viewController == nil ? [self topMostController] : viewController;
            id<UnityAdsShowDelegate>showDelegate = [_placementIdToRewardedVideoListener objectForKey:placementId];;
            
            if ([_placementIdToRewardedVideoObjectId hasObjectForKey:placementId]) {
                UADSShowOptions *options = [UADSShowOptions new];
                [options setObjectId:[_placementIdToRewardedVideoObjectId objectForKey:placementId]];
                [UnityAds show:vc placementId:placementId options:options showDelegate:showDelegate];
            } else {
                [UnityAds show:vc placementId:placementId showDelegate:showDelegate];
            }
        }
        @catch (NSException *exception) {
            NSString *message = [NSString stringWithFormat:@"ISUnityAdsAdapter: Exception while trying to show an RV ad. Description: '%@'", exception.description];
            LogAdapterApi_Internal(@"message = %@", message);
            NSError *showError = [NSError errorWithDomain:kAdapterName code:ERROR_CODE_NO_ADS_TO_SHOW userInfo:@{NSLocalizedDescriptionKey: message}];
            [delegate adapterRewardedVideoDidFailToShowWithError:showError];
        }
        
        [_rewardedVideoAdsAvailability setObject:@NO forKey:placementId];
        [delegate adapterRewardedVideoHasChangedAvailability:NO];
    }];
}

#pragma mark - Interstitial API

- (NSDictionary *) getInterstitialBiddingDataWithAdapterConfig:(ISAdapterConfig *)adapterConfig {
    LogAdapterApi_Internal(@"");
    return [self getBiddingData];
}

- (void) initInterstitialForBiddingWithUserId:(NSString *)userId
                                adapterConfig:(ISAdapterConfig *)adapterConfig
                                     delegate:(id<ISInterstitialAdapterDelegate>)delegate {
    LogAdapterApi_Internal(@"");
    [self initInterstitialWithUserId:userId adapterConfig:adapterConfig delegate:delegate];
}

- (void) initInterstitialWithUserId:(NSString *)userId adapterConfig:(ISAdapterConfig *)adapterConfig delegate:(id<ISInterstitialAdapterDelegate>)delegate {
    NSString *sourceId = adapterConfig.settings[kSourceId];
    NSString *placementId = adapterConfig.settings[kPlacementId];
    
    // Configuration Validation
    if (![self isConfigValueValid:sourceId]) {
        NSError *error = [self errorForMissingCredentialFieldWithName:kSourceId];
        LogAdapterApi_Internal(@"error = %@", error);
        [delegate adapterInterstitialInitFailedWithError:error];
        return;
    }
    
    if (![self isConfigValueValid:placementId]) {
        NSError *error = [self errorForMissingCredentialFieldWithName:kPlacementId];
        LogAdapterApi_Internal(@"error = %@", error);
        [delegate adapterInterstitialInitFailedWithError:error];
        return;
    }
    
    LogAdapterApi_Internal(@"placementId = %@", placementId);
    
    // Register Delegate for placement
    [_placementIdToInterstitialSmashDelegate setObject:delegate forKey:placementId];
    
    // Create interstitial listener
    ISUnityAdsInterstitialListener *interstitialListener = [[ISUnityAdsInterstitialListener alloc] initWithPlacementId:placementId andDelegate:self];
    [_placementIdToInterstitialListener setObject:interstitialListener forKey:placementId];
    
    switch (_initState) {
        case INIT_STATE_NONE:
        case INIT_STATE_IN_PROGRESS:
            [self initWithSourceId:sourceId adapterConfig:adapterConfig];
            break;
        case INIT_STATE_FAILED:
            [delegate adapterInterstitialInitFailedWithError:[NSError errorWithDomain:kAdapterName code:ERROR_CODE_INIT_FAILED userInfo:@{NSLocalizedDescriptionKey:@"UnityAds SDK init failed"}]];
            break;
        case INIT_STATE_SUCCESS:
            [delegate adapterInterstitialInitSuccess];
            break;
    }
}

- (void) loadInterstitialWithAdapterConfig:(ISAdapterConfig *)adapterConfig delegate:(id<ISInterstitialAdapterDelegate>)delegate {
    NSString *placementId = adapterConfig.settings[kPlacementId];
    LogAdapterApi_Internal(@"placementId = %@", placementId);
    [_interstitialAdsAvailability setObject:@NO forKey:placementId];
    [UnityAds load:placementId loadDelegate:[_placementIdToInterstitialListener objectForKey:placementId]];
}

- (void) loadInterstitialForBiddingWithServerData:(NSString *)serverData
                                    adapterConfig:(ISAdapterConfig *)adapterConfig
                                         delegate:(id<ISInterstitialAdapterDelegate>)delegate {
    NSString *placementId = adapterConfig.settings[kPlacementId];
    LogAdapterApi_Internal(@"placementId = %@", placementId);
    
    UADSLoadOptions *options = [UADSLoadOptions new];
    NSString *objectId = [[NSUUID UUID] UUIDString];
    [options setObjectId:objectId];
    [options setAdMarkup:serverData];
    [_placementIdToInterstitialObjectId setObject:objectId forKey:placementId];
    
    [_interstitialAdsAvailability setObject:@NO forKey:placementId];
    [UnityAds load:placementId options:options loadDelegate:[_placementIdToInterstitialListener objectForKey:placementId]];
}

- (BOOL) hasInterstitialWithAdapterConfig:(ISAdapterConfig *)adapterConfig {
    NSString *placementId = adapterConfig.settings[kPlacementId];
    NSNumber *available = [_interstitialAdsAvailability objectForKey:placementId];
    return (available != nil) && [available boolValue];
}

- (void) showInterstitialWithViewController:(UIViewController *)viewController
                              adapterConfig:(ISAdapterConfig *)adapterConfig
                                   delegate:(id<ISInterstitialAdapterDelegate>)delegate {
    NSString *placementId = adapterConfig.settings[kPlacementId];
    LogAdapterApi_Internal(@"placementId = %@", placementId);
    
    if (![self hasInterstitialWithAdapterConfig:adapterConfig]) {
        NSError *error = [ISError createError:ERROR_CODE_NO_ADS_TO_SHOW withMessage:[NSString stringWithFormat: @"%@ show failed", kAdapterName]];
        LogAdapterApi_Internal(@"error = %@", error);
        [delegate adapterInterstitialDidFailToShowWithError:error];
        return;
    }
    
    [self.dispatcher dispatchAsyncWithQueue:dispatch_get_main_queue() withBlock:^{
        @try {
            if ([self dynamicUserId]) {
                @synchronized (_UnityAdsStorageLock) {
                    id playerMetaData = [[UADSPlayerMetaData alloc] init];
                    [playerMetaData setServerId:[self dynamicUserId]];
                    [playerMetaData commit];
                }
            }
            
            UIViewController *vc = viewController == nil ? [self topMostController] : viewController;
            id<UnityAdsShowDelegate>showDelegate = [_placementIdToInterstitialListener objectForKey:placementId];;
            
            if ([_placementIdToInterstitialObjectId hasObjectForKey:placementId]) {
                UADSShowOptions *options = [UADSShowOptions new];
                [options setObjectId:[_placementIdToInterstitialObjectId objectForKey:placementId]];
                [UnityAds show:vc placementId:placementId options:options showDelegate:showDelegate];
            } else {
                [UnityAds show:vc placementId:placementId showDelegate:showDelegate];
            }
        }
        @catch (NSException *exception) {
            NSString *message = [NSString stringWithFormat:@"ISUnityAdsAdapter: Exception while trying to show an interstitial ad. Description: '%@'", exception.description];
            LogAdapterApi_Internal(@"message = %@", message);
            NSError *showError = [NSError errorWithDomain:kAdapterName code:ERROR_CODE_NO_ADS_TO_SHOW userInfo:@{NSLocalizedDescriptionKey: message}];
            [delegate adapterInterstitialDidFailToShowWithError:showError];
        }
        
        [_interstitialAdsAvailability setObject:@NO forKey:placementId];
    }];
}

#pragma mark - Banner API

- (void) initBannerWithUserId:(nonnull NSString *)userId
                adapterConfig:(nonnull ISAdapterConfig *)adapterConfig
                     delegate:(nonnull id<ISBannerAdapterDelegate>)delegate {
    // Get data
    NSString *sourceId = adapterConfig.settings[kSourceId];
    NSString *placementId = adapterConfig.settings[kPlacementId];
    
    // Configuration validation
    if (![self isConfigValueValid:sourceId]) {
        NSError *error = [self errorForMissingCredentialFieldWithName:kSourceId];
        LogAdapterApi_Internal(@"error = %@", error);
        [delegate adapterBannerInitFailedWithError:error];
        return;
    }
    
    if (![self isConfigValueValid:placementId]) {
        NSError *error = [self errorForMissingCredentialFieldWithName:kPlacementId];
        LogAdapterApi_Internal(@"error = %@", error);
        [delegate adapterBannerInitFailedWithError:error];
        return;
    }
    
    LogAdapterApi_Internal(@"placementId = %@", placementId);
    
    // Add to dictionary
    [_placementIdToBannerSmashDelegate setObject:delegate forKey:placementId];
    
    // Create banner listener
    ISUnityAdsBannerListener *bannerListener = [[ISUnityAdsBannerListener alloc] initWithDelegate:self];
    [_placementIdToBannerListener setObject:bannerListener forKey:placementId];
    
    switch (_initState) {
        case INIT_STATE_NONE:
        case INIT_STATE_IN_PROGRESS:
            [self initWithSourceId:sourceId adapterConfig:adapterConfig];
            break;
        case INIT_STATE_FAILED:
            [delegate adapterBannerInitFailedWithError:[NSError errorWithDomain:kAdapterName code:ERROR_CODE_INIT_FAILED userInfo:@{NSLocalizedDescriptionKey:@"UnityAds SDK init failed"}]];
            break;
        case INIT_STATE_SUCCESS:
            [delegate adapterBannerInitSuccess];
            break;
    }
}

- (void) loadBannerWithViewController:(nonnull UIViewController *)viewController
                                 size:(ISBannerSize *)size
                        adapterConfig:(nonnull ISAdapterConfig *)adapterConfig
                             delegate:(nonnull id <ISBannerAdapterDelegate>)delegate {
    // Placement
    NSString *placementId = adapterConfig.settings[kPlacementId];
    
    if (![self isConfigValueValid:placementId]) {
        NSError *error = [self errorForMissingCredentialFieldWithName:kPlacementId];
        LogAdapterApi_Internal(@"error = %@", error);
        [delegate adapterBannerDidFailToLoadWithError:error];
        return;
    }
    
    // Verify size
    if (![self isBannerSizeSupported:size]) {
        NSError *error = [ISError createError:ERROR_BN_UNSUPPORTED_SIZE withMessage:[NSString stringWithFormat:@"UnityAds unsupported banner size - %@", size.sizeDescription]];
        LogAdapterApi_Internal(@"error = %@", error);
        [delegate adapterBannerDidFailToLoadWithError:error];
        return;
    }
    
    LogAdapterApi_Internal(@"placementId = %@", placementId);
    
    // Banner size
    [_placementIdToBannerSize setObject:size forKey:placementId];
    
    [self loadBannerViewWithPlacementId:placementId
                                   size:size
                               delegate:delegate];
}

- (void) reloadBannerWithAdapterConfig:(nonnull ISAdapterConfig *)adapterConfig
                              delegate:(nonnull id <ISBannerAdapterDelegate>)delegate {
    // Placement
    NSString *placementId = adapterConfig.settings[kPlacementId];
    
    if (![self isConfigValueValid:placementId]) {
        NSError *error = [self errorForMissingCredentialFieldWithName:kPlacementId];
        LogAdapterApi_Internal(@"error = %@", error);
        [delegate adapterBannerDidFailToLoadWithError:error];
        return;
    }
    
    LogAdapterApi_Internal(@"placementId = %@", placementId);
    
    [self loadBannerViewWithPlacementId:placementId
                                   size:[_placementIdToBannerSize objectForKey:placementId]
                               delegate:delegate];
}

- (void) loadBannerViewWithPlacementId:(NSString *)placementId
                                  size:(ISBannerSize *)size
                              delegate:(nonnull id <ISBannerAdapterDelegate>)delegate {
    [self.dispatcher dispatchAsyncWithQueue:dispatch_get_main_queue() withBlock:^{
        @try {
            // Create banner
            UADSBannerView *bannerView = [[UADSBannerView alloc] initWithPlacementId:placementId size:[self getBannerSize:size]];
            
            // Add to ad dictionary
            [_placementIdToBannerAd setObject:bannerView forKey:placementId];
            
            // Set delegate
            bannerView.delegate = [_placementIdToBannerListener objectForKey:placementId];
            
            // Load banner
            [bannerView load];
        } @catch (NSException *exception) {
            NSString *message = [NSString stringWithFormat:@"ISUnityAdsAdapter: Exception while trying to load a banner ad. Description: '%@'", exception.description];
            LogAdapterApi_Internal(@"message = %@", message);
            id<ISBannerAdapterDelegate> delegate = [_placementIdToBannerSmashDelegate objectForKey:placementId];
            NSError *smashError = [NSError errorWithDomain:kAdapterName code:ERROR_CODE_GENERIC userInfo:@{NSLocalizedDescriptionKey:message}];
            [delegate adapterBannerDidFailToLoadWithError:smashError];
        }
    }];
}

- (BOOL) shouldBindBannerViewOnReload {
    return YES;
}

- (void) destroyBannerWithAdapterConfig:(nonnull ISAdapterConfig *)adapterConfig {
    // Placement
    NSString *placementId = adapterConfig.settings[kPlacementId];
    
    // Get banner
    UADSBannerView *bannerView = [_placementIdToBannerAd objectForKey:placementId];
    
    // Remove delegate
    if (bannerView) {
        bannerView.delegate = nil;
    }
    
    // Remove from ad dictionary and set null
    [_placementIdToBannerAd removeObjectForKey:placementId];
    bannerView = nil;
}

#pragma mark - UnityAds Rewarded Delegate

- (void) onRewardedVideoLoadFail:(NSString * _Nonnull)placementId
                       withError:(UnityAdsLoadError)error {
    NSString *loadError = [self unityAdsLoadErrorToString:error];
    LogAdapterDelegate_Internal(@"placementId = %@ reason - %@", placementId, loadError);
    [_rewardedVideoAdsAvailability setObject:@NO forKey:placementId];
    id<ISRewardedVideoAdapterDelegate> delegate = [_placementIdToRewardedVideoSmashDelegate objectForKey:placementId];
    
    if (delegate) {
        NSInteger errorCode = (error == kUnityAdsLoadErrorNoFill) ? ERROR_RV_LOAD_NO_FILL : error;
        NSError *smashError = [NSError errorWithDomain:kAdapterName code:errorCode userInfo:@{NSLocalizedDescriptionKey:loadError}];
        [delegate adapterRewardedVideoDidFailToLoadWithError:smashError];
        [delegate adapterRewardedVideoHasChangedAvailability:NO];
    }
}

- (void) onRewardedVideoLoadSuccess:(NSString * _Nonnull)placementId {
    LogAdapterDelegate_Internal(@"placementId = %@", placementId);
    [_rewardedVideoAdsAvailability setObject:@YES forKey:placementId];
    id<ISRewardedVideoAdapterDelegate> delegate = [_placementIdToRewardedVideoSmashDelegate objectForKey:placementId];
    
    if (delegate) {
        [delegate adapterRewardedVideoHasChangedAvailability:YES];
    }
}

- (void) onRewardedVideoDidShow:(NSString * _Nonnull)placementId {
    LogAdapterDelegate_Internal(@"placementId = %@", placementId);
    id<ISRewardedVideoAdapterDelegate> delegate = [_placementIdToRewardedVideoSmashDelegate objectForKey:placementId];
    
    if (delegate) {
        [delegate adapterRewardedVideoDidOpen];
        [delegate adapterRewardedVideoDidStart];
    }
}

- (void) onRewardedVideoShowFail:(NSString * _Nonnull)placementId
                       withError:(UnityAdsShowError)error
                      andMessage:(NSString * _Nonnull)errorMessage {
    NSString *showError = [NSString stringWithFormat:@"%@ - %@", [self unityAdsShowErrorToString:error], errorMessage];
    LogAdapterDelegate_Internal(@"placementId = %@ reason = %@", placementId, showError);
    id<ISRewardedVideoAdapterDelegate> delegate = [_placementIdToRewardedVideoSmashDelegate objectForKey:placementId];

    if (delegate) {
        NSError *smashError = [NSError errorWithDomain:kAdapterName code:error userInfo:@{NSLocalizedDescriptionKey: showError}];
        [delegate adapterRewardedVideoDidFailToShowWithError:smashError];
    }
}

- (void) onRewardedVideoDidClick:(NSString * _Nonnull)placementId {
    LogAdapterDelegate_Internal(@"placementId = %@", placementId);
    id<ISRewardedVideoAdapterDelegate> delegate = [_placementIdToRewardedVideoSmashDelegate objectForKey:placementId];
    
    if (delegate) {
        [delegate adapterRewardedVideoDidClick];
    }
}

- (void) onRewardedVideoDidShowComplete:(NSString * _Nonnull)placementId
                        withFinishState:(UnityAdsShowCompletionState)state {
    LogAdapterDelegate_Internal(@"placementId = %@ and completion state = %d", placementId, (int)state);
    id<ISRewardedVideoAdapterDelegate> delegate = [_placementIdToRewardedVideoSmashDelegate objectForKey:placementId];
       
    if (delegate) {
       switch (state) {
           case kUnityShowCompletionStateSkipped: {
               [delegate adapterRewardedVideoDidClose];
               break;
           }
           case kUnityShowCompletionStateCompleted: {
               [delegate adapterRewardedVideoDidEnd];
               [delegate adapterRewardedVideoDidReceiveReward];
               [delegate adapterRewardedVideoDidClose];
               break;
           }
           default:
               break;
       }
    }
}

#pragma mark - UnityAds Interstitial Delegate

- (void) onInterstitialLoadSuccess:(nonnull NSString *)placementId {
    LogAdapterDelegate_Internal(@"placementId = %@", placementId);
    [_interstitialAdsAvailability setObject:@YES forKey:placementId];
    id<ISInterstitialAdapterDelegate> delegate = [_placementIdToInterstitialSmashDelegate objectForKey:placementId];
    
    if (delegate) {
        [delegate adapterInterstitialDidLoad];
    }
}

- (void) onInterstitialLoadFail:(nonnull NSString *)placementId
                      withError:(UnityAdsLoadError)error {
    NSString *loadError = [self unityAdsLoadErrorToString:error];
    LogAdapterDelegate_Internal(@"placementId = %@ reason - %@", placementId, loadError);
    [_interstitialAdsAvailability setObject:@NO forKey:placementId];
    id<ISInterstitialAdapterDelegate> delegate = [_placementIdToInterstitialSmashDelegate objectForKey:placementId];
    
    if (delegate) {
        NSInteger errorCode = (error == kUnityAdsLoadErrorNoFill) ? ERROR_IS_LOAD_NO_FILL : error;
        NSError *smashError = [NSError errorWithDomain:kAdapterName code:errorCode userInfo:@{NSLocalizedDescriptionKey:loadError}];
        [delegate adapterInterstitialDidFailToLoadWithError:smashError];
    }
}

- (void) onInterstitialDidShow:(NSString * _Nonnull)placementId {
    LogAdapterDelegate_Internal(@"placementId = %@", placementId);
    id<ISInterstitialAdapterDelegate> delegate = [_placementIdToInterstitialSmashDelegate objectForKey:placementId];
    
    if (delegate) {
        [delegate adapterInterstitialDidOpen];
        [delegate adapterInterstitialDidShow];
    }
}

- (void) onInterstitialShowFail:(NSString * _Nonnull)placementId
                      withError:(UnityAdsShowError)error
                     andMessage:(NSString * _Nonnull)errorMessage {
    NSString *showError = [NSString stringWithFormat:@"%@ - %@", [self unityAdsShowErrorToString:error], errorMessage];
    LogAdapterDelegate_Internal(@"placementId = %@ reason = %@", placementId, showError);
    id<ISInterstitialAdapterDelegate> delegate = [_placementIdToInterstitialSmashDelegate objectForKey:placementId];

    if (delegate) {
        NSError *smashError = [NSError errorWithDomain:kAdapterName code:error userInfo:@{NSLocalizedDescriptionKey: showError}];
        [delegate adapterInterstitialDidFailToShowWithError:smashError];
    }
}

- (void) onInterstitialDidClick:(NSString * _Nonnull)placementId {
    LogAdapterDelegate_Internal(@"placementId = %@", placementId);
    id<ISInterstitialAdapterDelegate> delegate = [_placementIdToInterstitialSmashDelegate objectForKey:placementId];
    
    if (delegate) {
        [delegate adapterInterstitialDidClick];
    }
}

- (void) onInterstitialDidShowComplete:(NSString * _Nonnull)placementId withFinishState:(UnityAdsShowCompletionState)state {
    LogAdapterDelegate_Internal(@"placementId = %@ and completion state = %d", placementId, (int)state);
    id<ISInterstitialAdapterDelegate> delegate = [_placementIdToInterstitialSmashDelegate objectForKey:placementId];
    
    if (delegate) {
        switch (state) {
            case kUnityShowCompletionStateSkipped:
            case kUnityShowCompletionStateCompleted: {
                [delegate adapterInterstitialDidClose];
                break;
            }
            default:
                break;
        }
    }
}

#pragma mark - Banner Delegate

- (void) onBannerLoadSuccess:(UADSBannerView * _Nonnull)bannerView {
    LogAdapterDelegate_Internal(@"placementId = %@", bannerView.placementId);
    id<ISBannerAdapterDelegate> delegate = [_placementIdToBannerSmashDelegate objectForKey:bannerView.placementId];
    
    if (delegate) {
        [delegate adapterBannerDidLoad:bannerView];
        [delegate adapterBannerDidShow];
    }
}

- (void) onBannerLoadFail:(UADSBannerView * _Nonnull)bannerView
                withError:(UADSBannerError * _Nullable)error {
    LogAdapterDelegate_Internal(@"placementId = %@ reason - %@", bannerView.placementId, error);
    id<ISBannerAdapterDelegate> delegate = [_placementIdToBannerSmashDelegate objectForKey:bannerView.placementId];
    
    if (delegate) {
        NSInteger errorCode = (error.code == UADSBannerErrorCodeNoFillError)? ERROR_BN_LOAD_NO_FILL : error.code;
        NSError *smashError = [NSError errorWithDomain:kAdapterName code:errorCode userInfo:@{NSLocalizedDescriptionKey:error.description}];
        [delegate adapterBannerDidFailToLoadWithError:smashError];
    }
}

- (void) onBannerDidClick:(UADSBannerView * _Nonnull)bannerView {
    LogAdapterDelegate_Internal(@"placementId = %@", bannerView.placementId);
    id<ISBannerAdapterDelegate> delegate = [_placementIdToBannerSmashDelegate objectForKey:bannerView.placementId];
    
    if (delegate) {
        [delegate adapterBannerDidClick];
    }
}

- (void) onBannerBannerWillLeaveApplication:(UADSBannerView * _Nonnull)bannerView {
    LogAdapterDelegate_Internal(@"placementId = %@", bannerView.placementId);
    id<ISBannerAdapterDelegate> delegate = [_placementIdToBannerSmashDelegate objectForKey:bannerView.placementId];
    
    if (delegate) {
        [delegate adapterBannerWillLeaveApplication];
    }
}

#pragma mark - UnityAds Init Delegate

- (void) initializationComplete {
    LogAdapterDelegate_Internal(@"UnityAds init success");
    
    _initState = INIT_STATE_SUCCESS;
    
    NSArray *initDelegatesList = initCallbackDelegates.allObjects;
    
    // call init callback delegate success
    for (id<ISNetworkInitCallbackProtocol> initDelegate in initDelegatesList) {
        [initDelegate onNetworkInitCallbackSuccess];
    }
    
    [initCallbackDelegates removeAllObjects];
}

- (void) initializationFailed:(UnityAdsInitializationError)error
                  withMessage:(nonnull NSString *)message {
    NSString *initError = [NSString stringWithFormat:@"%@ - %@", [self unityAdsInitErrorToString:error], message];
    LogAdapterDelegate_Internal(@"init failed error - %@", initError);

    _initState = INIT_STATE_FAILED;
    
    NSArray *initDelegatesList = initCallbackDelegates.allObjects;
    
    // call init callback delegate fail
    for (id<ISNetworkInitCallbackProtocol> initDelegate in initDelegatesList) {
        [initDelegate onNetworkInitCallbackFailed:initError];
    }
    
    [initCallbackDelegates removeAllObjects];
}

- (void) onNetworkInitCallbackSuccess {
    // rewarded video
    NSArray *rewardedVideoPlacementIDs = _placementIdToRewardedVideoSmashDelegate.allKeys;
    
    for (NSString *placementId in rewardedVideoPlacementIDs) {
        if ([_rewardedVideoPlacementsForInitCallbacks hasObject:placementId]) {
            id<ISRewardedVideoAdapterDelegate> delegate = [_placementIdToRewardedVideoSmashDelegate objectForKey:placementId];
            LogAdapterApi_Internal(@"adapterRewardedVideoInitSuccess - placementId = %@", placementId);
            [delegate adapterRewardedVideoInitSuccess];
        } else {
            LogAdapterApi_Internal(@"loadRewardedVideo - placementId = %@", placementId);
            [self loadRewardedVideo:placementId];
        }
    }
    
    // interstitial
    NSArray *interstitialPlacementIDs = _placementIdToInterstitialSmashDelegate.allKeys;
    
    for (NSString *placementId in interstitialPlacementIDs) {
        id<ISInterstitialAdapterDelegate> delegate = [_placementIdToInterstitialSmashDelegate objectForKey:placementId];
        [delegate adapterInterstitialInitSuccess];
    }
    
    // banner
    NSArray *bannerPlacementIDs = _placementIdToBannerSmashDelegate.allKeys;
    
    for (NSString *placementId in bannerPlacementIDs) {
        id<ISBannerAdapterDelegate> delegate = [_placementIdToBannerSmashDelegate objectForKey:placementId];
        [delegate adapterBannerInitSuccess];
    }
}

- (void) onNetworkInitCallbackFailed:(nonnull NSString *)errorMessage {
    NSError *error = [NSError errorWithDomain:kAdapterName code:ERROR_CODE_INIT_FAILED userInfo:@{NSLocalizedDescriptionKey:errorMessage}];
    
    // rewarded video
    NSArray *rewardedVideoPlacementIDs = _placementIdToRewardedVideoSmashDelegate.allKeys;

    for (NSString *placementId in rewardedVideoPlacementIDs) {
        id<ISRewardedVideoAdapterDelegate> delegate = [_placementIdToRewardedVideoSmashDelegate objectForKey:placementId];
        
        if ([_rewardedVideoPlacementsForInitCallbacks hasObject:placementId]) {
            LogAdapterApi_Internal(@"adapterRewardedVideoInitFailed - error = %@", error);
            [delegate adapterRewardedVideoInitFailed:error];
        } else {
            LogAdapterApi_Internal(@"adapterRewardedVideoHasChangedAvailability:NO");
            [delegate adapterRewardedVideoHasChangedAvailability:NO];
        }
    }
    
    // interstitial
    NSArray *interstitialPlacementIDs = _placementIdToInterstitialSmashDelegate.allKeys;
    
    for (NSString *placementId in interstitialPlacementIDs) {
        id<ISInterstitialAdapterDelegate> delegate = [_placementIdToInterstitialSmashDelegate objectForKey:placementId];
        [delegate adapterInterstitialInitFailedWithError:error];
    }
    
    // banner
    NSArray *bannerPlacementIDs = _placementIdToBannerSmashDelegate.allKeys;
    
    for (NSString *placementId in bannerPlacementIDs) {
        id<ISBannerAdapterDelegate> delegate = [_placementIdToBannerSmashDelegate objectForKey:placementId];
        [delegate adapterBannerInitFailedWithError:error];
    }
}

#pragma mark - Private Methods

- (void) initWithSourceId:(NSString *)sourceId adapterConfig:(ISAdapterConfig *)adapterConfig  {
    // add self to init delegates only
    // when init not finished yet
    if (_initState == INIT_STATE_NONE || _initState == INIT_STATE_IN_PROGRESS) {
        [initCallbackDelegates addObject:self];
    }
    
    // Notice that dispatch_once is synchronous
    static dispatch_once_t oncePredicate;
    dispatch_once(&oncePredicate, ^{
        [self.dispatcher dispatchAsyncWithQueue:dispatch_get_main_queue() withBlock:^{
            _initState = INIT_STATE_IN_PROGRESS;
            
            // trying to fetch async token for the first load
            [self getAsyncToken:adapterConfig];

            @synchronized (_UnityAdsStorageLock) {
                UADSMediationMetaData *mediationMetaData = [[UADSMediationMetaData alloc] init];
                [mediationMetaData setName:@"IronSource"];
                [mediationMetaData setVersion:MEDIATION_VERSION];
                [mediationMetaData set:kAdapterVersion value:kAdapterVersion];
                [mediationMetaData commit];
            }

            [UnityAds setDebugMode:[ISConfigurations getConfigurations].adaptersDebug];
            LogAdapterApi_Internal(@"setDebugMode = %d", [ISConfigurations getConfigurations].adaptersDebug);

            [UnityAds initialize:sourceId testMode:NO initializationDelegate:self];
        }];
        
    });
}

- (NSDictionary *) getBiddingData {
    NSString *bidderToken = nil;

    if (_initState == INIT_STATE_SUCCESS) {
        bidderToken = [UnityAds getToken];
    } else if (asyncToken.length) {
        bidderToken = asyncToken;
    } else {
        LogAdapterApi_Internal(@"returning nil as token since init did not finish successfully");
        return nil;
    }
    
    NSString *returnedToken = bidderToken? bidderToken : @"";
    LogAdapterApi_Internal(@"token = %@", returnedToken);
    
    return @{@"token": returnedToken};
}

- (BOOL) isBannerSizeSupported:(ISBannerSize *)size {
    if ([size.sizeDescription isEqualToString:@"BANNER"] ||
        [size.sizeDescription isEqualToString:@"LARGE"] ||
        [size.sizeDescription isEqualToString:@"SMART"]) {
        return YES;
    }
    
    return NO;
}

- (CGSize) getBannerSize:(ISBannerSize *)size {
    if ([size.sizeDescription isEqualToString:@"BANNER"] ||
        [size.sizeDescription isEqualToString:@"LARGE"]) {
        return CGSizeMake(320, 50);
    }
    else if ([size.sizeDescription isEqualToString:@"SMART"]) {
        if (UI_USER_INTERFACE_IDIOM() == UIUserInterfaceIdiomPad) {
            return CGSizeMake(728, 90);
        }
        else {
            return CGSizeMake(320, 50);
        }
    }
    
    return CGSizeZero;
}

- (NSString *) unityAdsInitErrorToString:(UnityAdsInitializationError)error {
    NSString *result = nil;
    
    switch (error) {
        case kUnityInitializationErrorInternalError:
            result = @"INTERNAL_ERROR";
            break;
        case kUnityInitializationErrorInvalidArgument:
            result = @"INVALID_ARGUMENT";
            break;
        case kUnityInitializationErrorAdBlockerDetected:
            result = @"AD_BLOCKER_DETECTED";
            break;
        default:
            result = @"UNKOWN_ERROR";
    }
    
    return result;
}

- (NSString *) unityAdsLoadErrorToString:(UnityAdsLoadError)error {
    NSString *result = nil;
    
    switch (error) {
        case kUnityAdsLoadErrorInitializeFailed:
            result = @"SDK_NOT_INITIALIZED";
            break;
        case kUnityAdsLoadErrorInternal:
            result = @"INTERNAL_ERROR";
            break;
        case kUnityAdsLoadErrorInvalidArgument:
            result = @"INVALID_ARGUMENT";
            break;
        case kUnityAdsLoadErrorNoFill:
            result = @"NO_FILL";
            break;
        case kUnityAdsLoadErrorTimeout:
            result = @"LOAD_TIMEOUT";
            break;
        default:
            result = @"UNKOWN_ERROR";
    }
    
    return result;
}

- (NSString *) unityAdsShowErrorToString:(UnityAdsShowError)error {
    NSString *result = nil;
    
    switch (error) {
        case kUnityShowErrorNotInitialized:
            result = @"SDK_NOT_INITIALIZED";
            break;
        case kUnityShowErrorNotReady:
            result = @"PLACEMENT_NOT_READY";
            break;
        case kUnityShowErrorVideoPlayerError:
            result = @"VIDEO_PLAYER_ERROR";
            break;
        case kUnityShowErrorInvalidArgument:
            result = @"INVALID_ARGUMENT";
            break;
        case kUnityShowErrorNoConnection:
            result = @"NO_INTERNET_CONNECTION";
            break;
        case kUnityShowErrorAlreadyShowing:
            result = @"AD_IS_ALREADY_BEIGN_SHOWED";
            break;
        case kUnityShowErrorInternalError:
            result = @"NO_INTERNET_CONNECTION";
            break;
        default:
            result = @"UNKOWN_ERROR";
    }
    
    return result;
}

- (BOOL) isValidCOPPAMetaDataWithKey:(NSString *)key
                            andValue:(NSString *)value {
    return ([key caseInsensitiveCompare:kMetaDataCOPPAKey] == NSOrderedSame && (value.length));
}

// ability to override the adapter flag with a platform configuration in order to support load while show
- (ISLoadWhileShowSupportState) getLWSSupportState:(ISAdapterConfig *)adapterConfig {
    ISLoadWhileShowSupportState state = LWSState;
    
    if (adapterConfig != nil && [adapterConfig.settings objectForKey:kIsLWSSupported] != nil) {
        BOOL isLWSSupported = [[adapterConfig.settings objectForKey:kIsLWSSupported] boolValue];
        
        if (isLWSSupported) {
            state =  LOAD_WHILE_SHOW_BY_INSTANCE;
        }
    }
    
    return state;
}

-(void) getAsyncToken:(ISAdapterConfig *)adapterConfig {
    if (adapterConfig != nil && [adapterConfig.settings objectForKey:kIsAsyncTokenEnabled] != nil) {
        BOOL isAsyncTokenEnabled = [[adapterConfig.settings objectForKey:kIsAsyncTokenEnabled] boolValue];
        
        if (isAsyncTokenEnabled) {
            LogInternal_Internal(@"Trying to get UnityAds async token");
            [UnityAds getToken:^(NSString * _Nullable token) {
                if (token.length) {
                    LogInternal_Internal(@"async token = %@", token);
                    asyncToken = token;
                }
            }];
        }
    }
}

@end
