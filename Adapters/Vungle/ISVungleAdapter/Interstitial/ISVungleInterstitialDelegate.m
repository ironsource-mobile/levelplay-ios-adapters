//
//  ISVungleInterstitialDelegate.m
//  ISVungleAdapter
//
//  Copyright © 2021-2025 Unity Technologies. All rights reserved.
//

#import <IronSource/ISLog.h>
#import <IronSource/ISBaseInterstitial.h>
#import <IronSource/ISAdapterErrorType.h>
#import "ISVungleInterstitialDelegate.h"
#import "ISVungleConstants.h"

@implementation ISVungleInterstitialDelegate

- (instancetype)initWithDelegate:(id<ISInterstitialAdDelegate>)delegate {
    self = [super init];
    if (self) {
        _delegate = delegate;
    }
    return self;
}

#pragma mark - VungleInterstitialDelegate

- (void)interstitialAdDidLoad:(VungleInterstitial *)interstitial {
    NSString *creativeId = interstitial.creativeId;
    LogAdapterDelegate_Internal(logCreativeId, creativeId);

    if (creativeId.length) {
        [self.delegate adDidLoadWithExtraData:@{creativeIdKey: creativeId}];
    } else {
        [self.delegate adDidLoad];
    }
}

- (void)interstitialAdDidFailToLoad:(VungleInterstitial *)interstitial
                          withError:(NSError *)error {
    LogAdapterDelegate_Internal(logError, error.description);

    BOOL isNoFill = (error.code == VungleErrorAdNoFill);
    ISAdapterErrorType errorType = isNoFill ? ISAdapterErrorTypeNoFill : ISAdapterErrorTypeInternal;

    [self.delegate adDidFailToLoadWithErrorType:errorType
                                      errorCode:error.code
                                   errorMessage:error.description];
}

- (void)interstitialAdDidTrackImpression:(VungleInterstitial *)interstitial {
    LogAdapterDelegate_Internal(logCallbackEmpty);
    [self.delegate adDidOpen];
}

- (void)interstitialAdDidFailToPresent:(VungleInterstitial *)interstitial
                             withError:(NSError *)error {
    LogAdapterDelegate_Internal(logError, error.description);
    [self.delegate adDidFailToShowWithErrorCode:error.code
                                   errorMessage:error.description];
}

- (void)interstitialAdDidClick:(VungleInterstitial *)interstitial {
    LogAdapterDelegate_Internal(logCallbackEmpty);
    [self.delegate adDidClick];
}

- (void)interstitialAdDidClose:(VungleInterstitial *)interstitial {
    LogAdapterDelegate_Internal(logCallbackEmpty);
    [self.delegate adDidClose];
}

@end
