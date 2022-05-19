//
//  ISYahooInterstitialPlayListener.m
//  ISYahooAdapter
//
//  Created by Moshe Aviv Aslanov on 21/10/2021.
//  Copyright © 2021 IronSource. All rights reserved.
//

#import "ISYahooInterstitialListener.h"

@implementation ISYahooInterstitialListener : NSObject

- (instancetype)initWithDelegate:(id<ISYahooInterstitialDelegateWrapper>)delegate {
    self = [super init];
    if (self) {
        _delegate = delegate;
    }
    return self;
}

#pragma mark - VASInterstitialAdFactoryDelegate Delegates

// Called when the VASInterstitialAd has been shown.
- (void)interstitialAdFactory:(nonnull VASInterstitialAdFactory *)interstitialAdFactory didLoadInterstitialAd:(nonnull VASInterstitialAd *)interstitialAd {
    [_delegate onInterstitialLoadSuccess:interstitialAdFactory InterstitialAd:interstitialAd];
}

//Called when there is an error requesting a VASInterstitialAd.
- (void)interstitialAdFactory:(nonnull VASInterstitialAdFactory *)interstitialAdFactory didFailWithError:(nonnull VASErrorInfo *)errorInfo {
    [_delegate onInterstitialLoadFail:interstitialAdFactory withError:errorInfo];
}

#pragma mark - VASInterstitialAdDelegate Delegates

// Called when the VASInterstitialAd has been shown.
- (void)interstitialAdDidShow:(nonnull VASInterstitialAd *)interstitialAd {
    [_delegate onInterstitialAdShown:interstitialAd];
}

// Called when an error occurs during the VASInterstitialAd lifecycle. A VASErrorInfo object provides detail about the error.
- (void)interstitialAdDidFail:(nonnull VASInterstitialAd *)interstitialAd withError:(nonnull VASErrorInfo *)errorInfo {
    [_delegate onInterstitialShowFailed:interstitialAd withError:errorInfo];
}

// Called when the VASInterstitialAd has been clicked.
- (void)interstitialAdClicked:(nonnull VASInterstitialAd *)interstitialAd {
    [_delegate onInterstitialAdClicked:interstitialAd];
}

// Called when the VASInterstitialAd has been closed.
- (void)interstitialAdDidClose:(nonnull VASInterstitialAd *)interstitialAd {
    [_delegate onInterstitialAdClosed:interstitialAd];
}

// Called when the VASInterstitialAd causes the user to leave the application. For example, tapping a VASInterstitialAd may launch an external browser.
- (void)interstitialAdDidLeaveApplication:(nonnull VASInterstitialAd *)interstitialAd {
}

//This callback is used to surface additional events to the publisher from the SDK.
- (void)interstitialAdEvent:(nonnull VASInterstitialAd *)interstitialAd source:(nonnull NSString *)source eventId:(nonnull NSString *)eventId arguments:(nullable NSDictionary<NSString *,id> *)arguments {
}

@end
