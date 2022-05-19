//
//  ISSnapAdapter.m
//  ISSnapAdapter
//
//  Created by Yonti Makmel on 24/09/2019.
//

#import "ISSnapAdapter.h"
#import <SAKSDK/SAKSDK.h>

#define SYSTEM_VERSION_GREATER_THAN_OR_EQUAL_TO(v)  ([[[UIDevice currentDevice] systemVersion] compare:v options:NSNumericSearch] != NSOrderedAscending)

typedef NS_ENUM(NSInteger, InitState) {
    INIT_STATE_NONE,
    INIT_STATE_IN_PROGRESS,
    INIT_STATE_FAILED,
    INIT_STATE_SUCCESS
};
static InitState _initState = INIT_STATE_NONE;
static NSMutableSet<ISNetworkInitCallbackProtocol> *initCallbackDelegates = nil;

static NSString * const kAdapterName        = @"Snap";
static NSString * const kAdapterVersion     = SnapAdapterVersion;
static NSString * const kAppId              = @"appId";
static NSString * const kSlotId             = @"slotId";

static NSInteger kUnsupportedAdapterErrorCode          = 101;

static BOOL osSupported = YES;
static BOOL allowArbitraryLoads = YES;



@interface ISSnapAdapter() <SAKInterstitialDelegate, SAKRewardedAdDelegate, SAKAdViewDelegate, ISNetworkInitCallbackProtocol>


// Interstitial
@property (nonatomic, strong) ConcurrentMutableDictionary *isSlotIdToSmashDelegate;
@property (nonatomic, strong) ConcurrentMutableDictionary *isSlotIdToAd;
@property (nonatomic, strong) NSMapTable                  *isAdToSlotId;

// Rewarded Video
@property (nonatomic, strong) ConcurrentMutableDictionary *rvSlotIdToSmashDelegate;
@property (nonatomic, strong) ConcurrentMutableDictionary *rvSlotIdToAd;
@property (nonatomic, strong) NSMapTable                  *rvAdToSlotId;
@property (nonatomic, strong) NSMutableSet                *rewardedVideoPlacementsForInitCallbacks;

// Banner
@property (nonatomic, strong) ConcurrentMutableDictionary *bnSlotIdToSmashDelegate;
@property (nonatomic, strong) ConcurrentMutableDictionary *bnSlotIdToAd;
@property (nonatomic, strong) NSMapTable                  *bnAdToSlotId;
@property (nonatomic, strong) ConcurrentMutableDictionary *bannerSlotIdToSize;
@property (nonatomic, strong) ConcurrentMutableDictionary *bannerSlotIdToViewController;



@end

@implementation ISSnapAdapter

#pragma mark IronSourceProtocol Methods

- (NSString *)sdkVersion {
    if([self isSupported]) {
        return [[SAKMobileAd shared] sdkVersion];
    }
    else {
        return [self getErrorMsgForUnsupportedAdapter];
    }
}

- (NSString *)version {
    return kAdapterVersion;
}

- (NSArray *)systemFrameworks {
    return @[@"CoreFoundation", @"Foundation", @"StoreKit"];
}

- (NSString *)sdkName {
    return @"SAKInterstitial";
}

- (void)setConsent:(BOOL)consent {
    // Snap does not support GDPR
}

#pragma mark - Initializations Methods

- (instancetype)initAdapter:(NSString *)name {
    self = [super initAdapter:name];
    
    if (self) {
        
        if(initCallbackDelegates == nil) {
            initCallbackDelegates = [NSMutableSet<ISNetworkInitCallbackProtocol> new];
        }
        
        //Interstitial
        _isSlotIdToSmashDelegate            = [ConcurrentMutableDictionary dictionary];
        _isSlotIdToAd                       = [ConcurrentMutableDictionary dictionary];
        _isAdToSlotId                       = [NSMapTable mapTableWithKeyOptions:NSMapTableStrongMemory valueOptions:NSMapTableWeakMemory];
        
        //Rewarded video
        _rvSlotIdToSmashDelegate            = [ConcurrentMutableDictionary dictionary];
        _rvSlotIdToAd                       = [ConcurrentMutableDictionary dictionary];
        _rvAdToSlotId                       = [NSMapTable mapTableWithKeyOptions:NSMapTableStrongMemory valueOptions:NSMapTableWeakMemory];
        _rewardedVideoPlacementsForInitCallbacks = [[NSMutableSet alloc] init];
        
        //Banner
        _bnSlotIdToSmashDelegate            = [ConcurrentMutableDictionary dictionary];
        _bnSlotIdToAd                       = [ConcurrentMutableDictionary dictionary];
        _bnAdToSlotId                       = [NSMapTable mapTableWithKeyOptions:NSMapTableStrongMemory valueOptions:NSMapTableWeakMemory];
        _bannerSlotIdToSize                 = [ConcurrentMutableDictionary dictionary];
        _bannerSlotIdToViewController       = [ConcurrentMutableDictionary dictionary];

    }
    return self;
}

