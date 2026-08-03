//
//  ISFyberRewardedDelegate.m
//  ISFyberAdapter
//
//  Copyright © 2021-2025 Unity Technologies. All rights reserved.
//

#import <IASDKCore/IASDKCore.h>
#import <IronSource/ISLog.h>
#import <IronSource/ISError.h>
#import <IronSource/ISBaseRewardedVideo.h>
#import <IronSource/ISAdapterErrorType.h>
#import "ISFyberRewardedDelegate.h"
#import "ISFyberConstants.h"

@implementation ISFyberRewardedDelegate

- (instancetype)initWithDelegate:(id<ISRewardedVideoAdDelegate>)delegate {
    self = [super init];
    if (self) {
        _delegate = delegate;
    }
    return self;
}

#pragma mark - IAUnitDelegate

- (UIViewController *)IAParentViewControllerForUnitController:(IAUnitController *)unitController {
    return self.viewControllerForPresentingModalView;
}

/// Called when the ad is shown and logs an impression.
- (void)IAAdWillLogImpression:(IAUnitController *)unitController {
    LogAdapterDelegate_Internal(logCallbackEmpty);
    [self.delegate adDidOpen];
}

/// Called when the user clicks the ad.
- (void)IAAdDidReceiveClick:(IAUnitController *)unitController {
    LogAdapterDelegate_Internal(logCallbackEmpty);
    [self.delegate adDidClick];
}

/// Called when the user has earned a reward.
- (void)IAAdDidReward:(IAUnitController *)unitController {
    LogAdapterDelegate_Internal(logCallbackEmpty);
    [self.delegate adRewarded];
}

/// Called when the ad expires and is no longer available to show.
- (void)IAAdDidExpire:(IAUnitController *)unitController {
    LogAdapterDelegate_Internal(logCallbackEmpty);
    [self.delegate adDidFailToShowWithErrorCode:ERROR_RV_EXPIRED_ADS
                                   errorMessage:errorExpiredAds];
}

/// Called when the fullscreen ad is dismissed.
- (void)IAUnitControllerDidDismissFullscreen:(IAUnitController *)unitController {
    LogAdapterDelegate_Internal(logCallbackEmpty);
    [self.delegate adDidClose];
}

#pragma mark - IAVideoContentDelegate

/// Called when the video content finishes playing.
- (void)IAVideoCompleted:(IAVideoContentController *)contentController {
    LogAdapterDelegate_Internal(logCallbackEmpty);
}

/// Called when the video content is interrupted by an error.
- (void)IAVideoContentController:(IAVideoContentController *)contentController videoInterruptedWithError:(NSError *)error {
    LogAdapterDelegate_Internal(logError, error);
}

@end
