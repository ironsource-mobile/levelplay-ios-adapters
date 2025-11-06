//
//  ISYSORewardedVideoAdapter.m
//  ISYSOAdapter
//
//  Copyright © 2021-2025 Unity Technologies. All rights reserved.
//

#import "ISYSORewardedVideoAdapter.h"
#import "ISYSORewardedVideoAdDelegate.h"

@interface ISYSORewardedVideoAdapter ()

@property (nonatomic, weak)   ISYSOAdapter *adapter;
@property (nonatomic, strong) ISYSORewardedVideoAdDelegate *adDelegate;
@property (nonatomic, weak)   id<ISRewardedVideoAdapterDelegate> smashDelegate;

@end

@implementation ISYSORewardedVideoAdapter

- (instancetype)initWithYSOAdapter:(ISYSOAdapter *)adapter {
    self = [super init];
    if (self) {
        _adapter = adapter;
        _smashDelegate = nil;
        _adDelegate = nil;
    }
    return self;
}

#pragma mark - Rewarded Video API

- (void)initRewardedVideoForCallbacksWithUserId:(NSString *)userId 
                                  adapterConfig:(ISAdapterConfig *)adapterConfig
                                       delegate:(id<ISRewardedVideoAdapterDelegate>)delegate {
    NSString *placementKey = [self getStringValueFromAdapterConfig:adapterConfig
                                                            forKey:kPlacementKey];
    /* Configuration Validation */
    if (![self.adapter isConfigValueValid:placementKey]) {
        NSError *error = [self.adapter errorForMissingCredentialFieldWithName:kPlacementKey];
        LogAdapterApi_Internal(@"error = %@", error);
        [delegate adapterRewardedVideoInitFailed:error];
        return;
    }

    self.smashDelegate = delegate;
    
    LogAdapterApi_Internal(@"placementKey = %@", placementKey);
    
    switch ([self.adapter getInitState]) {
        case INIT_STATE_NONE:
        case INIT_STATE_IN_PROGRESS:
            [self.adapter initSDKWithPlacementKey:placementKey];
            break;
        case INIT_STATE_SUCCESS:
            [delegate adapterRewardedVideoInitSuccess];
            break;
        case INIT_STATE_FAILED:
            LogAdapterApi_Internal(@"init failed - placementKey = %@", placementKey);
            [delegate adapterRewardedVideoInitFailed:[ISError createError:ERROR_CODE_INIT_FAILED
                                                              withMessage:@"YSO SDK init failed"]];
            break;
    }
}

- (void)loadRewardedVideoForBiddingWithAdapterConfig:(ISAdapterConfig *)adapterConfig 
                                              adData:(NSDictionary *)adData
                                          serverData:(NSString *)serverData
                                            delegate:(id<ISRewardedVideoAdapterDelegate>)delegate {
    NSString *placementKey = [self getStringValueFromAdapterConfig:adapterConfig
                                                            forKey:kPlacementKey];
    LogAdapterApi_Internal(@"placementKey = %@", placementKey);
    
    // create rewardedVideo ad delegate
    ISYSORewardedVideoAdDelegate *adDelegate = [[ISYSORewardedVideoAdDelegate alloc] initWithPlacementKey:placementKey
                                                                                                 adapter:self.adapter
                                                                                         andDelegate:delegate];
    self.adDelegate = adDelegate;
    
    // load ad
    [YsoNetwork rewardedLoadWithKey:placementKey
                               json:serverData
                             onLoad:^(e_ActionError error) {
        [self.adDelegate handleOnLoad:error];
    }];
}

- (void)showRewardedVideoWithViewController:(UIViewController *)viewController 
                              adapterConfig:(ISAdapterConfig *)adapterConfig
                                   delegate:(id<ISRewardedVideoAdapterDelegate>)delegate {
    NSString *placementKey = [self getStringValueFromAdapterConfig:adapterConfig
                                                     forKey:kPlacementKey];

    LogAdapterApi_Internal(@"placementKey = %@", placementKey);

    if (![self hasRewardedVideoWithAdapterConfig:adapterConfig]) {
        NSError *error = [ISError createError:ERROR_CODE_NO_ADS_TO_SHOW
                                  withMessage:[NSString stringWithFormat: @"%@ show failed", kAdapterName]];
        LogAdapterApi_Internal(@"error = %@", error);
        [delegate adapterRewardedVideoDidFailToShowWithError:error];
        return;
    }
    
    dispatch_async(dispatch_get_main_queue(), ^{
        [YsoNetwork rewardedShowWithKey:placementKey
                            viewController:viewController
                              onDisplay:^(YNWebView * _Nullable view) {
            [self.adDelegate handleOnDisplay:view];
        }
                                    onClick:^{
            [self.adDelegate handleOnClick];
        }
                                    onClose:^(BOOL display, BOOL complete) {
            [self.adDelegate handleOnClose:display complete:complete];
        }];
    });
}

- (BOOL)hasRewardedVideoWithAdapterConfig:(ISAdapterConfig *)adapterConfig {
    NSString *placementKey = [self getStringValueFromAdapterConfig:adapterConfig
                                                     forKey:kPlacementKey];
    return [YsoNetwork rewardedIsReadyWithKey:placementKey];
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

- (void)destroyRewardedVideoAdWithAdapterConfig:(ISAdapterConfig *)adapterConfig {
    NSString *placementKey = [self getStringValueFromAdapterConfig:adapterConfig
                                                            forKey:kPlacementKey];
    LogAdapterApi_Internal(@"placementKey = %@", placementKey);
    self.adDelegate = nil;
    self.smashDelegate = nil;
}

@end
