//
//  ISGameloftAdapter.m
//  ISGameloftAdapter
//
//  Created by Hadar Pur on 02/08/2020.
//

#import "ISGameloftAdapter.h"
#import "ISGameloftAdapterSingleton.h"
#include "GLAdsSDKWrapper.h"

static NSString * const kAdapterVersion = GameloftAdapterVersion;
static NSString * const kAppId        = @"appID";
static NSString * const kInstanceId   = @"instanceIdValue";
static NSString * const kAdapterName  = @"Gameloft";

typedef NS_ENUM(NSInteger, GameloftInitState) {
    INIT_STATE_NONE,
    INIT_STATE_IN_PROGRESS,
    INIT_STATE_SUCCESS
};

static GameloftInitState initState = INIT_STATE_NONE;
static NSMutableSet<ISNetworkInitCallbackProtocol> *initCallbackDelegates = nil;

@interface ISGameloftAdapter () <ISGameloftDelegate, ISNetworkInitCallbackProtocol>
@end

@implementation ISGameloftAdapter {
    
    // Rewarded video
    ConcurrentMutableDictionary* _instanceIdToRewardedVideoSmashDelegate;
    NSMutableSet*                _rewardedVideoPlacementsForInitCallbacks;
    
    // Interstitial
    ConcurrentMutableDictionary* _instanceIdToInterstitialSmashDelegate;
    
    //Banner
    ConcurrentMutableDictionary* _instanceIdToBannerSmashDelegate;
}

#pragma mark - Initializations Methods

- (instancetype)initAdapter:(NSString *)name {
    self = [super initAdapter:name];
    
    if (self) {
        
        if(initCallbackDelegates == nil) {
            initCallbackDelegates = [NSMutableSet<ISNetworkInitCallbackProtocol> new];
        }
        
        //rewarded video
        _instanceIdToRewardedVideoSmashDelegate = [ConcurrentMutableDictionary dictionary];
        _rewardedVideoPlacementsForInitCallbacks = [[NSMutableSet alloc] init];
        
        //interstitial
        _instanceIdToInterstitialSmashDelegate = [ConcurrentMutableDictionary dictionary];
        
        //banner
        _instanceIdToBannerSmashDelegate = [ConcurrentMutableDictionary dictionary];
        
        // load while show
        LWSState = LOAD_WHILE_SHOW_BY_NETWORK;
    }
    
    return self;
}

#pragma mark - IronSource Protocol Methods

- (NSString *)version {
    return kAdapterVersion;
}

- (NSString *)sdkVersion {
    return GLAdsSDK.VersionString;
}

- (NSArray *)systemFrameworks {
    return @[@"CoreTelephony", @"iAd", @"MultipeerConnectivity", @"Photos", @"SystemConfiguration", @"UserNotifications",  @"WebKit"];
}

- (NSString *)sdkName {
    return kAdapterName;
}

#pragma mark - Init Gameloft
- (void)initSDK{
    LogInternal_Internal(@"");
    if(initState == INIT_STATE_NONE || initState == INIT_STATE_IN_PROGRESS){
        [initCallbackDelegates addObject:self];
    }
    
    // notice that dispatch_once is synchronous
    static dispatch_once_t oncePredicate;
    dispatch_once(&oncePredicate, ^{
        if (initState == INIT_STATE_NONE) {
            
            LogAdapterApi_Internal(@"init SDK");
            
            // set init in progress
            initState = INIT_STATE_IN_PROGRESS;
            
            // init SDK
            [GLAdsSDK InitializeWithDelegate:[ISGameloftAdapterSingleton sharedInstance]];
            
            
            // set init success
            initState = INIT_STATE_SUCCESS;
            
            // call success
            for (id<ISNetworkInitCallbackProtocol> initDelegate in initCallbackDelegates) {
                [initDelegate onNetworkInitCallbackSuccess];
            }
            
            [initCallbackDelegates removeAllObjects];
            
        }
    });
}


