//
//  ISAdMobRewardedVideoAdapter.m
//  ISAdMobAdapter
//
//  Copyright © 2021-2025 Unity Technologies. All rights reserved.
//

#import "ISAdMobRewardedVideoAdapter.h"
#import "ISAdMobRewardedVideoDelegate.h"

@interface ISAdMobRewardedVideoAdapter ()

@property (nonatomic, weak) ISAdMobAdapter *adapter;

@property (nonatomic, strong) ISConcurrentMutableDictionary *adUnitIdToAds;
@property (nonatomic, strong) ISConcurrentMutableDictionary *adUnitIdToSmashDelegate;
@property (nonatomic, strong) ISConcurrentMutableDictionary *adUnitIdToAdsAvailability;
@property (nonatomic, strong) ISConcurrentMutableDictionary *adUnitIdToAdDelegate;
@property (nonatomic, strong) ISConcurrentMutableDictionary *adUnitIdToAdData;
@property (nonatomic, strong) NSMutableSet                  *adUnitIdForInitCallbacks;

@end

@implementation ISAdMobRewardedVideoAdapter

- (instancetype)initWithAdMobAdapter:(ISAdMobAdapter *)adapter {
    self = [super init];
    if (self) {
        _adapter                        = adapter;
        _adUnitIdToAds                  = [ISConcurrentMutableDictionary dictionary];
        _adUnitIdToSmashDelegate        = [ISConcurrentMutableDictionary dictionary];
        _adUnitIdToAdsAvailability      = [ISConcurrentMutableDictionary dictionary];
        _adUnitIdToAdDelegate           = [ISConcurrentMutableDictionary dictionary];
        _adUnitIdToAdData               = [ISConcurrentMutableDictionary dictionary];
        _adUnitIdForInitCallbacks       = [[NSMutableSet alloc] init];
    }
    return self;
}

#pragma mark - Rewarded Video API

// Used for flows when the mediation needs to get a callback for init
- (void)initRewardedVideoForCallbacksWithUserId:(NSString *)userId
                                  adapterConfig:(ISAdapterConfig *)adapterConfig
                                       delegate:(id<ISRewardedVideoAdapterDelegate>)delegate {
    dispatch_async(dispatch_get_main_queue(), ^{
        
        NSString *adUnitId = adapterConfig.settings[kAdUnitId];
        
        /* Configuration Validation */
        if (![self.adapter isConfigValueValid:adUnitId]) {
            NSError *error = [self.adapter errorForMissingCredentialFieldWithName:kAdUnitId];
            LogAdapterApi_Internal(@"error.description = %@", error.description);
            [delegate adapterRewardedVideoInitFailed:error];
            return;
        }
        
        LogAdapterApi_Internal(@"adUnitId = %@", adUnitId);
        
        [self.adUnitIdToSmashDelegate setObject:delegate
                                         forKey:adUnitId];
        [self.adUnitIdForInitCallbacks addObject:adUnitId];
        
        switch ([self.adapter getInitState]) {
            case INIT_STATE_NONE:
            case INIT_STATE_IN_PROGRESS:
                [self.adapter initAdMobSDKWithAdapterConfig:adapterConfig];
                break;
            case INIT_STATE_FAILED: {
                LogAdapterApi_Internal(@"init failed - adUnitId = %@", adUnitId);
                [delegate adapterRewardedVideoInitFailed:[ISError createError:ERROR_CODE_INIT_FAILED
                                                                  withMessage:@"AdMob SDK init failed"]];
                break;
            }
            case INIT_STATE_SUCCESS:
                [delegate adapterRewardedVideoInitSuccess];
                break;
                
        }
    });
}

// Used for flows when the mediation doesn't need to get a callback for init
- (void)initAndLoadRewardedVideoWithUserId:(NSString *)userId
                             adapterConfig:(ISAdapterConfig *)adapterConfig
                                    adData:(NSDictionary *)adData
                                  delegate:(id<ISRewardedVideoAdapterDelegate>)delegate {
    dispatch_async(dispatch_get_main_queue(), ^{
        NSString *adUnitId = adapterConfig.settings[kAdUnitId];
        
        
        /* Configuration Validation */
        if (![self.adapter isConfigValueValid:adUnitId]) {
            NSError *error = [self.adapter errorForMissingCredentialFieldWithName:kAdUnitId];
            LogAdapterApi_Internal(@"error.description = %@", error.description);
            [delegate adapterRewardedVideoHasChangedAvailability:NO];
            return;
        }
        
        LogAdapterApi_Internal(@"adUnitId = %@", adUnitId);
        
        //add to rewarded video delegate map
        [self.adUnitIdToSmashDelegate setObject:delegate
                                         forKey:adUnitId];
        
        switch ([self.adapter getInitState]) {
            case INIT_STATE_NONE:
            case INIT_STATE_IN_PROGRESS:
                if (adData) {
                    [self.adUnitIdToAdData setObject:adData
                                              forKey:adUnitId];
                }
                
                [self.adapter initAdMobSDKWithAdapterConfig:adapterConfig];
                break;
            case INIT_STATE_FAILED: {
                LogAdapterApi_Internal(@"init failed - adUnitId = %@", adUnitId);
                [delegate adapterRewardedVideoHasChangedAvailability:NO];
                break;
            }
            case INIT_STATE_SUCCESS:
                [self loadRewardedVideoInternal:adUnitId
                                         adData:adData
                                     serverData:nil
                                       delegate:delegate];
                break;
                
        }
    });
}

