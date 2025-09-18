//
//  ISFacebookRewardedVideoAdapter.m
//  ISFacebookAdapter
//
//  Copyright © 2021-2025 Unity Technologies. All rights reserved.
//

#import "ISFacebookRewardedVideoAdapter.h"
#import "ISFacebookRewardedVideoDelegate.h"
#import <FBAudienceNetwork/FBAudienceNetwork.h>

@interface ISFacebookRewardedVideoAdapter ()

@property (nonatomic, weak) ISFacebookAdapter   *adapter;

@property (nonatomic, strong) ISConcurrentMutableDictionary     *adUnitPlacementIdToSmashDelegate;
@property (nonatomic, strong) ISConcurrentMutableDictionary     *adUnitPlacementIdToAdDelegate;
@property (nonatomic, strong) ISConcurrentMutableDictionary     *adUnitPlacementIdToAd;

@end

@implementation ISFacebookRewardedVideoAdapter

- (instancetype)initWithFacebookAdapter:(ISFacebookAdapter *)adapter {
    self = [super init];
    if (self) {
        _adapter                                 = adapter;
        _adUnitPlacementIdToSmashDelegate        = [ISConcurrentMutableDictionary dictionary];
        _adUnitPlacementIdToAdDelegate           = [ISConcurrentMutableDictionary dictionary];
        _adUnitPlacementIdToAd                   = [ISConcurrentMutableDictionary dictionary];
    }
    return self;
}

// Used for flows when the mediation needs to get a callback for init
- (void)initRewardedVideoForCallbacksWithUserId:(NSString *)userId
                                  adapterConfig:(ISAdapterConfig *)adapterConfig
                                       delegate:(id<ISRewardedVideoAdapterDelegate>)delegate {
    NSString *placementId = [self getStringValueFromAdapterConfig:adapterConfig
                                                           forKey:kPlacementId];
    NSString *allPlacementIds = [self getStringValueFromAdapterConfig:adapterConfig
                                                               forKey:kAllPlacementIds];

    /* Configuration Validation */
    if (![self.adapter isConfigValueValid:placementId]) {
        NSError *error = [self.adapter errorForMissingCredentialFieldWithName:kPlacementId];
        LogAdapterApi_Internal(@"error.description = %@", error.description);
        [delegate adapterRewardedVideoInitFailed:error];
        return;
    }
    
    if (![self.adapter isConfigValueValid:allPlacementIds]) {
        NSError *error = [self.adapter errorForMissingCredentialFieldWithName:kAllPlacementIds];
        LogAdapterApi_Internal(@"error.description = %@", error.description);
        [delegate adapterRewardedVideoInitFailed:error];
        return;
    }
    
    LogAdapterApi_Internal(@"placementId = %@", placementId);

    //add to rewarded video delegate map
    [self.adUnitPlacementIdToSmashDelegate setObject:delegate
                                              forKey:placementId];
                
    switch ([self.adapter getInitState]) {
        case INIT_STATE_NONE:
        case INIT_STATE_IN_PROGRESS:
            [self.adapter initSDKWithPlacementIds:allPlacementIds];
            break;
        case INIT_STATE_SUCCESS:
            [delegate adapterRewardedVideoInitSuccess];
            break;
        case INIT_STATE_FAILED: {
            LogAdapterApi_Internal(@"init failed - placementId = %@", placementId);
            NSError *error = [NSError errorWithDomain:kAdapterName
                                                 code:ERROR_CODE_INIT_FAILED
                                             userInfo:@{NSLocalizedDescriptionKey:@"Meta SDK init failed"}];
            [delegate adapterRewardedVideoInitFailed:error];
            break;
        }
    }
}