- (void) initSDKWithAppId:(NSString *)appId {
    
    if(_initState == INIT_STATE_NONE || _initState == INIT_STATE_IN_PROGRESS){
        [initCallbackDelegates addObject:self];
    }
    
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        LogAdapterApi_Internal(@"");
        _initState = INIT_STATE_IN_PROGRESS;
        SAKRegisterRequestConfigurationBuilder *configurationBuilder = [SAKRegisterRequestConfigurationBuilder new];
        [configurationBuilder withSnapKitAppId:appId];
        [SAKMobileAd shared].debug = YES;
        [[SAKMobileAd shared] startWithConfiguration:[configurationBuilder build] completion:^(BOOL success, NSError * _Nullable error) {
            LogAdapterDelegate_Internal(@"success = %@", success ? @"YES" : @"NO");
            if (error || !success) {
                // failed
                LogAdapterDelegate_Internal(@"error = %@", error);
                _initState = INIT_STATE_FAILED;
                for (id<ISNetworkInitCallbackProtocol> initDelegate in initCallbackDelegates) {
                    [initDelegate onNetworkInitCallbackFailed:error.localizedDescription];
                }
            } else {
                // success
                _initState = INIT_STATE_SUCCESS;
                for (id<ISNetworkInitCallbackProtocol> initDelegate in initCallbackDelegates) {
                    [initDelegate onNetworkInitCallbackSuccess];
                }
            }
            [initCallbackDelegates removeAllObjects];
        }];
        
    });
}

- (void)onNetworkInitCallbackFailed:(nonnull NSString *)errorMessage {
    LogAdapterDelegate_Info(@"init failed error - %@", errorMessage);
    NSError *error = [NSError errorWithDomain:kAdapterName code:ERROR_CODE_INIT_FAILED
                        userInfo:@{NSLocalizedDescriptionKey:errorMessage}];


    // report interstitial init fail
    NSArray *interstitialSlotIDs = _isSlotIdToSmashDelegate.allKeys;
    for (NSString* slotId in interstitialSlotIDs) {
        id<ISInterstitialAdapterDelegate> delegate = [self.isSlotIdToSmashDelegate objectForKey:slotId];
        [delegate adapterInterstitialInitFailedWithError:error];
    }
    
    // report rewarded init fail
    NSArray *rewardedVideoSlotIDs = _rvSlotIdToSmashDelegate.allKeys;
    for (NSString* slotId in rewardedVideoSlotIDs) {
        id<ISRewardedVideoAdapterDelegate> delegate = [self.rvSlotIdToSmashDelegate objectForKey:slotId];
        if ([_rewardedVideoPlacementsForInitCallbacks containsObject:slotId]) {
            [delegate adapterRewardedVideoInitFailed:error];
        } else {
            [delegate adapterRewardedVideoHasChangedAvailability:NO];
        }
    }
    
    // report banner init fail
    NSArray *bannerSlotIDs = _bnSlotIdToSmashDelegate.allKeys;
    for (NSString* slotId in bannerSlotIDs) {
        id<ISBannerAdapterDelegate> delegate = [self.bnSlotIdToSmashDelegate objectForKey:slotId];
        [delegate adapterBannerInitFailedWithError:error];
    }
}

- (void)onNetworkInitCallbackSuccess {
    LogAdapterDelegate_Info(@"init success");

    // rewarded
    NSArray *rewardedVideoSlotIDs = _rvSlotIdToSmashDelegate.allKeys;
    for (NSString* slotId in rewardedVideoSlotIDs) {
        if ([_rewardedVideoPlacementsForInitCallbacks containsObject:slotId]) {
            id<ISRewardedVideoAdapterDelegate> delegate = [_rvSlotIdToSmashDelegate objectForKey:slotId];
            [delegate adapterRewardedVideoInitSuccess];
        } else {
            [self loadRewardedVideo:slotId];
        }
    }
    
    // interstitial
    NSArray *interstitialSlotIDs = _isSlotIdToSmashDelegate.allKeys;
    for (NSString *slotId in interstitialSlotIDs) {
        id<ISInterstitialAdapterDelegate> delegate = [_isSlotIdToSmashDelegate objectForKey:slotId];
        [delegate adapterInterstitialInitSuccess];
    }
    
    // banner
    NSArray *bannerSlotIDs = _bnSlotIdToSmashDelegate.allKeys;
    for (NSString *slotId in bannerSlotIDs) {
        id<ISBannerAdapterDelegate> delegate = [_bnSlotIdToSmashDelegate objectForKey:slotId];
        [delegate adapterBannerInitSuccess];
    }

}

#pragma mark - Interstitial API

- (void)initInterstitialWithUserId:(NSString *)userId
                     adapterConfig:(ISAdapterConfig *)adapterConfig
                          delegate:(id<ISInterstitialAdapterDelegate>)delegate {
    NSString *appId = adapterConfig.settings[kAppId];
    NSString *slotId = adapterConfig.settings[kSlotId];
    
    // validating configuration
    
    // check supported adapter
    if (![self isSupported]) {
        NSError *error = [self errorForUnsupportedAdapter];
        LogAdapterApi_Internal(@"error = %@", error);
        [delegate adapterInterstitialInitFailedWithError:error];
        return;
    }
    
    // app id
    if (![self isConfigValueValid:appId]) {
        NSError *error = [self errorForMissingCredentialFieldWithName:kAppId];
        LogAdapterApi_Internal(@"error = %@", error);
        [delegate adapterInterstitialInitFailedWithError:error];
        return;
    }
    
    // slot id
    if (![self isConfigValueValid:slotId]) {
        NSError *error = [self errorForMissingCredentialFieldWithName:kSlotId];
        LogAdapterApi_Internal(@"error = %@", error);
        [delegate adapterInterstitialInitFailedWithError:error];
        return;
    }
    
    // add to listener dictionary
    [self.isSlotIdToSmashDelegate setObject:delegate forKey:slotId];

    // init network sdk
    [self initSDKWithAppId:appId];
    
    // call init success
    if (_initState == INIT_STATE_SUCCESS) {
        LogAdapterApi_Internal(@"slotId = %@ - userId = %@", slotId, userId);
        [delegate adapterInterstitialInitSuccess];
    }
    else if (_initState == INIT_STATE_FAILED) {
        NSError *error = [NSError errorWithDomain:kAdapterName code:ERROR_CODE_INIT_FAILED userInfo:@{NSLocalizedDescriptionKey:@"init failed"}];
        LogAdapterApi_Internal(@"error.description = %@", error.description);
        [delegate adapterInterstitialInitFailedWithError:error];
    }
}

