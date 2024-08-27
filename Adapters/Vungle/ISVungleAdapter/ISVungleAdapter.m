//
//  ISVungleAdapter.m
//  ISVungleAdapter
//
//  Copyright © 2024 ironSource Mobile Ltd. All rights reserved.
//

#import <ISVungleAdapter.h>
#import "ISVungleConstant.h"
#import <ISVungleRewardedVideoDelegate.h>
#import <ISVungleInterstitialDelegate.h>
#import <ISVungleBannerDelegate.h>
#import <VungleAdsSDK/VungleAdsSDK.h>

@interface ISVungleAdapter ()

// Rewarded video
@property (nonatomic, strong) ISConcurrentMutableDictionary   *rewardedVideoPlacementIdToAd;

// Interstitial
@property (nonatomic, strong) ISConcurrentMutableDictionary   *interstitialPlacementIdToAd;

// Banner
@property (nonatomic, strong) ISConcurrentMutableDictionary   *bannerPlacementIdToAd;
@property (nonatomic, strong) ISConcurrentMutableDictionary   *bannerPlacementIdToAdSize;

@end

@implementation ISVungleAdapter

#pragma mark - IronSource Protocol Methods

// Get adapter version
- (NSString *)version {
    return VungleAdapterVersion;
}

// Get network sdk version
- (NSString *)sdkVersion {
    return [VungleAds sdkVersion];
}

#pragma mark - Initializations Methods And Callbacks
- (instancetype)initAdapter:(NSString *)name {
    self = [super initAdapter:name];
    
    if (self) {
        // Rewarded video
        _rewardedVideoPlacementIdToAd                    = [ISConcurrentMutableDictionary dictionary];

        // Interstitial
        _interstitialPlacementIdToAd                     = [ISConcurrentMutableDictionary dictionary];

        // Banner
        _bannerPlacementIdToAd                           = [ISConcurrentMutableDictionary dictionary];
        _bannerPlacementIdToAdSize                       = [ISConcurrentMutableDictionary dictionary];

        // The network's capability to load a Rewarded Video ad while another Rewarded Video ad of that network is showing
        LWSState = LOAD_WHILE_SHOW_BY_INSTANCE;
    }

    return self;
}

- (void)initSDKWithAppId:(NSString *)appId
       successCompletion:(void (^)(void))successCompletion
       errorCompletion:(void (^)(NSError *))errorCompletion {
    LogAdapterApi_Internal(@"appId = %@", appId);

    [VungleAds setIntegrationName:kMediationName
                          version:[self version]];
    ISVungleAdapter * __weak weakSelf = self;

    [VungleAds initWithAppId:appId
                  completion:^(NSError * _Nullable error) {
        dispatch_async(dispatch_get_main_queue(), ^{

            __typeof__(self) strongSelf = weakSelf;

            if (error) {
                NSString *errorMsg = [NSString stringWithFormat:@"Vungle SDK init failed %@", error.description];
                LogAdapterDelegate_Internal(@"error = %@", errorMsg);
                if (errorCompletion) {
                    NSError *error = [ISError createErrorWithDomain:kAdapterName
                                                               code:ERROR_CODE_INIT_FAILED
                                                            message:errorMsg];
                    errorCompletion(error);
                }
            } else {
                if (successCompletion) {
                    successCompletion();
                }
            }
        });
    }];
}

#pragma mark - Rewarded Video API

