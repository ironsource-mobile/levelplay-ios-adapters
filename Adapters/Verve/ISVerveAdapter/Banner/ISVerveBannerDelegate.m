//
//  ISVerveBannerDelegate.m
//  ISVerveAdapter
//
//  Copyright © 2021-2025 Unity Technologies. All rights reserved.
//

#import "ISVerveBannerDelegate.h"
#import "ISVerveConstants.h"
#import <IronSource/ISBaseBanner.h>
#import <IronSource/ISAdapterErrorType.h>
#import <IronSource/ISLog.h>

@implementation ISVerveBannerDelegate

- (instancetype)initWithDelegate:(id<ISBannerAdDelegate>)delegate {
    self = [super init];
    if (self) {
        _delegate = delegate;
    }
    return self;
}

/// calls this method when ad successfully loaded and ready to be displayed.
/// @param adView adView object that was loaded
- (void)adViewDidLoad:(HyBidAdView *)adView {
    LogAdapterDelegate_Internal(logCallbackEmpty);
    [self.delegate adDidLoadWithView:adView];
}

/// calls this method when ad was not loaded for some reasons
/// @param adView adView object that was loaded
/// @param error the reason of failing loading
- (void)adView:(HyBidAdView *)adView didFailWithError:(NSError *)error {
    LogAdapterDelegate_Internal(logLoadFailed, networkName, error);
    ISAdapterErrorType errorType = (error.code == HyBidErrorCodeNoFill) ? ISAdapterErrorTypeNoFill : ISAdapterErrorTypeInternal;
    [self.delegate adDidFailToLoadWithErrorType:errorType
                                      errorCode:error.code
                                   errorMessage:error.localizedDescription];
}

/// calls this method when user clicked on the ad
/// @param adView adView object that was clicked
- (void)adViewDidTrackClick:(HyBidAdView *)adView {
    LogAdapterDelegate_Internal(logCallbackEmpty);
    [self.delegate adDidClick];
}

/// calls this method when ad was displayed and is viewable by the user
- (void)adViewDidTrackImpression:(HyBidAdView *)adView {
    LogAdapterDelegate_Internal(logCallbackEmpty);
    [self.delegate adDidOpen];
}

@end
