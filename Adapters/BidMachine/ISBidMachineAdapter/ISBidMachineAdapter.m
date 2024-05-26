//
//  ISBidMachineAdapter.m
//  ISBidMachineAdapter
//
//  Copyright © 2024 ironSource Mobile Ltd. All rights reserved.
//

#import <ISBidMachineAdapter.h>
#import "ISBidMachineConstants.h"
#import <ISBidMachineRewardedVideoDelegate.h>
#import <ISBidMachineInterstitialDelegate.h>
#import <ISBidMachineBannerDelegate.h>
#import <BidMachine/BidMachine.h>

// Handle init callback for all adapter instances
static InitState initState = INIT_STATE_NONE;
static ISConcurrentMutableSet<ISNetworkInitCallbackProtocol> *initCallbackDelegates = nil;

@interface ISBidMachineAdapter() <ISNetworkInitCallbackProtocol>

// Rewarded video
@property (nonatomic, strong) BidMachineRewarded *rewardedAd;
@property (nonatomic, strong) id<ISRewardedVideoAdapterDelegate> rewardedVideoSmashDelegate;
@property (nonatomic, strong) ISBidMachineRewardedVideoDelegate *rewardedVideoBidMachineAdDelegate;

// Interstitial
@property (nonatomic, strong) BidMachineInterstitial *interstitialAd;
@property (nonatomic, strong) id<ISInterstitialAdapterDelegate> interstitialSmashDelegate;
@property (nonatomic, strong) ISBidMachineInterstitialDelegate *interstitialBidMachineAdDelegate;

// Banner
@property (nonatomic, strong) BidMachineBanner *bannerAd;
@property (nonatomic, strong) id<ISBannerAdapterDelegate> bannerSmashDelegate;
@property (nonatomic, strong) ISBidMachineBannerDelegate *bannerBidMachineAdDelegate;

@end

@implementation ISBidMachineAdapter

#pragma mark - IronSource Protocol Methods

// Get adapter version
- (NSString *)version {
    return BidMachineAdapterVersion;
}

// Get network sdk version
- (NSString *)sdkVersion {
    return BidMachineSdk.sdkVersion;
}

#pragma mark - Initializations Methods And Callbacks

- (instancetype)initAdapter:(NSString *)name {
    self = [super initAdapter:name];
    
    if (self) {
        if (initCallbackDelegates == nil) {
            initCallbackDelegates = [ISConcurrentMutableSet<ISNetworkInitCallbackProtocol> set];
        }
        
        // Rewarded Video
        self.rewardedAd = nil;
        self.rewardedVideoSmashDelegate = nil;
        self.rewardedVideoBidMachineAdDelegate = nil;
        
        // Interstitial
        self.interstitialAd = nil;
        self.interstitialSmashDelegate = nil;
        self.interstitialBidMachineAdDelegate = nil;
        
        //Banner
        self.bannerAd = nil;
        self.bannerSmashDelegate = nil;
        self.bannerBidMachineAdDelegate = nil;
        
        // The network's capability to load a Rewarded Video ad while another Rewarded Video ad of that network is showing
        LWSState = LOAD_WHILE_SHOW_BY_INSTANCE;
    }
    
    return self;
}

- (void)initSDKWithSourceId:(NSString *)sourceId {
    
    // Add self to the init delegates only in case the initialization has not finished yet
    if (initState == INIT_STATE_NONE || initState == INIT_STATE_IN_PROGRESS) {
        [initCallbackDelegates addObject:self];
    }
    
    static dispatch_once_t initSdkOnceToken;
    dispatch_once(&initSdkOnceToken, ^{
        LogAdapterApi_Internal(@"sourceId = %@", sourceId);
        
        initState = INIT_STATE_IN_PROGRESS;
        
        [BidMachineSdk.shared populate:^(id<BidMachineInfoBuilderProtocol> builder) {
            
            BOOL enableLogs = [ISConfigurations getConfigurations].adaptersDebug;
            [builder withLoggingMode:enableLogs];
            [builder withEventLoggingMode:enableLogs];
            [builder withBidLoggingMode:enableLogs];
        }];
        
        [BidMachineSdk.shared initializeSdk:sourceId];
        [self initializationSuccess];
    });
}

