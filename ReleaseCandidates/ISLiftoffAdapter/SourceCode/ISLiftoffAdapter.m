//
//  ISLiftoffAdapter.m
//  ISLiftoffAdapter
//
//  Created by Roi Eshel on 14/09/2021.
//  Copyright © 2021 IronSource. All rights reserved.
//

#import "ISLiftoffAdapter.h"
#import "ISLiftoffBannerListener.h"
#import "ISLiftoffInterstitialListener.h"
#import "ISLiftoffRewardedVideoListener.h"
#import <LiftoffAds/LiftoffAds.h>

static NSString * const kAdapterVersion           = LiftoffAdapterVersion;
static NSString * const kAdapterName              = @"Liftoff";
static NSString * const kApiKey                   = @"apiKey";
static NSString * const kAdUnitId                 = @"adUnitId";

static bool isInitCompleted = NO;

@interface ISLiftoffAdapter () <ISLiftoffBannerDelegateWrapper, ISLiftoffInterstitialDelegateWrapper, ISLiftoffRewardedVideoDelegateWrapper>
    
// Rewrded video
@property (nonatomic, strong) ConcurrentMutableDictionary *adUnitIdToRewardedVideoSmashDelegate;
@property (nonatomic, strong) ConcurrentMutableDictionary *adUnitIdToRewardedVideoAd;
@property (nonatomic, strong) NSMapTable                  *rewardedVideoAdToAdUnitId;
@property (nonatomic, strong) ConcurrentMutableDictionary *rewardedVideoAdUnitIdToListener;
@property (nonatomic, strong) ConcurrentMutableDictionary *rewardedVideoAdsAvailability;

// Interstitial
@property (nonatomic, strong) ConcurrentMutableDictionary *adUnitIdToInterstitialSmashDelegate;
@property (nonatomic, strong) ConcurrentMutableDictionary *adUnitIdToInterstitialAd;
@property (nonatomic, strong) NSMapTable                  *interstitialAdToAdUnitId;
@property (nonatomic, strong) ConcurrentMutableDictionary *interstitialAdUnitIdToListener;
@property (nonatomic, strong) ConcurrentMutableDictionary *interstitialAdsAvailability;

// Banner
@property (nonatomic, strong) ConcurrentMutableDictionary *adUnitIdToBannerSmashDelegate;
@property (nonatomic, strong) ConcurrentMutableDictionary *adUnitIdToBannerAd;
@property (nonatomic, strong) NSMapTable                  *bannerAdToAdUnitId;
@property (nonatomic, strong) ConcurrentMutableDictionary *bannerAdUnitIdToListener;

@end


@implementation ISLiftoffAdapter

#pragma mark - Initializations Methods

- (instancetype)initAdapter:(NSString *)name {
    self = [super initAdapter:name];
    
    if (self) {
        // Rewrded video
        _adUnitIdToRewardedVideoSmashDelegate = [ConcurrentMutableDictionary dictionary];
        _adUnitIdToRewardedVideoAd = [ConcurrentMutableDictionary dictionary];
        _rewardedVideoAdToAdUnitId = [NSMapTable mapTableWithKeyOptions:NSMapTableStrongMemory valueOptions:NSMapTableWeakMemory];
        _rewardedVideoAdUnitIdToListener = [ConcurrentMutableDictionary dictionary];
        _rewardedVideoAdsAvailability = [ConcurrentMutableDictionary dictionary];
        
        // Interstitial
        _adUnitIdToInterstitialSmashDelegate = [ConcurrentMutableDictionary dictionary];
        _adUnitIdToInterstitialAd = [ConcurrentMutableDictionary dictionary];
        _interstitialAdToAdUnitId = [NSMapTable mapTableWithKeyOptions:NSMapTableStrongMemory valueOptions:NSMapTableWeakMemory];
        _interstitialAdUnitIdToListener = [ConcurrentMutableDictionary dictionary];
        _interstitialAdsAvailability = [ConcurrentMutableDictionary dictionary];
        
        // Banner
        _adUnitIdToBannerSmashDelegate = [ConcurrentMutableDictionary dictionary];
        _adUnitIdToBannerAd = [ConcurrentMutableDictionary dictionary];
        _bannerAdToAdUnitId = [NSMapTable mapTableWithKeyOptions:NSMapTableStrongMemory valueOptions:NSMapTableWeakMemory];
        _bannerAdUnitIdToListener = [ConcurrentMutableDictionary dictionary];
    
        LWSState = LOAD_WHILE_SHOW_BY_INSTANCE;
        
    }
    
    return self;
}

