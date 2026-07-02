//
//  ISMolocoInterstitialAdapter.m
//  ISMolocoAdapter
//
//  Copyright © 2021-2025 Unity Technologies. All rights reserved.
//

#import <MolocoSDK/MolocoSDK-Swift.h>
#import <IronSource/ISError.h>
#import <IronSource/ISLog.h>
#import "ISMolocoInterstitialAdapter.h"
#import "ISMolocoInterstitialDelegate.h"
#import "ISMolocoAdapter+Internal.h"
#import "ISMolocoAdapter.h"
#import "ISMolocoConstants.h"

@interface ISMolocoInterstitialAdapter ()

@property (nonatomic, strong) id<MolocoInterstitial>              interstitialAd;
@property (nonatomic, strong) ISMolocoInterstitialDelegate        *interstitialAdDelegate;

@end

@implementation ISMolocoInterstitialAdapter

#pragma mark - Interstitial Methods

- (void)loadAdWithAdData:(ISAdData *)adData
                delegate:(id<ISInterstitialAdDelegate>)delegate {
    NSString *adUnitId = [adData getString:adUnitIdKey];
    LogAdapterApi_Internal(logAdUnitId, adUnitId);

    // Validate adUnitId
    if (!adUnitId || adUnitId.length == 0) {
        NSString *errorMessage = [NSString stringWithFormat:logMissingParam, adUnitIdKey];
        LogAdapterApi_Internal(logError, errorMessage);
        [delegate adDidFailToLoadWithErrorType:ISAdapterErrorTypeInternal
                                     errorCode:ISAdapterErrorMissingParams
                                  errorMessage:errorMessage];
        return;
    }

    // Validate serverData
    NSString *serverData = adData.serverData;
    if (!serverData) {
        NSString *errorMessage = [NSString stringWithFormat:logMissingParam, serverDataKey];
        LogAdapterApi_Internal(logError, errorMessage);
        [delegate adDidFailToLoadWithErrorType:ISAdapterErrorTypeInternal
                                     errorCode:ISAdapterErrorMissingParams
                                  errorMessage:errorMessage];
        return;
    }

    // Create interstitial ad
    dispatch_async(dispatch_get_main_queue(), ^{
        // Create interstitial ad delegate
        self.interstitialAdDelegate = [[ISMolocoInterstitialDelegate alloc] initWithDelegate:delegate];

        MolocoCreateAdParams *params = [[MolocoCreateAdParams alloc] initWithAdUnit:adUnitId
                                                                           mediation:mediationName];

        self.interstitialAd = [[Moloco shared] createInterstitialWithParams:params];
        self.interstitialAd.interstitialDelegate = self.interstitialAdDelegate;

        // Load ad
        [self.interstitialAd loadWithBidResponse:serverData];
    });
}

- (void)showAdWithViewController:(UIViewController *)viewController
                          adData:(ISAdData *)adData
                        delegate:(id<ISInterstitialAdDelegate>)delegate {
    LogAdapterDelegate_Internal(logCallbackEmpty);

    if (![self isAdAvailableWithAdData:adData]) {
        LogAdapterApi_Internal(logError, errorInterstitialNotAvailable);
        [delegate adDidFailToShowWithErrorCode:ERROR_CODE_NO_ADS_TO_SHOW
                                  errorMessage:errorInterstitialNotAvailable];
        return;
    }

    dispatch_async(dispatch_get_main_queue(), ^{
        [self.interstitialAd showFrom:viewController];
    });
}

- (BOOL)isAdAvailableWithAdData:(ISAdData *)adData {
    return self.interstitialAd != nil && self.interstitialAd.isReady;
}

- (void)destroyAdWithAdData:(ISAdData *)adData {
    LogAdapterDelegate_Internal(logCallbackEmpty);

    [self.interstitialAd destroy];
    self.interstitialAd.interstitialDelegate = nil;
    dispatch_async(dispatch_get_main_queue(), ^{
        self.interstitialAd = nil;
    });
    self.interstitialAdDelegate = nil;
}

- (void)collectBiddingDataWithAdData:(ISAdData *)adData delegate:(id<ISBiddingDataDelegate>)delegate {
    ISMolocoAdapter *adapter = (ISMolocoAdapter *)[self getNetworkAdapter];
    if (!adapter) {
        NSError *error = [NSError errorWithDomain:networkName
                                             code:ISAdapterErrorInternal
                                         userInfo:@{NSLocalizedDescriptionKey:logAdapterNil}];
        [delegate failureWithError:error.localizedDescription];
        return;
    }
    [adapter collectBiddingDataWithDelegate:delegate];
}

@end
