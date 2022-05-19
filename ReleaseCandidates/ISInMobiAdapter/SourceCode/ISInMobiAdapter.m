//
//  ISInMobiAdapter.m
//  ISInMobiAdapter
//
//  Created by Yotam Ohayon on 26/10/2015.
//  Copyright © 2015 IronSource. All rights reserved.
//

#import "ISInMobiAdapter.h"

#import <InMobiSDK/IMSdk.h>
#import "InMobiSDK/IMCommonConstants.h"
#import "InMobiSDK/IMInterstitial.h"
#import "InMobiSDK/IMBanner.h"
#import "ISInMobiRewardedVideoListener.h"
#import "ISInMobiInterstitialListener.h"
#import "ISInMobiBannerListener.h"

typedef NS_ENUM(NSInteger, InitState) {
    INIT_STATE_NONE,
    INIT_STATE_IN_PROGRESS,
    INIT_STATE_ERROR,
    INIT_STATE_SUCCESS
};
static InitState _initState = INIT_STATE_NONE;

static NSString * const kAdapterVersion = InMobiAdapterVersion;
static NSString * const kAdapterName                = @"InMobi";
static NSString * const kAccountId                  = @"accountId";
static NSString * const kPlacementId                = @"placementId";
static NSString * const kMetaDataAgeRestrictedKey   = @"inMobi_AgeRestricted";

// consent and metadata
static NSString*    _consentCollectingUserData = nil;
static BOOL         _ageRestrictionCollecctingUserData = nil;

static ConcurrentMutableSet<ISNetworkInitCallbackProtocol> *initCallbackDelegates = nil;

@interface ISInMobiAdapter () <ISInMobiRewardedVideoListenerDelegate, ISInMobiInterstitialListenerDelegate, ISInMobiBannerListenerDelegate, ISNetworkInitCallbackProtocol>

@end

@implementation ISInMobiAdapter
{

    // Rewarded video
    ConcurrentMutableDictionary* _placementIdToRewardedVideoAd;
    ConcurrentMutableDictionary* _placementIdToRewardedVideoListener;
    ConcurrentMutableDictionary* _placementIdToRewardedVideoSmashDelegate;

    // Interstitial
    ConcurrentMutableDictionary* _placementIdToInterstitialAd;
    ConcurrentMutableDictionary* _placementIdToInterstitialListener;
    ConcurrentMutableDictionary* _placementIdToInterstitialSmashDelegate;

    // Banner
    ConcurrentMutableDictionary* _placementIdToBannerAd;
    ConcurrentMutableDictionary* _placementIdToBannerListener;
    ConcurrentMutableDictionary* _placementIdToBannerSmashDelegate;
    
    // programmatic
    ConcurrentMutableSet* _programmaticPlacementIds;
}

#pragma mark - Initializations Methods

