//
//  ISAdMobAdapter.m
//  ISAdMobAdapter
//
//  Created by Daniil Bystrov on 4/11/16.
//  Copyright © 2016 IronSource. All rights reserved.
//

#import "ISAdMobAdapter.h"
#import <GoogleMobileAds/GoogleMobileAds.h>
#import <ISAdMobIsFullScreenListener.h>
#import <ISAdMobRvFullScreenListener.h>


static NSString * const kAdapterName              = @"AdMob";
static NSString * const kAdapterVersion           = AdMobAdapterVersion;
static NSString * const kAdUnitId                 = @"adUnitId";
static NSString * const kCoppa                    = @"coppa";
static NSString * const kRequestAgent             = @"ironSource";

static NSString * const kNetworkOnlyInitFlag      = @"networkOnlyInit";
static NSString * const kInitResponseRequiredFlag = @"initResponseRequired";
static NSString * const kAdMobNetworkId           = @"GADMobileAds";

// Meta data keys
static NSString * const kAdMobTFCD                = @"admob_tfcd";
static NSString * const kAdMobTFUA                = @"admob_tfua";
static NSString * const kAdMobContentRating       = @"admob_maxcontentrating";

// Meta data content rate values
static NSString * const kAdMobMaxContentRatingG    = @"max_ad_content_rating_g";
static NSString * const kAdMobMaxContentRatingPG   = @"max_ad_content_rating_pg";
static NSString * const kAdMobMaxContentRatingT    = @"max_ad_content_rating_t";
static NSString * const kAdMobMaxContentRatingMA   = @"max_ad_content_rating_ma";

static NSInteger kRVNotReadyErrorCode             = 101;
static NSInteger kISFailedToShowErrorCode         = 102;
static NSInteger kBNFailedToReloadErrorCode       = 103;
static NSInteger kISNotReadyErrorCode             = 104;

static BOOL _didSetConsentCollectingUserData      = NO;
static BOOL _consentCollectingUserData            = NO;

typedef NS_ENUM(NSInteger, InitState) {
    INIT_STATE_NONE,
    INIT_STATE_IN_PROGRESS,
    INIT_STATE_FAILED,
    INIT_STATE_SUCCESS
};

static InitState _initState = INIT_STATE_NONE;

static ConcurrentMutableSet<ISNetworkInitCallbackProtocol> *initCallbackDelegates = nil;

@interface ISAdMobAdapter () <GADBannerViewDelegate,ISAdMobRvFullScreenDelegateWrapper, ISAdMobIsFullScreenDelegateWrapper, ISNetworkInitCallbackProtocol> {
    
}

// Rewarded video
@property (nonatomic, strong) ConcurrentMutableDictionary *rewardedVideoAds; // Holds placement and GADRewardedVideo
@property (nonatomic, strong) ConcurrentMutableDictionary *rewardedVideoPlacementToDelegate;
@property (nonatomic, strong) ConcurrentMutableDictionary *rewardedVideoAdsAvailability;
@property (nonatomic, strong) ConcurrentMutableDictionary *rvFullSCreenPlacementToListener;
@property (nonatomic, strong) NSMutableSet                *rewardedVideoPlacementsForInitCallbacks;

// Interstitial
@property (nonatomic, strong) ConcurrentMutableDictionary *interstitialAds; // Holds placement and GADInterstitial
@property (nonatomic, strong) ConcurrentMutableDictionary *interstitialPlacementToDelegate;
@property (nonatomic, strong) ConcurrentMutableDictionary *interstitialAdsAvailability;
@property (nonatomic, strong) ConcurrentMutableDictionary *isFullSCreenPlacementToListener;

// Banner
@property (nonatomic, strong) ConcurrentMutableDictionary *bannerAds; // Holds placement and GADBannerView
@property (nonatomic, strong) ConcurrentMutableDictionary *bannerPlacementToDelegate;


@end

@implementation ISAdMobAdapter

#pragma mark - Initializations Methods

