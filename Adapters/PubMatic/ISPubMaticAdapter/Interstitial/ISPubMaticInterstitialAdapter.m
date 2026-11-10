//
//  ISPubMaticInterstitialAdapter.m
//  ISPubMaticAdapter
//
//  Copyright © 2021-2025 Unity Technologies. All rights reserved.
//

#import <IronSource/ISError.h>
#import <IronSource/ISLog.h>
#import "ISPubMaticInterstitialAdapter.h"
#import "ISPubMaticInterstitialDelegate.h"
#import "ISPubMaticAdapter+Internal.h"

@interface ISPubMaticInterstitialAdapter ()

@property (nonatomic, strong) POBInterstitial *interstitialAd;
@property (nonatomic, strong) ISPubMaticInterstitialDelegate *interstitialAdDelegate;

@end

@implementation ISPubMaticInterstitialAdapter

#pragma mark - Interstitial Methods

- (void)loadAdWithAdData:(ISAdData *)adData
                delegate:(id<ISInterstitialAdDelegate>)delegate {
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

    self.interstitialAdDelegate = [[ISPubMaticInterstitialDelegate alloc] initWithDelegate:delegate];
    self.interstitialAd = [[POBInterstitial alloc] init];
    self.interstitialAd.delegate = self.interstitialAdDelegate;
    [self.interstitialAd loadAdWithResponse:adData.serverData forBiddingHost:POBSDKBiddingHostUnityLevelPlay];
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
    return [self.interstitialAd isReady];
}

- (void)destroyAdWithAdData:(ISAdData *)adData {
    LogAdapterApi_Internal(logCallbackEmpty);

    self.interstitialAd.delegate = nil;
    self.interstitialAd = nil;
    self.interstitialAdDelegate = nil;
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
                                       adFormat:POBAdFormatInterstitial];
    });
}

@end
