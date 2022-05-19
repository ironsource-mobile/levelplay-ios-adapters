//
//  ISFyberAdapter.m
//  ISFyberAdapter
//
//  Created by Gili Ariel on 14/03/2018.
//  Copyright © 2018 IronSource. All rights reserved.
//

#import <IASDKCore/IASDKCore.h>
#import "ISFyberAdapter.h"
#import "ISFyberRewardedVideoListener.h"
#import "ISFyberInterstitialListener.h"
#import "ISFyberBannerListener.h"

typedef NS_ENUM(NSInteger, INIT_STATE) {
    NO_INIT,
    INIT_IN_PROGRESS,
    INIT_SUCCESS,
    INIT_FAILED
};

static NSString * const kAdapterVersion             = FyberAdapterVersion;
static NSString * const kAdapterName                = @"Fyber";
static NSString * const kAdapterSDKName             = @"IASDKCore";
static NSString * const kMediationService           = @"IronSource";
static NSString * const kAppId                      = @"appId";
static NSString * const kSpotId                     = @"adSpotId";
static NSString * const kAdapterDomin               = @"ISFyberAdapter";

static int  requestTimeOut                          = 15;
static BOOL requestUsingSecureConnections           = YES;

static NSInteger kFyberNoFillErrorCode              = 204;

static NSNumber *setConsent = nil;
static NSNumber *setCCPA = nil;
static NSString *userID = nil;
static INIT_STATE initState = NO_INIT;
static ConcurrentMutableSet<ISNetworkInitCallbackProtocol> *initCallbackDelegates = nil;

@interface ISFyberAdapter () <ISFyberRewardedVideoDelegateWrapper, ISFyberInterstitialDelegateWrapper, ISFyberBannerDelegateWrapper ,ISNetworkInitCallbackProtocol>

// Rewarded Video
@property (nonatomic, strong) ConcurrentMutableDictionary *rvSpotIdToRvAd;
@property (nonatomic, strong) ConcurrentMutableDictionary *rvSpotIdToRvUnitController;
@property (nonatomic, strong) ConcurrentMutableDictionary *rvSpotIdToRvListener;
@property (nonatomic, strong) ConcurrentMutableDictionary *rvSpotIdSmashes;
@property (nonatomic, strong) ConcurrentMutableDictionary *rvAdsAvailability;
@property (nonatomic, strong) ConcurrentMutableDictionary *rvSpotIdToRvContentController; // holding the content controllers in the adapter required by the API
@property (nonatomic, strong) NSMutableDictionary         *rvSpotIdToRvMRaidContentController; // holding the raid content controllers in the adapter required by the API
@property (nonatomic, strong) NSMutableSet                *rvSpotIdForInitCallbacks;

// Interstitial
@property (nonatomic, strong) ConcurrentMutableDictionary *isSpotIdToIsAd;
@property (nonatomic, strong) ConcurrentMutableDictionary *isSpotIdToIsUnitController;
@property (nonatomic, strong) ConcurrentMutableDictionary *isSpotIdToIsListener;
@property (nonatomic, strong) ConcurrentMutableDictionary *isSpotIdSmashes;
@property (nonatomic, strong) ConcurrentMutableDictionary *isAdsAvailability;
@property (nonatomic, strong) ConcurrentMutableDictionary *isSpotIdToIsContentController; // holding the content controllers in the adapter required by the API
@property (nonatomic, strong) NSMutableDictionary         *isSpotIdToIsMRaidContentController; // holding the raid content controllers in the adapter required by the API

// Banner
@property (nonatomic, strong) ConcurrentMutableDictionary *bnSpotIdToBnAd;
@property (nonatomic, strong) ConcurrentMutableDictionary *bnSpotIdToBnSize;
@property (nonatomic, strong) ConcurrentMutableDictionary *bnSpotIdToBnUnitController;
@property (nonatomic, strong) ConcurrentMutableDictionary *bnSpotIdSmashes;
@property (nonatomic, strong) ConcurrentMutableDictionary *bnSpotIdToBnListener;
@property (nonatomic, strong) ConcurrentMutableDictionary *bnSpotIdToBnContentController; // holding the content controllers in the adapter required by the API
@property (nonatomic, strong) NSMutableDictionary         *bnSpotIdToBnMRaidContentController; // holding the raid content controllers in the adapter required by the API

@end

@implementation ISFyberAdapter

#pragma mark - Initialization Methods

- (instancetype)initAdapter:(NSString *)name
{
    self = [super initAdapter:name];
    
    if (self) {
        
        self.rvSpotIdToRvAd = [ConcurrentMutableDictionary dictionary];
        self.rvSpotIdToRvUnitController = [ConcurrentMutableDictionary dictionary];
        self.rvSpotIdToRvListener = [ConcurrentMutableDictionary dictionary];
        self.rvSpotIdSmashes = [ConcurrentMutableDictionary dictionary];
        self.rvAdsAvailability = [ConcurrentMutableDictionary dictionary];
        self.rvSpotIdToRvContentController = [ConcurrentMutableDictionary dictionary];
        self.rvSpotIdToRvMRaidContentController = [NSMutableDictionary dictionary];
        self.rvSpotIdForInitCallbacks = [[NSMutableSet alloc] init];
        
        self.isSpotIdToIsAd = [ConcurrentMutableDictionary dictionary];
        self.isSpotIdToIsUnitController = [ConcurrentMutableDictionary dictionary];
        self.isSpotIdToIsListener = [ConcurrentMutableDictionary dictionary];
        self.isSpotIdSmashes = [ConcurrentMutableDictionary dictionary];
        self.isAdsAvailability = [ConcurrentMutableDictionary dictionary];
        self.isSpotIdToIsContentController = [ConcurrentMutableDictionary dictionary];
        self.isSpotIdToIsMRaidContentController = [NSMutableDictionary dictionary];
        
        self.bnSpotIdToBnAd = [ConcurrentMutableDictionary dictionary];
        self.bnSpotIdToBnSize = [ConcurrentMutableDictionary dictionary];
        self.bnSpotIdToBnUnitController = [ConcurrentMutableDictionary dictionary];
        self.bnSpotIdToBnListener = [ConcurrentMutableDictionary dictionary];
        self.bnSpotIdSmashes = [ConcurrentMutableDictionary dictionary];
        self.bnSpotIdToBnContentController = [ConcurrentMutableDictionary dictionary];
        self.bnSpotIdToBnMRaidContentController = [NSMutableDictionary dictionary];
        
        // load while show
        LWSState = LOAD_WHILE_SHOW_BY_INSTANCE;
        
        if (initCallbackDelegates == nil) {
            initCallbackDelegates = [ConcurrentMutableSet<ISNetworkInitCallbackProtocol> set];
        }
    }
    return self;
}

