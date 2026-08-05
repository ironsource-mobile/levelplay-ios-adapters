//
//  ISChartboostInterstitialAdapter.m
//  ISChartboostAdapter
//
//  Copyright © 2021-2025 Unity Technologies. All rights reserved.
//

#import <IronSource/ISError.h>
#import <IronSource/ISLog.h>
#import "ISChartboostInterstitialAdapter.h"
#import "ISChartboostInterstitialDelegate.h"
#import "ISChartboostAdapter+Internal.h"

@interface ISChartboostInterstitialAdapter ()

@property (nonatomic, strong) CHBInterstitial *interstitialAd;
@property (nonatomic, strong) ISChartboostInterstitialDelegate *interstitialAdDelegate;

@end

@implementation ISChartboostInterstitialAdapter

#pragma mark - Interstitial Methods

- (void)loadAdWithAdData:(ISAdData *)adData
                delegate:(id<ISInterstitialAdDelegate>)delegate {
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

    self.interstitialAdDelegate = [[ISChartboostInterstitialDelegate alloc] initWithDelegate:delegate];
    self.interstitialAd = [[CHBInterstitial alloc] initWithLocation:locationId
                                                          mediation:[adapter getMediationInfo]
                                                           delegate:self.interstitialAdDelegate];

    if (adData.serverData) {
        [self.interstitialAd cacheBidResponse:adData.serverData];
    } else {
        [self.interstitialAd cache];
    }
}

- (void)showAdWithViewController:(UIViewController *)viewController
                          adData:(ISAdData *)adData
                        delegate:(id<ISInterstitialAdDelegate>)delegate {
    LogAdapterApi_Internal(logCallbackEmpty);

    if (![self isAdAvailableWithAdData:adData]) {
        NSError *error = [ISError createError:ERROR_CODE_NO_ADS_TO_SHOW
                                  withMessage:[NSString stringWithFormat:logShowFailed, networkName]];
        LogAdapterApi_Internal(logError, error);
        [delegate adDidFailToShowWithErrorCode:error.code
                                  errorMessage:error.localizedDescription];
        return;
    }

    [self.interstitialAd showFromViewController:viewController];
}

- (BOOL)isAdAvailableWithAdData:(ISAdData *)adData {
    return self.interstitialAd != nil && self.interstitialAd.isCached;
}

- (void)destroyAdWithAdData:(ISAdData *)adData {
    LogAdapterApi_Internal(logCallbackEmpty);

    self.interstitialAd = nil;
    self.interstitialAdDelegate = nil;
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