- (void)initializationSuccess {
    LogAdapterDelegate_Internal(@"");
    
    initState = INIT_STATE_SUCCESS;
    
    NSArray *initDelegatesList = initCallbackDelegates.allObjects;
    
    for (id<ISNetworkInitCallbackProtocol> initDelegate in initDelegatesList) {
        [initDelegate onNetworkInitCallbackSuccess];
    }
    
    [initCallbackDelegates removeAllObjects];
}

- (void)onNetworkInitCallbackSuccess {
    // Rewarded Video
    [self.rewardedVideoSmashDelegate adapterRewardedVideoInitSuccess];
    
    // Interstitial
    [self.interstitialSmashDelegate adapterInterstitialInitSuccess];
    
    // Banner
    [self.bannerSmashDelegate adapterBannerInitSuccess];
}

- (void)onNetworkInitCallbackFailed:(NSString *)errorMessage {}

#pragma mark - Rewarded Video API

- (void)initRewardedVideoForCallbacksWithUserId:(NSString *)userId
                                  adapterConfig:(ISAdapterConfig *)adapterConfig
                                       delegate:(id<ISRewardedVideoAdapterDelegate>)delegate {
    NSString *sourceId = adapterConfig.settings[kSourceId];
    
    // Configuration Validation
    if (![self isConfigValueValid:sourceId]) {
        NSError *error = [self errorForMissingCredentialFieldWithName:kSourceId];
        LogAdapterApi_Internal(@"error = %@", error.description);
        [delegate adapterRewardedVideoInitFailed:error];
        return;
    }
    
    LogAdapterApi_Internal(@"");
    
    // save rewarded video delegate
    self.rewardedVideoSmashDelegate = delegate;
    
    switch (initState) {
        case INIT_STATE_NONE:
        case INIT_STATE_IN_PROGRESS:
            [self initSDKWithSourceId:sourceId];
            break;
        case INIT_STATE_SUCCESS:
            [delegate adapterRewardedVideoInitSuccess];
            break;
    }
}

-(void)loadRewardedVideoForBiddingWithAdapterConfig:(ISAdapterConfig *)adapterConfig
                                             adData:(NSDictionary *)adData
                                         serverData:(NSString *)serverData
                                           delegate:(id<ISRewardedVideoAdapterDelegate>)delegate {
    // In favor of supporting all of the Mediation modes there is a need to save the Rewarded
    // delegate on both init and load APIs
    self.rewardedVideoSmashDelegate = delegate;
    
    NSError *configurationError = nil;
    id<BidMachineRequestConfigurationProtocol> config = [BidMachineSdk.shared requestConfiguration:BidMachinePlacementFormatRewarded
                                                                                             error:&configurationError];
    if (configurationError) {
        LogInternal_Error(@"error = %@", configurationError.description);
        NSError *error = [NSError errorWithDomain:kAdapterName
                                             code:configurationError.code
                                         userInfo:@{NSLocalizedDescriptionKey:configurationError.description}];
        [delegate adapterRewardedVideoDidFailToLoadWithError:error];
        return;
    }
    
    LogAdapterApi_Internal(@"");
    
    [config populate:^(id<BidMachineRequestBuilderProtocol> builder) {
        [builder withPayload:serverData];
    }];
    
    ISBidMachineAdapter * __weak weakSelf = self;
    [BidMachineSdk.shared rewarded:config
                                  :^(BidMachineRewarded * _Nullable rewarded,
                                     NSError * _Nullable error) {
        __typeof__(self) strongSelf = weakSelf;
        if (error || !rewarded) {
            NSInteger code = error ? error.code : ERROR_CODE_NO_ADS_TO_SHOW;
            NSString *decription = error ? error.description : [NSString stringWithFormat: @"%@ load failed", kAdapterName];
            
            NSError *errorInfo = [NSError errorWithDomain:kAdapterName
                                                     code:code
                                                 userInfo:@{NSLocalizedDescriptionKey:decription}];
            LogInternal_Error(@"error = %@", errorInfo.description);
            [delegate adapterRewardedVideoDidFailToLoadWithError:errorInfo];
            return;
        }
        
        ISBidMachineRewardedVideoDelegate *rewardedVideoAdDelegate = [[ISBidMachineRewardedVideoDelegate alloc] initWithDelegate:delegate];
        
        strongSelf.rewardedVideoBidMachineAdDelegate = rewardedVideoAdDelegate;
        strongSelf.rewardedAd = rewarded;
        
        rewarded.delegate = rewardedVideoAdDelegate;
        [rewarded loadAd];
    }];
}