- (instancetype)initAdapter:(NSString *)name
{
    self = [super initAdapter:name];
    
    if (self) {
        if (initCallbackDelegates == nil) {
            initCallbackDelegates =  [ConcurrentMutableSet<ISNetworkInitCallbackProtocol> set];
        }
        
        _rewardedVideoAds                           = [ConcurrentMutableDictionary dictionary];
        _rewardedVideoPlacementToDelegate           = [ConcurrentMutableDictionary dictionary];
        _rewardedVideoAdsAvailability               = [ConcurrentMutableDictionary dictionary];
        _rvFullSCreenPlacementToListener            = [ConcurrentMutableDictionary dictionary];
        _rewardedVideoPlacementsForInitCallbacks    = [[NSMutableSet alloc] init];
        
        _interstitialAds                            = [ConcurrentMutableDictionary dictionary];
        _interstitialPlacementToDelegate            = [ConcurrentMutableDictionary dictionary];
        _interstitialAdsAvailability                = [ConcurrentMutableDictionary dictionary];
        _isFullSCreenPlacementToListener            = [ConcurrentMutableDictionary dictionary];

        
        _bannerAds                                  = [ConcurrentMutableDictionary dictionary];
        _bannerPlacementToDelegate                  = [ConcurrentMutableDictionary dictionary];
        
        LWSState = LOAD_WHILE_SHOW_BY_INSTANCE;
    }
    
    return self;
}

#pragma mark - IronSource Protocol Methods

- (NSString *)version {
    return kAdapterVersion;
}

- (NSString *)sdkVersion {
    return GADMobileAds.sharedInstance.sdkVersion;
}

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

- (NSString *)sdkName {
    return @"GADMobileAds";
}

- (void)setConsent:(BOOL)consent {
    LogAdapterApi_Internal(@"value = %@", consent? @"YES" : @"NO");

    _consentCollectingUserData = consent;
    _didSetConsentCollectingUserData = YES;
}

- (void) setCCPAValue:(BOOL)value {
    LogAdapterApi_Internal(@"value = %@", value? @"YES" : @"NO");
    
    [NSUserDefaults.standardUserDefaults setBool:value forKey:@"gad_rdp"];
}

- (void)setMetaDataWithKey:(NSString *)key andValues:(NSMutableArray *) values {
    if(values.count == 0) return;
    NSString *value = values[0];
    LogAdapterApi_Internal(@"key = %@, value = %@", key, value);
    
    if ([ISMetaDataUtils isValidCCPAMetaDataWithKey:key andValue:value]) {
        [self setCCPAValue:[ISMetaDataUtils getCCPABooleanValue:value]];
    } else {
        [self setAdMobMetaDataWithKey:[key lowercaseString] value:[value lowercaseString]];
    }
}