// Used for flows when the mediation needs to get a callback for init
- (void)initRewardedVideoForCallbacksWithUserId:(NSString *)userId
                                  adapterConfig:(ISAdapterConfig *)adapterConfig
                                       delegate:(id<ISRewardedVideoAdapterDelegate>)delegate {

    NSString *appId = adapterConfig.settings[kAppId];
    NSString *placementId = adapterConfig.settings[kPlacementId];

    /* Configuration Validation */
    if (![self isConfigValueValid:appId]) {
        NSError *error = [self errorForMissingCredentialFieldWithName:kAppId];
        LogAdapterApi_Internal(@"error = %@", error.description);

        [delegate adapterRewardedVideoInitFailed:error];
        return;
    }

    if (![self isConfigValueValid:placementId]) {
        NSError *error = [self errorForMissingCredentialFieldWithName:kPlacementId];
        LogAdapterApi_Internal(@"error = %@", error.description);

        [delegate adapterRewardedVideoInitFailed:error];
        return;
    }

    LogAdapterApi_Internal(@"placementId = %@", placementId);

    [self initSDKWithAppId:appId
         successCompletion:^{
        [delegate adapterRewardedVideoInitSuccess];
    }
           errorCompletion:^(NSError * error) {
        [delegate adapterRewardedVideoInitFailed:error];
    }];
}

// Used for flows when the mediation doesn't need to get a callback for init
- (void)initAndLoadRewardedVideoWithUserId:(NSString *)userId
                             adapterConfig:(ISAdapterConfig *)adapterConfig
                                    adData:(NSDictionary *)adData
                                  delegate:(id<ISRewardedVideoAdapterDelegate>)delegate {
    NSString *appId = adapterConfig.settings[kAppId];
    NSString *placementId = adapterConfig.settings[kPlacementId];

    /* Configuration Validation */
    if (![self isConfigValueValid:appId]) {
        NSError *error = [self errorForMissingCredentialFieldWithName:kAppId];
        LogAdapterApi_Internal(@"error = %@", error.description);
        [delegate adapterRewardedVideoHasChangedAvailability:NO];
        return;
    }

    if (![self isConfigValueValid:placementId]) {
        NSError *error = [self errorForMissingCredentialFieldWithName:kPlacementId];
        LogAdapterApi_Internal(@"error = %@", error.description);
        [delegate adapterRewardedVideoHasChangedAvailability:NO];
        return;
    }

    LogAdapterApi_Internal(@"placementId = %@", placementId);
    
    [self initSDKWithAppId:appId
         successCompletion:^{
        [self loadRewardedVideoInternal:placementId
                             serverData:nil
                               delegate:delegate];
    }
           errorCompletion:^(NSError * error) {
        [delegate adapterRewardedVideoHasChangedAvailability:NO];
    }];
}

- (void)loadRewardedVideoForBiddingWithAdapterConfig:(ISAdapterConfig *)adapterConfig
                                              adData:(NSDictionary *)adData
                                          serverData:(NSString *)serverData
                                            delegate:(id<ISRewardedVideoAdapterDelegate>)delegate {
    NSString *placementId = adapterConfig.settings[kPlacementId];
    [self loadRewardedVideoInternal:placementId
                         serverData:serverData
                           delegate:delegate];
}

- (void)loadRewardedVideoWithAdapterConfig:(ISAdapterConfig *)adapterConfig
                                    adData:(NSDictionary *)adData
                                  delegate:(id<ISRewardedVideoAdapterDelegate>)delegate {
    NSString *placementId = adapterConfig.settings[kPlacementId];
    [self loadRewardedVideoInternal:placementId
                         serverData:nil
                           delegate:delegate];
}

- (void)loadRewardedVideoInternal:(NSString *)placementId
                       serverData:(NSString *)serverData
                         delegate:(id<ISRewardedVideoAdapterDelegate>)delegate {

    LogAdapterApi_Internal(@"placementId = %@", placementId);

    ISVungleRewardedVideoDelegate *rewardedVideoAdDelegate = [[ISVungleRewardedVideoDelegate alloc] initWithPlacementId:placementId
                                                                                                            andDelegate:delegate];

    VungleRewarded *rewardedVideoAd = [[VungleRewarded alloc] initWithPlacementId:placementId];
    rewardedVideoAd.delegate = rewardedVideoAdDelegate;

    // Add rewarded video ad to dictionary
    [self.rewardedVideoPlacementIdToAd setObject:rewardedVideoAd
                                          forKey:placementId];
    
    [rewardedVideoAd load:serverData];
}

