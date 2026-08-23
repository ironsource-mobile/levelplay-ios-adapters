//
//  ISPubMaticRewardedAdapter.m
//  ISPubMaticAdapter
//
//  Copyright © 2021-2025 Unity Technologies. All rights reserved.
//

#import <IronSource/ISError.h>
#import <IronSource/ISLog.h>
#import "ISPubMaticRewardedAdapter.h"
#import "ISPubMaticRewardedDelegate.h"
#import "ISPubMaticAdapter+Internal.h"

@interface ISPubMaticRewardedAdapter ()

@property (nonatomic, strong) POBRewardedAd *rewardedAd;
@property (nonatomic, strong) ISPubMaticRewardedDelegate *rewardedAdDelegate;

@end

@implementation ISPubMaticRewardedAdapter

#pragma mark - Rewarded Methods

- (void)loadAdWithAdData:(ISAdData *)adData
                delegate:(id<ISRewardedVideoAdDelegate>)delegate {
    NSString *adUnitId = [adData getString:adUnitIdKey];
    LogAdapterApi_Internal(logAdUnitId, adUnitId);

    if (!adUnitId || adUnitId.length == 0) {
        NSString *errorMessage = [NSString stringWithFormat:logMissingParam, adUnitIdKey];
        LogAdapterApi_Internal(logError, errorMessage);
        [delegate adDidFailToLoadWithErrorType:ISAdapterErrorTypeInternal
                                     errorCode:ISAdapterErrorMissingParams
                                  errorMessage:errorMessage];
        return;
    }

    self.rewardedAdDelegate = [[ISPubMaticRewardedDelegate alloc] initWithDelegate:delegate];
    self.rewardedAd = [[POBRewardedAd alloc] init];
    self.rewardedAd.delegate = self.rewardedAdDelegate;
    [self.rewardedAd loadAdWithResponse:adData.serverData forBiddingHost:POBSDKBiddingHostUnityLevelPlay];
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
    return [self.rewardedAd isReady];
}

- (void)destroyAdWithAdData:(ISAdData *)adData {
    LogAdapterApi_Internal(logCallbackEmpty);

    self.rewardedAd.delegate = nil;
    self.rewardedAd = nil;
    self.rewardedAdDelegate = nil;
}

#pragma mark - Helper Methods

- (void)collectBiddingDataWithAdData:(ISAdData *)adData
                            delegate:(id<ISBiddingDataDelegate>)delegate {
    ISPubMaticAdapter *adapter = (ISPubMaticAdapter *)[self getNetworkAdapter];

    if (!adapter) {
        LogAdapterApi_Internal(logError, logAdapterNil);
        [delegate failureWithError:logAdapterNil];
        return;
    }

    dispatch_async(dispatch_get_main_queue(), ^{
        [adapter collectBiddingDataWithDelegate:delegate
                                       adFormat:POBAdFormatRewarded];
    });
}

@end
