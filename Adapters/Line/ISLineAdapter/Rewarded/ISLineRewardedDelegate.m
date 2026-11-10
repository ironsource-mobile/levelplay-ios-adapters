//
//  ISLineRewardedDelegate.m
//  ISLineAdapter
//
//  Copyright © 2021-2025 Unity Technologies. All rights reserved.
//

#import <IronSource/ISBaseRewardedVideo.h>
#import <IronSource/ISError.h>
#import <IronSource/ISAdapterErrorType.h>
#import <IronSource/ISLog.h>
#import "ISLineRewardedDelegate.h"
#import "ISLineConstants.h"

@implementation ISLineRewardedDelegate

- (instancetype)initWithDelegate:(id<ISRewardedVideoAdDelegate>)delegate {
    self = [super init];
    if (self) {
        _delegate = delegate;
    }
    return self;
}

- (void)fiveVideoRewardAd:(nonnull FADVideoReward *)ad
didFailedToShowAdWithError:(FADErrorCode)errorCode {
    LogAdapterDelegate_Internal(logError, @(errorCode));
    [self.delegate adDidFailToShowWithErrorCode:ERROR_CODE_NO_ADS_TO_SHOW
                                   errorMessage:logNoAdsToShow];
}

- (void)fiveVideoRewardAdDidImpression:(nonnull FADVideoReward *)ad {
    LogAdapterDelegate_Internal(logCallbackEmpty);
    [self.delegate adDidOpen];
}

- (void)fiveVideoRewardAdDidPlay:(nonnull FADVideoReward *)ad {
    LogAdapterDelegate_Internal(logCallbackEmpty);
}

- (void)fiveVideoRewardAdDidViewThrough:(nonnull FADVideoReward *)ad {
    LogAdapterDelegate_Internal(logCallbackEmpty);
}

- (void)fiveVideoRewardAdDidClick:(nonnull FADVideoReward *)ad {
    LogAdapterDelegate_Internal(logCallbackEmpty);
    [self.delegate adDidClick];
}

- (void)fiveVideoRewardAdDidReward:(nonnull FADVideoReward *)ad {
    LogAdapterDelegate_Internal(logCallbackEmpty);
    [self.delegate adRewarded];
}

- (void)fiveVideoRewardAdFullScreenDidClose:(nonnull FADVideoReward *)ad {
    LogAdapterDelegate_Internal(logCallbackEmpty);
    [self.delegate adDidClose];
}

- (void)fiveVideoRewardAdFullScreenDidOpen:(nonnull FADVideoReward *)ad {
    LogAdapterDelegate_Internal(logCallbackEmpty);
}

- (void)fiveVideoRewardAdDidPause:(nonnull FADVideoReward *)ad {
    LogAdapterDelegate_Internal(logCallbackEmpty);
}

@end
