//
//  ISSmaatoBannerDelegate.m
//  ISSmaatoAdapter
//
//  Copyright © 2021-2025 Unity Technologies. All rights reserved.
//

#import <IronSource/ISBannerAdDelegate.h>
#import <IronSource/ISError.h>
#import <IronSource/ISAdapterErrorType.h>
#import <IronSource/ISLog.h>
#import "ISSmaatoBannerDelegate.h"
#import "ISSmaatoAdapter+Internal.h"

@implementation ISSmaatoBannerDelegate

- (instancetype)initWithViewController:(UIViewController *)viewController
                              delegate:(id<ISBannerAdDelegate>)delegate {
    self = [super init];
    if (self) {
        _viewController = viewController;
        _delegate = delegate;
    }
    return self;
}

- (UIViewController *)presentingViewControllerForBannerView:(SMABannerView *)bannerView {
    return self.viewController;
}

- (void)bannerViewDidLoad:(SMABannerView *_Nonnull)bannerView {
    NSString *creativeId = bannerView.sci;
    LogAdapterDelegate_Internal(logCreativeId, creativeId);

    if (creativeId.length) {
        [self.delegate adDidLoadWithView:bannerView
                               extraData:@{creativeIdKey: creativeId}];
    } else {
        [self.delegate adDidLoadWithView:bannerView];
    }
}

- (void)bannerView:(SMABannerView *_Nonnull)bannerView
    didFailWithError:(NSError *_Nonnull)error {
    LogAdapterDelegate_Internal(logError, error);

    BOOL isNoFill = error.code == kSMAErrorCodeNoAdAvailable;
    [self.delegate adDidFailToLoadWithErrorType:(isNoFill ? ISAdapterErrorTypeNoFill : ISAdapterErrorTypeInternal)
                                      errorCode:(isNoFill ? ERROR_BN_LOAD_NO_FILL : error.code)
                                   errorMessage:(isNoFill ? logNoFill : error.localizedDescription)];
}

- (void)bannerViewDidImpress:(SMABannerView *_Nonnull)bannerView {
    LogAdapterDelegate_Internal(logCallbackEmpty);
    [self.delegate adDidOpen];
}

- (void)bannerViewDidClick:(SMABannerView *_Nonnull)bannerView {
    LogAdapterDelegate_Internal(logCallbackEmpty);
    [self.delegate adDidClick];
}

- (void)bannerWillLeaveApplicationFromAd:(SMABannerView *_Nonnull)bannerView {
    LogAdapterDelegate_Internal(logCallbackEmpty);
    [self.delegate adWillLeaveApplication];
}

- (void)bannerViewWillPresentModalContent:(SMABannerView *_Nonnull)bannerView {
    LogAdapterDelegate_Internal(logCallbackEmpty);
    [self.delegate adWillPresentScreen];
}

- (void)bannerViewDidDismissModalContent:(SMABannerView *_Nonnull)bannerView {
    LogAdapterDelegate_Internal(logCallbackEmpty);
    [self.delegate adDidDismissScreen];
}

- (void)bannerViewDidPresentModalContent:(SMABannerView *_Nonnull)bannerView {
    LogAdapterDelegate_Internal(logCallbackEmpty);
}

- (void)bannerViewDidTTLExpire:(SMABannerView *_Nonnull)bannerView {
    LogAdapterDelegate_Internal(logAdExpired);
}

@end