- (void)loadInterstitialWithAdapterConfig:(ISAdapterConfig *)adapterConfig
                                 delegate:(id<ISInterstitialAdapterDelegate>)delegate {
    
    // slot id
    NSString *slotId = adapterConfig.settings[kSlotId];
    if (![self isConfigValueValid:slotId]) {
        NSError *error = [self errorForMissingCredentialFieldWithName:kSlotId];
        LogAdapterApi_Internal(@"error = %@", error);
        [delegate adapterInterstitialDidFailToLoadWithError:error];
        return;
    }
    // create configuration
    SAKAdRequestConfigurationBuilder *configurationBuilder = [[SAKAdRequestConfigurationBuilder alloc] withPublisherSlotId:slotId];
    
    // create ad
    SAKInterstitial *intertitialAd = [SAKInterstitial new];
    intertitialAd.delegate = self;
    
    // add to ad dictionary
    [self.isSlotIdToAd setObject:intertitialAd forKey:slotId];
    [self.isAdToSlotId setObject:slotId forKey:intertitialAd];
    
    
    dispatch_async(dispatch_get_main_queue(), ^{
        // load request
        [intertitialAd loadRequest:[configurationBuilder build]];
    });
    
}

- (void)showInterstitialWithViewController:(UIViewController *)viewController
                             adapterConfig:(ISAdapterConfig *)adapterConfig
                                  delegate:(id<ISInterstitialAdapterDelegate>)delegate {
        // slot id
        NSString *slotId = adapterConfig.settings[kSlotId];
        
        // get ad from dictionary
        SAKInterstitial *interstitialAd = [self.isSlotIdToAd objectForKey:slotId];
        
        // check ad availability and show
        if (interstitialAd != nil && interstitialAd.isReady) {
            LogAdapterApi_Internal(@"show ad for slotId = %@", slotId);
            
            // show ad
            [interstitialAd presentFromRootViewController:viewController dismissTransition:CGRectZero];
        }
        else {
            // create error with reason
            NSString *reason = (interstitialAd ? @"ad expired" : @"ad is null");
            NSString *desc = [NSString stringWithFormat: @"%@ show failed - %@", kAdapterName, reason];
            NSError *error = [NSError errorWithDomain:kAdapterName code:ERROR_CODE_NO_ADS_TO_SHOW
                                             userInfo:@{NSLocalizedDescriptionKey:desc}];
            LogAdapterApi_Internal(@"failed to show for slotId = %@", slotId);
            LogAdapterApi_Internal(@"error = %@", error);
            [delegate adapterInterstitialDidFailToShowWithError:error];
        }
}

- (BOOL)hasInterstitialWithAdapterConfig:(ISAdapterConfig *)adapterConfig {
    if (![self isSupported]) {
        return NO;
    }
    NSString *slotId = adapterConfig.settings[kSlotId];
    SAKInterstitial *interstitialAd = [self.isSlotIdToAd objectForKey:slotId];
    return (interstitialAd != nil && interstitialAd.isReady);
}

#pragma mark - Rewarded Video API

- (void)initAndLoadRewardedVideoWithUserId:(NSString *)userId
                             adapterConfig:(ISAdapterConfig *)adapterConfig
                                  delegate:(id<ISRewardedVideoAdapterDelegate>)delegate {
    
    NSString *appId = adapterConfig.settings[kAppId];
    NSString *slotId = adapterConfig.settings[kSlotId];
    
    // validating configuration
    // check supported adapter, app id and slot id
    if (![self isSupported] || ![self isConfigValueValid:appId] || ![self isConfigValueValid:slotId]) {
        NSError *error = [self errorForUnsupportedAdapter];
        LogAdapterApi_Internal(@"error = %@", error);
        [delegate adapterRewardedVideoHasChangedAvailability:NO];
        return;
    }
    
    // add to listener dictionary
    [self.rvSlotIdToSmashDelegate setObject:delegate forKey:slotId];

    // init network sdk
    [self initSDKWithAppId:appId];
    
    // call init success
    if (_initState == INIT_STATE_SUCCESS) {
        LogAdapterApi_Internal(@"slotId = %@ - userID = %@", slotId, userId);
        [self loadRewardedVideo:slotId];
    }
    else if (_initState == INIT_STATE_FAILED) {
        NSError *error = [NSError errorWithDomain:kAdapterName code:ERROR_CODE_INIT_FAILED userInfo:@{NSLocalizedDescriptionKey:@"init error"}];
        LogAdapterApi_Internal(@"error.description = %@", error.description);
        [delegate adapterRewardedVideoHasChangedAvailability:NO];
    }
}

