//
//  ISUnityAdsBannerDelegate.m
//  ISUnityAdsAdapter
//
//  Copyright © 2021-2025 Unity Technologies. All rights reserved.
//

#import <IronSource/ISBannerAdDelegate.h>
#import <IronSource/ISError.h>
#import <IronSource/ISAdapterErrorType.h>
#import <IronSource/ISLog.h>
#import "ISUnityAdsBannerDelegate.h"
#import "ISUnityAdsAdapter+Internal.h"

@implementation ISUnityAdsBannerDelegate

- (instancetype)initWithDelegate:(id<ISBannerAdDelegate>)delegate {
    self = [super init];
    if (self) {
        _delegate = delegate;
    }
    return self;
}

- (void)bannerImpression:(UADSBannerAd * _Nonnull)banner {
    LogAdapterDelegate_Internal(logCallbackEmpty);
    [self.delegate adDidOpen];
}

- (void)bannerDidClick:(UADSBannerAd * _Nonnull)banner {
    LogAdapterDelegate_Internal(logCallbackEmpty);
    [self.delegate adDidClick];
}

- (void)bannerDidFailShow:(UADSBannerAd * _Nonnull)banner
                    error:(id<UnityAdsError> _Nonnull)error {
    LogAdapterDelegate_Internal(logError, error.message);
    [self.delegate adDidFailToShowWithErrorCode:error.code
                                   errorMessage:error.message];
}

@end
