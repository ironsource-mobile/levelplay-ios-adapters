//
//  ISAdMobRewardedDelegate.m
//  ISAdMobAdapter
//
//  Copyright © 2021-2025 Unity Technologies. All rights reserved.
//

#import "ISAdMobRewardedDelegate.h"
#import "ISAdMobConstants.h"
#import <IronSource/ISBaseRewardedVideo.h>
#import <IronSource/ISLog.h>

@implementation ISAdMobRewardedDelegate

- (instancetype)initWithDelegate:(id<ISRewardedVideoAdDelegate>)delegate {
    self = [super init];
    if (self) {
        _delegate = delegate;
    }
    return self;
}

#pragma mark - GADFullScreenContentDelegate

- (void)adWillPresentFullScreenContent:(id<GADFullScreenPresentingAd>)ad {
    LogAdapterDelegate_Internal(logCallbackEmpty);
}

- (void)ad:(id<GADFullScreenPresentingAd>)ad didFailToPresentFullScreenContentWithError:(NSError *)error {
    LogAdapterDelegate_Internal(logShowFailed, networkName, error);
    [self.delegate adDidFailToShowWithErrorCode:error.code
                                   errorMessage:error.localizedDescription];
}

- (void)adDidRecordImpression:(id<GADFullScreenPresentingAd>)ad {
    LogAdapterDelegate_Internal(logCallbackEmpty);
    [self.delegate adDidOpen];
}

- (void)adDidRecordClick:(id<GADFullScreenPresentingAd>)ad {
    LogAdapterDelegate_Internal(logCallbackEmpty);
    [self.delegate adDidClick];
}

- (void)adWillDismissFullScreenContent:(id<GADFullScreenPresentingAd>)ad {
    LogAdapterDelegate_Internal(logCallbackEmpty);
}

- (void)adDidDismissFullScreenContent:(id<GADFullScreenPresentingAd>)ad {
    LogAdapterDelegate_Internal(logCallbackEmpty);
    [self.delegate adDidClose];
}

@end