- (void)showRewardedVideoWithViewController:(UIViewController *)viewController
                              adapterConfig:(ISAdapterConfig *)adapterConfig
                                   delegate:(id<ISRewardedVideoAdapterDelegate>)delegate {

    NSString *placementId = adapterConfig.settings[kPlacementId];
    LogAdapterApi_Internal(@"placementId = %@", placementId);

    if (![self hasRewardedVideoWithAdapterConfig:adapterConfig]) {
        NSError *error = [ISError createError:ERROR_CODE_NO_ADS_TO_SHOW
                                  withMessage:[NSString stringWithFormat: @"%@ show failed", kAdapterName]];
        LogAdapterApi_Internal(@"error = %@", error);
        [delegate adapterRewardedVideoDidFailToShowWithError:error];
        return;
    }
    
    VungleRewarded *rewardedVideoAd = [self.rewardedVideoPlacementIdToAd objectForKey:placementId];
    
    //set dynamic user Id
    if ([self dynamicUserId]) {
        LogAdapterApi_Internal(@"set userID to %@", [self dynamicUserId]);
        [rewardedVideoAd setUserIdWithUserId:self.dynamicUserId];
    }
    
    dispatch_async(dispatch_get_main_queue(), ^{
        [rewardedVideoAd presentWith:viewController];
    });
}

- (BOOL)hasRewardedVideoWithAdapterConfig:(ISAdapterConfig *)adapterConfig {
    NSString *placementId = adapterConfig.settings[kPlacementId];
    VungleRewarded *rewardedVideoAd = [self.rewardedVideoPlacementIdToAd objectForKey:placementId];
    return rewardedVideoAd != nil && [rewardedVideoAd canPlayAd];
}

- (NSDictionary *)getRewardedVideoBiddingDataWithAdapterConfig:(ISAdapterConfig *)adapterConfig
                                                        adData:(NSDictionary *)adData {
    NSString *placementId = adapterConfig.settings[kPlacementId];
    return [self getBiddingDataWithPlacementId:placementId];
}

#pragma mark - Interstitial API

- (void)initInterstitialForBiddingWithUserId:(NSString *)userId
                               adapterConfig:(ISAdapterConfig *)adapterConfig
                                    delegate:(id<ISInterstitialAdapterDelegate>)delegate {

    [self initInterstitialWithUserId:userId
                       adapterConfig:adapterConfig
                            delegate:delegate];
}
- (void)initInterstitialWithUserId:(NSString *)userId
                     adapterConfig:(ISAdapterConfig *)adapterConfig
                          delegate:(id<ISInterstitialAdapterDelegate>)delegate {

    NSString *appId = adapterConfig.settings[kAppId];
    NSString *placementId = adapterConfig.settings[kPlacementId];

    // Configuration Validation
    if (![self isConfigValueValid:appId]) {
        NSError *error = [self errorForMissingCredentialFieldWithName:kAppId];
        LogAdapterApi_Internal(@"error = %@", error.description);
        [delegate adapterInterstitialInitFailedWithError:error];
        return;
    }

    if (![self isConfigValueValid:placementId]) {
        NSError *error = [self errorForMissingCredentialFieldWithName:kPlacementId];
        LogAdapterApi_Internal(@"error = %@", error.description);

        [delegate adapterInterstitialInitFailedWithError:error];
        return;
    }

    LogAdapterApi_Internal(@"placementId = %@", placementId);

    [self initSDKWithAppId:appId
         successCompletion:^{
        [delegate adapterInterstitialInitSuccess];
    }
           errorCompletion:^(NSError * error) {
        [delegate adapterInterstitialInitFailedWithError:error];
    }];
}
- (void)loadInterstitialForBiddingWithAdapterConfig:(ISAdapterConfig *)adapterConfig
                                             adData:(NSDictionary *)adData
                                         serverData:(NSString *)serverData
                                           delegate:(id<ISInterstitialAdapterDelegate>)delegate {

    NSString *placementId = adapterConfig.settings[kPlacementId];
    [self loadInterstitialInternal:placementId
                        serverData:serverData
                          delegate:delegate];
}

