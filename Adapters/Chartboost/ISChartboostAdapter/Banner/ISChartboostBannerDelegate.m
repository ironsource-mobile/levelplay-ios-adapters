//
//  ISChartboostBannerDelegate.m
//  ISChartboostAdapter
//
//  Copyright © 2021-2025 Unity Technologies. All rights reserved.
//

#import <IronSource/ISAdapterErrorType.h>
#import <IronSource/ISBannerAdDelegate.h>
#import <IronSource/ISLog.h>
#import "ISChartboostBannerDelegate.h"
#import "ISChartboostConstants.h"

@implementation ISChartboostBannerDelegate

- (instancetype)initWithViewController:(UIViewController *)viewController
                              delegate:(id<ISBannerAdDelegate>)delegate {
    self = [super init];
    if (self) {
        _viewController = viewController;
        _delegate = delegate;
    }
    return self;
}

/// Called after a cache call, either if an ad has been loaded from the Chartboost servers and cached, or tried to but failed.
- (void)didCacheAd:(CHBCacheEvent *)event
             error:(nullable CHBCacheError *)error {
    if (error) {
        LogAdapterDelegate_Internal(logLoadFailed, networkName, error.description);
        ISAdapterErrorType errorType = (error.code == CHBCacheErrorCodeNoAdFound) ? ISAdapterErrorTypeNoFill : ISAdapterErrorTypeInternal;
        [self.delegate adDidFailToLoadWithErrorType:errorType
                                          errorCode:error.code
                                       errorMessage:error.description];
        return;
    }

    NSString *creativeId = event.adID;
    LogAdapterDelegate_Internal(logCreativeId, creativeId);

    if (creativeId.length) {
        [self.delegate adDidLoadWithView:self.bannerView
                               extraData:@{creativeIdKey: creativeId}];
    } else {
        [self.delegate adDidLoadWithView:self.bannerView];
    }

    [self.bannerView showFromViewController:self.viewController];
}

/// Called after a showFromViewController: call, either if the ad has been presented and an ad impression logged, or if the operation failed.
- (void)didShowAd:(CHBShowEvent *)event
            error:(nullable CHBShowError *)error {
    if (error) {
        LogAdapterDelegate_Internal(logError, error.description);
    }
}

/// Called after an ad has recorded an impression.
- (void)didRecordImpression:(CHBImpressionEvent *)event {
    NSString *creativeId = event.adID;
    LogAdapterDelegate_Internal(logCreativeId, creativeId);

    if (creativeId.length) {
        [self.delegate adDidOpenWithExtraData:@{creativeIdKey: creativeId}];
    } else {
        [self.delegate adDidOpen];
    }
}

/// Called after an ad has been clicked.
- (void)didClickAd:(CHBClickEvent *)event
             error:(nullable CHBClickError *)error {
    LogAdapterDelegate_Internal(logCallbackEmpty);
    [self.delegate adDidClick];

    if (error) {
        LogAdapterDelegate_Internal(logError, error.description);
    }
}

/// Called when a loaded ad has expired.
- (void)didExpireAd:(CHBExpirationEvent *)event {
    LogAdapterDelegate_Internal(logAdExpired);
}

@end
