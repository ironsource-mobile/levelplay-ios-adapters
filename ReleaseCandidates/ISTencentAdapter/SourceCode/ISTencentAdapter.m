//
//  ISTencentAdapter.m
//  ISTencentAdapter
//
//  Created by maoz.elbaz on 10/05/2021.
//

#import "ISTencentAdapter.h"
#import "GDTSDKConfig.h"
#import "GDTRewardVideoAd.h"
#import "GDTUnifiedInterstitialAd.h"
#import "GDTUnifiedBannerView.h"


static NSString * const kAdapterVersion           = TencentAdapterVersion;
static NSString * const kAdapterName              = @"Tencent";
static NSString * const kPlacementID              = @"placementId";
static NSString * const kAppId                    = @"appId";

static NSInteger kRVNotReadyErrorCode             = 101;
static NSInteger kBNFailedToReloadErrorCode       = 103;
static NSInteger kISNotReadyErrorCode             = 104;

static NSInteger kTencentLoadFailedErrorCode      = 5002;
static NSInteger kTencentShowFailedErrorCode      = 5003;
static NSInteger kTencentNoFillErrorCode          = 5004;


typedef NS_ENUM(NSInteger, InitState) {
    INIT_STATE_NONE,
    INIT_STATE_SUCCESS,
    INIT_STATE_FAILED
};

// init state is declared static because the network
// state should be the same for all class instances
static InitState initState = INIT_STATE_NONE;

@interface ISTencentAdapter () <GDTRewardedVideoAdDelegate, GDTUnifiedInterstitialAdDelegate, GDTUnifiedBannerViewDelegate> {
    
}


// Rewarded video
@property (nonatomic, strong) ConcurrentMutableDictionary *rewardedVideoAds;
@property (nonatomic, strong) ConcurrentMutableDictionary *rewardedVideoPlacementToDelegate;


// Interstitial
@property (nonatomic, strong) ConcurrentMutableDictionary *interstitialAds;
@property (nonatomic, strong) ConcurrentMutableDictionary *interstitialPlacementToDelegate;


// Banner
@property (nonatomic, strong) ConcurrentMutableDictionary *bannerAds;
@property (nonatomic, strong) ConcurrentMutableDictionary *bannerPlacementToDelegate;
@property (nonatomic, strong) NSMapTable *bannerAdToPlacementId;


@end


@implementation ISTencentAdapter

#pragma mark - Initializations Methods