- (void)loadRewardedVideoForBiddingWithAdapterConfig:(ISAdapterConfig *)adapterConfig
                                              adData:(NSDictionary *)adData
                                          serverData:(NSString *)serverData
                                            delegate:(id<ISRewardedVideoAdapterDelegate>)delegate {
    NSString *adUnitId = adapterConfig.settings[kAdUnitId];
    LogAdapterApi_Internal(@"adUnitId = %@", adUnitId);
    [self loadRewardedVideoInternal:adUnitId
                             adData:adData
                         serverData:serverData
                           delegate:delegate];
    
}

- (void)loadRewardedVideoWithAdapterConfig:(ISAdapterConfig *)adapterConfig
                                    adData:(NSDictionary *)adData
                                  delegate:(id<ISRewardedVideoAdapterDelegate>)delegate {
    NSString *adUnitId = adapterConfig.settings[kAdUnitId];
    LogAdapterApi_Internal(@"adUnitId = %@", adUnitId);
    [self loadRewardedVideoInternal:adUnitId
                             adData:adData
                         serverData:nil
                           delegate:delegate];
}

- (void)loadRewardedVideoInternal:(NSString *)adUnitId
                           adData:(NSDictionary *)adData
                       serverData:(NSString *)serverData
                         delegate:(id<ISRewardedVideoAdapterDelegate>)delegate {
    [self.adUnitIdToAdsAvailability setObject:@NO
                                       forKey:adUnitId];
    //add to rewarded video delegate map
    [self.adUnitIdToSmashDelegate setObject:delegate
                                     forKey:adUnitId];
            
    GADRewardedAdLoadCompletionHandler loadHandler = ^(GADRewardedAd *_Nullable rewardedAd, NSError *_Nullable error) {
        if (error) {
            LogAdapterDelegate_Internal(@"adUnitId = %@ failed to load with error = %@", adUnitId, error);
            NSError *smashError = (error.code == GADErrorNoFill) ? [ISError createError:ERROR_RV_LOAD_NO_FILL
                                                                             withMessage:@"AdMob no fill"] : error;
            
            [delegate adapterRewardedVideoHasChangedAvailability:NO];
            [delegate adapterRewardedVideoDidFailToLoadWithError:smashError];
            return;
        }
        
        if (!rewardedAd) {
            LogAdapterDelegate_Internal(@"adUnitId = %@ failed to load: ad is nil", adUnitId);
            NSError *error = [ISError createError:ERROR_CODE_GENERIC
                                                withMessage:@"Rewarded ad is nil"];
            
            [delegate adapterRewardedVideoHasChangedAvailability:NO];
            [delegate adapterRewardedVideoDidFailToLoadWithError:error];
            return;
        }
        
        [self handleRewardedVideoLoadSuccess:rewardedAd
                                    adUnitId:adUnitId
                                    delegate:delegate];
    };
    
    if (serverData) {
        // For bidding, use loadWithAdResponseString
        LogAdapterApi_Internal(@"loading bidding rewarded video for adUnitId = %@", adUnitId);
        [GADRewardedAd loadWithAdResponseString:serverData
                              completionHandler:loadHandler];
    } else {
        // For non-bidding, use request
        LogAdapterApi_Internal(@"loading rewarded video for adUnitId = %@", adUnitId);
        GADRequest *request = [self.adapter createGADRequestWithAdData:adData];
        [GADRewardedAd loadWithAdUnitID:adUnitId
                                request:request
                      completionHandler:loadHandler];
    }
}

- (void)showRewardedVideoWithViewController:(UIViewController *)viewController
                              adapterConfig:(ISAdapterConfig *)adapterConfig
                                   delegate:(id<ISRewardedVideoAdapterDelegate>)delegate {
    dispatch_async(dispatch_get_main_queue(), ^{
        NSString *adUnitId = adapterConfig.settings[kAdUnitId];
        
        LogAdapterApi_Internal(@"adUnitId = %@", adUnitId);
        
        GADRewardedAd *rewardedVideoAd = [self.adUnitIdToAds objectForKey:adUnitId];
        
        // Show the ad if it's ready.
        if (rewardedVideoAd && [self hasRewardedVideoWithAdapterConfig:adapterConfig]) {
            
            // Create and save delegate for show callbacks
            ISAdMobRewardedVideoDelegate *rewardedVideoAdDelegate = [[ISAdMobRewardedVideoDelegate alloc] initWithAdapter:self
                                                                                                                 adUnitId:adUnitId
                                                                                                              andDelegate:delegate];
            [self.adUnitIdToAdDelegate setObject:rewardedVideoAdDelegate
                                          forKey:adUnitId];
                        
            rewardedVideoAd.fullScreenContentDelegate = rewardedVideoAdDelegate;
            
            [rewardedVideoAd presentFromRootViewController:viewController
                                  userDidEarnRewardHandler:^{
                LogAdapterApi_Internal(@"adapterRewardedVideoDidReceiveReward");
                [delegate adapterRewardedVideoDidReceiveReward];
            }];
        }
        else {
            NSError *error = [ISError createError:ERROR_CODE_NO_ADS_TO_SHOW
                                      withMessage:[NSString stringWithFormat: @"%@ show failed", kAdapterName]];
            LogAdapterApi_Internal(@"error = %@", error);
            [delegate adapterRewardedVideoDidFailToShowWithError:error];
        }
        // once reward video is displayed or if it's not ready, it's no longer available
        [self.adUnitIdToAdsAvailability setObject:@NO
                                           forKey:adUnitId];
    });
}

