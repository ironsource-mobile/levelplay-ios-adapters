//
//  ISMobileFuseBannerDelegate.m
//  ISMobileFuseAdapter
//
//  Copyright © 2021-2025 Unity Technologies. All rights reserved.
//

#import <IronSource/ISLog.h>
#import <IronSource/ISError.h>
#import <IronSource/ISBaseBanner.h>
#import "ISMobileFuseBannerDelegate.h"
#import "ISMobileFuseConstants.h"

@implementation ISMobileFuseBannerDelegate

- (instancetype)initWithDelegate:(id<ISBannerAdDelegate>)delegate {
    self = [super init];
    if (self) {
        _delegate = delegate;
    }
    return self;
}

/// Ad has loaded - you are able to show the ad after this callback is triggered
- (void)onAdLoaded:(MFAd *)ad {
    LogAdapterDelegate_Internal(logCallbackEmpty);
    [self.delegate adDidLoadWithView:ad];
    [ad showAd];
}

/// No ad is currently available to display to this user
- (void)onAdNotFilled:(MFAd *)ad {
    LogAdapterDelegate_Internal(logCallbackEmpty);
    [self.delegate adDidFailToLoadWithErrorType:ISAdapterErrorTypeNoFill
                                      errorCode:ERROR_BN_LOAD_NO_FILL
                                   errorMessage:logNoFill];
}

- (void)onAdError:(MFAd *)ad withError:(MFAdError *)error {
    LogAdapterDelegate_Internal(logLoadFailed, networkName, error.description);
    [self.delegate adDidFailToLoadWithErrorType:ISAdapterErrorTypeInternal
                                      errorCode:error.code
                                   errorMessage:error.description];
}

/// Triggered when the ad begins to show to the user
- (void)onAdRendered:(MFAd *)ad {
    LogAdapterDelegate_Internal(logCallbackEmpty);
    [self.delegate adDidOpen];
}

/// Triggered when the ad is clicked by the user
- (void)onAdClicked:(MFAd *)ad {
    LogAdapterDelegate_Internal(logCallbackEmpty);
    [self.delegate adDidClick];
}

/// Triggered when a loaded ad has expired - you should manually try to load a new ad here
- (void)onAdExpired:(MFAd *)ad {
    LogAdapterDelegate_Internal(logCallbackEmpty);
}

@end
