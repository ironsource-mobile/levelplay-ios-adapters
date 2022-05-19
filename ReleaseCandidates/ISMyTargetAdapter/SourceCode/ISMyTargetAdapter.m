//
//  ISMyTargetAdapter.m
//  ISMyTargetAdapter
//
//  Created by Yonti Makmel on 12/01/2020.
//

#import "ISMyTargetAdapter.h"
#import "ISMyTargetRewardedVideoListener.h"
#import "ISMyTargetInterstitialListener.h"
#import <MyTargetSDK/MyTargetSDK.h>

static NSString * const kAdapterName         = @"MyTarget";
static NSString * const kAdapterVersion      = MyTargetAdapterVersion;
static NSString * const kPlacementId         = @"slotId";
static NSString * const IRONSOURCE_MEDIATION = @"8";

@interface ISMyTargetAdapter () <ISMyTargetRewardedVideoDelegateWrapper, ISMyTargetInterstitialDelegateWrapper>

// Rewarded video
@property (nonatomic, strong) ConcurrentMutableDictionary *rewardedVideoPlacementToSmashDelegate;
@property (nonatomic, strong) ConcurrentMutableDictionary *rewardedVideoPlacementToAd;
@property (nonatomic, strong) ConcurrentMutableDictionary *rewardedVideoPlacementToListener;
@property (nonatomic, strong) ConcurrentMutableDictionary *rewardedVideoAdsAvailability;
@property (nonatomic, strong) NSMapTable                  *rewardedVideoAdToPlacement;

// Interstitial
@property (nonatomic, strong) ConcurrentMutableDictionary *interstitialPlacementToSmashDelegate;
@property (nonatomic, strong) ConcurrentMutableDictionary *interstitialPlacementToAd;
@property (nonatomic, strong) ConcurrentMutableDictionary *interstitialPlacementToListener;
@property (nonatomic, strong) ConcurrentMutableDictionary *interstitialAdsAvailability;
@property (nonatomic, strong) NSMapTable *interstitialAdToPlacement;

@end

@implementation ISMyTargetAdapter

#pragma mark - Initializations Methods

- (instancetype)initAdapter:(NSString *)name
{
    self = [super initAdapter:name];
    
    if (self) {
        // Rewarded video
        _rewardedVideoPlacementToSmashDelegate  = [ConcurrentMutableDictionary dictionary];
        _rewardedVideoPlacementToAd             = [ConcurrentMutableDictionary dictionary];
        _rewardedVideoPlacementToListener       = [ConcurrentMutableDictionary dictionary];
        _rewardedVideoAdsAvailability           = [ConcurrentMutableDictionary dictionary];
        _rewardedVideoAdToPlacement             = [NSMapTable mapTableWithKeyOptions:NSMapTableStrongMemory valueOptions:NSMapTableWeakMemory];
        
        // Interstitial
        _interstitialPlacementToSmashDelegate  = [ConcurrentMutableDictionary dictionary];
        _interstitialPlacementToAd             = [ConcurrentMutableDictionary dictionary];
        _interstitialPlacementToListener       = [ConcurrentMutableDictionary dictionary];
        _interstitialAdsAvailability           = [ConcurrentMutableDictionary dictionary];
        _interstitialAdToPlacement             = [NSMapTable mapTableWithKeyOptions:NSMapTableStrongMemory valueOptions:NSMapTableWeakMemory];

        // load while show
        LWSState = LOAD_WHILE_SHOW_BY_INSTANCE;
    }
    
    return self;
}

#pragma mark - IronSource Protocol Methods

- (NSString*)version {
    return kAdapterVersion;
}

- (NSString*)sdkVersion {
    return [MTRGVersion currentVersion];
}

- (NSArray*)systemFrameworks {
    return @[@"AdSupport", @"AVFoundation",@"CoreGraphics", @"CoreMedia", @"CoreTelephony", @"SafariServices", @"StoreKit", @"SystemConfiguration"];
}

- (NSString*)sdkName {
    return @"MTRGInterstitialAd";
}

