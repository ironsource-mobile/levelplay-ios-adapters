//
//  ISLineInterstitialDelegate.m
//  ISLineAdapter
//
//  Copyright © 2021-2025 Unity Technologies. All rights reserved.
//

#import <IronSource/ISBaseInterstitial.h>
#import <IronSource/ISError.h>
#import <IronSource/ISAdapterErrorType.h>
#import <IronSource/ISLog.h>
#import "ISLineInterstitialDelegate.h"
#import "ISLineConstants.h"

@implementation ISLineInterstitialDelegate

- (instancetype)initWithDelegate:(id<ISInterstitialAdDelegate>)delegate {
    self = [super init];
    if (self) {
        _delegate = delegate;
    }
    return self;
}

- (void)fiveInterstitialAd:(nonnull FADInterstitial *)ad
didFailedToShowAdWithError:(FADErrorCode)errorCode {
    LogAdapterDelegate_Internal(logError, @(errorCode));
    [self.delegate adDidFailToShowWithErrorCode:ERROR_CODE_NO_ADS_TO_SHOW
                                   errorMessage:logNoAdsToShow];
}

- (void)fiveInterstitialAdDidImpression:(nonnull FADInterstitial *)ad {
    LogAdapterDelegate_Internal(logCallbackEmpty);
    [self.delegate adDidOpen];
}

- (void)fiveInterstitialAdDidClick:(nonnull FADInterstitial *)ad {
    LogAdapterDelegate_Internal(logCallbackEmpty);
    [self.delegate adDidClick];
}

- (void)fiveInterstitialAdFullScreenDidClose:(nonnull FADInterstitial *)ad {
    LogAdapterDelegate_Internal(logCallbackEmpty);
    [self.delegate adDidClose];
}

- (void)fiveInterstitialAdFullScreenDidOpen:(nonnull FADInterstitial *)ad {
    LogAdapterDelegate_Internal(logCallbackEmpty);
}

- (void)fiveInterstitialAdDidPlay:(nonnull FADInterstitial *)ad {
    LogAdapterDelegate_Internal(logCallbackEmpty);
}

- (void)fiveInterstitialAdDidPause:(nonnull FADInterstitial *)ad {
    LogAdapterDelegate_Internal(logCallbackEmpty);
}

- (void)fiveInterstitialAdDidViewThrough:(nonnull FADInterstitial *)ad {
    LogAdapterDelegate_Internal(logCallbackEmpty);
}

@end
