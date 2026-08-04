//
//  ISOguryBannerDelegate.m
//  ISOguryAdapter
//
//  Copyright © 2021-2025 Unity Technologies. All rights reserved.
//

#import <OguryAds/OguryAds.h>
#import <IronSource/ISLog.h>
#import <IronSource/ISBannerAdDelegate.h>
#import <IronSource/ISAdapterErrorType.h>
#import "ISOguryBannerDelegate.h"
#import "ISOguryConstants.h"

@implementation ISOguryBannerDelegate

- (instancetype)initWithDelegate:(id<ISBannerAdDelegate>)delegate {
    self = [super init];
    if (self) {
        _delegate = delegate;
    }
    return self;
}

#pragma mark - OguryBannerAdViewDelegate

- (void)bannerAdViewDidLoad:(OguryBannerAdView *)bannerAd {
    LogAdapterDelegate_Internal(logCallbackEmpty);
    [self.delegate adDidLoadWithView:bannerAd];
}

- (void)bannerAdView:(OguryBannerAdView *)bannerAd didFailWithError:(OguryAdError *)error {
    LogAdapterDelegate_Internal(logError, error);
    ISAdapterErrorType errorType = (error.code == OguryLoadErrorCodeNoFill) ? ISAdapterErrorTypeNoFill : ISAdapterErrorTypeInternal;
    [self.delegate adDidFailToLoadWithErrorType:errorType
                                      errorCode:error.code
                                   errorMessage:error.localizedDescription];
}

- (void)bannerAdViewDidTriggerImpression:(OguryBannerAdView *)bannerAd {
    LogAdapterDelegate_Internal(logCallbackEmpty);
    [self.delegate adDidOpen];
}

- (void)bannerAdViewDidClick:(OguryBannerAdView *)bannerAd {
    LogAdapterDelegate_Internal(logCallbackEmpty);
    [self.delegate adDidClick];
}

- (void)bannerAdViewDidClose:(OguryBannerAdView *)bannerAd {
    LogAdapterDelegate_Internal(logCallbackEmpty);
}

@end