- (void)initRewardedVideoForCallbacksWithUserId:(NSString *)userId
                                  adapterConfig:(ISAdapterConfig *)adapterConfig
                                       delegate:(id<ISRewardedVideoAdapterDelegate>)delegate {
    
    NSString *appId = adapterConfig.settings[kAppId];
    NSString *slotId = adapterConfig.settings[kSlotId];
    
    // validating configuration
    
    // check supported adapter
    if (![self isSupported]) {
        NSError *error = [self errorForUnsupportedAdapter];
        LogAdapterApi_Internal(@"error = %@", error);
        [delegate adapterRewardedVideoInitFailed:error];
        return;
    }
    
    // app id
    if (![self isConfigValueValid:appId]) {
        NSError *error = [self errorForMissingCredentialFieldWithName:kAppId];
        LogAdapterApi_Internal(@"error = %@", error);
        [delegate adapterRewardedVideoInitFailed:error];
        return;
    }
    
    // slot id
    if (![self isConfigValueValid:slotId]) {
        NSError *error = [self errorForMissingCredentialFieldWithName:kSlotId];
        LogAdapterApi_Internal(@"error = %@", error);
        [delegate adapterRewardedVideoInitFailed:error];
        return;
    }
    
    // add to listener dictionary
    [self.rvSlotIdToSmashDelegate setObject:delegate forKey:slotId];
    [self.rewardedVideoPlacementsForInitCallbacks addObject:slotId];

    // init network sdk
    [self initSDKWithAppId:appId];
    
    // call init success
    if (_initState == INIT_STATE_SUCCESS) {
        LogAdapterApi_Internal(@"slotId = %@ - userID = %@", slotId, userId);
        [delegate adapterRewardedVideoInitSuccess];
    }
    else if (_initState == INIT_STATE_FAILED) {
        NSError *error = [NSError errorWithDomain:kAdapterName code:ERROR_CODE_INIT_FAILED userInfo:@{NSLocalizedDescriptionKey:@"init error"}];
        LogAdapterApi_Internal(@"error.description = %@", error.description);
        [delegate adapterRewardedVideoInitFailed:error];
    }
}

- (void) showRewardedVideoWithViewController:(UIViewController *)viewController
                               adapterConfig:(ISAdapterConfig *)adapterConfig
                               delegate:(id<ISRewardedVideoAdapterDelegate>)delegate {
    
        // slot id
        NSString *slotId = adapterConfig.settings[kSlotId];
        
        // get ad from dictionary
        SAKRewardedAd *rewardedVideoAd = [self.rvSlotIdToAd objectForKey:slotId];
        
        // check ad availability and show
        if (rewardedVideoAd != nil && rewardedVideoAd.isReady) {
            LogAdapterApi_Internal(@"show ad for slotId = %@", slotId);
            // show ad
            [rewardedVideoAd presentFromRootViewController:viewController dismissTransition:CGRectZero];
        }
        else {
            NSError *error = [NSError errorWithDomain:kAdapterName code:ERROR_CODE_NO_ADS_TO_SHOW
                                             userInfo:@{NSLocalizedDescriptionKey:@"show failed"}];
            LogAdapterApi_Internal(@"failed - rewardedVideoAd not valid");
            [delegate adapterRewardedVideoDidFailToShowWithError:error];
        }
    
        [delegate adapterRewardedVideoHasChangedAvailability:NO];

}

- (void) fetchRewardedVideoForAutomaticLoadWithAdapterConfig:(ISAdapterConfig *)adapterConfig delegate:(id<ISRewardedVideoAdapterDelegate>)delegate {
    NSString *slotId = adapterConfig.settings[kSlotId];
    LogAdapterApi_Internal(@"slotId = %@", slotId);
    if (![self isConfigValueValid:slotId]) {
        NSError *error = [self errorForMissingCredentialFieldWithName:kSlotId];
        LogAdapterApi_Internal(@"error = %@", error);
        [delegate adapterRewardedVideoHasChangedAvailability:NO];
        return;
    }
    [self loadRewardedVideo:slotId];
}

- (BOOL) hasRewardedVideoWithAdapterConfig:(ISAdapterConfig *)adapterConfig {
    if (![self isSupported]) {
        return NO;
    }
    NSString *slotId = adapterConfig.settings[kSlotId];
    SAKRewardedAd *rewardedAd = [self.rvSlotIdToAd objectForKey:slotId];
    return (rewardedAd != nil && rewardedAd.isReady);
}

#pragma mark - Banner

- (void)initBannerWithUserId:(nonnull NSString *)userId
           adapterConfig:(nonnull ISAdapterConfig *)adapterConfig
                delegate:(nonnull id<ISBannerAdapterDelegate>)delegate {
    
    NSString *appId = adapterConfig.settings[kAppId];
    NSString *slotId = adapterConfig.settings[kSlotId];
    
    // validating configuration
    // check supported adapter, app id and slot id
    if (![self isSupported] || ![self isConfigValueValid:appId] || ![self isConfigValueValid:slotId]) {
        NSError *error = [self errorForUnsupportedAdapter];
        LogAdapterApi_Internal(@"error = %@", error);
        [delegate adapterBannerInitFailedWithError:error];
        return;
    }
    
    // add to listener dictionary
    [self.bnSlotIdToSmashDelegate setObject:delegate forKey:slotId];

    // init network sdk
    [self initSDKWithAppId:appId];
    
    // call init success
    if (_initState == INIT_STATE_SUCCESS) {
        LogAdapterApi_Internal(@"slotId = %@ - userId = %@", slotId, userId);
        [delegate adapterBannerInitSuccess];
    }
    else if (_initState == INIT_STATE_FAILED) {
        NSError *error = [NSError errorWithDomain:kAdapterName code:ERROR_CODE_INIT_FAILED userInfo:@{NSLocalizedDescriptionKey:@"init failed"}];
        LogAdapterApi_Internal(@"error.description = %@", error.description);
        
        [delegate adapterBannerInitFailedWithError:error];
    }
}



