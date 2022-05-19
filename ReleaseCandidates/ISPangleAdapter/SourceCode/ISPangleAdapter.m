//
//  ISPangleAdapter.m
//  ISPangleAdapter
//
//  Created by Guy Lis on 20/05/2019.
//

#import "ISPangleAdapter.h"
#import <BUAdSDK/BUAdSDK.h>

static NSString * const kAdapterName        = @"Pangle";
static NSString * const kAdapterVersion     = PangleAdapterVersion;
static NSString * const kAppID              = @"appID";
static NSString * const kSlotID             = @"slotID";
static NSString * const kIsChinaMainland    = @"isChinaMainland";
static NSString * const kCOPPAChild         = @"1";
static NSString * const kCOPPAAdult         = @"0";
static NSString * const kMetaDataCOPPAKey   = @"Pangle_COPPA";

typedef NS_ENUM(NSInteger, InitState) {
    INIT_STATE_NONE,
    INIT_STATE_IN_PROGRESS,
    INIT_STATE_FAILED,
    INIT_STATE_SUCCESS
};

static InitState _initState = INIT_STATE_NONE;
static ConcurrentMutableSet<ISNetworkInitCallbackProtocol> *initCallbackDelegates = nil;

static BOOL const kIsChinaMainlandDefaultValue = NO;

static BURewardedVideoModel *model;

@interface ISPangleAdapter () <BURewardedVideoAdDelegate, BUFullscreenVideoAdDelegate, BUNativeExpressBannerViewDelegate, ISNetworkInitCallbackProtocol>

// Rewarded video
@property (nonatomic, strong) ConcurrentMutableDictionary   *slotIdToRewardedVideoAd;
@property (nonatomic, strong) ConcurrentMutableDictionary   *slotIdToRewardedVideoDelegate;
@property (nonatomic, strong) NSMapTable                    *rewardedVideoAdToSmashDelegate;
@property (nonatomic, strong) NSMapTable                    *rewardedVideoAdToSlotId;
@property (nonatomic, strong) ConcurrentMutableDictionary   *rewardedVideoAdsAvailability;
@property (nonatomic, strong) ConcurrentMutableSet          *rewardedVideoPlacementsForInitCallbacks;

// Interstitial
@property (nonatomic, strong) ConcurrentMutableDictionary   *slotIdToInterstitialAd;
@property (nonatomic, strong) ConcurrentMutableDictionary   *slotIdToInterstitiaDelegate;
@property (nonatomic, strong) NSMapTable                    *interstitialAdToSmashDelegate;
@property (nonatomic, strong) NSMapTable                    *interstitialAdToSlotId;
@property (nonatomic, strong) ConcurrentMutableDictionary   *interstitialAdsAvailability;

// Banner
@property (nonatomic, strong) ConcurrentMutableDictionary   *slotIdToBannerAd;
@property (nonatomic, strong) ConcurrentMutableDictionary   *slotIdToBannerDelegate;
@property (nonatomic, strong) ConcurrentMutableDictionary   *slotIdToViewController;
@property (nonatomic, strong) ConcurrentMutableDictionary   *slotIdToBannerSize;
@property (nonatomic, strong) NSMapTable                    *bannerAdToSmashDelegate;
@property (nonatomic, strong) NSMapTable                    *bannerAdToSlotId;

@end

@implementation ISPangleAdapter

#pragma mark - Initializations Methods