#pragma mark - IronSource Protocol Methods

- (NSString *)version {
    return kAdapterVersion;
}

- (NSString *)sdkVersion {
    return [[IASDKCore sharedInstance] version];
}

- (NSArray *)systemFrameworks {
    return @[@"AdSupport", @"AVFoundation", @"CoreGraphics", @"CoreMedia", @"CoreTelephony", @"MediaPlayer", @"StoreKit", @"SystemConfiguration", @"WebKit"];
}

- (NSString *)sdkName {
    return kAdapterSDKName;
}

- (void)setConsent:(BOOL)consent {
    setConsent = consent == YES ? @1 : @0;
    LogAdapterApi_Internal(@"consent = %@", consent ? @"YES" : @"NO");
    
    if (initState == INIT_SUCCESS) {
        [IASDKCore.sharedInstance setGDPRConsent:consent];
    }
}

- (void)setCCPAValue:(BOOL)value {
    setCCPA = value == YES ? @1 : @0;
    LogAdapterApi_Internal(@"value = %@", value? @"YES" : @"NO");
    
    if (initState == INIT_SUCCESS) {
        NSString *ccpa = [self getFyberCCPAString:[setCCPA intValue]];
        [IASDKCore.sharedInstance setCCPAString:ccpa];
    }
}

- (void)setMetaDataWithKey:(NSString *)key
                 andValues:(NSMutableArray *)values {
    if (values.count == 0) {
        return;
    }
    
    NSString *value = values[0];
    LogAdapterApi_Internal(@"setMetaData: key=%@, value=%@", key, value);
    
    if ([ISMetaDataUtils isValidCCPAMetaDataWithKey:key
                                           andValue:value]) {
        [self setCCPAValue:[ISMetaDataUtils getCCPABooleanValue:value]];
    }
}

#pragma mark - Rewarded Video API

- (void)initRewardedVideoForCallbacksWithUserId:(NSString *)userId
                                  adapterConfig:(ISAdapterConfig *)adapterConfig
                                       delegate:(id<ISRewardedVideoAdapterDelegate>)delegate {
    
    [self.dispatcher dispatchAsyncWithQueue:dispatch_get_main_queue() withBlock:^ {
        NSString *appId = adapterConfig.settings[kAppId];
        NSString *spotId = adapterConfig.settings[kSpotId];

        if (![self isConfigValueValid:appId]) {
            NSError *error = [self errorForMissingCredentialFieldWithName:kAppId];
            LogAdapterApi_Internal(@"error = %@", error);
            [delegate adapterRewardedVideoInitFailed:error];
            return;
        }
        
        if (![self isConfigValueValid:spotId]) {
            NSError *error = [self errorForMissingCredentialFieldWithName:kSpotId];
            LogAdapterApi_Internal(@"error = %@", error);
            [delegate adapterRewardedVideoInitFailed:error];
            return;
        }
        
        LogAdapterApi_Internal(@"appId = %@, spotId = %@", appId, spotId);

        // add delegate to dictionary
        [self.rvSpotIdSmashes setObject:delegate
                                 forKey:spotId];
        [self.rvSpotIdForInitCallbacks addObject:spotId];

        if (initState == INIT_SUCCESS) {
            // initiate rewarded video ad request
            [self initiateFyberRewardedVideoWithSpotID:spotId];
            [delegate adapterRewardedVideoInitSuccess];
        } else if (initState == INIT_FAILED) {
            [delegate adapterRewardedVideoInitFailed:[NSError errorWithDomain:kAdapterName
                                                                         code:ERROR_CODE_INIT_FAILED
                                                                     userInfo:@{NSLocalizedDescriptionKey:@"Fyber SDK init failed"}]];
        } else {
            [self initFyberSDKWithAppId:appId
                                 userId:userId];
        }
    }];
}

- (void)initAndLoadRewardedVideoWithUserId:(NSString *)userId
                             adapterConfig:(ISAdapterConfig *)adapterConfig
                                  delegate:(id<ISRewardedVideoAdapterDelegate>)delegate {
    
    [self.dispatcher dispatchAsyncWithQueue:dispatch_get_main_queue() withBlock:^ {
        NSString *appId = adapterConfig.settings[kAppId];
        NSString *spotId = adapterConfig.settings[kSpotId];

        if (![self isConfigValueValid:appId]) {
            NSError *error = [self errorForMissingCredentialFieldWithName:kAppId];
            LogAdapterApi_Internal(@"error = %@", error);
            [delegate adapterRewardedVideoHasChangedAvailability:NO];
            return;
        }
        
        if (![self isConfigValueValid:spotId]) {
            NSError *error = [self errorForMissingCredentialFieldWithName:kSpotId];
            LogAdapterApi_Internal(@"error = %@", error);
            [delegate adapterRewardedVideoHasChangedAvailability:NO];
            return;
        }
        
        LogAdapterApi_Internal(@"appId = %@, spotId = %@", appId, spotId);

        // add delegate to dictionary
        [self.rvSpotIdSmashes setObject:delegate
                                 forKey:spotId];

        if (initState == INIT_SUCCESS) {
            // initiate rewarded video ad request
            [self initiateFyberRewardedVideoWithSpotID:spotId];
            [self loadRewardedVideoAd:spotId
                             delegate:delegate];
        } else if (initState == INIT_FAILED) {
            [delegate adapterRewardedVideoHasChangedAvailability:NO];
        } else {
            [self initFyberSDKWithAppId:appId
                                 userId:userId];
        }
    }];
}

- (void)fetchRewardedVideoForAutomaticLoadWithAdapterConfig:(ISAdapterConfig *)adapterConfig
                                                   delegate:(id<ISRewardedVideoAdapterDelegate>)delegate {
    NSString *spotId = adapterConfig.settings[kSpotId];
    LogAdapterApi_Internal(@"spotId = %@", spotId);
    [self loadRewardedVideoAd:spotId delegate:delegate];
}

