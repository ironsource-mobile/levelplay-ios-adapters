//
//  ISAdMobAdapter.m
//  ISAdMobAdapter
//
//  Created by Daniil Bystrov on 4/11/16.
//  Copyright © 2016 IronSource. All rights reserved.
//

#import "ISAdMobAdapter.h"
#import <GoogleMobileAds/GoogleMobileAds.h>
#import <ISAdMobInterstitialDelegate.h>
#import <ISAdMobRewardedVideoDelegate.h>
#import <ISAdMobBannerDelegate.h>

//AdMob requires a request agent name
static NSString * const kRequestAgent             = @"ironSource";

static NSString * const kAdapterName              = @"AdMob";
static NSString * const kAdUnitId                 = @"adUnitId";
static int const kMinUserAge                      = -1;
static int const kMaxChildAge                     = 13;

// Init configuration flags
static NSString * const kNetworkOnlyInitFlag      = @"networkOnlyInit";
static NSString * const kInitResponseRequiredFlag = @"initResponseRequired";

// AdMob network id
static NSString * const kAdMobNetworkId           = @"GADMobileAds";


// Init state
typedef NS_ENUM(NSInteger, InitState) {
    INIT_STATE_NONE,
    INIT_STATE_IN_PROGRESS,
    INIT_STATE_SUCCESS,
    INIT_STATE_FAILED
};

// Handle init callback for all adapter instances
static ConcurrentMutableSet<ISNetworkInitCallbackProtocol> *initCallbackDelegates = nil;
static InitState _initState = INIT_STATE_NONE;

// Meta data keys
static NSString * const kAdMobTFCD                = @"admob_tfcd";
static NSString * const kAdMobTFUA                = @"admob_tfua";
static NSString * const kAdMobContentRating       = @"admob_maxcontentrating";
static NSString * const kAdMobCCPAKey             = @"gad_rdp";


// Meta data content rate values
static NSString * const kAdMobMaxContentRatingG    = @"max_ad_content_rating_g";
static NSString * const kAdMobMaxContentRatingPG   = @"max_ad_content_rating_pg";
static NSString * const kAdMobMaxContentRatingT    = @"max_ad_content_rating_t";
static NSString * const kAdMobMaxContentRatingMA   = @"max_ad_content_rating_ma";

// Consent flags
static BOOL _didSetConsentCollectingUserData      = NO;
static BOOL _consentCollectingUserData            = NO;

@interface ISAdMobAdapter () <ISAdMobBannerDelegateWrapper,ISAdMobRewardedVideoDelegateWrapper, ISAdMobInterstitialDelegateWrapper, ISNetworkInitCallbackProtocol> {
}

// Rewarded video
@property (nonatomic, strong) ConcurrentMutableDictionary *rewardedVideoAds;
@property (nonatomic, strong) ConcurrentMutableDictionary *rewardedVideoAdUnitIdToSmashDelegate;
@property (nonatomic, strong) ConcurrentMutableDictionary *rewardedVideoAdsAvailability;
@property (nonatomic, strong) ConcurrentMutableDictionary *rewardedVideoAdUnitIdToAdMobAdDelegate;
@property (nonatomic, strong) NSMutableSet                *rewardedVideoAdUnitIdForInitCallbacks;

// Interstitial
@property (nonatomic, strong) ConcurrentMutableDictionary *interstitialAds;
@property (nonatomic, strong) ConcurrentMutableDictionary *interstitialAdUnitIdToSmashDelegate;
@property (nonatomic, strong) ConcurrentMutableDictionary *interstitialAdsAvailability;
@property (nonatomic, strong) ConcurrentMutableDictionary *interstitialAdUnitIdToAdMobAdDelegate;

// Banner
@property (nonatomic, strong) ConcurrentMutableDictionary *bannerAds;
@property (nonatomic, strong) ConcurrentMutableDictionary *bannerAdUnitIdToSmashDelegate;
@property (nonatomic, strong) ConcurrentMutableDictionary *bannerAdUnitIdToAdMobAdDelegate;


@end

@implementation ISAdMobAdapter


#pragma mark - IronSource Protocol Methods

// Get adapter version
- (NSString *)version {
    return AdMobAdapterVersion;
}

// Get network sdk version
- (NSString *)sdkVersion {
    return GADMobileAds.sharedInstance.sdkVersion;
}

// network system frameworks
- (NSArray *)systemFrameworks {
    return @[
        @"AdSupport",
        @"AudioToolbox",
        @"AVFoundation",
        @"CFNetwork",
        @"CoreGraphics",
        @"CoreMedia",
        @"CoreTelephony",
        @"CoreVideo",
        @"JavaScriptCore",
        @"MediaPlayer",
        @"MessageUI",
        @"MobileCoreServices",
        @"QuartzCore",
        @"SafariServices",
        @"Security",
        @"StoreKit",
        @"SystemConfiguration",
        @"WebKit"
    ];
}

// Get network name
- (NSString *)sdkName {
    return kAdMobNetworkId;
}


#pragma mark - Initializations Methods And Callbacks

