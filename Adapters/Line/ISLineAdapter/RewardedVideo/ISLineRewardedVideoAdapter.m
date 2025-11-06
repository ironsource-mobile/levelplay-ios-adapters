//
//  ISLineRewardedVideoAdapter.m
//  ISLineAdapter
//
//  Copyright © 2021-2025 Unity Technologies. All rights reserved.
//

#import "ISLineRewardedVideoAdapter.h"
#import "ISLineRewardedVideoDelegate.h"

@interface ISLineRewardedVideoAdapter ()

@property (nonatomic, weak) ISLineAdapter                      *adapter;
@property (nonatomic, strong) FADVideoReward                   *ad;
@property (nonatomic, strong) FADAdLoader                      *adLoader;
@property (nonatomic, strong) ISLineRewardedVideoDelegate      *lineAdDelegate;
@property (nonatomic, weak) id<ISRewardedVideoAdapterDelegate> smashDelegate;
@property (nonatomic, assign) BOOL                             adAvailability;

@end

@implementation ISLineRewardedVideoAdapter

- (instancetype)initWithLineAdapter:(ISLineAdapter *)adapter {
    self = [super init];
    if (self) {
        _adapter = adapter;
        _ad = nil;
        _adLoader = nil;
        _smashDelegate = nil;
        _lineAdDelegate = nil;
    }
    return self;
}

#pragma mark - Rewarded Video API

// Used for flows when the mediation needs to get a callback for init
- (void)initRewardedVideoForCallbacksWithUserId:(NSString *)userId
                                  adapterConfig:(ISAdapterConfig *)adapterConfig
                                       delegate:(id<ISRewardedVideoAdapterDelegate>)delegate {
    NSString *appId = [self getAppId:adapterConfig];
    /* Configuration Validation */
    if (![self.adapter isConfigValueValid:appId]) {
        NSError *error = [self.adapter errorForMissingCredentialFieldWithName:kAppId];
        LogAdapterApi_Internal(@"error = %@", error);
        [delegate adapterRewardedVideoInitFailed:error];
        return;
    }

    NSString *slotId = [self getSlotId:adapterConfig];
    /* Configuration Validation */
    if (![self.adapter isConfigValueValid:slotId]) {
        NSError *error = [self.adapter errorForMissingCredentialFieldWithName:kSlotId];
        LogAdapterApi_Internal(@"error = %@", error);
        [delegate adapterRewardedVideoInitFailed:error];
        return;
    }

    self.smashDelegate = delegate;

    LogAdapterApi_Internal(@"appId = %@, slotId = %@", appId, slotId);

    switch ([self.adapter getInitState]) {
        case INIT_STATE_NONE:
            [self.adapter initSDKWithAppId:appId];
            break;
        case INIT_STATE_SUCCESS:
            [delegate adapterRewardedVideoInitSuccess];
            break;
        case INIT_STATE_FAILED:
            LogAdapterApi_Internal(@"init failed - slotId = %@", slotId);
            [delegate adapterRewardedVideoInitFailed:[ISError createError:ERROR_CODE_INIT_FAILED
                                                                      withMessage:@"Line SDK init failed"]];
            break;
    }
}

