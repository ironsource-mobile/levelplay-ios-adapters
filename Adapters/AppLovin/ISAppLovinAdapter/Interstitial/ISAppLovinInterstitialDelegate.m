//
//  ISAppLovinInterstitialDelegate.m
//  ISAppLovinAdapter
//
//  Copyright © 2021-2025 Unity Technologies. All rights reserved.
//

#import <IronSource/ISBaseInterstitial.h>
#import <IronSource/ISError.h>
#import <IronSource/ISAdapterErrorType.h>
#import <IronSource/ISLog.h>
#import "ISAppLovinInterstitialDelegate.h"
#import "ISAppLovinInterstitialAdapter.h"
#import "ISAppLovinAdapter+Internal.h"

@implementation ISAppLovinInterstitialDelegate

- (instancetype)initWithAdapter:(ISAppLovinInterstitialAdapter *)adapter
                       delegate:(id<ISInterstitialAdDelegate>)delegate {
    self = [super init];
    if (self) {
        _adapter = adapter;
        _delegate = delegate;
    }
    return self;
}

#pragma mark - ALAdLoadDelegate

- (void)adService:(ALAdService *)adService
        didLoadAd:(ALAd *)ad {
    LogAdapterDelegate_Internal(logCallbackEmpty);
    [self.adapter setLoadedAd:ad];
    [self.delegate adDidLoad];
}

- (void)adService:(ALAdService *)adService didFailToLoadAdWithError:(int)code {
    NSString *errorReason = [ISAppLovinAdapter errorMessageForCode:code];
    LogAdapterDelegate_Internal(logError, errorReason);

    ISAdapterErrorType errorType = (code == kALErrorCodeNoFill) ? ISAdapterErrorTypeNoFill : ISAdapterErrorTypeInternal;
    [self.delegate adDidFailToLoadWithErrorType:errorType
                                      errorCode:code
                                   errorMessage:errorReason];
}

#pragma mark - ALAdDisplayDelegate

- (void)ad:(ALAd *)ad wasDisplayedIn:(UIView *)view {
    LogAdapterDelegate_Internal(logCallbackEmpty);
    [self.delegate adDidOpen];
}

- (void)ad:(ALAd *)ad wasClickedIn:(UIView *)view {
    LogAdapterDelegate_Internal(logCallbackEmpty);
    [self.delegate adDidClick];
}

- (void)ad:(ALAd *)ad wasHiddenIn:(UIView *)view {
    LogAdapterDelegate_Internal(logCallbackEmpty);
    [self.delegate adDidClose];
}

@end