- (void)loadInterstitialWithAdapterConfig:(ISAdapterConfig *)adapterConfig
                                   adData:(NSDictionary *)adData
                                 delegate:(id<ISInterstitialAdapterDelegate>)delegate {

    NSString *placementId = adapterConfig.settings[kPlacementId];
    [self loadInterstitialInternal:placementId
                        serverData:nil
                          delegate:delegate];
}

- (void)loadInterstitialInternal:(NSString *)placementId
                      serverData:(NSString *)serverData
                        delegate:(id<ISInterstitialAdapterDelegate>)delegate {

    LogAdapterApi_Internal(@"placementId = %@", placementId);

    ISVungleInterstitialDelegate *interstitialAdDelegate = [[ISVungleInterstitialDelegate alloc] initWithPlacementId:placementId
                                                                                                         andDelegate:delegate];

    VungleInterstitial *interstitialAd = [[VungleInterstitial alloc] initWithPlacementId:placementId];
    interstitialAd.delegate = interstitialAdDelegate;

    // Add interstitial ad to dictionary
    [self.interstitialPlacementIdToAd setObject:interstitialAd
                                         forKey:placementId];
    
    [interstitialAd load:serverData];
}

- (void)showInterstitialWithViewController:(UIViewController *)viewController
                             adapterConfig:(ISAdapterConfig *)adapterConfig
                                  delegate:(id<ISInterstitialAdapterDelegate>)delegate {

    NSString *placementId = adapterConfig.settings[kPlacementId];
    LogAdapterApi_Internal(@"placementId = %@", placementId);

    if (![self hasInterstitialWithAdapterConfig:adapterConfig]) {
        NSError *error = [ISError createError:ERROR_CODE_NO_ADS_TO_SHOW
                                  withMessage:[NSString stringWithFormat: @"%@ show failed", kAdapterName]];
        LogAdapterApi_Internal(@"error = %@", error);
        [delegate adapterInterstitialDidFailToShowWithError:error];
        return;
    }
    
    VungleInterstitial *interstitialAd = [self.interstitialPlacementIdToAd objectForKey:placementId];
    dispatch_async(dispatch_get_main_queue(), ^{
        [interstitialAd presentWith:viewController];
    });
}

- (BOOL)hasInterstitialWithAdapterConfig:(ISAdapterConfig *)adapterConfig {
    NSString *placementId = adapterConfig.settings[kPlacementId];
    VungleInterstitial *interstitialAd = [self.interstitialPlacementIdToAd objectForKey:placementId];
    return interstitialAd != nil && [interstitialAd canPlayAd];
}

- (NSDictionary *)getInterstitialBiddingDataWithAdapterConfig:(ISAdapterConfig *)adapterConfig
                                                       adData:(NSDictionary *)adData {
    NSString *placementId = adapterConfig.settings[kPlacementId];
    return [self getBiddingDataWithPlacementId:placementId];
}

#pragma mark - Banner API


- (void)initBannerForBiddingWithUserId:(NSString *)userId
                         adapterConfig:(ISAdapterConfig *)adapterConfig
                              delegate:(id<ISBannerAdapterDelegate>)delegate {

    [self initBannerWithUserId:userId
                 adapterConfig:adapterConfig
                      delegate:delegate];
}