- (BOOL)hasRewardedVideoWithAdapterConfig:(ISAdapterConfig *)adapterConfig {
    NSString *adUnitId = adapterConfig.settings[kAdUnitId];
    NSNumber *available = [self.adUnitIdToAdsAvailability objectForKey:adUnitId];
    return [available boolValue];
}

- (void)collectRewardedVideoBiddingDataWithAdapterConfig:(ISAdapterConfig *)adapterConfig
                                                  adData:(NSDictionary *)adData
                                                delegate:(id<ISBiddingDataDelegate>)delegate {
    [self.adapter collectBiddingDataWithAdFormat:GADAdFormatRewarded
                                    adapterConfig:adapterConfig
                                           adData:adData
                                         delegate:delegate];
}

#pragma mark - Init Delegate

- (void)onNetworkInitCallbackSuccess {
    NSArray *rewardedVideoAdUnitIds = self.adUnitIdToSmashDelegate.allKeys;

    for (NSString *adUnitId in rewardedVideoAdUnitIds) {
        id<ISRewardedVideoAdapterDelegate> delegate = [self.adUnitIdToSmashDelegate objectForKey:adUnitId];

        if ([self.adUnitIdForInitCallbacks containsObject:adUnitId]) {
            [delegate adapterRewardedVideoInitSuccess];
        } else {
            NSDictionary *adData = [self.adUnitIdToAdData objectForKey:adUnitId];
            [self loadRewardedVideoInternal:adUnitId
                                     adData:adData
                                 serverData:nil
                                   delegate:delegate];
        }
    }
}

- (void)onNetworkInitCallbackFailed:(NSString *)errorMessage {
    NSError *error = [ISError createErrorWithDomain:kAdapterName
                                               code:ERROR_CODE_INIT_FAILED
                                            message:errorMessage];
    
    NSArray *rewardedVideoAdUnitIds = self.adUnitIdToSmashDelegate.allKeys;

    for (NSString *adUnitId in rewardedVideoAdUnitIds) {
        id<ISRewardedVideoAdapterDelegate> delegate = [self.adUnitIdToSmashDelegate objectForKey:adUnitId];
        if ([self.adUnitIdForInitCallbacks containsObject:adUnitId]) {
            [delegate adapterRewardedVideoInitFailed:error];
        } else {
            [delegate adapterRewardedVideoHasChangedAvailability:NO];
        }

    }
}

#pragma mark - Availability

- (void)onAdUnitAvailabilityChangeWithAdUnitId:(NSString *)adUnitId
                                  availability:(BOOL)availability
                                    rewardedAd:(GADRewardedAd *)rewardedAd {
    if (availability) {
        [self.adUnitIdToAds setObject:rewardedAd
                               forKey:adUnitId];
    }

    [self.adUnitIdToAdsAvailability setObject:@(availability)
                                       forKey:adUnitId];
}

#pragma mark - Helpers

- (GADSignalRequest *)createSignalRequestWithAdData:(NSDictionary *)adData
                                      adapterConfig:(ISAdapterConfig *)adapterConfig {
    return [[GADRewardedSignalRequest alloc] initWithSignalType:kAdMobRequesterType];
}

- (void)handleRewardedVideoLoadSuccess:(GADRewardedAd *)rewardedAd
                              adUnitId:(NSString *)adUnitId
                              delegate:(id<ISRewardedVideoAdapterDelegate>)delegate {
    
    [self onAdUnitAvailabilityChangeWithAdUnitId:adUnitId
                                    availability:YES
                                      rewardedAd:rewardedAd];
        
    NSString *creativeId = rewardedAd.responseInfo.responseIdentifier;
    LogAdapterDelegate_Internal(@"adUnitId = %@ , %@ = %@", adUnitId, kCreativeId, creativeId);

    if (creativeId.length) {
        NSDictionary<NSString *, id> *extraData = @{kCreativeId: creativeId};
        [delegate adapterRewardedVideoHasChangedAvailability:YES
                                                        extraData:extraData];
    } else {
        [delegate adapterRewardedVideoHasChangedAvailability:YES];
    }
}

@end