- (void)loadRewardedVideoForBiddingWithAdapterConfig:(ISAdapterConfig *)adapterConfig
                                              adData:(NSDictionary *)adData
                                          serverData:(NSString *)serverData
                                            delegate:(id<ISRewardedVideoAdapterDelegate>)delegate {
   
    NSString *placementId = [self getStringValueFromAdapterConfig:adapterConfig
                                                           forKey:kPlacementId];
    
    dispatch_async(dispatch_get_main_queue(), ^{
        LogAdapterApi_Internal(@"placementId = %@", placementId);

        @try {
            
            //add to rewarded video delegate map
            [self.adUnitPlacementIdToSmashDelegate setObject:delegate
                                                      forKey:placementId];
            
            ISFacebookRewardedVideoDelegate *rewardedVideoAdDelegate = [[ISFacebookRewardedVideoDelegate alloc] initWithPlacementId:placementId
                                                                                                                        andDelegate:delegate];
            [self.adUnitPlacementIdToAdDelegate setObject:rewardedVideoAdDelegate
                                                   forKey:placementId];

            FBRewardedVideoAd *ad = [[FBRewardedVideoAd alloc] initWithPlacementID:placementId];
            ad.delegate = rewardedVideoAdDelegate;
            
            [self.adUnitPlacementIdToAd setObject:ad
                                           forKey:placementId];
            
            if (serverData == nil) {
                [ad loadAd];
            } else {
                [ad loadAdWithBidPayload:serverData];
            }
        } @catch (NSException *exception) {
            LogAdapterApi_Internal(@"exception = %@", exception);
            [delegate adapterRewardedVideoHasChangedAvailability:NO];
        }
    });
}

- (void)showRewardedVideoWithViewController:(UIViewController *)viewController
                              adapterConfig:(ISAdapterConfig *)adapterConfig
                                   delegate:(id<ISRewardedVideoAdapterDelegate>)delegate {

    dispatch_async(dispatch_get_main_queue(), ^{
        NSString *placementId = [self getStringValueFromAdapterConfig:adapterConfig
                                                               forKey:kPlacementId];
        LogAdapterApi_Internal(@"placementId = %@", placementId);

        @try {
            
            if ([self hasRewardedVideoWithAdapterConfig:adapterConfig]) {
                
                FBRewardedVideoAd *ad = [self.adUnitPlacementIdToAd objectForKey:placementId];
                
                // set dynamic user id to ad if exists
                if ([self.adapter dynamicUserId]) {
                    [ad setRewardDataWithUserID:[self.adapter dynamicUserId]
                                   withCurrency:@""];
                }
                
                [ad showAdFromRootViewController:viewController];

            } else {
                NSError *error = [ISError createError:ERROR_CODE_NO_ADS_TO_SHOW
                                          withMessage:[NSString stringWithFormat: @"%@ show failed", kAdapterName]];
                [delegate adapterRewardedVideoDidFailToShowWithError:error];
            }
            
        } @catch (NSException *exception) {
            LogAdapterApi_Internal(@"exception = %@", exception);
            NSError *error = [ISError createError:ERROR_CODE_GENERIC
                                      withMessage:[NSString stringWithFormat: @"%@ show failed", kAdapterName]];
            [delegate adapterRewardedVideoDidFailToShowWithError:error];
        }
    });
}

- (BOOL)hasRewardedVideoWithAdapterConfig:(ISAdapterConfig *)adapterConfig {
    NSString *placementId = [self getStringValueFromAdapterConfig:adapterConfig
                                                           forKey:kPlacementId];
    FBRewardedVideoAd *ad = [self.adUnitPlacementIdToAd objectForKey:placementId];
    return ad.adValid;
}

- (NSDictionary *)getRewardedVideoBiddingDataWithAdapterConfig:(ISAdapterConfig *)adapterConfig
                                                        adData:(NSDictionary *)adData {
    LogAdapterApi_Internal(@"");
    return [self.adapter getBiddingData];
}

#pragma mark - Init Delegate

- (void)onNetworkInitCallbackSuccess {
    NSArray *placementIds = self.adUnitPlacementIdToSmashDelegate.allKeys;
    
    for (NSString *placementId in placementIds) {
        id<ISRewardedVideoAdapterDelegate> delegate = [self.adUnitPlacementIdToSmashDelegate objectForKey:placementId];
        [delegate adapterRewardedVideoInitSuccess];
    }
}

- (void)onNetworkInitCallbackFailed:(NSString *)errorMessage {
    NSError *error = [ISError createErrorWithDomain:kAdapterName
                                               code:ERROR_CODE_INIT_FAILED
                                            message:errorMessage];
    
    NSArray *placementIds = self.adUnitPlacementIdToSmashDelegate.allKeys;
    
    for (NSString *placementId in placementIds) {
        id<ISRewardedVideoAdapterDelegate> delegate = [self.adUnitPlacementIdToSmashDelegate objectForKey:placementId];
        [delegate adapterRewardedVideoInitFailed:error];
    }
}

@end