#pragma mark - IronSource Protocol Methods

- (NSString *)version {
    return kAdapterVersion;
}

- (NSString *)sdkVersion {
    return Liftoff.sdkVersion;
}

- (NSArray *) systemFrameworks {
    return @[];
}

- (NSString *)sdkName {
    return @"LiftoffAds.Liftoff";
}

- (void)setMetaDataWithKey:(NSString *)key andValues:(NSMutableArray *) values {
    if (values.count == 0) {
        return;
    }
    
    NSString *value = values[0];
    LogAdapterApi_Internal(@"setMetaData: key=%@, value=%@", key, value);
    
    if ([ISMetaDataUtils isValidCCPAMetaDataWithKey:key andValue:value]) {
        [self setCCPAValue:[ISMetaDataUtils getCCPABooleanValue:value]];
    }
}

- (void) setCCPAValue:(BOOL)value {
    BOOL userConsent = !value;
    LogAdapterApi_Internal(@"userConsent = %@", userConsent ? @"YES" : @"NO");
    
    [[LOPrivacySettings shared] setIsGDPRApplicable:NO];
    [[LOPrivacySettings shared] setHasUserConsent:userConsent];
}

- (void) setConsent:(BOOL)consent {
    LogAdapterApi_Internal(@"consent = %@", consent ? @"YES" : @"NO");
    
    [[LOPrivacySettings shared] setIsGDPRApplicable:YES];
    [[LOPrivacySettings shared] setHasUserConsent:consent];
}

#pragma mark - Rewarded Video

- (void)initRewardedVideoForCallbacksWithUserId:(NSString *)userId
                                  adapterConfig:(ISAdapterConfig *)adapterConfig
                                       delegate:(id<ISRewardedVideoAdapterDelegate>)delegate {
    if (delegate == nil) {
        LogAdapterApi_Internal(@"delegate == nil");
        return;
    }
    
    NSString *apiKey = adapterConfig.settings[kApiKey];
    NSString *adUnitId = adapterConfig.settings[kAdUnitId];

    // Configuration Validation
    if (![self isConfigValueValid:apiKey]) {
        NSError *error = [self errorForMissingCredentialFieldWithName:kApiKey];
        LogAdapterApi_Internal(@"error = %@", error);
        [delegate adapterRewardedVideoInitFailed:error];
        return;
    }
    
    if (![self isConfigValueValid:adUnitId]) {
        NSError *error = [self errorForMissingCredentialFieldWithName:kAdUnitId];
        LogAdapterApi_Internal(@"error = %@", error);
        [delegate adapterRewardedVideoInitFailed:error];
        return;
    }
    
    LogAdapterApi_Internal(@"adUnitId = %@", adUnitId);
    
    // Register Smash for adUnitId
    [self.adUnitIdToRewardedVideoSmashDelegate setObject:delegate forKey:adUnitId];
    
    // Create delegate
    ISLiftoffRewardedVideoListener *rewardedVideoDelegate = [[ISLiftoffRewardedVideoListener alloc] initWithDelegate:self];
    [self.rewardedVideoAdUnitIdToListener setObject:rewardedVideoDelegate forKey:adUnitId];
    
    [self initSDKWithApiKey:apiKey];
    [delegate adapterRewardedVideoInitSuccess];
}

- (void)loadRewardedVideoForBiddingWithAdapterConfig:(ISAdapterConfig *)adapterConfig serverData:(NSString *)serverData delegate:(id<ISRewardedVideoAdapterDelegate>)delegate {
    // validate adUnitId
    NSString *adUnitId = adapterConfig.settings[kAdUnitId];
    
    if (![self isConfigValueValid:adUnitId]) {
        NSError *error = [self errorForMissingCredentialFieldWithName:kAdUnitId];
        LogAdapterApi_Internal(@"error = %@", error);
        [delegate adapterRewardedVideoHasChangedAvailability:NO];
        return;
    }
    
    LogInternal_Internal(@"adUnitId = %@", adUnitId);
    
    // set availability false for this ad
    [self.rewardedVideoAdsAvailability setObject:@NO forKey:adUnitId];
    
    [self.dispatcher dispatchAsyncWithQueue:dispatch_get_main_queue() withBlock:^{
        // create ad
        LOInterstitial *rewardedVideoAd = [Liftoff initInterstitialAdUnitFor:adUnitId];
        
        // add rewarded video to map table to so we may use it to extract the adUnitId later on
        [self.rewardedVideoAdToAdUnitId setObject:adUnitId forKey:rewardedVideoAd];
        
        // add rewarded video to dictionary so we may extract it later using the adUnitId
        [self.adUnitIdToRewardedVideoAd setObject:rewardedVideoAd forKey:adUnitId];
        
        // get delegate
        ISLiftoffRewardedVideoListener *rewardedVideoDelegate = [self.rewardedVideoAdUnitIdToListener objectForKey:adUnitId];
        rewardedVideoAd.delegate = rewardedVideoDelegate;
        [rewardedVideoAd requestAd:serverData];
    }];
}

