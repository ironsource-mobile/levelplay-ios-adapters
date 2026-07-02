//
//  ISMyTargetInterstitialDelegate.m
//  ISMyTargetAdapter
//
//  Copyright © 2021-2025 Unity Technologies. All rights reserved.
//

#import <MyTargetSDK/MyTargetSDK.h>
#import <IronSource/ISLog.h>
#import <IronSource/ISBaseInterstitial.h>
#import <IronSource/ISAdapterErrorType.h>
#import "ISMyTargetInterstitialDelegate.h"
#import "ISMyTargetInterstitialAdapter.h"
#import "ISMyTargetConstants.h"

@implementation ISMyTargetInterstitialDelegate

- (instancetype)initWithAdapter:(ISMyTargetInterstitialAdapter *)adapter
                       delegate:(id<ISInterstitialAdDelegate>)delegate {
    self = [super init];
    if (self) {
        _adapter = adapter;
        _delegate = delegate;
    }
    return self;
}

#pragma mark - MTRGInterstitialAdDelegate

- (void)onLoadWithInterstitialAd:(MTRGInterstitialAd *)interstitialAd {
    LogAdapterDelegate_Internal(logCallbackEmpty);
    [self.adapter setInterstitialAdAvailability:YES];
    [self.delegate adDidLoad];
}

- (void)onLoadFailedWithError:(NSError *)error
               interstitialAd:(MTRGInterstitialAd *)interstitialAd {
    LogAdapterDelegate_Internal(logError, error);
    [self.adapter setInterstitialAdAvailability:NO];
    [self.delegate adDidFailToLoadWithErrorType:ISAdapterErrorTypeInternal
                                      errorCode:error.code
                                   errorMessage:error.localizedDescription];
}

- (void)onClickWithInterstitialAd:(MTRGInterstitialAd *)interstitialAd {
    LogAdapterDelegate_Internal(logCallbackEmpty);
    [self.delegate adDidClick];
}

- (void)onDisplayWithInterstitialAd:(MTRGInterstitialAd *)interstitialAd {
    LogAdapterDelegate_Internal(logCallbackEmpty);
    [self.delegate adDidOpen];
}

- (void)onCloseWithInterstitialAd:(MTRGInterstitialAd *)interstitialAd {
    LogAdapterDelegate_Internal(logCallbackEmpty);
    [self.delegate adDidClose];
}

- (void)onVideoCompleteWithInterstitialAd:(MTRGInterstitialAd *)interstitialAd {
    LogAdapterDelegate_Internal(logCallbackEmpty);
}

@end