- (void)loadBannerWithViewController:(nonnull UIViewController *)viewController
                                size:(ISBannerSize *)size
                       adapterConfig:(nonnull ISAdapterConfig *)adapterConfig
                      delegate:(nonnull id <ISBannerAdapterDelegate>)delegate {
   
    NSString* slotId = adapterConfig.settings[kSlotId];

    // add size to dictionary
    [_bannerSlotIdToSize setObject:size forKey:slotId];
    [_bannerSlotIdToViewController setObject:viewController forKey:slotId];
    [self loadBannerInternal:adapterConfig viewController:viewController delegate:delegate slotId:slotId];

}

- (void)reloadBannerWithAdapterConfig:(nonnull ISAdapterConfig *)adapterConfig
            delegate:(nonnull id <ISBannerAdapterDelegate>)delegate {

    NSString *slotId = adapterConfig.settings[kSlotId];
    LogAdapterApi_Internal(@"slotId = %@", slotId);
    UIViewController* viewController = [_bannerSlotIdToViewController objectForKey:slotId];
    [self loadBannerInternal:adapterConfig viewController:viewController delegate:delegate slotId:slotId];
    
}


- (void)destroyBannerWithAdapterConfig:(nonnull ISAdapterConfig *)adapterConfig {
    // slotId
    NSString *slotId = adapterConfig.settings[kSlotId];
    
    // Get banner
    SAKAdView *bannerAd = [_bnSlotIdToAd objectForKey:slotId];
    
    // Remove delegate
    if (bannerAd) {
        bannerAd.delegate = nil;
    }
    
    // Remove from ad dictionary and set null
    [_bnSlotIdToAd removeObjectForKey:slotId];
    [_bnAdToSlotId removeObjectForKey:bannerAd];
    bannerAd = nil;
}

#pragma mark - Interstitial Delegate

- (void)interstitialDidLoad:(SAKInterstitial *)ad {
    // get slot id from ad
    NSString *slotId = [self.isAdToSlotId objectForKey:ad];
    LogAdapterDelegate_Internal(@"slotId = %@", slotId);
    
    // get delegate by slot id
    id<ISInterstitialAdapterDelegate> delegate = [self.isSlotIdToSmashDelegate objectForKey:slotId];
    
    if (delegate != nil) {
        [delegate adapterInterstitialDidLoad];
    }
}

- (void)interstitialDidExpire:(SAKInterstitial *)ad {
    // get slot id from ad
    NSString *slotId = [self.isAdToSlotId objectForKey:ad];
    LogAdapterDelegate_Internal(@"slotId = %@", slotId);
}

- (void)interstitialWillAppear:(SAKInterstitial *)ad {
    LogAdapterDelegate_Internal(@"");
}

- (void)interstitialDidAppear:(SAKInterstitial *)ad {
    // get slot id from ad
    NSString *slotId = [self.isAdToSlotId objectForKey:ad];
    LogAdapterDelegate_Internal(@"slotId = %@", slotId);
    
    // get delegate by slot id
    id<ISInterstitialAdapterDelegate> delegate = [self.isSlotIdToSmashDelegate objectForKey:slotId];
    
    if (delegate != nil) {
        [delegate adapterInterstitialDidOpen];
        [delegate adapterInterstitialDidShow];
    }
}

- (void)interstitialWillDisappear:(SAKInterstitial *)ad {
    LogAdapterDelegate_Internal(@"");
}

- (void)interstitialDidDisappear:(SAKInterstitial *)ad {
    // get slot id from ad
    NSString *slotId = [self.isAdToSlotId objectForKey:ad];
    LogAdapterDelegate_Internal(@"slotId = %@", slotId);
    
    // get delegate by slot id
    id<ISInterstitialAdapterDelegate> delegate = [self.isSlotIdToSmashDelegate objectForKey:slotId];
    
    if (delegate != nil) {
        [delegate adapterInterstitialDidClose];
    }
}

- (void)interstitialDidShowAttachment:(SAKInterstitial *)ad {
    // get slot id from ad
    NSString *slotId = [self.isAdToSlotId objectForKey:ad];
    LogAdapterDelegate_Internal(@"slotId = %@", slotId);

    // get delegate by slot id
    id<ISInterstitialAdapterDelegate> delegate = [self.isSlotIdToSmashDelegate objectForKey:slotId];

    if (delegate != nil) {
        [delegate adapterInterstitialDidClick];
    }
}

- (void)interstitialDidTrackImpression:(SAKInterstitial *)ad {
    LogAdapterDelegate_Internal(@"");
}