- (BOOL)hasRewardedVideoWithAdapterConfig:(ISAdapterConfig *)adapterConfig {
    NSString *adUnitId = adapterConfig.settings[kAdUnitId];
    NSNumber *available = [self.rewardedVideoAdsAvailability objectForKey:adUnitId];
    return (available != nil) && [available boolValue];
}

- (void)showRewardedVideoWithViewController:(UIViewController *)viewController
                              adapterConfig:(ISAdapterConfig *)adapterConfig
                                   delegate:(id<ISRewardedVideoAdapterDelegate>)delegate {
    dispatch_async(dispatch_get_main_queue(), ^{
        NSString *adUnitId = adapterConfig.settings[kAdUnitId];
        
        LogAdapterApi_Internal(@"adUnitId = %@", adUnitId);
        
        [delegate adapterRewardedVideoHasChangedAvailability:NO];

        if ([self hasRewardedVideoWithAdapterConfig:adapterConfig]) {
            
            // set availability false for this ad
            [self.rewardedVideoAdsAvailability setObject:@NO forKey:adUnitId];
            
            LOInterstitial *rewardedVideoAd = [self.adUnitIdToRewardedVideoAd objectForKey:adUnitId];
            [rewardedVideoAd showAdWith:viewController];
        } else {
            NSError *error = [NSError errorWithDomain:kAdapterName code:ERROR_CODE_NO_ADS_TO_SHOW userInfo:@{NSLocalizedDescriptionKey:@"ISLiftoff showRewardedVideoWithViewController"}];
            LogAdapterApi_Internal(@"error = %@", error);
            [delegate adapterRewardedVideoDidFailToShowWithError:error];
        }
    });
}

- (NSDictionary *)getRewardedVideoBiddingDataWithAdapterConfig:(ISAdapterConfig *)adapterConfig {
    LogAdapterApi_Internal(@"");
    return [self getBiddingData];
}

#pragma mark - Rewarded Video Delegate

- (void)onRewardedVideoLoadSuccess:(LOInterstitial *)rewardedVideoAd {
    NSString *adUnitId = [self.rewardedVideoAdToAdUnitId objectForKey:rewardedVideoAd];
    LogAdapterDelegate_Internal(@"adUnitId = %@", adUnitId);
    
    // set availability true for this ad
    [self.rewardedVideoAdsAvailability setObject:@YES forKey:adUnitId];

    // call delegate
    id<ISRewardedVideoAdapterDelegate> delegate = [self.adUnitIdToRewardedVideoSmashDelegate objectForKey:adUnitId];
    
    if (delegate) {
        [delegate adapterRewardedVideoHasChangedAvailability:YES];
    }
}

- (void)onRewardedVideoLoadFail:(LOInterstitial *)rewardedVideoAd {
    NSString *adUnitId = [self.rewardedVideoAdToAdUnitId objectForKey:rewardedVideoAd];
    LogAdapterDelegate_Internal(@"adUnitId = %@", adUnitId);
    
    // set availability false for this ad
    [self.rewardedVideoAdsAvailability setObject:@NO forKey:adUnitId];

    // call delegate
    id<ISRewardedVideoAdapterDelegate> delegate = [self.adUnitIdToRewardedVideoSmashDelegate objectForKey:adUnitId];
    
    if (delegate) {
        [delegate adapterRewardedVideoHasChangedAvailability:NO];
    }
}

- (void)onRewardedVideoShowFail:(LOInterstitial *)rewardedVideoAd {
    NSString *adUnitId = [self.rewardedVideoAdToAdUnitId objectForKey:rewardedVideoAd];
    LogAdapterDelegate_Internal(@"adUnitId = %@", adUnitId);

    // call delegate
    id<ISRewardedVideoAdapterDelegate> delegate = [self.adUnitIdToRewardedVideoSmashDelegate objectForKey:adUnitId];
    
    if (delegate) {
        NSError *error = [NSError errorWithDomain:kAdapterName code:ERROR_CODE_GENERIC userInfo:@{NSLocalizedDescriptionKey:@"ISLiftoff onRewardedVideoShowFail"}];
        [delegate adapterRewardedVideoDidFailToShowWithError:error];
    }
}


