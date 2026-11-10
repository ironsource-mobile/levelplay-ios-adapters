//
//  ISPubMaticBannerDelegate.m
//  ISPubMaticAdapter
//
//  Copyright © 2021-2025 Unity Technologies. All rights reserved.
//

#import <IronSource/ISBannerAdDelegate.h>
#import <IronSource/ISAdapterErrorType.h>
#import <IronSource/ISLog.h>
#import "ISPubMaticBannerDelegate.h"
#import "ISPubMaticConstants.h"

@implementation ISPubMaticBannerDelegate

- (instancetype)initWithViewController:(UIViewController *)viewController
                              delegate:(id<ISBannerAdDelegate>)delegate {
    self = [super init];
    if (self) {
        _viewController = viewController;
        _delegate = delegate;
    }
    return self;
}

- (UIViewController *)bannerViewPresentationController {
    LogAdapterDelegate_Internal(logCallbackEmpty);
    return self.viewController;
}

- (void)bannerViewDidReceiveAd:(POBBannerView *)bannerView {
    LogAdapterDelegate_Internal(logCallbackEmpty);
    [self.delegate adDidLoadWithView:bannerView];
}

- (void)bannerView:(POBBannerView *)bannerView didFailToReceiveAdWithError:(NSError *)error {
    LogAdapterDelegate_Internal(logError, error);

    if (error.code == POBErrorRenderError) {
        [self.delegate adDidFailToShowWithErrorCode:error.code
                                       errorMessage:error.description];
        return;
    }

    ISAdapterErrorType errorType = (error.code == POBErrorNoAds) ? ISAdapterErrorTypeNoFill : ISAdapterErrorTypeInternal;
    [self.delegate adDidFailToLoadWithErrorType:errorType
                                      errorCode:error.code
                                   errorMessage:error.description];
}

- (void)bannerViewDidRecordImpression:(POBBannerView *)bannerView {
    LogAdapterDelegate_Internal(logCallbackEmpty);
    [self.delegate adDidOpen];
}

- (void)bannerViewDidClickAd:(POBBannerView *)bannerView {
    LogAdapterDelegate_Internal(logCallbackEmpty);
    [self.delegate adDidClick];
}

- (void)bannerViewWillLeaveApplication:(POBBannerView *)bannerView {
    LogAdapterDelegate_Internal(logCallbackEmpty);
    [self.delegate adWillLeaveApplication];
}

- (void)bannerViewWillPresentModal:(POBBannerView *)bannerView {
    LogAdapterDelegate_Internal(logCallbackEmpty);
    [self.delegate adWillPresentScreen];
}

- (void)bannerViewDidDismissModal:(POBBannerView *)bannerView {
    LogAdapterDelegate_Internal(logCallbackEmpty);
    [self.delegate adDidDismissScreen];
}

@end