- (void)loadRewardedVideoAd:(NSString *)spotId
                   delegate:(id<ISRewardedVideoAdapterDelegate>)delegate {
    [self.dispatcher dispatchAsyncWithQueue:dispatch_get_main_queue() withBlock:^ {
        LogAdapterApi_Internal(@"spotId = %@", spotId);
                
        IAAdSpot *rewardedVideoAdSpot = [self.rvSpotIdToRvAd objectForKey:spotId];
        IAFullscreenUnitController *rewardedVideoUnitController = [self.rvSpotIdToRvUnitController objectForKey:spotId];
        
        if (!rewardedVideoAdSpot || !rewardedVideoUnitController) {
            LogAdapterApi_Internal(@"no spot found or no ad from dictionaries");
            [self.rvAdsAvailability setObject:@NO
                                       forKey:spotId];
            [delegate adapterRewardedVideoHasChangedAvailability:NO];
            return;
        }
        
        [rewardedVideoAdSpot fetchAdWithCompletion:^(IAAdSpot * _Nullable adSpot, IAAdModel * _Nullable adModel, NSError * _Nullable error) {
            if (error || adSpot.activeUnitController != rewardedVideoUnitController) {
                [self.rvAdsAvailability setObject:@NO
                                           forKey:spotId];
                [delegate adapterRewardedVideoHasChangedAvailability:NO];
                
                if (error) {
                    if (error.code == kFyberNoFillErrorCode) {
                        error = [NSError errorWithDomain:kAdapterName
                                                    code:ERROR_RV_LOAD_NO_FILL
                                                userInfo:@{NSLocalizedDescriptionKey : @"Fyber no fill"}];
                    }
                    
                    LogAdapterApi_Internal(@"error = %@", error);
                    [delegate adapterRewardedVideoDidFailToLoadWithError:error];
                }
            } else {
                [self.rvAdsAvailability setObject:@YES
                                           forKey:spotId];
                [delegate adapterRewardedVideoHasChangedAvailability:YES];
            }
        }];
    }];
}

- (void)showRewardedVideoWithViewController:(UIViewController *)viewController
                              adapterConfig:(ISAdapterConfig *)adapterConfig
                                   delegate:(id<ISRewardedVideoAdapterDelegate>)delegate {
    NSString *spotId = adapterConfig.settings[kSpotId];
    LogAdapterApi_Internal(@"spotId = %@", spotId);
    
    //set dynamic user Id
    if ([self dynamicUserId]) {
        LogAdapterApi_Internal(@"set userID to %@", [self dynamicUserId]);
        IASDKCore.sharedInstance.userID = [self dynamicUserId];
    }
    
    ISFyberRewardedVideoListener *listener = [self.rvSpotIdToRvListener objectForKey:spotId];
    
    if (listener != nil) {
        // updating the view controller required by the API delegate
        listener.viewControllerForPresentingModalView = viewController;
    }
    
    [delegate adapterRewardedVideoHasChangedAvailability:NO];
    
    IAFullscreenUnitController *rewardedVideoUnitController = [self.rvSpotIdToRvUnitController objectForKey:spotId];
    
    if (rewardedVideoUnitController != nil && [self hasRewardedVideoWithAdapterConfig:adapterConfig] && [rewardedVideoUnitController isReady]) {
        [self.dispatcher dispatchAsyncWithQueue:dispatch_get_main_queue() withBlock:^ {
            [rewardedVideoUnitController showAdAnimated:YES
                                             completion:nil];
        }];
    } else {
        NSError *error = [NSError errorWithDomain:kAdapterName
                                             code:ERROR_CODE_NO_ADS_TO_SHOW
                                         userInfo:@{NSLocalizedDescriptionKey:[NSString stringWithFormat: @"%@ show failed", kAdapterName]}];
        LogAdapterApi_Internal(@"error = %@", error);
        [delegate adapterRewardedVideoDidFailToShowWithError:error];
    }
    
    // Must be set to NO after attempting to show so it will not affect the check for isReady
    [self.rvAdsAvailability setObject:@NO
                               forKey:spotId];
}

- (BOOL)hasRewardedVideoWithAdapterConfig:(ISAdapterConfig *)adapterConfig {
    NSString *spotId = adapterConfig.settings[kSpotId];
    LogAdapterApi_Internal(@"spotId = %@", spotId);
    // API for readiness of ad is not to be used according to Fyber.
    // Instead, the callbacks should be used to determine the readiness of the ad
    NSNumber *available = [self.rvAdsAvailability objectForKey:spotId];
    return (available != nil) && [available boolValue];
}

#pragma mark - Interstitial API

- (void)initInterstitialWithUserId:(NSString *)userId
                     adapterConfig:(ISAdapterConfig *)adapterConfig
                          delegate:(id<ISInterstitialAdapterDelegate>)delegate {
    [self.dispatcher dispatchAsyncWithQueue:dispatch_get_main_queue() withBlock:^ {
        NSString *appId = adapterConfig.settings[kAppId];
        NSString *spotId = adapterConfig.settings[kSpotId];

        if (![self isConfigValueValid:appId]) {
            NSError *error = [self errorForMissingCredentialFieldWithName:kAppId];
            LogAdapterApi_Internal(@"error = %@", error);
            [delegate adapterInterstitialInitFailedWithError:error];
            return;
        }
        
        if (![self isConfigValueValid:spotId]) {
            NSError *error = [self errorForMissingCredentialFieldWithName:kSpotId];
            LogAdapterApi_Internal(@"error = %@", error);
            [delegate adapterInterstitialInitFailedWithError:error];
            return;
        }
        
        LogAdapterApi_Internal(@"appId = %@, spotId = %@", appId, spotId);
                
        // add delegate to dictionary
        [self.isSpotIdSmashes setObject:delegate
                                 forKey:spotId];
        
        if (initState == INIT_SUCCESS) {
            // initiate interstitial ad request
            [self initiateFyberInterstitialWithSpotID:spotId];
            [delegate adapterInterstitialInitSuccess];
        } else if (initState == INIT_FAILED) {
            [delegate adapterInterstitialInitFailedWithError:[NSError errorWithDomain:kAdapterName
                                                                                 code:ERROR_CODE_INIT_FAILED
                                                                             userInfo:@{NSLocalizedDescriptionKey:@"Fyber SDK init failed"}]];
        } else {
            [self initFyberSDKWithAppId:appId
                                 userId:userId];
        }
    }];
}

