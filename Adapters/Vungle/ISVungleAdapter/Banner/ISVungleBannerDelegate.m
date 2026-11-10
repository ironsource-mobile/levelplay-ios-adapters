//
//  ISVungleBannerDelegate.m
//  ISVungleAdapter
//
//  Copyright © 2021-2025 Unity Technologies. All rights reserved.
//

#import <IronSource/ISLog.h>
#import <IronSource/ISBaseBanner.h>
#import <IronSource/ISAdapterErrorType.h>
#import "ISVungleBannerDelegate.h"
#import "ISVungleConstants.h"

@implementation ISVungleBannerDelegate

- (instancetype)initWithDelegate:(id<ISBannerAdDelegate>)delegate {
    self = [super init];
    if (self) {
        _delegate = delegate;
        _isAdLoadSuccess = NO;
    }
    return self;
}

#pragma mark - VungleBannerViewDelegate

- (void)bannerAdDidLoad:(VungleBannerView *)bannerView {
    self.isAdLoadSuccess = YES;

    NSString *creativeId = bannerView.creativeId;
    LogAdapterDelegate_Internal(logCreativeId, creativeId);

    if (creativeId.length) {
        [self.delegate adDidLoadWithView:bannerView extraData:@{creativeIdKey: creativeId}];
    } else {
        [self.delegate adDidLoadWithView:bannerView];
    }
}

- (void)bannerAdDidFail:(VungleBannerView *)bannerView withError:(NSError *)error {
    LogAdapterDelegate_Internal(logError, error.description);

    BOOL isNoFill = (error.code == VungleErrorAdNoFill);
    ISAdapterErrorType errorType = isNoFill ? ISAdapterErrorTypeNoFill : ISAdapterErrorTypeInternal;

    if (!self.isAdLoadSuccess) {
        [self.delegate adDidFailToLoadWithErrorType:errorType
                                          errorCode:error.code
                                       errorMessage:error.description];
    } else {
        [self.delegate adDidFailToShowWithErrorCode:error.code
                                       errorMessage:error.description];
    }
}

- (void)bannerAdDidTrackImpression:(VungleBannerView *)bannerView {
    LogAdapterDelegate_Internal(logCallbackEmpty);
    [self.delegate adDidOpen];
}

- (void)bannerAdDidClick:(VungleBannerView *)bannerView {
    LogAdapterDelegate_Internal(logCallbackEmpty);
    [self.delegate adDidClick];
}

- (void)bannerAdWillLeaveApplication:(VungleBannerView *)bannerView {
    LogAdapterDelegate_Internal(logCallbackEmpty);
    [self.delegate adWillLeaveApplication];
}

@end