- (void)initBannerWithUserId:(NSString *)userId
               adapterConfig:(ISAdapterConfig *)adapterConfig
                    delegate:(id<ISBannerAdapterDelegate>)delegate {

    NSString *appId = adapterConfig.settings[kAppId];
    NSString *placementId = adapterConfig.settings[kPlacementId];

    /* Configuration Validation */
    if (![self isConfigValueValid:appId]) {
        NSError *error = [self errorForMissingCredentialFieldWithName:kAppId];
        LogAdapterApi_Internal(@"error = %@", error.description);
        [delegate adapterBannerInitFailedWithError:error];
        return;
    }

    if (![self isConfigValueValid:placementId]) {
        NSError *error = [self errorForMissingCredentialFieldWithName:kPlacementId];
        LogAdapterApi_Internal(@"error = %@", error.description);
        [delegate adapterBannerInitFailedWithError:error];
        return;
    }

    LogAdapterApi_Internal(@"placementId = %@", placementId);

    [self initSDKWithAppId:appId
         successCompletion:^{
        [delegate adapterBannerInitSuccess];
    }
           errorCompletion:^(NSError * error) {
        [delegate adapterBannerInitFailedWithError:error];
    }];
}

- (void)loadBannerForBiddingWithAdapterConfig:(ISAdapterConfig *)adapterConfig
                                       adData:(NSDictionary *)adData
                                   serverData:(NSString *)serverData
                               viewController:(UIViewController *)viewController
                                         size:(ISBannerSize *)size
                                     delegate:(id <ISBannerAdapterDelegate>)delegate {

    NSString *placementId = adapterConfig.settings[kPlacementId];
    [self loadBannerInternal:placementId
                  serverData:serverData
              viewController:viewController
                        size:size
                    delegate:delegate];
}

- (void)loadBannerWithAdapterConfig:(ISAdapterConfig *)adapterConfig
                             adData:(NSDictionary *)adData
                     viewController:(UIViewController *)viewController
                               size:(ISBannerSize *)size
                           delegate:(id <ISBannerAdapterDelegate>)delegate {

    NSString *placementId = adapterConfig.settings[kPlacementId];
    [self loadBannerInternal:placementId
                  serverData:nil
              viewController:viewController
                        size:size
                    delegate:delegate];
}

- (void)loadBannerInternal:(NSString *)placementId
                serverData:(NSString *)serverData
            viewController:(UIViewController *)viewController
                      size:(ISBannerSize *)size
                  delegate:(id <ISBannerAdapterDelegate>)delegate {
                   
    LogAdapterApi_Internal(@"placementId = %@", placementId);

    // create Vungle banner view
    dispatch_async(dispatch_get_main_queue(), ^{
        // initialize banner ad delegate
        ISVungleBannerDelegate *bannerAdDelegate = [[ISVungleBannerDelegate alloc] initWithPlacementId:placementId
                                                                                           andDelegate:delegate];

        [self.bannerPlacementIdToAdSize setObject:size
                                           forKey:placementId];

        // calculate VungleAdSize
        VungleAdSize *adSize = [self getBannerSize:size];
        
        // create vungle banner ad
        VungleBannerView *vungleBannerView = [[VungleBannerView alloc] initWithPlacementId:placementId
                                                                              vungleAdSize:adSize];
        
        // set delegate
        vungleBannerView.delegate = bannerAdDelegate;

        [self.bannerPlacementIdToAd setObject:vungleBannerView
                                       forKey:placementId];

        // load banner
        [vungleBannerView load:serverData];
    });
}

- (void)destroyBannerWithAdapterConfig:(ISAdapterConfig *)adapterConfig {
    NSString *placementId = adapterConfig.settings[kPlacementId];
    VungleBannerView *banner = [self.bannerPlacementIdToAd objectForKey:placementId];
    
    if (banner) {
        banner.delegate = nil;
        [self.bannerPlacementIdToAd removeObjectForKey:placementId];
        [self.bannerPlacementIdToAdSize removeObjectForKey:placementId];
    }
}

- (NSDictionary *)getBannerBiddingDataWithAdapterConfig:(ISAdapterConfig *)adapterConfig
                                                 adData:(NSDictionary *)adData {
    NSString *placementId = adapterConfig.settings[kPlacementId];
    return [self getBiddingDataWithPlacementId:placementId];
}

#pragma mark - Memory Handling

