//
//  ISMobileFuseInterstitialAdapter.m
//  ISMobileFuseAdapter
//
//  Copyright © 2021-2025 Unity Technologies. All rights reserved.
//

#import <MobileFuseSDK/MFInterstitialAd.h>
#import <IronSource/ISError.h>
#import <IronSource/ISLog.h>
#import "ISMobileFuseInterstitialAdapter.h"
#import "ISMobileFuseInterstitialDelegate.h"
#import "ISMobileFuseAdapter+Internal.h"
#import "ISMobileFuseConstants.h"

@interface ISMobileFuseInterstitialAdapter ()

@property (nonatomic, strong) MFInterstitialAd *interstitialAd;
@property (nonatomic, strong) ISMobileFuseInterstitialDelegate *interstitialAdDelegate;

@end

@implementation ISMobileFuseInterstitialAdapter

#pragma mark - Interstitial Methods

- (void)loadAdWithAdData:(ISAdData *)adData
                delegate:(id<ISInterstitialAdDelegate>)delegate {
    NSString *placementId = [adData getString:placementIdKey];
    LogAdapterApi_Internal(logPlacementId, placementId);

    if (!placementId || placementId.length == 0) {
        NSError *error = [NSError errorWithDomain:networkName
                                             code:ISAdapterErrorMissingParams
                                         userInfo:@{NSLocalizedDescriptionKey:logMissingPlacementId}];
        LogAdapterApi_Internal(logError, error);
        [delegate adDidFailToLoadWithErrorType:ISAdapterErrorTypeInternal
                                     errorCode:error.code
                                  errorMessage:error.localizedDescription];
        return;
    }

    // create interstitial ad delegate
    self.interstitialAdDelegate = [[ISMobileFuseInterstitialDelegate alloc] initWithDelegate:delegate];

    dispatch_async(dispatch_get_main_queue(), ^{
        self.interstitialAd = [[MFInterstitialAd alloc] initWithPlacementId:placementId];
        [self.interstitialAd registerAdCallbackReceiver:self.interstitialAdDelegate];
        // load ad
        [self.interstitialAd loadAdWithBiddingResponseToken:adData.serverData];
    });
}

- (void)showAdWithViewController:(UIViewController *)viewController
                          adData:(ISAdData *)adData
                        delegate:(id<ISInterstitialAdDelegate>)delegate {
    LogAdapterApi_Internal(logCallbackEmpty);

    if (![self isAdAvailableWithAdData:adData]) {
        NSError *error = [ISError createError:ERROR_CODE_NO_ADS_TO_SHOW
                                  withMessage:[NSString stringWithFormat:logNoAdsToShow, networkName]];
        LogAdapterApi_Internal(logError, error.description);
        [delegate adDidFailToShowWithErrorCode:error.code
                                  errorMessage:error.localizedDescription];
        return;
    }

    dispatch_async(dispatch_get_main_queue(), ^{
        // show ad
        [viewController.view addSubview:self.interstitialAd];
        [self.interstitialAd showAd];
    });
}

- (void)destroyAdWithAdData:(ISAdData *)adData {
    LogAdapterApi_Internal(logCallbackEmpty);

    dispatch_async(dispatch_get_main_queue(), ^{
        [self.interstitialAd destroy];
        self.interstitialAd = nil;
    });
    self.interstitialAdDelegate = nil;
}

- (BOOL)isAdAvailableWithAdData:(ISAdData *)adData {
    return self.interstitialAd != nil && self.interstitialAd.isLoaded;
}

- (void)collectBiddingDataWithAdData:(ISAdData *)adData delegate:(id<ISBiddingDataDelegate>)delegate {
    LogAdapterApi_Internal(logCallbackEmpty);

    ISMobileFuseAdapter *adapter = (ISMobileFuseAdapter *)[self getNetworkAdapter];
    if (!adapter) {
        LogAdapterApi_Internal(logError, logAdapterNil);
        [delegate failureWithError:logAdapterNil];
        return;
    }
    [adapter collectBiddingDataWithDelegate:delegate];
}

@end