- (instancetype)initAdapter:(NSString *)name
{
    self = [super initAdapter:name];
    if (self) {
        
        if(initCallbackDelegates == nil) {
            initCallbackDelegates = [ConcurrentMutableSet<ISNetworkInitCallbackProtocol> set];
        }
        
        _placementIdToRewardedVideoAd = [ConcurrentMutableDictionary dictionary];
        _placementIdToRewardedVideoListener = [ConcurrentMutableDictionary dictionary];
        _placementIdToRewardedVideoSmashDelegate = [ConcurrentMutableDictionary dictionary];

        _placementIdToInterstitialAd = [ConcurrentMutableDictionary dictionary];
        _placementIdToInterstitialListener = [ConcurrentMutableDictionary dictionary];
        _placementIdToInterstitialSmashDelegate = [ConcurrentMutableDictionary dictionary];

        _placementIdToBannerAd = [ConcurrentMutableDictionary dictionary];
        _placementIdToBannerListener = [ConcurrentMutableDictionary dictionary];
        _placementIdToBannerSmashDelegate = [ConcurrentMutableDictionary dictionary];
        
        _programmaticPlacementIds = [ConcurrentMutableSet set];

        
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
    return [IMSdk getVersion];
}

- (NSArray *)systemFrameworks {
    return @[@"WebKit"];
}

- (NSString *)sdkName {
    return @"IMSdk";
}

- (void)setConsent:(BOOL)consent {
    LogAdapterApi_Internal(@"consent = %@", consent ? @"YES" : @"NO");

    _consentCollectingUserData = [NSString stringWithFormat:@"%s", consent ? "true" : "false"];
    
    if (_initState == INIT_STATE_SUCCESS) {
        [IMSdk updateGDPRConsent:[self getConsentDictionary]];
    }
}

- (void)setMetaDataWithKey:(NSString *)key
                 andValues:(NSMutableArray *) values {
    if (values.count == 0) {
        return;
    }
    
    NSString *value = values[0];
    LogAdapterApi_Internal(@"key=%@, value=%@", key, value);
    
    NSString *formattedValue = [ISMetaDataUtils formatValue:value forType:(META_DATA_VALUE_BOOL)];
    if ([self isValidAgeRestrictionMetaData:key andValue:formattedValue]) {
        [self setAgeRestricted:[ISMetaDataUtils getCCPABooleanValue:formattedValue]];
    }
}

#pragma mark - Rewarded Video
- (NSDictionary *)getRewardedVideoBiddingDataWithAdapterConfig:(ISAdapterConfig *)adapterConfig {
    LogAdapterApi_Internal(@"");
    return [self getBiddingData];
}

- (void)initRewardedVideoForCallbacksWithUserId:(NSString *)userId
                                  adapterConfig:(ISAdapterConfig *)adapterConfig
                                       delegate:(id<ISRewardedVideoAdapterDelegate>)delegate {
    LogAdapterApi_Internal(@"");

    NSString *placementId = adapterConfig.settings[kPlacementId];
    NSString *accountId = adapterConfig.settings[kAccountId];

    // check delegate
    if (delegate == nil) {
        LogAdapterApi_Internal(@"delegate == nil");
        return;
    }
    
    // verified placementId
    if (![self isConfigValueValid:placementId]) {
        NSError *error = [self errorForMissingCredentialFieldWithName:kPlacementId];
        LogAdapterApi_Internal(@"error = %@", error);
        [delegate adapterRewardedVideoInitFailed:error];
        return;
    }
    
    // verified accountId
    if (![self isConfigValueValid:accountId]) {
        NSError *error = [self errorForMissingCredentialFieldWithName:kAccountId];
        LogAdapterApi_Internal(@"error = %@", error);
        [delegate adapterRewardedVideoInitFailed:error];
        return;
    }
    
    LogAdapterApi_Internal(@"accountId = %@", accountId);
    LogAdapterApi_Internal(@"placementId = %@", placementId);
    
    // handle listeners
    ISInMobiRewardedVideoListener* listener = [[ISInMobiRewardedVideoListener alloc] initWithPlacementId:placementId andDelegate:self];
    [_placementIdToRewardedVideoListener setObject:listener forKey:placementId];
    [_placementIdToRewardedVideoSmashDelegate setObject:delegate forKey:placementId];
    [_programmaticPlacementIds addObject:placementId];

    // handle init state if already initialized
    if (_initState == INIT_STATE_SUCCESS) {
        LogAdapterApi_Internal(@"init rewarded video: INIT_STATE_SUCCESS");
        [delegate adapterRewardedVideoInitSuccess];

    } else if (_initState == INIT_STATE_ERROR) {
        NSError *error = [NSError errorWithDomain:kAdapterName code:ERROR_CODE_INIT_FAILED
                            userInfo:@{NSLocalizedDescriptionKey:@"InMobi SDK Init Failed"}];
        LogAdapterApi_Internal(@"error = %@", error);
        [delegate adapterRewardedVideoInitFailed:error];
    } else {
        // main thread
        [self.dispatcher dispatchAsyncWithQueue:dispatch_get_main_queue() withBlock:^{

            // init SDK
            [self initSDKWithAccountId:accountId];
            
        }];
    }
    

}

- (void)initAndLoadRewardedVideoWithUserId:(NSString *)userId
                             adapterConfig:(ISAdapterConfig *)adapterConfig
                                  delegate:(id<ISRewardedVideoAdapterDelegate>)delegate {

    LogAdapterApi_Internal(@"");

    NSString *placementId = adapterConfig.settings[kPlacementId];
    NSString *accountId = adapterConfig.settings[kAccountId];

    // check delegate
    if (delegate == nil) {
        LogAdapterApi_Internal(@"delegate == nil");
        return;
    }
    
    // verified placementId
    if (![self isConfigValueValid:placementId]) {
        NSError *error = [self errorForMissingCredentialFieldWithName:kPlacementId];
        LogAdapterApi_Internal(@"error = %@", error);
        [delegate adapterRewardedVideoHasChangedAvailability:NO];
        return;
    }
    
    // verified accountId
    if (![self isConfigValueValid:accountId]) {
        NSError *error = [self errorForMissingCredentialFieldWithName:kAccountId];
        LogAdapterApi_Internal(@"error = %@", error);
        [delegate adapterRewardedVideoHasChangedAvailability:NO];
        return;
    }
    
    LogAdapterApi_Internal(@"accountId = %@", accountId);
    LogAdapterApi_Internal(@"placementId = %@", placementId);
    
    // handle listeners
    ISInMobiRewardedVideoListener* listener = [[ISInMobiRewardedVideoListener alloc] initWithPlacementId:placementId andDelegate:self];
    [_placementIdToRewardedVideoListener setObject:listener forKey:placementId];
    [_placementIdToRewardedVideoSmashDelegate setObject:delegate forKey:placementId];
    
    // handle init state if already initialized
    if (_initState == INIT_STATE_SUCCESS) {
        LogAdapterApi_Internal(@"init rewarded video: INIT_STATE_SUCCESS");

        // load rv
        [self loadRewardedVideoWithPlacementId:placementId serverData:nil];

    } else if (_initState == INIT_STATE_ERROR) {
        NSError *error = [NSError errorWithDomain:kAdapterName code:ERROR_CODE_INIT_FAILED
                            userInfo:@{NSLocalizedDescriptionKey:@"InMobi SDK Init Failed"}];
        LogAdapterApi_Internal(@"error = %@", error);
        [delegate adapterRewardedVideoHasChangedAvailability:NO];
    } else {
        // main thread
        [self.dispatcher dispatchAsyncWithQueue:dispatch_get_main_queue() withBlock:^{

            // init SDK
            [self initSDKWithAccountId:accountId];
            
        }];
    }

}

//Load rewarded video for bidding
- (void)loadRewardedVideoForBiddingWithAdapterConfig:(ISAdapterConfig *)adapterConfig serverData:(NSString *)serverData delegate:(id<ISRewardedVideoAdapterDelegate>)delegate{
    NSString *placementId = adapterConfig.settings[kPlacementId];
    LogAdapterApi_Internal(@"placementId = %@", placementId);

    [self loadRewardedVideoWithPlacementId:placementId serverData:serverData];
}

- (void)fetchRewardedVideoForAutomaticLoadWithAdapterConfig:(ISAdapterConfig *)adapterConfig delegate:(id<ISRewardedVideoAdapterDelegate>)delegate {
    NSString *placementId = adapterConfig.settings[kPlacementId];
    LogAdapterApi_Internal(@"placementId = %@", placementId);
    
    [self loadRewardedVideoWithPlacementId:placementId serverData:nil];
}

- (BOOL)hasRewardedVideoWithAdapterConfig:(ISAdapterConfig *)adapterConfig {
    NSString *placementId = adapterConfig.settings[kPlacementId];
    LogAdapterApi_Internal(@"placementId = %@", placementId);
    
    // get ad
    IMInterstitial* rewardedAd = [_placementIdToRewardedVideoAd objectForKey:placementId];
    
    return (rewardedAd != nil && [rewardedAd isReady]);
}

- (void) loadRewardedVideoWithPlacementId:(NSString*)placementId serverData:(NSString *)serverData {
    LogAdapterApi_Internal(@"placementId = %@", placementId);
    
    [self.dispatcher dispatchAsyncWithQueue:dispatch_get_main_queue() withBlock:^{

            LogAdapterApi_Internal(@"rewardedAd create ad");

            // get listener
            ISInMobiRewardedVideoListener* listener = [_placementIdToRewardedVideoListener objectForKey:placementId];

            // create ad
            IMInterstitial* rewardedAd = [[IMInterstitial alloc] initWithPlacementId:[placementId longLongValue] delegate:listener];

            if (rewardedAd != nil){
                // add to dictionary
                [_placementIdToRewardedVideoAd setObject:rewardedAd forKey:placementId];

                // load ad
                LogAdapterApi_Internal(@"load rewarded video");
                
                if (serverData == nil) {
                    rewardedAd.extras = @{@"tp": @"c_supersonic", @"tp-ver": @"ADAPTER_VERSION"}; // added by request of InMobi
                    [rewardedAd load];
                }
                else {
                    NSData* data = [serverData dataUsingEncoding:NSUTF8StringEncoding];
                    [rewardedAd load:data];
                }
            } else {
                NSError *error = [NSError errorWithDomain:kAdapterName code:ERROR_CODE_GENERIC
                                    userInfo:@{NSLocalizedDescriptionKey:@"rewardedAd ad is nil - can't continue"}];
                LogAdapterApi_Internal(@"error = %@", error);
                
                id<ISRewardedVideoAdapterDelegate> delegate = [_placementIdToRewardedVideoSmashDelegate objectForKey:placementId];
                if (delegate) {
                    [delegate adapterRewardedVideoHasChangedAvailability:NO];
                }
            }
    }];
}

- (void)showRewardedVideoWithViewController:(UIViewController *)viewController adapterConfig:(ISAdapterConfig *)adapterConfig delegate:(id<ISRewardedVideoAdapterDelegate>)delegate {
    NSString *placementId = adapterConfig.settings[kPlacementId];
    LogAdapterApi_Internal(@"placementId = %@", placementId);

    // get ad and check availability
    IMInterstitial* rewardedAd = [_placementIdToRewardedVideoAd objectForKey:placementId];

    [delegate adapterRewardedVideoHasChangedAvailability:NO];

    if (![self hasRewardedVideoWithAdapterConfig:adapterConfig]) {
        NSError *error = [NSError errorWithDomain:kAdapterName code:ERROR_CODE_GENERIC
                            userInfo:@{NSLocalizedDescriptionKey:@"show failed, rewardedAd isn't ready"}];
        LogAdapterApi_Internal(@"error = %@", error);
        [delegate adapterRewardedVideoDidFailToShowWithError:error];
        return;
    }
    
    // show on main thread
    [self.dispatcher dispatchAsyncWithQueue:dispatch_get_main_queue() withBlock:^{
        LogAdapterApi_Internal(@"show rewarded video");
        [rewardedAd showFromViewController:viewController];
    }];
}

#pragma mark - Interstitial
- (NSDictionary *)getInterstitialBiddingDataWithAdapterConfig:(ISAdapterConfig *)adapterConfig {
    LogAdapterApi_Internal(@"");
    return [self getBiddingData];
}

- (void)initInterstitialForBiddingWithUserId:(NSString *)userId adapterConfig:(ISAdapterConfig *)adapterConfig delegate:(id<ISInterstitialAdapterDelegate>)delegate {
    LogAdapterApi_Internal(@"");
    [self initInterstitialWithUserId:userId adapterConfig:adapterConfig delegate:delegate];
}

- (void)initInterstitialWithUserId:(NSString *)userId adapterConfig:(ISAdapterConfig *)adapterConfig delegate:(id<ISInterstitialAdapterDelegate>)delegate {
    LogAdapterApi_Internal(@"");
    NSString *placementId = adapterConfig.settings[kPlacementId];
    NSString *accountId = adapterConfig.settings[kAccountId];

    // check delegate
    if (delegate == nil) {
        LogAdapterApi_Internal(@"delegate == nil");
        return;
    }
    
    // verified placementId
    if (![self isConfigValueValid:placementId]) {
        NSError *error = [self errorForMissingCredentialFieldWithName:kPlacementId];
        LogAdapterApi_Internal(@"error = %@", error);
        [delegate adapterInterstitialInitFailedWithError:error];
        return;
    }
    
    // verified accountId
    if (![self isConfigValueValid:accountId]) {
        NSError *error = [self errorForMissingCredentialFieldWithName:kAccountId];
        LogAdapterApi_Internal(@"error = %@", error);
        [delegate adapterInterstitialInitFailedWithError:error];
        return;
    }
    
    LogAdapterApi_Internal(@"accountId = %@", accountId);
    LogAdapterApi_Internal(@"placementId = %@", placementId);
    
    // handle listeners
    ISInMobiInterstitialListener* listener = [[ISInMobiInterstitialListener alloc] initWithPlacementId:placementId andDelegate:self];
    [_placementIdToInterstitialListener setObject:listener forKey:placementId];
    [_placementIdToInterstitialSmashDelegate setObject:delegate forKey:placementId];
    
    if (_initState == INIT_STATE_SUCCESS) {
        LogAdapterApi_Internal(@"init interstitial: INIT_STATE_SUCCESS");
        
        // call init success
        [delegate adapterInterstitialInitSuccess];
    } else if (_initState == INIT_STATE_ERROR) {
        NSError *error = [NSError errorWithDomain:kAdapterName code:ERROR_CODE_INIT_FAILED
                            userInfo:@{NSLocalizedDescriptionKey:@"InMobi SDK Init Failed"}];
        LogAdapterApi_Internal(@"error = %@", error);
        [delegate adapterInterstitialInitFailedWithError:error];
    } else {
        // main thread block
        [self.dispatcher dispatchAsyncWithQueue:dispatch_get_main_queue() withBlock:^{

            // init SDK
            [self initSDKWithAccountId:accountId];
            
        }];
    }
    
    
}

//Load interstitial for bidding
- (void)loadInterstitialForBiddingWithServerData:(NSString *)serverData adapterConfig:(ISAdapterConfig *)adapterConfig delegate:(id<ISInterstitialAdapterDelegate>)delegate {
    NSString *placementId = adapterConfig.settings[kPlacementId];
    LogAdapterApi_Internal(@"placementId = %@", placementId);
    
    [self loadInterstitialInternal:delegate placementId:placementId serverData:serverData];

}

- (void)loadInterstitialWithAdapterConfig:(ISAdapterConfig *)adapterConfig delegate:(id<ISInterstitialAdapterDelegate>)delegate {
    NSString *placementId = adapterConfig.settings[kPlacementId];
    LogAdapterApi_Internal(@"placementId = %@", placementId);
    
    [self loadInterstitialInternal:delegate placementId:placementId serverData:nil];
}

- (void)showInterstitialWithViewController:(UIViewController *)viewController adapterConfig:(ISAdapterConfig *)adapterConfig delegate:(id<ISInterstitialAdapterDelegate>)delegate {
    NSString *placementId = adapterConfig.settings[kPlacementId];
    LogAdapterApi_Internal(@"placementId = %@", placementId);
    
    // get ad
    IMInterstitial* inMobiInterstitial = [_placementIdToInterstitialAd objectForKey:placementId];
    

    if (![self hasInterstitialWithAdapterConfig:adapterConfig]) {
        NSString *message = @"inMobiInterstitial is not ready";
        NSError *error = [NSError errorWithDomain:@"ISInMobiAdapter" code:ERROR_CODE_GENERIC userInfo:@{NSLocalizedDescriptionKey : message}];
        LogAdapterApi_Internal(@"error = %@", error);
        [delegate adapterInterstitialDidFailToShowWithError:error];
        return;
    }
    
    [self.dispatcher dispatchAsyncWithQueue:dispatch_get_main_queue() withBlock:^{
        [inMobiInterstitial showFromViewController:viewController];
    }];
}

- (void)loadInterstitialInternal:(id<ISInterstitialAdapterDelegate>)delegate placementId:(NSString *)placementId serverData:(NSString *)serverData {
    // main thread block
    [self.dispatcher dispatchAsyncWithQueue:dispatch_get_main_queue() withBlock:^{
        
        LogAdapterApi_Internal(@"interstitial create ad");
        
        // get listener
        ISInMobiInterstitialListener* listener = [_placementIdToInterstitialListener objectForKey:placementId];
        
        // create interstitial ad
        IMInterstitial* inMobiInterstitial = [[IMInterstitial alloc] initWithPlacementId:[placementId longLongValue] delegate:listener];
        
        if (inMobiInterstitial != nil){
            // add to dictionary
            [_placementIdToInterstitialAd setObject:inMobiInterstitial forKey:placementId];
            
            // load ad
            if(serverData == nil) {
                inMobiInterstitial.extras = @{@"tp": @"c_supersonic", @"tp-ver": @"ADAPTER_VERSION"}; // added by request of InMobi
                [inMobiInterstitial load];
            } else {
                NSData* data = [serverData dataUsingEncoding:NSUTF8StringEncoding];
                [inMobiInterstitial load:data];
            }
        } else {
            NSError *error = [NSError errorWithDomain:kAdapterName code:ERROR_CODE_GENERIC
                                userInfo:@{NSLocalizedDescriptionKey:@"inMobiInterstitial ad is nil - can't continue"}];
            LogAdapterApi_Internal(@"error = %@", error);
            [delegate adapterInterstitialDidFailToLoadWithError:error];
        }
    }];
}


- (BOOL)hasInterstitialWithAdapterConfig:(ISAdapterConfig *)adapterConfig {
    NSString *placementId = adapterConfig.settings[kPlacementId];
    LogAdapterApi_Internal(@"placementId = %@", placementId);

    // get ad
    IMInterstitial* inMobiInterstitial = [_placementIdToInterstitialAd objectForKey:placementId];

    return (inMobiInterstitial != nil && [inMobiInterstitial isReady]);
}

#pragma mark - Banner
- (NSDictionary *)getBannerBiddingDataWithAdapterConfig:(ISAdapterConfig *)adapterConfig {
    
    LogAdapterApi_Internal(@"");
    return [self getBiddingData];
}

- (void)initBannerForBiddingWithUserId:(NSString *)userId
                         adapterConfig:(ISAdapterConfig *)adapterConfig
                              delegate:(id<ISBannerAdapterDelegate>)delegate {
    LogAdapterApi_Internal(@"");
    [self initBannerWithUserId:userId adapterConfig:adapterConfig delegate:delegate];
}

- (void)initBannerWithUserId:(nonnull NSString *)userId adapterConfig:(nonnull ISAdapterConfig *)adapterConfig delegate:(nonnull id<ISBannerAdapterDelegate>)delegate {
    LogAdapterApi_Internal(@"");
    NSString *placementId = adapterConfig.settings[kPlacementId];
    NSString *accountId = adapterConfig.settings[kAccountId];

    // check delegate
    if (delegate == nil) {
        LogAdapterApi_Internal(@"delegate == nil");
        return;
    }
    
    // verified placementId
    if (![self isConfigValueValid:placementId]) {
        NSError *error = [self errorForMissingCredentialFieldWithName:kPlacementId];
        LogAdapterApi_Internal(@"error = %@", error);
        [delegate adapterBannerInitFailedWithError:error];
        return;
    }
    
    // verified accountId
    if (![self isConfigValueValid:accountId]) {
        NSError *error = [self errorForMissingCredentialFieldWithName:kAccountId];
        LogAdapterApi_Internal(@"error = %@", error);
        [delegate adapterBannerInitFailedWithError:error];
        return;
    }
    
    LogAdapterApi_Internal(@"accountId = %@", accountId);
    LogAdapterApi_Internal(@"placementId = %@", placementId);
    
    // handle listeners
    ISInMobiBannerListener* listener = [[ISInMobiBannerListener alloc] initWithPlacementId:placementId andDelegate:self];
    [_placementIdToBannerSmashDelegate setObject:delegate forKey:placementId];
    [_placementIdToBannerListener setObject:listener forKey:placementId];
    
    // handle init state if already initialized
    if (_initState == INIT_STATE_SUCCESS) {
        LogAdapterApi_Internal(@"init banner: INIT_STATE_SUCCESS");
        
        // call init success
        [delegate adapterBannerInitSuccess];
    } else if (_initState == INIT_STATE_ERROR) {
        NSError *error = [NSError errorWithDomain:kAdapterName code:ERROR_CODE_INIT_FAILED
                            userInfo:@{NSLocalizedDescriptionKey:@"InMobi SDK Init Failed"}];
        LogAdapterApi_Internal(@"error = %@", error);
        [delegate adapterBannerInitFailedWithError:error];
    } else {
        [self.dispatcher dispatchAsyncWithQueue:dispatch_get_main_queue() withBlock:^{

            // init SDK
            [self initSDKWithAccountId:accountId];
            
        }];
    }
    

}

- (void)loadBannerForBiddingWithServerData:(NSString *)serverData
                            viewController:(UIViewController *)viewController
                                      size:(ISBannerSize *)size
                             adapterConfig:(ISAdapterConfig *)adapterConfig
                                  delegate:(id <ISBannerAdapterDelegate>)delegate {
    
    LogAdapterApi_Internal(@"");
    [self loadBannerInternal:adapterConfig delegate:delegate size:size serverData:serverData];
}

- (void)loadBannerWithViewController:(nonnull UIViewController *)viewController size:(ISBannerSize *)size adapterConfig:(nonnull ISAdapterConfig *)adapterConfig delegate:(nonnull id <ISBannerAdapterDelegate>)delegate {
    LogAdapterApi_Internal(@"");

    [self loadBannerInternal:adapterConfig delegate:delegate size:size serverData:nil];
}

- (void)loadBannerInternal:(ISAdapterConfig * _Nonnull)adapterConfig delegate:(id<ISBannerAdapterDelegate> _Nonnull)delegate size:(ISBannerSize * _Nonnull)size serverData:(NSString *)serverData{
    NSString *placementId = adapterConfig.settings[kPlacementId];
    LogAdapterApi_Internal(@"placementId = %@", placementId);
    
    [self.dispatcher dispatchAsyncWithQueue:dispatch_get_main_queue() withBlock:^{
        
        // verify banner
        if ([self isBannerSizeSupported:size]) {
            
            // get listener
            ISInMobiBannerListener* listener = [_placementIdToBannerListener objectForKey:placementId];
            
            // create banner
            IMBanner *inMobiBanner = [self getInMobiBanner:listener size:size placementId:placementId];
            [inMobiBanner shouldAutoRefresh:NO];
            
            // add to dictionary
            [_placementIdToBannerAd setObject:inMobiBanner forKey:placementId];
            
            // load ad
            if(serverData == nil) {
                inMobiBanner.extras = @{@"tp": @"c_supersonic",@"tp-ver": @"ADAPTER_VERSION"}; // For supply source identification
                [inMobiBanner load];
            } else {
                NSData* data = [serverData dataUsingEncoding:NSUTF8StringEncoding];
                [inMobiBanner load:data];
            }
            
        } else {
            // banner size not supported
            NSError *error = [NSError errorWithDomain:kAdapterName code:ERROR_BN_UNSUPPORTED_SIZE
                                userInfo:@{NSLocalizedDescriptionKey:@"unsupported banner size"}];
            LogAdapterApi_Internal(@"error = %@", error);
            [delegate adapterBannerDidFailToLoadWithError:error];
        }
    }];
}

/// This method will not be called from version 6.14.0 - we leave it here for backwords compatibility
- (void)reloadBannerWithAdapterConfig:(nonnull ISAdapterConfig *)adapterConfig delegate:(nonnull id <ISBannerAdapterDelegate>)delegate {
    NSString *placementId = adapterConfig.settings[kPlacementId];
    LogAdapterApi_Internal(@"placementId = %@", placementId);
    
    IMBanner *banner = [_placementIdToBannerAd objectForKey:placementId];
    if (banner == nil) {
        id<ISBannerAdapterDelegate> delegate = [_placementIdToBannerSmashDelegate objectForKey:placementId];
        NSError *error = [NSError errorWithDomain:kAdapterName code:ERROR_BN_LOAD_EXCEPTION
                            userInfo:@{NSLocalizedDescriptionKey:@"Can't reload: null ad"}];
        LogAdapterApi_Internal(@"error = %@", error);
        if (delegate != nil) {
            [delegate adapterBannerDidFailToLoadWithError:error];
        }
    }
    else {
        [self.dispatcher dispatchAsyncWithQueue:dispatch_get_main_queue() withBlock:^{
            [banner load];
        }];
    }
}

- (void)destroyBannerWithAdapterConfig:(nonnull ISAdapterConfig *)adapterConfig {
    NSString *placementId = adapterConfig.settings[kPlacementId];
    LogAdapterApi_Internal(@"placementId = %@", placementId);
    IMBanner *banner = [_placementIdToBannerAd objectForKey:placementId];
    if(banner != nil) {
        [banner removeFromSuperview];
        banner.delegate = nil;
        banner = nil;
        [_placementIdToBannerAd removeObjectForKey:placementId];
        [_placementIdToBannerListener removeObjectForKey:placementId];
        [_placementIdToBannerSmashDelegate removeObjectForKey:placementId];
    }
}

- (void)releaseMemoryWithAdapterConfig:(ISAdapterConfig *)adapterConfig {
    // releasing memory currently only for banners
    [self destroyBannerWithAdapterConfig:adapterConfig];
}


#pragma mark - Rewarded Video Delegate

- (void)rewardedVideoDidFinishLoading:(IMInterstitial *)interstitial placementId:(NSString *)placementId {
    LogAdapterDelegate_Internal(@"placementId = %@", placementId);
    id<ISRewardedVideoAdapterDelegate> delegate = [_placementIdToRewardedVideoSmashDelegate objectForKey:placementId];
    if (delegate != nil) {
        [delegate adapterRewardedVideoHasChangedAvailability:YES];
    }
}

- (void)rewardedVideo:(IMInterstitial *)interstitial didFailToLoadWithError:(IMRequestStatus *)error placementId:(NSString *)placementId {
    LogAdapterDelegate_Internal(@"placementId = %@", placementId);
    LogAdapterDelegate_Internal(@"error = %@", error);
    id<ISRewardedVideoAdapterDelegate> delegate = [_placementIdToRewardedVideoSmashDelegate objectForKey:placementId];
    if (delegate != nil) {
        NSError *smashError = nil;
        if (error.code == kIMStatusCodeNoFill){
            // no fill
            smashError = [NSError errorWithDomain:kAdapterName code:ERROR_RV_LOAD_NO_FILL
                                      userInfo:@{NSLocalizedDescriptionKey:@"no fill"}];
        } else {
            smashError = error;
        }
        [delegate adapterRewardedVideoHasChangedAvailability:NO];
        [delegate adapterRewardedVideoDidFailToLoadWithError:smashError];
    }
}

- (void)rewardedVideoDidPresent:(IMInterstitial *)interstitial placementId:(NSString *)placementId{
    LogAdapterDelegate_Internal(@"placementId = %@", placementId);
    id<ISRewardedVideoAdapterDelegate> delegate = [_placementIdToRewardedVideoSmashDelegate objectForKey:placementId];
    if (delegate != nil) {
        [delegate adapterRewardedVideoDidOpen];
    }
}

- (void)rewardedVideo:(IMInterstitial *)interstitial didFailToPresentWithError:(IMRequestStatus *)error placementId:(NSString *)placementId{
    LogAdapterDelegate_Internal(@"placementId = %@", placementId);
    LogAdapterDelegate_Internal(@"error = %@", error);
    id<ISRewardedVideoAdapterDelegate> delegate = [_placementIdToRewardedVideoSmashDelegate objectForKey:placementId];
    if (delegate != nil) {
        [delegate adapterRewardedVideoDidFailToShowWithError:error];
    }
}


- (void)rewardedVideoDidDismiss:(IMInterstitial *)interstitial placementId:(NSString *)placementId{
    LogAdapterDelegate_Internal(@"placementId = %@", placementId);
    id<ISRewardedVideoAdapterDelegate> delegate = [_placementIdToRewardedVideoSmashDelegate objectForKey:placementId];
    if (delegate != nil) {
        [delegate adapterRewardedVideoDidClose];
    }
}

- (void)rewardedVideo:(IMInterstitial *)interstitial didInteractWithParams:(NSDictionary *)params placementId:(NSString *)placementId {
    LogAdapterDelegate_Internal(@"placementId = %@", placementId);
    id<ISRewardedVideoAdapterDelegate> delegate = [_placementIdToRewardedVideoSmashDelegate objectForKey:placementId];
    if (delegate != nil) {
        [delegate adapterRewardedVideoDidClick];
    }
}

- (void)rewardedVideo:(IMInterstitial *)interstitial rewardActionCompletedWithRewards:(NSDictionary *)rewards placementId:(NSString *)placementId {
    LogAdapterDelegate_Internal(@"placementId = %@", placementId);
    id<ISRewardedVideoAdapterDelegate> delegate = [_placementIdToRewardedVideoSmashDelegate objectForKey:placementId];
    if (delegate != nil) {
        [delegate adapterRewardedVideoDidReceiveReward];
    }
}


#pragma mark - Interstitial Delegate

- (void)interstitialDidFinishLoading:(IMInterstitial *)interstitial placementId:(NSString *)placementId {
    LogAdapterDelegate_Internal(@"placementId = %@", placementId);
    id<ISInterstitialAdapterDelegate> delegate = [_placementIdToInterstitialSmashDelegate objectForKey:placementId];
    if (delegate != nil) {
        [delegate adapterInterstitialDidLoad];
    }
}

- (void)interstitial:(IMInterstitial *)interstitial didFailToLoadWithError:(IMRequestStatus *)error placementId:(NSString *)placementId {
    LogAdapterDelegate_Internal(@"placementId = %@", placementId);
    LogAdapterDelegate_Internal(@"error = %@", error);
    id<ISInterstitialAdapterDelegate> delegate = [_placementIdToInterstitialSmashDelegate objectForKey:placementId];
    if (delegate != nil) {
        NSError *smashError = nil;
        if (error.code == kIMStatusCodeNoFill){
            // no fill
            smashError = [NSError errorWithDomain:kAdapterName code:ERROR_IS_LOAD_NO_FILL
                                      userInfo:@{NSLocalizedDescriptionKey:@"no fill"}];
        } else {
            smashError = error;
        }
        [delegate adapterInterstitialDidFailToLoadWithError:smashError];
    }
}

- (void)interstitialDidPresent:(IMInterstitial *)interstitial placementId:(NSString *)placementId{
    LogAdapterDelegate_Internal(@"placementId = %@", placementId);
    id<ISInterstitialAdapterDelegate> delegate = [_placementIdToInterstitialSmashDelegate objectForKey:placementId];
    if (delegate != nil) {
        [delegate adapterInterstitialDidOpen];
        [delegate adapterInterstitialDidShow];
    }
}

- (void)interstitial:(IMInterstitial *)interstitial didFailToPresentWithError:(IMRequestStatus *)error placementId:(NSString *)placementId{
    LogAdapterDelegate_Internal(@"placementId = %@", placementId);
    LogAdapterDelegate_Internal(@"error = %@", error);
    id<ISInterstitialAdapterDelegate> delegate = [_placementIdToInterstitialSmashDelegate objectForKey:placementId];
    if (delegate != nil) {
        [delegate adapterInterstitialDidFailToShowWithError:error];
    }
}

- (void)interstitialDidDismiss:(IMInterstitial *)interstitial placementId:(NSString *)placementId{
    LogAdapterDelegate_Internal(@"placementId = %@", placementId);
    id<ISInterstitialAdapterDelegate> delegate = [_placementIdToInterstitialSmashDelegate objectForKey:placementId];
    if (delegate != nil) {
        [delegate adapterInterstitialDidClose];
    }
}

- (void)interstitial:(IMInterstitial *)interstitial didInteractWithParams:(NSDictionary *)params placementId:(NSString *)placementId {
    LogAdapterDelegate_Internal(@"placementId = %@", placementId);
    id<ISInterstitialAdapterDelegate> delegate = [_placementIdToInterstitialSmashDelegate objectForKey:placementId];
    if (delegate != nil) {
        [delegate adapterInterstitialDidClick];
    }
}

#pragma mark - Banner Delegate

- (void)bannerDidFinishLoading:(IMBanner *)banner placementId:(NSString *)placementId{
    LogAdapterDelegate_Internal(@"placementId = %@", placementId);
    id<ISBannerAdapterDelegate> delegate = [_placementIdToBannerSmashDelegate objectForKey:placementId];
    if (delegate != nil) {
        [delegate adapterBannerDidLoad:banner];
        [delegate adapterBannerDidShow];

    }
}

- (void)banner:(IMBanner *)banner didFailToLoadWithError:(IMRequestStatus *)error placementId:(NSString *)placementId{
    LogAdapterDelegate_Internal(@"placementId = %@", placementId);
    id<ISBannerAdapterDelegate> delegate = [_placementIdToBannerSmashDelegate objectForKey:placementId];
    if (delegate != nil) {
        
        NSError* smashError;
        if (error.code == kIMStatusCodeNoFill){
            // no fill
            smashError = [NSError errorWithDomain:kAdapterName code:ERROR_BN_LOAD_NO_FILL
                                      userInfo:@{NSLocalizedDescriptionKey:@"no fill"}];
        } else {
            smashError = error;
        }
        
        [delegate adapterBannerDidFailToLoadWithError:smashError];
    }
}

-(void)banner:(IMBanner *)banner didInteractWithParams:(NSDictionary *)params placementId:(NSString *)placementId{
    LogAdapterDelegate_Internal(@"placementId = %@", placementId);
    id<ISBannerAdapterDelegate> delegate = [_placementIdToBannerSmashDelegate objectForKey:placementId];
    if (delegate != nil) {
        [delegate adapterBannerDidClick];
    }
}

-(void)userWillLeaveApplicationFromBanner:(IMBanner *)banner placementId:(NSString *)placementId{
    LogAdapterDelegate_Internal(@"placementId = %@", placementId);
    id<ISBannerAdapterDelegate> delegate = [_placementIdToBannerSmashDelegate objectForKey:placementId];
    if (delegate != nil) {
        [delegate adapterBannerWillLeaveApplication];
    }
}

- (void)bannerWillPresentScreenForPlacementId:(NSString *)placementId {
    LogAdapterDelegate_Internal(@"placementId = %@", placementId);
    id<ISBannerAdapterDelegate> delegate = [_placementIdToBannerSmashDelegate objectForKey:placementId];
    if (delegate != nil) {
        [delegate adapterBannerWillPresentScreen];
    }
}
- (void)bannerDidDismissScreenForPlacementId:(NSString *)placementId {
    LogAdapterDelegate_Internal(@"placementId = %@", placementId);
    id<ISBannerAdapterDelegate> delegate = [_placementIdToBannerSmashDelegate objectForKey:placementId];
    if (delegate != nil) {
        [delegate adapterBannerDidDismissScreen];
    }
}



#pragma mark - Private Methods

- (void)initSDKWithAccountId:(NSString *)accountId {
    LogAdapterApi_Internal(@"");
    
    // add self to init delegates only
    // when init not finished yet
    if(_initState == INIT_STATE_NONE || _initState == INIT_STATE_IN_PROGRESS){
        [initCallbackDelegates addObject:self];
    }
    
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        if (_initState == INIT_STATE_NONE) {

            // set init state in progress
            _initState = INIT_STATE_IN_PROGRESS;
            BOOL isAdapterDebug = [ISConfigurations getConfigurations].adaptersDebug;
            [IMSdk setLogLevel: isAdapterDebug ? kIMSDKLogLevelDebug : kIMSDKLogLevelNone];
            NSString *message = [NSString stringWithFormat:@"ISInMobiAdapter:setLogLevel:%@",(isAdapterDebug ? @"YES" : @"NO")];
            LogAdapterApi_Internal(@"setLogLevel - message = %@", message);
            
            [IMSdk initWithAccountID:accountId consentDictionary:[self getConsentDictionary] andCompletionHandler:^(NSError *error) {
                if (error == nil) {
                    // set init state success
                    _initState = INIT_STATE_SUCCESS;
                    

                    NSArray* initDelegatesList = initCallbackDelegates.allObjects;

                    // call init callback delegate success
                    for(id<ISNetworkInitCallbackProtocol> delegate in initDelegatesList){
                        [delegate onNetworkInitCallbackSuccess];
                    }
                    
                } else {
                    // set init state failed
                    _initState = INIT_STATE_ERROR;
                    
                    NSArray* initDelegatesList = initCallbackDelegates.allObjects;
                    
                    for(id<ISNetworkInitCallbackProtocol> delegate in initDelegatesList){
                            [delegate onNetworkInitCallbackFailed:@"init failed"];
                        }
                }
                
                [initCallbackDelegates removeAllObjects];
            }];
        }
    });
}

