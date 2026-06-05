//
//  ISYandexBannerDelegate.m
//  ISYandexAdapter
//
//  Copyright © 2021-2025 Unity Technologies. All rights reserved.
//

#import <Foundation/Foundation.h>
@import YandexMobileAds;
#import <IronSource/ISBaseBanner.h>
#import <IronSource/ISAdapterErrorType.h>
#import <IronSource/ISLog.h>
#import "ISYandexBannerDelegate.h"
#import "ISYandexBannerAdapter.h"
#import "ISYandexAdapter+Internal.h"
#import "ISYandexConstants.h"

@implementation ISYandexBannerDelegate

- (instancetype)initWithDelegate:(id<ISBannerAdDelegate>)delegate {
    self = [super init];
    if (self) {
        _delegate = delegate;
    }
    return self;
}

/// Notifies that the banner is loaded.
- (void)bannerAdViewDidLoad:(YMABannerAdView * _Nonnull)bannerAdView {
    // Extract creative IDs and pass as extra data if available
    NSString *creativeId = [ISYandexAdapter buildCreativeIdStringFromCreatives:bannerAdView.adInfo.creatives];
    LogAdapterDelegate_Internal(logCreativeId, creativeId);

    if (creativeId.length) {
        NSDictionary<NSString *, id> *extraData = @{creativeIdKey: creativeId};
        [self.delegate adDidLoadWithView:bannerAdView extraData:extraData];
    } else {
        [self.delegate adDidLoadWithView:bannerAdView];
    }
}

/// Notifies that the banner failed to load.
- (void)bannerAdViewDidFailLoading:(YMABannerAdView * _Nonnull)bannerAdView error:(NSError * _Nonnull)error {
    LogAdapterDelegate_Internal(logError, error);

    ISAdapterErrorType errorType = (error.code == yandexNoFillErrorCode) ? ISAdapterErrorTypeNoFill : ISAdapterErrorTypeInternal;

    [self.delegate adDidFailToLoadWithErrorType:errorType
                                      errorCode:error.code
                                   errorMessage:error.localizedDescription];
}

/// Notifies delegate when an impression was tracked.
- (void)bannerAdView:(YMABannerAdView * _Nonnull)bannerAdView
didTrackImpressionWithData:(id <YMAImpressionData> _Nullable)impressionData {
    LogAdapterDelegate_Internal(logCallbackEmpty);
    [self.delegate adDidOpen];
}

/// Notifies that the user has clicked on the banner.
- (void)bannerAdViewDidClick:(YMABannerAdView * _Nonnull)bannerAdView {
    LogAdapterDelegate_Internal(logCallbackEmpty);
    [self.delegate adDidClick];
}

@end