- (void)loadInterstitialWithAdapterConfig:(ISAdapterConfig *)adapterConfig
                                 delegate:(id<ISInterstitialAdapterDelegate>)delegate {
    [self.dispatcher dispatchAsyncWithQueue:dispatch_get_main_queue() withBlock:^ {
        
        NSString *spotId = adapterConfig.settings[kSpotId];
        LogAdapterApi_Internal(@"spotId = %@", spotId);

        IAAdSpot *interstitialAdSpot = [self.isSpotIdToIsAd objectForKey:spotId];
        IAFullscreenUnitController *interstitialUnitController = [self.isSpotIdToIsUnitController objectForKey:spotId];
        
        if (!interstitialAdSpot || !interstitialUnitController) {
            [self.isAdsAvailability setObject:@NO
                                       forKey:spotId];
            NSError *error = [NSError errorWithDomain:kAdapterName
                                                 code:ERROR_CODE_NO_ADS_TO_SHOW
                                             userInfo:@{NSLocalizedDescriptionKey:[NSString stringWithFormat: @"%@ load failed", kAdapterName]}];
            LogAdapterApi_Internal(@"error = %@", error);
            [delegate adapterInterstitialDidFailToLoadWithError:error];
            return;
        }
        
        [interstitialAdSpot fetchAdWithCompletion:^(IAAdSpot * _Nullable adSpot, IAAdModel * _Nullable adModel, NSError * _Nullable error) {
            if (error || adSpot.activeUnitController != interstitialUnitController) {
                [self.isAdsAvailability setObject:@NO
                                           forKey:spotId];
                
                if (error == nil) {
                    error = [NSError errorWithDomain:kAdapterName
                                                code:ERROR_CODE_NO_ADS_TO_SHOW
                                            userInfo:@{NSLocalizedDescriptionKey:[NSString stringWithFormat: @"%@ load failed", kAdapterName]}];
                } else if (error.code == kFyberNoFillErrorCode) {
                    error = [NSError errorWithDomain:kAdapterName
                                                code:ERROR_IS_LOAD_NO_FILL
                                            userInfo:@{NSLocalizedDescriptionKey : @"Fyber no fill"}];
                }
                
                LogAdapterApi_Internal(@"error = %@", error);
                [delegate adapterInterstitialDidFailToLoadWithError:error];
            } else {
                [self.isAdsAvailability setObject:@YES
                                           forKey:spotId];
                [delegate adapterInterstitialDidLoad];
            }
        }];
    }];
}

- (void)showInterstitialWithViewController:(UIViewController *)viewController
                             adapterConfig:(ISAdapterConfig *)adapterConfig
                                  delegate:(id<ISInterstitialAdapterDelegate>)delegate {
    NSString *spotId = adapterConfig.settings[kSpotId];
    LogAdapterApi_Internal(@"spotId = %@", spotId);
    
    ISFyberInterstitialListener *listener = [self.isSpotIdToIsListener objectForKey:spotId];
    
    if (listener != nil) {
        // updating the view controller required by the API delegate
        listener.viewControllerForPresentingModalView = viewController;
    }
    
    IAFullscreenUnitController *interstitialUnitController = [self.isSpotIdToIsUnitController objectForKey:spotId];
    
    if ([self hasInterstitialWithAdapterConfig:adapterConfig] && interstitialUnitController != nil && [interstitialUnitController isReady]) {
        [self.dispatcher dispatchAsyncWithQueue:dispatch_get_main_queue() withBlock:^ {
            [interstitialUnitController showAdAnimated:NO
                                            completion:nil];
        }];
    } else {
        NSError *error = [NSError errorWithDomain:kAdapterName
                                             code:ERROR_CODE_NO_ADS_TO_SHOW
                                         userInfo:@{NSLocalizedDescriptionKey:[NSString stringWithFormat: @"%@ show failed", kAdapterName]}];
        LogAdapterApi_Internal(@"error = %@", error);
        [delegate adapterInterstitialDidFailToShowWithError:error];
    }
    
    // Must be set to NO after attempting to show so it will not affect the check for isReady
    [self.isAdsAvailability setObject:@NO
                               forKey:spotId];
}

- (BOOL)hasInterstitialWithAdapterConfig:(ISAdapterConfig *)adapterConfig {
    NSString *spotId = adapterConfig.settings[kSpotId];
    LogAdapterApi_Internal(@"spotId = %@", spotId);
    NSNumber *available = [self.isAdsAvailability objectForKey:spotId];
    return (available != nil) && [available boolValue];
}

#pragma mark - Banner API

- (void)initBannerWithUserId:(nonnull NSString *)userId
               adapterConfig:(nonnull ISAdapterConfig *)adapterConfig
                    delegate:(nonnull id<ISBannerAdapterDelegate>)delegate {
    [self.dispatcher dispatchAsyncWithQueue:dispatch_get_main_queue() withBlock:^ {
        NSString *appId = adapterConfig.settings[kAppId];
        NSString *spotId = adapterConfig.settings[kSpotId];

        if (![self isConfigValueValid:appId]) {
            NSError *error = [self errorForMissingCredentialFieldWithName:kAppId];
            LogAdapterApi_Internal(@"error = %@", error);
            [delegate adapterBannerInitFailedWithError:error];
            return;
        }
        
        if (![self isConfigValueValid:spotId]) {
            NSError *error = [self errorForMissingCredentialFieldWithName:kSpotId];
            LogAdapterApi_Internal(@"error = %@", error);
            [delegate adapterBannerInitFailedWithError:error];
            return;
        }
        
        LogAdapterApi_Internal(@"appId = %@, spotId = %@", appId, spotId);
                
        // add delegate to dictionary
        [self.bnSpotIdSmashes setObject:delegate
                                 forKey:spotId];
        
        if (initState == INIT_SUCCESS) {
            // initiate banner ad request
            [self initiateFyberBannerWithSpotID:spotId];
            [delegate adapterBannerInitSuccess];
        } else if (initState == INIT_FAILED) {
            [delegate adapterBannerInitFailedWithError:[NSError errorWithDomain:kAdapterName
                                                                           code:ERROR_CODE_INIT_FAILED
                                                                       userInfo:@{NSLocalizedDescriptionKey:@"Fyber SDK init failed"}]];
        } else {
            [self initFyberSDKWithAppId:appId
                                 userId:userId];
        }
    }];
}