- (BOOL) isValidAgeRestrictionMetaData:(NSString *)key
                              andValue:(NSString *)value {
    return ([key caseInsensitiveCompare:kMetaDataAgeRestrictedKey] == NSOrderedSame && (value.length));
}

- (void) setAgeRestricted:(BOOL)isAgeRestricted {
    LogAdapterApi_Internal(@"isAgeRestricted = %@", isAgeRestricted ? @"YES" : @"NO");

    if (_initState == INIT_STATE_SUCCESS) {
        [IMSdk setIsAgeRestricted:isAgeRestricted];
    } else {
        _ageRestrictionCollecctingUserData = isAgeRestricted;
    }
}

- (void)onNetworkInitCallbackSuccess {
    LogAdapterApi_Internal(@"");

    if (_consentCollectingUserData != nil) {
        [self setAgeRestricted:_consentCollectingUserData];
    }
    
    // handle rewarded video
    NSArray *rewardedVideoPlacementIDs = _placementIdToRewardedVideoSmashDelegate.allKeys;

    for (NSString* placementId in rewardedVideoPlacementIDs) {
        id<ISRewardedVideoAdapterDelegate> delegate = [_placementIdToRewardedVideoSmashDelegate objectForKey:placementId];
        if ([_programmaticPlacementIds hasObject:placementId]) {
            LogAdapterApi_Internal(@"adapterRewardedVideoInitSuccess - placementId = %@", placementId);
            [delegate adapterRewardedVideoInitSuccess];
        } else {
            LogAdapterApi_Internal(@"loadVideoInternal - placementId = %@", placementId);
            [self loadRewardedVideoWithPlacementId:placementId serverData:nil];
        }
    }
    
    // handle interstitial
    NSArray *interstitialPlacementIDs = _placementIdToInterstitialSmashDelegate.allKeys;

    for (NSString *placementId in interstitialPlacementIDs) {
        id<ISInterstitialAdapterDelegate> delegate = [_placementIdToInterstitialSmashDelegate objectForKey:placementId];
        [delegate adapterInterstitialInitSuccess];
    }
    
    // handle banners
    NSArray *bannerPlacementIDs = _placementIdToBannerSmashDelegate.allKeys;

    for (NSString *placementId in bannerPlacementIDs) {
        id<ISBannerAdapterDelegate> delegate = [_placementIdToBannerSmashDelegate objectForKey:placementId];
        [delegate adapterBannerInitSuccess];
    }
}