-(void)showRewardedVideoWithViewController:(UIViewController *)viewController
                             adapterConfig:(ISAdapterConfig *)adapterConfig
                                  delegate:(id<ISRewardedVideoAdapterDelegate>)delegate {
    LogAdapterApi_Internal(@"");
    
    if (![self hasRewardedVideoWithAdapterConfig:adapterConfig]) {
        NSError *error = [ISError createError:ERROR_CODE_NO_ADS_TO_SHOW
                                  withMessage:[NSString stringWithFormat: @"%@ show failed", kAdapterName]];
        LogAdapterApi_Internal(@"error = %@", error);
        [delegate adapterRewardedVideoDidFailToShowWithError:error];
        return;
    }
    
    dispatch_async(dispatch_get_main_queue(), ^{
        self.rewardedAd.controller = viewController == nil ? [self topMostController] : viewController;
        [self.rewardedAd presentAd];
    });
}

- (BOOL)hasRewardedVideoWithAdapterConfig:(ISAdapterConfig *)adapterConfig {
    return [self.rewardedAd canShow];
}

- (void)collectRewardedVideoBiddingDataWithAdapterConfig:(ISAdapterConfig *)adapterConfig
                                                  adData:(NSDictionary *)adData
                                                delegate:(id<ISBiddingDataDelegate>)delegate {
    [self collectBiddingDataWithAdData:adData
                              adFormat:BidMachinePlacementFormatRewarded
                              delegate:delegate];
}

#pragma mark - Interstitial API

- (void)initInterstitialForBiddingWithUserId:(NSString *)userId
                               adapterConfig:(ISAdapterConfig *)adapterConfig
                                    delegate:(id<ISInterstitialAdapterDelegate>)delegate {
    NSString *sourceId = adapterConfig.settings[kSourceId];
    
    // Configuration Validation
    if (![self isConfigValueValid:sourceId]) {
        NSError *error = [self errorForMissingCredentialFieldWithName:kSourceId];
        LogAdapterApi_Internal(@"error = %@", error.description);
        [delegate adapterInterstitialInitFailedWithError:error];
        return;
    }
    
    LogAdapterApi_Internal(@"");
    
    // save interstitial delegate
    self.interstitialSmashDelegate = delegate;
    
    switch (initState) {
        case INIT_STATE_NONE:
        case INIT_STATE_IN_PROGRESS:
            [self initSDKWithSourceId:sourceId];
            break;
        case INIT_STATE_SUCCESS:
            [delegate adapterInterstitialInitSuccess];
            break;
    }
}