- (void)releaseMemoryWithAdapterConfig:(nonnull ISAdapterConfig *)adapterConfig {
    NSString *placementId = adapterConfig.settings[kPlacementId];

    if ([self.rewardedVideoPlacementIdToAd hasObjectForKey:placementId]) {
        [self.rewardedVideoPlacementIdToAd removeObjectForKey:placementId];

    } else if ([self.interstitialPlacementIdToAd hasObjectForKey:placementId]) {
        [self.interstitialPlacementIdToAd removeObjectForKey:placementId];

    } else if ([self.bannerPlacementIdToAd hasObjectForKey:placementId]) {
        [self destroyBannerWithAdapterConfig:adapterConfig];
    }
}

#pragma mark - Legal Methods

- (void)setConsent:(BOOL)consent {
    LogAdapterApi_Internal(@"consent = %@", consent ? @"YES" : @"NO");
    [VunglePrivacySettings setGDPRStatus:consent];
    [VunglePrivacySettings setGDPRMessageVersion:@""];
}

- (void)setCOPPAValue:(BOOL)value {
    LogAdapterApi_Internal(@"value = %@", value ? @"YES" : @"NO");
    [VunglePrivacySettings setCOPPAStatus:value];
}

- (void)setCCPAValue:(BOOL)value {
    // The Vungle CCPA API expects an indication if the user opts in to targeted advertising.
    // Given that this is opposite to the LevelPlay Mediation CCPA flag of do_not_sell
    // we will use the opposite value of what is passed to this method
    BOOL optIn = !value;
    LogAdapterApi_Internal(@"optIn = %@", optIn ? @"YES" : @"NO");
    [VunglePrivacySettings setCCPAStatus:optIn];
}

- (void)setMetaDataWithKey:(NSString *)key
                 andValues:(NSMutableArray *)values {

    if (values.count == 0) {
        return;
    }

    // This is an array of 1 value
    NSString *value = values[0];

    if ([ISMetaDataUtils isValidCCPAMetaDataWithKey:key
                                           andValue:value]) {
        [self setCCPAValue:[ISMetaDataUtils getMetaDataBooleanValue:value]];

    } else {
        NSString *formattedValue = [ISMetaDataUtils formatValue:value
                                                        forType:(META_DATA_VALUE_BOOL)];

        if ([ISMetaDataUtils isValidMetaDataWithKey:key
                                               flag:kMetaDataCOPPAKey
                                           andValue:formattedValue]) {
            [self setCOPPAValue:[ISMetaDataUtils getMetaDataBooleanValue:formattedValue]];
        }
    }
}


#pragma mark - Helper Methods

- (NSDictionary *)getBiddingDataWithPlacementId:(NSString *)placementId {
    LogAdapterApi_Internal(@"placementId = %@", placementId);

    NSString *bidderToken = [VungleAds getBiddingToken];
    NSString *returnedToken = bidderToken? bidderToken : @"";

    LogAdapterApi_Internal(@"token = %@", returnedToken);

    return @{@"token": returnedToken};
}

- (VungleAdSize *)getBannerSize:(ISBannerSize *)size {
    if ([size.sizeDescription isEqualToString:kSizeCustom]) {
        return [VungleAdSize VungleAdSizeFromCGSize:CGSizeMake(size.width, size.height)];
    } else if ([size.sizeDescription isEqualToString:kSizeRectangle]) {
        return [VungleAdSize VungleAdSizeMREC];
    } else if ([size.sizeDescription isEqualToString:kSizeLeaderboard]) {
        return [VungleAdSize VungleAdSizeLeaderboard];
    } else if ([size.sizeDescription isEqualToString:kSizeSmart]) {
        if (UI_USER_INTERFACE_IDIOM() == UIUserInterfaceIdiomPad) {
            return [VungleAdSize VungleAdSizeLeaderboard];
        }
    }
    return [VungleAdSize VungleAdSizeBannerRegular];
}

@end