- (void)interstitial:(nonnull SAKInterstitial *)ad didFailWithError:(nonnull NSError *)error {
    // get slot id from ad
    NSString *slotId = [self.isAdToSlotId objectForKey:ad];
    NSString *message = [self getErrorMessage:error.code];
    
    NSInteger errorCode = (error.code != SAKErrorNoAdAvailable) ? error.code : ERROR_IS_LOAD_NO_FILL;
    
    LogAdapterDelegate_Internal(@"slotId = %@", slotId);
    LogAdapterDelegate_Internal(@"code = %ld, %@", errorCode, message);
    
    // get delegate by slot id
    id<ISInterstitialAdapterDelegate> delegate = [self.isSlotIdToSmashDelegate objectForKey:slotId];
    NSLog(@" error => %@ ", [error localizedDescription] );

    NSError *generatedError = [[NSError alloc] initWithDomain:kAdapterName code:errorCode userInfo:@{NSLocalizedDescriptionKey:message}];
    
    if (delegate != nil) {
        [delegate adapterInterstitialDidFailToLoadWithError:generatedError];
    }
}


#pragma mark - Rewarded Video Delegate

- (void)rewardedAdDidLoad:(SAKRewardedAd *)ad {
    // get slot id from ad
    NSString *slotId = [self.rvAdToSlotId objectForKey:ad];
    LogAdapterDelegate_Internal(@"slotId = %@", slotId);
    
    // get delegate by slot id
    id<ISRewardedVideoAdapterDelegate> delegate = [self.rvSlotIdToSmashDelegate objectForKey:slotId];
    
    if (delegate != nil) {
        [delegate adapterRewardedVideoHasChangedAvailability:YES];
    }
}

- (void)rewardedAd:(SAKRewardedAd *)ad didFailWithError:(NSError *)error {
    // get slot id from ad
    NSString *slotId = [self.rvAdToSlotId objectForKey:ad];
    NSString *message = [self getErrorMessage:error.code];
    
    NSInteger errorCode = (error.code != SAKErrorNoAdAvailable) ? error.code : ERROR_RV_LOAD_NO_FILL;
    
    LogAdapterDelegate_Internal(@"slotId = %@", slotId);
    LogAdapterDelegate_Internal(@"code = %ld, %@", errorCode, message);
    // get delegate by slot id
    id<ISRewardedVideoAdapterDelegate> delegate = [self.rvSlotIdToSmashDelegate objectForKey:slotId];
    
    NSError *generatedError = [NSError errorWithDomain:kAdapterName code:errorCode userInfo:@{NSLocalizedDescriptionKey:message}];

    
    if (delegate != nil) {
        [delegate adapterRewardedVideoDidFailToLoadWithError:generatedError];
        [delegate adapterRewardedVideoHasChangedAvailability:NO];
    }
}

- (void)rewardedAdDidExpire:(SAKRewardedAd *)ad {
    LogAdapterDelegate_Internal(@"");
    // get delegate by slot id
    NSString *slotId = [self.rvAdToSlotId objectForKey:ad];
    id<ISRewardedVideoAdapterDelegate> delegate = [self.rvSlotIdToSmashDelegate objectForKey:slotId];

    if (delegate != nil) {
        NSError *error = [NSError errorWithDomain:kAdapterName code:ERROR_RV_EXPIRED_ADS
                                         userInfo:@{NSLocalizedDescriptionKey:@"ads are expired"}];
        [delegate adapterRewardedVideoDidFailToLoadWithError:error];
    }
}

- (void)rewardedAdWillAppear:(SAKRewardedAd *)ad {
    LogAdapterDelegate_Internal(@"");
    
}

- (void)rewardedAdDidAppear:(SAKRewardedAd *)ad {
    // get slot id from ad
    NSString *slotId = [self.rvAdToSlotId objectForKey:ad];
    LogAdapterDelegate_Internal(@"slotId = %@", slotId);
    
    // get delegate by slot id
    id<ISRewardedVideoAdapterDelegate> delegate = [self.rvSlotIdToSmashDelegate objectForKey:slotId];
    
    if (delegate != nil) {
        [delegate adapterRewardedVideoDidOpen];
    }
}

- (void)rewardedAdWillDisappear:(SAKRewardedAd *)ad {
    LogAdapterDelegate_Internal(@"");
}

- (void)rewardedAdDidDisappear:(SAKRewardedAd *)ad {
    // get slot id from ad
    NSString *slotId = [self.rvAdToSlotId objectForKey:ad];
    LogAdapterDelegate_Internal(@"slotId = %@", slotId);
    
    // get delegate by slot id
    id<ISRewardedVideoAdapterDelegate> delegate = [self.rvSlotIdToSmashDelegate objectForKey:slotId];
    
    if (delegate != nil) {
        [delegate adapterRewardedVideoDidEnd];
        [delegate adapterRewardedVideoDidClose];
    }
}

- (void)rewardedAdDidShowAttachment:(SAKRewardedAd *)ad {
    // get slot id from ad
    NSString *slotId = [self.rvAdToSlotId objectForKey:ad];
    LogAdapterDelegate_Internal(@"slotId = %@", slotId);
    
    // get delegate by slot id
    id<ISRewardedVideoAdapterDelegate> delegate = [self.rvSlotIdToSmashDelegate objectForKey:slotId];
    
    if (delegate != nil) {
        [delegate adapterRewardedVideoDidClick];
    }

}

