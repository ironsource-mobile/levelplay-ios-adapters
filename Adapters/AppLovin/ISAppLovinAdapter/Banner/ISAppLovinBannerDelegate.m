//
//  ISAppLovinBannerDelegate.m
//  ISAppLovinAdapter
//
//  Copyright © 2021-2025 Unity Technologies. All rights reserved.
//

#import <IronSource/ISBannerAdDelegate.h>
#import <IronSource/ISError.h>
#import <IronSource/ISAdapterErrorType.h>
#import <IronSource/ISLog.h>
#import "ISAppLovinBannerDelegate.h"
#import "ISAppLovinAdapter+Internal.h"

@implementation ISAppLovinBannerDelegate

- (instancetype)initWithBannerView:(ALAdView *)bannerView
                          delegate:(id<ISBannerAdDelegate>)delegate {
    self = [super init];
    if (self) {
        _bannerView = bannerView;
        _delegate = delegate;
    }
    return self;
}

#pragma mark - ALAdLoadDelegate

- (void)adService:(ALAdService *)adService
        didLoadAd:(ALAd *)ad {
    LogAdapterDelegate_Internal(logCallbackEmpty);
    ALAdView *bannerView = self.bannerView;

    if (bannerView == nil) {
        LogAdapterDelegate_Internal(logBannerViewNil);
        return;
    }

    [self.delegate adDidLoadWithView:bannerView];
    [bannerView render:ad];
}

- (void)adService:(ALAdService *)adService didFailToLoadAdWithError:(int)code {
    NSString *errorReason = [ISAppLovinAdapter errorMessageForCode:code];
    LogAdapterDelegate_Internal(logError, errorReason);

    ISAdapterErrorType errorType = (code == kALErrorCodeNoFill) ? ISAdapterErrorTypeNoFill : ISAdapterErrorTypeInternal;
    [self.delegate adDidFailToLoadWithErrorType:errorType
                                      errorCode:code
                                   errorMessage:errorReason];
}

#pragma mark - ALAdDisplayDelegate

- (void)ad:(ALAd *)ad wasDisplayedIn:(UIView *)view {
    LogAdapterDelegate_Internal(logCallbackEmpty);
    [self.delegate adDidOpen];
}

- (void)ad:(ALAd *)ad wasClickedIn:(UIView *)view {
    LogAdapterDelegate_Internal(logCallbackEmpty);
    [self.delegate adDidClick];
}

- (void)ad:(ALAd *)ad wasHiddenIn:(UIView *)view {
    LogAdapterDelegate_Internal(logCallbackEmpty);
}

#pragma mark - ALAdViewEventDelegate

- (void)ad:(ALAd *)ad willLeaveApplicationForAdView:(ALAdView *)adView {
    LogAdapterDelegate_Internal(logCallbackEmpty);
    [self.delegate adWillLeaveApplication];
}

- (void)ad:(ALAd *)ad didPresentFullscreenForAdView:(ALAdView *)adView {
    LogAdapterDelegate_Internal(logCallbackEmpty);
    [self.delegate adWillPresentScreen];
}

- (void)ad:(ALAd *)ad didDismissFullscreenForAdView:(ALAdView *)adView {
    LogAdapterDelegate_Internal(logCallbackEmpty);
    [self.delegate adDidDismissScreen];
}

@end