- (void)onNetworkInitCallbackSuccess {
    LogAdapterApi_Internal(@"");
    //rewarded video
    NSArray *rewardedVideoInstanceIDs = _instanceIdToRewardedVideoSmashDelegate.allKeys;
    for (NSString* instanceId in rewardedVideoInstanceIDs) {
        id<ISRewardedVideoAdapterDelegate> delegate =[_instanceIdToRewardedVideoSmashDelegate objectForKey:instanceId];
        if ([_rewardedVideoPlacementsForInitCallbacks containsObject:instanceId]) {
            [delegate adapterRewardedVideoInitSuccess];
        } else {
            [self loadRewardVideoWithInstanceId:instanceId delegate:delegate];
        }
    }
    
    // interstitial
    NSArray *interstitialInstanceIDs = _instanceIdToInterstitialSmashDelegate.allKeys;
    for (NSString* instanceId in interstitialInstanceIDs) {
        id<ISInterstitialAdapterDelegate> delegate = [_instanceIdToInterstitialSmashDelegate objectForKey:instanceId];
        [delegate adapterInterstitialInitSuccess];
    }
    
    // banner
    NSArray *bannerInstanceIDs = _instanceIdToBannerSmashDelegate.allKeys;
    for (NSString* instanceId in bannerInstanceIDs) {
        id<ISBannerAdapterDelegate> delegate = [_instanceIdToBannerSmashDelegate objectForKey:instanceId];
        [delegate adapterBannerInitSuccess];
    }
}

- (void)onNetworkInitCallbackFailed:(nonnull NSString *)errorMessage {
    
}


#pragma mark - Rewarded Video

- (void)initAndLoadRewardedVideoWithUserId:(NSString *)userId
                             adapterConfig:(ISAdapterConfig *)adapterConfig
                                  delegate:(id<ISRewardedVideoAdapterDelegate>)delegate {
    
    LogInternal_Internal(@"");
    NSString *instanceId = adapterConfig.settings[kInstanceId];
    
    // check instanceID
    if (![self isConfigValueValid:instanceId]) {
        NSError *error = [self errorForMissingCredentialFieldWithName:kInstanceId];
        LogInternal_Error(@"error.description = %@", error.description);
        [delegate adapterRewardedVideoHasChangedAvailability:NO];
        return;
    }
    
    // set delegate
    [[ISGameloftAdapterSingleton sharedInstance] addRewardedVideoDelegate:self forInstanceId:instanceId];
    
    // add delegate to map
    [_instanceIdToRewardedVideoSmashDelegate setObject:delegate forKey:instanceId];
    
    dispatch_async(dispatch_get_main_queue(), ^{
        [self initSDK];
        
        if (initState == INIT_STATE_SUCCESS) {
            [self loadRewardVideoWithInstanceId:instanceId delegate:delegate];
        }
    });
}

- (void)initRewardedVideoForCallbacksWithUserId:(NSString *)userId
                                  adapterConfig:(ISAdapterConfig *)adapterConfig
                                       delegate:(id<ISRewardedVideoAdapterDelegate>)delegate {
    
    LogInternal_Internal(@"");
    NSString *instanceId = adapterConfig.settings[kInstanceId];
    
    // check instanceID
    if (![self isConfigValueValid:instanceId]) {
        NSError *error = [self errorForMissingCredentialFieldWithName:kInstanceId];
        LogInternal_Error(@"error.description = %@", error.description);
        [delegate adapterRewardedVideoInitFailed:error];
        return;
    }
    
    // set delegate
    [[ISGameloftAdapterSingleton sharedInstance] addRewardedVideoDelegate:self forInstanceId:instanceId];
    
    // add delegate to map
    [_instanceIdToRewardedVideoSmashDelegate setObject:delegate forKey:instanceId];
    [_rewardedVideoPlacementsForInitCallbacks addObject:instanceId];
    
    dispatch_async(dispatch_get_main_queue(), ^{
        [self initSDK];
        
        if (initState == INIT_STATE_SUCCESS) {
            [delegate adapterRewardedVideoInitSuccess];
        }
    });
}

