//
//  ISAPSRewardedAdapter.m
//  ISAPSAdapter
//
//  Copyright © 2021-2025 Unity Technologies. All rights reserved.
//

#import <IronSource/ISError.h>
#import <IronSource/ISLog.h>
#import "ISAPSRewardedAdapter.h"
#import "ISAPSRewardedDelegate.h"
#import "ISAPSAdapter+Internal.h"

@interface ISAPSRewardedAdapter ()

@property (nonatomic, strong) DTBAdInterstitialDispatcher *rewardedAd;
@property (nonatomic, strong) ISAPSRewardedDelegate *rewardedAdDelegate;
@property (nonatomic, strong, nullable) DTBAdResponse *adResponse;

@end

@implementation ISAPSRewardedAdapter

#pragma mark - Rewarded Methods

- (void)loadAdWithAdData:(ISAdData *)adData
                delegate:(id<ISRewardedVideoAdDelegate>)delegate {
    if (!self.adResponse) {
        LogAdapterApi_Internal(logError, logAdResponseMissing);
        [delegate adDidFailToLoadWithErrorType:ISAdapterErrorTypeInternal
                                     errorCode:ERROR_CODE_GENERIC
                                  errorMessage:logAdResponseMissing];
        return;
    }

    LogAdapterApi_Internal(logUuid, self.adResponse.adSize.slotUUID);

    self.rewardedAdDelegate = [[ISAPSRewardedDelegate alloc] initWithDelegate:delegate];

    NSDictionary *mediationHints = self.adResponse.mediationHints;
    dispatch_async(dispatch_get_main_queue(), ^{
        self.rewardedAd = [[DTBAdInterstitialDispatcher alloc] initWithDelegate:self.rewardedAdDelegate];
        [self.rewardedAd fetchAdWithParameters:mediationHints];
    });
}

- (void)showAdWithViewController:(UIViewController *)viewController
                          adData:(ISAdData *)adData
                        delegate:(id<ISRewardedVideoAdDelegate>)delegate {
    LogAdapterApi_Internal(logCallbackEmpty);

    if (![self isAdAvailableWithAdData:adData]) {
        NSError *error = [ISError createError:ERROR_CODE_NO_ADS_TO_SHOW
                                  withMessage:[NSString stringWithFormat:logShowFailed, networkName]];
        LogAdapterApi_Internal(logError, error);
        [delegate adDidFailToShowWithErrorCode:error.code
                                  errorMessage:error.localizedDescription];
        return;
    }

    dispatch_async(dispatch_get_main_queue(), ^{
        [self.rewardedAd showFromController:viewController];
    });
}

- (BOOL)isAdAvailableWithAdData:(ISAdData *)adData {
    return self.rewardedAd != nil && self.rewardedAd.interstitialLoaded;
}

- (void)destroyAdWithAdData:(ISAdData *)adData {
    LogAdapterApi_Internal(logCallbackEmpty);

    dispatch_async(dispatch_get_main_queue(), ^{
        self.rewardedAd = nil;
        self.rewardedAdDelegate = nil;
        self.adResponse = nil;
    });
}

#pragma mark - Helper Methods

- (void)collectBiddingDataWithAdData:(ISAdData *)adData
                            delegate:(id<ISBiddingDataDelegate>)delegate {
    NSString *uuid = [adData getString:uuidKey];

    if (!uuid) {
        NSString *errorMessage = [NSString stringWithFormat:logMissingConfigurationParam, uuidKey];
        LogAdapterApi_Error(logError, errorMessage);
        [delegate failureWithError:errorMessage];
        return;
    }

    ISAPSAdapter *adapter = (ISAPSAdapter *)[self getNetworkAdapter];

    if (!adapter) {
        LogAdapterApi_Error(logError, logAdapterNil);
        [delegate failureWithError:logAdapterNil];
        return;
    }

    DTBAdSize *adSize = [adapter createVideoAdSizeWithSlotUUID:uuid];

    __weak typeof(self) weakSelf = self;
    [adapter collectBiddingInfoWithSize:adSize
                               delegate:delegate
                             completion:^(DTBAdResponse *adResponse) {
        typeof(weakSelf) strongSelf = weakSelf;
        strongSelf.adResponse = adResponse;
    }];
}

@end
