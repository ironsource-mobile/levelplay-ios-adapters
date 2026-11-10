//
//  ISFacebookBannerDelegate.m
//  ISFacebookAdapter
//
//  Copyright © 2021-2025 Unity Technologies. All rights reserved.
//

#import "ISFacebookBannerDelegate.h"
#import "ISFacebookConstants.h"
#import <IronSource/ISBaseBanner.h>
#import <IronSource/ISAdapterErrorType.h>
#import <IronSource/ISLog.h>

@implementation ISFacebookBannerDelegate

- (instancetype)initWithDelegate:(id<ISBannerAdDelegate>)delegate {
    self = [super init];
    if (self) {
        _delegate = delegate;
    }
    return self;
}

#pragma mark - FBAdViewDelegate

- (void)adViewDidLoad:(FBAdView *)adView {
    LogAdapterDelegate_Internal(logCallbackEmpty);
    [self.delegate adDidLoadWithView:adView];
}

- (void)adView:(FBAdView *)adView didFailWithError:(NSError *)error {
    LogAdapterDelegate_Internal(logLoadFailed, networkName, error);

    ISAdapterErrorType errorType = (error.code == facebookNoFillErrorCode) ?
        ISAdapterErrorTypeNoFill : ISAdapterErrorTypeInternal;

    [self.delegate adDidFailToLoadWithErrorType:errorType
                                      errorCode:error.code
                                   errorMessage:error.localizedDescription];
}

- (void)adViewWillLogImpression:(FBAdView *)adView {
    LogAdapterDelegate_Internal(logCallbackEmpty);
    [self.delegate adDidOpen];
}

- (void)adViewDidClick:(FBAdView *)adView {
    LogAdapterDelegate_Internal(logCallbackEmpty);
    [self.delegate adDidClick];
}

@end