- (void)loadRewardedVideoForBiddingWithAdapterConfig:(ISAdapterConfig *)adapterConfig
                                              adData:(NSDictionary *)adData
                                          serverData:(NSString *)serverData
                                            delegate:(id<ISRewardedVideoAdapterDelegate>)delegate {
    NSString *appId = [self getAppId:adapterConfig];
    NSString *slotId = [self getSlotId:adapterConfig];

    LogAdapterApi_Internal(@"appId = %@, slotId = %@", appId, slotId);
    
    self.adAvailability = NO;
    
    // create rewarded ad delegate
    ISLineRewardedVideoDelegate *adDelegate = [[ISLineRewardedVideoDelegate alloc] initWithSlotId:slotId
                                                                                          adapter:self
                                                                                        andDelegate:delegate];
    self.lineAdDelegate = adDelegate;
    self.adLoader = [self.adapter getAdLoader:appId];
    if (self.adLoader == nil){
        NSError *error = [ISError createError:ERROR_CODE_GENERIC
                                  withMessage:[NSString stringWithFormat:@"%@ - adLoader is nil", kAdapterName]];
        [delegate adapterRewardedVideoDidFailToLoadWithError:error];
        return;
    }
    
    FADBidData *bidData = [[FADBidData alloc] initWithBidResponse: serverData withWatermark: nil];
    void (^rewardedLoadCallback)(FADVideoReward *_Nullable, NSError *_Nullable) = ^(FADVideoReward *_Nullable ad, NSError *_Nullable error) {
        if (error)
        {
            [delegate adapterRewardedVideoHasChangedAvailability:NO];
            [delegate adapterRewardedVideoDidFailToLoadWithError:error];
            return;
        }
        
        if (!ad)
        {
            NSError *error = [ISError createError:ERROR_CODE_GENERIC
                                      withMessage:[NSString stringWithFormat:@"%@ no ad", kAdapterName]];
            [delegate adapterRewardedVideoHasChangedAvailability:NO];
            [delegate adapterRewardedVideoDidFailToLoadWithError:error];
            return;
        }
        self.ad = ad;
        [self onAdUnitAvailabilityChangeWithAdSlotId:slotId
                                                availability:YES
                                             rewardedVideoAd:ad];
        [delegate adapterRewardedVideoHasChangedAvailability:YES];
    };
    [self.adLoader loadRewardAdWithBidData:bidData
                          withLoadCallback:rewardedLoadCallback];
}

- (void)showRewardedVideoWithViewController:(UIViewController *)viewController
                              adapterConfig:(ISAdapterConfig *)adapterConfig
                                   delegate:(id<ISRewardedVideoAdapterDelegate>)delegate {
    NSString *slotId = [self getSlotId:adapterConfig];

    LogAdapterDelegate_Internal(@"slotId = %@", slotId);
    
    if (![self hasRewardedVideoWithAdapterConfig:adapterConfig]) {
        self.adAvailability = NO;
        NSError *error = [ISError createError:ERROR_CODE_NO_ADS_TO_SHOW
                                  withMessage:[NSString stringWithFormat: @"%@ show failed", kAdapterName]];
        LogAdapterApi_Internal(@"error = %@", error);
        [delegate adapterRewardedVideoDidFailToShowWithError:error];
        return;
    }
    if (self.ad) {
        [self.ad setEventListener: self.lineAdDelegate];
        [self.ad showWithViewController:viewController];
    } else {
        NSError *error = [ISError createError:ERROR_CODE_NO_ADS_TO_SHOW
                                  withMessage:@"No ad loaded yet"];
        [delegate adapterRewardedVideoDidFailToShowWithError:error];
    }
}

- (BOOL)hasRewardedVideoWithAdapterConfig:(ISAdapterConfig *)adapterConfig {
    return self.ad != nil && self.adAvailability;
}

- (void)collectRewardedVideoBiddingDataWithAdapterConfig:(ISAdapterConfig *)adapterConfig
                                                  adData:(NSDictionary *)adData
                                                delegate:(id<ISBiddingDataDelegate>)delegate {
    NSString *appId = [self getAppId:adapterConfig];
    NSString *slotId = [self getSlotId:adapterConfig];
    [self.adapter collectBiddingDataWithDelegate:delegate
                                           appId:appId
                                          slotId:slotId];
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
    NSString *slotId = [self getSlotId:adapterConfig];
    LogAdapterDelegate_Internal(@"slotId = %@", slotId);
    self.ad = nil;
    [self.ad setEventListener:nil];
    self.smashDelegate = nil;
    self.lineAdDelegate.delegate = nil;
    self.lineAdDelegate = nil;
    self.adLoader = nil;
}

#pragma mark - Helper Methods

- (void)onAdUnitAvailabilityChangeWithAdSlotId:(NSString *)slotId
                                  availability:(BOOL)availability
                               rewardedVideoAd:(FADVideoReward *)rewardedVideoAd {
    self.ad = rewardedVideoAd;
    self.adAvailability = availability;
}

- (NSString *)getSlotId:(ISAdapterConfig *)adapterConfig {
    return [self getStringValueFromAdapterConfig:adapterConfig
                                          forKey:kSlotId];
}

- (NSString *)getAppId:(ISAdapterConfig *)adapterConfig {
    return [self getStringValueFromAdapterConfig:adapterConfig
                                          forKey:kAppId];
}

@end