- (instancetype)initAdapter:(NSString *)name {
    self = [super initAdapter:name];
    
    if (self) {
        if (initCallbackDelegates == nil) {
            initCallbackDelegates =  [ConcurrentMutableSet<ISNetworkInitCallbackProtocol> set];
        }
        
        // Rewarded video data collections
        _rewardedVideoAds                           = [ConcurrentMutableDictionary dictionary];
        _rewardedVideoAdUnitIdToSmashDelegate       = [ConcurrentMutableDictionary dictionary];
        _rewardedVideoAdsAvailability               = [ConcurrentMutableDictionary dictionary];
        _rewardedVideoAdUnitIdToAdMobAdDelegate     = [ConcurrentMutableDictionary dictionary];
        _rewardedVideoAdUnitIdForInitCallbacks      = [[NSMutableSet alloc] init];
        
        // Interstitial data collections
        _interstitialAds                            = [ConcurrentMutableDictionary dictionary];
        _interstitialAdUnitIdToSmashDelegate        = [ConcurrentMutableDictionary dictionary];
        _interstitialAdsAvailability                = [ConcurrentMutableDictionary dictionary];
        _interstitialAdUnitIdToAdMobAdDelegate      = [ConcurrentMutableDictionary dictionary];

        // Banner data collections
        _bannerAds                                  = [ConcurrentMutableDictionary dictionary];
        _bannerAdUnitIdToSmashDelegate              = [ConcurrentMutableDictionary dictionary];
        _bannerAdUnitIdToAdMobAdDelegate            = [ConcurrentMutableDictionary dictionary];
        
        // The network's capability to load a Rewarded Video ad while another Rewarded Video ad of that network is showing
        LWSState = LOAD_WHILE_SHOW_BY_INSTANCE;
    }
    
    return self;
}

- (void)initAdMobSDKWithAdapterConfig:(ISAdapterConfig *)adapterConfig {
    // add self to init delegates only when init not finished yet
    if (_initState == INIT_STATE_NONE || _initState == INIT_STATE_IN_PROGRESS) {
        [initCallbackDelegates addObject:self];
    }
    
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        LogAdapterDelegate_Internal(@"");
        
        _initState = INIT_STATE_IN_PROGRESS;
        
        // In case the platform doesn't override this flag the default is to init only the network
        BOOL networkOnlyInit = adapterConfig.settings[kNetworkOnlyInitFlag] ? [adapterConfig.settings[kNetworkOnlyInitFlag] boolValue] : YES;
        
        if (networkOnlyInit) {
            LogAdapterDelegate_Internal(@"disableMediationInitialization");
            [[GADMobileAds sharedInstance] disableMediationInitialization];
        }
        
        // In case the platform doesn't override this flag the default is not to wait for the init callback before loading an ad
        BOOL shouldWaitForInitCallback = adapterConfig.settings[kInitResponseRequiredFlag] ? [adapterConfig.settings[kInitResponseRequiredFlag] boolValue] : NO;
        
        if (shouldWaitForInitCallback) {
            LogAdapterDelegate_Internal(@"init and wait for callback");
            
            [[GADMobileAds sharedInstance] startWithCompletionHandler:^(GADInitializationStatus *_Nonnull status) {
                NSDictionary *adapterStatuses = status.adapterStatusesByClassName;
                
                if ([adapterStatuses objectForKey:kAdMobNetworkId]) {
                    GADAdapterStatus *initStatus = [adapterStatuses objectForKey:kAdMobNetworkId];
                    
                    if (initStatus.state == GADAdapterInitializationStateReady) {
                        [self initializationSuccess];
                        return;
                    }
                }
                
                // If we got here then either the AdMob network is missing from the initalization status dictionary
                // or it returned as not ready
                [self initializationFailure];
            }];
        }
        else {
            LogAdapterDelegate_Internal(@"init without callback");
            [[GADMobileAds sharedInstance] startWithCompletionHandler:nil];
            [self initializationSuccess];
        }
    });
}
- (void)onNetworkInitCallbackFailed:(NSString *)errorMessage {
    NSError *error = [ISError createError:ERROR_CODE_INIT_FAILED
                              withMessage:errorMessage];

    // rewarded video
    NSArray *rewardedVideoAdUnitIds = _rewardedVideoAdUnitIdToSmashDelegate.allKeys;
    
    for (NSString *adUnitId in rewardedVideoAdUnitIds) {
        id<ISRewardedVideoAdapterDelegate> delegate = [_rewardedVideoAdUnitIdToSmashDelegate objectForKey:adUnitId];
        if ([_rewardedVideoAdUnitIdForInitCallbacks containsObject:adUnitId]) {
            [delegate adapterRewardedVideoInitFailed:error];
        } else {
            [delegate adapterRewardedVideoHasChangedAvailability:NO];
        }
        
    }
    
    // interstitial
    NSArray *interstitialAdUnitIds = _interstitialAdUnitIdToSmashDelegate.allKeys;
    
    for (NSString *adUnitId in interstitialAdUnitIds) {
        id<ISInterstitialAdapterDelegate> delegate = [_interstitialAdUnitIdToSmashDelegate objectForKey:adUnitId];
        [delegate adapterInterstitialInitFailedWithError:error];
    }
    
    // banner
    NSArray *bannerAdUnitIds = _bannerAdUnitIdToSmashDelegate.allKeys;
    
    for (NSString *adUnitId in bannerAdUnitIds) {
        id<ISBannerAdapterDelegate> delegate = [_bannerAdUnitIdToSmashDelegate objectForKey:adUnitId];
        [delegate adapterBannerInitFailedWithError:error];
    }
}

