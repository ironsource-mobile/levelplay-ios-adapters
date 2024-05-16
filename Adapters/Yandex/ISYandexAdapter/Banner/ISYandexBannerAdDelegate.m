//
//  ISYandexBannerAdDelegate.m
//  ISYandexAdapter
//
//  Copyright © 2024 ironSource Mobile Ltd. All rights reserved.
//

#import "ISYandexBannerAdapter.h"
#import "ISYandexBannerAdDelegate.h"

@implementation ISYandexBannerAdDelegate

- (instancetype)initWithAdUnitId:(NSString *)adUnitId
                     andDelegate:(id<ISBannerAdapterDelegate>)delegate {
    self = [super init];
    if (self) {
        _adUnitId = adUnitId;
        _delegate = delegate;
    }
    return self;
}

/// Notifies that the banner is loaded.
/// remark:
/// At this time, you can add AdView if you haven’t done so yet.
/// @param adView A reference to the object of the AdView class that invoked the method.
- (void)adViewDidLoad:(YMAAdView * _Nonnull)adView {
    LogAdapterDelegate_Internal(@"adUnitId = %@", self.adUnitId);
    [self.delegate adapterBannerDidLoad:adView];
}

/// Notifies that the banner failed to load.
/// @param adView A reference to the object of the AdView class that invoked the method.
/// @param error Information about the error (for details, see AdErrorCode).
- (void)adViewDidFailLoading:(YMAAdView * _Nonnull)adView 
                       error:(NSError * _Nonnull)error {
    LogAdapterDelegate_Internal(@"adUnitID = %@ with error = %@", self.adUnitId, error);
    NSError *smashError = error.code == YMAAdErrorCodeNoFill ? [ISError createError:ERROR_BN_LOAD_NO_FILL
                                                                        withMessage:@"Yandex no fill"] : error;
    [self.delegate adapterBannerDidFailToLoadWithError:smashError];
}

/// Notifies delegate when an impression was tracked.
/// @param adView A reference to the object of the AdView class that invoked the method.
/// @param impressionData Ad impression-level revenue data.
- (void)adView:(YMAAdView * _Nonnull)adView
didTrackImpressionWithData:(id <YMAImpressionData> _Nullable)impressionData {
    LogAdapterDelegate_Internal(@"adUnitId = %@", self.adUnitId);
    [self.delegate adapterBannerDidShow];

}

/// Notifies that the user has clicked on the banner.
/// @param adView A reference to the object of the AdView class that invoked the method.
- (void)adViewDidClick:(YMAAdView * _Nonnull)adView {
    LogAdapterDelegate_Internal(@"adUnitId = %@", self.adUnitId);
    [self.delegate adapterBannerDidClick];
}


/// Notifies that the app will become inactive now because the user clicked on the banner ad
/// and is about to switch to a different application (Phone, App Store, and so on).
/// @param adView A reference to the object of the AdView class that invoked the method.
- (void)adViewWillLeaveApplication:(YMAAdView * _Nonnull)adView {
    LogAdapterDelegate_Internal(@"adUnitId = %@", self.adUnitId);
    [self.delegate adapterBannerWillLeaveApplication];
}


/// Notifies that the user has clicked on the banner and the in-app browser will open now.
/// @param adView A reference to the object of the AdView class that invoked the method.
/// @param viewController Modal UIViewController.
- (void)adView:(YMAAdView * _Nonnull)adView
willPresentScreen:(UIViewController * _Nullable)viewController {
    LogAdapterDelegate_Internal(@"adUnitId = %@", self.adUnitId);
    [self.delegate adapterBannerWillPresentScreen];
}


/// Notifies that the user has closed the embedded browser.
/// @param adView A reference to the object of the AdView class that invoked the method.
/// @param viewController Modal UIViewController.
- (void)adView:(YMAAdView * _Nonnull)adView 
didDismissScreen:(UIViewController * _Nullable)viewController {
    LogAdapterDelegate_Internal(@"adUnitId = %@", self.adUnitId);
    [self.delegate adapterBannerDidDismissScreen];
}

@end

