//
//  ISUnityAdsInterstitialDelegate.m
//  ISUnityAdsAdapter
//
//  Copyright © 2021-2025 Unity Technologies. All rights reserved.
//

#import <IronSource/ISBaseInterstitial.h>
#import <IronSource/ISError.h>
#import <IronSource/ISAdapterErrorType.h>
#import <IronSource/ISLog.h>
#import "ISUnityAdsInterstitialDelegate.h"
#import "ISUnityAdsAdapter+Internal.h"

@implementation ISUnityAdsInterstitialDelegate

- (instancetype)initWithDelegate:(id<ISInterstitialAdDelegate>)delegate {
    self = [super init];
    if (self) {
        _delegate = delegate;
    }
    return self;
}

- (void)showDidStart:(UnityAd * _Nonnull)unityAd {
    LogAdapterDelegate_Internal(logCallbackEmpty);
    [self.delegate adDidOpen];
}

- (void)showDidClick:(UnityAd * _Nonnull)unityAd {
    LogAdapterDelegate_Internal(logCallbackEmpty);
    [self.delegate adDidClick];
}

- (void)showDidComplete:(UnityAd * _Nonnull)unityAd
                   with:(enum UADSShowFinishState)finishState {
    LogAdapterDelegate_Internal(logCallbackEmpty);
    [self.delegate adDidClose];
}

- (void)showDidFail:(UnityAd * _Nonnull)unityAd
              error:(id<UnityAdsError> _Nonnull)error {
    LogAdapterDelegate_Internal(logError, error.message);
    [self.delegate adDidFailToShowWithErrorCode:error.code
                                   errorMessage:error.message];
}

@end
