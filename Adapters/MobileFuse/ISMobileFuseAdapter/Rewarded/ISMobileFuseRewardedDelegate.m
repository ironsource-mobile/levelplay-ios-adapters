//
//  ISMobileFuseRewardedDelegate.m
//  ISMobileFuseAdapter
//
//  Copyright © 2021-2025 Unity Technologies. All rights reserved.
//

#import <IronSource/ISLog.h>
#import <IronSource/ISError.h>
#import <IronSource/ISBaseRewardedVideo.h>
#import "ISMobileFuseRewardedDelegate.h"
#import "ISMobileFuseConstants.h"

@implementation ISMobileFuseRewardedDelegate

- (instancetype)initWithDelegate:(id<ISRewardedVideoAdDelegate>)delegate {
    self = [super init];
    if (self) {
        _delegate = delegate;
    }
    return self;
}

/// Ad has loaded - you are able to show the ad after this callback is triggered
- (void)onAdLoaded:(MFAd *)ad {
    LogAdapterDelegate_Internal(logCallbackEmpty);
    [self.delegate adDidLoad];
}

/// No ad is currently available to display to this user
- (void)onAdNotFilled:(MFAd *)ad {
    LogAdapterDelegate_Internal(logCallbackEmpty);
    [self.delegate adDidFailToLoadWithErrorType:ISAdapterErrorTypeNoFill
                                      errorCode:ERROR_RV_LOAD_NO_FILL
                                   errorMessage:logNoFill];
}

- (void)onAdError:(MFAd *)ad withError:(MFAdError *)error {
    LogAdapterDelegate_Internal(logLoadFailed, networkName, error.description);

    if (error.code == MobileFuseAlreadyLoaded || error.code == MobileFuseLoadError) {
        [self.delegate adDidFailToLoadWithErrorType:ISAdapterErrorTypeInternal
                                          errorCode:error.code
                                       errorMessage:error.description];
    } else {
        [self.delegate adDidFailToShowWithErrorCode:error.code
                                       errorMessage:error.description];
    }
}

/// Triggered when the ad begins to show to the user
- (void)onAdRendered:(MFAd *)ad {
    LogAdapterDelegate_Internal(logCallbackEmpty);
    [self.delegate adDidOpen];
}

/// The user has watched this rewarded ad and earned the reward for doing so
- (void)onUserEarnedReward:(MFAd *)ad {
    LogAdapterDelegate_Internal(logCallbackEmpty);
    [self.delegate adRewarded];
}

/// Triggered when the ad is clicked by the user
- (void)onAdClicked:(MFAd *)ad {
    LogAdapterDelegate_Internal(logCallbackEmpty);
    [self.delegate adDidClick];
}

/// The ad has been displayed and closed
- (void)onAdClosed:(MFAd *)ad {
    LogAdapterDelegate_Internal(logCallbackEmpty);
    [self.delegate adDidClose];
}

/// Triggered when a loaded ad has expired - you should manually try to load a new ad here
- (void)onAdExpired:(MFAd *)ad {
    LogAdapterDelegate_Internal(logCallbackEmpty);
    [self.delegate adDidFailToLoadWithErrorType:ISAdapterErrorTypeInternal
                                      errorCode:ERROR_RV_EXPIRED_ADS
                                   errorMessage:logAdsExpired];
}

@end
