//
//  ISFyberBannerDelegate.m
//  ISFyberAdapter
//
//  Copyright © 2021-2025 Unity Technologies. All rights reserved.
//

#import <IASDKCore/IASDKCore.h>
#import <IronSource/ISLog.h>
#import <IronSource/ISBaseBanner.h>
#import <IronSource/ISAdapterErrorType.h>
#import "ISFyberBannerDelegate.h"
#import "ISFyberConstants.h"

@implementation ISFyberBannerDelegate

- (instancetype)initWithDelegate:(id<ISBannerAdDelegate>)delegate {
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

/// Called when the ad logs an impression.
- (void)IAAdWillLogImpression:(IAUnitController *)unitController {
    LogAdapterDelegate_Internal(logCallbackEmpty);
    [self.delegate adDidOpen];
}

/// Called when the user clicks the ad.
- (void)IAAdDidReceiveClick:(IAUnitController *)unitController {
    LogAdapterDelegate_Internal(logCallbackEmpty);
    [self.delegate adDidClick];
}

/// Called when the ad is about to open an external application.
- (void)IAUnitControllerWillOpenExternalApp:(IAUnitController *)unitController {
    LogAdapterDelegate_Internal(logCallbackEmpty);
    [self.delegate adWillLeaveApplication];
}

/// Called when the ad is about to present a fullscreen view.
- (void)IAUnitControllerWillPresentFullscreen:(IAUnitController *)unitController {
    LogAdapterDelegate_Internal(logCallbackEmpty);
    [self.delegate adWillPresentScreen];
}

/// Called when the ad dismisses a fullscreen view.
- (void)IAUnitControllerDidDismissFullscreen:(IAUnitController *)unitController {
    LogAdapterDelegate_Internal(logCallbackEmpty);
    [self.delegate adDidDismissScreen];
}

@end