- (void)loadBannerWithViewController:(nonnull UIViewController *)viewController
                                size:(ISBannerSize *)size
                       adapterConfig:(nonnull ISAdapterConfig *)adapterConfig
                            delegate:(nonnull id <ISBannerAdapterDelegate>)delegate {
    NSString *spotId = adapterConfig.settings[kSpotId];
    LogAdapterApi_Internal(@"spotId = %@", spotId);

    ISFyberBannerListener *listener = [self.bnSpotIdToBnListener objectForKey:spotId];
    
    if (listener != nil) {
        // updating the view controller required by the API delegate
        listener.viewControllerForPresentingModalView = viewController;
    }
    
    if (![self isBannerSizeSupported:size]) {
        NSError *error = [NSError errorWithDomain:kAdapterName
                                             code:ERROR_BN_UNSUPPORTED_SIZE
                                         userInfo:@{NSLocalizedDescriptionKey:@"Fyber unsupported banner size"}];
        LogAdapterApi_Internal(@"error = %@", error);
        [delegate adapterBannerDidFailToLoadWithError:error];
        return;
    }
    
    // add size for spot id
    [self.bnSpotIdToBnSize setObject:size
                              forKey:spotId];
    
    IAViewUnitController *bannerUnitController = [self.bnSpotIdToBnUnitController objectForKey:spotId];
    IAAdSpot *bannerAdSpot = [self.bnSpotIdToBnAd objectForKey:spotId];
    
    if (!bannerAdSpot || !bannerUnitController) {
        NSError *error = [NSError errorWithDomain:kAdapterName
                                             code:ERROR_BN_LOAD_EXCEPTION
                                         userInfo:@{NSLocalizedDescriptionKey:@"Fyber load banner failed"}];
        LogAdapterApi_Internal(@"error = %@", error);
        [delegate adapterBannerDidFailToLoadWithError:error];
        return;
    }
    
    CGSize bannerSize = [self getBannerSize:size];
    bannerUnitController.adView.bounds = CGRectMake(0, 0, bannerSize.width, bannerSize.height);
    
    [bannerAdSpot fetchAdWithCompletion:^(IAAdSpot * _Nullable adSpot, IAAdModel * _Nullable adModel, NSError * _Nullable error) {
        if (error || adSpot.activeUnitController != bannerUnitController) {
            if (error == nil) {
                error  = [NSError errorWithDomain:kAdapterName
                                             code:ERROR_BN_LOAD_EXCEPTION
                                         userInfo:@{NSLocalizedDescriptionKey:@"Fyber load banner failed"}];
            } else if (error.code == kFyberNoFillErrorCode) {
                error = [NSError errorWithDomain:kAdapterName
                                            code:ERROR_BN_LOAD_NO_FILL
                                        userInfo:@{NSLocalizedDescriptionKey : @"Fyber no fill"}];
            }
            
            LogAdapterApi_Internal(@"error = %@", error);
            [delegate adapterBannerDidFailToLoadWithError:error];
        } else {
            [delegate adapterBannerDidLoad:bannerUnitController.adView];
        }
    }];
}

/// This method will not be called from version 6.14.0 - we leave it here for backwords compatibility
- (void)reloadBannerWithAdapterConfig:(nonnull ISAdapterConfig *)adapterConfig
                             delegate:(nonnull id <ISBannerAdapterDelegate>)delegate {
    
    // get spot id
    NSString *spotId = adapterConfig.settings[kSpotId];
    LogAdapterApi_Internal(@"spotId = %@", spotId);
    
    @try {
        // get view controller for spot id
        ISFyberBannerListener *listener = [self.bnSpotIdToBnListener objectForKey:spotId];
        UIViewController *viewController = listener.viewControllerForPresentingModalView;
        
        // get size
        ISBannerSize *size = [self.bnSpotIdToBnSize objectForKey:spotId];
        
        // call load
        [self loadBannerWithViewController:viewController
                                      size:size
                             adapterConfig:adapterConfig
                                  delegate:delegate];
        
    } @catch (NSException *exception) {
        NSError *error = [NSError errorWithDomain:kAdapterName
                                             code:ERROR_CODE_NO_ADS_TO_SHOW
                                         userInfo:@{NSLocalizedDescriptionKey:[NSString stringWithFormat:@"Fyber reloadBanner failed - exception = %@", exception]}];
        LogAdapterApi_Internal(@"error = %@", error);
        [delegate adapterBannerDidFailToLoadWithError:error];
    }
}

- (BOOL)shouldBindBannerViewOnReload {
    return YES;
}

- (void)destroyBannerWithAdapterConfig:(nonnull ISAdapterConfig *)adapterConfig {
    LogAdapterApi_Internal(@"");
    // NO required API to destroy the banner
}

#pragma mark - Rewarded Video Delegate

- (void)onRewardedVideoDidShow:(NSString *)spotId {
    LogAdapterDelegate_Internal(@"spotId = %@", spotId);
    id<ISRewardedVideoAdapterDelegate> delegate = [self.rvSpotIdSmashes objectForKey:spotId];
    
    if (delegate) {
        [delegate adapterRewardedVideoDidStart];
        [delegate adapterRewardedVideoDidOpen];
    }
}

- (void)onRewardedVideoShowFailed:(NSString *)spotId
                        withError:(NSError *)error {
    LogAdapterDelegate_Internal(@"spotId = %@, error = %@", spotId, error);
    id<ISRewardedVideoAdapterDelegate> delegate = [self.rvSpotIdSmashes objectForKey:spotId];
    
    if (delegate) {
        [delegate adapterRewardedVideoDidFailToShowWithError:error];
    }
}

