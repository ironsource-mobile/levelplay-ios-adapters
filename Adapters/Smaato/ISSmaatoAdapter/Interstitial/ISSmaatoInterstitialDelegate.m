//
//  ISSmaatoInterstitialDelegate.m
//  ISSmaatoAdapter
//
//  Copyright © 2021-2025 Unity Technologies. All rights reserved.
//

#import <IronSource/ISBaseInterstitial.h>
#import <IronSource/ISError.h>
#import <IronSource/ISAdapterErrorType.h>
#import <IronSource/ISLog.h>
#import "ISSmaatoInterstitialDelegate.h"
#import "ISSmaatoInterstitialAdapter.h"
#import "ISSmaatoAdapter+Internal.h"

@implementation ISSmaatoInterstitialDelegate

- (instancetype)initWithAdapter:(ISSmaatoInterstitialAdapter *)adapter
                       delegate:(id<ISInterstitialAdDelegate>)delegate {
    self = [super init];
    if (self) {
        _adapter = adapter;
        _delegate = delegate;
    }
    return self;
}

- (void)interstitialDidLoad:(SMAInterstitial *_Nonnull)interstitial {
    NSString *creativeId = interstitial.sci;
    LogAdapterDelegate_Internal(logCreativeId, creativeId);

    [self.adapter setInterstitialAd:interstitial];

    if (creativeId.length) {
        [self.delegate adDidLoadWithExtraData:@{creativeIdKey: creativeId}];
    } else {
        [self.delegate adDidLoad];
    }
}

- (void)interstitial:(SMAInterstitial *_Nullable)interstitial
           didFailWithError:(NSError *_Nonnull)error {
    LogAdapterDelegate_Internal(logError, error);

    [self.adapter setInterstitialAd:nil];

    BOOL isNoFill = error.code == kSMAErrorCodeNoAdAvailable;
    [self.delegate adDidFailToLoadWithErrorType:(isNoFill ? ISAdapterErrorTypeNoFill : ISAdapterErrorTypeInternal)
                                      errorCode:(isNoFill ? ERROR_IS_LOAD_NO_FILL : error.code)
                                   errorMessage:(isNoFill ? logNoFill : error.localizedDescription)];
}

- (void)interstitialDidAppear:(SMAInterstitial *_Nonnull)interstitial {
    LogAdapterDelegate_Internal(logCallbackEmpty);
    [self.delegate adDidOpen];
}

- (void)interstitialDidClick:(SMAInterstitial *_Nonnull)interstitial {
    LogAdapterDelegate_Internal(logCallbackEmpty);
    [self.delegate adDidClick];
}

- (void)interstitialDidDisappear:(SMAInterstitial *_Nonnull)interstitial {
    LogAdapterDelegate_Internal(logCallbackEmpty);
    [self.delegate adDidClose];
}

- (void)interstitialWillAppear:(SMAInterstitial *_Nonnull)interstitial {
    LogAdapterDelegate_Internal(logCallbackEmpty);
}

- (void)interstitialWillDisappear:(SMAInterstitial *_Nonnull)interstitial {
    LogAdapterDelegate_Internal(logCallbackEmpty);
}

- (void)interstitialWillLeaveApplication:(SMAInterstitial *_Nonnull)interstitial {
    LogAdapterDelegate_Internal(logCallbackEmpty);
}

- (void)interstitialDidTTLExpire:(SMAInterstitial *_Nonnull)interstitial {
    LogAdapterDelegate_Internal(logAdExpired);
}

@end