- (void)fetchRewardedVideoForAutomaticLoadWithAdapterConfig:(ISAdapterConfig *)adapterConfig delegate:(id<ISRewardedVideoAdapterDelegate>)delegate {
    LogInternal_Internal(@"");
    NSString *instanceId = adapterConfig.settings[kInstanceId];
    [self loadRewardVideoWithInstanceId:instanceId delegate:delegate];
    
}

- (void) loadRewardVideoWithInstanceId:(NSString *)instanceId delegate:(id<ISRewardedVideoAdapterDelegate>)delegate {
    LogAdapterApi_Internal(@"instanceId = %@", instanceId);
    [GLAdsSDK LoadAd:GLAdsSDK_AdType_Incentivized instance:instanceId];
}

- (void)showRewardedVideoWithViewController:(UIViewController *)viewController adapterConfig:(ISAdapterConfig *)adapterConfig delegate:(id<ISRewardedVideoAdapterDelegate>)delegate {
    NSString *instanceId = adapterConfig.settings[kInstanceId];
    LogAdapterApi_Internal(@"instanceId = %@", instanceId);
    
    if ([self hasRewardedVideoWithAdapterConfig:adapterConfig]) {
        [GLAdsSDK ShowLoadedAd:GLAdsSDK_AdType_Incentivized instance:instanceId];
    } else {
        NSError *error = [ISError createError:ERROR_CODE_NO_ADS_TO_SHOW withMessage:[NSString stringWithFormat: @"%@ show failed", kAdapterName]];
        LogInternal_Error(@"error = %@", error);
        [delegate adapterRewardedVideoDidFailToShowWithError:error];
    }
    
    [delegate adapterRewardedVideoHasChangedAvailability:NO];
}

- (BOOL)hasRewardedVideoWithAdapterConfig:(ISAdapterConfig *)adapterConfig {
    NSString *instanceId = adapterConfig.settings[kInstanceId];
    BOOL isRewardedVideoAvailable = [GLAdsSDK IsAdLoaded:GLAdsSDK_AdType_Incentivized instance:instanceId];
    LogAdapterApi_Internal(@"instanceId = %@, isRewardedVideoAvailable = %@", instanceId, isRewardedVideoAvailable ? @"YES" : @"NO");
    return isRewardedVideoAvailable;
}

#pragma mark - Rewarded Video Delegate

- (void)rewardedVideoAdWasLoadedWithInstance:(nonnull NSString *)instance {
    id<ISRewardedVideoAdapterDelegate> delegate = [_instanceIdToRewardedVideoSmashDelegate objectForKey:instance];
    if (delegate != nil) {
        [delegate adapterRewardedVideoHasChangedAvailability:YES];
    }
}

- (void)rewardedVideoAdLoadFailedWithInstance:(nonnull NSString *)instance andReason:(GLAdsSDK_AdLoadFailedReason)reason {
    id<ISRewardedVideoAdapterDelegate> delegate = [_instanceIdToRewardedVideoSmashDelegate objectForKey:instance];
    if (delegate != nil) {
        NSError *error = [ISError createError:[self AdLoadFailedReasonToErrorCode:reason isBanner: NO] withMessage:[self AdLoadFailedReasonToString:reason]];
        [delegate adapterRewardedVideoDidFailToLoadWithError:error];
        [delegate adapterRewardedVideoHasChangedAvailability:NO];
    }
}

- (void)rewardedVideoAdWillShowWithInstance:(nonnull NSString *)instance {
    id<ISRewardedVideoAdapterDelegate> delegate = [_instanceIdToRewardedVideoSmashDelegate objectForKey:instance];
    if (delegate != nil) {
        [delegate adapterRewardedVideoDidOpen];
    }
}

- (void)rewardedVideoAdShowFailedWithInstance:(nonnull NSString *)instance andReason:(GLAdsSDK_AdShowFailedReason)reason {
    id<ISRewardedVideoAdapterDelegate> delegate = [_instanceIdToRewardedVideoSmashDelegate objectForKey:instance];
    if (delegate != nil) {
        NSError *error = [ISError createError:[self AdShowFailedReasonToErrorCode:reason isBanner: NO] withMessage:[self AdShowFailedReasonToString:reason]];
        [delegate adapterRewardedVideoDidFailToShowWithError:error];
        [delegate adapterRewardedVideoHasChangedAvailability:NO];
    }
}

