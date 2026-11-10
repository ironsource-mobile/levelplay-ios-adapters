//
//  ISOguryInterstitialDelegate.m
//  ISOguryAdapter
//
//  Copyright © 2021-2025 Unity Technologies. All rights reserved.
//

#import <OguryAds/OguryAds.h>
#import <IronSource/ISLog.h>
#import <IronSource/ISBaseInterstitial.h>
#import <IronSource/ISAdapterErrorType.h>
#import "ISOguryInterstitialDelegate.h"
#import "ISOguryConstants.h"

@implementation ISOguryInterstitialDelegate

- (instancetype)initWithDelegate:(id<ISInterstitialAdDelegate>)delegate {
    self = [super init];
    if (self) {
        _delegate = delegate;
    }
    return self;
}

#pragma mark - OguryInterstitialAdDelegate

- (void)interstitialAdDidLoad:(OguryInterstitialAd *)interstitialAd {
    LogAdapterDelegate_Internal(logCallbackEmpty);
    [self.delegate adDidLoad];
}

- (void)interstitialAd:(OguryInterstitialAd *)interstitialAd didFailWithError:(OguryAdError *)error {
    LogAdapterDelegate_Internal(logError, error);

    if (error.type == OguryAdErrorTypeLoad) {
        ISAdapterErrorType errorType = (error.code == OguryLoadErrorCodeNoFill) ? ISAdapterErrorTypeNoFill : ISAdapterErrorTypeInternal;
        [self.delegate adDidFailToLoadWithErrorType:errorType
                                          errorCode:error.code
                                       errorMessage:error.localizedDescription];
    } else {
        [self.delegate adDidFailToShowWithErrorCode:error.code
                                       errorMessage:error.localizedDescription];
    }
}

- (void)interstitialAdDidTriggerImpression:(OguryInterstitialAd *)interstitialAd {
    LogAdapterDelegate_Internal(logCallbackEmpty);
    [self.delegate adDidOpen];
}

- (void)interstitialAdDidClick:(OguryInterstitialAd *)interstitialAd {
    LogAdapterDelegate_Internal(logCallbackEmpty);
    [self.delegate adDidClick];
}

- (void)interstitialAdDidClose:(OguryInterstitialAd *)interstitialAd {
    LogAdapterDelegate_Internal(logCallbackEmpty);
    [self.delegate adDidClose];
}

@end