- (void)onRewardedVideoDidOpen:(LOInterstitial *)rewardedVideoAd {
    NSString *adUnitId = [self.rewardedVideoAdToAdUnitId objectForKey:rewardedVideoAd];
    LogAdapterDelegate_Internal(@"adUnitId = %@", adUnitId);

    // call delegate
    id<ISRewardedVideoAdapterDelegate> delegate = [self.adUnitIdToRewardedVideoSmashDelegate objectForKey:adUnitId];
    
    if (delegate) {
        [delegate adapterRewardedVideoDidOpen];
    }
}

- (void)onRewardedVideoDidShow:(LOInterstitial *)rewardedVideoAd {
    NSString *adUnitId = [self.rewardedVideoAdToAdUnitId objectForKey:rewardedVideoAd];
    LogAdapterDelegate_Internal(@"adUnitId = %@", adUnitId);

    // call delegate
    id<ISRewardedVideoAdapterDelegate> delegate = [self.adUnitIdToRewardedVideoSmashDelegate objectForKey:adUnitId];
    
    if (delegate) {
        [delegate adapterRewardedVideoDidStart];
    }
}

- (void)onRewardedVideoDidClick:(LOInterstitial *)rewardedVideoAd {
    NSString *adUnitId = [self.rewardedVideoAdToAdUnitId objectForKey:rewardedVideoAd];
    LogAdapterDelegate_Internal(@"adUnitId = %@", adUnitId);

    // call delegate
    id<ISRewardedVideoAdapterDelegate> delegate = [self.adUnitIdToRewardedVideoSmashDelegate objectForKey:adUnitId];
    
    if (delegate) {
        [delegate adapterRewardedVideoDidClick];
    }
}

- (void)onRewardedVideoDidReceiveReward:(LOInterstitial *)rewardedVideoAd {
    NSString *adUnitId = [self.rewardedVideoAdToAdUnitId objectForKey:rewardedVideoAd];
    LogAdapterDelegate_Internal(@"adUnitId = %@", adUnitId);

    // call delegate
    id<ISRewardedVideoAdapterDelegate> delegate = [self.adUnitIdToRewardedVideoSmashDelegate objectForKey:adUnitId];
    
    if (delegate) {
        [delegate adapterRewardedVideoDidReceiveReward];
    }
}

- (void)onRewardedVideoDidClose:(LOInterstitial *)rewardedVideoAd {
    NSString *adUnitId = [self.rewardedVideoAdToAdUnitId objectForKey:rewardedVideoAd];
    LogAdapterDelegate_Internal(@"adUnitId = %@", adUnitId);

    // call delegate
    id<ISRewardedVideoAdapterDelegate> delegate = [self.adUnitIdToRewardedVideoSmashDelegate objectForKey:adUnitId];
    
    if (delegate) {
        [delegate adapterRewardedVideoDidEnd];
        [delegate adapterRewardedVideoDidClose];
    }
}

#pragma mark - Interstitial

- (void)initInterstitialForBiddingWithUserId:(NSString *)userId
                               adapterConfig:(ISAdapterConfig *)adapterConfig
                                    delegate:(id<ISInterstitialAdapterDelegate>)delegate {
    if (delegate == nil) {
        LogAdapterApi_Internal(@"delegate == nil");
        return;
    }
    
    NSString *apiKey = adapterConfig.settings[kApiKey];
    NSString *adUnitId = adapterConfig.settings[kAdUnitId];

    // Configuration Validation
    if (![self isConfigValueValid:apiKey]) {
        NSError *error = [self errorForMissingCredentialFieldWithName:kApiKey];
        LogAdapterApi_Internal(@"error = %@", error);
        [delegate adapterInterstitialInitFailedWithError:error];
        return;
    }
    
    if (![self isConfigValueValid:adUnitId]) {
        NSError *error = [self errorForMissingCredentialFieldWithName:kAdUnitId];
        LogAdapterApi_Internal(@"error = %@", error);
        [delegate adapterInterstitialInitFailedWithError:error];
        return;
    }
    
    LogAdapterApi_Internal(@"adUnitId = %@", adUnitId);
    
    // Register Smash for adUnitId
    [self.adUnitIdToInterstitialSmashDelegate setObject:delegate forKey:adUnitId];
    
    // Create delegate
    ISLiftoffInterstitialListener *interstitialDelegate = [[ISLiftoffInterstitialListener alloc] initWithDelegate:self];
    [self.interstitialAdUnitIdToListener setObject:interstitialDelegate forKey:adUnitId];
    
    [self initSDKWithApiKey:apiKey];
    [delegate adapterInterstitialInitSuccess];
}