- (void)onNetworkInitCallbackFailed:(nonnull NSString *)errorMessage {

    NSError *error = [NSError errorWithDomain:kAdapterName code:ERROR_CODE_INIT_FAILED
                                                       userInfo:@{NSLocalizedDescriptionKey:errorMessage}];
    LogAdapterDelegate_Internal(@"error = %@", error);
    
    // handle rewarded video
    NSArray *rewardedVideoPlacementIDs = _placementIdToRewardedVideoSmashDelegate.allKeys;
    
    for (NSString* placementId in rewardedVideoPlacementIDs) {
        id<ISRewardedVideoAdapterDelegate> delegate = [_placementIdToRewardedVideoSmashDelegate objectForKey:placementId];
        if ([_programmaticPlacementIds hasObject:placementId]) {
            LogAdapterApi_Internal(@"adapterRewardedVideoInitFailed - error = %@", error);
            [delegate adapterRewardedVideoInitFailed:error];
        } else {
            LogAdapterApi_Internal(@"adapterRewardedVideoHasChangedAvailability:NO");
            [delegate adapterRewardedVideoHasChangedAvailability:NO];
        }
    }
    
    // handle interstitial
    NSArray *interstitialPlacementIDs = _placementIdToInterstitialSmashDelegate.allKeys;
    
    for (NSString *placementId in interstitialPlacementIDs) {
        id<ISInterstitialAdapterDelegate> delegate = [_placementIdToInterstitialSmashDelegate objectForKey:placementId];
        [delegate adapterInterstitialInitFailedWithError:error];
    }
    
    // handle banners
    NSArray *bannerPlacementIDs = _placementIdToBannerSmashDelegate.allKeys;
    
    for (NSString *placementId in bannerPlacementIDs) {
        id<ISBannerAdapterDelegate> delegate = [_placementIdToBannerSmashDelegate objectForKey:placementId];
        [delegate adapterBannerInitFailedWithError:error];
    }
}