- (void)onRewardedVideoDidClick:(NSString *)spotId {
    LogAdapterDelegate_Internal(@"spotId = %@", spotId);
    id<ISRewardedVideoAdapterDelegate> delegate = [self.rvSpotIdSmashes objectForKey:spotId];
    
    if (delegate) {
        [delegate adapterRewardedVideoDidClick];
    }
}

- (void)onRewardedVideoDidReceiveReward:(NSString *)spotId {
    LogAdapterDelegate_Internal(@"spotId = %@", spotId);
    id<ISRewardedVideoAdapterDelegate> delegate = [self.rvSpotIdSmashes objectForKey:spotId];
    
    if (delegate) {
        [delegate adapterRewardedVideoDidReceiveReward];
    }
}

- (void)onRewardedVideoDidClose:(NSString *)spotId {
    LogAdapterDelegate_Internal(@"spotId = %@", spotId);
    id<ISRewardedVideoAdapterDelegate> delegate = [self.rvSpotIdSmashes objectForKey:spotId];
    
    if (delegate) {
        [delegate adapterRewardedVideoDidEnd];
        [delegate adapterRewardedVideoDidClose];
    }
}

#pragma mark - Interstitial Delegate

- (void)onInterstitialDidShow:(NSString *)spotId {
    LogAdapterDelegate_Internal(@"spotId = %@", spotId);
    id<ISInterstitialAdapterDelegate> delegate = [self.isSpotIdSmashes objectForKey:spotId];
    
    if (delegate) {
        [delegate adapterInterstitialDidOpen];
        [delegate adapterInterstitialDidShow];
    }
}

- (void)onInterstitialShowFailed:(NSString *)spotId
                       withError:(NSError *)error {
    LogAdapterDelegate_Internal(@"spotId = %@, error = %@", spotId, error);
    id<ISInterstitialAdapterDelegate> delegate = [self.isSpotIdSmashes objectForKey:spotId];
    
    if (delegate) {
        [delegate adapterInterstitialDidFailToShowWithError:error];
    }
}

- (void)onInterstitialDidClick:(NSString *)spotId {
    LogAdapterDelegate_Internal(@"spotId = %@", spotId);
    id<ISInterstitialAdapterDelegate> delegate = [self.isSpotIdSmashes objectForKey:spotId];
    
    if (delegate) {
        [delegate adapterInterstitialDidClick];
    }
}

- (void)onInterstitialDidClose:(NSString *)spotId {
    LogAdapterDelegate_Internal(@"spotId = %@", spotId);
    id<ISInterstitialAdapterDelegate> delegate = [self.isSpotIdSmashes objectForKey:spotId];
    
    if (delegate) {
        [delegate adapterInterstitialDidClose];
    }
}

#pragma mark - Banner Delegate

- (void)onBannerDidShow:(NSString *)spotId {
    LogAdapterDelegate_Internal(@"spotId = %@", spotId);
    id<ISBannerAdapterDelegate> delegate = [self.bnSpotIdSmashes objectForKey:spotId];
    
    if (delegate) {
        [delegate adapterBannerDidShow];
    }
}

- (void)onBannerDidShowFailed:(NSString *)spotId
                    withError:(NSError *)error {
    LogAdapterDelegate_Internal(@"spotId = %@, error = %@", spotId, error);
}

- (void)onBannerDidClick:(NSString *)spotId {
    LogAdapterDelegate_Internal(@"spotId = %@", spotId);
    id<ISBannerAdapterDelegate> delegate = [self.bnSpotIdSmashes objectForKey:spotId];
    
    if (delegate) {
        [delegate adapterBannerDidClick];
    }
}

- (void)onBannerBannerWillLeaveApplication:(NSString *)spotId {
    LogAdapterDelegate_Internal(@"spotId = %@", spotId);
    id<ISBannerAdapterDelegate> delegate = [self.bnSpotIdSmashes objectForKey:spotId];
    
    if (delegate) {
        [delegate adapterBannerWillLeaveApplication];
    }
}

#pragma mark - ISNetworkInitCallbackProtocol

- (void)onNetworkInitCallbackSuccess {
    //set Fyber User ID
    if (userID != nil && userID.length > 0) {
        LogAdapterApi_Internal(@"set userID to %@", userID);
        IASDKCore.sharedInstance.userID = userID;
    }
    
    // set consent
    if (setConsent != nil) {
        [self setConsent:[setConsent intValue] == 1 ? YES : NO];
    }
    
    // set ccpa
    if (setCCPA != nil) {
        [self setCCPAValue:[setCCPA intValue] == 1 ? YES : NO];
    }

    // rewarded video
    NSArray *rewardedVideoSpotIDs = self.rvSpotIdSmashes.allKeys;

    for (NSString *spotId in rewardedVideoSpotIDs) {
        id<ISRewardedVideoAdapterDelegate> delegate = [self.rvSpotIdSmashes objectForKey:spotId];
        // initiate rewarded video ad request
        [self initiateFyberRewardedVideoWithSpotID:spotId];
        
        if ([self.rvSpotIdForInitCallbacks containsObject:spotId]) {
            [delegate adapterRewardedVideoInitSuccess];
        } else {
            // call to load rv
            [self loadRewardedVideoAd:spotId delegate:delegate];
        }
    }

    // interstitial
    NSArray *interstitialSpotIDs = self.isSpotIdSmashes.allKeys;

    for (NSString *spotId in interstitialSpotIDs) {
        id<ISInterstitialAdapterDelegate> delegate = [self.isSpotIdSmashes objectForKey:spotId];
        // initiate interstitial ad request
        [self initiateFyberInterstitialWithSpotID:spotId];
        [delegate adapterInterstitialInitSuccess];
    }

    // banner
    NSArray *bannerSpotIDs = self.bnSpotIdSmashes.allKeys;

    for (NSString *spotId in bannerSpotIDs) {
        id<ISBannerAdapterDelegate> delegate = [self.bnSpotIdSmashes objectForKey:spotId];
        // initiate banner ad request
        [self initiateFyberBannerWithSpotID:spotId];
        [delegate adapterBannerInitSuccess];
    }
}

