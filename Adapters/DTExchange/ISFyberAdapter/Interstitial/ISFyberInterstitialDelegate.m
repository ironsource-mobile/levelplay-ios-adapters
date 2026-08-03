//
//  ISFyberInterstitialDelegate.m
//  ISFyberAdapter
//
//  Copyright © 2021-2025 Unity Technologies. All rights reserved.
//

#import <IASDKCore/IASDKCore.h>
#import <IronSource/ISLog.h>
#import <IronSource/ISError.h>
#import <IronSource/ISBaseInterstitial.h>
#import <IronSource/ISAdapterErrorType.h>
#import "ISFyberInterstitialDelegate.h"
#import "ISFyberConstants.h"

@implementation ISFyberInterstitialDelegate

- (instancetype)initWithDelegate:(id<ISInterstitialAdDelegate>)delegate {
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

/// Called when the interstitial ad presents its fullscreen view.
- (void)IAUnitControllerDidPresentFullscreen:(IAUnitController *)unitController {
    LogAdapterDelegate_Internal(logCallbackEmpty);
}

/// Called when the ad is shown and logs an impression.
- (void)IAAdWillLogImpression:(IAUnitController *)unitController {
    LogAdapterDelegate_Internal(logCallbackEmpty);
    [self.delegate adDidOpen];
}

/// Called when the interstitial ad is clicked.
- (void)IAAdDidReceiveClick:(IAUnitController *)unitController {
    LogAdapterDelegate_Internal(logCallbackEmpty);
    [self.delegate adDidClick];
}

/// Called when the interstitial ad has expired.
- (void)IAAdDidExpire:(IAUnitController *)unitController {
    LogAdapterDelegate_Internal(logCallbackEmpty);
    [self.delegate adDidFailToShowWithErrorCode:ERROR_CODE_NO_ADS_TO_SHOW
                                   errorMessage:errorExpiredAds];
}

/// Called when the interstitial ad is dismissed.
- (void)IAUnitControllerDidDismissFullscreen:(IAUnitController *)unitController {
    LogAdapterDelegate_Internal(logCallbackEmpty);
    [self.delegate adDidClose];
}

/// Called when the interstitial video content is interrupted by an error.
- (void)IAVideoContentController:(IAVideoContentController *)contentController videoInterruptedWithError:(NSError *)error {
    LogAdapterDelegate_Internal(logError, error);
}

@end
