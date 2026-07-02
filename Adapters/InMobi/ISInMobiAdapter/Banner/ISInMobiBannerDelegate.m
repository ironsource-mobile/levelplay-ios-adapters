//
//  ISInMobiBannerDelegate.m
//  ISInMobiAdapter
//
//  Copyright © 2021-2025 Unity Technologies. All rights reserved.
//

#import "ISInMobiBannerDelegate.h"
#import "ISInMobiConstants.h"
#import <IronSource/ISBaseBanner.h>
#import <IronSource/ISAdapterErrorType.h>
#import <IronSource/ISLog.h>

@implementation ISInMobiBannerDelegate

- (instancetype)initWithDelegate:(id<ISBannerAdDelegate>)delegate {
    self = [super init];
    if (self) {
        self.delegate = delegate;
    }

    return self;
}

#pragma mark - IMBannerDelegate

- (void)bannerDidFinishLoading:(IMBanner *)banner {
    NSString *creativeId = banner.creativeId;
    LogAdapterDelegate_Internal(logCreativeId, creativeId);

    if (creativeId.length) {
        NSDictionary *extraData = @{creativeIdKey: creativeId};
        [self.delegate adDidLoadWithView:banner extraData:extraData];
    } else {
        [self.delegate adDidLoadWithView:banner];
    }
}

- (void)banner:(IMBanner *)banner
didFailToLoadWithError:(IMRequestStatus *)error {
    LogAdapterDelegate_Internal(logLoadFailed, networkName, error);

    ISAdapterErrorType errorType = (error.code == IMStatusCodeNoFill) ?
        ISAdapterErrorTypeNoFill : ISAdapterErrorTypeInternal;

    [self.delegate adDidFailToLoadWithErrorType:errorType
                                      errorCode:error.code
                                   errorMessage:error.localizedDescription];
}

- (void)bannerAdImpressed:(IMBanner *)banner {
    LogAdapterDelegate_Internal(logCallbackEmpty);

    [self.delegate adDidOpen];
}

- (void)banner:(IMBanner *)banner
didInteractWithParams:(NSDictionary *)params {
    LogAdapterDelegate_Internal(logCallbackEmpty);

    [self.delegate adDidClick];
}

- (void)bannerWillPresentScreen:(IMBanner *)banner {
    LogAdapterDelegate_Internal(logCallbackEmpty);

    [self.delegate adWillPresentScreen];
}

- (void)bannerDidDismissScreen:(IMBanner *)banner {
    LogAdapterDelegate_Internal(logCallbackEmpty);

    [self.delegate adDidDismissScreen];
}

- (void)userWillLeaveApplicationFromBanner:(IMBanner *)banner {
    LogAdapterDelegate_Internal(logCallbackEmpty);

    [self.delegate adWillLeaveApplication];
}

@end