- (void)onNetworkInitCallbackFailed:(nonnull NSString *)errorMessage {
    NSError *error = [NSError errorWithDomain:kAdapterName
                                         code:ERROR_CODE_INIT_FAILED
                                     userInfo:@{NSLocalizedDescriptionKey:errorMessage}];

    // rewarded video
    NSArray *rewardedVideoSpotIDs = self.rvSpotIdSmashes.allKeys;

    for (NSString *spotId in rewardedVideoSpotIDs) {
        id<ISRewardedVideoAdapterDelegate> delegate = [self.rvSpotIdSmashes objectForKey:spotId];
        
        if ([self.rvSpotIdForInitCallbacks containsObject:spotId]) {
            [delegate adapterRewardedVideoInitFailed:error];
        } else {
            [delegate adapterRewardedVideoHasChangedAvailability:NO];
        }
    }

    // interstitial
    NSArray *interstitialSpotIDs = self.isSpotIdSmashes.allKeys;

    for (NSString *spotId in interstitialSpotIDs) {
        id<ISInterstitialAdapterDelegate> delegate = [self.isSpotIdSmashes objectForKey:spotId];
        [delegate adapterInterstitialInitFailedWithError:error];
    }

    // banner
    NSArray *bannerSpotIDs = self.bnSpotIdSmashes.allKeys;

    for (NSString *spotId in bannerSpotIDs) {
        id<ISBannerAdapterDelegate> delegate = [self.bnSpotIdSmashes objectForKey:spotId];
        [delegate adapterBannerInitFailedWithError:error];
    }
}

#pragma mark - Private Methods

- (void)initFyberSDKWithAppId:(NSString *)appId userId:(NSString *)userId {
    if (initState == NO_INIT || initState == INIT_IN_PROGRESS) {
        [initCallbackDelegates addObject:self];
    }
    
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        
        LogAdapterApi_Internal(@"appId = %@", appId);
        userID = userId;
        // set init state
        initState = INIT_IN_PROGRESS;
        
        /* Initialize Fyber Ads SDK */
        [[IASDKCore sharedInstance] initWithAppID:appId completionBlock:^(BOOL success, NSError * _Nullable error) {
            initState = (success ? INIT_SUCCESS : INIT_FAILED);
            
            NSArray *initDelegatesList = initCallbackDelegates.allObjects;
            
            for (id<ISNetworkInitCallbackProtocol> delegate in initDelegatesList) {
                if (success) {
                    LogAdapterDelegate_Internal(@"Fyber Successfully initialized");
                    [delegate onNetworkInitCallbackSuccess];
                } else {
                    NSString *errorReason = [NSString stringWithFormat:@"Fyber SDK init failed - %@", (error? error.localizedDescription : @"")];
                    LogAdapterDelegate_Error(@"%@", errorReason);
                    [delegate onNetworkInitCallbackFailed:errorReason];
                }
            }
            
            // remove all init callback delegates
            [initCallbackDelegates removeAllObjects];
            
        } completionQueue:dispatch_get_main_queue()];
    });
}

- (NSString *)getFyberCCPAString:(int)value {
    if (value == 1) {
        return @"1YY-";
    }
    
    return @"1YN-";
}

- (void) initiateFyberRewardedVideoWithSpotID:(NSString *)spotID {
    IAAdRequest *request = [self getRequestForSpotID:spotID];
    ISFyberRewardedVideoListener *listener = [[ISFyberRewardedVideoListener alloc] initWithSpotId:spotID
                                                                                      andDelegate:self];
    [self.rvSpotIdToRvListener setObject:listener
                                  forKey:spotID];
    
    IAVideoContentController *rewardedVideoContentController = [IAVideoContentController build:^(id<IAVideoContentControllerBuilder> _Nonnull builder) {
        
        builder.videoContentDelegate = listener;
    }];
    
    [self.rvSpotIdToRvContentController setObject:rewardedVideoContentController
                                           forKey:spotID];
    
    IAMRAIDContentController *rewardedvideoMRAIDContentController = [IAMRAIDContentController build:^(id<IAMRAIDContentControllerBuilder> _Nonnull builder) {
    }];
    
    [self.rvSpotIdToRvMRaidContentController setObject:rewardedvideoMRAIDContentController
                                                forKey:spotID];
    
    IAFullscreenUnitController *rewardedVideoUnitController = [IAFullscreenUnitController build:^(id<IAFullscreenUnitControllerBuilder> _Nonnull builder) {
        builder.unitDelegate = listener;
        
        [builder addSupportedContentController:rewardedvideoMRAIDContentController];
        [builder addSupportedContentController:rewardedVideoContentController];
    }];
    
    [self.rvSpotIdToRvUnitController setObject:rewardedVideoUnitController
                                        forKey:spotID];
    
    IAAdSpot *rewardedVideoAdSpot = [IAAdSpot build:^(id<IAAdSpotBuilder> _Nonnull builder) {
        // set request
        builder.adRequest = request;
        
        // set mediation type
        builder.mediationType = [IAMediationIronSource new];
        
        // add supported unit controller
        [builder addSupportedUnitController:rewardedVideoUnitController];
    }];
    
    [self.rvSpotIdToRvAd setObject:rewardedVideoAdSpot
                            forKey:spotID];
}

- (void)initiateFyberInterstitialWithSpotID:(NSString *)spotID {
    
    IAAdRequest *request = [self getRequestForSpotID:spotID];
    ISFyberInterstitialListener *listener = [[ISFyberInterstitialListener alloc] initWithSpotId:spotID
                                                                                    andDelegate:self];
    [self.isSpotIdToIsListener setObject:listener
                                  forKey:spotID];
    
    IAVideoContentController *interstitialVideoContentController = [IAVideoContentController build:^(id<IAVideoContentControllerBuilder> _Nonnull builder) {
        builder.videoContentDelegate = listener;
    }];
    
    [self.isSpotIdToIsContentController setObject:interstitialVideoContentController
                                           forKey:spotID];
    
    IAMRAIDContentController *interstitialMRAIDContentController = [IAMRAIDContentController build:^(id<IAMRAIDContentControllerBuilder> _Nonnull builder) {
    }];
    
    [self.isSpotIdToIsMRaidContentController setObject:interstitialMRAIDContentController
                                                forKey:spotID];
    
    IAFullscreenUnitController *interstitialUnitController = [IAFullscreenUnitController build:^(id<IAFullscreenUnitControllerBuilder> _Nonnull builder) {
        builder.unitDelegate = listener;
        
        [builder addSupportedContentController:interstitialVideoContentController];
        [builder addSupportedContentController:interstitialMRAIDContentController];
    }];
    
    [self.isSpotIdToIsUnitController setObject:interstitialUnitController
                                        forKey:spotID];
    
    IAAdSpot *interstitialAdSpot = [IAAdSpot build:^(id<IAAdSpotBuilder> _Nonnull builder) {
        // set request
        builder.adRequest = request;
        
        // set mediation type
        builder.mediationType = [IAMediationIronSource new];
        
        // add supported unit controller
        [builder addSupportedUnitController:interstitialUnitController];
    }];
    
    [self.isSpotIdToIsAd setObject:interstitialAdSpot
                            forKey:spotID];
}