- (IMBanner *)getInMobiBanner:(id<IMBannerDelegate>)delegate size:(ISBannerSize *)size placementId:(NSString *)placementId{
    IMBanner *inMobiBanner = nil;
    
    if ([size.sizeDescription isEqualToString:@"BANNER"] || [size.sizeDescription isEqualToString:@"LARGE"]) {
        inMobiBanner = [[IMBanner alloc] initWithFrame:CGRectMake(0, 0, 320, 50) placementId:[placementId longLongValue] delegate:delegate];
        
    } else if ([size.sizeDescription isEqualToString:@"RECTANGLE"]) {
        inMobiBanner = [[IMBanner alloc] initWithFrame:CGRectMake(0, 0, 300, 250) placementId:[placementId longLongValue] delegate:delegate];
        
    } else if ([size.sizeDescription isEqualToString:@"SMART"]) {
        if (UI_USER_INTERFACE_IDIOM() == UIUserInterfaceIdiomPad) {
            inMobiBanner = [[IMBanner alloc] initWithFrame:CGRectMake(0, 0, 728, 90) placementId:[placementId longLongValue] delegate:delegate];
        } else {
            inMobiBanner = [[IMBanner alloc] initWithFrame:CGRectMake(0, 0, 320, 50) placementId:[placementId longLongValue] delegate:delegate];
        }
        
    } else if ([size.sizeDescription isEqualToString:@"CUSTOM"]) {
        inMobiBanner = [[IMBanner alloc] initWithFrame:CGRectMake(0, 0, size.width, size.height) placementId:[placementId longLongValue] delegate:delegate];
    }
    
    return inMobiBanner;
}