- (void)loadInterstitialForBiddingWithServerData:(NSString *)serverData
                                   adapterConfig:(ISAdapterConfig *)adapterConfig
                                        delegate:(id<ISInterstitialAdapterDelegate>)delegate {
    // validate adUnitId
    NSString *adUnitId = adapterConfig.settings[kAdUnitId];
    
    if (![self isConfigValueValid:adUnitId]) {
        NSError *error = [self errorForMissingCredentialFieldWithName:kAdUnitId];
        LogAdapterApi_Internal(@"error = %@", error);
        [delegate adapterInterstitialDidFailToLoadWithError:error];
        return;
    }
    
    LogInternal_Internal(@"adUnitId = %@", adUnitId);
    
    // set availability false for this ad
    [self.interstitialAdsAvailability setObject:@NO forKey:adUnitId];
    
    [self.dispatcher dispatchAsyncWithQueue:dispatch_get_main_queue() withBlock:^{
        // create ad
        LOInterstitial *interstitialAd = [Liftoff initInterstitialAdUnitFor:adUnitId];
        
        // add interstitial to map table to so we may use it to extract the adUnitId later on
        [self.interstitialAdToAdUnitId setObject:adUnitId forKey:interstitialAd];
        
        // add interstitial to dictionary so we may extract it later using the adUnitId
        [self.adUnitIdToInterstitialAd setObject:interstitialAd forKey:adUnitId];
        
        // get delegate
        ISLiftoffInterstitialListener *interstitialDelegate = [self.interstitialAdUnitIdToListener objectForKey:adUnitId];
        interstitialAd.delegate = interstitialDelegate;
        [interstitialAd requestAd:serverData];
    }];
}

- (BOOL)hasInterstitialWithAdapterConfig:(ISAdapterConfig *)adapterConfig {
    NSString *adUnitId = adapterConfig.settings[kAdUnitId];
    NSNumber *available = [self.interstitialAdsAvailability objectForKey:adUnitId];
    return (available != nil) && [available boolValue];
}

- (void)showInterstitialWithViewController:(UIViewController *)viewController
                             adapterConfig:(ISAdapterConfig *)adapterConfig
                                  delegate:(id<ISInterstitialAdapterDelegate>)delegate {
    dispatch_async(dispatch_get_main_queue(), ^{
        NSString *adUnitId = adapterConfig.settings[kAdUnitId];
        
        LogAdapterApi_Internal(@"adUnitId = %@", adUnitId);

        if ([self hasInterstitialWithAdapterConfig:adapterConfig]) {
            
            // set availability false for this ad
            [self.interstitialAdsAvailability setObject:@NO forKey:adUnitId];
            
            LOInterstitial *interstitialAd = [self.adUnitIdToInterstitialAd objectForKey:adUnitId];
            [interstitialAd showAdWith:viewController];
        } else {
            NSError *error = [NSError errorWithDomain:kAdapterName code:ERROR_CODE_NO_ADS_TO_SHOW userInfo:@{NSLocalizedDescriptionKey:@"ISLiftoff showInterstitialWithViewController"}];
            LogAdapterApi_Internal(@"error = %@", error);
            [delegate adapterInterstitialDidFailToShowWithError:error];
        }
    });
}

- (NSDictionary *)getInterstitialBiddingDataWithAdapterConfig:(ISAdapterConfig *)adapterConfig {
    LogAdapterApi_Internal(@"");
    return [self getBiddingData];
}

#pragma mark - Interstitial Delegate

- (void)onInterstitialLoadSuccess:(LOInterstitial *)interstitialAd {
    NSString *adUnitId = [self.interstitialAdToAdUnitId objectForKey:interstitialAd];
    LogAdapterDelegate_Internal(@"adUnitId = %@", adUnitId);
    
    // set availability true for this ad
    [self.interstitialAdsAvailability setObject:@YES forKey:adUnitId];

    // call delegate
    id<ISInterstitialAdapterDelegate> delegate = [self.adUnitIdToInterstitialSmashDelegate objectForKey:adUnitId];
    
    if (delegate) {
        [delegate adapterInterstitialDidLoad];
    }
}

