//
//  ISFacebookNativeAdDelegate.m
//  ISFacebookAdapter
//
//  Copyright © 2021-2025 Unity Technologies. All rights reserved.
//

#import "ISFacebookNativeAdDelegate.h"
#import "ISFacebookNativeAdData.h"
#import "ISFacebookNativeAdViewBinder.h"
#import "ISFacebookConstants.h"
#import <IronSource/ISNativeAdDelegate.h>
#import <IronSource/ISAdapterErrorType.h>
#import <IronSource/ISLog.h>

@implementation ISFacebookNativeAdDelegate

- (instancetype)initWithAdOptionsPosition:(ISAdOptionsPosition)adOptionsPosition
                          viewController:(UIViewController *)viewController
                                delegate:(id<ISNativeAdDelegate>)delegate {
    self = [super init];
    if (self) {
        _adOptionsPosition = adOptionsPosition;
        _viewController = viewController;
        _delegate = delegate;
    }
    return self;
}

#pragma mark - FBNativeAdDelegate

- (void)nativeAdDidLoad:(FBNativeAd *)nativeAd {
    LogAdapterDelegate_Internal(logCallbackEmpty);

    [nativeAd unregisterView];

    ISAdapterNativeAdData *adData = [[ISFacebookNativeAdData alloc] initWithNativeAd:nativeAd];
    ISFacebookNativeAdViewBinder *binder = [[ISFacebookNativeAdViewBinder alloc] initWithNativeAd:nativeAd
                                                                               adOptionsPosition:self.adOptionsPosition
                                                                                  viewController:self.viewController];

    [self.delegate adDidLoadWithAdData:adData
                          adViewBinder:binder];
}

- (void)nativeAdDidDownloadMedia:(FBNativeAd *)nativeAd {
    LogAdapterDelegate_Internal(logCallbackEmpty);
}

- (void)nativeAd:(FBNativeAd *)nativeAd didFailWithError:(NSError *)error {
    LogAdapterDelegate_Internal(logLoadFailed, networkName, error);

    ISAdapterErrorType errorType = (error.code == facebookNoFillErrorCode) ?
        ISAdapterErrorTypeNoFill : ISAdapterErrorTypeInternal;

    [self.delegate adDidFailToLoadWithErrorType:errorType
                                      errorCode:error.code
                                   errorMessage:error.localizedDescription];
}

- (void)nativeAdWillLogImpression:(FBNativeAd *)nativeAd {
    LogAdapterDelegate_Internal(logCallbackEmpty);
    [self.delegate adDidOpen];
}

- (void)nativeAdDidClick:(FBNativeAd *)nativeAd {
    LogAdapterDelegate_Internal(logCallbackEmpty);
    [self.delegate adDidClick];
}

@end