- (instancetype)initAdapter:(NSString *)name
{
    self = [super initAdapter:name];
    
    if (self) {

        _rewardedVideoAds                 = [ConcurrentMutableDictionary dictionary];
        _rewardedVideoPlacementToDelegate = [ConcurrentMutableDictionary dictionary];
        
        _interstitialAds                  = [ConcurrentMutableDictionary dictionary];
        _interstitialPlacementToDelegate  = [ConcurrentMutableDictionary dictionary];
        
        _bannerAds                        = [ConcurrentMutableDictionary dictionary];
        _bannerPlacementToDelegate        = [ConcurrentMutableDictionary dictionary];
        _bannerAdToPlacementId            = [NSMapTable mapTableWithKeyOptions:NSMapTableStrongMemory valueOptions:NSMapTableWeakMemory];
        
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
    return [GDTSDKConfig sdkVersion];
}

- (NSArray *)systemFrameworks {
    return @[
        @"AdSupport",
        @"AVFoundation",
        @"CoreLocation",
        @"CoreTelephony",
        @"Foundation",
        @"libxml2",
        @"QuartzCore",
        @"Security",
        @"StoreKit",
        @"SystemConfiguration",
        @"WebKit"
    ];
}

- (NSString *)sdkName {
    return @"Tencent";
}


#pragma mark - Rewarded Video

- (void)initAndLoadRewardedVideoWithUserId:(NSString *)userId
                             adapterConfig:(ISAdapterConfig *)adapterConfig
                                  delegate:(id<ISRewardedVideoAdapterDelegate>)delegate {
    
    if (delegate == nil) {
        LogAdapterApi_Error(@"delegate == nil");
        return;
    }
    
    NSString *placementId = adapterConfig.settings[kPlacementID];
    
    if (![self isConfigValueValid:placementId]) {
        NSError *error = [self errorForMissingCredentialFieldWithName:placementId];
        LogAdapterApi_Error(@"error = %@", error);
        [delegate adapterRewardedVideoHasChangedAvailability:NO];
        return;
    }
    
    LogAdapterApi_Internal(@"placementId = %@ - userId = %@", placementId, userId);
    
    [self.rewardedVideoPlacementToDelegate setObject:delegate forKey:placementId];
    
    [self initSDK:adapterConfig];

    if (initState == INIT_STATE_SUCCESS) {
        LogAdapterApi_Internal(@"rewarded init success - placementId = %@", placementId);
        [self loadRewardedVideoInternalWithAdPlacementId:placementId];
    } else {
        [delegate adapterRewardedVideoHasChangedAvailability:NO];
    }
}

- (void)initRewardedVideoForCallbacksWithUserId:(NSString *)userId
                                  adapterConfig:(ISAdapterConfig *)adapterConfig
                                       delegate:(id<ISRewardedVideoAdapterDelegate>)delegate {
    
    if (delegate == nil) {
        LogAdapterApi_Error(@"delegate == nil");
        return;
    }
    
    NSString *placementId = adapterConfig.settings[kPlacementID];
    
    if (![self isConfigValueValid:placementId]) {
        NSError *error = [self errorForMissingCredentialFieldWithName:placementId];
        LogAdapterApi_Error(@"error = %@", error);
        [delegate adapterRewardedVideoInitFailed:error];
        return;
    }
    
    LogAdapterApi_Internal(@"placementId = %@ - userId = %@", placementId, userId);
    
    [self.rewardedVideoPlacementToDelegate setObject:delegate forKey:placementId];
    
    [self initSDK:adapterConfig];

    if(initState == INIT_STATE_SUCCESS) {
        LogAdapterApi_Internal(@"rewarded init success - placementId = %@", placementId);
        [delegate adapterRewardedVideoInitSuccess];
    } else {
        NSError *error = [ISError createError:ERROR_CODE_INIT_FAILED withMessage:@"Tencent SDK init failed"];
        [delegate adapterRewardedVideoInitFailed:error];
    }
}

- (void)showRewardedVideoWithViewController:(UIViewController *)viewController
                              adapterConfig:(ISAdapterConfig *)adapterConfig
                                   delegate:(id<ISRewardedVideoAdapterDelegate>)delegate {
    dispatch_async(dispatch_get_main_queue(), ^{
        NSString *placementId = adapterConfig.settings[kPlacementID];
        
        LogAdapterApi_Internal(@"placementId = %@", placementId);
        
        [delegate adapterRewardedVideoHasChangedAvailability:NO];

        if ([self hasRewardedVideoWithAdapterConfig:adapterConfig]) {
            GDTRewardVideoAd *rvAd = [self.rewardedVideoAds objectForKey:placementId];
            [rvAd showAdFromRootViewController:viewController];
        } else {
            NSError *error = [NSError errorWithDomain:@"ISTencentAdapter" code:kRVNotReadyErrorCode userInfo:nil];
            [delegate adapterRewardedVideoDidFailToShowWithError:error];
        }
        
    });
}

- (void)fetchRewardedVideoForAutomaticLoadWithAdapterConfig:(ISAdapterConfig *)adapterConfig delegate:(id<ISRewardedVideoAdapterDelegate>)delegate {
    NSString *placementId = adapterConfig.settings[kPlacementID];
    LogAdapterApi_Internal(@"placementId = %@", placementId);
    [self loadRewardedVideoInternalWithAdPlacementId:placementId];
}

- (BOOL)hasRewardedVideoWithAdapterConfig:(ISAdapterConfig *)adapterConfig {
    NSString *placementId = adapterConfig.settings[kPlacementID];
    GDTRewardVideoAd *rvAd = [self.rewardedVideoAds objectForKey:placementId];
    
    if (rvAd != nil) {
        return [rvAd isAdValid];
    }
    
    return NO;
}

- (void)loadRewardedVideoInternalWithAdPlacementId:(NSString *)placementId {
    dispatch_async(dispatch_get_main_queue(), ^{
        if ([self.rewardedVideoPlacementToDelegate objectForKey:placementId]) {
            LogAdapterApi_Internal(@"placementId = %@", placementId);
            GDTRewardVideoAd *rewardVideoAd = [[GDTRewardVideoAd alloc] initWithPlacementId:placementId];
            rewardVideoAd.delegate = self;
            [self.rewardedVideoAds setObject:rewardVideoAd forKey:placementId];
            [rewardVideoAd loadAd];
        }
    });
}


#pragma mark - Rewarded video delegate

/**
 Tell the delegate that a  rewarded video ad is successfully called back
 @param rewardedVideoAd GDTRewardVideoAd
 */
- (void)gdt_rewardVideoAdDidLoad:(GDTRewardVideoAd *)rewardedVideoAd{
    LogAdapterDelegate_Internal(@"placementId = %@", rewardedVideoAd.placementId);
}

/**
 Tell the delegate that  video data for the ad has been downloaded, and the downloaded videos will be  directly called back
 @param rewardedVideoAd GDTRewardVideoAd
 */
- (void)gdt_rewardVideoAdVideoDidLoad:(GDTRewardVideoAd *)rewardedVideoAd{
    LogAdapterDelegate_Internal(@"placementId = %@", rewardedVideoAd.placementId);
    id<ISRewardedVideoAdapterDelegate> delegate = [self.rewardedVideoPlacementToDelegate objectForKey:rewardedVideoAd.placementId];
    [delegate adapterRewardedVideoHasChangedAvailability:YES];
}

/**
 Tell the delegate that  the reward video ad play page will display the callback
 @param rewardedVideoAd GDTRewardVideoAd
 */
- (void)gdt_rewardVideoAdWillVisible:(GDTRewardVideoAd *)rewardedVideoAd{
    LogAdapterDelegate_Internal(@"placementId = %@", rewardedVideoAd.placementId);
}

/**
 Tell the delegate that  the rewarded video ad exposes the callback
 @param rewardedVideoAd GDTRewardVideoAd
 */
- (void)gdt_rewardVideoAdDidExposed:(GDTRewardVideoAd *)rewardedVideoAd{
    LogAdapterDelegate_Internal(@"placementId = %@", rewardedVideoAd.placementId);
    id<ISRewardedVideoAdapterDelegate> delegate = [self.rewardedVideoPlacementToDelegate objectForKey:rewardedVideoAd.placementId];
    
    [delegate adapterRewardedVideoDidOpen];
}

/**
 Tell the delegate that  the rewarded video ad play page closes callback
 @param rewardedVideoAd GDTRewardVideoAd
 */
- (void)gdt_rewardVideoAdDidClose:(GDTRewardVideoAd *)rewardedVideoAd{
    LogAdapterDelegate_Internal(@"placementId = %@", rewardedVideoAd.placementId);
    id<ISRewardedVideoAdapterDelegate> delegate = [_rewardedVideoPlacementToDelegate objectForKey:rewardedVideoAd.placementId];
    [delegate adapterRewardedVideoDidClose];
}

/**
 Tell the delegate that  rewarded video ad information clicks callback
 @param rewardedVideoAd GDTRewardVideoAd
 */
- (void)gdt_rewardVideoAdDidClicked:(GDTRewardVideoAd *)rewardedVideoAd{
    LogAdapterDelegate_Internal(@"placementId = %@", rewardedVideoAd.placementId);
    id<ISRewardedVideoAdapterDelegate> delegate = [_rewardedVideoPlacementToDelegate objectForKey:rewardedVideoAd.placementId];
    [delegate adapterRewardedVideoDidClick];
}

/**
 Tell the delegate that  all error information of rewarded video ad is called back
 @param rewardedVideoAd GDTRewardVideoAd, error
 */
- (void)gdt_rewardVideoAd:(GDTRewardVideoAd *)rewardedVideoAd didFailWithError:(NSError *)error{
    LogAdapterDelegate_Internal(@"placementId = %@, error = %@", rewardedVideoAd.placementId, error);
    id<ISRewardedVideoAdapterDelegate> delegate = [_rewardedVideoPlacementToDelegate objectForKey:rewardedVideoAd.placementId];
    
    if ([self isLoadFailed:error]) {
//      load failed error: kTencentLoadFailedErrorCode
        NSError *smashError = error.code == kTencentNoFillErrorCode?
        [ISError createError:ERROR_RV_LOAD_NO_FILL withMessage:@"Tencent no fill"] :
        error;
        [delegate adapterRewardedVideoHasChangedAvailability:NO];
        [delegate adapterRewardedVideoDidFailToLoadWithError:smashError];
    } else if ([self isShowFailed:error]) {
//      show failed :kShowFailedErrorCode
        [delegate adapterRewardedVideoDidFailToShowWithError:error];
    }
}

/**
 Tell the delegate that  the rewarded video ad has reached the reward conditions for callback and this  callback serves as the reward basis
 @param rewardedVideoAd GDTRewardVideoAd
 @param info  @{@"GDT_TRANS_ID":@"930f1fc8ac59983bbdf4548ee40ac353"}, @“GDT_TRANS_ID” id
 */
- (void)gdt_rewardVideoAdDidRewardEffective:(GDTRewardVideoAd *)rewardedVideoAd info:(NSDictionary *)info {
    LogAdapterDelegate_Internal(@"placementId = %@", rewardedVideoAd.placementId);
    id<ISRewardedVideoAdapterDelegate> delegate = [_rewardedVideoPlacementToDelegate objectForKey:rewardedVideoAd.placementId];
    [delegate adapterRewardedVideoDidReceiveReward];
}

/**
 Tell the delegate that  the reward video ad play has completed the callback
 @param rewardedVideoAd GDTRewardVideoAd
 */
- (void)gdt_rewardVideoAdDidPlayFinish:(GDTRewardVideoAd *)rewardedVideoAd {
    LogAdapterDelegate_Internal(@"placementId = %@", rewardedVideoAd.placementId);
}


#pragma mark - Interstitial

- (void)initInterstitialWithUserId:(NSString *)userId adapterConfig:(ISAdapterConfig *)adapterConfig delegate:(id<ISInterstitialAdapterDelegate>)delegate {
    if (delegate == nil) {
        LogAdapterApi_Error(@"delegate == nil");
        return;
    }
    
    NSString *placementId = adapterConfig.settings[kPlacementID];
    
    if (![self isConfigValueValid:placementId]) {
        NSError *error = [self errorForMissingCredentialFieldWithName:placementId];
        LogAdapterApi_Error(@"error = %@", error);
        [delegate adapterInterstitialInitFailedWithError:error];
        return;
    }
    
    LogAdapterApi_Internal(@"placementId = %@ - userId = %@", placementId, userId);
    
    [self.interstitialPlacementToDelegate setObject:delegate forKey:placementId];
    
    [self initSDK:adapterConfig];

    if (initState == INIT_STATE_SUCCESS) {
        LogAdapterApi_Internal(@"interstitial init success - placementID = %@", placementId);
        [delegate adapterInterstitialInitSuccess];
    } else {
        NSError *error = [ISError createError:ERROR_CODE_INIT_FAILED withMessage:@"Tencent SDK init failed"];
        [delegate adapterInterstitialInitFailedWithError:error];
    }
}

- (void)loadInterstitialWithAdapterConfig:(ISAdapterConfig *)adapterConfig delegate:(id<ISInterstitialAdapterDelegate>)delegate {
    dispatch_async(dispatch_get_main_queue(), ^{
        NSString *placementId = adapterConfig.settings[kPlacementID];
        LogAdapterApi_Internal(@"placementId = %@", placementId);
        GDTUnifiedInterstitialAd *interstitialAd= [[GDTUnifiedInterstitialAd alloc] initWithPlacementId:placementId];
        [self.interstitialAds setObject:interstitialAd forKey:placementId];
        interstitialAd.delegate = self;
        [interstitialAd loadFullScreenAd];
    });
}


- (void)showInterstitialWithViewController:(UIViewController *)viewController
                             adapterConfig:(ISAdapterConfig *)adapterConfig
                                  delegate:(id<ISInterstitialAdapterDelegate>)delegate {
    dispatch_async(dispatch_get_main_queue(), ^{
        NSString *placementId = adapterConfig.settings[kPlacementID];
        
        if ([self hasInterstitialWithAdapterConfig:adapterConfig]) {
            GDTUnifiedInterstitialAd *isAd = [self.interstitialAds objectForKey:placementId];
            [isAd presentFullScreenAdFromRootViewController:viewController];
        } else {
            NSError *error = [NSError errorWithDomain:@"ISTencentAdapter" code:kISNotReadyErrorCode userInfo:nil];
            [delegate adapterInterstitialDidFailToShowWithError:error];
        }
    });
}

- (BOOL)hasInterstitialWithAdapterConfig:(ISAdapterConfig *)adapterConfig {
    NSString *placementId = adapterConfig.settings[kPlacementID];
    GDTUnifiedInterstitialAd *ad = [self.interstitialAds objectForKey:placementId];
    
    if (ad != nil) {
        return [ad isAdValid];
    }
    
    return false;
}


#pragma mark - Interstitial Delegate
/**
 *  Interstitial 2.0 ad preload success callback
 *  This function is called when the advertisement data returned by the receiving server is successful and preloaded
 */
- (void)unifiedInterstitialSuccessToLoadAd:(GDTUnifiedInterstitialAd *)unifiedInterstitial {
    LogAdapterDelegate_Internal(@"placementId = %@", unifiedInterstitial.placementId);
    id<ISInterstitialAdapterDelegate> delegate = [_interstitialPlacementToDelegate objectForKey:unifiedInterstitial.placementId];
    [delegate adapterInterstitialDidLoad];
}

/**
 *   Interstitial 2.0 ad preload failure callback
 *   This function is called when the advertisement data returned by the receiving server fails
 */
- (void)unifiedInterstitialFailToLoadAd:(GDTUnifiedInterstitialAd *)unifiedInterstitial error:(NSError *)error {
    LogAdapterDelegate_Internal(@"placementId = %@, error = %@", unifiedInterstitial.placementId, error);
    id<ISInterstitialAdapterDelegate> delegate = [_interstitialPlacementToDelegate objectForKey:unifiedInterstitial.placementId];
    NSError *smashError = (error.code == kTencentNoFillErrorCode)?
    [ISError createError:ERROR_IS_LOAD_NO_FILL withMessage:@"Tencent no fill"] :
    error;
    [delegate adapterInterstitialDidFailToLoadWithError:smashError];
}

/**
 *  Interstitial 2.0 ads will show callback
 *  Interstitial 2.0 ads are about to be displayed, callback this function
 */
- (void)unifiedInterstitialWillPresentScreen:(GDTUnifiedInterstitialAd *)unifiedInterstitial {
    LogAdapterDelegate_Internal(@"placementId = %@", unifiedInterstitial.placementId);
}

/**
 *  Interstitial 2.0 ad view display success callback
 *  This function is called back when the interstitial 2.0 ad is displayed successfully
 */
- (void)unifiedInterstitialDidPresentScreen:(GDTUnifiedInterstitialAd *)unifiedInterstitial {
    LogAdapterDelegate_Internal(@"placementId = %@", unifiedInterstitial.placementId);
    id<ISInterstitialAdapterDelegate> delegate = [_interstitialPlacementToDelegate objectForKey:unifiedInterstitial.placementId];
    [delegate adapterInterstitialDidOpen];
    [delegate adapterInterstitialDidShow];
}

/**
 *  Interstitial 2.0 ad view display failed callback
 *  Interstitial 2.0 ad display failure callback function
 */
- (void)unifiedInterstitialFailToPresent:(GDTUnifiedInterstitialAd *)unifiedInterstitial error:(NSError *)error {
    LogAdapterDelegate_Internal(@"placementId = %@, error = %@", unifiedInterstitial.placementId, error);
    id<ISInterstitialAdapterDelegate> delegate = [_interstitialPlacementToDelegate objectForKey:unifiedInterstitial.placementId];
    [delegate adapterInterstitialDidFailToShowWithError:error];
}

/**
 *  Interstitial 2.0 ad display end callback
 *  This function is called when the interstitial 2.0 ad display ends
 */
- (void)unifiedInterstitialDidDismissScreen:(GDTUnifiedInterstitialAd *)unifiedInterstitial {
    LogAdapterDelegate_Internal(@"placementId = %@", unifiedInterstitial.placementId);
    id<ISInterstitialAdapterDelegate> delegate = [_interstitialPlacementToDelegate objectForKey:unifiedInterstitial.placementId];
    [delegate adapterInterstitialDidClose];
}

/**
 *  When you click to download the app, the system program will be called to open other App or Appstore.
 */
- (void)unifiedInterstitialWillLeaveApplication:(GDTUnifiedInterstitialAd *)unifiedInterstitial {
    LogAdapterDelegate_Internal(@"placementId = %@", unifiedInterstitial.placementId);
}

/**
 *  Interstitial 2.0 ad exposure callback
 */
- (void)unifiedInterstitialWillExposure:(GDTUnifiedInterstitialAd *)unifiedInterstitial {
    LogAdapterDelegate_Internal(@"placementId = %@", unifiedInterstitial.placementId);
}

/**
 *  Interstitial 2.0 ad click callback
 */
- (void)unifiedInterstitialClicked:(GDTUnifiedInterstitialAd *)unifiedInterstitial {
    LogAdapterDelegate_Internal(@"placementId = %@", unifiedInterstitial.placementId);
    id<ISInterstitialAdapterDelegate> delegate = [_interstitialPlacementToDelegate objectForKey:unifiedInterstitial.placementId];
    [delegate adapterInterstitialDidClick];
}

/**
 *  Interstitial 2.0 advertising video caching completed
 */
- (void)unifiedInterstitialDidDownloadVideo:(GDTUnifiedInterstitialAd *)unifiedInterstitial {
    LogAdapterDelegate_Internal(@"placementId = %@", unifiedInterstitial.placementId);
}

/**
 *  Interstitial 2.0 ads rendered successfully
 *  It is recommended to display ads after this callback
 */
- (void)unifiedInterstitialRenderSuccess:(GDTUnifiedInterstitialAd *)unifiedInterstitial {
    LogAdapterDelegate_Internal(@"placementId = %@", unifiedInterstitial.placementId);
}

/**
 *  Interstitial 2.0 ad rendering failed
 */
- (void)unifiedInterstitialRenderFail:(GDTUnifiedInterstitialAd *)unifiedInterstitial error:(NSError *)error {
    LogAdapterDelegate_Internal(@"placementId = %@, error = %@", unifiedInterstitial.placementId, error);
}

/**
 *  After clicking on the interstitial 2.0 ad, a full-screen ad page will pop up
 */
- (void)unifiedInterstitialAdWillPresentFullScreenModal:(GDTUnifiedInterstitialAd *)unifiedInterstitial {
    LogAdapterDelegate_Internal(@"placementId = %@", unifiedInterstitial.placementId);
}

/**
 *  After clicking on the interstitial 2.0 ad, a full-screen ad page will pop up
 */
- (void)unifiedInterstitialAdDidPresentFullScreenModal:(GDTUnifiedInterstitialAd *)unifiedInterstitial {
    LogAdapterDelegate_Internal(@"placementId = %@", unifiedInterstitial.placementId);
}

/**
 *  The full screen ad page is about to close
 */
- (void)unifiedInterstitialAdWillDismissFullScreenModal:(GDTUnifiedInterstitialAd *)unifiedInterstitial {
    LogAdapterDelegate_Internal(@"placementId = %@", unifiedInterstitial.placementId);
}

/**
 *  Full screen ad page is closed
 */
- (void)unifiedInterstitialAdDidDismissFullScreenModal:(GDTUnifiedInterstitialAd *)unifiedInterstitial {
    LogAdapterDelegate_Internal(@"placementId = %@", unifiedInterstitial.placementId);
}

/**
 * Interstitial 2.0 video ad player playback status update callback
 */
- (void)unifiedInterstitialAd:(GDTUnifiedInterstitialAd *)unifiedInterstitial playerStatusChanged:(GDTMediaPlayerStatus)status {
    LogAdapterDelegate_Internal(@"placementId = %@", unifiedInterstitial.placementId);
}

/**
 * Interstitial 2.0 video ad details page WillPresent callback
 */
- (void)unifiedInterstitialAdViewWillPresentVideoVC:(GDTUnifiedInterstitialAd *)unifiedInterstitial {
    LogAdapterDelegate_Internal(@"placementId = %@", unifiedInterstitial.placementId);
}

/**
 * Interstitial 2.0 video ad details page DidPresent callback
 */
- (void)unifiedInterstitialAdViewDidPresentVideoVC:(GDTUnifiedInterstitialAd *)unifiedInterstitial {
    LogAdapterDelegate_Internal(@"placementId = %@", unifiedInterstitial.placementId);
}

/**
 * Interstitial 2.0 video ad details page WillDismiss callback
 */
- (void)unifiedInterstitialAdViewWillDismissVideoVC:(GDTUnifiedInterstitialAd *)unifiedInterstitial {
    LogAdapterDelegate_Internal(@"placementId = %@", unifiedInterstitial.placementId);
}

/**
 * Interstitial 2.0 video ad details page DidDismiss callback
 */
- (void)unifiedInterstitialAdViewDidDismissVideoVC:(GDTUnifiedInterstitialAd *)unifiedInterstitial {
    LogAdapterDelegate_Internal(@"placementId = %@", unifiedInterstitial.placementId);
}


#pragma mark - Banner

- (void)initBannerWithUserId:(nonnull NSString *)userId
               adapterConfig:(nonnull ISAdapterConfig *)adapterConfig
                    delegate:(nonnull id<ISBannerAdapterDelegate>)delegate {
    if (delegate == nil) {
        LogAdapterApi_Error(@"delegate == nil");
        return;
    }
    
    NSString *placementId = adapterConfig.settings[kPlacementID];
    
    if (![self isConfigValueValid:placementId]) {
        NSError *error = [self errorForMissingCredentialFieldWithName:placementId];
        LogAdapterApi_Error(@"error = %@", error);
        [delegate adapterBannerInitFailedWithError:error];
        return;
    }
    
    LogAdapterApi_Internal(@"placementId = %@ - userId = %@", placementId, userId);
    
    [self.bannerPlacementToDelegate setObject:delegate forKey:placementId];
    
    [self initSDK:adapterConfig];
    
    if (initState == INIT_STATE_SUCCESS) {
        LogAdapterApi_Internal(@"interstitial init success - placementID = %@", placementId);
        [delegate adapterBannerInitSuccess];
    } else {
        NSError *error = [ISError createError:ERROR_CODE_INIT_FAILED withMessage:@"Tencent SDK init failed"];
        [delegate adapterBannerInitFailedWithError:error];
    }
}

- (void)loadBannerWithViewController:(nonnull UIViewController *)viewController
                                size:(ISBannerSize *)size
                       adapterConfig:(nonnull ISAdapterConfig *)adapterConfig
                            delegate:(nonnull id <ISBannerAdapterDelegate>)delegate {
    NSString *placementId = adapterConfig.settings[kPlacementID];
    
    // verify size
    if (![self isBannerSizeSupported:size]) {
        NSError *error = [ISError createError:ERROR_BN_UNSUPPORTED_SIZE withMessage:@"Tencent unsupported banner size"];
        LogInternal_Error(@"error = %@", error);
        [delegate adapterBannerDidFailToLoadWithError:error];
        return;
    }
    
    dispatch_async(dispatch_get_main_queue(), ^{
        CGRect bannerSize = [self getBannerRect:size];
        GDTUnifiedBannerView *adView =[[GDTUnifiedBannerView alloc] initWithFrame:bannerSize placementId:placementId viewController:viewController];
        // add to dictionaries
        [self.bannerAdToPlacementId setObject:placementId forKey:adView];
        [self.bannerAds setObject:adView forKey:placementId];
        
        adView.delegate = self;
        [adView loadAdAndShow];
    });
}

/// This method will not be called from version 6.14.0 - we leave it here for backwords compatibility
- (void)reloadBannerWithAdapterConfig:(nonnull ISAdapterConfig *)adapterConfig
                             delegate:(nonnull id <ISBannerAdapterDelegate>)delegate {
    NSString *placementId = adapterConfig.settings[kPlacementID];
    LogAdapterApi_Internal(@"placementId = %@", placementId);
    GDTUnifiedBannerView *adView = [self.bannerAds objectForKey:placementId];
    
    if (adView) {
        [adView loadAdAndShow];
    } else {
        id<ISBannerAdapterDelegate> delegate = [self.bannerPlacementToDelegate objectForKey:placementId];
        NSError *error = [NSError errorWithDomain:@"ISTencentAdapter" code:kBNFailedToReloadErrorCode userInfo:@{NSLocalizedDescriptionKey : @"reloadBanner Failed"}];
        LogAdapterApi_Internal(@"error = %@", error);
        [delegate adapterBannerDidFailToLoadWithError:error];
    }
}

- (void)destroyBannerWithAdapterConfig:(nonnull ISAdapterConfig *)adapterConfig {
    // adUnitID
    NSString *placementId = adapterConfig.settings[kPlacementID];
    GDTUnifiedBannerView *adView = [self.bannerAds objectForKey:placementId];
    
    // Remove from ad dictionary
    [adView removeFromSuperview];
    adView = nil;
    [self.bannerAds removeObjectForKey:placementId];
    [self.bannerAdToPlacementId removeObjectForKey:adView];
}

- (void)releaseMemoryWithAdapterConfig:(ISAdapterConfig *)adapterConfig {
    // releasing memory currently only for banners
    NSString *placementId = adapterConfig.settings[kPlacementID];
    GDTUnifiedBannerView *adView = [self.bannerAds objectForKey:placementId];
    
    if (adView) {
        [self destroyBannerWithAdapterConfig:adapterConfig];
    }
}


#pragma mark - Banner Delegate

/**
 *  Call after a successful request for banner data.
 */
- (void)unifiedBannerViewDidLoad:(GDTUnifiedBannerView *)unifiedBannerView {
    NSString *placementId = [self.bannerAdToPlacementId objectForKey:unifiedBannerView];
    LogAdapterDelegate_Internal(@"placementId = %@", placementId);
    id<ISBannerAdapterDelegate> delegate = [self.bannerPlacementToDelegate objectForKey:placementId];
    [delegate adapterBannerDidLoad:unifiedBannerView];
}

/**
 *  Call after a failed request for banner data.
 */
- (void)unifiedBannerViewFailedToLoad:(GDTUnifiedBannerView *)unifiedBannerView error:(NSError *)error {
    NSString *placementId = [self.bannerAdToPlacementId objectForKey:unifiedBannerView];
    LogAdapterDelegate_Internal(@"placementId = %@, error = %@", placementId, error);
    id<ISBannerAdapterDelegate> delegate = [self.bannerPlacementToDelegate objectForKey:placementId];
    NSError *smashError = (error.code == kTencentNoFillErrorCode)?
    [ISError createError:ERROR_BN_LOAD_NO_FILL withMessage:@"Tencent no fill"] :
    error;
    [delegate adapterBannerDidFailToLoadWithError:smashError];
}

/**
 *  Banner2.0 exposure callback
 */
- (void)unifiedBannerViewWillExpose:(GDTUnifiedBannerView *)unifiedBannerView {
    NSString *placementId = [self.bannerAdToPlacementId objectForKey:unifiedBannerView];
    LogAdapterDelegate_Internal(@"placementId = %@", placementId);
    id<ISBannerAdapterDelegate> delegate = [self.bannerPlacementToDelegate objectForKey:placementId];
    [delegate adapterBannerDidShow];
}

/**
 *  Banner2.0 click callback
 */
- (void)unifiedBannerViewClicked:(GDTUnifiedBannerView *)unifiedBannerView {
    NSString *placementId = [self.bannerAdToPlacementId objectForKey:unifiedBannerView];
    LogAdapterDelegate_Internal(@"placementId = %@", placementId);
    id<ISBannerAdapterDelegate> delegate = [self.bannerPlacementToDelegate objectForKey:placementId];
    [delegate adapterBannerDidClick];
}

/**
 *  Full-screen ad page will pop up after Banner 2.0 is clicked
 */
- (void)unifiedBannerViewWillPresentFullScreenModal:(GDTUnifiedBannerView *)unifiedBannerView {
    NSString *placementId = [self.bannerAdToPlacementId objectForKey:unifiedBannerView];
    LogAdapterDelegate_Internal(@"placementId = %@", placementId);
    id<ISBannerAdapterDelegate> delegate = [self.bannerPlacementToDelegate objectForKey:placementId];
    [delegate adapterBannerWillPresentScreen];
}

/**
 *  Full-screen ad page has poped up after Banner 2.0 is clicked
 */
- (void)unifiedBannerViewDidPresentFullScreenModal:(GDTUnifiedBannerView *)unifiedBannerView {
    NSString *placementId = [self.bannerAdToPlacementId objectForKey:unifiedBannerView];
    LogAdapterDelegate_Internal(@"placementId = %@", placementId);
}

/**
 *  Full-screen ad page is going to be closed
 */
- (void)unifiedBannerViewWillDismissFullScreenModal:(GDTUnifiedBannerView *)unifiedBannerView {
    NSString *placementId = [self.bannerAdToPlacementId objectForKey:unifiedBannerView];
    LogAdapterDelegate_Internal(@"placementId = %@", placementId);
}

/**
 *  Full-screen ad page has been closed
 */
- (void)unifiedBannerViewDidDismissFullScreenModal:(GDTUnifiedBannerView *)unifiedBannerView {
    NSString *placementId = [self.bannerAdToPlacementId objectForKey:unifiedBannerView];
    LogAdapterDelegate_Internal(@"placementId = %@", placementId);
    id<ISBannerAdapterDelegate> delegate = [self.bannerPlacementToDelegate objectForKey:placementId];
    [delegate adapterBannerDidDismissScreen];
}

/**
 *  Open when clicking on an app to download or an ad to invoke the system  app
 */
- (void)unifiedBannerViewWillLeaveApplication:(GDTUnifiedBannerView *)unifiedBannerView {
    NSString *placementId = [self.bannerAdToPlacementId objectForKey:unifiedBannerView];
    LogAdapterDelegate_Internal(@"placementId = %@", placementId);
    id<ISBannerAdapterDelegate> delegate = [self.bannerPlacementToDelegate objectForKey:placementId];
    [delegate adapterBannerWillLeaveApplication];
}

/**
 *  Call when Banner 2.0 is closed by users
 */
- (void)unifiedBannerViewWillClose:(GDTUnifiedBannerView *)unifiedBannerView {
    NSString *placementId = [self.bannerAdToPlacementId objectForKey:unifiedBannerView];
    LogAdapterDelegate_Internal(@"placementId = %@", placementId);
}


#pragma mark - Private Methods

- (void)initSDK:(ISAdapterConfig *)adapterConfig {
    LogAdapterDelegate_Internal(@"");
    
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        NSString *appId = adapterConfig.settings[kAppId];
        BOOL isSuccess = [GDTSDKConfig registerAppId:appId];
        
        if (isSuccess) {
            //init succes
            initState = INIT_STATE_SUCCESS;
        } else {
            //init failed
            initState = INIT_STATE_FAILED;
        }
    });
}