- (void)onInterstitialLoadFail:(LOInterstitial *)interstitialAd {
    NSString *adUnitId = [self.interstitialAdToAdUnitId objectForKey:interstitialAd];
    LogAdapterDelegate_Internal(@"adUnitId = %@", adUnitId);
    
    // set availability false for this ad
    [self.interstitialAdsAvailability setObject:@NO forKey:adUnitId];
    
    // call delegate
    id<ISInterstitialAdapterDelegate> delegate = [self.adUnitIdToInterstitialSmashDelegate objectForKey:adUnitId];
    
    if (delegate) {
        NSError *error = [ISError createError:ERROR_CODE_GENERIC withMessage:[NSString stringWithFormat:@"Liftoff load failed"]];
        [delegate adapterInterstitialDidFailToLoadWithError:error];
    }
}

- (void)onInterstitialShowFail:(LOInterstitial *)interstitialAd {
    NSString *adUnitId = [self.interstitialAdToAdUnitId objectForKey:interstitialAd];
    LogAdapterDelegate_Internal(@"adUnitId = %@", adUnitId);
    
    // call delegate
    id<ISInterstitialAdapterDelegate> delegate = [self.adUnitIdToInterstitialSmashDelegate objectForKey:adUnitId];
    
    if (delegate) {
        NSError *error = [NSError errorWithDomain:kAdapterName code:ERROR_CODE_GENERIC userInfo:@{NSLocalizedDescriptionKey:@"ISLiftoff onInterstitialShowFail"}];
        [delegate adapterInterstitialDidFailToShowWithError:error];
    }
}

- (void)onInterstitialDidClick:(LOInterstitial *)interstitialAd {
    NSString *adUnitId = [self.interstitialAdToAdUnitId objectForKey:interstitialAd];
    LogAdapterDelegate_Internal(@"adUnitId = %@", adUnitId);
    
    // call delegate
    id<ISInterstitialAdapterDelegate> delegate = [self.adUnitIdToInterstitialSmashDelegate objectForKey:adUnitId];
    
    if (delegate) {
        [delegate adapterInterstitialDidClick];
    }
}

- (void)onInterstitialDidOpen:(LOInterstitial *)interstitialAd {
    NSString *adUnitId = [self.interstitialAdToAdUnitId objectForKey:interstitialAd];
    LogAdapterDelegate_Internal(@"adUnitId = %@", adUnitId);
    
    // call delegate
    id<ISInterstitialAdapterDelegate> delegate = [self.adUnitIdToInterstitialSmashDelegate objectForKey:adUnitId];
    
    if (delegate) {
        [delegate adapterInterstitialDidOpen];
    }
}

- (void)onInterstitialDidShow:(LOInterstitial *)interstitialAd {
    NSString *adUnitId = [self.interstitialAdToAdUnitId objectForKey:interstitialAd];
    LogAdapterDelegate_Internal(@"adUnitId = %@", adUnitId);
    
    // call delegate
    id<ISInterstitialAdapterDelegate> delegate = [self.adUnitIdToInterstitialSmashDelegate objectForKey:adUnitId];
    
    if (delegate) {
        [delegate adapterInterstitialDidShow];
    }
}

- (void)onInterstitialDidClose:(LOInterstitial *)interstitialAd {
    NSString *adUnitId = [self.interstitialAdToAdUnitId objectForKey:interstitialAd];
    LogAdapterDelegate_Internal(@"adUnitId = %@", adUnitId);
    
    // call delegate
    id<ISInterstitialAdapterDelegate> delegate = [self.adUnitIdToInterstitialSmashDelegate objectForKey:adUnitId];
    
    if (delegate) {
        [delegate adapterInterstitialDidClose];
    }
}

#pragma mark - Banner


- (void)initBannerForBiddingWithUserId:(NSString *)userId adapterConfig:(ISAdapterConfig *)adapterConfig delegate:(id<ISBannerAdapterDelegate>)delegate {
    
    if (delegate == nil) {
        LogAdapterApi_Internal(@"delegate == nil");
        return;
    }
    
    NSString *apiKey = adapterConfig.settings[kApiKey];
    NSString *adUnitId = adapterConfig.settings[kAdUnitId];

    // Configuration Validation
    if (![self isConfigValueValid:apiKey]) {
        NSError *error = [self errorForMissingCredentialFieldWithName:kApiKey];
        LogAdapterApi_Internal(@"error = %@", error);
        [delegate adapterBannerInitFailedWithError:error];
        return;
    }
    
    if (![self isConfigValueValid:adUnitId]) {
        NSError *error = [self errorForMissingCredentialFieldWithName:kAdUnitId];
        LogAdapterApi_Internal(@"error = %@", error);
        [delegate adapterBannerInitFailedWithError:error];
        return;
    }
    
    LogAdapterApi_Internal(@"adUnitId = %@", adUnitId);
    
    // Register Smash for adUnitId
    [self.adUnitIdToBannerSmashDelegate setObject:delegate forKey:adUnitId];
    
    // Create delegate
    ISLiftoffBannerListener *bannerDelegate = [[ISLiftoffBannerListener alloc] initWithDelegate:self];
    [self.bannerAdUnitIdToListener setObject:bannerDelegate forKey:adUnitId];
    
    [self initSDKWithApiKey:apiKey];
    [delegate adapterBannerInitSuccess];
}