- (void)setConsent:(BOOL)consent {
    LogAdapterApi_Internal(@"consent = %@", consent ? @"YES" : @"NO");
    [MTRGPrivacy setUserConsent:consent];
}

#pragma mark - Rewarded Video API

- (NSDictionary *)getRewardedVideoBiddingDataWithAdapterConfig:(ISAdapterConfig *)adapterConfig {
    return [self getBiddingData];
}

- (void)initAndLoadRewardedVideoWithUserId:(NSString *)userId
                             adapterConfig:(ISAdapterConfig *)adapterConfig
                                  delegate:(id<ISRewardedVideoAdapterDelegate>)delegate {
    LogAdapterApi_Internal(@"");
    [self initRewardedVideoInternalWithUserId:userId adapterConfig:adapterConfig delegate:delegate block:^(BOOL completed, NSError *error) {
        if (completed) {
            [self loadRewardVideoInternalWithAdunitId:adapterConfig serverData:nil delegate:delegate];
        } else {
            [delegate adapterRewardedVideoHasChangedAvailability:NO];
        }
    }];
}

- (void)initRewardedVideoForCallbacksWithUserId:(NSString *)userId
                                  adapterConfig:(ISAdapterConfig *)adapterConfig
                                       delegate:(id<ISRewardedVideoAdapterDelegate>)delegate {
    LogAdapterApi_Internal(@"");
    [self initRewardedVideoInternalWithUserId:userId adapterConfig:adapterConfig delegate:delegate block:^(BOOL completed, NSError *error) {
        if (completed) {
            [delegate adapterRewardedVideoInitSuccess];
        } else {
            [delegate adapterRewardedVideoInitFailed:error];
        }
    }];
}

- (void)initRewardedVideoInternalWithUserId:(NSString *)userId adapterConfig:(ISAdapterConfig *)adapterConfig delegate:(id<ISRewardedVideoAdapterDelegate>)delegate block:(void (^)(BOOL, NSError *))block {
        // validate placement
        NSString *placementId = adapterConfig.settings[kPlacementId];
    
        if (![self isConfigValueValid:placementId]) {
            NSError *error = [self errorForMissingCredentialFieldWithName:kPlacementId];
            LogInternal_Error(@"error = %@", error);
            block(NO, error);
            return;
        }
        
        LogInternal_Internal(@"placementId = %@", placementId);
        
        // add delegate to dictionary
        [self.rewardedVideoPlacementToSmashDelegate setObject:delegate forKey:placementId];
        
        // create delegate
        ISMyTargetRewardedVideoListener *rewardedVideoDelegate = [[ISMyTargetRewardedVideoListener alloc] initWithDelegate:self];

        // add listener to dictionary
        [self.rewardedVideoPlacementToListener setObject:rewardedVideoDelegate forKey:placementId];
    
        // setup debug
        [MTRGManager setDebugMode:[ISConfigurations getConfigurations].adaptersDebug];
        LogAdapterApi_Internal(@"setDebugMode=%d", [ISConfigurations getConfigurations].adaptersDebug);

        block(YES, nil);
}

- (void)loadRewardedVideoForBiddingWithAdapterConfig:(ISAdapterConfig *)adapterConfig serverData:(NSString *)serverData delegate:(id<ISRewardedVideoAdapterDelegate>)delegate {
    LogAdapterApi_Internal(@"");
    [self loadRewardVideoInternalWithAdunitId:adapterConfig serverData:serverData delegate:delegate];
}

- (void)fetchRewardedVideoForAutomaticLoadWithAdapterConfig:(ISAdapterConfig *)adapterConfig delegate:(id<ISRewardedVideoAdapterDelegate>)delegate {
    LogAdapterApi_Internal(@"");
    [self loadRewardVideoInternalWithAdunitId:adapterConfig serverData:nil delegate:delegate];
}