- (void)loadInterstitialForBiddingWithAdapterConfig:(ISAdapterConfig *)adapterConfig
                                             adData:(NSDictionary *)adData
                                         serverData:(NSString *)serverData
                                           delegate:(id<ISInterstitialAdapterDelegate>)delegate {
    // In favor of supporting all of the Mediation modes there is a need to save the Interstitial
    // delegate on both init and load APIs
    self.interstitialSmashDelegate = delegate;
    
    NSError *configurationError = nil;
    id<BidMachineRequestConfigurationProtocol> config = [BidMachineSdk.shared requestConfiguration:BidMachinePlacementFormatInterstitial
                                                                                             error:&configurationError];
    if (configurationError) {
        LogInternal_Error(@"error = %@", configurationError.description);
        NSError *error = [NSError errorWithDomain:kAdapterName
                                             code:configurationError.code
                                         userInfo:@{NSLocalizedDescriptionKey:configurationError.description}];
        [delegate adapterInterstitialDidFailToLoadWithError:error];
        return;
    }
    
    LogAdapterApi_Internal(@"");
    
    [config populate:^(id<BidMachineRequestBuilderProtocol> builder) {
        [builder withPayload:serverData];
    }];
    
    ISBidMachineAdapter * __weak weakSelf = self;
    [BidMachineSdk.shared interstitial:config
                                      :^(BidMachineInterstitial * _Nullable interstitial, NSError * _Nullable error) {
        
        __typeof__(self) strongSelf = weakSelf;
        if (error || !interstitial) {
            NSInteger code = error ? error.code : ERROR_CODE_NO_ADS_TO_SHOW;
            NSString *decription = error ? error.description : [NSString stringWithFormat: @"%@ load failed", kAdapterName];
            
            NSError *errorInfo = [NSError errorWithDomain:kAdapterName
                                                     code:code
                                                 userInfo:@{NSLocalizedDescriptionKey:decription}];
            LogInternal_Error(@"error = %@", errorInfo.description);
            [delegate adapterInterstitialDidFailToLoadWithError:errorInfo];
            return;
        }
        
        ISBidMachineInterstitialDelegate *interstitialAdDelegate = [[ISBidMachineInterstitialDelegate alloc] initWithDelegate:delegate];
        
        strongSelf.interstitialBidMachineAdDelegate = interstitialAdDelegate;
        strongSelf.interstitialAd = interstitial;
        
        interstitial.delegate = interstitialAdDelegate;
        [interstitial loadAd];
    }];
}

- (void)showInterstitialWithViewController:(UIViewController *)viewController
                             adapterConfig:(ISAdapterConfig *)adapterConfig
                                  delegate:(id<ISInterstitialAdapterDelegate>)delegate {
    LogAdapterApi_Internal(@"");
    
    if (![self hasInterstitialWithAdapterConfig:adapterConfig]) {
        
        NSError *error = [ISError createError:ERROR_CODE_NO_ADS_TO_SHOW
                                  withMessage:[NSString stringWithFormat: @"%@ show failed", kAdapterName]];
        LogAdapterApi_Internal(@"error = %@", error);
        [delegate adapterInterstitialDidFailToShowWithError:error];
        return;
    }
    
    dispatch_async(dispatch_get_main_queue(), ^{
        self.interstitialAd.controller = viewController == nil ? [self topMostController] : viewController;
        [self.interstitialAd presentAd];
    });
}

- (BOOL)hasInterstitialWithAdapterConfig:(ISAdapterConfig *)adapterConfig {
    return [self.interstitialAd canShow];
}

- (void)collectInterstitialBiddingDataWithAdapterConfig:(ISAdapterConfig *)adapterConfig
                                                      adData:(NSDictionary *)adData
                                                    delegate:(id<ISBiddingDataDelegate>)delegate {
    [self collectBiddingDataWithAdData:adData
                              adFormat:BidMachinePlacementFormatInterstitial
                              delegate:delegate];
}

#pragma mark - Banner API

- (void)initBannerForBiddingWithUserId:(NSString *)userId
                         adapterConfig:(ISAdapterConfig *)adapterConfig
                              delegate:(id<ISBannerAdapterDelegate>)delegate {
    NSString *sourceId = adapterConfig.settings[kSourceId];
    
    // Configuration Validation
    if (![self isConfigValueValid:sourceId]) {
        NSError *error = [self errorForMissingCredentialFieldWithName:kSourceId];
        LogAdapterApi_Internal(@"error = %@", error.description);
        [delegate adapterBannerInitFailedWithError:error];
        return;
    }
    
    LogAdapterApi_Internal(@"");
    
    // save banner delegate
    self.bannerSmashDelegate = delegate;
    
    switch (initState) {
        case INIT_STATE_NONE:
        case INIT_STATE_IN_PROGRESS:
            [self initSDKWithSourceId:sourceId];
            break;
        case INIT_STATE_SUCCESS:
            [delegate adapterBannerInitSuccess];
            break;
    }
}