- (void)rewardedAdDidEarnReward:(SAKRewardedAd *)ad {
    // get slot id from ad
    NSString *slotId = [self.rvAdToSlotId objectForKey:ad];
    LogAdapterDelegate_Internal(@"slotId = %@", slotId);
    
    // get delegate by slot id
    id<ISRewardedVideoAdapterDelegate> delegate = [self.rvSlotIdToSmashDelegate objectForKey:slotId];
    
    if (delegate != nil) {
        [delegate adapterRewardedVideoDidReceiveReward];
    }
}

#pragma mark - Banner Delegate

- (void)adView:(nonnull SAKAdView *)adView didFailWithError:(nonnull NSError *)error {
    // get slot id from ad
    NSString *slotId = [self.bnAdToSlotId objectForKey:adView];
    NSString *message = [self getErrorMessage:error.code];
    NSInteger errorCode = (error.code != SAKErrorNoAdAvailable) ? error.code:
        ERROR_BN_LOAD_NO_FILL;
    
    LogAdapterDelegate_Internal(@"slotId = %@", slotId);
    LogAdapterDelegate_Internal(@"code = %ld, %@", errorCode, message);
    
    // Smash delegate
    id<ISBannerAdapterDelegate> bannerDelegate = [_bnSlotIdToSmashDelegate objectForKey:slotId];
    
    if (!bannerDelegate) {
        LogAdapterApi_Internal(@"failed - null listener");
        return;
    }
    
    NSError *generatedError = [[NSError alloc] initWithDomain:kAdapterName code:errorCode userInfo:@{NSLocalizedDescriptionKey:message}];
    [bannerDelegate adapterBannerDidFailToLoadWithError:generatedError];
}

- (void)adViewDidClick:(nonnull SAKAdView *)adView {
    NSString *slotId = [self.bnAdToSlotId objectForKey:adView];
    LogAdapterDelegate_Internal(@"slotId = %@", slotId);
    
    // Smash delegate
    id<ISBannerAdapterDelegate> bannerDelegate = [_bnSlotIdToSmashDelegate objectForKey:slotId];
    
    if (!bannerDelegate) {
        LogAdapterApi_Internal(@"failed - null listener");
        return;
    }
    
    [bannerDelegate adapterBannerDidClick];
}

- (void)adViewDidLoad:(nonnull SAKAdView *)adView {
    NSString *slotId = [self.bnAdToSlotId objectForKey:adView];
    LogAdapterDelegate_Internal(@"slotId = %@", slotId);
    
    // Smash delegate
    id<ISBannerAdapterDelegate> bannerDelegate = [_bnSlotIdToSmashDelegate objectForKey:slotId];
    
    if (!bannerDelegate) {
        LogAdapterApi_Internal(@"failed - null listener");
        return;
    }
    
    [bannerDelegate adapterBannerDidLoad:adView];
}

- (void)adViewDidTrackImpression:(nonnull SAKAdView *)adView {
    NSString *slotId = [self.bnAdToSlotId objectForKey:adView];
    LogAdapterDelegate_Internal(@"slotId = %@", slotId);
    
    // Smash delegate
    id<ISBannerAdapterDelegate> bannerDelegate = [_bnSlotIdToSmashDelegate objectForKey:slotId];
    
    if (!bannerDelegate) {
        LogAdapterApi_Internal(@"failed - null listener");
        return;
    }
    
    [bannerDelegate adapterBannerDidShow];
}

#pragma mark - Utils

- (BOOL)isConfigValueValid:(NSString *)value {
    // if value is not empty
    if (value && value.length > 0) {
        return YES;
    }
    
    return NO;
}

/**
 Snap Ad SDK support iOS 10 and above and AllowARbitraryLoads flag set to YES
 */
- (BOOL) isSupported {
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        [self setSupportedValues];
    });
    return osSupported && allowArbitraryLoads;
}


- (void) setSupportedValues {
    osSupported = [self isOSVersionSupported];
    allowArbitraryLoads = [self isATSSupported];
}

- (BOOL) isOSVersionSupported {
    if (SYSTEM_VERSION_GREATER_THAN_OR_EQUAL_TO(@"10.0")) {
        return true;
    }
    return false;
}

//return the allowsArbitraryLoads flag. snap adapter is supported if this method return Yes
- (BOOL)isATSSupported {
    NSDictionary *ats = [[NSBundle mainBundle] objectForInfoDictionaryKey:@"NSAppTransportSecurity"];
    BOOL allowsArbitraryLoads = NO;
    if(ats != nil) {
        id dictValue = [ats objectForKey:@"NSAllowsArbitraryLoads"];
        if(dictValue != nil) {
            allowsArbitraryLoads = [dictValue boolValue];
        }
    }
    LogInternal_Internal(@"allowsArbitraryLoads = %@", allowsArbitraryLoads ? @"Yes" : @"No");
    return allowsArbitraryLoads;
}

- (NSError*)errorForUnsupportedAdapter {
    NSString *desc = [self getErrorMsgForUnsupportedAdapter];
    return [NSError errorWithDomain:kAdapterName
                               code:kUnsupportedAdapterErrorCode
                           userInfo:@{NSLocalizedDescriptionKey : desc
                           }];
}

//change this if there is a new value for unsupported adapter
- (NSString*)getErrorMsgForUnsupportedAdapter {
    if(!osSupported) {
        return [NSString stringWithFormat:@"failed due to unsupported OS version for %@", kAdapterName];
    } else if(!allowArbitraryLoads) {
        return [NSString stringWithFormat:@"failed due to AllowsArbitraryLoads flag is set to NO for %@", kAdapterName];
    }
    return @"unsupported adapter";
}

