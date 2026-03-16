//
//  ISVoodooRewardedVideoAdapter.m
//  ISVoodooAdapter
//
//  Copyright © 2021-2025 Unity Technologies. All rights reserved.
//

#import "ISVoodooRewardedVideoAdapter.h"
#import "ISVoodooRewardedVideoDelegate.h"

@interface ISVoodooRewardedVideoAdapter ()

@property (nonatomic, weak)   ISVoodooAdapter                    *adapter;
@property (nonatomic, strong) AdnFullscreenAdController          *ad;
@property (nonatomic, strong) ISVoodooRewardedVideoDelegate      *adDelegate;
@property (nonatomic, weak)   id<ISRewardedVideoAdapterDelegate> smashDelegate;

@end

@implementation ISVoodooRewardedVideoAdapter

- (instancetype)initWithVoodooAdapter:(ISVoodooAdapter *)adapter {
    self = [super init];
    if (self) {
        _adapter = adapter;
        _ad = nil;
        _adDelegate = nil;
        _smashDelegate = nil;
    }
    return self;
}

#pragma mark - Rewarded Video API

- (void)initRewardedVideoForCallbacksWithUserId:(NSString *)userId
                                  adapterConfig:(ISAdapterConfig *)adapterConfig
                                       delegate:(id<ISRewardedVideoAdapterDelegate>)delegate {
    NSString *placementId = adapterConfig.settings[kPlacementId];

    /* Configuration Validation */
    if (![self.adapter isConfigValueValid:placementId]) {
        NSError *error = [self.adapter errorForMissingCredentialFieldWithName:kPlacementId];
        LogAdapterApi_Internal(@"error = %@", error.description);
        [delegate adapterRewardedVideoInitFailed:error];
        return;
    }

    LogAdapterApi_Internal(@"placementId = %@", placementId);

    self.smashDelegate = delegate;

    switch ([self.adapter getInitState]) {
        case INIT_STATE_NONE:
        case INIT_STATE_IN_PROGRESS:
            [self.adapter initSDKWithConfig:adapterConfig];
            break;
        case INIT_STATE_SUCCESS:
            [delegate adapterRewardedVideoInitSuccess];
            break;
        case INIT_STATE_FAILED: {
            LogAdapterApi_Internal(@"init failed - placementId = %@", placementId);
            NSError *error = [ISError createError:ERROR_CODE_INIT_FAILED
                                      withMessage:@"Voodoo SDK init failed"];
            [delegate adapterRewardedVideoInitFailed:error];
            break;
        }
    }
}

- (void)loadRewardedVideoForBiddingWithAdapterConfig:(ISAdapterConfig *)adapterConfig
                                              adData:(NSDictionary *)adData
                                          serverData:(NSString *)serverData
                                            delegate:(id<ISRewardedVideoAdapterDelegate>)delegate {
    NSString *placementId = adapterConfig.settings[kPlacementId];
    LogAdapterApi_Internal(@"placementId = %@", placementId);

    // In favor of supporting all of the Mediation modes there is a need to store the Rewarded Video delegate
    // in a dictionary on both init and load APIs
    self.smashDelegate = delegate;

    self.adDelegate = [[ISVoodooRewardedVideoDelegate alloc] initWithPlacementId:placementId
                                                                                                            andDelegate:delegate];

    self.ad = [[AdnFullscreenAdController alloc] init];
    self.ad.fullscreenAdDelegate = self.adDelegate;
    
    AdnFullscreenAdOptions *options = [[AdnFullscreenAdOptions alloc] initWithPlacement:AdnPlacementTypeRewarded
                                                                               adMarkup:serverData];

    [self.ad loadAdWithOptions:options
                            completion:^(NSError * _Nullable error) {
        [self.adDelegate handleOnLoad:error];
    }];
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

    [self.ad presentAdFrom:viewController];
}

- (BOOL)hasRewardedVideoWithAdapterConfig:(ISAdapterConfig *)adapterConfig {
    return self.ad != nil && [self.ad canShow];
}

- (void)collectRewardedVideoBiddingDataWithAdapterConfig:(ISAdapterConfig *)adapterConfig
                                                  adData:(NSDictionary *)adData
                                                delegate:(id<ISBiddingDataDelegate>)delegate {
    [self.adapter collectBiddingDataWithDelegate:delegate
                                   placementType:AdnPlacementTypeRewarded
                                   adapterConfig:adapterConfig];
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

- (void)destroyRewardedVideoAdWithAdapterConfig:(ISAdapterConfig *)adapterConfig {
    NSString *placementId = adapterConfig.settings[kPlacementId];
    LogAdapterApi_Internal(@"placementId = %@", placementId);
    [self.ad cleanUp];
    self.ad.fullscreenAdDelegate = nil;
    self.ad = nil;
    self.smashDelegate = nil;
    self.adDelegate = nil;
}

@end