- (void) loadRewardVideoInternalWithAdunitId:(ISAdapterConfig *)adapterConfig serverData:(NSString *)serverData delegate:(id<ISRewardedVideoAdapterDelegate>)delegate {
    // validate placement
    NSString *placementId = adapterConfig.settings[kPlacementId];
    
    if (![self isConfigValueValid:placementId]) {
        NSError *error = [self errorForMissingCredentialFieldWithName:kPlacementId];
        LogInternal_Error(@"error = %@", error);
        [delegate adapterRewardedVideoHasChangedAvailability:NO];
        return;
    }
    
    LogInternal_Internal(@"placementId = %@", placementId);
    
    // create ad
    MTRGRewardedAd *rewardedVideoAd = [MTRGRewardedAd rewardedAdWithSlotId:placementId.integerValue];
    
    // add to dictionary to be able to extract placement by ad
    [self.rewardedVideoAdToPlacement setObject:placementId forKey:rewardedVideoAd];
    
    // set availability false for this ad
    [self.rewardedVideoAdsAvailability setObject:@NO forKey:placementId];

    // get delegate
    ISMyTargetRewardedVideoListener *rewardedVideoDelegate = [self.rewardedVideoPlacementToListener objectForKey:placementId];
    
    // set delegate
    [rewardedVideoAd setDelegate:rewardedVideoDelegate];
    
    // add custom params
    [rewardedVideoAd.customParams setCustomParam:IRONSOURCE_MEDIATION forKey:@"mediation"];
    
    // load ad
    if (adapterConfig.isBidder) {
        LogAdapterApi_Internal(@"load RV with serverData = %@", serverData);
        // load bidder ad
        [rewardedVideoAd loadFromBid:serverData];
    } else {
        LogAdapterApi_Internal(@"load RV");
        [rewardedVideoAd load];
    }
}

- (void)showRewardedVideoWithViewController:(UIViewController *)viewController adapterConfig:(ISAdapterConfig *)adapterConfig delegate:(id<ISRewardedVideoAdapterDelegate>)delegate {
    
    // validate placement
    NSString *placementId = adapterConfig.settings[kPlacementId];
    
    if (![self isConfigValueValid:placementId]) {
        NSError *error = [self errorForMissingCredentialFieldWithName:kPlacementId];
        LogInternal_Error(@"error = %@", error);
        [delegate adapterRewardedVideoDidFailToShowWithError:error];
        [delegate adapterRewardedVideoHasChangedAvailability:NO];
        return;
    }
    
    LogAdapterApi_Internal(@"placementId = %@", placementId);
    
    // get ad
    MTRGRewardedAd *rewardedVideoAd = [self.rewardedVideoPlacementToAd objectForKey:placementId];
    
    // set availability false for this ad
    [self.rewardedVideoAdsAvailability setObject:@NO forKey:placementId];

    if (rewardedVideoAd) {
        // show ad
        [rewardedVideoAd showWithController:viewController];
    } else {
        NSError *error = [ISError createError:ERROR_CODE_GENERIC withMessage:[NSString stringWithFormat:@"no ad for placementId = %@", placementId]];
        [delegate adapterRewardedVideoDidFailToShowWithError:error];
    }
    
    // remove from dictionary
    [self.rewardedVideoPlacementToAd removeObjectForKey:placementId];

    // announce on availability false
    [delegate adapterRewardedVideoHasChangedAvailability:NO];
}

- (BOOL)hasRewardedVideoWithAdapterConfig:(ISAdapterConfig *)adapterConfig {
    NSString *placementId = adapterConfig.settings[kPlacementId];
    NSNumber *available = [self.rewardedVideoAdsAvailability objectForKey:placementId];
    return (available != nil) && [available boolValue];
}

#pragma mark - Rewarded Video Delegate

- (void)onRewardedVideoLoadSuccess:(MTRGRewardedAd *)rewardedVideoAd {
    NSString *placementId = [self.rewardedVideoAdToPlacement objectForKey:rewardedVideoAd];
    LogAdapterDelegate_Internal(@"placementId = %@", placementId);

    // add to dictionary
    [self.rewardedVideoPlacementToAd setObject:rewardedVideoAd forKey:placementId];

    // set availability true for this ad
    [self.rewardedVideoAdsAvailability setObject:@YES forKey:placementId];

    // call delegate
    [[self.rewardedVideoPlacementToSmashDelegate objectForKey:placementId] adapterRewardedVideoHasChangedAvailability:YES];
}

