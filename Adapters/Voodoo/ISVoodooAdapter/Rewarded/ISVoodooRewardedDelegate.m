//
//  ISVoodooRewardedDelegate.m
//  ISVoodooAdapter
//
//  Copyright © 2021-2025 Unity Technologies. All rights reserved.
//

#import <IronSource/ISBaseRewardedVideo.h>
#import <IronSource/ISLog.h>
#import "ISVoodooRewardedDelegate.h"
#import "ISVoodooConstants.h"

@implementation ISVoodooRewardedDelegate

- (instancetype)initWithDelegate:(id<ISRewardedVideoAdDelegate>)delegate {
    self = [super init];
    if (self) {
        _delegate = delegate;
    }
    return self;
}

#pragma mark - Rewarded Delegate

- (void)didRecordAdImpression {
    LogAdapterDelegate_Internal(logCallbackEmpty);
    [self.delegate adDidOpen];
}

- (void)didRecordAdClick {
    LogAdapterDelegate_Internal(logCallbackEmpty);
    [self.delegate adDidClick];
}

- (void)onAdRewarded {
    LogAdapterDelegate_Internal(logCallbackEmpty);
    [self.delegate adRewarded];
}

- (void)didFailToPresentFullscreenAdWithError:(NSError *_Nullable)error {
    LogAdapterDelegate_Internal(logError, error.description);
    [self.delegate adDidFailToShowWithErrorCode:error.code
                                   errorMessage:error.localizedDescription];
}

- (void)didDismissFullscreenAd {
    LogAdapterDelegate_Internal(logCallbackEmpty);
    [self.delegate adDidClose];
}

- (void)didPresentFullscreenAd {
    LogAdapterDelegate_Internal(logCallbackEmpty);
}

@end