- (NSString *)getErrorMessage:(NSInteger)erroCode {
    NSString *errorMessage = @"Unknown error code";
    
    switch (erroCode) {
        case SAKErrorNetworkError:
            errorMessage = @"Network error";
            break;
        case SAKErrorNotEligible:
            errorMessage = @"Cannot request ad due user not eligible";
            break;
        case SAKErrorFailedToParse:
            errorMessage = @"Cannot parse response from network request";
            break;
        case SAKErrorSDKNotInitialized:
            errorMessage = @"Cannot request ad due to SDK not ready";
            break;
        case SAKErrorNoAdAvailable:
            errorMessage = @"No ad returned from server";
            break;
        case SAKErrorCodeNoCreativeEndpoint:
            errorMessage = @"Cannot find creative endpoint to download ad media";
            break;
        case SAKErrorCodeMediaDownloadError:
            errorMessage = @"Media download error";
            break;
        case SAKErrorFailedToRegister:
            errorMessage = @"Failed to Register";
            break;
        case SAKErrorAdsDisabled:
            errorMessage = @"Ads are disabled";
            break;
    }
    
    return errorMessage;
}

- (void) loadRewardedVideo:(NSString*)slotId {
    LogAdapterApi_Internal(@"slotId = %@", slotId);
    
    // create configuration
    SAKAdRequestConfigurationBuilder *configurationBuilder = [[SAKAdRequestConfigurationBuilder alloc] withPublisherSlotId:slotId];
    
    // create ad
    SAKRewardedAd *rewardedVideoAd = [SAKRewardedAd new];
    rewardedVideoAd.delegate = self;
    
    // add to ad dictionary
    [self.rvSlotIdToAd setObject:rewardedVideoAd forKey:slotId];
    [self.rvAdToSlotId setObject:slotId forKey:rewardedVideoAd];
    
    dispatch_async(dispatch_get_main_queue(), ^{
        // load request
        [rewardedVideoAd loadRequest:[configurationBuilder build]];
    });
}

- (void)loadBannerInternal:(ISAdapterConfig * _Nonnull)adapterConfig
                  viewController:(UIViewController * _Nonnull)viewController
                  delegate:(id<ISBannerAdapterDelegate> _Nonnull)delegate slotId:(NSString * _Nonnull)slotId {
    
    if (![self isConfigValueValid:slotId]) {
        NSError *error = [self errorForMissingCredentialFieldWithName:kSlotId];
        LogAdapterApi_Internal(@"error = %@", error);
        [delegate adapterBannerDidFailToLoadWithError:error];
        return;
    }
    // get size
    ISBannerSize* size = [_bannerSlotIdToSize objectForKey:slotId];
    
    if([self isBannerSizeSupported:size]){ // load banner
        // create configuration
        dispatch_async(dispatch_get_main_queue(), ^{
        SAKAdRequestConfigurationBuilder *configurationBuilder = [[SAKAdRequestConfigurationBuilder alloc] withPublisherSlotId:slotId];
        
        // create ad
        SAKAdView *bannerAd = [[SAKAdView alloc] initWithFormat:[self getBannerSizeFormat:size]];
        bannerAd.frame = [self getBannerSizeRect:size];
        bannerAd.delegate = self;
        bannerAd.rootViewController = viewController;

        // add to ad dictionary
        [self.bnSlotIdToAd setObject:bannerAd forKey:slotId];
        [self.bnAdToSlotId setObject:slotId forKey:bannerAd];
        
        // load request
        [bannerAd loadRequest:[configurationBuilder build]];
        });
    } else{
        // size not supported
        NSError *error = [NSError errorWithDomain:kAdapterName code:ERROR_BN_UNSUPPORTED_SIZE
                            userInfo:@{NSLocalizedDescriptionKey:[NSString stringWithFormat:@"%@ - unsupported banner size", kAdapterName]}];
        LogAdapterApi_Internal(@"error = %@", error);
        [delegate adapterBannerDidFailToLoadWithError:error];
    }
}

- (SAKAdViewFormat)getBannerSizeFormat:(ISBannerSize *)size {

    if ([size.sizeDescription isEqualToString:@"RECTANGLE"]) {
        return SAKAdViewFormatMediumRectangle;
    }

    return SAKAdViewFormatBanner;
}

- (CGRect)getBannerSizeRect:(ISBannerSize *)size {

    CGRect bannerFrame;
    if ([size.sizeDescription isEqualToString:@"SMART"] &&
         UI_USER_INTERFACE_IDIOM() != UIUserInterfaceIdiomPad)
    {
        ISBannerSize* bannerSize = ISBannerSize_BANNER;
        bannerFrame = CGRectMake(0, 0, bannerSize.width, bannerSize.height);
    }
    else
    {
        bannerFrame = CGRectMake(0, 0, size.width, size.height);
    }
    
    return bannerFrame;
}


- (bool)isBannerSizeSupported:(ISBannerSize *)size {
    if ([size.sizeDescription isEqualToString:@"BANNER"]) {
        return true;
    }
    else if ([size.sizeDescription isEqualToString:@"RECTANGLE"]) {
        return true;
    } else if ([size.sizeDescription isEqualToString:@"SMART"]) {
        // SMART on an iphone is equal to banner which is supported.
        return (UI_USER_INTERFACE_IDIOM() != UIUserInterfaceIdiomPad);
    }
    return false;
}


@end
