//
//  ISAppLovinRewardedDelegate.m
//  ISAppLovinAdapter
//
//  Copyright © 2021-2025 Unity Technologies. All rights reserved.
//

#import <IronSource/ISBaseRewardedVideo.h>
#import <IronSource/ISError.h>
#import <IronSource/ISAdapterErrorType.h>
#import <IronSource/ISLog.h>
#import "ISAppLovinRewardedDelegate.h"
#import "ISAppLovinRewardedAdapter.h"
#import "ISAppLovinAdapter+Internal.h"

@implementation ISAppLovinRewardedDelegate

- (instancetype)initWithAdapter:(ISAppLovinRewardedAdapter *)adapter
                       delegate:(id<ISRewardedVideoAdDelegate>)delegate {
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

#pragma mark - ALAdVideoPlaybackDelegate

- (void)videoPlaybackBeganInAd:(ALAd *)ad {
    LogAdapterDelegate_Internal(logCallbackEmpty);
    [self.delegate adDidStart];
}

// AppLovin reports video end and reward eligibility through this single callback,
// so both are dispatched here.
- (void)videoPlaybackEndedInAd:(ALAd *)ad
             atPlaybackPercent:(NSNumber *)percentPlayed
                  fullyWatched:(BOOL)wasFullyWatched {
    LogAdapterDelegate_Internal(logCallbackEmpty);
    [self.delegate adDidEnd];

    if (wasFullyWatched) {
        [self.delegate adRewarded];
    }
}

#pragma mark - ALAdRewardDelegate

- (void)rewardValidationRequestForAd:(ALAd *)ad
              didSucceedWithResponse:(NSDictionary *)response {
    LogAdapterDelegate_Internal(logCallbackEmpty);
}

- (void)rewardValidationRequestForAd:(ALAd *)ad
          didExceedQuotaWithResponse:(NSDictionary *)response {
    LogAdapterDelegate_Internal(logCallbackEmpty);
}

- (void)rewardValidationRequestForAd:(ALAd *)ad
             wasRejectedWithResponse:(NSDictionary *)response {
    LogAdapterDelegate_Internal(logCallbackEmpty);
}

- (void)rewardValidationRequestForAd:(ALAd *)ad
                    didFailWithError:(NSInteger)responseCode {
    LogAdapterDelegate_Internal(logCallbackEmpty);
}

@end