- (bool)isBannerSizeSupported:(ISBannerSize *)size {
    if ([size.sizeDescription isEqualToString:@"BANNER"]) {
        return true;
    } else if ([size.sizeDescription isEqualToString:@"LARGE"]) {
        return true;
    } else if ([size.sizeDescription isEqualToString:@"RECTANGLE"]) {
        return true;
    } else if ([size.sizeDescription isEqualToString:@"SMART"]) {
        return true;
    }
    
    return false;
}

- (CGRect)getBannerRect:(ISBannerSize *)size {
    if ([size.sizeDescription isEqualToString:@"BANNER"]) {
        return CGRectMake(0, 0, 320, 50);
    } else if ([size.sizeDescription isEqualToString:@"LARGE"]) {
        return CGRectMake(0, 0, 300, 90);
    } else if ([size.sizeDescription isEqualToString:@"RECTANGLE"]) {
        return CGRectMake(0, 0, 300, 250);
    } else if ([size.sizeDescription isEqualToString:@"SMART"]) {
        if (UI_USER_INTERFACE_IDIOM() == UIUserInterfaceIdiomPad) {
            return CGRectMake(0, 0, 728, 90);
        }
        else {
            return CGRectMake(0, 0, 320, 50);
        }
    }
    
    return CGRectMake(0, 0, 0, 0);
}

- (BOOL)isLoadFailed:(NSError * _Nonnull)error {
    return error.code == kTencentLoadFailedErrorCode || error.code == kTencentNoFillErrorCode;
}

- (BOOL)isShowFailed:(NSError * _Nonnull)error {
    return error.code == kTencentShowFailedErrorCode;
}

@end