- (void)rewardedVideoAdRewardedWithInstance:(nonnull NSString *)instance {
    id<ISRewardedVideoAdapterDelegate> delegate = [_instanceIdToRewardedVideoSmashDelegate objectForKey:instance];
    if (delegate != nil) {
        [delegate adapterRewardedVideoDidReceiveReward];
    }
}

- (void)rewardedVideoAdClickedWithInstance:(nonnull NSString *)instance {
    id<ISRewardedVideoAdapterDelegate> delegate = [_instanceIdToRewardedVideoSmashDelegate objectForKey:instance];
    if (delegate != nil) {
        [delegate adapterRewardedVideoDidClick];
    }
}

- (void)rewardedVideoAdWasClosedWithInstance:(nonnull NSString *)instance {
    id<ISRewardedVideoAdapterDelegate> delegate = [_instanceIdToRewardedVideoSmashDelegate objectForKey:instance];
    if (delegate != nil) {
        [delegate adapterRewardedVideoDidClose];
    }
}

- (void)rewardedVideoAdHasExpiredWithInstance:(nonnull NSString *)instance {
}

#pragma mark - Interstitial

- (void)initInterstitialWithUserId:(NSString *)userId adapterConfig:(ISAdapterConfig *)adapterConfig delegate:(id<ISInterstitialAdapterDelegate>)delegate {
    LogInternal_Internal(@"");
    NSString *instanceId = adapterConfig.settings[kInstanceId];
    
    // check instanceID
    if (![self isConfigValueValid:instanceId]) {
        NSError *error = [self errorForMissingCredentialFieldWithName:kInstanceId];
        LogInternal_Error(@"error.description = %@", error.description);
        [delegate adapterInterstitialInitFailedWithError:error];
        return;
    }
    
    // set delegate
    [[ISGameloftAdapterSingleton sharedInstance] addInterstitialDelegate:self forInstanceId:instanceId];
    
    // add delegate to map
    [_instanceIdToInterstitialSmashDelegate setObject:delegate forKey:instanceId];
    
    dispatch_async(dispatch_get_main_queue(), ^{
        [self initSDK];
        
        if (initState == INIT_STATE_SUCCESS) {
            [delegate adapterInterstitialInitSuccess];
        }
    });
}

- (void)loadInterstitialWithAdapterConfig:(ISAdapterConfig *)adapterConfig delegate:(id<ISInterstitialAdapterDelegate>)delegate {
    NSString *instanceId = adapterConfig.settings[kInstanceId];
    LogAdapterApi_Internal(@"instanceId = %@", instanceId);
    [GLAdsSDK LoadAd:GLAdsSDK_AdType_Interstitial instance:instanceId];
}

- (void)showInterstitialWithViewController:(UIViewController *)viewController adapterConfig:(ISAdapterConfig *)adapterConfig delegate:(id<ISInterstitialAdapterDelegate>)delegate {
    NSString *instanceId = adapterConfig.settings[kInstanceId];
    LogAdapterApi_Internal(@"instanceId = %@", instanceId);
    
    if ([self hasInterstitialWithAdapterConfig:adapterConfig]) {
        [GLAdsSDK ShowLoadedAd:GLAdsSDK_AdType_Interstitial instance:instanceId];
    } else {
        NSError *error = [ISError createError:ERROR_CODE_NO_ADS_TO_SHOW withMessage:[NSString stringWithFormat: @"%@ show failed", kAdapterName]];
        LogInternal_Error(@"error = %@", error);
        [delegate adapterInterstitialDidFailToShowWithError:error];
    }
}

