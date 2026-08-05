//
//  ISChartboostRewardedAdapter.m
//  ISChartboostAdapter
//
//  Copyright © 2021-2025 Unity Technologies. All rights reserved.
//

#import <IronSource/ISError.h>
#import <IronSource/ISLog.h>
#import "ISChartboostRewardedAdapter.h"
#import "ISChartboostRewardedDelegate.h"
#import "ISChartboostAdapter+Internal.h"

@interface ISChartboostRewardedAdapter ()

@property (nonatomic, strong) CHBRewarded *rewardedAd;
@property (nonatomic, strong) ISChartboostRewardedDelegate *rewardedAdDelegate;

@end

@implementation ISChartboostRewardedAdapter

#pragma mark - Rewarded Methods

- (void)loadAdWithAdData:(ISAdData *)adData
                delegate:(id<ISRewardedVideoAdDelegate>)delegate {
    NSString *locationId = [adData getString:locationIdKey];
    LogAdapterApi_Internal(logLocationId, locationId);

    if (!locationId || locationId.length == 0) {
        NSString *errorMessage = [NSString stringWithFormat:logMissingParam, locationIdKey];
        LogAdapterApi_Internal(logError, errorMessage);
        [delegate adDidFailToLoadWithErrorType:ISAdapterErrorTypeInternal
                                     errorCode:ISAdapterErrorMissingParams
                                  errorMessage:errorMessage];
        return;
    }

    ISChartboostAdapter *adapter = (ISChartboostAdapter *)[self getNetworkAdapter];

    if (!adapter) {
        LogAdapterApi_Internal(logError, logAdapterNil);
        [delegate adDidFailToLoadWithErrorType:ISAdapterErrorTypeInternal
                                     errorCode:ISAdapterErrorInternal
                                  errorMessage:logAdapterNil];
        return;
    }

    self.rewardedAdDelegate = [[ISChartboostRewardedDelegate alloc] initWithDelegate:delegate];
    self.rewardedAd = [[CHBRewarded alloc] initWithLocation:locationId
                                                  mediation:[adapter getMediationInfo]
                                                   delegate:self.rewardedAdDelegate];

    if (adData.serverData) {
        [self.rewardedAd cacheBidResponse:adData.serverData];
    } else {
        [self.rewardedAd cache];
    }
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

    [self.rewardedAd showFromViewController:viewController];
}

- (BOOL)isAdAvailableWithAdData:(ISAdData *)adData {
    return self.rewardedAd != nil && self.rewardedAd.isCached;
}

- (void)destroyAdWithAdData:(ISAdData *)adData {
    LogAdapterApi_Internal(logCallbackEmpty);

    self.rewardedAd = nil;
    self.rewardedAdDelegate = nil;
}

#pragma mark - Helper Methods

- (void)collectBiddingDataWithAdData:(ISAdData *)adData
                            delegate:(id<ISBiddingDataDelegate>)delegate {
    ISChartboostAdapter *adapter = (ISChartboostAdapter *)[self getNetworkAdapter];

    if (!adapter) {
        LogAdapterApi_Internal(logError, logAdapterNil);
        [delegate failureWithError:logAdapterNil];
        return;
    }

    [adapter collectBiddingDataWithDelegate:delegate];
}

@end