- (void)onRewardedVideoLoadFailWithReason:(NSString *)reason rewardedVideoAd:(MTRGRewardedAd *)rewardedVideoAd {
    NSString *placementId = [self.rewardedVideoAdToPlacement objectForKey:rewardedVideoAd];
    LogAdapterDelegate_Internal(@"placementId = %@", placementId);

    // remove from dictionary
    [self.rewardedVideoPlacementToAd removeObjectForKey:placementId];

    // set availability false for this ad
    [self.rewardedVideoAdsAvailability setObject:@NO forKey:placementId];

    // create error
    NSError *error = [ISError createError:ERROR_CODE_NO_ADS_TO_SHOW withMessage:[NSString stringWithFormat:@"MyTarget load failed, reason = %@", reason]];

    // call delegate
    [[self.rewardedVideoPlacementToSmashDelegate objectForKey:placementId] adapterRewardedVideoHasChangedAvailability:NO];
    [[self.rewardedVideoPlacementToSmashDelegate objectForKey:placementId] adapterRewardedVideoDidFailToLoadWithError:error];
}

- (void)onRewardedVideoClicked:(MTRGRewardedAd *)rewardedVideoAd {
    NSString *placementId = [self.rewardedVideoAdToPlacement objectForKey:rewardedVideoAd];
    LogAdapterDelegate_Internal(@"placementId = %@", placementId);

    // call delegate
    [[self.rewardedVideoPlacementToSmashDelegate objectForKey:placementId] adapterRewardedVideoDidClick];
}

- (void)onRewardedVideoDisplay:(MTRGRewardedAd *)rewardedVideoAd {
    NSString *placementId = [self.rewardedVideoAdToPlacement objectForKey:rewardedVideoAd];
    LogAdapterDelegate_Internal(@"placementId = %@", placementId);

    // call delegate
    [[self.rewardedVideoPlacementToSmashDelegate objectForKey:placementId] adapterRewardedVideoDidOpen];
}

- (void)onRewardedVideoClosed:(MTRGRewardedAd *)rewardedVideoAd {
    NSString *placementId = [self.rewardedVideoAdToPlacement objectForKey:rewardedVideoAd];
    LogAdapterDelegate_Internal(@"placementId = %@", placementId);

    // call delegate
    [[self.rewardedVideoPlacementToSmashDelegate objectForKey:placementId] adapterRewardedVideoDidClose];
}

- (void)onRewardedVideoCompleted:(MTRGRewardedAd *)rewardedVideoAd {
    NSString *placementId = [self.rewardedVideoAdToPlacement objectForKey:rewardedVideoAd];
    LogAdapterDelegate_Internal(@"placementId = %@", placementId);

    // call delegate
    [[self.rewardedVideoPlacementToSmashDelegate objectForKey:placementId] adapterRewardedVideoDidReceiveReward];
}

#pragma mark - Interstitial Methods

- (NSDictionary *)getInterstitialBiddingDataWithAdapterConfig:(ISAdapterConfig *)adapterConfig {
    return [self getBiddingData];
}

- (void)initInterstitialForBiddingWithUserId:(NSString *)userId adapterConfig:(ISAdapterConfig *)adapterConfig delegate:(id<ISInterstitialAdapterDelegate>)delegate {
    LogAdapterApi_Internal(@"");
    [self initInterstitialInternalWithUserId:userId adapterConfig:adapterConfig delegate:delegate];
}

