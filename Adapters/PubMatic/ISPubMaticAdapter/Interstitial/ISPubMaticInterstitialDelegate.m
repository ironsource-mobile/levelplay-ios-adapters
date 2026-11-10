//
//  ISPubMaticInterstitialDelegate.m
//  ISPubMaticAdapter
//
//  Copyright © 2021-2025 Unity Technologies. All rights reserved.
//

#import <IronSource/ISBaseInterstitial.h>
#import <IronSource/ISAdapterErrorType.h>
#import <IronSource/ISLog.h>
#import "ISPubMaticInterstitialDelegate.h"
#import "ISPubMaticConstants.h"

@implementation ISPubMaticInterstitialDelegate

- (instancetype)initWithDelegate:(id<ISInterstitialAdDelegate>)delegate {
    self = [super init];
    if (self) {
        _delegate = delegate;
    }
    return self;
}

- (void)interstitialDidReceiveAd:(POBInterstitial *)interstitial {
    LogAdapterDelegate_Internal(logCallbackEmpty);
    [self.delegate adDidLoad];
}

- (void)interstitial:(POBInterstitial *)interstitial didFailToReceiveAdWithError:(NSError *)error {
    LogAdapterDelegate_Internal(logError, error);
    ISAdapterErrorType errorType = (error.code == POBErrorNoAds) ? ISAdapterErrorTypeNoFill : ISAdapterErrorTypeInternal;
    [self.delegate adDidFailToLoadWithErrorType:errorType
                                      errorCode:error.code
                                   errorMessage:error.description];
}

- (void)interstitialDidRecordImpression:(POBInterstitial *)interstitial {
    LogAdapterDelegate_Internal(logCallbackEmpty);
    [self.delegate adDidOpen];
}

- (void)interstitial:(POBInterstitial *)interstitial didFailToShowAdWithError:(NSError *)error {
    LogAdapterDelegate_Internal(logError, error);
    [self.delegate adDidFailToShowWithErrorCode:error.code
                                   errorMessage:error.description];
}

- (void)interstitialDidClickAd:(POBInterstitial *)interstitial {
    LogAdapterDelegate_Internal(logCallbackEmpty);
    [self.delegate adDidClick];
}

- (void)interstitialDidDismissAd:(POBInterstitial *)interstitial {
    LogAdapterDelegate_Internal(logCallbackEmpty);
    [self.delegate adDidClose];
}

- (void)interstitialWillPresentAd:(POBInterstitial *)interstitial {
    LogAdapterDelegate_Internal(logCallbackEmpty);
}

- (void)interstitialDidPresentAd:(POBInterstitial *)interstitial {
    LogAdapterDelegate_Internal(logCallbackEmpty);
}

- (void)interstitialWillLeaveApplication:(POBInterstitial *)interstitial {
    LogAdapterDelegate_Internal(logCallbackEmpty);
}

@end