- (void) setAdMobMetaDataWithKey:(NSString *)key value:(NSString *)valueString {
    NSString *formattedValueString = valueString;
    
    if ([key isEqualToString:kAdMobTFCD] || [key isEqualToString:kAdMobTFUA]) {
        // Those of the AdMob MetaData keys accept only boolean values
        formattedValueString = [ISMetaDataUtils formatValue:valueString forType:(META_DATA_VALUE_BOOL)];
        
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

//check if the network supports adaptive banners
- (BOOL)getAdaptiveBannerSupport {
    return YES;
}


#pragma mark - Rewarded Video

- (void)initAndLoadRewardedVideoWithUserId:(NSString *)userId
                             adapterConfig:(ISAdapterConfig *)adapterConfig
                                  delegate:(id<ISRewardedVideoAdapterDelegate>)delegate {
    [self.dispatcher dispatchAsyncWithQueue:dispatch_get_main_queue() withBlock:^{
        NSString *adUnitId = adapterConfig.settings[kAdUnitId];
        
        LogAdapterApi_Internal(@"adUnitId = %@ - userId = %@", adUnitId, userId);
        
        /* Configuration Validation */
        if (![self isConfigValueValid:adUnitId]) {
            NSError *error = [self errorForMissingCredentialFieldWithName:kAdUnitId];
            LogAdapterApi_Internal(@"error.description = %@", error.description);
            [delegate adapterRewardedVideoHasChangedAvailability:NO];
            return;
        }
        
        ISAdMobRvFullScreenListener *listener = [[ISAdMobRvFullScreenListener alloc] initWithPlacementId:adUnitId andDelegate:self]; //using dedicated listener since the callbacks of RV and IS are the same
        [self.rvFullSCreenPlacementToListener setObject:listener forKey:adUnitId];
        [self.rewardedVideoPlacementToDelegate setObject:delegate forKey:adUnitId];
        
        switch (_initState) {
            case INIT_STATE_NONE:
                [self initAdMobSDK:adapterConfig];
                break;
            case INIT_STATE_FAILED:
                [delegate adapterRewardedVideoHasChangedAvailability:NO];
                break;
            case INIT_STATE_SUCCESS:
                [self loadRewardedVideoForAdMobWithPlacement:adUnitId];
                break;
            case INIT_STATE_IN_PROGRESS:
                [initCallbackDelegates addObject:self];
                break;
        }
    }];
}

- (void)initRewardedVideoForCallbacksWithUserId:(NSString *)userId
                                  adapterConfig:(ISAdapterConfig *)adapterConfig
                                       delegate:(id<ISRewardedVideoAdapterDelegate>)delegate {
    [self.dispatcher dispatchAsyncWithQueue:dispatch_get_main_queue() withBlock:^{
        NSString *adUnitId = adapterConfig.settings[kAdUnitId];
        
        LogAdapterApi_Internal(@"adUnitId = %@ - userId = %@", adUnitId, userId);
        
        /* Configuration Validation */
        if (![self isConfigValueValid:adUnitId]) {
            NSError *error = [self errorForMissingCredentialFieldWithName:kAdUnitId];
            LogAdapterApi_Internal(@"error.description = %@", error.description);
            [delegate adapterRewardedVideoInitFailed:error];
            return;
        }
        
        ISAdMobRvFullScreenListener *listener = [[ISAdMobRvFullScreenListener alloc] initWithPlacementId:adUnitId andDelegate:self]; //using dedicated listener since the callbacks of RV and IS are the same
        [self.rvFullSCreenPlacementToListener setObject:listener forKey:adUnitId];
        [self.rewardedVideoPlacementToDelegate setObject:delegate forKey:adUnitId];
        [self.rewardedVideoPlacementsForInitCallbacks addObject:adUnitId];
        
        switch (_initState) {
            case INIT_STATE_NONE:
                [self initAdMobSDK:adapterConfig];
                break;
            case INIT_STATE_FAILED:
                [delegate adapterRewardedVideoInitFailed:[ISError createError:ERROR_CODE_INIT_FAILED withMessage:@"AdMob SDK init failed"]];
                break;
            case INIT_STATE_SUCCESS:
                [delegate adapterRewardedVideoInitSuccess];
                break;
            case INIT_STATE_IN_PROGRESS:
                [initCallbackDelegates addObject:self];
                break;
        }
    }];
}

- (void)showRewardedVideoWithViewController:(UIViewController *)viewController
                              adapterConfig:(ISAdapterConfig *)adapterConfig
                             delegate:(id<ISRewardedVideoAdapterDelegate>)delegate {
    [self.dispatcher dispatchAsyncWithQueue:dispatch_get_main_queue() withBlock:^{
        NSString *adUnitId = adapterConfig.settings[kAdUnitId];

        LogAdapterApi_Internal(@"adUnitId = %@", adUnitId);
        
        GADRewardedAd *rvAd = [self.rewardedVideoAds objectForKey:adUnitId];
        if (rvAd && [self.rewardedVideoAdsAvailability objectForKey:adUnitId]) {
            ISAdMobRvFullScreenListener* listener = [_rvFullSCreenPlacementToListener objectForKey:rvAd.adUnitID];
            rvAd.fullScreenContentDelegate = listener;
            [rvAd presentFromRootViewController:viewController
                                          userDidEarnRewardHandler:^{
                id<ISRewardedVideoAdapterDelegate> delegate = [_rewardedVideoPlacementToDelegate objectForKey:rvAd.adUnitID];
                [delegate adapterRewardedVideoDidReceiveReward];
            }];
        }
        else {
            NSError *error = [NSError errorWithDomain:@"ISAdMobAdapter" code:kRVNotReadyErrorCode userInfo:nil];
            [delegate adapterRewardedVideoDidFailToShowWithError:error];
        }
        // once reward video is displayed or if it's not ready, it's no longer available
        [self.rewardedVideoAdsAvailability setObject:@NO forKey:adUnitId];
        [delegate adapterRewardedVideoHasChangedAvailability:NO];
    }];
}

- (void)loadRewardedVideoForAdMobWithPlacement:(NSString *)placementID {
    [self.rewardedVideoAdsAvailability setObject:@NO forKey:placementID];
    if ([self.rewardedVideoPlacementToDelegate objectForKey:placementID]) {
        id<ISRewardedVideoAdapterDelegate> delegate = [self.rewardedVideoPlacementToDelegate objectForKey:placementID];
        LogAdapterApi_Internal(@"placementID = %@", placementID);
        GADRequest *request = [self createGADRequest];
        [GADRewardedAd
               loadWithAdUnitID:placementID
                        request:request
              completionHandler:^(GADRewardedAd *ad, NSError *error) {
            
            [self.rewardedVideoAds setObject:ad forKey:placementID];
            if (error) {
                LogAdapterApi_Internal(@"failed for placementID = %@", placementID);
                [self.rewardedVideoAdsAvailability setObject:@NO forKey:placementID];
                [delegate adapterRewardedVideoHasChangedAvailability:NO];
                NSError *smashError = (error.code == GADErrorNoFill || error.code == GADErrorMediationNoFill) ? [ISError createError:ERROR_RV_LOAD_NO_FILL withMessage:@"AdMob no fill"] : error;
                [delegate adapterRewardedVideoDidFailToLoadWithError:smashError];
            } else {
                LogAdapterApi_Internal(@"success for placementID = %@", placementID);
                [self.rewardedVideoAdsAvailability setObject:@YES forKey:placementID];
                [delegate adapterRewardedVideoHasChangedAvailability:YES];

            }
            
        }];
    }
    else {
        LogAdapterApi_Internal(@"cannot find placementID = %@", placementID);
    }
}


- (void)fetchRewardedVideoForAutomaticLoadWithAdapterConfig:(ISAdapterConfig *)adapterConfig delegate:(id<ISRewardedVideoAdapterDelegate>)delegate {
    [self.dispatcher dispatchAsyncWithQueue:dispatch_get_main_queue() withBlock:^{
        NSString *adUnitId = adapterConfig.settings[kAdUnitId];
        LogAdapterApi_Internal(@"adUnitId = %@", adUnitId);
        [self loadRewardedVideoForAdMobWithPlacement:adUnitId];
    }];
}

- (BOOL)hasRewardedVideoWithAdapterConfig:(ISAdapterConfig *)adapterConfig {
    NSString *adUnitId = adapterConfig.settings[kAdUnitId];
    NSNumber *available = [self.rewardedVideoAdsAvailability objectForKey:adUnitId];
    return (available != nil) && [available boolValue];
}

#pragma mark - Interstitial

- (void)initInterstitialWithUserId:(NSString *)userId adapterConfig:(ISAdapterConfig *)adapterConfig delegate:(id<ISInterstitialAdapterDelegate>)delegate {
    [self.dispatcher dispatchAsyncWithQueue:dispatch_get_main_queue() withBlock:^{
        NSString *adUnitId = adapterConfig.settings[kAdUnitId];
        
        LogAdapterApi_Internal(@"adUnitId = %@ - userId = %@", adUnitId, userId);
        
        /* Configuration Validation */
        if (![self isConfigValueValid:adUnitId]) {
            NSError *error = [self errorForMissingCredentialFieldWithName:kAdUnitId];
            LogAdapterApi_Internal(@"error = %@", error);
            [delegate adapterInterstitialInitFailedWithError:error];
            return;
        }
        
        ISAdMobIsFullScreenListener *listener = [[ISAdMobIsFullScreenListener alloc] initWithPlacementId:adUnitId andDelegate:self]; //using dedicated listener since the callbacks of RV and IS are the same
        [self.isFullSCreenPlacementToListener setObject:listener forKey:adUnitId];
        [self.interstitialPlacementToDelegate setObject:delegate forKey:adUnitId];
        switch (_initState) {
            case INIT_STATE_NONE:
                [self initAdMobSDK:adapterConfig];
                break;
            case INIT_STATE_FAILED:
                [delegate adapterInterstitialInitFailedWithError:[ISError createError:ERROR_CODE_INIT_FAILED withMessage:@"AdMob SDK init failed"]];
                break;
            case INIT_STATE_SUCCESS:
                [delegate adapterInterstitialInitSuccess];
                break;
            case INIT_STATE_IN_PROGRESS:
                [initCallbackDelegates addObject:self];
                break;
        }
    }];
}

- (void)loadInterstitialWithAdapterConfig:(ISAdapterConfig *)adapterConfig delegate:(id<ISInterstitialAdapterDelegate>)delegate {
    [self.dispatcher dispatchAsyncWithQueue:dispatch_get_main_queue() withBlock:^{
        NSString *adUnitId = adapterConfig.settings[kAdUnitId];
        [self.interstitialAdsAvailability setObject:@NO forKey:adUnitId];
        LogAdapterApi_Internal(@"adUnitId = %@", adUnitId);
        GADRequest *request = [self createGADRequest];
        /* Create new GADInterstitial */
        [GADInterstitialAd loadWithAdUnitID:adUnitId
                                        request:request
                              completionHandler:^(GADInterstitialAd *ad, NSError *error) {

    
            [self.interstitialAds setObject:ad forKey:adUnitId];
            id<ISInterstitialAdapterDelegate> delegate = [_interstitialPlacementToDelegate objectForKey:adUnitId];
            if (error) {
              [self.interstitialAdsAvailability setObject:@NO forKey:adUnitId];
                NSError *smashError = (error.code == GADErrorNoFill || error.code == GADErrorMediationNoFill) ? [ISError createError:ERROR_IS_LOAD_NO_FILL withMessage:@"AdMob no fill"] : error;

              [delegate adapterInterstitialDidFailToLoadWithError:smashError];
          } else {
              [self.interstitialAdsAvailability setObject:@YES forKey:adUnitId];
              [delegate adapterInterstitialDidLoad];

          }

        }];


        
    }];
}

- (void)showInterstitialWithViewController:(UIViewController *)viewController
                             adapterConfig:(ISAdapterConfig *)adapterConfig
                            delegate:(id<ISInterstitialAdapterDelegate>)delegate {
    [self.dispatcher dispatchAsyncWithQueue:dispatch_get_main_queue() withBlock:^{
        NSString *adUnitId = adapterConfig.settings[kAdUnitId];
        LogAdapterApi_Internal(@"adUnitId = %@", adUnitId);
        GADInterstitialAd *interstitialAd = [self.interstitialAds objectForKey:adUnitId];
        ISAdMobIsFullScreenListener* listener = [_isFullSCreenPlacementToListener objectForKey:adUnitId];
        interstitialAd.fullScreenContentDelegate = listener;
        if (interstitialAd != nil && [self.interstitialAdsAvailability objectForKey:adUnitId]) {
            [interstitialAd presentFromRootViewController:viewController];
        }
        else {
            NSError *error = [NSError errorWithDomain:@"ISAdMobAdapter" code:kISNotReadyErrorCode userInfo:nil];
            LogAdapterApi_Internal(@"error = %@", error);
            [delegate adapterInterstitialDidFailToShowWithError:error];
            
        }
        [self.interstitialAdsAvailability setObject:@NO forKey:adUnitId];
    }];
}

- (BOOL)hasInterstitialWithAdapterConfig:(ISAdapterConfig *)adapterConfig {
    NSString *adUnitId = adapterConfig.settings[kAdUnitId];
    NSNumber *available = [self.interstitialAdsAvailability objectForKey:adUnitId];
    return (available != nil) && [available boolValue];
}

#pragma mark - Banner

- (void)initBannerWithUserId:(nonnull NSString *)userId
           adapterConfig:(nonnull ISAdapterConfig *)adapterConfig
                delegate:(nonnull id<ISBannerAdapterDelegate>)delegate {
    
    [self.dispatcher dispatchAsyncWithQueue:dispatch_get_main_queue() withBlock:^{
        NSString *adUnitId = adapterConfig.settings[kAdUnitId];
    
        
        /* Configuration Validation */
        if (![self isConfigValueValid:adUnitId]) {
            NSError *error = [self errorForMissingCredentialFieldWithName:kAdUnitId];
            LogAdapterApi_Internal(@"error = %@", error);
            [delegate adapterBannerInitFailedWithError:error];
            return;
        }
        
        LogAdapterApi_Internal(@"adUnitId = %@ - userId = %@", adUnitId, userId);
        
        [_bannerPlacementToDelegate setObject:delegate forKey:adUnitId];
        
        switch (_initState) {
            case INIT_STATE_NONE:
                [self initAdMobSDK:adapterConfig];
                break;
            case INIT_STATE_FAILED:
                [delegate adapterBannerInitFailedWithError:[ISError createError:ERROR_CODE_INIT_FAILED withMessage:@"AdMob SDK init failed"]];
                break;
            case INIT_STATE_SUCCESS:
                [delegate adapterBannerInitSuccess];
                break;
            case INIT_STATE_IN_PROGRESS:
                [initCallbackDelegates addObject:self];
                break;
        }
    }];
}

- (void)loadBannerWithViewController:(nonnull UIViewController *)viewController
                                size:(ISBannerSize *)size
                       adapterConfig:(nonnull ISAdapterConfig *)adapterConfig
                      delegate:(nonnull id <ISBannerAdapterDelegate>)delegate {
    [self.dispatcher dispatchAsyncWithQueue:dispatch_get_main_queue() withBlock:^{
        
        NSString *adUnitId = adapterConfig.settings[kAdUnitId];
        LogAdapterApi_Internal(@"adUnitId = %@", adUnitId);
        
        if([self isBannerSizeSupported:size]){ // load banner
            
            // get size
            GADAdSize adMobSize = [self getBannerSize:size];
            
            // create banner
            GADBannerView *banner = [[GADBannerView alloc] initWithAdSize:adMobSize];
            banner.delegate = self;
            banner.adUnitID = adUnitId;
            banner.rootViewController = viewController;
            
            // add to dictionary
            [_bannerAds setObject:banner forKey:adUnitId];
            
            // load request
            [banner loadRequest:[self createGADRequest]];
            
        }else{
             // size not supported
             
             NSError *error = [ISError createError:ERROR_BN_UNSUPPORTED_SIZE withMessage:@"AdMob unsupported banner size"];
             LogAdapterApi_Internal(@"error = %@", error);
             [delegate adapterBannerDidFailToLoadWithError:error];
        }
        
    }];
}

/// This method will not be called from version 6.14.0 - we leave it here for backwords compatibility
- (void)reloadBannerWithAdapterConfig:(nonnull ISAdapterConfig *)adapterConfig
            delegate:(nonnull id <ISBannerAdapterDelegate>)delegate {
    [self.dispatcher dispatchAsyncWithQueue:dispatch_get_main_queue() withBlock:^{
        NSString *adUnitId = adapterConfig.settings[kAdUnitId];
        LogAdapterApi_Internal(@"adUnitId = %@", adUnitId);
        
        GADBannerView *banner = [_bannerAds objectForKey:adUnitId];
        if(banner) {
            [banner loadRequest:[self createGADRequest]];
        }
        else {
            id<ISBannerAdapterDelegate> delegate = [_bannerPlacementToDelegate objectForKey:adUnitId];
            NSError *error = [NSError errorWithDomain:@"ISAdMobAdapter" code:kBNFailedToReloadErrorCode userInfo:@{NSLocalizedDescriptionKey : @"reloadBanner Failed"}];
            LogAdapterApi_Internal(@"error = %@", error);
            [delegate adapterBannerDidFailToLoadWithError:error];
        }
    }];
}

- (void)destroyBannerWithAdapterConfig:(nonnull ISAdapterConfig *)adapterConfig {
    
}

#pragma mark - Interstitial full screen Delegate

- (void)isAdDidRecordImpressionForPlacementId:(NSString *)placementId{
    LogAdapterDelegate_Internal(@"placementId = %@", placementId);
}

- (void)isAdDidFailToPresentFullScreenContentWithError:(NSError *)error ForPlacementId:(NSString *)placementId {
    LogAdapterDelegate_Internal(@"placementId = %@ , error = %@", placementId, error);
    id<ISInterstitialAdapterDelegate> delegate = [_interstitialPlacementToDelegate objectForKey:placementId];
    [delegate adapterInterstitialDidFailToShowWithError:error];
}

- (void)isAdWillPresentFullScreenContentForPlacementId:(NSString *)placementId {
    LogAdapterDelegate_Internal(@"placementId = %@", placementId);
    id<ISInterstitialAdapterDelegate> delegate = [_interstitialPlacementToDelegate objectForKey:placementId];
    [delegate adapterInterstitialDidOpen];
    [delegate adapterInterstitialDidShow];
}

- (void)isAdWillDismissFullScreenContentForPlacementId:(NSString *)placementId {
    LogAdapterDelegate_Internal(@"placementId = %@", placementId);
}

- (void)isAdDidDismissFullScreenContentForPlacementId:(NSString *)placementId {
    LogAdapterDelegate_Internal(@"placementId = %@", placementId);
    id<ISInterstitialAdapterDelegate> delegate = [_interstitialPlacementToDelegate objectForKey:placementId];
    [delegate adapterInterstitialDidClose];
}

- (void)isAdDidRecordClickForPlacementId:(NSString *)placementId {
    LogAdapterDelegate_Internal(@"placementId = %@", placementId);
    id<ISInterstitialAdapterDelegate> delegate = [_interstitialPlacementToDelegate objectForKey:placementId];
    [delegate adapterInterstitialDidClick];
}



#pragma mark - Rewarded Video full screen Delegate

- (void)rvAdDidRecordImpressionForPlacementId:(NSString *)placementId{
    LogAdapterDelegate_Internal(@"placementId = %@", placementId);
}

- (void)rvAdDidFailToPresentFullScreenContentWithError:(NSError *)error ForPlacementId:(NSString *)placementId{
    LogAdapterDelegate_Internal(@"placementId = %@", placementId);
    id<ISRewardedVideoAdapterDelegate> delegate = [_rewardedVideoPlacementToDelegate objectForKey:placementId];
    [delegate adapterRewardedVideoHasChangedAvailability:NO];
    [delegate adapterRewardedVideoDidFailToShowWithError:error];
}

- (void)rvAdWillPresentFullScreenContentForPlacementId:(NSString *)placementId {
    LogAdapterDelegate_Internal(@"placementId = %@", placementId);
    id<ISRewardedVideoAdapterDelegate> delegate = [_rewardedVideoPlacementToDelegate objectForKey:placementId];
    [delegate adapterRewardedVideoDidOpen];
}

- (void)rvAdWillDismissFullScreenContentForPlacementId:(NSString *)placementId {
    LogAdapterDelegate_Internal(@"placementId = %@", placementId);
}

- (void)rvAdDidDismissFullScreenContentForPlacementId:(NSString *)placementId {
    LogAdapterDelegate_Internal(@"placementId = %@", placementId);
    id<ISRewardedVideoAdapterDelegate> delegate = [_rewardedVideoPlacementToDelegate objectForKey:placementId];
    [delegate adapterRewardedVideoDidClose];
}

- (void)rvAdDidRecordClickForPlacementId:(NSString *)placementId {
    LogAdapterDelegate_Internal(@"placementId = %@", placementId);
    id<ISRewardedVideoAdapterDelegate> delegate = [_rewardedVideoPlacementToDelegate objectForKey:placementId];
    [delegate adapterRewardedVideoDidClick];
}



#pragma mark - Banner Delegate

/// Tells the delegate that an ad request successfully received an ad. The delegate may want to add
/// the banner view to the view hierarchy if it hasn't been added yet.
- (void)bannerViewDidReceiveAd:(GADBannerView *)bannerView {
    LogAdapterDelegate_Internal(@"bannerView.adUnitID = %@", bannerView.adUnitID);
    id<ISBannerAdapterDelegate> delegate = [_bannerPlacementToDelegate objectForKey:bannerView.adUnitID];
    [delegate adapterBannerDidLoad:bannerView];
}



/// Tells the delegate that a click has been recorded for the ad.
- (void)bannerViewDidRecordClick:(nonnull GADBannerView *)bannerView; {
    LogAdapterDelegate_Internal(@"bannerView.adUnitID = %@", bannerView.adUnitID);
    id<ISBannerAdapterDelegate> delegate = [_bannerPlacementToDelegate objectForKey:bannerView.adUnitID];
    [delegate adapterBannerDidClick];
}

/// Tells the delegate that an ad request failed. The failure is normally due to network
/// connectivity or ad availablility (i.e., no fill).
- (void)bannerView:(GADBannerView *)bannerView didFailToReceiveAdWithError:(nonnull NSError *)error {
    LogAdapterDelegate_Internal(@"bannerView.adUnitID = %@", bannerView.adUnitID);
    id<ISBannerAdapterDelegate> delegate = [_bannerPlacementToDelegate objectForKey:bannerView.adUnitID];
    NSError *smashError = (error.code == GADErrorNoFill || error.code == GADErrorMediationNoFill)?
    [ISError createError:ERROR_BN_LOAD_NO_FILL withMessage:@"AdMob no fill"] :
    error;
    [delegate adapterBannerDidFailToLoadWithError:smashError];
}

/// Tells the delegate that an impression has been recorded for an ad.
- (void)bannerViewDidRecordImpression:(nonnull GADBannerView *)bannerView {
    LogAdapterDelegate_Internal(@"bannerView.adUnitID = %@", bannerView.adUnitID);
    id<ISBannerAdapterDelegate> delegate = [_bannerPlacementToDelegate objectForKey:bannerView.adUnitID];
    [delegate adapterBannerDidShow];
}
#pragma mark  Click-Time Lifecycle Notifications

/// Tells the delegate that a full screen view will be presented in response to the user clicking on
/// an ad. The delegate may want to pause animations and time sensitive interactions.
- (void)bannerViewWillPresentScreen:(GADBannerView *)bannerView {
    LogAdapterDelegate_Internal(@"bannerView.adUnitID = %@", bannerView.adUnitID);
    id<ISBannerAdapterDelegate> delegate = [_bannerPlacementToDelegate objectForKey:bannerView.adUnitID];
    [delegate adapterBannerWillPresentScreen];

}

/// Tells the delegate that the full screen view has been dismissed. The delegate should restart
/// anything paused while handling adViewWillPresentScreen:.
- (void)bannerViewDidDismissScreen:(GADBannerView *)bannerView {
    LogAdapterDelegate_Internal(@"bannerView.adUnitID = %@", bannerView.adUnitID);
    id<ISBannerAdapterDelegate> delegate = [_bannerPlacementToDelegate objectForKey:bannerView.adUnitID];
    [delegate adapterBannerDidDismissScreen];
}

/// Tells the delegate that the full screen view will be dismissed.
- (void)bannerViewWillDismissScreen:(GADBannerView *)bannerView {
    LogAdapterDelegate_Internal(@"bannerView.adUnitID = %@", bannerView.adUnitID);
}



#pragma mark - Private Methods

- (void)initAdMobSDK:(ISAdapterConfig *)adapterConfig {
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

- (GADRequest *)createGADRequest{
    GADRequest *request = [GADRequest request];
    request.requestAgent = kRequestAgent;
    if ([ISConfigurations getConfigurations].userAge  > -1) {
        LogAdapterApi_Internal(@"creating request with age=%ld tagForChildDirectedTreatment=%d", (long)[ISConfigurations getConfigurations].userAge, [ISConfigurations getConfigurations].userAge < 13);
        [GADMobileAds.sharedInstance.requestConfiguration tagForChildDirectedTreatment:([ISConfigurations getConfigurations].userAge < 13)];
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

#pragma mark - ISNetworkInitCallbackProtocol

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
        [initDelegate onNetworkInitCallbackFailed:@""];
    }
    
    [initCallbackDelegates removeAllObjects];
}

- (void)onNetworkInitCallbackFailed:(nonnull NSString *)errorMessage {
    LogAdapterDelegate_Internal(@"");
    NSArray *rewardedVideoPlacementIDs = _rewardedVideoPlacementToDelegate.allKeys;
    NSError *error = [ISError createError:ERROR_CODE_INIT_FAILED withMessage:errorMessage];

    // rewarded video
    for (NSString *placementId in rewardedVideoPlacementIDs) {
        id<ISRewardedVideoAdapterDelegate> delegate = [_rewardedVideoPlacementToDelegate objectForKey:placementId];
        if ([_rewardedVideoPlacementsForInitCallbacks containsObject:placementId]) {
            [delegate adapterRewardedVideoInitFailed:[ISError createError:ERROR_CODE_INIT_FAILED withMessage:@"AdMob SDK init failed"]];
        } else {
            [delegate adapterRewardedVideoHasChangedAvailability:NO];
        }
    }
    
    // interstitial
    NSArray *interstitialPlacementIDs = _interstitialPlacementToDelegate.allKeys;
    
    for (NSString *placementId in interstitialPlacementIDs) {
        id<ISInterstitialAdapterDelegate> delegate = [_interstitialPlacementToDelegate objectForKey:placementId];
        [delegate adapterInterstitialInitFailedWithError:error];
    }
    
    // banner
    NSArray *bannerPlacementIDs = _bannerPlacementToDelegate.allKeys;
    
    for (NSString *placementId in bannerPlacementIDs) {
        id<ISBannerAdapterDelegate> delegate = [_bannerPlacementToDelegate objectForKey:placementId];
        [delegate adapterBannerInitFailedWithError:error];
    }
}

- (void)onNetworkInitCallbackSuccess {
    LogAdapterDelegate_Internal(@"");

    NSArray *rewardedVideoPlacementIDs = _rewardedVideoPlacementToDelegate.allKeys;
    
    for (NSString *placementId in rewardedVideoPlacementIDs) {
        if ([_rewardedVideoPlacementsForInitCallbacks containsObject:placementId]) {
            id<ISRewardedVideoAdapterDelegate> delegate = [_rewardedVideoPlacementToDelegate objectForKey:placementId];
            [delegate adapterRewardedVideoInitSuccess];
        } else {
            [self loadRewardedVideoForAdMobWithPlacement:placementId];
        }
    }
    
    // interstitial
    NSArray *interstitialPlacementIDs = _interstitialPlacementToDelegate.allKeys;
    
    for (NSString *placementId in interstitialPlacementIDs) {
        id<ISInterstitialAdapterDelegate> delegate = [_interstitialPlacementToDelegate objectForKey:placementId];
        [delegate adapterInterstitialInitSuccess];
    }
    
    // banner
    NSArray *bannerPlacementIDs = _bannerPlacementToDelegate.allKeys;
    
    for (NSString *placementId in bannerPlacementIDs) {
        id<ISBannerAdapterDelegate> delegate = [_bannerPlacementToDelegate objectForKey:placementId];
        [delegate adapterBannerInitSuccess];
    }
}

@end