- (void)loadBannerForBiddingWithServerData:(NSString *)serverData viewController:(UIViewController *)viewController size:(ISBannerSize *)size adapterConfig:(ISAdapterConfig *)adapterConfig delegate:(id<ISBannerAdapterDelegate>)delegate {
    NSString *adUnitId = adapterConfig.settings[kAdUnitId];
    
    // verify that the adUnitId is not empty
    if (![self isConfigValueValid:adUnitId]) {
        NSError *error = [self errorForMissingCredentialFieldWithName:kAdUnitId];
        LogAdapterApi_Internal(@"error = %@", error);
        [delegate adapterBannerDidFailToLoadWithError:error];
        return;
    }
    
    LogAdapterApi_Internal(@"adUnitId = %@", adUnitId);
    
    // get banner size
    CGSize bannerSize = [self getBannerSize:size];

    dispatch_async(dispatch_get_main_queue(), ^{
        //create banner view
        LOBanner *bannerView = [Liftoff initBannerAdUnitFor:adUnitId size:bannerSize];
        
        // add banner view to map table to so we may use it to extract the adUnitId later on
        [self.bannerAdToAdUnitId setObject:adUnitId forKey:bannerView];
        
        // add banner view to dictionary so we may extract it later using the adUnitId
        [self.adUnitIdToBannerAd setObject:bannerView forKey:adUnitId];
        
        // get delegate
        ISLiftoffBannerListener *bannerDelegate = [self.bannerAdUnitIdToListener objectForKey:adUnitId];
        bannerView.delegate = bannerDelegate;
        [bannerView requestAd:serverData];
    });
}

- (void)reloadBannerWithAdapterConfig:(ISAdapterConfig *)adapterConfig delegate:(id<ISBannerAdapterDelegate>)delegate {
    LogInternal_Warning(@"Unsupported method");
}

- (void)destroyBannerWithAdapterConfig:(ISAdapterConfig *)adapterConfig {
    NSString *adUnitId = adapterConfig.settings[kAdUnitId];
    LogAdapterApi_Internal(@"adUnitId = %@", adUnitId);

    LOBanner *bannerView = [_adUnitIdToBannerAd objectForKey:adUnitId];
    
    if (bannerView != nil) {
        // remove banner from the map
        [_adUnitIdToBannerAd removeObjectForKey:adUnitId];
        [_adUnitIdToBannerSmashDelegate removeObjectForKey:adUnitId];
    }
}

- (NSDictionary *)getBannerBiddingDataWithAdapterConfig:(ISAdapterConfig *)adapterConfig {
    LogAdapterApi_Internal(@"");
    return [self getBiddingData];
}

- (BOOL)shouldBindBannerViewOnReload {
    return YES;
}


#pragma mark - Banner Delegate

- (void)onBannerLoadSuccess:(LOBanner *)bannerAd withView:(UIView *)bannerView {
    NSString *adUnitId = [self.bannerAdToAdUnitId objectForKey:bannerAd];
    LogAdapterDelegate_Internal(@"adUnitId = %@", adUnitId);
    
    // call delegate
    id<ISBannerAdapterDelegate> delegate = [self.adUnitIdToBannerSmashDelegate objectForKey:adUnitId];
    
    if (delegate) {
        [delegate adapterBannerDidLoad:bannerView];
    }
}

- (void)onBannerLoadFail:(LOBanner *)bannerAd {
    NSString *adUnitId = [self.bannerAdToAdUnitId objectForKey:bannerAd];
    LogAdapterDelegate_Internal(@"adUnitId = %@", adUnitId);
    
    // call delegate
    id<ISBannerAdapterDelegate> delegate = [self.adUnitIdToBannerSmashDelegate objectForKey:adUnitId];
    
    if (delegate) {
        NSError *error = [[NSError alloc] initWithDomain:kAdapterName code:ERROR_CODE_GENERIC userInfo:@{NSLocalizedDescriptionKey:@"Liftoff load failed"}];
        [delegate adapterBannerDidFailToLoadWithError:error];
    }
}

- (void)onBannerShowFail:(LOBanner *)bannerAd {
    NSString *adUnitId = [self.bannerAdToAdUnitId objectForKey:bannerAd];
    LogAdapterDelegate_Internal(@"adUnitId = %@", adUnitId);
}