- (void)initiateFyberBannerWithSpotID:(NSString *)spotID {
    
    IAAdRequest *request = [self getRequestForSpotID:spotID];
    ISFyberBannerListener *listener = [[ISFyberBannerListener alloc] initWithSpotId:spotID
                                                                        andDelegate:self];
    [self.bnSpotIdToBnListener setObject:listener
                                  forKey:spotID];
    
    IAVideoContentController *bannerVideoContentController = [IAVideoContentController build:^(id<IAVideoContentControllerBuilder> _Nonnull builder) {
        builder.videoContentDelegate = listener;
    }];
    
    [self.bnSpotIdToBnContentController setObject:bannerVideoContentController
                                           forKey:spotID];
    
    IAMRAIDContentController *bannerMRAIDContentController = [IAMRAIDContentController build:^(id<IAMRAIDContentControllerBuilder> _Nonnull builder) {}];
    [self.bnSpotIdToBnMRaidContentController setObject:bannerMRAIDContentController
                                                forKey:spotID];
    
    IAViewUnitController *bannerUnitController = [IAViewUnitController build:^(id<IAViewUnitControllerBuilder> _Nonnull builder) {
        builder.unitDelegate = listener;
        
        [builder addSupportedContentController:bannerVideoContentController];
        [builder addSupportedContentController:bannerMRAIDContentController];
    }];
    
    [self.bnSpotIdToBnUnitController setObject:bannerUnitController
                                        forKey:spotID];
    
    IAAdSpot *bannerAdSpot = [IAAdSpot build:^(id<IAAdSpotBuilder> _Nonnull builder) {
        // set request
        builder.adRequest = request;
        
        // set mediation type
        builder.mediationType = [IAMediationIronSource new];
        
        // add supported unit controller
        [builder addSupportedUnitController:bannerUnitController];
    }];
    
    [self.bnSpotIdToBnAd setObject:bannerAdSpot
                            forKey:spotID];
}

- (IAAdRequest *)getRequestForSpotID:(NSString *)spotID {
    
    // The blocks runs on the same thread as invoked from, and is synchronous.
    IAAdRequest *request = [IAAdRequest build:^(id<IAAdRequestBuilder> _Nonnull builder) {
        builder.useSecureConnections = requestUsingSecureConnections;
        builder.spotID = spotID;
        builder.timeout = requestTimeOut;
    }];
    
    return request;
}

- (CGSize)getBannerSize:(ISBannerSize *)size {
    CGSize bannerSize = CGSizeZero;
    
    if ([size.sizeDescription isEqualToString:@"BANNER"]) {
        bannerSize = CGSizeMake(320, 50);
    } else if ([size.sizeDescription isEqualToString:@"RECTANGLE"]) {
        bannerSize = CGSizeMake(300, 250);
    } else if ([size.sizeDescription isEqualToString:@"SMART"]) {
        if (UI_USER_INTERFACE_IDIOM() == UIUserInterfaceIdiomPad) {
            bannerSize = CGSizeMake(728, 90);
        } else {
            bannerSize = CGSizeMake(320, 50);
        }
    }
    
    return bannerSize;
}

- (BOOL)isBannerSizeSupported:(ISBannerSize *)size {
    if ([size.sizeDescription isEqualToString:@"BANNER"]     ||
        [size.sizeDescription isEqualToString:@"RECTANGLE"]  ||
        [size.sizeDescription isEqualToString:@"SMART"]) {
        return YES;
    }
    
    return NO;
}

- (void)releaseMemoryWithAdapterConfig:(nonnull ISAdapterConfig *)adapterConfig {
    NSString *spotId = adapterConfig.settings[kSpotId];
    
    if ([self.rvSpotIdToRvAd objectForKey:spotId]) {
        [self.rvSpotIdToRvAd removeObjectForKey:spotId];
        [self.rvSpotIdToRvUnitController removeObjectForKey:spotId];
        [self.rvSpotIdToRvListener removeObjectForKey:spotId];
        [self.rvSpotIdSmashes removeObjectForKey:spotId];
        [self.rvAdsAvailability removeObjectForKey:spotId];
        [self.rvSpotIdToRvContentController removeObjectForKey:spotId];
        [self.rvSpotIdToRvMRaidContentController removeObjectForKey:spotId];
    } else if ([self.isSpotIdToIsAd objectForKey:spotId]) {
        [self.isSpotIdToIsAd removeObjectForKey:spotId];
        [self.isSpotIdToIsUnitController removeObjectForKey:spotId];
        [self.isSpotIdToIsListener removeObjectForKey:spotId];
        [self.isSpotIdSmashes removeObjectForKey:spotId];
        [self.isAdsAvailability removeObjectForKey:spotId];
        [self.isSpotIdToIsContentController removeObjectForKey:spotId];
        [self.isSpotIdToIsMRaidContentController removeObjectForKey:spotId];
    } else if ([self.bnSpotIdToBnAd objectForKey:spotId]) {
        [self.bnSpotIdToBnAd removeObjectForKey:spotId];
        [self.bnSpotIdToBnSize removeObjectForKey:spotId];
        [self.bnSpotIdToBnUnitController removeObjectForKey:spotId];
        [self.bnSpotIdSmashes removeObjectForKey:spotId];
        [self.bnSpotIdToBnListener removeObjectForKey:spotId];
        [self.bnSpotIdToBnContentController removeObjectForKey:spotId];
        [self.bnSpotIdToBnMRaidContentController removeObjectForKey:spotId];
    }
}


@end
