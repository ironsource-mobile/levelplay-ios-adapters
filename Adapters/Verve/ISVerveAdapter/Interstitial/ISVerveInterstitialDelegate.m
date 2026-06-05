//
//  ISVerveInterstitialDelegate.m
//  ISVerveAdapter
//
//  Copyright © 2021-2025 Unity Technologies. All rights reserved.
//

#import "ISVerveInterstitialDelegate.h"
#import "ISVerveConstants.h"
#import <IronSource/ISBaseInterstitial.h>
#import <IronSource/ISAdapterErrorType.h>
#import <IronSource/ISLog.h>

@implementation ISVerveInterstitialDelegate

- (instancetype)initWithDelegate:(id<ISInterstitialAdDelegate>)delegate {
    self = [super init];
    if (self) {
        _delegate = delegate;
    }
    return self;
}

/// calls this method when ad successfully loaded and ready to be displayed.
- (void)interstitialDidLoad {
    LogAdapterDelegate_Internal(logCallbackEmpty);
    [self.delegate adDidLoad];
}

/// calls this method when ad was not loaded for some reasons
/// @param error the reason of failing loading
- (void)interstitialDidFailWithError:(NSError * _Null_unspecified)error {
    LogAdapterDelegate_Internal(logLoadFailed, networkName, error);
    ISAdapterErrorType errorType = (error.code == HyBidErrorCodeNoFill) ? ISAdapterErrorTypeNoFill : ISAdapterErrorTypeInternal;
    [self.delegate adDidFailToLoadWithErrorType:errorType
                                      errorCode:error.code
                                   errorMessage:error.localizedDescription];
}

/// calls this method when user clicked on the ad
- (void)interstitialDidTrackClick {
    LogAdapterDelegate_Internal(logCallbackEmpty);
    [self.delegate adDidClick];
}

/// calls this method when ad was dismissed by user action using the close button
- (void)interstitialDidDismiss {
    LogAdapterDelegate_Internal(logCallbackEmpty);
    [self.delegate adDidClose];
}

/// calls this method when ad has been presented to the user
- (void)interstitialDidTrackImpression {
    LogAdapterDelegate_Internal(logCallbackEmpty);
    [self.delegate adDidOpen];
}

@end
