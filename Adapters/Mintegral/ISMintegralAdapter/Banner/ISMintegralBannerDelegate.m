//
//  ISMintegralBannerDelegate.m
//  ISMintegralAdapter
//
//  Copyright © 2021-2025 Unity Technologies. All rights reserved.
//

#import <MTGSDK/MTGErrorCodeConstant.h>
#import <IronSource/ISLog.h>
#import <IronSource/ISBaseBanner.h>
#import <IronSource/ISAdapterErrorType.h>
#import "ISMintegralBannerDelegate.h"
#import "ISMintegralConstants.h"

@implementation ISMintegralBannerDelegate

- (instancetype)initWithDelegate:(id<ISBannerAdDelegate>)delegate {
    self = [super init];
    if (self) {
        _delegate = delegate;
    }
    return self;
}

#pragma mark - MTGBannerAdViewDelegate

- (void)adViewLoadSuccess:(MTGBannerAdView *)adView {
    NSString *creativeId = adView.creativeId;
    LogAdapterDelegate_Internal(logCreativeId, creativeId);

    if (creativeId.length) {
        NSDictionary *extraData = @{creativeIdKey: creativeId};
        [self.delegate adDidLoadWithView:adView extraData:extraData];
    } else {
        [self.delegate adDidLoadWithView:adView];
    }
}

- (void)adViewLoadFailedWithError:(NSError *)error adView:(MTGBannerAdView *)adView {
    LogAdapterDelegate_Internal(logError, error);

    BOOL isNoFill = error.code == mintegralNoFillEmptyError ||
                    error.code == kMTGErrorCodeNoAds ||
                    error.code == kMTGErrorCodeNoAdsAvailableToPlay;
    ISAdapterErrorType errorType = isNoFill ? ISAdapterErrorTypeNoFill : ISAdapterErrorTypeInternal;

    [self.delegate adDidFailToLoadWithErrorType:errorType
                                      errorCode:error.code
                                   errorMessage:error.description];
}

- (void)adViewWillLogImpression:(MTGBannerAdView *)adView {
    LogAdapterDelegate_Internal(logCallbackEmpty);
    [self.delegate adDidOpen];
}

- (void)adViewDidClicked:(MTGBannerAdView *)adView {
    LogAdapterDelegate_Internal(logCallbackEmpty);
    [self.delegate adDidClick];
}

- (void)adViewWillOpenFullScreen:(MTGBannerAdView *)adView {
    LogAdapterDelegate_Internal(logCallbackEmpty);
    [self.delegate adWillPresentScreen];
}

- (void)adViewCloseFullScreen:(MTGBannerAdView *)adView {
    LogAdapterDelegate_Internal(logCallbackEmpty);
    [self.delegate adDidDismissScreen];
}

- (void)adViewWillLeaveApplication:(MTGBannerAdView *)adView {
    LogAdapterDelegate_Internal(logCallbackEmpty);
    [self.delegate adWillLeaveApplication];
}

- (void)adViewClosed:(MTGBannerAdView *)adView {
    LogAdapterDelegate_Internal(logCallbackEmpty);
}

@end