- (void)onNetworkInitCallbackSuccess {

    // rewarded video
    NSArray *rewardedVideoAdUnitIds = _rewardedVideoAdUnitIdToSmashDelegate.allKeys;

    for (NSString *adUnitId in rewardedVideoAdUnitIds) {
        id<ISRewardedVideoAdapterDelegate> delegate = [_rewardedVideoAdUnitIdToSmashDelegate objectForKey:adUnitId];
        
        if ([_rewardedVideoAdUnitIdForInitCallbacks containsObject:adUnitId]) {
            [delegate adapterRewardedVideoInitSuccess];
        } else {
            [self loadRewardedVideoInternal:adUnitId
                                   delegate:delegate];
        }
    }
    
    // interstitial
    NSArray *interstitialAdUnitIds = _interstitialAdUnitIdToSmashDelegate.allKeys;
    
    for (NSString *adUnitId in interstitialAdUnitIds) {
        id<ISInterstitialAdapterDelegate> delegate = [_interstitialAdUnitIdToSmashDelegate objectForKey:adUnitId];
        [delegate adapterInterstitialInitSuccess];
    }
    
    // banner
    NSArray *bannerAdUnitIds = _bannerAdUnitIdToSmashDelegate.allKeys;
    
    for (NSString *adUnitId in bannerAdUnitIds) {
        id<ISBannerAdapterDelegate> delegate = [_bannerAdUnitIdToSmashDelegate objectForKey:adUnitId];
        [delegate adapterBannerInitSuccess];
    }
}

- (void)initializationSuccess {
    LogAdapterDelegate_Internal(@"");
    
    _initState = INIT_STATE_SUCCESS;
    
    NSArray* initDelegatesList = initCallbackDelegates.allObjects;
    for(id<ISNetworkInitCallbackProtocol> initDelegate in initDelegatesList){
        [initDelegate onNetworkInitCallbackSuccess];
    }
    
    [initCallbackDelegates removeAllObjects];
}

- (void)initializationFailure {
    LogAdapterDelegate_Internal(@"");

    _initState = INIT_STATE_FAILED;
    
    NSArray* initDelegatesList = initCallbackDelegates.allObjects;
    for(id<ISNetworkInitCallbackProtocol> initDelegate in initDelegatesList){
        [initDelegate onNetworkInitCallbackFailed:@"AdMob SDK init failed"];
    }
    
    [initCallbackDelegates removeAllObjects];
}

#pragma mark - Rewarded Video API


// Used for flows when the mediation needs to get a callback for init
- (void)initRewardedVideoForCallbacksWithUserId:(NSString *)userId
                                  adapterConfig:(ISAdapterConfig *)adapterConfig
                                       delegate:(id<ISRewardedVideoAdapterDelegate>)delegate {
    dispatch_async(dispatch_get_main_queue(), ^{

        NSString *adUnitId = adapterConfig.settings[kAdUnitId];
        
        
        /* Configuration Validation */
        if (![self isConfigValueValid:adUnitId]) {
            NSError *error = [self errorForMissingCredentialFieldWithName:kAdUnitId];
            LogAdapterApi_Internal(@"error.description = %@", error.description);
            [delegate adapterRewardedVideoInitFailed:error];
            return;
        }
        
        LogAdapterApi_Internal(@"adUnitId = %@", adUnitId);

        ISAdMobRewardedVideoDelegate *rewardedVideoDelegate = [[ISAdMobRewardedVideoDelegate alloc] initWithAdUnitId:adUnitId
                                                                                                         andDelegate:self];
        [_rewardedVideoAdUnitIdToAdMobAdDelegate setObject:rewardedVideoDelegate
                                                    forKey:adUnitId];
        [_rewardedVideoAdUnitIdToSmashDelegate setObject:delegate
                                                  forKey:adUnitId];
        [_rewardedVideoAdUnitIdForInitCallbacks addObject:adUnitId];
        
        switch (_initState) {
            case INIT_STATE_NONE:
            case INIT_STATE_IN_PROGRESS:
                [self initAdMobSDKWithAdapterConfig:adapterConfig];
                break;
            case INIT_STATE_FAILED: {
                LogAdapterApi_Internal(@"init failed - adUnitId = %@", adUnitId);
                [delegate adapterRewardedVideoInitFailed:[ISError createError:ERROR_CODE_INIT_FAILED
                                                                  withMessage:@"AdMob SDK init failed"]];
                break;
            }
            case INIT_STATE_SUCCESS:
                [delegate adapterRewardedVideoInitSuccess];
                break;

        }
    });
}

// Used for flows when the mediation doesn't need to get a callback for init
- (void)initAndLoadRewardedVideoWithUserId:(NSString *)userId
                             adapterConfig:(ISAdapterConfig *)adapterConfig
                                  delegate:(id<ISRewardedVideoAdapterDelegate>)delegate {
    dispatch_async(dispatch_get_main_queue(), ^{
        NSString *adUnitId = adapterConfig.settings[kAdUnitId];
        
        
        /* Configuration Validation */
        if (![self isConfigValueValid:adUnitId]) {
            NSError *error = [self errorForMissingCredentialFieldWithName:kAdUnitId];
            LogAdapterApi_Internal(@"error.description = %@", error.description);
            [delegate adapterRewardedVideoHasChangedAvailability:NO];
            return;
        }
        
        LogAdapterApi_Internal(@"adUnitId = %@", adUnitId);

        ISAdMobRewardedVideoDelegate *rewardedVideoDelegate = [[ISAdMobRewardedVideoDelegate alloc] initWithAdUnitId:adUnitId
                                                                                                         andDelegate:self];
        [_rewardedVideoAdUnitIdToAdMobAdDelegate setObject:rewardedVideoDelegate
                                                    forKey:adUnitId];
        
        //add to rewarded video Delegate map
        [_rewardedVideoAdUnitIdToSmashDelegate setObject:delegate
                                                  forKey:adUnitId];
        
        switch (_initState) {
            case INIT_STATE_NONE:
            case INIT_STATE_IN_PROGRESS:
                [self initAdMobSDKWithAdapterConfig:adapterConfig];
                break;
            case INIT_STATE_FAILED: {
                LogAdapterApi_Internal(@"init failed - adUnitId = %@", adUnitId);
                [delegate adapterRewardedVideoHasChangedAvailability:NO];
                break;
            }
            case INIT_STATE_SUCCESS:
                [self loadRewardedVideoInternal:adUnitId
                                       delegate:delegate];
                break;

        }
    });
}