- (BOOL)hasInterstitialWithAdapterConfig:(ISAdapterConfig *)adapterConfig {
    NSString *instanceId = adapterConfig.settings[kInstanceId];
    BOOL isInterstitialAvailable = [GLAdsSDK IsAdLoaded:GLAdsSDK_AdType_Interstitial instance:instanceId];
    LogAdapterApi_Internal(@"instanceId = %@, isInterstitialAvailable = %@", instanceId, isInterstitialAvailable ? @"YES" : @"NO");
    return isInterstitialAvailable;
}

#pragma mark - Interstitial Delegate

- (void)interstitialAdWasLoadedWithInstance:(nonnull NSString *)instance {
    id<ISInterstitialAdapterDelegate> delegate = [_instanceIdToInterstitialSmashDelegate objectForKey:instance];
    if (delegate != nil) {
        [delegate adapterInterstitialDidLoad];
    }
}

- (void)interstitialAdLoadFailedWithInstance:(nonnull NSString *)instance andReason:(GLAdsSDK_AdLoadFailedReason)reason {
    id<ISInterstitialAdapterDelegate> delegate = [_instanceIdToInterstitialSmashDelegate objectForKey:instance];
    if (delegate != nil) {
        NSError *error = [ISError createError:[self AdLoadFailedReasonToErrorCode:reason isBanner: NO] withMessage:[self AdLoadFailedReasonToString:reason]];
        [delegate adapterInterstitialDidFailToLoadWithError:error];
    }
}

- (void)interstitialAdWillShowWithInstance:(nonnull NSString *)instance {
    id<ISInterstitialAdapterDelegate> delegate = [_instanceIdToInterstitialSmashDelegate objectForKey:instance];
    if (delegate != nil) {
        [delegate adapterInterstitialDidOpen];
        [delegate adapterInterstitialDidShow];
    }
}

- (void)interstitialAdShowFailedWithInstance:(nonnull NSString *)instance andReason:(GLAdsSDK_AdShowFailedReason)reason {
    id<ISInterstitialAdapterDelegate> delegate = [_instanceIdToInterstitialSmashDelegate objectForKey:instance];
    if (delegate != nil) {
        NSError *error = [ISError createError:[self AdShowFailedReasonToErrorCode:reason isBanner: NO] withMessage:[self AdShowFailedReasonToString:reason]];
        [delegate adapterInterstitialDidFailToShowWithError:error];
    }
}

- (void)interstitialAdClickedWithInstance:(nonnull NSString *)instance {
    id<ISInterstitialAdapterDelegate> delegate = [_instanceIdToInterstitialSmashDelegate objectForKey:instance];
    if (delegate != nil) {
        [delegate adapterInterstitialDidClick];
    }
}

- (void)interstitialAdWasClosedWithInstance:(nonnull NSString *)instance {
    id<ISInterstitialAdapterDelegate> delegate = [_instanceIdToInterstitialSmashDelegate objectForKey:instance];
    if (delegate != nil) {
        [delegate adapterInterstitialDidClose];
    }
}

- (void)interstitialAdHasExpiredWithInstance:(nonnull NSString *)instance {
}

#pragma mark - Banner

- (void)initBannerWithUserId:(NSString *)userId adapterConfig:(ISAdapterConfig *)adapterConfig delegate:(id<ISBannerAdapterDelegate>)delegate {
    LogInternal_Internal(@"");
    NSString *instanceId = adapterConfig.settings[kInstanceId];
    
    // check instanceID
    if (![self isConfigValueValid:instanceId]) {
        NSError *error = [self errorForMissingCredentialFieldWithName:kInstanceId];
        LogInternal_Error(@"error.description = %@", error.description);
        [delegate adapterBannerInitFailedWithError:error];
        return;
    }
    
    // set delegate
    [[ISGameloftAdapterSingleton sharedInstance] addBannerDelegate:self forInstanceId:instanceId];
    
    // add delegate to map
    [_instanceIdToBannerSmashDelegate setObject:delegate forKey:instanceId];
    
    dispatch_async(dispatch_get_main_queue(), ^{
        [self initSDK];
        
        if (initState == INIT_STATE_SUCCESS) {
            [delegate adapterBannerInitSuccess];
        }
    });
}