- (void)initInterstitialInternalWithUserId:(NSString *)userId adapterConfig:(ISAdapterConfig *)adapterConfig delegate:(id<ISInterstitialAdapterDelegate>)delegate {
    LogAdapterApi_Internal(@"");
    NSString *placementId = adapterConfig.settings[kPlacementId];

    // validate placement
    if (![self isConfigValueValid:placementId]) {
        NSError *error = [self errorForMissingCredentialFieldWithName:kPlacementId];
        LogInternal_Error(@"error = %@", error);
        [delegate adapterInterstitialInitFailedWithError:error];
        return;
    }
    
    LogAdapterApi_Internal(@"placementId = %@", placementId);
    
    // add delegate to dictionary
    [self.interstitialPlacementToSmashDelegate setObject:delegate forKey:placementId];
    
    // create delegate
    ISMyTargetInterstitialListener *interstitialDelegate = [[ISMyTargetInterstitialListener alloc] initWithDelegate:self];

    // add listener to dictionary
    [self.interstitialPlacementToListener setObject:interstitialDelegate forKey:placementId];

    // setup debug
    [MTRGManager setDebugMode:[ISConfigurations getConfigurations].adaptersDebug];
    LogAdapterApi_Internal(@"setDebugMode=%d", [ISConfigurations getConfigurations].adaptersDebug);

    // announce init success
    [delegate adapterInterstitialInitSuccess];
}

- (void)loadInterstitialForBiddingWithServerData:(NSString *)serverData adapterConfig:(ISAdapterConfig *)adapterConfig delegate:(id<ISInterstitialAdapterDelegate>)delegate {
    LogAdapterApi_Internal(@"");
    [self loadInterstitialInternalWithAdapterConfig:adapterConfig serverData:serverData delegate:delegate];
}

- (void)loadInterstitialInternalWithAdapterConfig:(ISAdapterConfig *)adapterConfig serverData:(NSString *)serverData delegate:(id<ISInterstitialAdapterDelegate>)delegate {
    NSString *placementId = adapterConfig.settings[kPlacementId];

    // validate placement
    if (![self isConfigValueValid:placementId]) {
        NSError *error = [self errorForMissingCredentialFieldWithName:kPlacementId];
        LogInternal_Error(@"error = %@", error);
        [delegate adapterInterstitialDidFailToLoadWithError:error];
        return;
    }
    
    LogInternal_Internal(@"placementId = %@", placementId);
    
    // create ad
    MTRGInterstitialAd *interstitialAd = [MTRGInterstitialAd interstitialAdWithSlotId:placementId.integerValue];
    
    // add to dictionary to be able to extract placement by ad
    [self.interstitialAdToPlacement setObject:placementId forKey:interstitialAd];
    
    // set availability false for this ad
    [self.interstitialAdsAvailability setObject:@NO forKey:placementId];
    
    // get delegate
    ISMyTargetInterstitialListener *interstitialDelegate = [self.interstitialPlacementToListener objectForKey:placementId];
    
    // set delegate
    [interstitialAd setDelegate:interstitialDelegate];
    
    // add custom params
    [interstitialAd.customParams setCustomParam:IRONSOURCE_MEDIATION forKey:@"mediation"];
    
    LogAdapterApi_Internal(@"serverData = %@", serverData);
    
    // load bidder ad
    [interstitialAd loadFromBid:serverData];
}

- (void)showInterstitialWithViewController:(UIViewController *)viewController adapterConfig:(ISAdapterConfig *)adapterConfig delegate:(id<ISInterstitialAdapterDelegate>)delegate {
    NSString *placementId = adapterConfig.settings[kPlacementId];

    // validate placement
    if (![self isConfigValueValid:placementId]) {
        NSError *error = [self errorForMissingCredentialFieldWithName:kPlacementId];
        LogInternal_Error(@"error = %@", error);
        [delegate adapterInterstitialDidFailToShowWithError:error];
        return;
    }
    
    LogAdapterApi_Internal(@"placementId = %@", placementId);
    
    // get ad
    MTRGInterstitialAd *interstitialAd = [self.interstitialPlacementToAd objectForKey:placementId];
    
    // set availability false for this ad
    [self.interstitialAdsAvailability setObject:@NO forKey:placementId];

    if (interstitialAd) {
        // show ad
        [interstitialAd showWithController:viewController];
    } else {
        NSError *error = [ISError createError:ERROR_CODE_GENERIC withMessage:[NSString stringWithFormat:@"no ad for placementId = %@", placementId]];
        [delegate adapterInterstitialDidFailToShowWithError:error];
    }
    
    // remove from dictionary
    [self.interstitialPlacementToAd removeObjectForKey:placementId];
}

