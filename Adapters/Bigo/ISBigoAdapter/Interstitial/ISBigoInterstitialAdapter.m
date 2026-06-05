//
//  ISBigoInterstitialAdapter.m
//  ISBigoAdapter
//
//  Copyright © 2021-2025 Unity Technologies. All rights reserved.
//

#import <BigoADS/BigoAdSdk.h>
#import <IronSource/ISError.h>
#import <IronSource/ISLog.h>
#import "ISBigoInterstitialAdapter.h"
#import "ISBigoInterstitialDelegate.h"
#import "ISBigoAdapter+Internal.h"
#import "ISBigoAdapter.h"
#import "ISBigoConstants.h"

@interface ISBigoInterstitialAdapter ()

@property (nonatomic, strong) BigoInterstitialAd           *interstitialAd;
@property (nonatomic, strong) BigoInterstitialAdLoader     *interstitialAdLoader;
@property (nonatomic, strong) ISBigoInterstitialDelegate   *interstitialAdDelegate;

@end

@implementation ISBigoInterstitialAdapter

#pragma mark - Interstitial Methods

- (void)loadAdWithAdData:(ISAdData *)adData
                delegate:(id<ISInterstitialAdDelegate>)delegate {
    NSString *slotId = [adData getString:slotIdKey];
    LogAdapterApi_Internal(logSlotId, slotId);

    if (!slotId || slotId.length == 0) {
        NSError *error = [NSError errorWithDomain:networkName
                                             code:ISAdapterErrorMissingParams
                                         userInfo:@{NSLocalizedDescriptionKey:logMissingSlotId}];
        LogAdapterApi_Internal(logError, error);
        [delegate adDidFailToLoadWithErrorType:ISAdapterErrorTypeInternal
                                     errorCode:error.code
                                  errorMessage:error.localizedDescription];
        return;
    }

    ISBigoAdapter *adapter = (ISBigoAdapter *)[self getNetworkAdapter];
    if (!adapter) {
        LogAdapterApi_Internal(logError, logAdapterNil);
        [delegate adDidFailToLoadWithErrorType:ISAdapterErrorTypeInternal
                                     errorCode:ISAdapterErrorMissingParams
                                  errorMessage:logAdapterNil];
        return;
    }

    self.interstitialAdDelegate = [[ISBigoInterstitialDelegate alloc] initWithAdapter:self
                                                                             delegate:delegate];

    BigoInterstitialAdRequest *request = [[BigoInterstitialAdRequest alloc] initWithSlotId:slotId];
    [request setServerBidPayload:adData.serverData];

    self.interstitialAdLoader = [[BigoInterstitialAdLoader alloc] initWithInterstitialAdLoaderDelegate:self.interstitialAdDelegate];
    self.interstitialAdLoader.ext = [adapter getMediationInfo];
    [self.interstitialAdLoader loadAd:request];
}

- (void)showAdWithViewController:(UIViewController *)viewController
                          adData:(ISAdData *)adData
                        delegate:(id<ISInterstitialAdDelegate>)delegate {
    LogAdapterApi_Internal(logCallbackEmpty);

    if (![self isAdAvailableWithAdData:adData]) {
        NSError *error = [NSError errorWithDomain:networkName
                                             code:ERROR_CODE_NO_ADS_TO_SHOW
                                         userInfo:@{NSLocalizedDescriptionKey:logShowFailed}];
        LogAdapterApi_Internal(logError, error);
        [delegate adDidFailToShowWithErrorCode:error.code
                                  errorMessage:error.localizedDescription];
        return;
    }

    dispatch_async(dispatch_get_main_queue(), ^{
        [self.interstitialAd show:viewController];
    });
}

- (BOOL)isAdAvailableWithAdData:(ISAdData *)adData {
    return self.interstitialAd != nil && ![self.interstitialAd isExpired];
}

- (void)destroyAdWithAdData:(ISAdData *)adData {
    LogAdapterApi_Internal(logCallbackEmpty);

    dispatch_async(dispatch_get_main_queue(), ^{
        [self.interstitialAd destroy];
        self.interstitialAd = nil;
    });
    self.interstitialAdDelegate = nil;
    self.interstitialAdLoader = nil;
}

#pragma mark - Helper Methods

- (void)storeInterstitialAd:(BigoInterstitialAd *)ad {
    self.interstitialAd = ad;
    [self.interstitialAd setAdInteractionDelegate:self.interstitialAdDelegate];
}

- (void)collectBiddingDataWithAdData:(ISAdData *)adData delegate:(id<ISBiddingDataDelegate>)delegate {
    LogAdapterApi_Internal(logCallbackEmpty);

    ISBigoAdapter *adapter = (ISBigoAdapter *)[self getNetworkAdapter];
    if (!adapter) {
        LogAdapterApi_Internal(logError, logAdapterNil);
        [delegate failureWithError:logAdapterNil];
        return;
    }

    [adapter collectBiddingDataWithDelegate:delegate];
}

@end