- (void)fetchRewardedVideoForAutomaticLoadWithAdapterConfig:(ISAdapterConfig *)adapterConfig
                                                   delegate:(id<ISRewardedVideoAdapterDelegate>)delegate {
    dispatch_async(dispatch_get_main_queue(), ^{
        NSString *adUnitId = adapterConfig.settings[kAdUnitId];
        LogAdapterApi_Internal(@"adUnitId = %@", adUnitId);
        [self loadRewardedVideoInternal:adUnitId
                               delegate:delegate];
    });
}

- (void)loadRewardedVideoInternal:(NSString *)adUnitId
                         delegate:(id<ISRewardedVideoAdapterDelegate>)delegate {
    [_rewardedVideoAdsAvailability setObject:@NO
                                      forKey:adUnitId];
    if ([_rewardedVideoAdUnitIdToSmashDelegate objectForKey:adUnitId]) {
        LogAdapterApi_Internal(@"adUnitId = %@", adUnitId);
        GADRequest *request = [self createGADRequest];
        [GADRewardedAd loadWithAdUnitID:adUnitId
                                request:request
                      completionHandler:^(GADRewardedAd *ad, NSError *error) {
            
            [_rewardedVideoAds setObject:ad
                                  forKey:adUnitId];
            if (error) {
                LogAdapterApi_Internal(@"failed for adUnitId = %@", adUnitId);
                [_rewardedVideoAdsAvailability setObject:@NO
                                                  forKey:adUnitId];
                // set the rewarded video availability to false
                [delegate adapterRewardedVideoHasChangedAvailability:NO];
                NSError *smashError = [self isNoFillError:error] ? [ISError createError:ERROR_RV_LOAD_NO_FILL
                                                                            withMessage:@"AdMob no fill"] : error;
                [delegate adapterRewardedVideoDidFailToLoadWithError:smashError];
            } else {
                LogAdapterApi_Internal(@"success for adUnitId = %@", adUnitId);
                [_rewardedVideoAdsAvailability setObject:@YES
                                                  forKey:adUnitId];
                [delegate adapterRewardedVideoHasChangedAvailability:YES];

            }
            
        }];
    }
}

- (void)showRewardedVideoWithViewController:(UIViewController *)viewController
                              adapterConfig:(ISAdapterConfig *)adapterConfig
                                   delegate:(id<ISRewardedVideoAdapterDelegate>)delegate {
    dispatch_async(dispatch_get_main_queue(), ^{
        NSString *adUnitId = adapterConfig.settings[kAdUnitId];

        LogAdapterApi_Internal(@"adUnitId = %@", adUnitId);
        
        GADRewardedAd *rewardedVideoAd = [_rewardedVideoAds objectForKey:adUnitId];
        if (rewardedVideoAd && [self hasRewardedVideoWithAdapterConfig:adapterConfig]) {
            ISAdMobRewardedVideoDelegate* rewardedVideoDelegate = [_rewardedVideoAdUnitIdToAdMobAdDelegate objectForKey:rewardedVideoAd.adUnitID];
            rewardedVideoAd.fullScreenContentDelegate = rewardedVideoDelegate;
            [rewardedVideoAd presentFromRootViewController:viewController
                                  userDidEarnRewardHandler:^{
                LogAdapterApi_Internal(@"adapterRewardedVideoDidReceiveReward");
                [delegate adapterRewardedVideoDidReceiveReward];
            }];
        }
        else {
            NSError *error = [ISError createError:ERROR_CODE_NO_ADS_TO_SHOW
                                      withMessage:[NSString stringWithFormat: @"%@ show failed", kAdapterName]];
            LogAdapterApi_Internal(@"error = %@", error);
            [delegate adapterRewardedVideoDidFailToShowWithError:error];
        }
        // once reward video is displayed or if it's not ready, it's no longer available
        [_rewardedVideoAdsAvailability setObject:@NO
                                          forKey:adUnitId];
        [delegate adapterRewardedVideoHasChangedAvailability:NO];
    });
}

- (BOOL)hasRewardedVideoWithAdapterConfig:(ISAdapterConfig *)adapterConfig {
    NSString *adUnitId = adapterConfig.settings[kAdUnitId];
    NSNumber *available = [_rewardedVideoAdsAvailability objectForKey:adUnitId];
    return (available != nil) && [available boolValue];
}

#pragma mark - Rewarded Video Delegate

- (void)onRewardedVideoDidOpen:(nonnull NSString *)adUnitId {
    LogAdapterDelegate_Internal(@"adUnitId = %@", adUnitId);
    id<ISRewardedVideoAdapterDelegate> delegate = [_rewardedVideoAdUnitIdToSmashDelegate objectForKey:adUnitId];
    [delegate adapterRewardedVideoDidOpen];
}

- (void)onRewardedVideoShowFail:(nonnull NSString *)adUnitId
                      withError:(nonnull NSError *)error{
    LogAdapterDelegate_Internal(@"adUnitId = %@ with error = %@", adUnitId,error);
    id<ISRewardedVideoAdapterDelegate> delegate = [_rewardedVideoAdUnitIdToSmashDelegate objectForKey:adUnitId];
    [delegate adapterRewardedVideoDidFailToShowWithError:error];
}