- (instancetype)initAdapter:(NSString *)name {
    self = [super initAdapter:name];
    
    if (self) {
        if (initCallbackDelegates == nil) {
            initCallbackDelegates =  [ConcurrentMutableSet<ISNetworkInitCallbackProtocol> set];
        }
        
        // Rewarded video
        _slotIdToRewardedVideoAd                    = [ConcurrentMutableDictionary dictionary];
        _slotIdToRewardedVideoDelegate              = [ConcurrentMutableDictionary dictionary];
        _rewardedVideoAdToSmashDelegate             = [NSMapTable mapTableWithKeyOptions:NSMapTableStrongMemory valueOptions:NSMapTableWeakMemory];
        _rewardedVideoAdToSlotId                    = [NSMapTable mapTableWithKeyOptions:NSMapTableStrongMemory valueOptions:NSMapTableWeakMemory];
        _rewardedVideoAdsAvailability               = [ConcurrentMutableDictionary dictionary];
        _rewardedVideoPlacementsForInitCallbacks    = [[ConcurrentMutableSet alloc] init];
        
        // Interstitial
        _slotIdToInterstitialAd                     = [ConcurrentMutableDictionary dictionary];
        _slotIdToInterstitiaDelegate                = [ConcurrentMutableDictionary dictionary];
        _interstitialAdToSmashDelegate              = [NSMapTable mapTableWithKeyOptions:NSMapTableStrongMemory valueOptions:NSMapTableWeakMemory];
        _interstitialAdToSlotId                     = [NSMapTable mapTableWithKeyOptions:NSMapTableStrongMemory valueOptions:NSMapTableWeakMemory];
        _interstitialAdsAvailability                = [ConcurrentMutableDictionary dictionary];

        // Banner
        _slotIdToBannerAd                           = [ConcurrentMutableDictionary dictionary];
        _slotIdToBannerDelegate                     = [ConcurrentMutableDictionary dictionary];
        _slotIdToBannerSize                         = [ConcurrentMutableDictionary dictionary];
        _slotIdToViewController                     = [ConcurrentMutableDictionary dictionary];
        _bannerAdToSmashDelegate                    = [NSMapTable mapTableWithKeyOptions:NSMapTableStrongMemory valueOptions:NSMapTableWeakMemory];
        _bannerAdToSlotId                           = [NSMapTable mapTableWithKeyOptions:NSMapTableStrongMemory valueOptions:NSMapTableWeakMemory];
        
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
    return [BUAdSDKManager SDKVersion];
}

- (NSArray *)systemFrameworks {
    return @[@"Accelerate", @"AdSupport", @"AudioToolbox", @"AVFoundation", @"CoreGraphics", @"CoreImage", @"CoreLocation", @"CoreMedia", @"CoreMotion", @"CoreTelephony", @"CoreText", @"ImageIO", @"JavaScriptCore", @"MediaPlayer", @"MapKit", @"MobileCoreServices", @"QuartzCore", @"Security", @"StoreKit", @"SystemConfiguration", @"UIKit", @"WebKit"];
}

- (NSString *)sdkName {
    return @"BURewardedVideoAd";
}

- (void)setConsent:(BOOL)consent {
	//Bug fix - if the user grants consent, you should set gdpr=0 for pangle. 
    int value = consent ? 0 : 1;
    LogAdapterApi_Internal(@"consent = %@", consent ? @"YES" : @"NO");
    [BUAdSDKManager setGDPR: value];
}

- (void) setCOPPAValue:(NSInteger)value {
    LogInternal_Internal(@"value = %@", value == 1 ? @"Child" : @"Adult");
    [BUAdSDKManager setCoppa:value];
}

- (void)setMetaDataWithKey:(NSString *)key andValues:(NSMutableArray *) values {
    if(values.count == 0) return;
    NSString *value = values[0];
    LogAdapterApi_Internal(@"key = %@, value = %@", key, value);
    
    if ([self isValidCOPPAMetaDataWithKey:key andValue:value]) {
        [self setCOPPAValue:value.integerValue];
    }
}

/**
 This method checks if the Meta Data key is the COPPA key and the value is valid
 
 @param key The Meta Data key
 @param value The Meta Data value
 */
- (BOOL) isValidCOPPAMetaDataWithKey:(NSString *)key andValue:(NSString *)value {
    LogInternal_Internal(@"key = %@, value = %@", key, value);
    return ([key caseInsensitiveCompare:kMetaDataCOPPAKey] == NSOrderedSame && ([value isEqualToString:kCOPPAChild] || [value isEqualToString:kCOPPAAdult]));
}

#pragma mark - Rewarded Video

- (NSDictionary *)getRewardedVideoBiddingDataWithAdapterConfig:(ISAdapterConfig *)adapterConfig {
    LogAdapterApi_Internal(@"");
    NSString *slotID = adapterConfig.settings[kSlotID];
    return [self getBiddingDataWithSlotID:slotID];
}

- (void)initRewardedVideoForCallbacksWithUserId:(NSString *)userId
                                  adapterConfig:(ISAdapterConfig *)adapterConfig
                                       delegate:(id<ISRewardedVideoAdapterDelegate>)delegate {

    LogAdapterApi_Internal(@"");
    
    [self.dispatcher dispatchAsyncWithQueue:dispatch_get_main_queue() withBlock:^{
        
        NSString *appID = adapterConfig.settings[kAppID];
        NSString *slotID = adapterConfig.settings[kSlotID];
        BOOL isChinaMainland = [self isChinaMainland:adapterConfig];

        // validating configuration
        if (![self isConfigValueValid:appID]) {
            NSError *error = [self errorForMissingCredentialFieldWithName:kAppID];
            LogAdapterApi_Internal(@"error = %@", error);
            [delegate adapterRewardedVideoInitFailed:error];
            return;
        }
        
        if (![self isConfigValueValid:slotID]) {
            NSError *error = [self errorForMissingCredentialFieldWithName:kSlotID];
            LogAdapterApi_Internal(@"error = %@", error);
            [delegate adapterRewardedVideoInitFailed:error];
            return;
        }
        
        LogAdapterApi_Internal(@"slotID = %@", slotID);
        LogAdapterApi_Internal(@"userId = %@", userId);
        LogAdapterApi_Internal(@"isChinaMainland = %@", isChinaMainland ? @"YES" : @"NO");

        // add delegate to dictionary
        [self.slotIdToRewardedVideoDelegate setObject:delegate forKey:slotID];
        [self.rewardedVideoPlacementsForInitCallbacks addObject:slotID];

        switch (_initState) {
            case INIT_STATE_NONE:
            case INIT_STATE_IN_PROGRESS:
                [self initSDKWithAppID:appID userId:userId isChinaMainland:isChinaMainland];
                break;
            case INIT_STATE_FAILED:
                [delegate adapterRewardedVideoInitFailed:[NSError errorWithDomain:kAdapterName code:ERROR_CODE_INIT_FAILED userInfo:@{NSLocalizedDescriptionKey:@"Pangle SDK init failed"}]];
                break;
            case INIT_STATE_SUCCESS:
                [delegate adapterRewardedVideoInitSuccess];
                break;
        }
    }];
}

- (void)initAndLoadRewardedVideoWithUserId:(NSString *)userId
                             adapterConfig:(ISAdapterConfig *)adapterConfig
                                  delegate:(id<ISRewardedVideoAdapterDelegate>)delegate {
    LogAdapterApi_Internal(@"");
    
    [self.dispatcher dispatchAsyncWithQueue:dispatch_get_main_queue() withBlock:^{
        
        NSString *appID = adapterConfig.settings[kAppID];
        NSString *slotID = adapterConfig.settings[kSlotID];
        BOOL isChinaMainland = [self isChinaMainland:adapterConfig];

        // validating configuration
        if (![self isConfigValueValid:appID]) {
            NSError *error = [self errorForMissingCredentialFieldWithName:kAppID];
            LogAdapterApi_Internal(@"error = %@", error);
            [delegate adapterRewardedVideoHasChangedAvailability:NO];
            return;
        }
        
        if (![self isConfigValueValid:slotID]) {
            NSError *error = [self errorForMissingCredentialFieldWithName:kSlotID];
            LogAdapterApi_Internal(@"error = %@", error);
            [delegate adapterRewardedVideoHasChangedAvailability:NO];
            return;
        }

        LogAdapterApi_Internal(@"slotID = %@", slotID);
        LogAdapterApi_Internal(@"userId = %@", userId);
        LogAdapterApi_Internal(@"isChinaMainland = %@", isChinaMainland ? @"YES" : @"NO");

        // add delegate to dictionary
        [self.slotIdToRewardedVideoDelegate setObject:delegate forKey:slotID];

        switch (_initState) {
            case INIT_STATE_NONE:
            case INIT_STATE_IN_PROGRESS:
                [self initSDKWithAppID:appID userId:userId isChinaMainland:isChinaMainland];
                break;
            case INIT_STATE_FAILED:
                [delegate adapterRewardedVideoHasChangedAvailability:NO];
                break;
            case INIT_STATE_SUCCESS:
                [self fetchRewardedVideoForAutomaticLoadWithAdapterConfig:adapterConfig delegate:delegate];
                break;
        }
    }];
}

- (void)loadRewardedVideoForBiddingWithAdapterConfig:(ISAdapterConfig *)adapterConfig serverData:(NSString *)serverData delegate:(id<ISRewardedVideoAdapterDelegate>)delegate {
    NSString *slotID = adapterConfig.settings[kSlotID];
    
    // validating configuration
    if (![self isConfigValueValid:slotID]) {
        NSError *error = [self errorForMissingCredentialFieldWithName:kSlotID];
        LogAdapterApi_Internal(@"error = %@", error);
        [delegate adapterRewardedVideoDidFailToLoadWithError:error];
        return;
    }
    
    LogAdapterApi_Internal(@"slotID = %@", slotID);
    [self loadRewardVideoWithSlotID:slotID isBidder:YES serverData:serverData delegate:delegate];
}

- (void)fetchRewardedVideoForAutomaticLoadWithAdapterConfig:(ISAdapterConfig *)adapterConfig delegate:(id<ISRewardedVideoAdapterDelegate>)delegate {
    NSString *slotID = adapterConfig.settings[kSlotID];
    
    // validating configuration
    if (![self isConfigValueValid:slotID]) {
        NSError *error = [self errorForMissingCredentialFieldWithName:kSlotID];
        LogAdapterApi_Internal(@"error = %@", error);
        [delegate adapterRewardedVideoHasChangedAvailability:NO];
        return;
    }
    
    LogAdapterApi_Internal(@"slotID = %@", slotID);
    [self loadRewardVideoWithSlotID:slotID isBidder:NO serverData:Nil delegate:delegate];
}

- (void) loadRewardVideoWithSlotID:(NSString *)slotID isBidder:(BOOL)isBidder serverData:(NSString *)serverData delegate:(id<ISRewardedVideoAdapterDelegate>)delegate {
    [self.dispatcher dispatchAsyncWithQueue:dispatch_get_main_queue() withBlock:^{
        
        BURewardedVideoAd *rewardedVideoAd = [[BURewardedVideoAd alloc] initWithSlotID:slotID rewardedVideoModel:model];
        [self.slotIdToRewardedVideoAd setObject:rewardedVideoAd forKey:slotID];
        [self.rewardedVideoAdToSmashDelegate setObject:delegate forKey:rewardedVideoAd];
        [self.rewardedVideoAdToSlotId setObject:slotID forKey:rewardedVideoAd];
        rewardedVideoAd.delegate = self;
        
        // set availability false for this ad
        [self.rewardedVideoAdsAvailability setObject:@NO forKey:slotID];
        
        if (isBidder) {
            LogAdapterApi_Internal(@"setAdMarkUp");
            [rewardedVideoAd setMopubAdMarkUp:serverData];
        }
        else {
            LogAdapterApi_Internal(@"loadAdData");
            [rewardedVideoAd loadAdData];
        }
    }];
}


- (void)showRewardedVideoWithViewController:(UIViewController *)viewController adapterConfig:(ISAdapterConfig *)adapterConfig delegate:(id<ISRewardedVideoAdapterDelegate>)delegate {
    [self.dispatcher dispatchAsyncWithQueue:dispatch_get_main_queue() withBlock:^{
        
        NSString *slotID = adapterConfig.settings[kSlotID];
        LogAdapterApi_Internal(@"slotID = %@", slotID);
        
        // validating availability
        BURewardedVideoAd *rewardedVideoAd = [self.slotIdToRewardedVideoAd objectForKey:slotID];
        
        BOOL isAvailable = [self isAdAvailableWithSlotId:slotID adsAvailability:self.rewardedVideoAdsAvailability];
        
        // set availability false for this ad
        [self.rewardedVideoAdsAvailability setObject:@NO forKey:slotID];
        
        if (rewardedVideoAd != nil && isAvailable) {
            LogAdapterApi_Internal(@"showAdFromRootViewController");
            [rewardedVideoAd showAdFromRootViewController:viewController];
        }
        else {
            NSError *error = [ISError errorWithDomain:kAdapterName code:ERROR_CODE_NO_ADS_TO_SHOW userInfo:@{NSLocalizedDescriptionKey:@"RewardedVideoDidFailToShow"}];
            LogAdapterApi_Internal(@"failed - rewardedVideoAd not valid");
            [delegate adapterRewardedVideoDidFailToShowWithError:error];
        }
        
        [delegate adapterRewardedVideoHasChangedAvailability:NO];
    }];
}

- (BOOL)hasRewardedVideoWithAdapterConfig:(ISAdapterConfig *)adapterConfig {
    NSString *slotID = adapterConfig.settings[kSlotID];
    BOOL isAvailable = [self isAdAvailableWithSlotId:slotID adsAvailability:self.rewardedVideoAdsAvailability];
    LogAdapterApi_Internal(@"SlotID = %@ isAvailable = %@",slotID, isAvailable ? @"Yes" : @"No");
    return isAvailable;
}


#pragma mark - Interstitial

//Get bidding token
- (NSDictionary *)getInterstitialBiddingDataWithAdapterConfig:(ISAdapterConfig *)adapterConfig {
    LogAdapterApi_Internal(@"");
    NSString *slotID = adapterConfig.settings[kSlotID];
    return [self getBiddingDataWithSlotID:slotID];
}

//Init interstitial for bidding
- (void)initInterstitialForBiddingWithUserId:(NSString *)userId adapterConfig:(ISAdapterConfig *)adapterConfig delegate:(id<ISInterstitialAdapterDelegate>)delegate {
    LogAdapterApi_Internal(@"");
    [self initInterstitialInternalWithUserId:userId adapterConfig:adapterConfig delegate:delegate];
}

//Init interstitial for traditional
- (void)initInterstitialWithUserId:(NSString *)userId adapterConfig:(ISAdapterConfig *)adapterConfig delegate:(id<ISInterstitialAdapterDelegate>)delegate {
    LogAdapterApi_Internal(@"");
    [self initInterstitialInternalWithUserId:userId adapterConfig:adapterConfig delegate:delegate];
}

- (void)initInterstitialInternalWithUserId:(NSString *)userId adapterConfig:(ISAdapterConfig *)adapterConfig delegate:(id<ISInterstitialAdapterDelegate>)delegate {
    [self.dispatcher dispatchAsyncWithQueue:dispatch_get_main_queue() withBlock:^{
        
        NSString *appID = adapterConfig.settings[kAppID];
        NSString *slotID = adapterConfig.settings[kSlotID];
        BOOL isChinaMainland = [self isChinaMainland:adapterConfig];

        // validating configuration
        if (![self isConfigValueValid:appID]) {
            NSError *error = [self errorForMissingCredentialFieldWithName:kAppID];
            LogAdapterApi_Internal(@"error = %@", error);
            [delegate adapterInterstitialInitFailedWithError:error];
            return;
        }
        
        if (![self isConfigValueValid:slotID]) {
            NSError *error = [self errorForMissingCredentialFieldWithName:kSlotID];
            LogAdapterApi_Internal(@"error = %@", error);
            [delegate adapterInterstitialInitFailedWithError:error];
            return;
        }
        
        LogAdapterApi_Internal(@"slotID = %@", slotID);
        LogAdapterApi_Internal(@"userId = %@", userId);
        LogAdapterApi_Internal(@"isChinaMainland = %@", isChinaMainland ? @"YES" : @"NO");

        // add delegate to dictionary
        [self.slotIdToInterstitiaDelegate setObject:delegate forKey:slotID];

        switch (_initState) {
            case INIT_STATE_NONE:
            case INIT_STATE_IN_PROGRESS:
                [self initSDKWithAppID:appID userId:userId isChinaMainland:isChinaMainland];
                break;
            case INIT_STATE_FAILED:
                [delegate adapterInterstitialInitFailedWithError:[NSError errorWithDomain:kAdapterName code:ERROR_CODE_INIT_FAILED userInfo:@{NSLocalizedDescriptionKey:@"Pangle SDK init failed"}]];
                break;
            case INIT_STATE_SUCCESS:
                [delegate adapterInterstitialInitSuccess];
                break;
        }
    }];
}


//Load interstitial for bidding
- (void)loadInterstitialForBiddingWithServerData:(NSString *)serverData adapterConfig:(ISAdapterConfig *)adapterConfig delegate:(id<ISInterstitialAdapterDelegate>)delegate {
    LogAdapterApi_Internal(@"slotID = %@", adapterConfig.settings[kSlotID]);
    [self loadInterstitialInternal:adapterConfig delegate:delegate serverData:serverData];
}

//Load interstitial for traditional
- (void)loadInterstitialWithAdapterConfig:(ISAdapterConfig *)adapterConfig delegate:(id<ISInterstitialAdapterDelegate>)delegate {
    LogAdapterApi_Internal(@"slotID = %@", adapterConfig.settings[kSlotID]);
    [self loadInterstitialInternal:adapterConfig delegate:delegate serverData:nil];
}

- (void)loadInterstitialInternal:(ISAdapterConfig *)adapterConfig delegate:(id<ISInterstitialAdapterDelegate>)delegate serverData:(NSString *)serverData {
    
    NSString *slotID = adapterConfig.settings[kSlotID];
    
    [self.dispatcher dispatchAsyncWithQueue:dispatch_get_main_queue() withBlock:^{
        BUFullscreenVideoAd *fullscreenVideoAd = [[BUFullscreenVideoAd alloc] initWithSlotID:slotID];
        [self.slotIdToInterstitialAd setObject:fullscreenVideoAd forKey:slotID];
        [self.interstitialAdToSmashDelegate setObject:delegate forKey:fullscreenVideoAd];
        [self.interstitialAdToSlotId setObject:slotID forKey:fullscreenVideoAd];
        // set availability false for this ad
        [self.interstitialAdsAvailability setObject:@NO forKey:slotID];
        fullscreenVideoAd.delegate = self;
        
        if (adapterConfig.isBidder) {
            LogAdapterApi_Internal(@"setAdMarkUp");
            [fullscreenVideoAd setMopubAdMarkUp:serverData];
        }
        else {
            LogAdapterApi_Internal(@"loadAdData");
            [fullscreenVideoAd loadAdData];
        }
    }];
}

//Show interstitial
- (void)showInterstitialWithViewController:(UIViewController *)viewController adapterConfig:(ISAdapterConfig *)adapterConfig delegate:(id<ISInterstitialAdapterDelegate>)delegate {
    [self.dispatcher dispatchAsyncWithQueue:dispatch_get_main_queue() withBlock:^{
        NSString *slotID = adapterConfig.settings[kSlotID];
        LogAdapterApi_Internal(@"slotID = %@", slotID);
        
        // check availability
        BUFullscreenVideoAd *fullscreenVideoAd = [self.slotIdToInterstitialAd objectForKey:slotID];
        
        BOOL isAvailable = [self isAdAvailableWithSlotId:slotID adsAvailability:self.interstitialAdsAvailability];
        
        // set availability false for this ad
        [self.interstitialAdsAvailability setObject:@NO forKey:slotID];
        
        if (fullscreenVideoAd == nil || !isAvailable) {
            NSError *error = [ISError errorWithDomain:kAdapterName code:ERROR_CODE_NO_ADS_TO_SHOW userInfo:@{NSLocalizedDescriptionKey:@"didFailToShowInterstitial"}];
            LogAdapterApi_Internal(@"error = %@", error);
            [delegate adapterInterstitialDidFailToShowWithError:error];
            return;
        }
        
        [fullscreenVideoAd showAdFromRootViewController:viewController];
    }];
}

- (BOOL)hasInterstitialWithAdapterConfig:(ISAdapterConfig *)adapterConfig {
    NSString *slotID = adapterConfig.settings[kSlotID];
    BOOL isAvailable = [self isAdAvailableWithSlotId:slotID adsAvailability:self.interstitialAdsAvailability];
    LogAdapterApi_Internal(@"SlotID = %@ isAvailable = %@",slotID, isAvailable ? @"Yes" : @"No");
    return isAvailable;
}

#pragma mark - Banner
- (NSDictionary *)getBannerBiddingDataWithAdapterConfig:(ISAdapterConfig *)adapterConfig {
    LogAdapterApi_Internal(@"");
    NSString *slotID = adapterConfig.settings[kSlotID];
    return [self getBiddingDataWithSlotID:slotID];
}

- (void)initBannerWithUserId:(NSString *)userId adapterConfig:(ISAdapterConfig *)adapterConfig delegate:(id<ISBannerAdapterDelegate>)delegate {
    LogAdapterApi_Internal(@"");
    [self initBannerInternal:userId adapterConfig:adapterConfig delegate:delegate];
}

- (void)initBannerForBiddingWithUserId:(NSString *)userId adapterConfig:(ISAdapterConfig *)adapterConfig delegate:(id<ISBannerAdapterDelegate>)delegate {
    LogAdapterApi_Internal(@"");
    [self initBannerInternal:userId adapterConfig:adapterConfig delegate:delegate];
}

- (void) initBannerInternal:(NSString *)userId adapterConfig:(ISAdapterConfig *)adapterConfig delegate:(id<ISBannerAdapterDelegate>)delegate {
    NSString *appID = adapterConfig.settings[kAppID];
    NSString *slotID = adapterConfig.settings[kSlotID];
    BOOL isChinaMainland = [self isChinaMainland:adapterConfig];

    // validating configuration
    if (![self isConfigValueValid:appID]) {
        NSError *error = [self errorForMissingCredentialFieldWithName:kAppID];
        LogAdapterApi_Error(@"error = %@", error);
        [delegate adapterBannerInitFailedWithError:error];
        return;
    }
    
    if (![self isConfigValueValid:slotID]) {
        NSError *error = [self errorForMissingCredentialFieldWithName:kSlotID];
        LogAdapterApi_Error(@"error = %@", error);
        [delegate adapterBannerInitFailedWithError:error];
        return;
    }
    
    LogAdapterApi_Internal(@"slotID = %@", slotID);
    LogAdapterApi_Internal(@"userId = %@", userId);
    LogAdapterApi_Internal(@"isChinaMainland = %@", isChinaMainland ? @"YES" : @"NO");

    // add delegate to dictionary
    [self.slotIdToBannerDelegate setObject:delegate forKey:slotID];

    switch (_initState) {
        case INIT_STATE_NONE:
        case INIT_STATE_IN_PROGRESS: {
            [self.dispatcher dispatchAsyncWithQueue:dispatch_get_main_queue() withBlock:^{
                [self initSDKWithAppID:appID userId:userId isChinaMainland:isChinaMainland];
            }];
            break;
        }
        case INIT_STATE_FAILED:
            [delegate adapterBannerInitFailedWithError:[NSError errorWithDomain:kAdapterName code:ERROR_CODE_INIT_FAILED userInfo:@{NSLocalizedDescriptionKey:@"Pangle SDK init failed"}]];
            break;
        case INIT_STATE_SUCCESS:
            [delegate adapterBannerInitSuccess];
            break;
    }
}

- (void)loadBannerWithViewController:(UIViewController *)viewController size:(ISBannerSize *)size adapterConfig:(ISAdapterConfig *)adapterConfig delegate:(id<ISBannerAdapterDelegate>)delegate {
    LogAdapterApi_Internal(@"");
    [self loadBannerInternal:NO serverData:nil viewController:viewController size:size adapterConfig:adapterConfig delegate:delegate];
}

- (void)loadBannerForBiddingWithServerData:(NSString *)serverData viewController:(UIViewController *)viewController size:(ISBannerSize *)size adapterConfig:(ISAdapterConfig *)adapterConfig delegate:(id<ISBannerAdapterDelegate>)delegate {
    LogAdapterApi_Internal(@"");
    [self loadBannerInternal:YES serverData:serverData viewController:viewController size:size adapterConfig:adapterConfig delegate:delegate];
}

- (void)loadBannerInternal:(BOOL)isBidder serverData:(NSString *)serverData viewController:(UIViewController *)viewController size:(ISBannerSize *)size adapterConfig:(ISAdapterConfig *)adapterConfig delegate:(id<ISBannerAdapterDelegate>)delegate {
    [self.dispatcher dispatchAsyncWithQueue:dispatch_get_main_queue() withBlock:^{
        NSString *slotID = adapterConfig.settings[kSlotID];
        
        // placement
        if (![self isConfigValueValid:slotID]) {
            NSError *error = [self errorForMissingCredentialFieldWithName:kSlotID];
            LogAdapterApi_Error(@"error = %@", error);
            [delegate adapterBannerDidFailToLoadWithError:error];
            return;
        }
        
        // verify size
        if (![self isBannerSizeSupported:size]) {
            NSError *error = [ISError errorWithDomain:kAdapterName code:ERROR_BN_UNSUPPORTED_SIZE userInfo:@{NSLocalizedDescriptionKey:[NSString stringWithFormat:@"unsupported banner size - %@", size.sizeDescription]}];
            LogAdapterApi_Error(@"error = %@", error);
            [delegate adapterBannerDidFailToLoadWithError:error];
            return;
        }
        
        LogAdapterApi_Internal(@"slotID = %@", slotID);
        LogAdapterApi_Internal(@"size = %@", size.sizeDescription);
        
        // creat Pangle banner
        CGSize bannerSize = [self getBannerSize:size];
        BUNativeExpressBannerView *expressBannerView  = [[BUNativeExpressBannerView alloc] initWithSlotID:slotID rootViewController:viewController adSize:bannerSize];
        expressBannerView.delegate = self;
        expressBannerView.frame = CGRectMake(0, 0, bannerSize.width, bannerSize.height);
        
        [self.slotIdToViewController setObject:viewController forKey:slotID];
        [self.slotIdToBannerSize setObject:size forKey:slotID];
        [self.slotIdToBannerAd setObject:expressBannerView forKey:slotID];
        [self.bannerAdToSmashDelegate setObject:delegate forKey:expressBannerView];
        [self.bannerAdToSlotId setObject:slotID forKey:expressBannerView];
        
        if (isBidder) {
            [expressBannerView setMopubAdMarkUp:serverData];
        } else {
            [expressBannerView loadAdData];
        }
    }];
}

- (void)reloadBannerWithAdapterConfig:(ISAdapterConfig *)adapterConfig delegate:(id<ISBannerAdapterDelegate>)delegate {
    LogAdapterApi_Internal(@"");
    NSString *slotID = adapterConfig.settings[kSlotID];
    
    // get size
    ISBannerSize *size = [self.slotIdToBannerSize objectForKey:slotID];

    // get vc
    UIViewController *viewController = [self.slotIdToViewController objectForKey:slotID];
    
    if (size && viewController) {
        // call load
        [self loadBannerInternal:NO serverData:nil viewController:viewController size:size adapterConfig:adapterConfig delegate:delegate];
    } else {
        NSError *error = [ISError errorWithDomain:kAdapterName code:ERROR_BN_LOAD_EXCEPTION userInfo:@{NSLocalizedDescriptionKey:[NSString stringWithFormat:@"Reload failed - no data for slotID = %@", slotID]}];
        LogAdapterApi_Internal(@"error = %@", error);
        [delegate adapterBannerDidFailToLoadWithError:error];
    }
}

- (void)destroyBannerWithAdapterConfig:(ISAdapterConfig *)adapterConfig {
    LogAdapterApi_Internal(@"");
    // slot id
    NSString *slotID = adapterConfig.settings[kSlotID];

    [self.slotIdToBannerAd removeObjectForKey:slotID];
    [self.slotIdToBannerSize removeObjectForKey:slotID];
    [self.slotIdToViewController removeObjectForKey:slotID];
    [self.bannerAdToSmashDelegate removeObjectForKey:slotID];
}

- (BOOL)shouldBindBannerViewOnReload {
    return YES;
}

#pragma mark - Rewarded Video Delegate

/**
 This method is called when video ad material loaded successfully.
 */
- (void)rewardedVideoAdDidLoad:(BURewardedVideoAd *)rewardedVideoAd {
    NSString *slotID = [self.rewardedVideoAdToSlotId objectForKey:rewardedVideoAd];
    LogAdapterDelegate_Internal(@"slotID = %@", slotID);
    id<ISRewardedVideoAdapterDelegate> delegate = [self.rewardedVideoAdToSmashDelegate objectForKey:rewardedVideoAd];
    
    // set availability true for this ad
    [self.rewardedVideoAdsAvailability setObject:@YES forKey:slotID];
    
    if (delegate) {
        [delegate adapterRewardedVideoHasChangedAvailability:YES];
    }
}

/**
 This method is called when video ad materia failed to load.
 @param error : the reason of error
 */
- (void)rewardedVideoAd:(BURewardedVideoAd *)rewardedVideoAd didFailWithError:(NSError *)error {
    NSString *slotID = [self.rewardedVideoAdToSlotId objectForKey:rewardedVideoAd];
    LogAdapterDelegate_Internal(@"slotID = %@", slotID);
    id<ISRewardedVideoAdapterDelegate> delegate = [self.rewardedVideoAdToSmashDelegate objectForKey:rewardedVideoAd];
    
    // set availability false for this ad
    [self.rewardedVideoAdsAvailability setObject:@NO forKey:slotID];
    
    if (delegate) {
        [delegate adapterRewardedVideoHasChangedAvailability:NO];
        
        if (error) {
            LogAdapterDelegate_Internal(@"error = %@", error);
            NSInteger errorCode = error.code == BUErrorCodeNOAD? ERROR_RV_LOAD_NO_FILL : error.code;
            [delegate adapterRewardedVideoDidFailToLoadWithError: [NSError errorWithDomain:kAdapterName code:errorCode userInfo:@{NSLocalizedDescriptionKey : error.description}]];
        }
    }
}

/**
 This method is called when cached successfully.
 */
- (void)rewardedVideoAdVideoDidLoad:(BURewardedVideoAd *)rewardedVideoAd {
    NSString *slotID = [self.rewardedVideoAdToSlotId objectForKey:rewardedVideoAd];
    LogAdapterDelegate_Internal(@"slotID = %@", slotID);
}

/**
 This method is called when video ad slot has been shown.
 */
- (void)rewardedVideoAdDidVisible:(BURewardedVideoAd *)rewardedVideoAd {
    NSString *slotID = [self.rewardedVideoAdToSlotId objectForKey:rewardedVideoAd];
    LogAdapterDelegate_Internal(@"slotID = %@", slotID);
    id<ISRewardedVideoAdapterDelegate> delegate = [self.rewardedVideoAdToSmashDelegate objectForKey:rewardedVideoAd];
    
    if (delegate) {
        [delegate adapterRewardedVideoDidOpen];
        [delegate adapterRewardedVideoDidStart];
    }
}

/**
 This method is called when video ad is closed.
 */
- (void)rewardedVideoAdDidClose:(BURewardedVideoAd *)rewardedVideoAd {
    NSString *slotID = [self.rewardedVideoAdToSlotId objectForKey:rewardedVideoAd];
    LogAdapterDelegate_Internal(@"slotID = %@", slotID);
    id<ISRewardedVideoAdapterDelegate> delegate = [self.rewardedVideoAdToSmashDelegate objectForKey:rewardedVideoAd];
    
    if (delegate) {
        [delegate adapterRewardedVideoDidClose];
    }
}

/**
 This method is called when video ad is clicked.
 */
- (void)rewardedVideoAdDidClick:(BURewardedVideoAd *)rewardedVideoAd {
    NSString *slotID = [self.rewardedVideoAdToSlotId objectForKey:rewardedVideoAd];
    LogAdapterDelegate_Internal(@"slotID = %@", slotID);
    id<ISRewardedVideoAdapterDelegate> delegate = [self.rewardedVideoAdToSmashDelegate objectForKey:rewardedVideoAd];
    
    if (delegate) {
        [delegate adapterRewardedVideoDidClick];
    }
}

/**
 This method is called when video ad play completed or an error occurred.
 @param error : the reason of error
 */
- (void)rewardedVideoAdDidPlayFinish:(BURewardedVideoAd *)rewardedVideoAd didFailWithError:(NSError *_Nullable)error {
    NSString *slotID = [self.rewardedVideoAdToSlotId objectForKey:rewardedVideoAd];
    LogAdapterDelegate_Internal(@"slotID = %@", slotID);
    id<ISRewardedVideoAdapterDelegate> delegate = [self.rewardedVideoAdToSmashDelegate objectForKey:rewardedVideoAd];
    
    if (delegate) {
        if (error) {
            LogAdapterDelegate_Internal(@"error = %@", error);
            [delegate adapterRewardedVideoDidFailToShowWithError:error];
        }
        else {
            [delegate adapterRewardedVideoDidEnd];
        }
    }
}

/**
 Server verification which is requested asynchronously is succeeded.
 @param verify :return YES when return value is 2000.
 */
- (void)rewardedVideoAdServerRewardDidSucceed:(BURewardedVideoAd *)rewardedVideoAd verify:(BOOL)verify {
    NSString *slotID = [self.rewardedVideoAdToSlotId objectForKey:rewardedVideoAd];
    LogAdapterDelegate_Internal(@"slotID = %@", slotID);
    LogAdapterDelegate_Internal(@"verify = %@", verify ? @"YES" : @"NO");
    
    if (verify) {
        id<ISRewardedVideoAdapterDelegate> delegate = [self.rewardedVideoAdToSmashDelegate objectForKey:rewardedVideoAd];
        
        if (delegate) {
            [delegate adapterRewardedVideoDidReceiveReward];
        }
    }
}

/**
 Server verification which is requested asynchronously is failed.
 Return value is not 2000.
 */
- (void)rewardedVideoAdServerRewardDidFail:(BURewardedVideoAd *)rewardedVideoAd error:(NSError *)error {
    NSString *slotID = [self.rewardedVideoAdToSlotId objectForKey:rewardedVideoAd];
    LogAdapterDelegate_Internal(@"slotID = %@", slotID);
    
    if (error) {
        LogAdapterDelegate_Internal(@"error = %@", error);
    }
}

/**
 This method is called when the user clicked skip button.
 */
- (void)rewardedVideoAdDidClickSkip:(BURewardedVideoAd *)rewardedVideoAd {
    NSString *slotID = [self.rewardedVideoAdToSlotId objectForKey:rewardedVideoAd];
    LogAdapterDelegate_Internal(@"slotID = %@", slotID);
}

#pragma mark - Interstitial Delegate

/**
 This method is called when video ad materia failed to load.
 @param error : the reason of error
 */
- (void)fullscreenVideoAd:(BUFullscreenVideoAd *)fullscreenVideoAd didFailWithError:(NSError *)error {
    NSString *slotID = [self.interstitialAdToSlotId objectForKey:fullscreenVideoAd];
    LogAdapterDelegate_Internal(@"slotID = %@", slotID);
    id<ISInterstitialAdapterDelegate> delegate = [self.interstitialAdToSmashDelegate objectForKey:fullscreenVideoAd];
    
    // set availability false for this ad
    [self.interstitialAdsAvailability setObject:@NO forKey:slotID];
    
    if (delegate) {
        NSInteger errorCode;
        NSString *errorReason;
        
        if (error) {
            LogAdapterDelegate_Internal(@"error = %@", error);
            errorCode = error.code == BUErrorCodeNOAD? ERROR_IS_LOAD_NO_FILL : error.code;
            errorReason = error.description;
        }
        else {
            errorCode = ERROR_CODE_GENERIC;
            errorReason = [NSString stringWithFormat:@"%@ interstitial load failed for slotID %@", kAdapterName, slotID];
        }
        
        [delegate adapterInterstitialDidFailToLoadWithError:[NSError errorWithDomain:kAdapterName code:errorCode userInfo:@{NSLocalizedDescriptionKey :errorReason}]];
    }
}

/**
 This method is called when video ad material loaded successfully.
 */
- (void)fullscreenVideoMaterialMetaAdDidLoad:(BUFullscreenVideoAd *)fullscreenVideoAd {
    NSString *slotID = [self.interstitialAdToSlotId objectForKey:fullscreenVideoAd];
    LogAdapterDelegate_Internal(@"slotID = %@", slotID);
    id<ISInterstitialAdapterDelegate> delegate = [self.interstitialAdToSmashDelegate objectForKey:fullscreenVideoAd];
    // set availability true for this ad
    [self.interstitialAdsAvailability setObject:@YES forKey:slotID];
    if (delegate) {
        [delegate adapterInterstitialDidLoad];
    }
}

/**
 This method is called when video cached successfully.
 */
- (void)fullscreenVideoAdVideoDataDidLoad:(BUFullscreenVideoAd *)fullscreenVideoAd {
    NSString *slotID = [self.interstitialAdToSlotId objectForKey:fullscreenVideoAd];
    LogAdapterDelegate_Internal(@"slotID = %@", slotID);
}

/**
 This method is called when video ad slot has been shown.
 */
- (void)fullscreenVideoAdDidVisible:(BUFullscreenVideoAd *)fullscreenVideoAd {
    NSString *slotID = [self.interstitialAdToSlotId objectForKey:fullscreenVideoAd];
    LogAdapterDelegate_Internal(@"slotID = %@", slotID);
    id<ISInterstitialAdapterDelegate> delegate = [self.interstitialAdToSmashDelegate objectForKey:fullscreenVideoAd];
    
    if (delegate) {
        [delegate adapterInterstitialDidOpen];
        [delegate adapterInterstitialDidShow];
    }
}

/**
 This method is called when video ad is clicked.
 */
- (void)fullscreenVideoAdDidClick:(BUFullscreenVideoAd *)fullscreenVideoAd {
    NSString *slotID = [self.interstitialAdToSlotId objectForKey:fullscreenVideoAd];
    LogAdapterDelegate_Internal(@"slotID = %@", slotID);
    id<ISInterstitialAdapterDelegate> delegate = [self.interstitialAdToSmashDelegate objectForKey:fullscreenVideoAd];
    
    if (delegate) {
        [delegate adapterInterstitialDidClick];
    }
}

/**
 This method is called when video ad is closed.
 */
- (void)fullscreenVideoAdDidClose:(BUFullscreenVideoAd *)fullscreenVideoAd {
    NSString *slotID = [self.interstitialAdToSlotId objectForKey:fullscreenVideoAd];
    LogAdapterDelegate_Internal(@"slotID = %@", slotID);
    id<ISInterstitialAdapterDelegate> delegate = [self.interstitialAdToSmashDelegate objectForKey:fullscreenVideoAd];
    
    if (delegate) {
        [delegate adapterInterstitialDidClose];
    }
}

/**
 This method is called when video ad play completed or an error occurred.
 @param error : the reason of error
 */
- (void)fullscreenVideoAdDidPlayFinish:(BUFullscreenVideoAd *)fullscreenVideoAd didFailWithError:(NSError *_Nullable)error {
    NSString *slotID = [self.interstitialAdToSlotId objectForKey:fullscreenVideoAd];
    LogAdapterDelegate_Internal(@"slotID = %@", slotID);
    id<ISInterstitialAdapterDelegate> delegate = [self.interstitialAdToSmashDelegate objectForKey:fullscreenVideoAd];
    
    if (delegate && error) {
        LogAdapterDelegate_Internal(@"error = %@", error);
        [delegate adapterInterstitialDidFailToShowWithError:error];
    }
}

/**
 This method is called when the user clicked skip button.
 */
- (void)fullscreenVideoAdDidClickSkip:(BUFullscreenVideoAd *)fullscreenVideoAd {
    NSString *slotID = [self.interstitialAdToSlotId objectForKey:fullscreenVideoAd];
    LogAdapterDelegate_Internal(@"slotID = %@", slotID);
}

#pragma mark - Banner Delegate
/**
 This method is called when bannerAdView ad slot loaded successfully.
 @param bannerAdView : view for bannerAdView
 */
- (void)nativeExpressBannerAdViewDidLoad:(BUNativeExpressBannerView *)bannerAdView {
    // no-op
}

/**
 This method is called when bannerAdView ad slot failed to load.
 @param error : the reason of error
 */
- (void)nativeExpressBannerAdView:(BUNativeExpressBannerView *)bannerAdView didLoadFailWithError:(NSError *_Nullable)error {
    NSString *slotID = [self.bannerAdToSlotId objectForKey:bannerAdView];
    LogAdapterDelegate_Internal(@"slotID = %@", slotID);
    id<ISBannerAdapterDelegate> delegate = [self.bannerAdToSmashDelegate objectForKey:bannerAdView];

    if (delegate) {
        NSInteger errorCode;
        NSString *errorReason;
        
        if (error) {
            LogAdapterDelegate_Internal(@"error = %@", error);
            errorCode = error.code == BUErrorCodeNOAD? ERROR_BN_LOAD_NO_FILL : error.code;
            errorReason = error.description;
        }
        else {
            errorCode = ERROR_CODE_GENERIC;
            errorReason = [NSString stringWithFormat:@"%@ banner load failed for slotID %@", kAdapterName, slotID];
        }
        
        [delegate adapterBannerDidFailToLoadWithError:[NSError errorWithDomain:kAdapterName code:ERROR_CODE_GENERIC userInfo:@{NSLocalizedDescriptionKey : errorReason}]];
    }
}

/**
 This method is called when rendering a nativeExpressAdView successed.
 */
- (void)nativeExpressBannerAdViewRenderSuccess:(BUNativeExpressBannerView *)bannerAdView {
    NSString *slotID = [self.bannerAdToSlotId objectForKey:bannerAdView];
    LogAdapterDelegate_Internal(@"slotID = %@", slotID);
    id<ISBannerAdapterDelegate> delegate = [self.bannerAdToSmashDelegate objectForKey:bannerAdView];
    
    if (delegate) {
        [delegate adapterBannerDidLoad:bannerAdView];
    }
}

/**
 This method is called when a nativeExpressAdView failed to render.
 @param error : the reason of error
 */
- (void)nativeExpressBannerAdViewRenderFail:(BUNativeExpressBannerView *)bannerAdView error:(NSError * __nullable)error {
    NSString *slotID = [self.bannerAdToSlotId objectForKey:bannerAdView];
    LogAdapterDelegate_Internal(@"slotID = %@", slotID);
    id<ISBannerAdapterDelegate> delegate = [self.bannerAdToSmashDelegate objectForKey:bannerAdView];
    
    if (delegate) {
        NSError *smashError;

        if (error) {
            LogAdapterDelegate_Internal(@"error = %@", error);
            smashError = error;
        }
        else {
            smashError = [ISError errorWithDomain:kAdapterName code:ERROR_CODE_GENERIC userInfo:@{NSLocalizedDescriptionKey:[NSString stringWithFormat:@"Banner show failed - no data for slotID = %@", slotID]}];
        }
        
        [delegate adapterBannerDidFailToLoadWithError:smashError];
    }
}

/**
 This method is called when bannerAdView ad slot showed new ad.
 */
- (void)nativeExpressBannerAdViewWillBecomVisible:(BUNativeExpressBannerView *)bannerAdView {
    NSString *slotID = [self.bannerAdToSlotId objectForKey:bannerAdView];
    LogAdapterDelegate_Internal(@"slotID = %@", slotID);
    id<ISBannerAdapterDelegate> delegate = [self.bannerAdToSmashDelegate objectForKey:bannerAdView];
    [delegate adapterBannerDidShow];

}

/**
 This method is called when bannerAdView is clicked.
 */
- (void)nativeExpressBannerAdViewDidClick:(BUNativeExpressBannerView *)bannerAdView {
    NSString *slotID = [self.bannerAdToSlotId objectForKey:bannerAdView];
    LogAdapterDelegate_Internal(@"slotID = %@", slotID);
    id<ISBannerAdapterDelegate> delegate = [self.bannerAdToSmashDelegate objectForKey:bannerAdView];
    
    if (delegate) {
        [delegate adapterBannerDidClick];
    }
}

/**
 This method is called when the user clicked dislike button and chose dislike reasons.
 @param filterwords : the array of reasons for dislike.
 */
- (void)nativeExpressBannerAdView:(BUNativeExpressBannerView *)bannerAdView dislikeWithReason:(NSArray<BUDislikeWords *> *_Nullable)filterwords {
    // no-op
}

/**
 This method is called when another controller has been closed.
 @param interactionType : open appstore in app or open the webpage or view video ad details page.
 */
- (void)nativeExpressBannerAdViewDidCloseOtherController:(BUNativeExpressBannerView *)bannerAdView interactionType:(BUInteractionType)interactionType {
    NSString *slotID = [self.bannerAdToSlotId objectForKey:bannerAdView];
    LogAdapterDelegate_Internal(@"slotID = %@", slotID);
    id<ISBannerAdapterDelegate> delegate = [self.bannerAdToSmashDelegate objectForKey:bannerAdView];
    
    if (delegate) {
        [delegate adapterBannerWillLeaveApplication];
    }
}

#pragma mark - Private Methods

- (NSDictionary *)getBiddingDataWithSlotID:(NSString *)slotID {
    LogAdapterDelegate_Internal(@"slotID = %@", slotID);
    NSString *bidderToken = [BUAdSDKManager getBiddingToken:slotID];
    NSString *returnedToken = bidderToken? bidderToken : @"";
    LogAdapterApi_Internal(@"token = %@", returnedToken);
    
    return @{@"token": returnedToken};
}

- (void)initSDKWithAppID:(NSString *)appID userId:(NSString *) userId isChinaMainland:(BOOL)isChinaMainland {
    // add self to init delegates only when init not finished yet
    if (_initState == INIT_STATE_NONE || _initState == INIT_STATE_IN_PROGRESS) {
        [initCallbackDelegates addObject:self];
    }
    
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        
        _initState = INIT_STATE_IN_PROGRESS;

        BOOL isDebugMode = [ISConfigurations getConfigurations].adaptersDebug;
        LogAdapterApi_Internal(@"userId = %@ appID = %@ debug = %d isChinaMainland = %@", userId, appID, isDebugMode, isChinaMainland ? @"YES" : @"NO");
        [BUAdSDKManager setLoglevel:(isDebugMode? BUAdSDKLogLevelDebug : BUAdSDKLogLevelNone)];
        [BUAdSDKManager setTerritory:isChinaMainland ? BUAdSDKTerritory_CN : BUAdSDKTerritory_NO_CN];
        [BUAdSDKManager allowModifyAudioSessionSetting:YES];
        [BUAdSDKManager setUserExtData:[self getPangleInitData]];
        [BUAdSDKManager setAppID:appID];

        model = [[BURewardedVideoModel alloc] init];
        
        [BUAdSDKManager startWithAsyncCompletionHandler:^(BOOL success, NSError *error) {
            if (success) {
                _initState = INIT_STATE_SUCCESS;
                LogAdapterDelegate_Internal(@"Pangle Successfully initialized");

                NSArray *initDelegatesList = initCallbackDelegates.allObjects;
                for (id<ISNetworkInitCallbackProtocol> delegate in initDelegatesList) {
                    [delegate onNetworkInitCallbackSuccess];
                }
            } else {
                _initState = INIT_STATE_FAILED;
                LogAdapterDelegate_Internal(@"Pangle failed to init! - %@" , error);

                NSArray *initDelegatesList = initCallbackDelegates.allObjects;
                for (id<ISNetworkInitCallbackProtocol> delegate in initDelegatesList) {
                    NSString *errorMsg = @"Pangle SDK init failed";
                    if (error) {
                        errorMsg = [NSString stringWithFormat:@"Pangle SDK init failed with error: %@", error.description];
                    }
                    
                    [delegate onNetworkInitCallbackFailed:errorMsg];
                }
            }
            
            // remove all init callback delegates
            [initCallbackDelegates removeAllObjects];
        }];
    });
}

