//
//  ISPubMaticRewardedVideoAdapter.m
//  ISPubMaticAdapter
//
//  Copyright © 2021-2025 Unity Technologies. All rights reserved.
//

#import "ISPubMaticRewardedVideoAdapter.h"
#import "ISPubMaticRewardedVideoDelegate.h"

@interface ISPubMaticRewardedVideoAdapter ()

@property (nonatomic, weak)   ISPubMaticAdapter                  *adapter;
@property (nonatomic, strong) POBRewardedAd                      *ad;
@property (nonatomic, strong) ISPubMaticRewardedVideoDelegate    *adDelegate;
@property (nonatomic, weak)   id<ISRewardedVideoAdapterDelegate> smashDelegate;

@end

@implementation ISPubMaticRewardedVideoAdapter

- (instancetype)initWithPubMaticAdapter:(ISPubMaticAdapter *)adapter {
    self = [super init];
    if (self) {
        _adapter = adapter;
        _ad = nil;
        _smashDelegate = nil;
        _adDelegate = nil;
    }
    return self;
}

#pragma mark - Rewarded Video API

- (void)initRewardedVideoForCallbacksWithUserId:(NSString *)userId
                                  adapterConfig:(ISAdapterConfig *)adapterConfig
                                       delegate:(id<ISRewardedVideoAdapterDelegate>)delegate {
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

    LogAdapterApi_Internal(@"adUnitId = %@", adUnitId);

    switch ([self.adapter getInitState]) {
        case INIT_STATE_NONE:
        case INIT_STATE_IN_PROGRESS:
            [self.adapter initSDKWithConfig:adapterConfig];
            break;
        case INIT_STATE_SUCCESS:
            [delegate adapterRewardedVideoInitSuccess];
            break;
        case INIT_STATE_FAILED:
            LogAdapterApi_Internal(@"init failed - adUnitId = %@", adUnitId);
            [delegate adapterRewardedVideoInitFailed:[ISError createError:ERROR_CODE_INIT_FAILED
                                                              withMessage:@"PubMatic SDK init failed"]];
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

    // create rewarded ad delegate
    ISPubMaticRewardedVideoDelegate *adDelegate = [[ISPubMaticRewardedVideoDelegate alloc] initWithAdUnitId:adUnitId
                                                                                                andDelegate:delegate];
    self.adDelegate = adDelegate;
    self.ad = [[POBRewardedAd alloc] init];
    self.ad.delegate = self.adDelegate;

    // load ad
    [self.ad loadAdWithResponse:serverData forBiddingHost:POBSDKBiddingHostUnityLevelPlay];
}

- (void)showRewardedVideoWithViewController:(UIViewController *)viewController
                              adapterConfig:(ISAdapterConfig *)adapterConfig
                                   delegate:(id<ISRewardedVideoAdapterDelegate>)delegate {
    NSString *adUnitId = [self getStringValueFromAdapterConfig:adapterConfig
                                                        forKey:kAdUnitId];
    
    LogAdapterApi_Internal(@"adUnitId = %@", adUnitId);

    if (![self hasRewardedVideoWithAdapterConfig:adapterConfig]) {
        NSError *error = [ISError createError:ERROR_CODE_NO_ADS_TO_SHOW
                                  withMessage:[NSString stringWithFormat: @"%@ show failed", kAdapterName]];
        LogAdapterApi_Internal(@"error = %@", error);
        [delegate adapterRewardedVideoDidFailToShowWithError:error];
        return;
    }
    [self.ad showFromViewController:viewController];
}

- (BOOL)hasRewardedVideoWithAdapterConfig:(ISAdapterConfig *)adapterConfig {
    return [self.ad isReady];
}

- (void)collectRewardedVideoBiddingDataWithAdapterConfig:(ISAdapterConfig *)adapterConfig
                                                  adData:(NSDictionary *)adData
                                                delegate:(id<ISBiddingDataDelegate>)delegate {
    dispatch_async(dispatch_get_main_queue(), ^{
        [self.adapter collectBiddingDataWithDelegate:delegate
                                            adFormat:POBAdFormatRewarded
                                       adapterConfig:adapterConfig];
    });
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
    NSString *adUnitId = [self getStringValueFromAdapterConfig:adapterConfig
                                                        forKey:kAdUnitId];
    LogAdapterApi_Internal(@"adUnitId = %@", adUnitId);
    self.ad.delegate = nil;
    self.ad = nil;
    self.smashDelegate = nil;
    self.adDelegate = nil;
}

@end
