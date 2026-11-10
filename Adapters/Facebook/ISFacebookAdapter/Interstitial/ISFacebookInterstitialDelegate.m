//
//  ISFacebookInterstitialDelegate.m
//  ISFacebookAdapter
//
//  Copyright © 2021-2025 Unity Technologies. All rights reserved.
//

#import "ISFacebookInterstitialDelegate.h"
#import "ISFacebookConstants.h"
#import <IronSource/ISBaseInterstitial.h>
#import <IronSource/ISAdapterErrorType.h>
#import <IronSource/ISLog.h>

@implementation ISFacebookInterstitialDelegate

- (instancetype)initWithDelegate:(id<ISInterstitialAdDelegate>)delegate {
    self = [super init];
    if (self) {
        _delegate = delegate;
    }
    return self;
}

#pragma mark - FBInterstitialAdDelegate

- (void)interstitialAdDidLoad:(FBInterstitialAd *)interstitialAd {
    LogAdapterDelegate_Internal(logCallbackEmpty);
    [self.delegate adDidLoad];
}

- (void)interstitialAd:(FBInterstitialAd *)interstitialAd didFailWithError:(NSError *)error {
    LogAdapterDelegate_Internal(logLoadFailed, networkName, error);

    ISAdapterErrorType errorType = (error.code == facebookNoFillErrorCode) ?
        ISAdapterErrorTypeNoFill : ISAdapterErrorTypeInternal;

    [self.delegate adDidFailToLoadWithErrorType:errorType
                                      errorCode:error.code
                                   errorMessage:error.localizedDescription];
}

- (void)interstitialAdWillLogImpression:(FBInterstitialAd *)interstitialAd {
    LogAdapterDelegate_Internal(logCallbackEmpty);
    [self.delegate adDidOpen];
}

- (void)interstitialAdDidClick:(FBInterstitialAd *)interstitialAd {
    LogAdapterDelegate_Internal(logCallbackEmpty);
    [self.delegate adDidClick];
}

- (void)interstitialAdDidClose:(FBInterstitialAd *)interstitialAd {
    LogAdapterDelegate_Internal(logCallbackEmpty);
    [self.delegate adDidClose];
}

@end