- (void)loadBannerWithViewController:(UIViewController *)viewController size:(ISBannerSize *)size adapterConfig:(ISAdapterConfig *)adapterConfig delegate:(id<ISBannerAdapterDelegate>)delegate {
    NSString *instanceId = adapterConfig.settings[kInstanceId];
    LogAdapterApi_Internal(@"instanceId = %@", instanceId);
    
    if (![self isConfigValueValid:instanceId]) {
        NSError *error = [self errorForMissingCredentialFieldWithName:kInstanceId];
        LogInternal_Error(@"error = %@", error);
        [delegate adapterBannerDidFailToLoadWithError:error];
        return;
    }
    
    // Verify size
    if (![self isBannerSizeSupported:size]) {
        NSError *error = [ISError createError:ERROR_BN_UNSUPPORTED_SIZE withMessage:[NSString stringWithFormat:@"%@ unsupported banner size - %@", kAdapterName ,size.sizeDescription]];
        LogInternal_Error(@"error = %@", error);
        [delegate adapterBannerDidFailToLoadWithError:error];
        return;
    }
    
    [GLAdsSDK LoadAd:GLAdsSDK_AdType_Banner instance:instanceId];
}

- (void)reloadBannerWithAdapterConfig:(ISAdapterConfig *)adapterConfig delegate:(id<ISBannerAdapterDelegate>)delegate {
    NSString *instanceId = adapterConfig.settings[kInstanceId];
    LogAdapterApi_Internal(@"instanceId = %@", instanceId);
    
    if (![self isConfigValueValid:instanceId]) {
        NSError *error = [self errorForMissingCredentialFieldWithName:kInstanceId];
        LogInternal_Error(@"error = %@", error);
        [delegate adapterBannerDidFailToLoadWithError:error];
        return;
    }
    
    [GLAdsSDK LoadAd:GLAdsSDK_AdType_Banner instance:instanceId];
}

- (void)destroyBannerWithAdapterConfig:(ISAdapterConfig *)adapterConfig {
    NSString *instanceId = adapterConfig.settings[kInstanceId];
    LogAdapterApi_Internal(@"instanceId = %@", instanceId);
    
    // destroy banner
    [GLAdsSDK HideAd:GLAdsSDK_AdType_Banner];
}

- (BOOL)shouldBindBannerViewOnReload {
    return YES;
}

#pragma mark - Banner Delegate

- (void)bannerAdLoadFailedWithInstance:(nonnull NSString *)instance andReason:(GLAdsSDK_AdLoadFailedReason)reason {
    id<ISBannerAdapterDelegate> delegate = [_instanceIdToBannerSmashDelegate objectForKey:instance];
    if (delegate != nil) {
        NSError *error = [ISError createError:[self AdLoadFailedReasonToErrorCode:reason isBanner: YES] withMessage:[self AdLoadFailedReasonToString:reason]];
        [delegate adapterBannerDidFailToLoadWithError:error];
    }
}

- (void)bannerAdWasLoadedWithInstance:(nonnull NSString *)instance {
    [GLAdsSDK SetBannerPosition:0 yOffset:0 align:GLAdsSDK_AdAlign_Bottom_Center];
    [GLAdsSDK ShowLoadedAd:GLAdsSDK_AdType_Banner instance:instance];
}

- (void)bannerAdWillShowWithInstance:(NSString *)instance {
    id<ISBannerAdapterDelegate> delegate = [_instanceIdToBannerSmashDelegate objectForKey:instance];
    if (delegate != nil) {
        // create container
        UIView* containerView = [[UIView alloc] initWithFrame:CGRectZero];
        [delegate adapterBannerDidLoad:containerView];
    }
}

- (void)bannerAdShowFailedWithInstance:(NSString *)instance andReason:(GLAdsSDK_AdShowFailedReason)reason {
    id<ISBannerAdapterDelegate> delegate = [_instanceIdToBannerSmashDelegate objectForKey:instance];
    if (delegate != nil) {
        NSError *error = [ISError createError:[self AdShowFailedReasonToErrorCode:reason isBanner: YES] withMessage:[self AdShowFailedReasonToString:reason]];
        [delegate adapterBannerDidFailToLoadWithError:error];
    }
}