- (void)onRewardedVideoDidClick:(nonnull NSString *)adUnitId {
    LogAdapterDelegate_Internal(@"adUnitId = %@", adUnitId);
    id<ISRewardedVideoAdapterDelegate> delegate = [_rewardedVideoAdUnitIdToSmashDelegate objectForKey:adUnitId];
    [delegate adapterRewardedVideoDidClick];
}

- (void)onRewardedVideoDidClose:(nonnull NSString *)adUnitId {
    LogAdapterDelegate_Internal(@"adUnitId = %@", adUnitId);
    id<ISRewardedVideoAdapterDelegate> delegate = [_rewardedVideoAdUnitIdToSmashDelegate objectForKey:adUnitId];
    [delegate adapterRewardedVideoDidClose];
}



#pragma mark - Interstitial API

- (void)initInterstitialWithUserId:(NSString *)userId
                     adapterConfig:(ISAdapterConfig *)adapterConfig
                          delegate:(id<ISInterstitialAdapterDelegate>)delegate {
    dispatch_async(dispatch_get_main_queue(), ^{
        
        NSString *adUnitId = adapterConfig.settings[kAdUnitId];
        
        
        /* Configuration Validation */
        if (![self isConfigValueValid:adUnitId]) {
            NSError *error = [self errorForMissingCredentialFieldWithName:kAdUnitId];
            LogAdapterApi_Internal(@"error = %@", error);
            [delegate adapterInterstitialInitFailedWithError:error];
            return;
        }
        
        LogAdapterApi_Internal(@"adUnitId = %@", adUnitId);

        ISAdMobInterstitialDelegate *interstitialDelegate = [[ISAdMobInterstitialDelegate alloc] initWithAdUnitId:adUnitId
                                                                                                      andDelegate:self];
        [_interstitialAdUnitIdToAdMobAdDelegate setObject:interstitialDelegate
                                                   forKey:adUnitId];
        [_interstitialAdUnitIdToSmashDelegate setObject:delegate
                                                 forKey:adUnitId];
        switch (_initState) {
            case INIT_STATE_NONE:
            case INIT_STATE_IN_PROGRESS:
                [self initAdMobSDKWithAdapterConfig:adapterConfig];
                break;
            case INIT_STATE_FAILED: {
                LogAdapterApi_Internal(@"init failed - adUnitId = %@", adUnitId);
                [delegate adapterInterstitialInitFailedWithError:[ISError createError:ERROR_CODE_INIT_FAILED
                                                                          withMessage:@"AdMob SDK init failed"]];
                break;
            }
            case INIT_STATE_SUCCESS:
                [delegate adapterInterstitialInitSuccess];
                break;
        }
    });
}

- (void)loadInterstitialWithAdapterConfig:(ISAdapterConfig *)adapterConfig
                                 delegate:(id<ISInterstitialAdapterDelegate>)delegate {
    dispatch_async(dispatch_get_main_queue(), ^{
        
        NSString *adUnitId = adapterConfig.settings[kAdUnitId];
        [_interstitialAdsAvailability setObject:@NO
                                         forKey:adUnitId];
        LogAdapterApi_Internal(@"adUnitId = %@", adUnitId);
        id<ISInterstitialAdapterDelegate> delegate = [_interstitialAdUnitIdToSmashDelegate objectForKey:adUnitId];
        if (delegate == nil) {
            LogAdapterApi_Internal(@"delegate = nil");
            return;
        }
        GADRequest *request = [self createGADRequest];
        /* Create new GADInterstitial */
        [GADInterstitialAd loadWithAdUnitID:adUnitId
                                    request:request
                          completionHandler:^(GADInterstitialAd *ad, NSError *error) {
            [_interstitialAds setObject:ad
                                 forKey:adUnitId];
            if (error) {
            // set the interstitial ad availability to false
              [_interstitialAdsAvailability setObject:@NO
                                               forKey:adUnitId];
                NSError *smashError = [self isNoFillError:error] ? [ISError createError:ERROR_IS_LOAD_NO_FILL
                                                                            withMessage:@"AdMob no fill"] : error;
              [delegate adapterInterstitialDidFailToLoadWithError:smashError];
          } else {
              [_interstitialAdsAvailability setObject:@YES
                                               forKey:adUnitId];
              [delegate adapterInterstitialDidLoad];
          }
        }];
    });
}

- (void)showInterstitialWithViewController:(UIViewController *)viewController
                             adapterConfig:(ISAdapterConfig *)adapterConfig
                                  delegate:(id<ISInterstitialAdapterDelegate>)delegate {
    dispatch_async(dispatch_get_main_queue(), ^{
        NSString *adUnitId = adapterConfig.settings[kAdUnitId];
        LogAdapterApi_Internal(@"adUnitId = %@", adUnitId);
        GADInterstitialAd *interstitialAd = [_interstitialAds objectForKey:adUnitId];
        ISAdMobInterstitialDelegate* interstitialDelegate = [_interstitialAdUnitIdToAdMobAdDelegate objectForKey:adUnitId];
        interstitialAd.fullScreenContentDelegate = interstitialDelegate;
        // Show the ad if it's ready.
        if (interstitialAd != nil && [self hasInterstitialWithAdapterConfig:adapterConfig]) {
            [interstitialAd presentFromRootViewController:viewController];
        }
        else {
            NSError *error = [ISError createError:ERROR_CODE_NO_ADS_TO_SHOW
                                      withMessage:[NSString stringWithFormat: @"%@ show failed", kAdapterName]];
            LogAdapterApi_Internal(@"error = %@", error);
            [delegate adapterInterstitialDidFailToShowWithError:error];
            
        }
        //change interstitial availability to false
        [_interstitialAdsAvailability setObject:@NO
                                         forKey:adUnitId];
    });
}

