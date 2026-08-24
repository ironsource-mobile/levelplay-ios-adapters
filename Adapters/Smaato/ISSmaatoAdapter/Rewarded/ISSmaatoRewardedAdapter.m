//
//  ISSmaatoRewardedAdapter.m
//  ISSmaatoAdapter
//
//  Copyright © 2021-2025 Unity Technologies. All rights reserved.
//

#import <IronSource/ISError.h>
#import <IronSource/ISLog.h>
#import "ISSmaatoRewardedAdapter.h"
#import "ISSmaatoRewardedDelegate.h"
#import "ISSmaatoAdapter+Internal.h"

@interface ISSmaatoRewardedAdapter ()

@property (nonatomic, strong) SMARewardedInterstitial *rewardedAd;
@property (nonatomic, strong) ISSmaatoRewardedDelegate *rewardedAdDelegate;

@end

@implementation ISSmaatoRewardedAdapter

#pragma mark - Rewarded Methods

- (void)loadAdWithAdData:(ISAdData *)adData
                delegate:(id<ISRewardedVideoAdDelegate>)delegate {
    NSString *adSpaceId = [adData getString:adSpaceIdKey];
    LogAdapterApi_Internal(logAdSpaceId, adSpaceId);

    if (!adSpaceId || adSpaceId.length == 0) {
        NSString *errorMessage = [NSString stringWithFormat:logMissingParam, adSpaceIdKey];
        LogAdapterApi_Internal(logError, errorMessage);
        [delegate adDidFailToLoadWithErrorType:ISAdapterErrorTypeInternal
                                     errorCode:ISAdapterErrorMissingParams
                                  errorMessage:errorMessage];
        return;
    }

    ISSmaatoAdapter *adapter = (ISSmaatoAdapter *)[self getNetworkAdapter];

    if (!adapter) {
        LogAdapterApi_Internal(logError, logAdapterNil);
        [delegate adDidFailToLoadWithErrorType:ISAdapterErrorTypeInternal
                                     errorCode:ISAdapterErrorInternal
                                  errorMessage:logAdapterNil];
        return;
    }

    self.rewardedAdDelegate = [[ISSmaatoRewardedDelegate alloc] initWithAdapter:self
                                                                    delegate:delegate];

    SMAAdRequestParams *adRequestParams = [adapter getAdRequestWithServerData:adData.serverData];

    dispatch_async(dispatch_get_main_queue(), ^{
        if (adRequestParams == nil) {
            LogAdapterApi_Internal(logError, logAdRequestFailed);
            [delegate adDidFailToLoadWithErrorType:ISAdapterErrorTypeInternal
                                         errorCode:ERROR_CODE_GENERIC
                                      errorMessage:logAdRequestFailed];
            return;
        }

        [SmaatoSDK loadRewardedInterstitialForAdSpaceId:adSpaceId
                                               delegate:self.rewardedAdDelegate
                                          requestParams:adRequestParams];
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
        [self.rewardedAd showFromViewController:viewController];
    });
}

- (BOOL)isAdAvailableWithAdData:(ISAdData *)adData {
    return self.rewardedAd != nil && self.rewardedAd.availableForPresentation;
}

- (void)destroyAdWithAdData:(ISAdData *)adData {
    LogAdapterApi_Internal(logCallbackEmpty);

    self.rewardedAd = nil;
    self.rewardedAdDelegate = nil;
}

#pragma mark - Helper Methods

- (void)setRewardedAd:(SMARewardedInterstitial *)ad {
    _rewardedAd = ad;
}

- (void)collectBiddingDataWithAdData:(ISAdData *)adData
                            delegate:(id<ISBiddingDataDelegate>)delegate {
    ISSmaatoAdapter *adapter = (ISSmaatoAdapter *)[self getNetworkAdapter];

    if (!adapter) {
        LogAdapterApi_Internal(logError, logAdapterNil);
        [delegate failureWithError:logAdapterNil];
        return;
    }

    [adapter collectBiddingDataWithDelegate:delegate];
}

@end
