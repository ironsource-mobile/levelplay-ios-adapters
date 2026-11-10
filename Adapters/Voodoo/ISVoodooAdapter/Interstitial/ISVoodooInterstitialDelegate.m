//
//  ISVoodooInterstitialDelegate.m
//  ISVoodooAdapter
//
//  Copyright © 2021-2025 Unity Technologies. All rights reserved.
//

#import <IronSource/ISBaseInterstitial.h>
#import <IronSource/ISLog.h>
#import "ISVoodooInterstitialDelegate.h"
#import "ISVoodooConstants.h"

@implementation ISVoodooInterstitialDelegate

- (instancetype)initWithDelegate:(id<ISInterstitialAdDelegate>)delegate {
    self = [super init];
    if (self) {
        _delegate = delegate;
    }
    return self;
}

#pragma mark - Interstitial Delegate

- (void)didRecordAdImpression {
    LogAdapterDelegate_Internal(logCallbackEmpty);
    [self.delegate adDidOpen];
}

- (void)didRecordAdClick {
    LogAdapterDelegate_Internal(logCallbackEmpty);
    [self.delegate adDidClick];
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

- (void)onAdRewarded {
    LogAdapterDelegate_Internal(logCallbackEmpty);
}

@end