-(void)onNetworkInitCallbackFailed:(nonnull NSString *)errorMessage {
    NSError *error = [NSError errorWithDomain:kAdapterName code:ERROR_CODE_INIT_FAILED userInfo:@{NSLocalizedDescriptionKey:errorMessage}];;

    // rewarded video
    NSArray *rewardedVideoSlotIDs = _slotIdToRewardedVideoDelegate.allKeys;
    for (NSString* slotId in rewardedVideoSlotIDs) {
        id<ISRewardedVideoAdapterDelegate> delegate =[_slotIdToRewardedVideoDelegate objectForKey:slotId];
        
        if ([_rewardedVideoPlacementsForInitCallbacks hasObject:slotId]) {
            [delegate adapterRewardedVideoInitFailed:error];
        } else {
            [delegate adapterRewardedVideoHasChangedAvailability:NO];
        }
    }
    
    // interstitial
    NSArray *interstitialSlotIDs = _slotIdToInterstitiaDelegate.allKeys;
    for (NSString *slotId in interstitialSlotIDs) {
        id<ISInterstitialAdapterDelegate> delegate = [_slotIdToInterstitiaDelegate objectForKey:slotId];
        [delegate adapterInterstitialInitFailedWithError: error];
    }
    
    // banner
    NSArray *bannerSlotIDs = _slotIdToBannerDelegate.allKeys;
    for (NSString *slotId in bannerSlotIDs) {
        id<ISBannerAdapterDelegate> delegate = [_slotIdToBannerDelegate objectForKey:slotId];
        [delegate adapterBannerInitFailedWithError:error];
    }
}