- (BOOL)hasInterstitialWithAdapterConfig:(ISAdapterConfig *)adapterConfig {
    NSString *adUnitId = adapterConfig.settings[kAdUnitId];
    NSNumber *available = [_interstitialAdsAvailability objectForKey:adUnitId];
    return (available != nil) && [available boolValue];
}

#pragma mark - Interstitial Delegate


- (void)onInterstitialDidOpen:(nonnull NSString *)adUnitId {
    LogAdapterDelegate_Internal(@"adUnitId = %@", adUnitId);
    id<ISInterstitialAdapterDelegate> delegate = [_interstitialAdUnitIdToSmashDelegate objectForKey:adUnitId];
    [delegate adapterInterstitialDidOpen];
    [delegate adapterInterstitialDidShow];
}

- (void)onInterstitialShowFail:(nonnull NSString *)adUnitId
                     withError:(nonnull NSError *)error {
    LogAdapterDelegate_Internal(@"adUnitId = %@ with error = %@", adUnitId,error);
    id<ISInterstitialAdapterDelegate> delegate = [_interstitialAdUnitIdToSmashDelegate objectForKey:adUnitId];
    [delegate adapterInterstitialDidFailToShowWithError:error];
}

- (void)onInterstitialDidClick:(nonnull NSString *)adUnitId {
    LogAdapterDelegate_Internal(@"adUnitId = %@", adUnitId);
    id<ISInterstitialAdapterDelegate> delegate = [_interstitialAdUnitIdToSmashDelegate objectForKey:adUnitId];
    [delegate adapterInterstitialDidClick];
}

- (void)onInterstitialDidClose:(nonnull NSString *)adUnitId {
    LogAdapterDelegate_Internal(@"adUnitId = %@", adUnitId);
    id<ISInterstitialAdapterDelegate> delegate = [_interstitialAdUnitIdToSmashDelegate objectForKey:adUnitId];
    [delegate adapterInterstitialDidClose];
}
#pragma mark - Banner API

- (void)initBannerWithUserId:(NSString *)userId
               adapterConfig:(ISAdapterConfig *)adapterConfig
                    delegate:(id<ISBannerAdapterDelegate>)delegate {
    
    dispatch_async(dispatch_get_main_queue(), ^{
        NSString *adUnitId = adapterConfig.settings[kAdUnitId];
    
        
        /* Configuration Validation */
        if (![self isConfigValueValid:adUnitId]) {
            NSError *error = [self errorForMissingCredentialFieldWithName:kAdUnitId];
            LogAdapterApi_Internal(@"error = %@", error);
            [delegate adapterBannerInitFailedWithError:error];
            return;
        }
        
        LogAdapterApi_Internal(@"adUnitId = %@", adUnitId);
                
        ISAdMobBannerDelegate *bannerDelegate = [[ISAdMobBannerDelegate alloc] initWithAdUnitId:adUnitId
                                                                                    andDelegate:self];
        
        //add banner to delegate map
        [_bannerAdUnitIdToAdMobAdDelegate setObject:bannerDelegate
                                             forKey:adUnitId];
        
        [_bannerAdUnitIdToSmashDelegate setObject:delegate
                                           forKey:adUnitId];

        switch (_initState) {
            case INIT_STATE_NONE:
            case INIT_STATE_IN_PROGRESS:
                [self initAdMobSDKWithAdapterConfig:adapterConfig];
                break;
            case INIT_STATE_FAILED: {
                LogAdapterApi_Internal(@"init failed - adUnitId = %@", adUnitId);
                [delegate adapterBannerInitFailedWithError:[ISError createError:ERROR_CODE_INIT_FAILED
                                                                    withMessage:@"AdMob SDK init failed"]];
                break;
            }
            case INIT_STATE_SUCCESS:
                [delegate adapterBannerInitSuccess];
                break;
        }
    });
}
- (void)loadBannerWithViewController:(UIViewController *)viewController
                                size:(ISBannerSize *)size
                       adapterConfig:(ISAdapterConfig *)adapterConfig
                            delegate:(id<ISBannerAdapterDelegate>)delegate {

    dispatch_async(dispatch_get_main_queue(), ^{

        NSString *adUnitId = adapterConfig.settings[kAdUnitId];
        LogAdapterApi_Internal(@"adUnitId = %@", adUnitId);
        
        // validate banner size
        if([self isBannerSizeSupported:size]){
            
            // get size
            GADAdSize adMobSize = [self getBannerSize:size];
            
            // create banner
            GADBannerView *banner = [[GADBannerView alloc] initWithAdSize:adMobSize];
            ISAdMobBannerDelegate *bannerDelegate = [_bannerAdUnitIdToAdMobAdDelegate objectForKey:adUnitId];
            banner.delegate = bannerDelegate;
            banner.adUnitID = adUnitId;
            banner.rootViewController = viewController;
            
            // add to dictionary
            [_bannerAds setObject:banner
                           forKey:adUnitId];
            
            // load request
            [banner loadRequest:[self createGADRequest]];
            
        }else{
             // size not supported
             NSError *error = [ISError createError:ERROR_BN_UNSUPPORTED_SIZE
                                       withMessage:@"AdMob unsupported banner size"];
             LogAdapterApi_Internal(@"error = %@", error);
             [delegate adapterBannerDidFailToLoadWithError:error];
        }
        
    });
}
- (void)reloadBannerWithAdapterConfig:(ISAdapterConfig *)adapterConfig
                             delegate:(id<ISBannerAdapterDelegate>)delegate {
    LogInternal_Warning(@"Unsupported method");
}

