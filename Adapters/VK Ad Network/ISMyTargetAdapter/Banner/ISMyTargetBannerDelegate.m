//
//  ISMyTargetBannerDelegate.m
//  ISMyTargetAdapter
//
//  Copyright © 2021-2025 Unity Technologies. All rights reserved.
//

#import <MyTargetSDK/MyTargetSDK.h>
#import <IronSource/ISLog.h>
#import <IronSource/ISBaseBanner.h>
#import <IronSource/ISAdapterErrorType.h>
#import "ISMyTargetBannerDelegate.h"
#import "ISMyTargetConstants.h"

@implementation ISMyTargetBannerDelegate

- (instancetype)initWithDelegate:(id<ISBannerAdDelegate>)delegate {
    self = [super init];
    if (self) {
        _delegate = delegate;
    }
    return self;
}

#pragma mark - MTRGAdViewDelegate

- (void)onLoadWithAdView:(MTRGAdView *)adView {
    LogAdapterDelegate_Internal(logCallbackEmpty);
    [self.delegate adDidLoadWithView:adView];
}

- (void)onLoadFailedWithError:(NSError *)error adView:(MTRGAdView *)adView {
    LogAdapterDelegate_Internal(logError, error);
    [self.delegate adDidFailToLoadWithErrorType:ISAdapterErrorTypeInternal
                                      errorCode:error.code
                                   errorMessage:error.localizedDescription];
}

- (void)onAdClickWithAdView:(MTRGAdView *)adView {
    LogAdapterDelegate_Internal(logCallbackEmpty);
    [self.delegate adDidClick];
}

- (void)onAdShowWithAdView:(MTRGAdView *)adView {
    LogAdapterDelegate_Internal(logCallbackEmpty);
    [self.delegate adDidOpen];
}

- (void)onShowModalWithAdView:(MTRGAdView *)adView {
    LogAdapterDelegate_Internal(logCallbackEmpty);
    [self.delegate adWillPresentScreen];
}

- (void)onDismissModalWithAdView:(MTRGAdView *)adView {
    LogAdapterDelegate_Internal(logCallbackEmpty);
    [self.delegate adDidDismissScreen];
}

- (void)onLeaveApplicationWithAdView:(MTRGAdView *)adView {
    LogAdapterDelegate_Internal(logCallbackEmpty);
    [self.delegate adWillLeaveApplication];
}

@end