- (void)onBannerDidShow:(LOBanner *)bannerAd {
    NSString *adUnitId = [self.bannerAdToAdUnitId objectForKey:bannerAd];
    LogAdapterDelegate_Internal(@"adUnitId = %@", adUnitId);
    
    // call delegate
    id<ISBannerAdapterDelegate> delegate = [self.adUnitIdToBannerSmashDelegate objectForKey:adUnitId];
    
    if (delegate) {
        [delegate adapterBannerDidShow];
    }
}

- (void)onBannerDidClick:(LOBanner *)bannerAd {
    NSString *adUnitId = [self.bannerAdToAdUnitId objectForKey:bannerAd];
    LogAdapterDelegate_Internal(@"adUnitId = %@", adUnitId);
    
    // call delegate
    id<ISBannerAdapterDelegate> delegate = [self.adUnitIdToBannerSmashDelegate objectForKey:adUnitId];
    
    if (delegate) {
        [delegate adapterBannerDidClick];
    }
}

- (void)onBannerBannerWillLeaveApplication:(LOBanner *)bannerAd {
    NSString *adUnitId = [self.bannerAdToAdUnitId objectForKey:bannerAd];
    LogAdapterDelegate_Internal(@"adUnitId = %@", adUnitId);
    
    // call delegate
    id<ISBannerAdapterDelegate> delegate = [self.adUnitIdToBannerSmashDelegate objectForKey:adUnitId];
    
    if (delegate) {
        [delegate adapterBannerWillLeaveApplication];
    }
}

- (void)onBannerWillPresentScreen:(LOBanner *)bannerAd {
    NSString *adUnitId = [self.bannerAdToAdUnitId objectForKey:bannerAd];
    LogAdapterDelegate_Internal(@"adUnitId = %@", adUnitId);
    
    // call delegate
    id<ISBannerAdapterDelegate> delegate = [self.adUnitIdToBannerSmashDelegate objectForKey:adUnitId];
    
    if (delegate) {
        [delegate adapterBannerWillPresentScreen];
    }
}

- (void)onBannerDidDismissScreen:(LOBanner *)bannerAd {
    NSString *adUnitId = [self.bannerAdToAdUnitId objectForKey:bannerAd];
    LogAdapterDelegate_Internal(@"adUnitId = %@", adUnitId);
    
    // call delegate
    id<ISBannerAdapterDelegate> delegate = [self.adUnitIdToBannerSmashDelegate objectForKey:adUnitId];
    
    if (delegate) {
        [delegate adapterBannerDidDismissScreen];
    }
}

#pragma mark - Private Methods

- (void)initSDKWithApiKey:(NSString *)apiKey {
    LogAdapterApi_Internal(@"");
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        dispatch_async(dispatch_get_main_queue(), ^{
            if ([ISConfigurations getConfigurations].adaptersDebug) {
                [Liftoff setLogLevel:LOLoggingLevelDebug];
            }
            
            [Liftoff initWithAPIKey:apiKey];
            isInitCompleted = YES;
        });
    });
}

#pragma mark - Helper Methods

- (NSDictionary *)getBiddingData {
    if (!isInitCompleted) {
        LogAdapterApi_Internal(@"returning nil as token since init isn't completed");
        return nil;
    }
    
    // The Liftoff token is _Nonnull so there is no need to check for a null response
    NSString *bidderToken = Liftoff.biddingToken;
    NSString *returnedToken = bidderToken ? bidderToken : @"";
    LogAdapterApi_Internal(@"token = %@", returnedToken);
    
    return @{@"token": returnedToken};
}

- (CGSize)getBannerSize:(ISBannerSize *)size {
    CGSize bannerSize = LOConstants.flexAll;

    if ([size.sizeDescription isEqualToString:@"BANNER"]) {
        bannerSize = LOConstants.phoneBanner;
    } else if ([size.sizeDescription isEqualToString:@"RECTANGLE"]) {
        bannerSize = LOConstants.mediumRectangle;
    } else if ([size.sizeDescription isEqualToString:@"SMART"]) {
        if (UI_USER_INTERFACE_IDIOM() == UIUserInterfaceIdiomPad) {
            bannerSize = LOConstants.tabletBanner;
        } else {
            bannerSize = LOConstants.phoneBanner;
        }
    } else if ([size.sizeDescription isEqualToString:@"CUSTOM"]) {
        bannerSize = CGSizeMake(size.width, size.height);
    }

    return bannerSize;
}

@end
