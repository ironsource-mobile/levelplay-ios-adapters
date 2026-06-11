//
//  ISInMobiInterstitialDelegate.m
//  ISInMobiAdapter
//
//  Copyright © 2021-2025 Unity Technologies. All rights reserved.
//

#import "ISInMobiInterstitialDelegate.h"
#import "ISInMobiConstants.h"
#import <IronSource/ISBaseInterstitial.h>
#import <IronSource/ISAdapterErrorType.h>
#import <IronSource/ISLog.h>

@implementation ISInMobiInterstitialDelegate

- (instancetype)initWithDelegate:(id<ISInterstitialAdDelegate>)delegate {
    self = [super init];
    if (self) {
        self.delegate = delegate;
    }

    return self;
}

#pragma mark - IMInterstitialDelegate

- (void)interstitialDidFinishLoading:(IMInterstitial *)interstitial {
    NSString *creativeId = interstitial.creativeId;
    LogAdapterDelegate_Internal(logCreativeId, creativeId);

    if (creativeId.length) {
        NSDictionary *extraData = @{creativeIdKey: creativeId};
        [self.delegate adDidLoadWithExtraData:extraData];
    } else {
        [self.delegate adDidLoad];
    }
}

- (void)interstitial:(IMInterstitial *)interstitial
didFailToLoadWithError:(IMRequestStatus *)error {
    LogAdapterDelegate_Internal(logLoadFailed, @"Interstitial", error);

    ISAdapterErrorType errorType = (error.code == IMStatusCodeNoFill) ?
        ISAdapterErrorTypeNoFill : ISAdapterErrorTypeInternal;

    [self.delegate adDidFailToLoadWithErrorType:errorType
                                      errorCode:error.code
                                   errorMessage:error.localizedDescription];
}

- (void)interstitialAdImpressed:(IMInterstitial *)interstitial {
    LogAdapterDelegate_Internal(logCallbackEmpty);

    [self.delegate adDidOpen];
}

- (void)interstitial:(IMInterstitial *)interstitial
didFailToPresentWithError:(IMRequestStatus *)error {
    LogAdapterDelegate_Internal(logShowFailed, @"Interstitial", error);

    [self.delegate adDidFailToShowWithErrorCode:error.code
                                   errorMessage:error.localizedDescription];
}

- (void)interstitialDidDismiss:(IMInterstitial *)interstitial {
    LogAdapterDelegate_Internal(logCallbackEmpty);

    [self.delegate adDidClose];
}

- (void)interstitial:(IMInterstitial *)interstitial
didInteractWithParams:(NSDictionary *)params {
    LogAdapterDelegate_Internal(logCallbackEmpty);

    [self.delegate adDidClick];
}

@end