- (BOOL)hasInterstitialWithAdapterConfig:(ISAdapterConfig *)adapterConfig {
    NSString *placementId = adapterConfig.settings[kPlacementId];
    NSNumber *available = [self.interstitialAdsAvailability objectForKey:placementId];
    return (available != nil) && [available boolValue];
}

#pragma mark - Interstitial Delegate

- (void)onInterstitialLoadSuccess:(MTRGInterstitialAd *)interstitialAd {
    NSString *placementId = [self.interstitialAdToPlacement objectForKey:interstitialAd];
    LogAdapterDelegate_Internal(@"placementId = %@", placementId);
    
    // add to dictionary
    [self.interstitialPlacementToAd setObject:interstitialAd forKey:placementId];
    
    // set availability true for this ad
    [self.interstitialAdsAvailability setObject:@YES forKey:placementId];

    // call delegate
    [[self.interstitialPlacementToSmashDelegate objectForKey:placementId] adapterInterstitialDidLoad];
}

- (void)onInterstitialLoadFailWithReason:(NSString *)reason interstitialAd:(MTRGInterstitialAd *)interstitialAd {
    NSString *placementId = [self.interstitialAdToPlacement objectForKey:interstitialAd];
    LogAdapterDelegate_Internal(@"placementId = %@", placementId);
    
    // remove from dictionary
    [self.interstitialPlacementToAd removeObjectForKey:placementId];
    
    // set availability false for this ad
    [self.interstitialAdsAvailability setObject:@NO forKey:placementId];

    // create error
    NSError *error = [ISError createError:ERROR_CODE_NO_ADS_TO_SHOW withMessage:[NSString stringWithFormat:@"MyTarget load failed, reason = %@", reason]];
    
    // call delegate
    [[self.interstitialPlacementToSmashDelegate objectForKey:placementId] adapterInterstitialDidFailToLoadWithError:error];
}

- (void)onInterstitialClicked:(MTRGInterstitialAd *)interstitialAd {
    NSString *placementId = [self.interstitialAdToPlacement objectForKey:interstitialAd];
    LogAdapterDelegate_Internal(@"placementId = %@", placementId);
    
    // call delegate
    [[self.interstitialPlacementToSmashDelegate objectForKey:placementId] adapterInterstitialDidClick];
}

- (void)onInterstitialDisplay:(MTRGInterstitialAd *)interstitialAd {
    NSString *placementId = [self.interstitialAdToPlacement objectForKey:interstitialAd];
    LogAdapterDelegate_Internal(@"placementId = %@", placementId);
        
    // call delegate
    [[self.interstitialPlacementToSmashDelegate objectForKey:placementId] adapterInterstitialDidOpen];
    [[self.interstitialPlacementToSmashDelegate objectForKey:placementId] adapterInterstitialDidShow];
}

- (void)onInterstitialClosed:(MTRGInterstitialAd *)interstitialAd {
    NSString *placementId = [self.interstitialAdToPlacement objectForKey:interstitialAd];
    LogAdapterDelegate_Internal(@"placementId = %@", placementId);
    
    // call delegate
    [[self.interstitialPlacementToSmashDelegate objectForKey:placementId] adapterInterstitialDidClose];
}

- (void)onInterstitialCompleted:(MTRGInterstitialAd *)interstitialAd {
    NSString *placementId = [self.interstitialAdToPlacement objectForKey:interstitialAd];
    LogAdapterDelegate_Internal(@"placementId = %@", placementId);
}

#pragma mark - Helper Methods

- (NSDictionary *)getBiddingData {
    NSString *bidderToken = [MTRGManager getBidderToken];
    NSString *returnedToken = bidderToken? bidderToken : @"";
    LogAdapterApi_Internal(@"token = %@", returnedToken);
    return @{@"token": returnedToken};
}

@end
