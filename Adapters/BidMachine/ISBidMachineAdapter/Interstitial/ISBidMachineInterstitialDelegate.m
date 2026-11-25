//
//  ISBidMachineInterstitialDelegate.m
//  ISBidMachineAdapter
//
//  Copyright © 2021-2025 Unity Technologies. All rights reserved.
//

#import "ISBidMachineInterstitialDelegate.h"
#import "ISBidMachineInterstitialAdapter.h"
#import "ISBidMachineConstants.h"
#import <IronSource/ISLog.h>
#import <IronSource/ISAdapterErrorType.h>
#import <IronSource/ISAdapterErrors.h>
#import <IronSource/ISBaseInterstitial.h>

@implementation ISBidMachineInterstitialDelegate

- (instancetype)initWithAdapter:(ISBidMachineInterstitialAdapter *)adapter
                       delegate:(id<ISInterstitialAdDelegate>)delegate {
    self = [super init];
    if (self) {
        _adapter = adapter;
        _delegate = delegate;
    }
    return self;
}

- (void)interstitialDidPresent:(BidMachineInterstitial * _Nonnull)ad {
    LogAdapterDelegate_Internal(logEmptyCallback);
}

- (void)interstitialDidTrackImpression:(BidMachineInterstitial * _Nonnull)ad {
    LogAdapterDelegate_Internal(logEmptyCallback);
    [self.delegate adDidOpen];
}

- (void)interstitialDidFailPresent:(BidMachineInterstitial * _Nonnull)ad
                             error:(BidMachineError * _Nonnull)error {
    LogAdapterDelegate_Internal(logError, error.description);
    [self.delegate adDidFailToShowWithErrorCode:error.code
                                   errorMessage:error.description];
}

- (void)interstitialDidClick:(BidMachineInterstitial * _Nonnull)ad {
    LogAdapterDelegate_Internal(logEmptyCallback);
    [self.delegate adDidClick];
}

- (void)interstitialDidExpire:(BidMachineInterstitial * _Nonnull)ad {
    LogAdapterDelegate_Internal(logAdExpired);
    [self.adapter releaseAd];
    [self.delegate adDidFailToLoadWithErrorType:ISAdapterErrorTypeAdExpired
                                      errorCode:ISAdapterErrorAdExpired
                                   errorMessage:logAdExpired];
}

- (void)interstitialDidDismiss:(BidMachineInterstitial * _Nonnull)ad {
    LogAdapterDelegate_Internal(logEmptyCallback);
    [self.delegate adDidClose];
}

@end