- (void)onNetworkInitCallbackSuccess {
    // rewarded video
    NSArray *rewardedVideoSlotIDs = _slotIdToRewardedVideoDelegate.allKeys;
    for (NSString* slotId in rewardedVideoSlotIDs) {
        id<ISRewardedVideoAdapterDelegate> delegate =[_slotIdToRewardedVideoDelegate objectForKey:slotId];
        if ([_rewardedVideoPlacementsForInitCallbacks hasObject:slotId]) {
            [delegate adapterRewardedVideoInitSuccess];
        } else {
            [self loadRewardVideoWithSlotID:slotId isBidder:NO serverData:nil delegate:delegate];
        }
    }
    
    // interstitial
    NSArray *interstitialSlotIDs = _slotIdToInterstitiaDelegate.allKeys;
    for (NSString *slotId in interstitialSlotIDs) {
        id<ISInterstitialAdapterDelegate> delegate = [_slotIdToInterstitiaDelegate objectForKey:slotId];
        [delegate adapterInterstitialInitSuccess];
    }
    
    // banner
    NSArray *bannerSlotIDs = _slotIdToBannerDelegate.allKeys;
    for (NSString *slotId in bannerSlotIDs) {
        id<ISBannerAdapterDelegate> delegate = [_slotIdToBannerDelegate objectForKey:slotId];
        [delegate adapterBannerInitSuccess];
    }
}

