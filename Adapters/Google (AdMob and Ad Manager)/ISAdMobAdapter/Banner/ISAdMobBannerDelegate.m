//
//  ISAdMobBannerDelegate.m
//  ISAdMobAdapter
//
//  Copyright © 2021-2025 Unity Technologies. All rights reserved.
//

#import "ISAdMobBannerDelegate.h"
#import "ISAdMobConstants.h"
#import <IronSource/ISBaseBanner.h>
#import <IronSource/ISAdapterErrorType.h>
#import <IronSource/ISLog.h>

@implementation ISAdMobBannerDelegate

- (instancetype)initWithDelegate:(id<ISBannerAdDelegate>)delegate {
    self = [super init];
    if (self) {
        _delegate = delegate;
    }
    return self;
}

#pragma mark - GADBannerViewDelegate

- (void)bannerViewDidReceiveAd:(GADBannerView *)bannerView {
    NSString *creativeId = bannerView.responseInfo.responseIdentifier;
    LogAdapterDelegate_Internal(logCreativeId, creativeId);

    if (creativeId.length) {
        NSDictionary *extraData = @{creativeIdKey: creativeId};
        [self.delegate adDidLoadWithView:bannerView extraData:extraData];
    } else {
        [self.delegate adDidLoadWithView:bannerView];
    }
}

- (void)bannerView:(GADBannerView *)bannerView didFailToReceiveAdWithError:(NSError *)error {
    LogAdapterDelegate_Internal(logLoadFailed, networkName, error);

    ISAdapterErrorType errorType = (error.code == GADErrorNoFill) ?
        ISAdapterErrorTypeNoFill : ISAdapterErrorTypeInternal;

    [self.delegate adDidFailToLoadWithErrorType:errorType
                                      errorCode:error.code
                                   errorMessage:error.localizedDescription];
}

- (void)bannerViewDidRecordImpression:(GADBannerView *)bannerView {
    LogAdapterDelegate_Internal(logCallbackEmpty);
    [self.delegate adDidOpen];
}

- (void)bannerViewDidRecordClick:(GADBannerView *)bannerView {
    LogAdapterDelegate_Internal(logCallbackEmpty);
    [self.delegate adDidClick];
}

- (void)bannerViewWillPresentScreen:(GADBannerView *)bannerView {
    LogAdapterDelegate_Internal(logCallbackEmpty);
    [self.delegate adWillPresentScreen];
}

- (void)bannerViewWillDismissScreen:(GADBannerView *)bannerView {
    LogAdapterDelegate_Internal(logCallbackEmpty);
}

- (void)bannerViewDidDismissScreen:(GADBannerView *)bannerView {
    LogAdapterDelegate_Internal(logCallbackEmpty);
    [self.delegate adDidDismissScreen];
}

@end