// destroy banner ad
- (void) destroyBannerWithAdapterConfig:(ISAdapterConfig *)adapterConfig {
}

//check if the network supports adaptive banners
- (BOOL)getAdaptiveBannerSupport {
    return YES;
}

#pragma mark - Banner Delegate

- (void)onBannerDidLoad:(nonnull GADBannerView *)bannerView {
    LogAdapterDelegate_Internal(@"bannerView.adUnitID = %@", bannerView.adUnitID);
    id<ISBannerAdapterDelegate> delegate = [_bannerAdUnitIdToSmashDelegate objectForKey:bannerView.adUnitID];
    [delegate adapterBannerDidLoad:bannerView];
}
- (void)onBannerDidFailToLoad:(nonnull NSString *)adUnitId
                    withError:(nonnull NSError *)error {
    LogAdapterDelegate_Internal(@"bannerView.adUnitID = %@ with error = %@", adUnitId,error);
    NSError *smashError = [self isNoFillError:error] ? [ISError createError:ERROR_BN_LOAD_NO_FILL
                                                                withMessage:@"AdMob no fill"] : error;
    id<ISBannerAdapterDelegate> delegate = [_bannerAdUnitIdToSmashDelegate objectForKey:adUnitId];
    [delegate adapterBannerDidFailToLoadWithError:smashError];
}

- (void)onBannerDidShow:(nonnull NSString *)adUnitId {
    LogAdapterDelegate_Internal(@"bannerView.adUnitID = %@", adUnitId);
    id<ISBannerAdapterDelegate> delegate = [_bannerAdUnitIdToSmashDelegate objectForKey:adUnitId];
    [delegate adapterBannerDidShow];
}

- (void)onBannerDidClick:(nonnull NSString *)adUnitId {
    LogAdapterDelegate_Internal(@"bannerView.adUnitID = %@", adUnitId);
    id<ISBannerAdapterDelegate> delegate = [_bannerAdUnitIdToSmashDelegate objectForKey:adUnitId];
    [delegate adapterBannerDidClick];
}

- (void)onBannerWillPresentScreen:(nonnull NSString *)adUnitId {
    LogAdapterDelegate_Internal(@"bannerView.adUnitID = %@", adUnitId);
    id<ISBannerAdapterDelegate> delegate = [_bannerAdUnitIdToSmashDelegate objectForKey:adUnitId];
    [delegate adapterBannerWillPresentScreen];

}

- (void)onBannerDidDismissScreen:(nonnull NSString *)adUnitId {
    LogAdapterDelegate_Internal(@"bannerView.adUnitID = %@", adUnitId);
    id<ISBannerAdapterDelegate> delegate = [_bannerAdUnitIdToSmashDelegate objectForKey:adUnitId];
    [delegate adapterBannerDidDismissScreen];
}


#pragma mark - Legal Methods

- (void)setConsent:(BOOL)consent {
    LogAdapterApi_Internal(@"value = %@", consent? @"YES" : @"NO");
    _consentCollectingUserData = consent;
    _didSetConsentCollectingUserData = YES;
}

- (void) setCCPAValue:(BOOL)value {
    LogAdapterApi_Internal(@"key = %@ value = %@",kAdMobCCPAKey, value? @"YES" : @"NO");
    
    [NSUserDefaults.standardUserDefaults setBool:value
                                          forKey:kAdMobCCPAKey];
}

- (void)setMetaDataWithKey:(NSString *)key
                 andValues:(NSMutableArray *) values {
    if (values.count == 0) {
            return;
    }
    
    // this is a list of 1 value
    NSString *value = values[0];
    LogAdapterApi_Internal(@"key = %@, value = %@", key, value);
    
    if ([ISMetaDataUtils isValidCCPAMetaDataWithKey:key
                                           andValue:value]) {
        [self setCCPAValue:[ISMetaDataUtils getCCPABooleanValue:value]];
    } else {
        [self setAdMobMetaDataWithKey:[key lowercaseString]
                                value:[value lowercaseString]];
    }
}

- (void) setAdMobMetaDataWithKey:(NSString *)key
                           value:(NSString *)valueString {
    NSString *formattedValueString = valueString;
    
    if ([key isEqualToString:kAdMobTFCD] || [key isEqualToString:kAdMobTFUA]) {
        // Those of the AdMob MetaData keys accept only boolean values
        formattedValueString = [ISMetaDataUtils formatValue:valueString
                                                    forType:(META_DATA_VALUE_BOOL)];
        
        if (!formattedValueString.length) {
            LogAdapterApi_Internal(@"MetaData value for key %@ is invalid %@", key, valueString);
            return;
        }
    }
    
    if ([key isEqualToString:kAdMobTFCD]) {
        BOOL coppaValue = [ISMetaDataUtils getCCPABooleanValue:formattedValueString];
        LogAdapterApi_Internal(@"key = %@, coppaValue = %@", kAdMobTFCD, coppaValue? @"YES" : @"NO");
        [GADMobileAds.sharedInstance.requestConfiguration tagForChildDirectedTreatment:coppaValue];
    } else if ([key isEqualToString:kAdMobTFUA]) {
        BOOL euValue = [ISMetaDataUtils getCCPABooleanValue:formattedValueString];
        LogAdapterApi_Internal(@"key = %@, euValue = %@", kAdMobTFUA, euValue? @"YES" : @"NO");
        [GADMobileAds.sharedInstance.requestConfiguration tagForUnderAgeOfConsent:euValue];
    } else if ([key isEqualToString:kAdMobContentRating]) {
        GADMaxAdContentRating ratingValue = [self getAdMobRatingValue:formattedValueString];
        if (ratingValue.length) {
            LogAdapterApi_Internal(@"key = %@, ratingValue = %@", kAdMobContentRating, formattedValueString);
            [GADMobileAds.sharedInstance.requestConfiguration setMaxAdContentRating: ratingValue];
        }
    }
}

