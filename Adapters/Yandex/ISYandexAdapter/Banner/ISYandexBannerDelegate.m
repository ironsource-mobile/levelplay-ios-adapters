//
//  ISYandexBannerDelegate.m
//  ISYandexAdapter
//
//  Copyright © 2021-2025 Unity Technologies. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <YandexMobileAds/YandexMobileAds.h>
#import <IronSource/ISBaseBanner.h>
#import <IronSource/ISAdapterErrorType.h>
#import <IronSource/ISLog.h>
#import "ISYandexBannerDelegate.h"
#import "ISYandexBannerAdapter.h"
#import "ISYandexAdapter+Internal.h"
#import "ISYandexConstants.h"

@implementation ISYandexBannerDelegate

- (instancetype)initWithAdUnitId:(NSString *)adUnitId
                     andDelegate:(id<ISBannerAdDelegate>)delegate {
    self = [super init];
    if (self) {
        _adUnitId = adUnitId;
        _delegate = delegate;
    }
    return self;
}

/// Notifies that the banner is loaded.
- (void)adViewDidLoad:(YMAAdView * _Nonnull)adView {
    // Extract creative IDs and pass as extra data if available
    NSString *creativeId = [ISYandexAdapter buildCreativeIdStringFromCreatives:adView.adInfo.creatives];
    LogAdapterDelegate_Internal(logCreativeId, creativeId);

    if (creativeId.length) {
        NSDictionary<NSString *, id> *extraData = @{creativeIdKey: creativeId};
        [self.delegate adDidLoadWithView:adView extraData:extraData];
    } else {
        [self.delegate adDidLoadWithView:adView];
    }
}

/// Notifies that the banner failed to load.
- (void)adViewDidFailLoading:(YMAAdView * _Nonnull)adView
                       error:(NSError * _Nonnull)error {
    LogAdapterDelegate_Internal(logCallbackFailed, self.adUnitId, error.localizedDescription);

    ISAdapterErrorType errorType = (error.code == yandexNoFillErrorCode) ? ISAdapterErrorTypeNoFill : ISAdapterErrorTypeInternal;

    [self.delegate adDidFailToLoadWithErrorType:errorType
                                      errorCode:error.code
                                   errorMessage:error.localizedDescription];
}

/// Notifies delegate when an impression was tracked.
- (void)adView:(YMAAdView * _Nonnull)adView
didTrackImpressionWithData:(id <YMAImpressionData> _Nullable)impressionData {
    LogAdapterDelegate_Internal(logCallbackEmpty);
    [self.delegate adDidOpen];
}

/// Notifies that the user has clicked on the banner.
- (void)adViewDidClick:(YMAAdView * _Nonnull)adView {
    LogAdapterDelegate_Internal(logCallbackEmpty);
    [self.delegate adDidClick];
}

/// Notifies that the app will become inactive now because the user clicked on the banner ad
/// and is about to switch to a different application (Phone, App Store, and so on).
- (void)adViewWillLeaveApplication:(YMAAdView * _Nonnull)adView {
    LogAdapterDelegate_Internal(logCallbackEmpty);
    [self.delegate adWillLeaveApplication];
}

/// Notifies that the user has clicked on the banner and the in-app browser will open now.
- (void)adView:(YMAAdView * _Nonnull)adView
willPresentScreen:(UIViewController * _Nullable)viewController {
    LogAdapterDelegate_Internal(logCallbackEmpty);
    [self.delegate adWillPresentScreen];
}

/// Notifies that the user has closed the embedded browser.
- (void)adView:(YMAAdView * _Nonnull)adView
didDismissScreen:(UIViewController * _Nullable)viewController {
    LogAdapterDelegate_Internal(logCallbackEmpty);
    [self.delegate adDidDismissScreen];
}

@end