- (BOOL)isAdAvailableWithSlotId:(NSString *)slotID adsAvailability:(ConcurrentMutableDictionary *) adsAvailability {
    NSNumber *available = [adsAvailability objectForKey:slotID];
    BOOL isAvailable = (available != nil) && [available boolValue];
    return isAvailable;
}

- (BOOL) isBannerSizeSupported:(ISBannerSize *)size {
    if ([size.sizeDescription isEqualToString:@"BANNER"] ||
        [size.sizeDescription isEqualToString:@"RECTANGLE"]) {
        return YES;
    } else if ([size.sizeDescription isEqualToString:@"SMART"]) {
        // Pangle bidding doesn't support leaderboard
        return (UI_USER_INTERFACE_IDIOM() != UIUserInterfaceIdiomPad);
    }
    
    return NO;
}

- (CGSize) getBannerSize:(ISBannerSize *)size {
    if ([size.sizeDescription isEqualToString:@"BANNER"]) {
        return CGSizeMake(320, 50);
    } else if ([size.sizeDescription isEqualToString:@"RECTANGLE"]) {
        return CGSizeMake(300, 250);
    } else if ([size.sizeDescription isEqualToString:@"SMART"]) {
        if (UI_USER_INTERFACE_IDIOM() == UIUserInterfaceIdiomPad) {
            return CGSizeMake(728, 90);
        }
        else {
            return CGSizeMake(320, 50);
        }
    }
        
    return CGSizeZero;
}

- (NSString *)getPangleInitData {
    NSArray *pangleData = @[@{@"name" : @"mediation", @"value" : @"Ironsource"}, @{@"name" : @"adapter_version", @"value" : kAdapterVersion}];
    
    NSError *error;
    NSData *returnData = [NSJSONSerialization dataWithJSONObject:pangleData options:NSJSONWritingPrettyPrinted error:&error];
    
    if (error) {
        return @"";
    }

    NSString *stringData = [[NSString alloc] initWithData:returnData encoding:NSUTF8StringEncoding];
    LogAdapterApi_Internal(@"stringData: %@", stringData);
    return stringData;
}

- (BOOL)isChinaMainland:(ISAdapterConfig *)adapterConfig {
    return [adapterConfig.settings objectForKey:kIsChinaMainland] == nil ? kIsChinaMainlandDefaultValue : [[adapterConfig.settings objectForKey:kIsChinaMainland] boolValue];
}

@end