-(GADMaxAdContentRating) getAdMobRatingValue:(NSString *)value {
    if (!value.length) {
        LogInternal_Error(@"The ratingValue is nil");
        return nil;
    }
    
    GADMaxAdContentRating contentValue = nil;
    if ([value isEqualToString:kAdMobMaxContentRatingG]) {
        contentValue = GADMaxAdContentRatingGeneral;
    } else if ([value isEqualToString:kAdMobMaxContentRatingPG]) {
        contentValue = GADMaxAdContentRatingParentalGuidance;
    } else if ([value isEqualToString:kAdMobMaxContentRatingT]) {
        contentValue = GADMaxAdContentRatingTeen;
    } else if ([value isEqualToString:kAdMobMaxContentRatingMA]) {
        contentValue = GADMaxAdContentRatingMatureAudience;
    } else {
        LogInternal_Error(@"The ratingValue = %@ is undefine", value);
    }
    
    return contentValue;
}


#pragma mark - Helper Methods


- (GADRequest *)createGADRequest{
    GADRequest *request = [GADRequest request];
    request.requestAgent = kRequestAgent;
    if ([ISConfigurations getConfigurations].userAge  > kMinUserAge) {
        LogAdapterApi_Internal(@"creating request with age=%ld tagForChildDirectedTreatment=%d", (long)[ISConfigurations getConfigurations].userAge, [ISConfigurations getConfigurations].userAge < kMaxChildAge);
        [GADMobileAds.sharedInstance.requestConfiguration tagForChildDirectedTreatment:([ISConfigurations getConfigurations].userAge < kMaxChildAge)];
    }
    
    if (_didSetConsentCollectingUserData && !_consentCollectingUserData) {
        // The default behavior of the Google Mobile Ads SDK is to serve personalized ads
        // If a user has consented to receive only non-personalized ads, you can configure an GADRequest object with the following code to specify that only non-personalized ads should be returned:
        GADExtras *extras = [[GADExtras alloc] init];
        extras.additionalParameters = @{@"npa": @"1"};
        [request registerAdNetworkExtras:extras];
    }
    return request;
}

- (bool)isBannerSizeSupported:(ISBannerSize *)size {
    if ([size.sizeDescription isEqualToString:@"BANNER"]) {
        return true;
    }
    else if ([size.sizeDescription isEqualToString:@"LARGE"]) {
        return true;
    }
    else if ([size.sizeDescription isEqualToString:@"RECTANGLE"]) {
        return true;
    }
    else if ([size.sizeDescription isEqualToString:@"SMART"]) {
        return true;
    }
    else if ([size.sizeDescription isEqualToString:@"CUSTOM"]) {
        return true;
    }
    
    return false;
}

- (BOOL)getIsAdaptiveBanner:(ISBannerSize *)size {
    //only available from mediation version 7.1.14
    //added respondsToSelector because we want to protect from a crash if the publisher is using an older mediation version and a new admob adapter
    if (size && [size respondsToSelector:@selector(isAdaptive)]) {
        return [size isAdaptive];
    }
        return NO;
}


- (GADAdSize)getBannerSize:(ISBannerSize *)size {
    GADAdSize adMobSize = GADAdSizeInvalid;
    
    if ([size.sizeDescription isEqualToString:@"BANNER"]) {
        adMobSize = GADAdSizeBanner;
    }
    else if ([size.sizeDescription isEqualToString:@"LARGE"]) {
        adMobSize = GADAdSizeLargeBanner;
    }
    else if ([size.sizeDescription isEqualToString:@"RECTANGLE"]) {
        adMobSize = GADAdSizeMediumRectangle;
    }
    else if ([size.sizeDescription isEqualToString:@"SMART"]) {
        if (UI_USER_INTERFACE_IDIOM() == UIUserInterfaceIdiomPad) {
            adMobSize = GADAdSizeLeaderboard;
        }
        else {
            adMobSize = GADAdSizeBanner;
        }
    }
    else if ([size.sizeDescription isEqualToString:@"CUSTOM"]) {
        adMobSize = GADAdSizeFromCGSize(CGSizeMake(size.width, size.height));
    }
    
    if ([self getIsAdaptiveBanner:size]){
        NSInteger originalHeight = adMobSize.size.height;
        adMobSize = GADCurrentOrientationAnchoredAdaptiveBannerAdSizeWithWidth(adMobSize.size.width);
        NSInteger adaptiveHeight = adMobSize.size.height;
        LogAdapterApi_Internal(@"original height - %lu adaptive height - %lu", originalHeight, adaptiveHeight);
    }
    return adMobSize;
}

- (BOOL)isNoFillError:(NSError * _Nonnull)error {
    return (error.code == GADErrorNoFill || error.code == GADErrorMediationNoFill);
}


@end