- (void)loadBannerForBiddingWithAdapterConfig:(ISAdapterConfig *)adapterConfig
                                       adData:(NSDictionary *)adData
                                   serverData:(NSString *)serverData
                               viewController:(UIViewController *)viewController
                                         size:(ISBannerSize *)size
                                     delegate:(id <ISBannerAdapterDelegate>)delegate {
    // In favor of supporting all of the Mediation modes there is a need to store the Banner
    // delegate on both init and load APIs
    self.bannerSmashDelegate = delegate;
    
    BidMachinePlacementFormat bannerFormat = [self getBannerFormat:size];
    
    NSError *configurationError = nil;
    id<BidMachineRequestConfigurationProtocol> config = [BidMachineSdk.shared requestConfiguration:bannerFormat
                                                                                             error:&configurationError];
    if (configurationError) {
        LogInternal_Error(@"error = %@", configurationError.description);
        NSError *error = [NSError errorWithDomain:kAdapterName
                                             code:configurationError.code
                                         userInfo:@{NSLocalizedDescriptionKey:configurationError.description}];
        [delegate adapterBannerDidFailToLoadWithError:error];
        return;
    }
    
    LogAdapterApi_Internal(@"");
    
    [config populate:^(id<BidMachineRequestBuilderProtocol> builder) {
        [builder withPayload:serverData];
    }];
    
    ISBidMachineAdapter * __weak weakSelf = self;
    [BidMachineSdk.shared banner:config
                                :^(BidMachineBanner * _Nullable banner, NSError * _Nullable error) {
        
        __typeof__(self) strongSelf = weakSelf;
        if (error || !banner) {
            NSInteger code = error ? error.code : ERROR_CODE_NO_ADS_TO_SHOW;
            NSString *decription = error ? error.description : [NSString stringWithFormat: @"%@ load failed", kAdapterName];
            
            NSError *errorInfo = [NSError errorWithDomain:kAdapterName
                                                     code:code
                                                 userInfo:@{NSLocalizedDescriptionKey:decription}];
            LogInternal_Error(@"error = %@", errorInfo.description);
            [delegate adapterBannerDidFailToLoadWithError:errorInfo];
            return;
        }
        
        ISBidMachineBannerDelegate *bannerAdDelegate = [[ISBidMachineBannerDelegate alloc] initWithBanner:banner
                                                                                              andDelegate:delegate];
        
        strongSelf.bannerBidMachineAdDelegate = bannerAdDelegate;
        strongSelf.bannerAd = banner;
        
        dispatch_async(dispatch_get_main_queue(), ^{
            banner.controller = viewController == nil ? [self topMostController] : viewController;
            banner.delegate = bannerAdDelegate;
            [banner loadAd];
        });
    }];
}

- (void)destroyBannerWithAdapterConfig:(ISAdapterConfig *)adapterConfig {
    LogAdapterApi_Internal(@"");
    
    self.bannerAd.controller = nil;
    self.bannerAd.delegate = nil;
    self.bannerAd = nil;
    self.bannerSmashDelegate = nil;
    self.bannerBidMachineAdDelegate = nil;
}

- (void)collectBannerBiddingDataWithAdapterConfig:(ISAdapterConfig *)adapterConfig
                                           adData:(NSDictionary *)adData
                                         delegate:(id<ISBiddingDataDelegate>)delegate {
    if ([adData objectForKey:@"bannerSize"]) {
        ISBannerSize *size = [adData objectForKey:@"bannerSize"];
        BidMachinePlacementFormat bannerFormat = [self getBannerFormat:size];
        [self collectBiddingDataWithAdData:adData
                                  adFormat:bannerFormat
                                  delegate:delegate];
    }
}


#pragma mark - Memory Handling

- (void)releaseMemoryWithAdapterConfig:(nonnull ISAdapterConfig *)adapterConfig {
    
    // Rewarded Video
    self.rewardedAd.controller = nil;
    self.rewardedAd.delegate = nil;
    self.rewardedAd = nil;
    self.rewardedVideoSmashDelegate = nil;
    self.rewardedVideoBidMachineAdDelegate = nil;
    
    // Interstitial
    self.interstitialAd.controller = nil;
    self.interstitialAd.delegate = nil;
    self.interstitialAd = nil;
    self.interstitialSmashDelegate = nil;
    self.interstitialBidMachineAdDelegate = nil;
    
    // Banner
    [self destroyBannerWithAdapterConfig:adapterConfig];
}

