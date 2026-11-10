//
//  ISMintegralInterstitialDelegate.m
//  ISMintegralAdapter
//
//  Copyright © 2021-2025 Unity Technologies. All rights reserved.
//

#import <MTGSDK/MTGErrorCodeConstant.h>
#import <IronSource/ISLog.h>
#import <IronSource/ISBaseInterstitial.h>
#import <IronSource/ISAdapterErrorType.h>
#import "ISMintegralInterstitialDelegate.h"
#import "ISMintegralConstants.h"

@implementation ISMintegralInterstitialDelegate

- (instancetype)initWithDelegate:(id<ISInterstitialAdDelegate>)delegate {
    self = [super init];
    if (self) {
        _delegate = delegate;
    }
    return self;
}

#pragma mark - MTGNewInterstitialBidAdDelegate

- (void)newInterstitialBidAdLoadSuccess:(MTGNewInterstitialBidAdManager *_Nonnull)adManager {
    LogAdapterDelegate_Internal(logCallbackEmpty);
}

- (void)newInterstitialBidAdResourceLoadSuccess:(MTGNewInterstitialBidAdManager *_Nonnull)adManager {
    NSString *creativeId = [adManager getCreativeIdWithUnitId:adManager.currentUnitId];
    LogAdapterDelegate_Internal(logCreativeId, creativeId);

    if (creativeId.length) {
        NSDictionary *extraData = @{creativeIdKey: creativeId};
        [self.delegate adDidLoadWithExtraData:extraData];
    } else {
        [self.delegate adDidLoad];
    }
}

- (void)newInterstitialBidAdLoadFail:(nonnull NSError *)error
                           adManager:(MTGNewInterstitialBidAdManager *_Nonnull)adManager {
    LogAdapterDelegate_Internal(logError, error);

    BOOL isNoFill = error.code == mintegralNoFillEmptyError ||
                    error.code == kMTGErrorCodeNoAds ||
                    error.code == kMTGErrorCodeNoAdsAvailableToPlay;
    ISAdapterErrorType errorType = isNoFill ? ISAdapterErrorTypeNoFill : ISAdapterErrorTypeInternal;

    [self.delegate adDidFailToLoadWithErrorType:errorType
                                      errorCode:error.code
                                   errorMessage:error.description];
}

- (void)newInterstitialBidAdShowSuccess:(MTGNewInterstitialBidAdManager *_Nonnull)adManager {
    LogAdapterDelegate_Internal(logCallbackEmpty);
    [self.delegate adDidOpen];
}

- (void)newInterstitialBidAdShowSuccessWithBidToken:(nonnull NSString *)bidToken
                                          adManager:(MTGNewInterstitialBidAdManager *_Nonnull)adManager {
    LogAdapterDelegate_Internal(logCallbackEmpty);
}

- (void)newInterstitialBidAdShowFail:(nonnull NSError *)error
                           adManager:(MTGNewInterstitialBidAdManager *_Nonnull)adManager {
    LogAdapterDelegate_Internal(logError, error);
    [self.delegate adDidFailToShowWithErrorCode:error.code
                                   errorMessage:error.description];
}

- (void)newInterstitialBidAdPlayCompleted:(MTGNewInterstitialBidAdManager *_Nonnull)adManager {
    LogAdapterDelegate_Internal(logCallbackEmpty);
}

- (void)newInterstitialBidAdEndCardShowSuccess:(MTGNewInterstitialBidAdManager *_Nonnull)adManager {
    LogAdapterDelegate_Internal(logCallbackEmpty);
}

- (void)newInterstitialBidAdClicked:(MTGNewInterstitialBidAdManager *_Nonnull)adManager {
    LogAdapterDelegate_Internal(logCallbackEmpty);
    [self.delegate adDidClick];
}

- (void)newInterstitialBidAdDismissedWithConverted:(BOOL)converted
                                         adManager:(MTGNewInterstitialBidAdManager *_Nonnull)adManager {
    LogAdapterDelegate_Internal(logCallbackEmpty);
}

- (void)newInterstitialBidAdDidClosed:(MTGNewInterstitialBidAdManager *_Nonnull)adManager {
    LogAdapterDelegate_Internal(logCallbackEmpty);
    [self.delegate adDidClose];
}

- (void)newInterstitialBidAdRewarded:(BOOL)rewardedOrNot
                   alertWindowStatus:(MTGNIAlertWindowStatus)alertWindowStatus
                           adManager:(MTGNewInterstitialBidAdManager *_Nonnull)adManager {
    LogAdapterDelegate_Internal(logCallbackEmpty);
}

@end