- (BOOL)isBannerSizeSupported:(ISBannerSize *)size {
    BOOL isSupported = NO;
    
    if ([size.sizeDescription isEqualToString:@"BANNER"] || [size.sizeDescription isEqualToString:@"LARGE"]) {
        isSupported = YES;
    } else if ([size.sizeDescription isEqualToString:@"RECTANGLE"]) {
        isSupported = YES;
    } else if ([size.sizeDescription isEqualToString:@"SMART"]) {
        isSupported = YES;
    } else if ([size.sizeDescription isEqualToString:@"CUSTOM"]) {
        isSupported = YES;
    }
    
    return isSupported;
}

- (NSDictionary *)getConsentDictionary {
    if (_consentCollectingUserData == nil || _consentCollectingUserData.length == 0) {
        return @{};
    } else {
        return @{IM_GDPR_CONSENT_AVAILABLE:_consentCollectingUserData};
    }
}

- (NSDictionary *)getBiddingData {
    if (_initState != INIT_STATE_SUCCESS) {
        LogAdapterApi_Internal(@"returning nil as token since init failed");
        return nil;
    }
    NSDictionary* extras = @{@"tp": @"c_supersonic", @"tp-ver": @"ADAPTER_VERSION"};
    NSString *bidderToken = [IMSdk getTokenWithExtras:extras andKeywords:@""];
    NSString *returnedToken = bidderToken? bidderToken : @"";
    LogAdapterApi_Internal(@"token = %@", returnedToken);
    
    return @{@"token": returnedToken};
}


@end
