//
//  ISMolocoRewardedVideoAdapter.m
//  ISMolocoAdapter
//
//  Copyright © 2024 ironSource. All rights reserved.
//

#import "ISMolocoRewardedVideoAdapter.h"
#import "ISMolocoRewardedVideoDelegate.h"

@interface ISMolocoRewardedVideoAdapter ()

@property (nonatomic, weak)   ISMolocoAdapter *adapter;
@property (nonatomic, strong) id<MolocoRewardedInterstitial> ad;
@property (nonatomic, strong) ISMolocoRewardedVideoDelegate *molocoAdDelegate;
@property (nonatomic, weak) id<ISRewardedVideoAdapterDelegate> smashDelegate;

@end

@implementation ISMolocoRewardedVideoAdapter

- (instancetype)initWithMolocoAdapter:(ISMolocoAdapter *)adapter {
    self = [super init];
    if (self) {
        _adapter = adapter;
        _ad = nil;
        _smashDelegate = nil;
        _molocoAdDelegate = nil;
    }
    return self;
}

#pragma mark - Rewarded Video API

// Used for flows when the mediation needs to get a callback for init
- (void)initRewardedVideoForCallbacksWithUserId:(NSString *)userId
                                  adapterConfig:(ISAdapterConfig *)adapterConfig
                                       delegate:(id<ISRewardedVideoAdapterDelegate>)delegate {
    NSString *appKey = [self getStringValueFromAdapterConfig:adapterConfig
                                                     forKey:kAppKey];
    /* Configuration Validation */
    if (![self.adapter isConfigValueValid:appKey]) {
        NSError *error = [self.adapter errorForMissingCredentialFieldWithName:kAppKey];
        LogAdapterApi_Internal(@"error = %@", error);
        [delegate adapterRewardedVideoInitFailed:error];
        return;
    }

    NSString *adUnitId = [self getStringValueFromAdapterConfig:adapterConfig
                                                        forKey:kAdUnitId];
    /* Configuration Validation */
    if (![self.adapter isConfigValueValid:adUnitId]) {
        NSError *error = [self.adapter errorForMissingCredentialFieldWithName:kAdUnitId];
        LogAdapterApi_Internal(@"error = %@", error);
        [delegate adapterRewardedVideoInitFailed:error];
        return;
    }

    self.smashDelegate = delegate;

    LogAdapterApi_Internal(@"appId = %@, adUnitId = %@", appKey, adUnitId);

    switch ([self.adapter getInitState]) {
        case INIT_STATE_NONE:
        case INIT_STATE_IN_PROGRESS:
            [self.adapter initSDKWithAppKey:appKey];
            break;
        case INIT_STATE_SUCCESS:
            [delegate adapterRewardedVideoInitSuccess];
            break;
            
        case INIT_STATE_FAILED:
            LogAdapterApi_Internal(@"init failed - adUnitId = %@", adUnitId);
            [delegate adapterRewardedVideoInitFailed:[ISError createError:ERROR_CODE_INIT_FAILED
                                                              withMessage:@"Moloco SDK init failed"]];
            break;
    }
}

- (void)loadRewardedVideoForBiddingWithAdapterConfig:(ISAdapterConfig *)adapterConfig
                                              adData:(NSDictionary *)adData
                                          serverData:(NSString *)serverData
                                            delegate:(id<ISRewardedVideoAdapterDelegate>)delegate {
    NSString *adUnitId = [self getStringValueFromAdapterConfig:adapterConfig
                                                        forKey:kAdUnitId];

    LogAdapterApi_Internal(@"adUnitId = %@", adUnitId);

    dispatch_async(dispatch_get_main_queue(), ^{
    // create rewarded ad delegate
    ISMolocoRewardedVideoDelegate *adDelegate = [[ISMolocoRewardedVideoDelegate alloc] initWithAdUnitId:adUnitId
                                                                                               andDelegate:delegate];
    
    self.molocoAdDelegate = adDelegate;
    self.ad = [[Moloco shared] createRewardedFor:adUnitId delegate:adDelegate watermarkData:nil];
    
    // load ad
        [self.ad loadWithBidResponse:serverData];
    });

}

- (void)showRewardedVideoWithViewController:(UIViewController *)viewController
                              adapterConfig:(ISAdapterConfig *)adapterConfig
                                   delegate:(id<ISRewardedVideoAdapterDelegate>)delegate {
    NSString *adUnitId = [self getStringValueFromAdapterConfig:adapterConfig
                                                        forKey:kAdUnitId];

    LogAdapterDelegate_Internal(@"adUnitId = %@", adUnitId);

    if (![self hasRewardedVideoWithAdapterConfig:adapterConfig]) {
        NSError *error = [ISError createError:ERROR_CODE_NO_ADS_TO_SHOW
                                  withMessage:[NSString stringWithFormat: @"%@ show failed", kAdapterName]];
        LogAdapterApi_Internal(@"error = %@", error);
        [delegate adapterRewardedVideoDidFailToShowWithError:error];
        return;
    }

    dispatch_async(dispatch_get_main_queue(), ^{
        [self.ad showFrom:viewController];
    });
}


- (BOOL)hasRewardedVideoWithAdapterConfig:(ISAdapterConfig *)adapterConfig {
    return self.ad != nil && self.ad.isReady;
}

- (void)collectRewardedVideoBiddingDataWithAdapterConfig:(ISAdapterConfig *)adapterConfig
                                                  adData:(NSDictionary *)adData
                                                delegate:(id<ISBiddingDataDelegate>)delegate {
    
    [self.adapter collectBiddingDataWithDelegate:delegate];
}

#pragma mark - Init Delegate

- (void)onNetworkInitCallbackSuccess {
    [self.smashDelegate adapterRewardedVideoInitSuccess];
}


- (void)onNetworkInitCallbackFailed:(NSString *)errorMessage {
    NSError *error = [ISError createErrorWithDomain:kAdapterName
                                               code:ERROR_CODE_INIT_FAILED
                                            message:errorMessage];
    [self.smashDelegate adapterRewardedVideoInitFailed:error];
}

#pragma mark - Memory Handling

- (void)releaseMemoryWithAdapterConfig:(ISAdapterConfig *)adapterConfig {
    NSString *adUnitId = [self getStringValueFromAdapterConfig:adapterConfig
                                                        forKey:kAdUnitId];
    LogAdapterDelegate_Internal(@"adUnitId = %@", adUnitId);

    [self.ad destroy];
    self.ad.rewardedDelegate = nil;
    dispatch_async(dispatch_get_main_queue(), ^{
        self.ad = nil;
    });
    self.smashDelegate = nil;
    self.molocoAdDelegate = nil;
}

@end