- (void)bannerAdClickedWithInstance:(nonnull NSString *)instance {
    id<ISBannerAdapterDelegate> delegate = [_instanceIdToBannerSmashDelegate objectForKey:instance];
    if (delegate != nil) {
        [delegate adapterBannerDidClick];
    }
}

- (void)bannerAdWasClosedWithInstance:(nonnull NSString *)instance {
    id<ISBannerAdapterDelegate> delegate = [_instanceIdToBannerSmashDelegate objectForKey:instance];
    if (delegate != nil) {
        [delegate adapterBannerDidDismissScreen];
    }
}

- (void)bannerAdHasExpiredWithInstance:(nonnull NSString *)instance {
}


#pragma mark - Helper Methods
-(NSString*) AdLoadFailedReasonToString:(GLAdsSDK_AdLoadFailedReason)reason {
    switch (reason) {
        case GLAdsSDK_AdLoadFailedReason_Invalid_Server_Response:
            return @"Invalid Server Response";
            
        case GLAdsSDK_AdLoadFailedReason_Network_Error:
            return @"Network Error";
            
        case GLAdsSDK_AdLoadFailedReason_No_Ad_Available:
            return @"No Ad Available";
            
        default:
            return @"Unknown Reason";
    }
}

-(int) AdLoadFailedReasonToErrorCode:(GLAdsSDK_AdLoadFailedReason)reason isBanner:(BOOL)isBanner {
    switch (reason) {
        case GLAdsSDK_AdLoadFailedReason_No_Ad_Available:
            return isBanner ? ERROR_BN_LOAD_NO_FILL : ERROR_CODE_NO_ADS_TO_SHOW;
            ;
        case GLAdsSDK_AdLoadFailedReason_Invalid_Server_Response:
        case GLAdsSDK_AdLoadFailedReason_Network_Error:
        default:
            return ERROR_CODE_GENERIC;
    }
}


-(NSString*) AdShowFailedReasonToString:(GLAdsSDK_AdShowFailedReason)reason {
    switch (reason) {
        case GLAdsSDK_AdShowFailedReason_Invalid_Server_Response:
            return @"Invalid Server Response";
            
        case GLAdsSDK_AdShowFailedReason_Network_Error:
            return @"Network Error";
            
        case GLAdsSDK_AdShowFailedReason_No_Ad_Available:
            return @"No Ad Available";
            
        case GLAdsSDK_AdShowFailedReason_Already_Showing:
            return @"Already Showing";
            
        case GLAdsSDK_AdShowFailedReason_Cancelled:
            return @"Cancelled";
            
        case GLAdsSDK_AdShowFailedReason_WebView_Crash:
            return @"WebView Crash";
            
        default:
            return @"Unknown Reason";
    }
}

-(int) AdShowFailedReasonToErrorCode:(GLAdsSDK_AdShowFailedReason)reason isBanner:(BOOL)isBanner {
    switch (reason) {
        case GLAdsSDK_AdShowFailedReason_No_Ad_Available:
            return isBanner ? ERROR_BN_LOAD_NO_FILL : ERROR_CODE_NO_ADS_TO_SHOW;
            
        case GLAdsSDK_AdShowFailedReason_Invalid_Server_Response:
        case GLAdsSDK_AdShowFailedReason_Network_Error:
        case GLAdsSDK_AdShowFailedReason_Already_Showing:
        case GLAdsSDK_AdShowFailedReason_Cancelled:
        case GLAdsSDK_AdShowFailedReason_WebView_Crash:
        default:
            return ERROR_CODE_GENERIC;
    }
}

- (BOOL) isBannerSizeSupported:(ISBannerSize *)size {
    if (size == nil) {
        LogAdapterDelegate_Internal(@"size is nil");
        return NO;
    }
    
    if ([size.sizeDescription isEqualToString:@"BANNER"] || [size.sizeDescription isEqualToString:@"SMART"]) {
        return YES;
    }
    
    return NO;
}

@end