#pragma mark - Legal Methods

- (void)setMetaDataWithKey:(NSString *)key
                 andValues:(NSMutableArray *)values {
    if (values.count == 0) {
        return;
    }
    
    // This is an array of 1 value
    NSString *value = values[0];
    LogAdapterApi_Internal(@"key = %@, value = %@", key, value);
    
    if ([ISMetaDataUtils isValidCCPAMetaDataWithKey:key
                                           andValue:value]) {
        [self setCCPAValue:[ISMetaDataUtils getMetaDataBooleanValue:value]];
        
    } else {
        NSString *formattedValue = [ISMetaDataUtils formatValue:value
                                                        forType:(META_DATA_VALUE_BOOL)];
        
        if ([ISMetaDataUtils isValidMetaDataWithKey:key
                                               flag:kMetaDataCOPPAKey
                                           andValue:value]) {
            [self setCOPPAValue:[ISMetaDataUtils getMetaDataBooleanValue:formattedValue]];
        }
    }
    
}

- (void)setConsent:(BOOL)consent {
    LogAdapterApi_Internal(@"consent = %@", consent ? @"YES" : @"NO");
    
    [BidMachineSdk.shared.regulationInfo
     populate:^(id<BidMachineRegulationInfoBuilderProtocol> builder) {
        [builder withGDPRZone:YES];
        [builder withGDPRConsent:consent];
    }];
}

- (void)setCCPAValue:(BOOL)value {
    NSString *ccpaConsentString = (value) ? kMetaDataCCPANoConsentValue : kMetaDataCCPAConsentValue;
    
    LogAdapterApi_Internal(@"value = %@", ccpaConsentString);
    
    [BidMachineSdk.shared.regulationInfo
     populate:^(id<BidMachineRegulationInfoBuilderProtocol> builder) {
        [builder withUSPrivacyString:ccpaConsentString];
    }];
}

- (void)setCOPPAValue:(BOOL)value {
    LogAdapterApi_Internal(@"value = %@", value ? @"YES" : @"NO");
    
    [BidMachineSdk.shared.regulationInfo
     populate:^(id<BidMachineRegulationInfoBuilderProtocol> builder) {
        [builder withCOPPA:value];
    }];
}

#pragma mark - Helper Methods

- (void)collectBiddingDataWithAdData:(NSDictionary *)adData
                            adFormat:(BidMachinePlacementFormat)adFormat
                            delegate:(id<ISBiddingDataDelegate>)delegate {
    
    if (initState == INIT_STATE_NONE) {
        NSString *error = [NSString stringWithFormat:@"returning nil as token since init hasn't started"];
        LogAdapterApi_Internal(@"%@", error);
        [delegate failureWithError:error];
        return;
    }
    
    [BidMachineSdk.shared tokenWith:adFormat completion:^(NSString *token) {
        NSDictionary *biddingDataDictionary = [NSDictionary dictionaryWithObjectsAndKeys: token, @"token", nil];
        NSString *returnedToken = token? token : @"";
        LogAdapterApi_Internal(@"token = %@", returnedToken);
        [delegate successWithBiddingData:biddingDataDictionary];
    }];
}

- (BidMachinePlacementFormat)getBannerFormat:(ISBannerSize *)size {
    if ([size.sizeDescription isEqualToString:@"BANNER"]) {
        return BidMachinePlacementFormatBanner320x50;
    } else if ([size.sizeDescription isEqualToString:@"RECTANGLE"]) {
        return BidMachinePlacementFormatBanner300x250;
    } else if ([size.sizeDescription isEqualToString:@"SMART"]) {
        if (UI_USER_INTERFACE_IDIOM() == UIUserInterfaceIdiomPad) {
            return BidMachinePlacementFormatBanner728x90;
        } else {
            return BidMachinePlacementFormatBanner320x50;
        }
    }
    return BidMachinePlacementFormatUnknown;
}

@end
