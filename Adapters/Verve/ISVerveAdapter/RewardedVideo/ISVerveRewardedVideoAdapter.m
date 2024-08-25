//
//  ISVerveRewardedVideoAdapter.m
//  ISVerveAdapter
//
//  Copyright © 2024 ironSource. All rights reserved.
//

#import "ISVerveRewardedVideoAdapter.h"
#import "ISVerveRewardedVideoDelegate.h"

@interface ISVerveRewardedVideoAdapter ()

@property (nonatomic, weak)   ISVerveAdapter *adapter;
@property (nonatomic, strong) HyBidRewardedAd *ad;
@property (nonatomic, strong) ISVerveRewardedVideoDelegate *verveAdDelegate;
@property (nonatomic, weak) id<ISRewardedVideoAdapterDelegate> smashDelegate;

@end

@implementation ISVerveRewardedVideoAdapter

- (instancetype)initWithVerveAdapter:(ISVerveAdapter *)adapter {
    self = [super init];
    if (self) {
        _adapter = adapter;
        _ad = nil;
        _smashDelegate = nil;
        _verveAdDelegate = nil;
    }
    return self;
}

#pragma mark - Rewarded Video API

// Used for flows when the mediation needs to get a callback for init
- (void)initRewardedVideoForCallbacksWithUserId:(NSString *)userId
                                  adapterConfig:(ISAdapterConfig *)adapterConfig
                                       delegate:(id<ISRewardedVideoAdapterDelegate>)delegate {
    NSString *appToken = [self getStringValueFromAdapterConfig:adapterConfig
                                                     forKey:kAppToken];
    /* Configuration Validation */
    if (![self.adapter isConfigValueValid:appToken]) {
        NSError *error = [self.adapter errorForMissingCredentialFieldWithName:kAppToken];
        LogAdapterApi_Internal(@"error = %@", error);
        [delegate adapterRewardedVideoInitFailed:error];
        return;
    }

    NSString *adUnitId = [self getStringValueFromAdapterConfig:adapterConfig
                                                        forKey:kZoneId];
    /* Configuration Validation */
    if (![self.adapter isConfigValueValid:adUnitId]) {
        NSError *error = [self.adapter errorForMissingCredentialFieldWithName:kZoneId];
        LogAdapterApi_Internal(@"error = %@", error);
        [delegate adapterRewardedVideoInitFailed:error];
        return;
    }

    self.smashDelegate = delegate;

    LogAdapterApi_Internal(@"appToken = %@, adUnitId = %@", appToken, adUnitId);

    switch ([self.adapter getInitState]) {
        case INIT_STATE_NONE:
        case INIT_STATE_IN_PROGRESS:
            [self.adapter initSDKWithAppToken:appToken];
            break;
        case INIT_STATE_SUCCESS:
            [delegate adapterRewardedVideoInitSuccess];
            break;
            
        case INIT_STATE_FAILED:
            LogAdapterApi_Internal(@"init failed - adUnitId = %@", adUnitId);
            [delegate adapterRewardedVideoInitFailed:[ISError createError:ERROR_CODE_INIT_FAILED
                                                              withMessage:@"Verve SDK init failed"]];
            break;
    }
}

- (NSString *)getZoneId:(ISAdapterConfig *)adapterConfig {
    return [self getStringValueFromAdapterConfig:adapterConfig
                                          forKey:kZoneId];
}

- (void)loadRewardedVideoForBiddingWithAdapterConfig:(ISAdapterConfig *)adapterConfig
                                              adData:(NSDictionary *)adData
                                          serverData:(NSString *)serverData
                                            delegate:(id<ISRewardedVideoAdapterDelegate>)delegate {
    NSString *zoneId = [self getZoneId:adapterConfig];
    
    LogAdapterApi_Internal(@"zoneId = %@", zoneId);
    
    // create rewarded ad delegate
    ISVerveRewardedVideoDelegate *adDelegate = [[ISVerveRewardedVideoDelegate alloc] initWithZoneId:zoneId
                                                                                        andDelegate:delegate];
    
    self.verveAdDelegate = adDelegate;
    self.ad = [[HyBidRewardedAd alloc] initWithDelegate:adDelegate];
    
    [self.ad prepareAdWithContent:serverData];
    
}

- (void)showRewardedVideoWithViewController:(UIViewController *)viewController
                              adapterConfig:(ISAdapterConfig *)adapterConfig
                                   delegate:(id<ISRewardedVideoAdapterDelegate>)delegate {
        
    NSString *zoneId = [self getZoneId:adapterConfig];

    LogAdapterDelegate_Internal(@"zoneId = %@", zoneId);
    
    if (![self hasRewardedVideoWithAdapterConfig:adapterConfig]) {
        NSError *error = [ISError createError:ERROR_CODE_NO_ADS_TO_SHOW
                                  withMessage:[NSString stringWithFormat: @"%@ show failed", kAdapterName]];
        LogAdapterApi_Internal(@"error = %@", error);
        [delegate adapterRewardedVideoDidFailToShowWithError:error];
        return;
    }
    
    dispatch_async(dispatch_get_main_queue(), ^{
        [self.ad showFromViewController: viewController];
    });

}

- (BOOL)hasRewardedVideoWithAdapterConfig:(ISAdapterConfig *)adapterConfig {
    return self.ad != nil && [self.ad isReady];
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
    NSString *zoneId = [self getStringValueFromAdapterConfig:adapterConfig
                                                        forKey:kZoneId];
    LogAdapterDelegate_Internal(@"zoneId = %@", zoneId);

    self.ad = nil;
    self.smashDelegate = nil;
    self.verveAdDelegate = nil;
}

@end
